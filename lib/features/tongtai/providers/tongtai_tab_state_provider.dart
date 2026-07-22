import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import '../state/tongtai_tab_state.dart';
import '../state/tongtai_tab_state_store.dart';

/// Persistence boundary for Tổng Tài tab state (WTM-56).
///
/// Defaults to the SharedPreferences-backed store; tests override this with an
/// [InMemoryTongtaiTabStateStore].
final tongtaiTabStateStoreProvider = Provider<TongtaiTabStateStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsTongtaiTabStateStore(prefs);
});

/// Caches per-tab UI state (scroll offset + form values) in memory and mirrors
/// every mutation to local storage (WTM-56).
///
/// The map is keyed by tab index (see `TongtaiTabs`). Screens read the current
/// snapshot for their tab and write back scroll/form changes; the values then
/// survive both tab switches (in memory) and app restarts (persisted).
final tongtaiTabStateProvider =
    NotifierProvider<TongtaiTabStateController, Map<int, TongtaiTabState>>(
      TongtaiTabStateController.new,
    );

class TongtaiTabStateController extends Notifier<Map<int, TongtaiTabState>> {
  TongtaiTabStateStore get _store => ref.read(tongtaiTabStateStoreProvider);

  @override
  Map<int, TongtaiTabState> build() {
    // Hydrate from storage on first read (covers app-restart scenarios).
    return Map<int, TongtaiTabState>.from(
      ref.watch(tongtaiTabStateStoreProvider).readAll(),
    );
  }

  /// Current snapshot for [tabIndex], or an empty state if none is cached.
  TongtaiTabState stateFor(int tabIndex) =>
      state[tabIndex] ?? const TongtaiTabState();

  /// Persists [tabIndex]'s state to memory + storage, pruning empty entries.
  Future<void> _commit(int tabIndex, TongtaiTabState next) async {
    final current = stateFor(tabIndex);
    if (current == next) return; // nothing changed — skip redundant writes
    final updated = Map<int, TongtaiTabState>.from(state);
    if (next.isEmpty) {
      updated.remove(tabIndex);
    } else {
      updated[tabIndex] = next;
    }
    state = updated;
    await _store.writeAll(updated);
  }

  /// Records the scroll offset for [tabIndex] (AC: scroll memory).
  Future<void> saveScrollOffset(int tabIndex, double offset) {
    final clamped = offset < 0 ? 0.0 : offset;
    return _commit(
      tabIndex,
      stateFor(tabIndex).copyWith(scrollOffset: clamped),
    );
  }

  /// Records a form field value for [tabIndex] (AC: form preservation).
  Future<void> saveFormValue(int tabIndex, String fieldKey, String value) {
    return _commit(tabIndex, stateFor(tabIndex).withFormValue(fieldKey, value));
  }

  /// Removes a single form field for [tabIndex].
  Future<void> clearFormValue(int tabIndex, String fieldKey) {
    return _commit(tabIndex, stateFor(tabIndex).withoutFormValue(fieldKey));
  }

  /// Discards all cached state for [tabIndex] so the tab reloads fresh data
  /// (AC: manual refresh clears cache and resets tab state).
  Future<void> refreshTab(int tabIndex) async {
    if (!state.containsKey(tabIndex)) return;
    final updated = Map<int, TongtaiTabState>.from(state)..remove(tabIndex);
    state = updated;
    await _store.writeAll(updated);
  }

  /// Wipes all cached + persisted tab state (AC: cleanup on logout /
  /// user-context switch — prevents state from leaking across users).
  Future<void> clearAll() async {
    state = <int, TongtaiTabState>{};
    await _store.clear();
  }
}
