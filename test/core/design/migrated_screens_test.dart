import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';

/// **Màn đã migrate phải ở lại Design System** — WTM-369 (Epic WTM-362).
///
/// Migration tăng dần chỉ có nghĩa nếu phần đã đi không trôi ngược. Danh sách
/// dưới đây là hợp đồng: thêm một màn vào đây nghĩa là màn đó **không được**
/// quay lại màu viết thẳng hay token cũ.
///
/// Đây là lý do test này quét theo **danh sách đã migrate** chứ không quét cả
/// `ui/`: quét tất cả sẽ đỏ ngay vì ~40 màn chưa đi, và một suite đỏ thường
/// trực thì không ai đọc nữa.
void main() {
  /// Màn đã đưa về Design System, kèm story đã làm việc đó.
  const migrated = <String, String>{
    'tongtai_onboarding_v2_screen.dart': 'WTM-365',
    'tongtai_startup_screen.dart': 'WTM-367',
    'tongtai_home_screen.dart': 'WTM-369',
    'tongtai_producer_screen.dart': 'WTM-370',
    'tongtai_inventory_screen.dart': 'WTM-370',
    'tongtai_consumer_screen.dart': 'WTM-370',
    'tongtai_opportunity_feed_screen.dart': 'WTM-370',
  };

  /// Bỏ chú thích trước khi quét — một mã màu nhắc trong tài liệu không phải
  /// một mã màu đang được dùng.
  String codeOf(String file) => File('lib/features/tongtai/ui/screens/$file')
      .readAsLinesSync()
      .where(
        (l) =>
            !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'),
      )
      .join('\n');

  test('⭐ quét được mã nguồn thật (chống PASS giả)', () {
    for (final file in migrated.keys) {
      final code = codeOf(file);
      expect(code, isNotEmpty, reason: file);
      expect(
        code,
        contains('core/design/tt.dart'),
        reason: '$file chưa nhập Design System',
      );
    }
  });

  test('⛔ không màn nào đã migrate còn màu viết thẳng', () {
    for (final entry in migrated.entries) {
      expect(
        codeOf(entry.key).contains('Color(0x'),
        isFalse,
        reason:
            '${entry.key} (${entry.value}) có mã màu viết thẳng — một giá trị '
            'không ai sở hữu sẽ lệch khỏi mọi màn khác vào lần sửa sau',
      );
    }
  });

  test('⛔ không màn nào đã migrate còn dùng token thị giác cũ', () {
    for (final entry in migrated.entries) {
      final uses = RegExp(
        r'TongtaiDesignTokens\.(?!.*\bTongtaiTabs\b)[a-zA-Z]',
      ).allMatches(codeOf(entry.key));
      expect(
        uses,
        isEmpty,
        reason:
            '${entry.key} (${entry.value}) còn ${uses.length} chỗ dùng token cũ',
      );
    }
  });

  test('⛔ không màn nào tự viết switch màu theo mức khẩn', () {
    // `TtStatus` là chủ duy nhất của ánh xạ mức → màu. Hai bảng ánh xạ sẽ lệch
    // nhau đúng vào ngày ai đó sửa một bên (P-27/P-28).
    for (final entry in migrated.entries) {
      final code = codeOf(entry.key);
      final hasSeverityColourSwitch =
          code.contains('BriefSeverity.critical =>') &&
          code.contains('TtColors.danger');
      expect(
        hasSeverityColourSwitch,
        isFalse,
        reason: '${entry.key} ánh xạ mức khẩn sang màu tại chỗ — dùng TtStatus',
      );
    }
  });

  group('⭐ bảng ánh xạ chữ — theo GIÁ TRỊ, không theo tên', () {
    // ⚠️ Đây là lỗi đã xảy ra thật (WTM-370): phép thay tự động ánh xạ
    // `bodyStyle`→`body` và `heading2Style`→`h2` **theo tên**, và vì tên lệch
    // một bậc so với giá trị, mọi tiêu đề lẫn thân bài của bốn màn bị thu nhỏ.
    // Triệu chứng duy nhất lộ ra là một chỗ tràn **1 pixel** — suýt trôi qua.
    //
    // Nên bảng ánh xạ nay là mã chạy được, không phải một dòng trong tài liệu.
    const pairs = <String, (TextStyle, TextStyle)>{
      'bodyStyle → bodyLarge': (
        TongtaiDesignTokens.bodyStyle,
        TtType.bodyLarge,
      ),
      'smallStyle → body': (TongtaiDesignTokens.smallStyle, TtType.body),
      'captionStyle → caption': (
        TongtaiDesignTokens.captionStyle,
        TtType.caption,
      ),
      'heading1Style → display': (
        TongtaiDesignTokens.heading1Style,
        TtType.display,
      ),
    };

    test('cỡ chữ và line-height khớp hẳn', () {
      for (final e in pairs.entries) {
        final (legacy, ds) = e.value;
        expect(ds.fontSize, legacy.fontSize, reason: e.key);
        expect(
          ds.height! * ds.fontSize!,
          closeTo(legacy.height! * legacy.fontSize!, 0.01),
          reason: e.key,
        );
      }
    });

    test('hai cặp còn lại chỉ lệch ở weight/line-height, KHÔNG lệch cỡ', () {
      // `heading2Style` 24px → `h1` 24px · `heading3Style` 20px → `h2` 20px.
      // Cỡ chữ là thứ quyết định bố cục; weight và line-height lệch nhẹ chấp
      // nhận được, cỡ lệch thì không.
      expect(TtType.h1.fontSize, TongtaiDesignTokens.heading2Style.fontSize);
      expect(TtType.h2.fontSize, TongtaiDesignTokens.heading3Style.fontSize);
    });
  });

  test('danh sách đã migrate không có mục chết', () {
    for (final file in migrated.keys) {
      expect(
        File('lib/features/tongtai/ui/screens/$file').existsSync(),
        isTrue,
        reason: '$file không còn tồn tại — gỡ khỏi danh sách',
      );
    }
  });
}
