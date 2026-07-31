library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../../../database/migrations/tongtai_migrations.dart';

/// The `.ttbk` **v2** backup format — a complete, lossless snapshot of the
/// business (WTM-164, ADR-TON-018).
///
/// **Why v2 exists.** v1 was a single *CSV export* encrypted with a passphrase.
/// It covered 3 of 6 repositories, dropped `order.id` and
/// `OrderItem.productId` entirely (breaking every Inventory↔Orders link),
/// stored enums as **localized display labels**, and carried no schema version
/// at all. Restoring from it would have silently destroyed a business. v2 is a
/// separate format for a separate job: CSV stays for Excel and sharing; `.ttbk`
/// is the thing you restore from.
///
/// ## Wire format
///
/// ```text
/// TONGTAI-BACKUP-V2:{"manifest":{…},"payload":"<base64>"}
/// ```
///
/// The **manifest is plaintext**; the **payload may be encrypted**. That split
/// is deliberate:
///
/// - a reader can check version compatibility and integrity *before* asking
///   for a passphrase, and before touching the database;
/// - per-dataset record counts live **inside** the payload, so an encrypted
///   backup does not leak "this shop has 412 customers" to anyone holding the
///   file.
///
/// ## Integrity vs authenticity — not the same claim
///
/// [BackupManifest.payloadSha256] detects **corruption and truncation**. It is
/// **not** tamper protection: anyone who edits the payload can recompute the
/// hash. Authenticity comes only from AES-GCM's tag, and therefore only when
/// the backup was encrypted. The UI must never present a checksum as proof
/// that a file is genuine.

/// Container format version — the envelope (header, manifest, framing).
const int kBackupFormatVersion = 2;

/// Payload shape version — the datasets and their field names.
///
/// Bumped when the payload changes shape. A reader supports a *range*: see
/// [BackupCompatibility].
const int kBackupContentSchemaVersion = 1;

/// The app version stamped into backups.
///
/// Kept as a constant rather than read through a plugin: it is metadata for a
/// human reading a restore preview, not a runtime decision. A governance test
/// asserts it still matches `pubspec.yaml`, so it cannot quietly go stale.
const String kTongtaiAppVersion = '0.1.0';

/// The armor header. The version lives in the header itself so a v1 file, a v3
/// file and a random text file are all distinguishable before any parsing.
const String kBackupV2Header = 'TONGTAI-BACKUP-V2:';

/// Dataset keys — the canonical names used in the payload and in counts.
/// Stable identifiers: renaming one is a content-schema break.
class BackupDatasets {
  const BackupDatasets._();

  static const String customers = 'customers';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String goals = 'goals';
  static const String transactions = 'transactions';
  static const String favourites = 'favourites';

  /// Every dataset a v2 backup must carry. A file missing any of these is
  /// **not** a complete snapshot and is rejected rather than partially applied.
  static const List<String> all = [
    customers,
    products,
    orders,
    goals,
    transactions,
    favourites,
  ];
}

/// How the payload bytes are protected.
enum BackupEncryption {
  /// Plain UTF-8 JSON. Still checksummed — corruption is still detected.
  none,

  /// AES-256-GCM with a PBKDF2 key, the v1 container reused verbatim.
  aesGcm;

  String get code => switch (this) {
    BackupEncryption.none => 'none',
    BackupEncryption.aesGcm => 'aes-256-gcm',
  };

  static BackupEncryption? fromCode(String code) => switch (code) {
    'none' => BackupEncryption.none,
    'aes-256-gcm' => BackupEncryption.aesGcm,
    _ => null,
  };
}

