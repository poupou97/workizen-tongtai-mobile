import 'package:drift/drift.dart';

import '../database.dart';
import 'schema_integrity.dart';
import 'schema_version_store.dart';
import 'tongtai_migrations.dart';

/// What the migrator did on this launch.
enum MigrationOutcome {
  /// No schema version was recorded — this is a fresh install and the schema
  /// was just created for the first time.
  freshInstall,

  /// A lower schema version was recorded and has now been upgraded.
  upgraded,

  /// The recorded version already matched the current schema; nothing to do.
  upToDate,
}

/// Outcome of running [TongtaiDatabaseMigrator.ensureMigrated].
class MigrationReport {
  const MigrationReport({
    required this.outcome,
    required this.previousVersion,
    required this.currentVersion,
    required this.integrity,
  });

  /// What happened this launch.
  final MigrationOutcome outcome;

  /// The schema version recorded before this launch, or `null` on a fresh
  /// install.
  final int? previousVersion;

  /// The schema version the database is now at.
  final int currentVersion;

  /// Result of verifying every declared table exists after migration.
  final SchemaIntegrityResult integrity;

  /// `true` when the migration completed and the schema is intact.
  bool get isSuccessful => integrity.isValid;

  @override
  String toString() =>
      'MigrationReport(${outcome.name}, $previousVersion -> $currentVersion, '
      '${integrity.isValid ? 'schema OK' : 'MISSING ${integrity.missingTables}'})';
}

/// Thrown when the schema is not intact after a migration (a declared table is
/// missing). Surfaced by [bootstrapTongtaiDatabase] so production fails loudly
/// rather than running on a half-created database.
class SchemaIntegrityException implements Exception {
  const SchemaIntegrityException(this.result);

  final SchemaIntegrityResult result;

  @override
  String toString() =>
      'SchemaIntegrityException: missing tables ${result.missingTables} '
      '(expected ${result.expectedTables.length}, '
      'found ${result.presentTables.length})';
}

/// Coordinates the schema migration on app launch (WTM-52).
///
/// Responsibilities:
/// 1. Read the last applied schema version from the shared-preferences
///    [SchemaVersionStore] (the "first launch" signal — `null` means fresh).
/// 2. Touch the database so Drift runs `onCreate` / `onUpgrade` (opening the
///    lazily-connected DB is what actually creates the tables).
/// 3. Verify schema integrity — confirm every declared table now exists.
/// 4. Record the current version so later launches short-circuit to
///    [MigrationOutcome.upToDate].
///
/// The version store is only written when the schema is verified intact, so a
/// failed creation is never recorded as success and will be retried next
/// launch.
class TongtaiDatabaseMigrator {
  TongtaiDatabaseMigrator({
    required GeneratedDatabase database,
    required SchemaVersionStore versionStore,
  })  : _db = database,
        _store = versionStore;

  final GeneratedDatabase _db;
  final SchemaVersionStore _store;

  /// Runs the migration + integrity check and returns a [MigrationReport].
  ///
  /// Does not throw on an intact-but-unexpected state; callers that need a hard
  /// failure on a broken schema should inspect [MigrationReport.isSuccessful]
  /// (or use [bootstrapTongtaiDatabase], which throws).
  Future<MigrationReport> ensureMigrated() async {
    final previous = _store.readVersion();
    final current = _db.schemaVersion;

    // Reading the schema catalogue forces the lazily-opened connection to open,
    // which runs Drift's onCreate/onUpgrade and thus creates all tables.
    final integrity = await verifyTongtaiSchema(_db);

    final MigrationOutcome outcome;
    if (previous == null) {
      outcome = MigrationOutcome.freshInstall;
    } else if (previous < current) {
      outcome = MigrationOutcome.upgraded;
    } else {
      outcome = MigrationOutcome.upToDate;
    }

    // Only persist success once the schema is proven intact, and only when the
    // recorded version is actually stale (avoids a redundant write per launch).
    if (integrity.isValid && previous != current) {
      await _store.writeVersion(current);
    }

    return MigrationReport(
      outcome: outcome,
      previousVersion: previous,
      currentVersion: current,
      integrity: integrity,
    );
  }
}

/// Production entrypoint: open the on-device Tổng Tài database and run the
/// first-launch migration, throwing [SchemaIntegrityException] if the schema is
/// not intact afterwards.
///
/// Call this once during app startup. It composes the file-backed
/// [AppDatabase] with a [SharedPrefsSchemaVersionStore] and returns the open
/// database together with a [MigrationReport] describing what happened.
///
/// Kept dependency-injectable ([database]/[versionStore]) so it can also be
/// driven from tests or a data-reset flow without touching platform channels.
Future<({AppDatabase database, MigrationReport report})>
    bootstrapTongtaiDatabase({
  AppDatabase? database,
  required SchemaVersionStore versionStore,
}) async {
  final db = database ?? AppDatabase();
  final migrator =
      TongtaiDatabaseMigrator(database: db, versionStore: versionStore);
  final report = await migrator.ensureMigrated();

  if (!report.isSuccessful) {
    throw SchemaIntegrityException(report.integrity);
  }

  // Sanity: the current schema version must match the migration module's
  // constant, so the DB, the strategy, and the persisted version never diverge.
  assert(
    db.schemaVersion == kTongtaiSchemaVersion,
    'AppDatabase.schemaVersion (${db.schemaVersion}) != kTongtaiSchemaVersion '
    '($kTongtaiSchemaVersion)',
  );

  return (database: db, report: report);
}
