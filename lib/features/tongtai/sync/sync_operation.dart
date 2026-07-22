// Sync-queue domain types for Tổng Tài offline-first replay (WTM-54).
//
// The on-device sync queue (`SyncQueueItemsTable`) stores the *kind* of each
// pending write as a plain string, mirroring how the rest of the schema
// persists enums (see `core/tongtai_enums.dart`). These types turn that string
// into a type-safe enum and define the conflict-resolution strategy replayed
// against the cloud in a future Phase 3.

import 'dart:convert';

/// The kind of write captured by a queued sync operation.
enum SyncOperationType {
  /// A new entity was created locally.
  create,

  /// An existing entity was modified locally.
  update,

  /// An entity was removed locally.
  delete;

  /// The value persisted in `SyncQueueItemsTable.operationType`.
  String get storageValue => name;

  /// Parse a stored operation string.
  ///
  /// Unknown/absent values throw, because a sync record with an unrecognised
  /// operation cannot be safely replayed — corrupt queue data must surface
  /// loudly rather than silently default to (say) a destructive delete.
  static SyncOperationType fromStorage(String value) {
    return SyncOperationType.values.firstWhere(
      (op) => op.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown SyncOperationType',
      ),
    );
  }

  String get labelEn => switch (this) {
    SyncOperationType.create => 'Create',
    SyncOperationType.update => 'Update',
    SyncOperationType.delete => 'Delete',
  };

  String get labelVi => switch (this) {
    SyncOperationType.create => 'Tạo mới',
    SyncOperationType.update => 'Cập nhật',
    SyncOperationType.delete => 'Xóa',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Which side of a conflict a resolver chose.
enum ConflictWinner {
  /// The device's pending (local) write survives.
  local,

  /// The server's (remote) write survives.
  remote,
}

/// **Last-write-wins (LWW)** conflict-resolution strategy — the Tổng Tài
/// default (WTM-54, AC3).
///
/// When a queued local operation and a server record disagree, the version with
/// the newer [DateTime] survives; the older one is discarded. LWW is chosen
/// because it is deterministic, needs no user prompt, and — given a shared
/// clock reference — converges every device to the same value. Its known
/// trade-off (a slow write can clobber a concurrent one) is acceptable for a
/// single-user, single-business app where true concurrent edits are rare. See
/// `docs/tongtai/SYNC-QUEUE-CONFLICT-RESOLUTION.md` for the full rationale and
/// the Phase-3 upgrade path.
class LastWriteWinsResolver {
  /// [tieBreak] decides an exact timestamp tie. It defaults to
  /// [ConflictWinner.remote] so that, when two writes are genuinely
  /// indistinguishable in time, all devices converge on the server's shared
  /// copy instead of each keeping its own.
  const LastWriteWinsResolver({this.tieBreak = ConflictWinner.remote});

  /// Winner chosen when [local] and [remote] timestamps are exactly equal.
  final ConflictWinner tieBreak;

  /// Decide which side wins purely from the two timestamps.
  ConflictWinner resolve({required DateTime local, required DateTime remote}) {
    if (local.isAfter(remote)) return ConflictWinner.local;
    if (remote.isAfter(local)) return ConflictWinner.remote;
    return tieBreak;
  }

  /// Return whichever of [local]/[remote] carries the newer timestamp, applying
  /// the same rule as [resolve]. Convenience for callers that hold the actual
  /// values (rows, payloads) rather than just the timestamps.
  T pick<T>({
    required T local,
    required DateTime localTimestamp,
    required T remote,
    required DateTime remoteTimestamp,
  }) {
    return resolve(local: localTimestamp, remote: remoteTimestamp) ==
            ConflictWinner.local
        ? local
        : remote;
  }
}

/// An immutable, Drift-free view of a single queued sync operation.
///
/// The repository maps `SyncQueueItemsTableData` rows into this so callers work
/// with a typed [SyncOperationType] and a decoded [payloadMap] instead of raw
/// strings, and so nothing outside the data layer depends on generated Drift
/// classes.
class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    this.payload,
  });

  /// Monotonic sequence number / primary key — also the FIFO order.
  final int id;

  /// Create / update / delete.
  final SyncOperationType type;

  /// Entity kind, e.g. `product`.
  final String entityType;

  /// Affected row's id.
  final String entityId;

  /// Logical time of the operation (drives last-write-wins).
  final DateTime timestamp;

  /// Raw JSON payload as stored, or `null` for a delete.
  final String? payload;

  /// The [payload] decoded as a JSON object, or `null` when there is no payload.
  ///
  /// Throws [FormatException] if the stored payload is not a JSON object — a
  /// corrupt queue row should fail loudly rather than replay garbage.
  Map<String, dynamic>? get payloadMap {
    final raw = payload;
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw FormatException('Sync payload is not a JSON object', raw);
  }

  @override
  String toString() =>
      'SyncOperation(#$id ${type.name} $entityType/$entityId @ $timestamp)';
}