/// Plaintext header of a v2 backup.
///
/// Everything here is safe to read without a passphrase and safe to show
/// before the database is touched. Note what is **absent**: record counts,
/// customer names, revenue — none of that belongs in a plaintext header.
@immutable
class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.contentSchemaVersion,
    required this.appVersion,
    required this.databaseSchemaVersion,
    required this.backupId,
    required this.createdAt,
    required this.encryption,
    required this.compression,
    required this.checksumAlgorithm,
    required this.payloadSha256,
    required this.payloadBytes,
  });

  final int formatVersion;
  final int contentSchemaVersion;
  final String appVersion;
  final int databaseSchemaVersion;

  /// Random per-backup id. Lets a restore be traced in a support conversation
  /// without naming the file — the filename is the user's, not ours.
  final String backupId;

  final DateTime createdAt;
  final BackupEncryption encryption;

  /// Reserved: no compression in v2. Declared so a future codec is a manifest
  /// change, not a format break.
  final String compression;

  /// Always `SHA-256` in v2; declared so the field is self-describing.
  final String checksumAlgorithm;

  /// Hex SHA-256 of the payload bytes **as stored** (ciphertext when
  /// encrypted). Detects corruption/truncation; see the library doc on why it
  /// is not authenticity.
  final String payloadSha256;

  /// Length of the stored payload in bytes — a truncated file fails this check
  /// before the (more expensive) hash is even computed.
  final int payloadBytes;

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'contentSchemaVersion': contentSchemaVersion,
    'appVersion': appVersion,
    'databaseSchemaVersion': databaseSchemaVersion,
    'backupId': backupId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'encryption': encryption.code,
    'compression': compression,
    'checksumAlgorithm': checksumAlgorithm,
    'payloadSha256': payloadSha256,
    'payloadBytes': payloadBytes,
  };

  /// Parses a manifest, returning `null` when any required field is missing or
  /// the wrong type. A malformed manifest is a rejected file, never a
  /// best-effort guess.
  static BackupManifest? tryParse(Object? json) {
    if (json is! Map) return null;
    final formatVersion = json['formatVersion'];
    final contentSchemaVersion = json['contentSchemaVersion'];
    final appVersion = json['appVersion'];
    final databaseSchemaVersion = json['databaseSchemaVersion'];
    final backupId = json['backupId'];
    final createdAt = json['createdAt'];
    final encryption = json['encryption'];
    final checksumAlgorithm = json['checksumAlgorithm'];
    final payloadSha256 = json['payloadSha256'];
    final payloadBytes = json['payloadBytes'];
    if (formatVersion is! int ||
        contentSchemaVersion is! int ||
        appVersion is! String ||
        databaseSchemaVersion is! int ||
        backupId is! String ||
        createdAt is! String ||
        encryption is! String ||
        checksumAlgorithm is! String ||
        payloadSha256 is! String ||
        payloadBytes is! int) {
      return null;
    }
    final parsedEncryption = BackupEncryption.fromCode(encryption);
    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedEncryption == null || parsedCreatedAt == null) return null;
    return BackupManifest(
      formatVersion: formatVersion,
      contentSchemaVersion: contentSchemaVersion,
      appVersion: appVersion,
      databaseSchemaVersion: databaseSchemaVersion,
      backupId: backupId,
      createdAt: parsedCreatedAt.toLocal(),
      encryption: parsedEncryption,
      compression: json['compression'] is String
          ? json['compression'] as String
          : 'none',
      checksumAlgorithm: checksumAlgorithm,
      payloadSha256: payloadSha256,
      payloadBytes: payloadBytes,
    );
  }
}

/// Whether this build can restore a given backup — and if not, why.
enum BackupCompatibility {
  /// Same content schema: restore directly.
  supported,

  /// Older content schema this build knows how to migrate. The payload is
  /// migrated **explicitly** before restore, never read as-is and hoped for.
  migratable,

  /// Written by a newer app. Blocked: a newer schema may carry fields this
  /// build would silently drop, and dropping fields during a *restore* is
  /// exactly the failure mode WTM-164 exists to prevent.
  tooNew,

  /// Not a Tổng Tài v2 backup, or one this build has no migration for.
  unsupported;

