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
    'tongtai_reports_screen.dart': 'WTM-371',
    'tongtai_finance_screen.dart': 'WTM-371',
    'tongtai_supplier_detail_screen.dart': 'WTM-371',
    'tongtai_customer_risk_screen.dart': 'WTM-371',
    'tongtai_customer_history_screen.dart': 'WTM-371',
    'tongtai_opportunity_detail_screen.dart': 'WTM-371',
    'tongtai_journey_screen.dart': 'WTM-372',
    'tongtai_goals_screen.dart': 'WTM-372',
    'tongtai_brief_story_screen.dart': 'WTM-372',
    'tongtai_agent_screen.dart': 'WTM-372',
    'tongtai_import_screen.dart': 'WTM-373',
    'tongtai_stock_alerts_screen.dart': 'WTM-373',
    'tongtai_more_screen.dart': 'WTM-373',
    'tongtai_create_order_screen.dart': 'WTM-373',
    'tongtai_forecast_screen.dart': 'WTM-373',
    'tongtai_product_form_screen.dart': 'WTM-374',
    'tongtai_customer_form_screen.dart': 'WTM-374',
    'tongtai_goal_form_screen.dart': 'WTM-374',
    'tongtai_transaction_form_screen.dart': 'WTM-374',
    'tongtai_business_input_form_screen.dart': 'WTM-374',
    'tongtai_goal_detail_screen.dart': 'WTM-374',
    'tongtai_inventory_picker_screen.dart': 'WTM-374',
  };

  /// Màn **đã đi một nửa**: token thị giác đã sang Design System, nhưng còn một
  /// bảng màu riêng chưa chuyển.
  ///
  /// Ba màn dòng thời gian phân biệt **chủ thể** (người bán · nền tảng · khách)
  /// bằng màu — đó là một nghĩa thật, không phải màu vô chủ, và ép nó vào khe
  /// ngữ nghĩa của Design System sẽ **mất** đúng thứ nó đang nói. Chuyển bảng
  /// ấy là một quyết định sản phẩm riêng, không phải một phép thay.
  ///
  /// Khai ở đây thay vì im lặng: một màn đi nửa đường mà không ai ghi lại thì
  /// lần sau người ta tưởng nó đã xong.
  const partiallyMigrated = <String, String>{
    'tongtai_business_life_screen.dart': 'bảng màu chủ thể (WTM-338)',
    'tongtai_conversations_screen.dart': 'bảng màu chủ thể (WTM-338)',
    'tongtai_conversation_screen.dart': 'bảng màu chủ thể (WTM-338)',
    'tongtai_customer_list_screen.dart': 'thang hạng khách vàng/đồng (WTM-75)',
    'tongtai_connections_screen.dart': 'tím demo-connected (WTM-340)',
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

  test('màn đi nửa đường vẫn phải sạch token thị giác cũ', () {
    for (final entry in partiallyMigrated.entries) {
      final uses = RegExp(
        r'TongtaiDesignTokens\.[a-zA-Z]',
      ).allMatches(codeOf(entry.key));
      expect(
        uses,
        isEmpty,
        reason: '${entry.key} còn ${uses.length} chỗ dùng token cũ',
      );
    }
  });

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

  test('⛔ nút chính KHÔNG mượn màu ngữ nghĩa của thứ khác', () {
    // ⚠️ Lỗi tìm thấy khi làm WTM-374: **cùng một nút Lưu mang năm màu khác
    // nhau** tuỳ màn — hổ phách ở sản phẩm, xanh dương ở khách, tím ở mục tiêu
    // và giao dịch, mặc định ở nguồn đầu vào. Di sản của bảng màu-theo-năng-lực
    // cũ: mỗi form ăn theo màu của capability chứa nó.
    //
    // Dưới luật mới thì đó là nói sai: `Lưu` là **HÀNH ĐỘNG** nên nó phải cam.
    // Một nút *"Lưu giao dịch"* màu tím nói rằng **AI** đang làm việc này —
    // trong khi người bán mới là người làm. Đúng chỗ chỉ thị §Design System
    // gọi tên: *ORANGE ≠ AI*.
    //
    // Nút cam nằm trong `TtPrimaryButton`, nên test này bắt đúng thứ ngược lại:
    // một `FilledButton` **tự sơn** màu ngữ nghĩa.
    const stolen = [
      'ai',
      'aiOnLight',
      'info',
      'infoOnLight',
      'success',
      'successOnLight',
      'warning',
      'warningOnDark',
    ];
    for (final file in migrated.keys) {
      final code = codeOf(file);
      for (var i = 0; i < code.length;) {
        final at = code.indexOf('FilledButton.styleFrom(', i);
        if (at < 0) break;
        final block = code.substring(at, (at + 260).clamp(0, code.length));
        for (final name in stolen) {
          expect(
            block.contains('backgroundColor: TtColors.$name'),
            isFalse,
            reason:
                '$file sơn nút đặc bằng TtColors.$name — nút cam là '
                'TtPrimaryButton; màu ngữ nghĩa nói NGHĨA, không nói cấp bậc',
          );
        }
        i = at + 1;
      }
    }
  });

  group('⭐ `readableOn` với đối số cố định — dùng HẰNG, không gọi hàm', () {
    // ⚠️ Lỗi đã xảy ra thật (WTM-374): phép thay sinh ra
    // `TtColors.readableOn(TtColors.danger)` bên trong một widget `const`, và
    // build đỏ ngay — *"Methods can't be invoked in constant expressions"*.
    //
    // Đây là lỗi may mắn: nó gãy lúc biên dịch. Nhưng cách sửa đúng không phải
    // gỡ `const` đi — mà là dùng biến thể hằng, vì giá trị hai bên y hệt nhau.
    // Hai test dưới giữ cả hai vế của câu đó.
    const fixed = <String, (Color, Color)>{
      'success': (TtColors.success, TtColors.successOnLight),
      'info': (TtColors.info, TtColors.infoOnLight),
      'ai': (TtColors.ai, TtColors.aiOnLight),
      'danger': (TtColors.danger, TtColors.dangerOnLight),
    };

    test('hằng và hàm cho ra ĐÚNG một màu', () {
      for (final e in fixed.entries) {
        final (base, constant) = e.value;
        expect(TtColors.readableOn(base), constant, reason: e.key);
      }
    });

    test('⛔ không màn nào gọi hàm khi đối số là hằng', () {
      // Gọi hàm ở đây không sai *hôm nay* — nó sai vào ngày ai đó bọc chỗ ấy
      // trong `const`. Chặn ở đây rẻ hơn sửa lúc build đỏ.
      for (final file in migrated.keys) {
        for (final name in fixed.keys) {
          expect(
            codeOf(file).contains('readableOn(TtColors.$name)'),
            isFalse,
            reason: '$file gọi readableOn(TtColors.$name) — dùng biến thể hằng',
          );
        }
      }
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
