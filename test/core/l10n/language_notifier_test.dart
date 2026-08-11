import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/core/l10n/language_notifier.dart';

/// WTM-308 — **giao diện chỉ một locale**, và nó là tiếng Việt.
void main() {
  test('⛔ locale KHÔNG theo máy nữa — nó là hằng số', () {
    // Trước đây mặc định lấy ngôn ngữ máy, nên máy đặt tiếng Anh thì nhãn ra
    // tiếng Anh trong khi câu brief vẫn là dữ liệu tiếng Việt đã lưu. Mở app
    // trên một chiếc máy tiếng Anh là đọc được nửa này nửa kia.
    expect(kAppLocaleCode, 'vi');
    expect(kAppLocale.languageCode, 'vi');
  });

  test('bộ chuỗi tiếng Anh GIỮ NGUYÊN trong mã, chỉ không được tự chọn', () {
    // Ngày thêm một thị trường là một quyết định sản phẩm thật; lúc đó bộ chuỗi
    // đã sẵn ở đây. Cái bị bỏ là việc để máy chọn hộ.
    const en = AppStringsEn();
    const vi = AppStringsVi();
    expect(en.languageCode, 'en');
    expect(vi.languageCode, 'vi');
    expect(en.actionCancel, isNotEmpty);
  });
}
