import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'tongtai_tab_state.dart';

/// Persistence boundary for per-tab UI state (WTM-56).
///
/// Reads are synchronous so the Riverpod controller can hydrate its initial
/// state without an async `build`. Writes are async because the underlying
/// platform store is. Follows the same interface + in-memory-fake pattern as
/// the identity store (WTM-58) so the controller is testable without platform
/// channels.
abstract interface class TongtaiTabStateStore {
  /// All persisted tab states, keyed by tab index. Returns an empty map when
  /// nothing has been saved (fresh install / after a clear).
  Map<int, TongtaiTabState> readAll();

  /// Overwrites the persisted snapshot with [states].
  Future<void> writeAll(Map<int, TongtaiTabState> states);

  /// Removes all persisted tab state (used on logout / user-context switch).
  Future<void> clear();

  /// SharedPreferences key holding the JSON-encoded tab-state map.
  static const String storageKey = 'tongtai.tab_state';
}

/// Production store backed by [SharedPreferences].
///
/// The whole tab-state map is encoded as a single JSON object under
/// [TongtaiTabStateStore.storageKey] — small, and cheaper than one key per tab.
class SharedPrefsTongtaiTabStateStore implements TongtaiTabStateStore {
  SharedPrefsTongtaiTabStateStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Map<int, TongtaiTabState> readAll() {
    final raw = _prefs.getString(TongtaiTabStateStore.storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <int, TongtaiTabState>{};
      decoded.forEach((key, value) {
        final tabIndex = int.tryParse('$key');
        if (tabIndex != null && value is Map) {
          result[tabIndex] = TongtaiTabState.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
      return result;
    } on FormatException {
      // Corrupt payload — treat as no saved state rather than crashing.
      return {};
    }
  }

  @override
  Future<void> writeAll(Map<int, TongtaiTabState> states) async {
    if (states.isEmpty) {
      await clear();
      return;
    }
    final encoded = jsonEncode(
      states.map((tab, s) => MapEntry('$tab', s.toJson())),
    );
    await _prefs.setString(TongtaiTabStateStore.storageKey, encoded);
  }

  @override
  Future<void> clear() => _prefs.remove(TongtaiTabStateStore.storageKey);
}

/// In-memory store for tests (no platform channels required).
class InMemoryTongtaiTabStateStore implements TongtaiTabStateStore {
  InMemoryTongtaiTabStateStore([Map<int, TongtaiTabState>? seed])
    : _states = {...?seed};

  final Map<int, TongtaiTabState> _states;

  @override
  Map<int, TongtaiTabState> readAll() => Map.unmodifiable(_states);

  @override
  Future<void> writeAll(Map<int, TongtaiTabState> states) async {
    _states
      ..clear()
      ..addAll(states);
  }

  @override
  Future<void> clear() async => _states.clear();
}
