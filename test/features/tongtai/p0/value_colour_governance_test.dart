// P0 — **màu định vị không được tô lên một con số** (WTM-407, luật Founder A2).
//
// ## Luật
//
// `PURPLE = AI · ORANGE = ACTION · GREEN = POSITIVE · BLUE = INFO ·
//  AMBER = ATTENTION · RED = CRITICAL · GRAY = UNKNOWN`
//
// Founder A2, 2026-08-12: **màu thương hiệu / định vị tuyệt đối không được dùng
// để biểu diễn trạng thái hay giá trị.** Chúng chỉ để *chỉ đường* — thanh nav,
// ô biểu tượng.
//
// ## Lỗi này đã tái diễn HAI lần
//
// - **WTM-389** (Home): ô *"Nguồn hàng **0**"* tô **xanh lá** vì xanh lá là màu
//   Nguồn hàng ⇒ một con số không đọc ra "tin tốt".
// - **WTM-407** (Khách hàng): `75 / 0 / 4` và huy hiệu `82` tô **xanh dương**;
//   `VIP 0` mặc màu INFO. Sau WTM-404, Home nói *"con số trung tính"* còn màn
//   này nói *"con số màu xanh"* — hai bề mặt, hai luật màu.
//
// Hai lần cùng một hình dạng ⇒ nó cần một **cổng cơ học**, không cần thêm một
// đoạn văn hay hơn.
//
// ## Cổng này canh CÁI GÌ
//
// Không canh pixel — canh **hình dạng API**: một widget hiện con số **không
// được nhận một tham số `Color` từ phía gọi**. Còn tham số thì lần sau ai đó sẽ
// truyền màu năng lực vào, và không có gì đỏ lên.
//
// Đó cũng là cách `TtMetricCard` (WTM-404) giải: phơi ra `TtValueTone` hai giá
// trị (`neutral`/`critical`) thay vì một `Color`. Chọn được sắc thái **ngữ
// nghĩa**, không chọn được màu tuỳ ý.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Các widget **hiện con số** đã bị bắt tô màu định vị, hoặc cùng hình dạng.
const _valueWidgets = <String, String>{
  'lib/features/tongtai/ui/screens/tongtai_consumer_screen.dart':
      '_CustomerStat|_LifecycleStage',
};

void main() {
  test('⭐ widget hiện con số KHÔNG nhận tham số Color từ phía gọi', () {
    final offenders = <String>[];

    for (final entry in _valueWidgets.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final name in entry.value.split('|')) {
        final start = source.indexOf('class $name extends');
        expect(
          start,
          isNot(-1),
          reason:
              '$name không còn trong ${entry.key} — nếu đã đổi tên, cập nhật '
              'danh sách này; nếu đã xoá, bỏ khỏi danh sách. ⛔ Đừng xoá cổng.',
        );
        // Thân lớp tới `build(` — vùng khai báo trường + hàm dựng.
        final buildAt = source.indexOf('Widget build(', start);
        final head = source.substring(start, buildAt == -1 ? null : buildAt);
        if (RegExp(r'\bfinal\s+Color[?\s]').hasMatch(head)) {
          offenders.add(
            '${entry.key}: $name nhận một tham số Color — phía gọi sẽ truyền '
            'màu năng lực vào một con số (A2 · WTM-389 · WTM-407)',
          );
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('màn Khách hàng KHÔNG còn hằng màu năng lực để tiện tay dùng lại', () {
    // Bỏ *dùng* mà giữ *hằng* thì cái bình vẫn còn đó. WTM-407 xoá hẳn
    // `static const _blue = TtColors.info;`.
    final source = File(
      'lib/features/tongtai/ui/screens/tongtai_consumer_screen.dart',
    ).readAsStringSync();
    expect(
      RegExp(r'static\s+const\s+_blue\s*=').hasMatch(source),
      isFalse,
      reason: 'hằng `_blue` quay lại — con số tiếp theo sẽ được tô bằng nó',
    );
  });
}
