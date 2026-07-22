// Offline-first sync queue repository for Tổng Tài (WTM-54).
//
// Wraps `SyncQueueItemsTable` behind a small FIFO-queue API. Every local write
// that must eventually reach the cloud is `enqueue`d here; a future Phase-3 sync
// worker drains the queue with `peek`/`dequeue` in insertion order and replays
// each operation, using `LastWriteWinsResolver` to settle conflicts.

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import 'sync_operation.dart';

/// FIFO outbox of pending sync operations, backed by SQLite/Drift.
///
/// Ordering is by the table's auto-incrementing [SyncQueueItemsTable.id], which
/// is strictly monotonic, so items always come out in the order they went in —
/// even when several share the same millisecond [SyncOperation.timestamp].
class SyncQueueRepository {
  SyncQueueRepository(this._db);

  final AppDatabase _db;

  $SyncQueueItemsTableTable get _table => _db.syncQueueItemsTable;

  /// Append an operation to the tail of the queue.
  ///
  /// [payload] is a JSON-serialisable snapshot of the entity's fields; pass
  /// `null` for a delete. [timestamp] defaults to now (the column default) and
  /// is the logical time used later for last-write-wins resolution.
  ///
  /// Returns the newly assigned sequence id.
  Future<int> enqueue({
    required SyncOperationType operationType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
  }) {
    return _db
        .into(_table)
        .insert(
          SyncQueueItemsTableCompanion.insert(
            operationType: operationType.storageValue,
            entityType: entityType,
            entityId: entityId,
            payload: payload == null
                ? const Value.absent()
                : Value(jsonEncode(payload)),
            timestamp: timestamp == null
                ? const Value.absent()
                : Value(timestamp),
          ),
        );
  }

  /// Return the oldest queued operation **without removing it**, or `null` when
  /// the queue is empty.
  Future<SyncOperation?> peek() async {
    final row = await _oldestQuery().getSingleOrNull();
    return row == null ? null : _toOperation(row);
  }

  /// Remove and return the oldest queued operation (FIFO), or `null` when the
  /// queue is empty.
  ///
  /// The read + delete run in a single transaction so two concurrent drainers
  /// can never hand out the same item twice.
  Future<SyncOperation?> dequeue() {
    return _db.transaction(() async {
      final row = await _oldestQuery().getSingleOrNull();
      if (row == null) return null;
      await (_db.delete(_table)..where((t) => t.id.equals(row.id))).go();
      return _toOperation(row);
    });
  }

  /// All queued operations in FIFO order (oldest first). Read-only inspection;
  /// does not modify the queue.
  Future<List<SyncOperation>> pending() async {
    final rows = await (_db.select(
      _table,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return rows.map(_toOperation).toList();
  }

  /// Number of operations currently waiting in the queue.
  Future<int> count() async {
    final countExp = _table.id.count();
    final row = await (_db.selectOnly(
      _table,
    )..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  /// `true` when there is nothing left to sync.
  Future<bool> isEmpty() async => (await count()) == 0;

  /// Remove every queued operation. Returns the number of rows deleted (e.g.
  /// after a successful full sync or a user-initiated reset).
  Future<int> clear() => _db.delete(_table).go();

  /// Oldest-first, single-row query used by [peek]/[dequeue].
  SimpleSelectStatement<$SyncQueueItemsTableTable, SyncQueueItemsTableData>
  _oldestQuery() {
    return _db.select(_table)
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(1);
  }

  SyncOperation _toOperation(SyncQueueItemsTableData row) {
    return SyncOperation(
      id: row.id,
      type: SyncOperationType.fromStorage(row.operationType),
      entityType: row.entityType,
      entityId: row.entityId,
      timestamp: row.timestamp,
      payload: row.payload,
    );
  }
}
