library;

import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';

import '../../../database/migrations/tongtai_migrations.dart';

/// The `.ttbk` **v2** format — a **Business Snapshot Package** (WTM-164/165,
/// ADR-TON-018).
///
/// **Backup is one capability of the package, not the package itself**
/// (Founder note, 2026-07-31). The same envelope is meant to carry, later:
/// Restore · Clone Business · Migration · Demo Dataset · AI Sandbox · Support
/// Bundle · Analytics Exchange. None of those are implemented; the format
/// simply must not foreclose them, which costs three manifest fields now and
/// a schema migration later.
///
/// What that reservation buys, concretely:
///
/// - [BackupManifest.packageKind] — a package states what it is *for*, so a
///   demo dataset, a support bundle and a real backup are not indistinguishable
///   files that a reader has to guess about.
/// - [BackupManifest.datasets] — a package declares what it *contains*.
///   "A snapshot must hold all six datasets" is a rule of **restore**, not of
///   the format: an Analytics Exchange or a Demo Dataset carrying three of them
///   is legitimate, and the parser has no business rejecting it.
/// - [BackupManifest.redaction] — a Support Bundle will need customer names and
///   phones stripped. A reader must be able to see that happened, and restore
///   must be able to refuse a redacted package rather than silently writing
///   holes into a business.
///
/// Unknown manifest keys are **ignored, never fatal**, so a newer writer adding
/// a field does not turn its packages into "corrupt" for an older reader — the
/// version fields are what gate compatibility.
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

  /// Business Journey tree (WTM-185). **Optional on purpose** — see [optional].
  static const String journeys = 'journeys';

  /// AI Business Profile (WTM-177). **Optional on purpose** — see [optional].
  static const String businessProfile = 'businessProfile';

  /// Every dataset a v2 backup must carry. A file missing any of these is
  /// **not** a complete snapshot and is rejected rather than partially applied.
  ///
  /// ⚠️ **Adding a name here retroactively invalidates every `.ttbk` file that
  /// already exists.** `BackupService` rejects a package missing any required
  /// dataset, so a seller who backed up yesterday would find today's build
  /// refuses to restore it — a data-loss-shaped bug produced by an additive
  /// feature. New datasets go in [optional] instead, unless the Founder
  /// explicitly accepts breaking older files.
  static const List<String> all = [
    customers,
    products,
    orders,
    goals,
    transactions,
    favourites,
  ];

  /// Datasets a package **may** carry. Written when present; when absent the
  /// restore proceeds and that part of the app is simply left empty.
  ///
  /// This is ADR-TON-018 amendment 1 applied to datasets rather than to
  /// manifest keys: *"vắng mặt ⇒ mặc định (file v2 cũ vẫn restore được)"*.
  static const List<String> optional = [businessProfile, journeys];
}

/// What a package is **for**.
///
/// Reserved now, used later. Only [backup] is produced or accepted today —
/// everything else is declared so a future writer has a name to put in the
/// manifest and a future reader has something to switch on, instead of both
/// having to invent one and disagree.
///
/// Stored as a stable string: an unknown kind from a newer app parses to
/// [unknown] rather than failing, and `restore` refuses it explicitly.
enum PackageKind {
  /// A full snapshot of one business, taken to be restored onto itself.
  backup,

  /// A snapshot taken to seed a *different* business. Will need id re-keying
  /// rules before it can be honoured.
  clone,

  /// A snapshot carried across a schema change.
  migration,

  /// Curated sample data shipped for demos (cf. ADR-TON-014 `sample-` rows).
  demoDataset,

  /// A dataset handed to an AI sandbox — never the live business.
  aiSandbox,

  /// A diagnostic bundle for support. Will be redacted; see [BackupRedaction].
  supportBundle,

  /// Aggregates for exchange. Not a restorable business.
  analyticsExchange,

  /// A kind this build does not know. Kept as a value so an unknown package is
  /// *identified* rather than mistaken for a backup.
  unknown;

