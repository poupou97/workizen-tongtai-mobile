import 'package:shared_preferences/shared_preferences.dart';

/// Persistence boundary for the *last applied* database schema version (WTM-52).
///
/// This is the shared-preferences "version check" the acceptance criteria calls
/// for: on a fresh install nothing is stored, so [readVersion] returns `null`
/// and the migrator treats it as first launch. After the schema is created (or
/// upgraded) the migrator records the new version here, so subsequent launches
/// know the DB is already at that version without re-inspecting it.
///
/// Follows the same interface + SharedPrefs-impl + in-memory-fake pattern as the
/// onboarding and tab-state stores, so the migrator is testable without
/// platform channels.
abstract interface class SchemaVersionStore {
  /// The schema version last applied to the on-device database, or `null` if no
  /// migration has ever completed (fresh install / first launch).
  int? readVersion();

  /// Records [version] as the last applied schema version.
  Future<void> writeVersion(int version);

  /// Clears the stored version (used by tests and a full data reset).
  Future<void> clear();

  /// SharedPreferences key holding the last applied schema version.
  static const String storageKey = 'tongtai.db_schema_version';
}

/// Production store backed by [SharedPreferences]. The version is a plain int
/// with no sensitive content, so no secure storage is required.
class SharedPrefsSchemaVersionStore implements SchemaVersionStore {
  SharedPrefsSchemaVersionStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  int? readVersion() => _prefs.getInt(SchemaVersionStore.storageKey);

  @override
  Future<void> writeVersion(int version) =>
      _prefs.setInt(SchemaVersionStore.storageKey, version);

  @override
  Future<void> clear() => _prefs.remove(SchemaVersionStore.storageKey);
}

/// In-memory store for tests (no platform channels required).
class InMemorySchemaVersionStore implements SchemaVersionStore {
  InMemorySchemaVersionStore([this._version]);

  int? _version;

  @override
  int? readVersion() => _version;

  @override
  Future<void> writeVersion(int version) async => _version = version;

  @override
  Future<void> clear() async => _version = null;
}
