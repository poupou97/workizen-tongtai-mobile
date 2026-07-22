import 'package:drift/drift.dart';

/// SyncQueueItem: the local, offline-first outbox of pending write operations
/// (WTM-54).
///
/// This is **infrastructure**, not one of the 15 business entities. When the
/// device is offline (or cloud sync is simply not implemented yet), every
/// CREATE / UPDATE / DELETE the user makes is appended here as a durable record
/// of intent. A future Phase-3 cloud sync worker drains this queue in order and
/// replays each operation against the server. See
/// `docs/tongtai/SYNC-QUEUE-CONFLICT-RESOLUTION.md`.
///
/// ## FIFO ordering
/// [id] is an auto-incrementing integer, so it is a strictly monotonic sequence
/// number that reflects true insertion order. The repository dequeues/peeks by
/// `id ASC`, which guarantees first-in-first-out replay **even when two
/// operations share the same wall-clock [timestamp]** (timestamps can collide
/// at millisecond resolution; the sequence id never does). [timestamp] carries
/// the *logical* time of the operation and drives last-write-wins conflict
/// resolution — it is deliberately kept separate from the ordering key.
///
/// There is no foreign key to the mutated entity on purpose: a queued DELETE
/// outlives the row it deletes, so the queue must survive after the referenced
/// entity is gone.
class SyncQueueItemsTable extends Table {
  /// Monotonic sequence number / primary key. Also the FIFO ordering key.
  IntColumn get id => integer().autoIncrement()();

  /// The kind of write: `create`, `update`, or `delete`.
  ///
  /// Stored as plain text (the [SyncOperationType] enum name) to match how the
  /// rest of the Tổng Tài schema persists enums as strings (see
  /// `tongtai_enums.dart`).
  TextColumn get operationType => text()();

  /// Entity kind the operation targets, e.g. `product`, `order`, `customer`.
  TextColumn get entityType => text()();

  /// Primary key of the affected row in its own table.
  TextColumn get entityId => text()();

  /// Logical timestamp of the operation. Drives last-write-wins conflict
  /// resolution during replay; NOT used for ordering (that is [id]).
  DateTimeColumn get timestamp =>
      dateTime().withDefault(Constant(DateTime.now()))();

  /// JSON snapshot of the mutated entity (the fields to replay).
  ///
  /// Nullable because a DELETE needs no body — [entityType] + [entityId] fully
  /// describe it.
  TextColumn get payload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
