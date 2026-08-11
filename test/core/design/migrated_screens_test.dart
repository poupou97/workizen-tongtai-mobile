import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';

/// **Ngôn ngữ thị giác không được trôi ngược** — Epic WTM-362.
///
/// ## Suite này từng là một danh sách, và nay không còn là
///
/// Từ WTM-369 đến WTM-374 nó quét theo **danh sách màn đã migrate**, vì lúc ấy
/// ~40 màn chưa đi và quét cả `ui/` sẽ đỏ thường trực — mà một suite đỏ thường
/// trực thì không ai đọc nữa.
///
/// WTM-375 đóng nốt phần còn lại, nên danh sách ấy **hết lý do tồn tại** và trở
/// thành một lỗ: thêm một màn mới mà quên khai thì không gì đỏ cả. Nay nó quét
/// **cả thư mục**, và thứ phải khai là **ngoại lệ** — kèm lý do.
///
/// Đó là chiều đúng: quên khai một màn mới thì test đỏ, chứ không im lặng.
void main() {
  const uiDir = 'lib/features/tongtai/ui';

  /// Màn giữ một bảng màu **mang nghĩa riêng**, không phải màu vô chủ.
  ///
  /// Ép chúng vào khe ngữ nghĩa của Design System sẽ **mất** đúng thứ chúng
  /// đang nói. Chuyển là một quyết định sản phẩm riêng, không phải một phép
  /// thay — nên chúng đứng đây, có tên và có lý do, thay vì im lặng.
  const ownPalette = <String, String>{
    'tongtai_business_life_screen.dart': 'bảng màu chủ thể (WTM-338)',
    'tongtai_conversations_screen.dart': 'bảng màu chủ thể (WTM-338)',
    'tongtai_conversation_screen.dart': 'bảng màu chủ thể (WTM-338)',
    'tongtai_customer_list_screen.dart': 'thang hạng khách vàng/đồng (WTM-75)',
    'tongtai_connections_screen.dart': 'tím demo-connected (WTM-340)',
  };

  /// Thành viên `TongtaiDesignTokens` **không phải màu** nên còn dùng được.
  ///
  /// Luật là *"một chủ cho mỗi màu"*, không phải *"cấm nhắc tên file cũ"*.
  const legacyNonColour = <String>{'navBarIconSize'};

  /// Bỏ chú thích trước khi quét — một mã màu nhắc trong tài liệu không phải
  /// một mã màu đang được dùng.
  String codeOf(File f) => f
      .readAsLinesSync()
      .where(
        (l) =>
            !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'),
      )
      .join('\n');

  List<File> uiFiles() => Directory(uiDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String nameOf(File f) => f.uri.pathSegments.last;

  test('⭐ quét được mã nguồn thật (chống PASS giả)', () {
    // Nếu đường dẫn sai hay bộ lọc hỏng, mọi test dưới sẽ PASS trên một danh
    // sách rỗng. Cửa này bắt đúng cái đó.
    final files = uiFiles();
    expect(files.length, greaterThan(40), reason: 'quét hụt $uiDir');
    expect(
      files.map(codeOf).where((c) => c.contains('TtColors.')).length,
      greaterThan(30),
      reason: 'đọc được file nhưng không thấy Design System đâu',
    );
  });

  test('ngoại lệ phải là màn có thật', () {
    for (final name in ownPalette.keys) {
      expect(
        File('$uiDir/screens/$name').existsSync(),
        isTrue,
        reason: '$name không còn tồn tại — gỡ khỏi danh sách ngoại lệ',
      );
    }
  });

  test('⛔ không màu viết thẳng ngoài các bảng màu đã khai', () {
    for (final f in uiFiles()) {
      if (ownPalette.containsKey(nameOf(f))) continue;
      expect(
        codeOf(f).contains('Color(0x'),
        isFalse,
        reason:
            '${nameOf(f)} có mã màu viết thẳng — một giá trị không ai sở hữu '
            'sẽ lệch khỏi mọi màn khác vào lần sửa sau',
      );
    }
  });

  test('⛔ không ai còn dùng token MÀU cũ', () {
    final uses = RegExp(r'TongtaiDesignTokens\.([a-zA-Z]+)');
    for (final f in uiFiles()) {
      for (final m in uses.allMatches(codeOf(f))) {
        expect(
          legacyNonColour.contains(m.group(1)),
          isTrue,
          reason: '${nameOf(f)} còn dùng TongtaiDesignTokens.${m.group(1)}',
        );
      }
    }
  });

  test('⛔ không màn nào tự viết switch màu theo mức khẩn', () {
    // `TtStatus` là chủ duy nhất của ánh xạ mức → màu. Hai bảng ánh xạ sẽ lệch
    // nhau đúng vào ngày ai đó sửa một bên (P-27/P-28).
    for (final f in uiFiles()) {
      final code = codeOf(f);
      expect(
        code.contains('BriefSeverity.critical =>') &&
            code.contains('TtColors.danger'),
        isFalse,
        reason: '${nameOf(f)} ánh xạ mức khẩn sang màu tại chỗ — dùng TtStatus',
      );
    }
  });

  test('⛔ nút đặc KHÔNG tự sơn — nó đến từ catalog', () {
    // ⚠️ Lỗi tìm thấy khi làm WTM-374: **cùng một nút Lưu mang năm màu khác
    // nhau** tuỳ màn — hổ phách ở sản phẩm, xanh dương ở khách, tím ở mục tiêu
    // và giao dịch, mặc định ở nguồn đầu vào. Di sản của bảng màu-theo-năng-lực
    // cũ: mỗi form ăn theo màu của capability chứa nó.
    //
    // Luật không phải *"nút chính luôn cam"* — mà là **một nút không mượn nghĩa
    // nó không có**. `Lưu` màu tím nói *AI đang làm*; `Quan tâm` màu xanh lá
    // nói *đã thành công*, trong khi nó là hành động **chưa xảy ra**.
    //
    // Nút đỏ của *"Khôi phục = Thay thế"* thì đúng là đỏ — nên nó là một loại
    // riêng (`TtDangerButton`), không phải một `FilledButton` ai đó tự sơn. Vì
    // vậy test này cấm **mọi** lời tự sơn, không chỉ vài màu.
    for (final f in uiFiles()) {
      final code = codeOf(f);
      for (var i = 0; i < code.length;) {
        final at = code.indexOf('FilledButton.styleFrom(', i);
        if (at < 0) break;
        final block = code.substring(at, (at + 260).clamp(0, code.length));
        expect(
          block.contains('backgroundColor:'),
          isFalse,
          reason:
              '${nameOf(f)} tự sơn nền một nút đặc — dùng TtPrimaryButton / '
              'TtDangerButton / TtAiActionButton',
        );
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

    test('⛔ không ai gọi hàm khi đối số là hằng', () {
      // Gọi hàm ở đây không sai *hôm nay* — nó sai vào ngày ai đó bọc chỗ ấy
      // trong `const`. Chặn ở đây rẻ hơn sửa lúc build đỏ.
      for (final f in uiFiles()) {
        for (final name in fixed.keys) {
          expect(
            codeOf(f).contains('readableOn(TtColors.$name)'),
            isFalse,
            reason:
                '${nameOf(f)} gọi readableOn(TtColors.$name) — dùng biến thể '
                'hằng',
          );
        }
      }
    });
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
}
