import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