  bool get canRestore =>
      this == BackupCompatibility.supported ||
      this == BackupCompatibility.migratable;
}

/// The oldest content schema this build can migrate from. Equal to the current
/// version today — there is no older v2 payload in the wild yet, and claiming
/// otherwise would be a migration path nothing has ever exercised.
const int kMinMigratableContentSchemaVersion = kBackupContentSchemaVersion;

/// Classifies a manifest against what this build supports.
BackupCompatibility backupCompatibilityOf(BackupManifest manifest) {
  if (manifest.formatVersion != kBackupFormatVersion) {
    return manifest.formatVersion > kBackupFormatVersion
        ? BackupCompatibility.tooNew
        : BackupCompatibility.unsupported;
  }
  if (manifest.contentSchemaVersion == kBackupContentSchemaVersion) {
    return BackupCompatibility.supported;
  }
  if (manifest.contentSchemaVersion > kBackupContentSchemaVersion) {
    return BackupCompatibility.tooNew;
  }
  return manifest.contentSchemaVersion >= kMinMigratableContentSchemaVersion
      ? BackupCompatibility.migratable
      : BackupCompatibility.unsupported;
}

/// The decoded payload: the counts the writer declared, and the raw dataset
/// rows. Kept as JSON here — turning rows into domain objects is the codec's
/// job (`backup_codec.dart`), so a corrupt row fails validation with a precise
/// message instead of a constructor assertion deep in the domain.
@immutable
class BackupPayload {
  const BackupPayload({required this.declaredCounts, required this.datasets});

  /// Counts as written. Cross-checked against the parsed rows: a mismatch
  /// means the file is inconsistent with itself and is rejected.
  final Map<String, int> declaredCounts;

  /// dataset key → list of row maps.
  final Map<String, List<Map<String, Object?>>> datasets;

  Map<String, Object?> toJson() => {
    'counts': declaredCounts,
    'datasets': datasets,
  };

  static BackupPayload? tryParse(Object? json) {
    if (json is! Map) return null;
    final counts = json['counts'];
    final datasets = json['datasets'];
    if (counts is! Map || datasets is! Map) return null;
    final parsedCounts = <String, int>{};
    for (final entry in counts.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! int) return null;
      parsedCounts[key] = value;
    }
    final parsedDatasets = <String, List<Map<String, Object?>>>{};
    for (final entry in datasets.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! List) return null;
      final rows = <Map<String, Object?>>[];
      for (final row in value) {
        if (row is! Map) return null;
        rows.add(row.cast<String, Object?>());
      }
      parsedDatasets[key] = rows;
    }
    return BackupPayload(
      declaredCounts: parsedCounts,
      datasets: parsedDatasets,
    );
  }
}

/// Hex SHA-256 of [bytes].
Future<String> backupSha256Hex(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Builds the armored v2 document from a manifest and stored payload bytes.
String encodeBackupDocument(BackupManifest manifest, List<int> payloadBytes) {
  final body = jsonEncode({
    'manifest': manifest.toJson(),
    'payload': base64Encode(payloadBytes),
  });
  return '$kBackupV2Header$body';
}

/// The manifest plus raw stored payload bytes of an armored document, or null
/// when [armored] is not a well-formed v2 document.
({BackupManifest manifest, Uint8List payloadBytes})? decodeBackupDocument(
  String armored,
) {
  if (!armored.startsWith(kBackupV2Header)) return null;
  final body = armored.substring(kBackupV2Header.length).trim();
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json is! Map) return null;
  final manifest = BackupManifest.tryParse(json['manifest']);
  final payload = json['payload'];
  if (manifest == null || payload is! String) return null;
  final Uint8List bytes;
  try {
    bytes = base64Decode(payload);
  } on FormatException {
    return null;
  }
  return (manifest: manifest, payloadBytes: bytes);
}

/// The database schema version stamped into new backups.
int get currentDatabaseSchemaVersion => kTongtaiSchemaVersion;
