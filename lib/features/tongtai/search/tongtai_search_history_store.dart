/// Recent-search history persistence for the Tổng Tài Unified Search screen
/// (WTM-73 AC: "Search history stored and accessible with quick repeat").
///
/// Follows the same interface + real-impl + in-memory-fake pattern as the other
/// Tổng Tài stores (onboarding, tab-state, favorites), so the controller and
/// screen are testable without platform channels. History is a short, ordered
/// list of raw query strings — most-recent-first, de-duplicated, capped — so a
/// tap on a recent entry repeats the exact search.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// How many recent searches are kept. Small on purpose: quick-repeat is most
/// useful for the handful of most recent queries, and it keeps the chip row
/// tidy.
const int kTongtaiSearchHistoryLimit = 10;

/// Folds [query] into [current], returning the new history list.
///
/// Pure so the ordering/dedup/cap rules are unit-testable in isolation:
/// * a blank query is ignored (returns a copy of [current] unchanged);
/// * the new query moves to the front (most-recent-first);
/// * any earlier occurrence (case-insensitive) is removed, so repeats don't pile
///   up — re-running an old search just bumps it back to the top;
/// * the result is capped at [limit].
List<String> foldSearchHistory(
  List<String> current,
  String query, {
  int limit = kTongtaiSearchHistoryLimit,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return List<String>.of(current);

  final lower = trimmed.toLowerCase();
  final out = <String>[trimmed];
  for (final entry in current) {
    if (out.length >= limit) break;
    if (entry.trim().toLowerCase() == lower) continue; // drop the old copy
    out.add(entry);
  }
  return out;
}

/// Persistence boundary for the recent-search list.
abstract interface class TongtaiSearchHistoryStore {
  /// SharedPreferences key holding the ordered recent-query list.
  static const String storageKey = 'tongtai.search_history';

  /// The recent queries, most-recent-first. Empty on a fresh install.
  Future<List<String>> load();

  /// Records [query] as the most recent search and returns the updated list.
  /// De-duplicates and caps per [foldSearchHistory]; a blank query is a no-op.
  Future<List<String>> add(String query);

  /// Clears the entire history.
  Future<void> clear();
}

/// Production store backed by [SharedPreferences] (a plain string list — the
/// queries carry nothing sensitive, so no secure storage is needed).
class SharedPrefsTongtaiSearchHistoryStore
    implements TongtaiSearchHistoryStore {
  SharedPrefsTongtaiSearchHistoryStore(
    this._prefs, {
    this.limit = kTongtaiSearchHistoryLimit,
  });

  final SharedPreferences _prefs;
  final int limit;

  @override
  Future<List<String>> load() async =>
      _prefs.getStringList(TongtaiSearchHistoryStore.storageKey) ??
      const <String>[];

  @override
  Future<List<String>> add(String query) async {
    final next = foldSearchHistory(await load(), query, limit: limit);
    await _prefs.setStringList(TongtaiSearchHistoryStore.storageKey, next);
    return next;
  }

  @override
  Future<void> clear() => _prefs.remove(TongtaiSearchHistoryStore.storageKey);
}

/// In-memory store for tests and standalone screen previews (no platform
/// channels). Behaviourally matches the SharedPreferences implementation.
class InMemoryTongtaiSearchHistoryStore implements TongtaiSearchHistoryStore {
  InMemoryTongtaiSearchHistoryStore({
    this.limit = kTongtaiSearchHistoryLimit,
    List<String>? seed,
  }) : _entries = List<String>.of(seed ?? const <String>[]);

  final int limit;
  final List<String> _entries;

  @override
  Future<List<String>> load() async => List<String>.of(_entries);

  @override
  Future<List<String>> add(String query) async {
    final next = foldSearchHistory(_entries, query, limit: limit);
    _entries
      ..clear()
      ..addAll(next);
    return List<String>.of(_entries);
  }

  @override
  Future<void> clear() async => _entries.clear();
}
