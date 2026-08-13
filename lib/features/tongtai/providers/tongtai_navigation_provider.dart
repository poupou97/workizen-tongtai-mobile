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
    final saved = prefs.getInt(_prefsKey) ?? _defaultTab;
    // ⭐ WTM-405 — kẹp về khoảng hợp lệ khi ĐỌC, không chỉ khi ghi.
    //
    // Giá trị này sống trong SharedPreferences qua các lần cài đặt, nên nó có
    // thể **cũ hơn thanh nav hiện tại**. `assert` ở `select()` chỉ chạy trong
    // bản debug và chỉ canh đường GHI — một chỉ số lạc từ bản trước đi thẳng
    // vào `IndexedStack` và làm sập app ở bản release, ngay lần mở đầu tiên,
    // trước cả khi người dùng chạm được gì.
    //
    // Chưa xảy ra vì thanh mới chỉ dài thêm. Lần thanh **ngắn lại** thì nó xảy
    // ra — và đó là kiểu lỗi chỉ gặp ở người đã dùng app từ trước, tức đúng
    // những người ít bị test chạm tới nhất.
    if (saved < TongtaiTabs.home || saved >= TongtaiTabs.count) {
      return _defaultTab;
    }
    return saved;
  }

  /// Select a tab by index and persist the selection
  Future<void> select(int tabIndex) async {
    assert(
      tabIndex >= TongtaiTabs.home && tabIndex < TongtaiTabs.count,
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
