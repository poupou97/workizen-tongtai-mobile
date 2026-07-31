import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_queue_repository.dart';
import 'supplier_favorite.dart';

/// Persistence boundary for the user's favorite suppliers (WTM-65).
///
/// Follows the same interface + real-impl + in-memory-fake pattern as the other
/// Tổng Tài stores (identity, tab-state, schema-version), so the controller and
/// screens are testable without a database or platform channels. The production
/// implementation ([DriftSupplierFavoritesStore]) is backed by SQLite and also
/// enqueues each change for cloud sync; the fake ([InMemorySupplierFavoritesStore])
/// keeps everything in a map.
abstract interface class SupplierFavoritesStore {
  /// The entity type recorded on queued sync operations for a favorite.
  static const String syncEntityType = 'supplier_favorite';

  /// All favorites, ordered most-recently-added first (WTM-65 AC3).
  Future<List<SupplierFavorite>> loadAll();

  /// Add [supplierId] to favorites (idempotent — re-adding just refreshes
  /// [addedAt]). Returns the stored [SupplierFavorite].
  Future<SupplierFavorite> add(String supplierId, {DateTime? addedAt});

  /// Remove [supplierId] from favorites. A no-op if it was not a favorite.
  Future<void> remove(String supplierId);

  /// Removes every favourite of this business (WTM-164 restore Replace).
  Future<void> deleteAll();
}

/// SQLite-backed favorites store (WTM-65 AC5: "persisted locally in SQLite with
/// sync to backend").
///
/// Writes are durable in the `supplier_favorites_table`; every add/remove is
/// also appended to the offline-first [SyncQueueRepository] so a future Phase-3
/// cloud worker can replay it to the backend. Reads come straight from SQLite,
/// ordered by `added_at DESC`.
class DriftSupplierFavoritesStore implements SupplierFavoritesStore {
  DriftSupplierFavoritesStore(AppDatabase db, {SyncQueueRepository? syncQueue})
    : _db = db,
      _syncQueue = syncQueue ?? SyncQueueRepository(db);

  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;

  $SupplierFavoritesTableTable get _table => _db.supplierFavoritesTable;

  @override
  Future<List<SupplierFavorite>> loadAll() async {
    final rows = await (_db.select(
      _table,
    )..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).get();
    return [
      for (final row in rows)
        SupplierFavorite(supplierId: row.supplierId, addedAt: row.addedAt),
    ];
  }

  @override
  Future<SupplierFavorite> add(String supplierId, {DateTime? addedAt}) async {
    final timestamp = addedAt ?? DateTime.now();
    await _db
        .into(_table)
        .insertOnConflictUpdate(
          SupplierFavoritesTableCompanion.insert(
            supplierId: supplierId,
            addedAt: Value(timestamp),
          ),
        );
    await _syncQueue.enqueue(
      operationType: SyncOperationType.create,
      entityType: SupplierFavoritesStore.syncEntityType,
      entityId: supplierId,
      payload: {
        'supplierId': supplierId,
        'addedAt': timestamp.toIso8601String(),
      },
      timestamp: timestamp,
    );
    return SupplierFavorite(supplierId: supplierId, addedAt: timestamp);
  }

  @override
  Future<void> remove(String supplierId) async {
    final deleted = await (_db.delete(
      _table,
    )..where((t) => t.supplierId.equals(supplierId))).go();
    // Only queue a sync delete when something was actually removed, so a
    // double-tap that finds nothing to remove does not emit a phantom op.
    if (deleted > 0) {
      await _syncQueue.enqueue(
        operationType: SyncOperationType.delete,
        entityType: SupplierFavoritesStore.syncEntityType,
        entityId: supplierId,
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    // The favourites table is not business-scoped (it predates the workspace
    // column), so "all" really is all — which is what a Replace restore wants.
    await _db.delete(_table).go();
  }
}

/// In-memory favorites store for tests and standalone screen previews.
///
/// No SQLite, no sync queue — just a map keyed by supplier id. Behaviourally
/// matches [DriftSupplierFavoritesStore] for [loadAll] ordering and idempotent
/// [add].
class InMemorySupplierFavoritesStore implements SupplierFavoritesStore {
  InMemorySupplierFavoritesStore([Iterable<SupplierFavorite>? seed]) {
    for (final f in seed ?? const <SupplierFavorite>[]) {
      _byId[f.supplierId] = f;
    }
  }

  final Map<String, SupplierFavorite> _byId = {};

  @override
  Future<List<SupplierFavorite>> loadAll() async =>
      sortByMostRecentlyAdded(_byId.values);

  @override
  Future<SupplierFavorite> add(String supplierId, {DateTime? addedAt}) async {
    final favorite = SupplierFavorite(
      supplierId: supplierId,
      addedAt: addedAt ?? DateTime.now(),
    );
    _byId[supplierId] = favorite;
    return favorite;
  }

  @override
  Future<void> remove(String supplierId) async => _byId.remove(supplierId);

  @override
  Future<void> deleteAll() async => _byId.clear();
}
