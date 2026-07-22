import 'package:drift/drift.dart';

/// Result of verifying that the on-disk SQLite schema matches the tables Drift
/// declares for the Tổng Tài database (WTM-52).
class SchemaIntegrityResult {
  const SchemaIntegrityResult({
    required this.expectedTables,
    required this.presentTables,
    required this.missingTables,
  });

  /// All table names Drift expects to exist (derived from `db.allTables`).
  final List<String> expectedTables;

  /// Expected tables that were actually found in `sqlite_master`.
  final List<String> presentTables;

  /// Expected tables that are missing from the database. Empty when the schema
  /// is intact.
  final List<String> missingTables;

  /// `true` when every declared table exists on disk.
  bool get isValid => missingTables.isEmpty;

  @override
  String toString() => isValid
      ? 'SchemaIntegrityResult(valid, ${presentTables.length} tables)'
      : 'SchemaIntegrityResult(INVALID, missing: $missingTables)';
}

/// Verifies that every table declared on [db] actually exists in the SQLite
/// catalogue.
///
/// The expected set is taken from Drift's own [GeneratedDatabase.allTables], so
/// it always covers exactly the tables the app knows about (all 15 Tổng Tài
/// entities today) with no hand-maintained list to drift out of sync. The
/// actual set is read from `sqlite_master`, excluding SQLite's internal
/// `sqlite_*` bookkeeping tables.
///
/// This is the "schema integrity verified" acceptance check: after the
/// migration runs it confirms `onCreate` created everything and nothing is
/// missing.
Future<SchemaIntegrityResult> verifyTongtaiSchema(GeneratedDatabase db) async {
  final expected = db.allTables.map((t) => t.actualTableName).toSet();

  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      )
      .get();
  final actual = rows.map((r) => r.read<String>('name')).toSet();

  final missing = expected.difference(actual).toList()..sort();
  final present = expected.intersection(actual).toList()..sort();
  final expectedSorted = expected.toList()..sort();

  return SchemaIntegrityResult(
    expectedTables: expectedSorted,
    presentTables: present,
    missingTables: missing,
  );
}
