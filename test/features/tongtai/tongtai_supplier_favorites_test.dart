import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/migrations/schema_integrity.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorite.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_controller.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/producer/supplier_search_service.dart';
import 'package:tongtai/features/tongtai/sync/sync_operation.dart';
import 'package:tongtai/features/tongtai/sync/sync_queue_repository.dart';

/// Real unit tests for WTM-65 Supplier Favorites: the domain model + recency
/// sort, the reactive controller (add/remove/filter), and the SQLite-backed
/// store with its cloud-sync side effects. The Drift store runs against a real
/// in-memory SQLite database (no mocks, no placebo assertions).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupplierFavorite model', () {
    test('equality is by supplierId + addedAt', () {
      final t = DateTime(2026, 7, 16, 9);
      expect(
        SupplierFavorite(supplierId: 's1', addedAt: t),
        equals(SupplierFavorite(supplierId: 's1', addedAt: t)),
      );
      expect(
        SupplierFavorite(supplierId: 's1', addedAt: t),
        isNot(SupplierFavorite(supplierId: 's2', addedAt: t)),
      );
    });

    test('sortByMostRecentlyAdded: newest first, ties break by id (AC3)', () {
      final favorites = [
        SupplierFavorite(supplierId: 'b', addedAt: DateTime(2026, 7, 10)),
        SupplierFavorite(supplierId: 'c', addedAt: DateTime(2026, 7, 16)),
        SupplierFavorite(supplierId: 'a', addedAt: DateTime(2026, 7, 12)),
      ];
      final sorted = sortByMostRecentlyAdded(favorites);
      expect(sorted.map((f) => f.supplierId).toList(), ['c', 'a', 'b']);
    });

    test('sortByMostRecentlyAdded breaks exact-timestamp ties by id asc', () {
      final ts = DateTime(2026, 7, 16, 12);
      final sorted = sortByMostRecentlyAdded([
        SupplierFavorite(supplierId: 's3', addedAt: ts),
        SupplierFavorite(supplierId: 's1', addedAt: ts),
        SupplierFavorite(supplierId: 's2', addedAt: ts),
      ]);
      expect(sorted.map((f) => f.supplierId).toList(), ['s1', 's2', 's3']);
    });

    test('sort does not mutate the input list', () {
      final input = [
        SupplierFavorite(supplierId: 'a', addedAt: DateTime(2026, 7, 10)),
        SupplierFavorite(supplierId: 'b', addedAt: DateTime(2026, 7, 16)),
      ];
      sortByMostRecentlyAdded(input);
      expect(input.first.supplierId, 'a'); // unchanged order
    });
  });

  group('SupplierFavoritesController (in-memory store)', () {
    late SupplierFavoritesController controller;

    setUp(() => controller = SupplierFavoritesController.inMemory());

    test('starts empty', () {
      expect(controller.count, 0);
      expect(controller.isFavorite('s1'), isFalse);
      expect(controller.favoriteIds, isEmpty);
    });

    test('toggle adds then removes with one tap each (AC1)', () async {
      final added = await controller.toggle('s1');
      expect(added, isTrue);
      expect(controller.isFavorite('s1'), isTrue);
      expect(controller.count, 1);

      final removed = await controller.toggle('s1');
      expect(removed, isFalse);
      expect(controller.isFavorite('s1'), isFalse);
      expect(controller.count, 0);
    });

    test('notifies listeners on every toggle', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.toggle('s1');
      await controller.toggle('s1');
      expect(notifications, 2);
    });

    test('favoriteSuppliers resolves ids most-recently-added first (AC3)',
        () async {
      await controller.toggle('s2', now: DateTime(2026, 7, 10));
      await controller.toggle('s5', now: DateTime(2026, 7, 16));
      await controller.toggle('s1', now: DateTime(2026, 7, 12));

      final ordered = controller.favoriteSuppliers(kSampleSuppliers);
      expect(ordered.map((s) => s.id).toList(), ['s5', 's1', 's2']);
    });

    test('favoriteSuppliers drops ids not present in the directory', () async {
      await controller.toggle('does-not-exist', now: DateTime(2026, 7, 16));
      await controller.toggle('s1', now: DateTime(2026, 7, 15));
      final ordered = controller.favoriteSuppliers(kSampleSuppliers);
      expect(ordered.map((s) => s.id).toList(), ['s1']);
    });

    test('onlyFavorites keeps favorites and preserves input order (AC4)',
        () async {
      await controller.toggle('s3');
      await controller.toggle('s1');

      final input = [
        for (final id in ['s1', 's2', 's3', 's4'])
          kSampleSuppliers.firstWhere((s) => s.id == id),
      ];
      final filtered = controller.onlyFavorites(input);
      expect(filtered.map((s) => s.id).toList(), ['s1', 's3']);
    });

    test('load hydrates from the backing store', () async {
      final store = InMemorySupplierFavoritesStore([
        SupplierFavorite(supplierId: 's4', addedAt: DateTime(2026, 7, 9)),
        SupplierFavorite(supplierId: 's6', addedAt: DateTime(2026, 7, 14)),
      ]);
      final hydrated = SupplierFavoritesController(store);
      expect(hydrated.isLoaded, isFalse);

      await hydrated.load();

      expect(hydrated.isLoaded, isTrue);
      expect(hydrated.count, 2);
      expect(hydrated.isFavorite('s4'), isTrue);
      expect(hydrated.isFavorite('s6'), isTrue);
    });
  });

  group('DriftSupplierFavoritesStore (real SQLite + sync — AC5)', () {
    late AppDatabase db;
    late SyncQueueRepository queue;
    late DriftSupplierFavoritesStore store;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      queue = SyncQueueRepository(db);
      store = DriftSupplierFavoritesStore(db, syncQueue: queue);
    });

    tearDown(() async => db.close());

    test('supplier_favorites_table is part of the created schema', () async {
      final result = await verifyTongtaiSchema(db);
      expect(result.isValid, isTrue, reason: result.toString());
      expect(result.presentTables, contains('supplier_favorites_table'));
    });

    test('add persists to SQLite and loadAll reads it back', () async {
      await store.add('s1', addedAt: DateTime(2026, 7, 16, 8));
      final all = await store.loadAll();
      expect(all, hasLength(1));
      expect(all.first.supplierId, 's1');
      expect(all.first.addedAt, DateTime(2026, 7, 16, 8));
    });

    test('loadAll orders by most-recently-added first (AC3)', () async {
      await store.add('s1', addedAt: DateTime(2026, 7, 10));
      await store.add('s2', addedAt: DateTime(2026, 7, 16));
      await store.add('s3', addedAt: DateTime(2026, 7, 12));
      final all = await store.loadAll();
      expect(all.map((f) => f.supplierId).toList(), ['s2', 's3', 's1']);
    });

    test('add enqueues a CREATE sync op with a JSON payload (sync to backend)',
        () async {
      await store.add('s1', addedAt: DateTime(2026, 7, 16, 8));

      final ops = await queue.pending();
      expect(ops, hasLength(1));
      expect(ops.first.type, SyncOperationType.create);
      expect(ops.first.entityType, SupplierFavoritesStore.syncEntityType);
      expect(ops.first.entityId, 's1');
      expect(ops.first.payloadMap, {
        'supplierId': 's1',
        'addedAt': DateTime(2026, 7, 16, 8).toIso8601String(),
      });
    });

    test('remove deletes the row and enqueues a DELETE sync op', () async {
      await store.add('s1', addedAt: DateTime(2026, 7, 16));
      await store.remove('s1');

      expect(await store.loadAll(), isEmpty);

      final ops = await queue.pending();
      expect(ops.map((o) => o.type).toList(),
          [SyncOperationType.create, SyncOperationType.delete]);
      final del = ops.last;
      expect(del.entityType, SupplierFavoritesStore.syncEntityType);
      expect(del.entityId, 's1');
      expect(del.payload, isNull); // a delete carries no body
    });

    test('removing a non-favorite is a no-op and queues nothing', () async {
      await store.remove('never-favorited');
      expect(await store.loadAll(), isEmpty);
      expect(await queue.count(), 0);
    });

    test('re-adding is idempotent: one row, refreshed timestamp', () async {
      await store.add('s1', addedAt: DateTime(2026, 7, 10));
      await store.add('s1', addedAt: DateTime(2026, 7, 16));

      final all = await store.loadAll();
      expect(all, hasLength(1));
      expect(all.first.addedAt, DateTime(2026, 7, 16));
    });

    test('controller backed by the Drift store persists across reloads',
        () async {
      final c1 = SupplierFavoritesController(store);
      await c1.toggle('s1', now: DateTime(2026, 7, 16));
      expect(c1.isFavorite('s1'), isTrue);

      // A fresh controller over the same SQLite store sees the persisted state.
      final c2 = SupplierFavoritesController(store);
      await c2.load();
      expect(c2.isFavorite('s1'), isTrue);
      expect(c2.count, 1);
    });
  });
}