  String get code => switch (this) {
    PackageKind.backup => 'backup',
    PackageKind.clone => 'clone',
    PackageKind.migration => 'migration',
    PackageKind.demoDataset => 'demo-dataset',
    PackageKind.aiSandbox => 'ai-sandbox',
    PackageKind.supportBundle => 'support-bundle',
    PackageKind.analyticsExchange => 'analytics-exchange',
    PackageKind.unknown => 'unknown',
  };

  static PackageKind fromCode(String? code) => switch (code) {
    'backup' => PackageKind.backup,
    'clone' => PackageKind.clone,
    'migration' => PackageKind.migration,
    'demo-dataset' => PackageKind.demoDataset,
    'ai-sandbox' => PackageKind.aiSandbox,
    'support-bundle' => PackageKind.supportBundle,
    'analytics-exchange' => PackageKind.analyticsExchange,
    // A package written before this field existed is a backup — that is all
    // the format could produce at the time.
    null => PackageKind.backup,
    _ => PackageKind.unknown,
  };

  /// Whether a package of this kind may be written over a live business.
  /// Only [backup] today; the rest need rules that do not exist yet, and
  /// guessing at them is how a "clone" quietly becomes a data-loss event.
  bool get isRestorable => this == PackageKind.backup;
}

/// What was removed from a package before it was written.
enum BackupRedaction {
  /// Nothing removed — a faithful snapshot.
  none,

  /// Personal fields (names, phones, emails, addresses, notes) stripped.
  /// Reserved for Support Bundle; **never restorable**, because restoring it
  /// would write blanks over real customers.
  personalData;

  String get code => switch (this) {
    BackupRedaction.none => 'none',
    BackupRedaction.personalData => 'personal-data',
  };

  static BackupRedaction fromCode(String? code) => switch (code) {
    'personal-data' => BackupRedaction.personalData,
    _ => BackupRedaction.none,
  };
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
    this.packageKind = PackageKind.backup,
    this.datasets = BackupDatasets.all,
    this.redaction = BackupRedaction.none,
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

  /// What this package is for (WTM-165). Defaults to [PackageKind.backup] for
  /// packages written before the field existed — that is all v2 could produce.
  final PackageKind packageKind;

  /// Which datasets the payload declares. **Completeness is a rule of restore,
  /// not of the format**: a Demo Dataset or an Analytics Exchange carrying a
  /// subset is a valid package, just not a restorable one.
  final List<String> datasets;

  /// What was stripped before writing. A redacted package is readable and
  /// inspectable but must never be written over a live business.
  final BackupRedaction redaction;

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
    'packageKind': packageKind.code,
    'datasets': datasets,
    'redaction': redaction.code,
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
    // The three WTM-165 fields are OPTIONAL on read. A package written before
    // they existed is a complete, unredacted backup — which is exactly what
    // the format could produce then, so the defaults are facts, not guesses.
    final rawDatasets = json['datasets'];
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
      packageKind: PackageKind.fromCode(
        json['packageKind'] is String ? json['packageKind'] as String : null,
      ),
      datasets: rawDatasets is List
          ? [
              for (final d in rawDatasets)
                if (d is String) d,
            ]
          : BackupDatasets.all,
      redaction: BackupRedaction.fromCode(
        json['redaction'] is String ? json['redaction'] as String : null,
      ),
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
///
/// **Synchronous on purpose.** The `cryptography` package's `Sha256().hash()`
/// returns a Future that never completes inside `testWidgets`' fake-async
/// zone, so a screen that checksums a file could not be widget tested at all
/// — the whole restore flow would have been unverifiable above the service
/// layer. A checksum has no reason to be asynchronous; `package:crypto` does
/// it in pure Dart, synchronously, everywhere.
String backupSha256Hex(List<int> bytes) =>
    crypto.sha256.convert(bytes).toString();

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
