import 'package:drift/drift.dart';

/// SupplierFavorite: a supplier the user has starred for quick access (WTM-65).
///
/// Local-first, on-device storage of the user's favorite suppliers. Each row is
/// one favorited supplier; the composite of ([supplierId]) is unique so a
/// supplier is either a favorite or it is not — re-favoriting is idempotent
/// (upsert), un-favoriting deletes the row.
///
/// ## Sort key
/// [addedAt] records when the supplier was favorited. The Favorites list is
/// ordered by this column **descending** so the most recently added supplier
/// surfaces first (WTM-65 AC: "sorted by most recently added").
///
/// ## Sync
/// Favorites are part of the offline-first sync story: every add/remove is also
/// appended to `SyncQueueItemsTable` (see `SyncQueueRepository`) so a future
/// Phase-3 cloud worker can replay them to the backend. This table itself is the
/// durable local source of truth.
class SupplierFavoritesTable extends Table {
  /// Id of the favorited supplier (matches `Supplier.id`). Primary key, so each
  /// supplier appears at most once.
  TextColumn get supplierId => text()();

  /// When the supplier was added to favorites. Defaults to now on insert and
  /// drives the most-recently-added ordering of the Favorites list.
  DateTimeColumn get addedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {supplierId};
}
