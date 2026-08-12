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

  test('sắc của primary nằm ở vùng cam — ⚠️ CHỈ bắt được đổi SẮC', () {
    // ⚠️ **Đọc kỹ giới hạn của test này trước khi tin nó.**
    //
    // Nó bắt được *"ai đó gieo lại bằng xanh lá"* (sắc 130°). Nó **KHÔNG** bắt
    // được lỗi WTM-380 — nâu đất `#8D4E2A` mà `fromSeed` sinh ra có sắc
    // **21,8°**, tức **nằm gọn trong khoảng 5–55 này**, nên test vẫn xanh
    // trong khi hộp thoại trên máy màu nâu.
    //
    // Khác biệt thật giữa nâu và cam không nằm ở sắc mà ở **độ bão hoà**:
    // 0,541 so với 0,883. Khẳng định của test thuộc một trục, còn cái hỏng
    // thuộc trục khác — nên nó đúng mà vô dụng.
    //
    // Cửa thật sự bảo vệ là test dưới (`primary == brandOnDark`) và ca âm tính
    // ở cuối file. Dòng này ở lại vì nó vẫn rẻ và vẫn bắt được một dạng lỗi —
    // nhưng nó **không** phải cái đang giữ cửa.
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

  test('⭐ vai NHÌN THẤY ĐƯỢC đến từ token DS, không phải thang tông M3', () {
    // ⚠️ Lỗi tìm thấy trên Nokia 6.1 (WTM-380): `fromSeed` **không giữ** màu
    // hạt giống — nó sinh một thang tông và lấy một bậc tối làm `primary`, rồi
    // nhuộm `surface` theo sắc hạt giống. Kết quả trên máy thật: hộp thoại nền
    // **kem**, nút chính màu **nâu đất**, trong khi Design System nói cam.
    //
    // WTM-379 không bắt được vì nó chỉ hỏi *"primary có ở vùng cam không"* —
    // mà nâu đất **vẫn ở vùng cam**. Đây là cửa chặt hơn: đúng token, không
    // phải đúng vùng sắc.
    expect(scheme.primary, TtColors.brandOnDark, reason: 'primary');
    expect(scheme.onPrimary, TtColors.textOnBrand, reason: 'onPrimary');
    expect(scheme.surface, TtColors.surface, reason: 'surface phải TRẮNG');
    expect(scheme.onSurface, TtColors.textPrimary, reason: 'onSurface');
    expect(scheme.error, TtColors.dangerOnLight, reason: 'error');
  });

  test('⛔ bề mặt nổi KHÔNG bị lớp phủ tông màu M3 nhuộm kem', () {
    // `surfaceTint` là đúng thứ biến một thẻ trắng thành thẻ kem khi nó được
    // nâng lên — vô hình trong test widget, rất rõ trên máy.
    expect(tongtaiTheme.dialogTheme.backgroundColor, TtColors.surface);
    expect(tongtaiTheme.dialogTheme.surfaceTintColor, Colors.transparent);
    expect(tongtaiTheme.cardTheme.surfaceTintColor, Colors.transparent);
    expect(tongtaiTheme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
    expect(tongtaiTheme.appBarTheme.surfaceTintColor, Colors.transparent);
    expect(tongtaiTheme.popupMenuTheme.surfaceTintColor, Colors.transparent);
  });

  test('⛔ điều khiển bật/tắt mang CAM = hành động, không phải nâu', () {
    const on = <WidgetState>{WidgetState.selected};
    expect(
      tongtaiTheme.switchTheme.trackColor!.resolve(on),
      TtColors.brandOnDark,
    );
    expect(
      tongtaiTheme.checkboxTheme.fillColor!.resolve(on),
      TtColors.brandOnDark,
    );
    expect(
      tongtaiTheme.radioTheme.fillColor!.resolve(on),
      TtColors.brandOnDark,
    );
    expect(tongtaiTheme.progressIndicatorTheme.color, TtColors.brandOnDark);
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

  group('⭐ ca ÂM TÍNH — chính màu đã lên máy sáng 12/08', () {
    // Cách duy nhất biết một chốt có đo đúng thứ cần đo: **đưa cho nó đúng cái
    // đã hỏng** và xem nó có đỏ không.
    //
    // `#8D4E2A` không phải màu nghĩ ra: đó là `ColorScheme.fromSeed(brand)
    // .primary` — thứ Material sinh ra và thứ người dùng nhìn thấy trên nút
    // *"Nạp mẫu"* trước WTM-380.
    final brown = ColorScheme.fromSeed(seedColor: TtColors.brand).primary;

    test('màu nâu ấy KHÁC token DS ⇒ cửa hiện tại đỏ với nó', () {
      expect(
        scheme.primary,
        isNot(brown),
        reason: 'theme đang mang chính màu nâu của lỗi WTM-380',
      );
      expect(scheme.primary, TtColors.brandOnDark);
    });

    test('⚠️ và ĐÂY là lý do khoá theo sắc là chưa đủ', () {
      // Ghi lại phép đo, không phải một lời khẳng định suông: nếu Material đổi
      // thuật toán tông màu, con số này đổi và ai đó sẽ phải đọc lại đoạn văn
      // ở đầu file thay vì tin nó.
      final h = HSLColor.fromColor(brown);
      expect(
        h.hue,
        inInclusiveRange(5, 55),
        reason: 'nâu đất VẪN nằm trong vùng sắc "cam" — nên sắc không cứu được',
      );
      expect(
        h.saturation,
        lessThan(HSLColor.fromColor(TtColors.brandOnDark).saturation - 0.2),
        reason: 'khác biệt thật nằm ở độ bão hoà, không ở sắc',
      );
    });
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
