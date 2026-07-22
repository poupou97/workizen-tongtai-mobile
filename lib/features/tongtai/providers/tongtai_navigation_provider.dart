import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import '../navigation/tongtai_design_tokens.dart';

/// Manages the currently selected tab in Tổng Tài bottom navigation.
/// Persists the selection across app sessions.
final tongtaiSelectedTabProvider =
    NotifierProvider<TongtaiSelectedTabNotifier, int>(
  TongtaiSelectedTabNotifier.new,
);

class TongtaiSelectedTabNotifier extends Notifier<int> {
  static const String _prefsKey = 'tongtai_selected_tab';
  static const int _defaultTab = TongtaiTabs.home;

  @override
  int build() {
    // Load the last selected tab from preferences synchronously
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_prefsKey) ?? _defaultTab;
  }

  /// Select a tab by index and persist the selection
  Future<void> select(int tabIndex) async {
    assert(
      tabIndex >= TongtaiTabs.home && tabIndex <= TongtaiTabs.more,
      'Invalid tab index: $tabIndex',
    );
    state = tabIndex;

    // Persist the selection
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_prefsKey, tabIndex);
  }

  /// Reset to the home tab
  Future<void> reset() async {
    await select(TongtaiTabs.home);
  }
}

/// Provides the current tab name
final tongtaiCurrentTabNameProvider = Provider<String>((ref) {
  final tabIndex = ref.watch(tongtaiSelectedTabProvider);
  return getTabName(tabIndex);
});

/// Provides the current tab color
final tongtaiCurrentTabColorProvider = Provider((ref) {
  final tabIndex = ref.watch(tongtaiSelectedTabProvider);
  return getTabColor(tabIndex);
});
