// WTM-405/406 — chỉ số tab đã lưu phải được KẸP khi đọc.
//
// ## Đây là một sự cố ĐÃ XẢY RA trên máy thật, không phải một tình huống nghĩ ra
//
// 2026-08-13, Nokia 6.1: cài bản có **6 tab**, chạm "Thêm" (index 5), rồi cài
// đè một bản dựng **cũ hơn chỉ có 5 tab**. App mở lên là **màn đỏ**:
//
//     'package:flutter/src/widgets/indexed_stack.dart': Failed assertion:
//     'index == null || … (index >= 0 && index < children.length)'
//
// `run-as … cat shared_prefs/FlutterSharedPreferences.xml` xác nhận:
//     tongtai_selected_tab" value="5"
//
// Không cú chạm nào cứu được — nó sập **trước khi** người dùng chạm được gì.
//
// ## Vì sao `assert` trong `select()` không bắt được
//
// Nó canh đường **GHI**, và chỉ chạy ở bản **debug**. Giá trị hỏng đi vào từ
// đường **ĐỌC** — nó đã nằm sẵn trong SharedPreferences từ một lần cài trước,
// và ở bản release thì `assert` bị gỡ bỏ hoàn toàn. Cùng họ P-31 (*"thêm trường
// xong nửa dưới — đường GHI vẫn viết bằng mô hình cũ"*), chỉ đảo chiều.
//
// ## Ai gặp
//
// Người **đã dùng app từ trước** — nhóm ít bị test chạm tới nhất, và là nhóm
// duy nhất có một giá trị cũ trong máy.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_navigation_provider.dart';

Future<ProviderContainer> containerWithTab(Object? saved) async {
  SharedPreferences.setMockInitialValues(
    saved == null ? {} : {'tongtai_selected_tab': saved},
  );
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('⭐ chỉ số vượt số tab hiện có ⇒ về Trang chủ, KHÔNG sập', () async {
    // Đúng giá trị đọc được từ máy Founder lúc sập: 5, trên bản chỉ có 5 tab.
    final c = await containerWithTab(TongtaiTabs.count);
    expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
  });

  test('chỉ số âm ⇒ về Trang chủ', () async {
    final c = await containerWithTab(-1);
    expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
  });

  test('chỉ số xa ngoài khoảng ⇒ về Trang chủ', () async {
    final c = await containerWithTab(99);
    expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
  });

  test(
    'mọi chỉ số HỢP LỆ được giữ nguyên — kẹp không được nuốt cái đúng',
    () async {
      // Không có ca này thì `return TongtaiTabs.home;` vô điều kiện cũng xanh, và
      // app sẽ **quên** tab người dùng đang xem ở mọi lần mở — một lỗi im lặng
      // thay cho một lỗi ồn ào.
      for (var tab = TongtaiTabs.home; tab < TongtaiTabs.count; tab++) {
        final c = await containerWithTab(tab);
        expect(c.read(tongtaiSelectedTabProvider), tab, reason: 'tab $tab');
      }
    },
  );

  test('chưa lưu gì ⇒ Trang chủ', () async {
    final c = await containerWithTab(null);
    expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
  });

  test(
    'mục cuối cùng của thanh LÀ hợp lệ — biên trên không lệch một đơn vị',
    () async {
      // `<= count` thay vì `< count` để lọt đúng chỉ số đã gây sập.
      final c = await containerWithTab(TongtaiTabs.count - 1);
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.count - 1);
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.more);
    },
  );
}
