import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt.dart';

/// **Hạt giống theme** — WTM-379 (Epic WTM-362).
///
/// ## Vì sao suite này tồn tại
///
/// WTM-375 đổi `ColorScheme.fromSeed` từ `producerGreen` sang **cam thương
/// hiệu**. Đó là thay đổi **rộng nhất** của cả Epic: mọi widget Material không
/// được tạo kiểu riêng — hộp thoại, công tắc, ô đánh dấu, tay kéo chọn chữ,
/// snackbar, nút mặc định — đều lấy màu từ đó.
///
/// Và **không có gì canh nó**. 2686 test xanh không biết hạt giống là màu gì;
/// chỉ mắt người trên máy thật mới thấy được nó đổi. Suite này biến thứ chỉ mắt
/// người thấy thành thứ test thấy.
///
/// Nó **không thay được** dogfood máy thật (WTM-321) — nó chỉ chặn đường trôi
/// ngược, và nói rõ mình chặn được đến đâu.
void main() {
  /// Tỉ lệ tương phản WCAG giữa hai màu (1.0 … 21.0).
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Lược đồ màu **app thật đang dùng**, không phải một lược đồ dựng trong
  /// test.
  ///
  /// `tongtaiTheme` là chính đối tượng `main.dart` truyền cho `MaterialApp`,
  /// nên đổi hạt giống ở đó là suite này đỏ ngay — nó không được gọi lại
  /// `fromSeed` bằng tay ở đây.
  final scheme = tongtaiTheme.colorScheme;

  test('⛔ hạt giống là CAM thương hiệu, không phải xanh lá', () {
    // `fromSeed` không giữ nguyên hạt giống, nên không so bằng nhau được. Thứ
    // so được — và cũng là thứ có nghĩa — là **sắc**: một lược đồ gieo từ cam
    // không thể có primary nằm ở vùng xanh lá.
    final hue = HSLColor.fromColor(scheme.primary).hue;
    expect(
      hue,
      inInclusiveRange(5, 55),
      reason:
          'primary lệch khỏi vùng cam (sắc $hue°) — hạt giống có thể đã bị đổi. '
          'Cam = HÀNH ĐỘNG; gieo bằng xanh lá là cả app ngầm nói "thành công" '
          'ở mọi chỗ chưa ai sơn tay (WTM-375)',
    );
  });

  test('⛔ primary mặc định KHÔNG trùng khe ngữ nghĩa nào', () {
    // Nếu `primary` rơi trùng `success`, một hộp thoại **mặc định** sẽ ngầm nói
    // *"thành công"* — đúng lỗi WTM-375 phải dọn, chỉ khác chỗ nó nấp.
    for (final semantic in <String, Color>{
      'success': TtColors.success,
      'info': TtColors.info,
      'danger': TtColors.danger,
      'ai': TtColors.ai,
    }.entries) {
      expect(
        scheme.primary.toARGB32(),
        isNot(semantic.value.toARGB32()),
        reason: 'primary trùng TtColors.${semantic.key}',
      );
    }
  });

  test('vai chính của lược đồ đọc được trên nền của chính nó', () {
    // 4,5:1 — WCAG AA cho chữ thường. Người bán đọc điện thoại giữa trưa nắng
    // đúng là người con số này nói về.
    final pairs = <String, (Color, Color)>{
      'onPrimary/primary': (scheme.onPrimary, scheme.primary),
      'onSurface/surface': (scheme.onSurface, scheme.surface),
      'onError/error': (scheme.onError, scheme.error),
      'onSecondaryContainer/secondaryContainer': (
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
    };
    for (final pair in pairs.entries) {
      final (fg, bg) = pair.value;
      expect(
        contrast(fg, bg),
        greaterThanOrEqualTo(4.5),
        reason: '${pair.key} chỉ đạt ${contrast(fg, bg).toStringAsFixed(2)}:1',
      );
    }
  });

  test('⭐ phép đo tương phản tự nó đúng (chống PASS giả)', () {
    // Nếu công thức sai, ba test trên PASS trên mọi bảng màu. Hai mốc đã biết:
    // đen trên trắng = 21:1, và một màu với chính nó = 1:1.
    expect(
      contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(contrast(TtColors.brand, TtColors.brand), closeTo(1, 0.001));
    // Và mốc đã biết của repo này: trắng trên `brand` KHÔNG đạt — đó là lý do
    // `brandOnDark` tồn tại (WTM-366).
    expect(contrast(Colors.white, TtColors.brand), lessThan(4.5));
    expect(
      contrast(TtColors.textOnBrand, TtColors.brandOnDark),
      greaterThanOrEqualTo(4.5),
    );
  });
}
