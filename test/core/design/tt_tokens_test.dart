import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt_tokens.dart';

/// Design System v1.0 — WTM-363 (Epic WTM-362).
///
/// Hai luật ở đây không phải chuyện thẩm mỹ. Chúng là chuyện **nói thật bằng
/// màu**, và cả hai đều đã sai ít nhất một lần ở sản phẩm khác:
///
/// * **CAM ≠ AI** — tô câu kết luận màu hành động sẽ dạy người bán rằng chữ cam
///   nghĩa là "AI nói", rồi họ thôi bấm những nút thật sự bấm được.
/// * **XÁM ≠ XANH** — *"chưa đủ dữ liệu"* mang màu thành công là lời trấn an
///   cho điều chưa ai kiểm.
void main() {
  group('⛔ màu ngữ nghĩa nói đúng nghĩa của nó', () {
    test('CHƯA BIẾT không mang màu thành công', () {
      expect(TtStatus.unknown.color, isNot(TtStatus.success.color));
      expect(TtStatus.unknown.soft, isNot(TtStatus.success.soft));
    });

    test('CHƯA BIẾT là màu NHẠT NHẤT trong các mức', () {
      // Kiểm **tính chất tương đối**, không kiểm mã màu: đổi sang một sắc xám
      // khác vẫn hợp lệ, còn đổi sang thứ gì có sắc thái ngang một mức ngữ
      // nghĩa thì không.
      //
      // Ngưỡng tuyệt đối là cái bẫy: bản đầu của test này đặt 0.12 và đỏ ngay,
      // vì #94A3B8 của spec là xám *slate* — có thiên lam nhẹ, cố ý.
      double chroma(Color c) {
        final v = [c.r, c.g, c.b];
        return v.reduce((a, b) => a > b ? a : b) -
            v.reduce((a, b) => a < b ? a : b);
      }

      final unknown = chroma(TtStatus.unknown.color);
      for (final s in TtStatus.values) {
        if (s == TtStatus.unknown) continue;
        expect(
          unknown,
          lessThan(chroma(s.color)),
          reason:
              'unknown đậm sắc ngang ${s.name} ⇒ nó đang nói một điều gì '
              'đó về chất lượng, trong khi nghĩa của nó là CHƯA BIẾT',
        );
      }
    });

    test('AI và HÀNH ĐỘNG là hai màu khác nhau', () {
      // Nếu hai cái này trùng thì cả ngôn ngữ thị giác của sản phẩm sụp: không
      // còn cách nào phân biệt "Tổng Tài đang nói" với "bạn bấm được".
      expect(TtColors.ai, isNot(TtColors.brand));
      expect(TtStatus.ai.color, TtColors.ai);
    });

    test('mọi mức đều có màu và nền riêng, không mức nào rơi về mặc định', () {
      final colors = {for (final s in TtStatus.values) s.color};
      final softs = {for (final s in TtStatus.values) s.soft};
      expect(colors, hasLength(TtStatus.values.length));
      expect(softs, hasLength(TtStatus.values.length));
    });

    test('⭐ chống PASS giả — đảo hai màu thì test đầu tiên phải đỏ', () {
      // Tự chứng minh khẳng định trên có nội dung: nếu `unknown` và `success`
      // trỏ cùng một chỗ, phép so sánh kia sẽ thất bại.
      expect(
        TtColors.unknown == TtColors.success,
        isFalse,
        reason: 'hai token này phải là hai giá trị khác nhau',
      );
    });
  });

  group('thang giá trị đúng spec', () {
    test('bo góc theo directive §5', () {
      expect(TtRadius.xs, 6);
      expect(TtRadius.sm, 8);
      expect(TtRadius.md, 12); // nút, ô nhập
      expect(TtRadius.lg, 16); // thẻ tiêu chuẩn
      expect(TtRadius.xl, 20); // thẻ AI / hero
      expect(TtRadius.full, 999);
    });

    test('khoảng cách nằm trên lưới 4px', () {
      for (final v in [
        TtSpace.x1,
        TtSpace.x2,
        TtSpace.x3,
        TtSpace.x4,
        TtSpace.x5,
        TtSpace.x6,
        TtSpace.x8,
        TtSpace.x10,
        TtSpace.x12,
      ]) {
        expect(v % 4, 0, reason: '$v không nằm trên lưới 4px');
      }
    });

    test('chữ có đủ 12 vai, mỗi vai có line-height', () {
      final styles = <String, TextStyle>{
        'display': TtType.display,
        'h1': TtType.h1,
        'h2': TtType.h2,
        'h3': TtType.h3,
        'title': TtType.title,
        'bodyLarge': TtType.bodyLarge,
        'body': TtType.body,
        'bodyMedium': TtType.bodyMedium,
        'caption': TtType.caption,
        'label': TtType.label,
        'metricLarge': TtType.metricLarge,
        'metric': TtType.metric,
      };
      expect(styles, hasLength(12));
      for (final e in styles.entries) {
        expect(e.value.height, isNotNull, reason: e.key);
        expect(e.value.fontFamily, TtType.family, reason: e.key);
        // Dự phòng bắt buộc: tiếng Việt có dấu chồng, và một máy thiếu Inter mà
        // không có fallback sẽ dựng dấu bằng font mặc định trông rất khác.
        expect(e.value.fontFamilyFallback, isNotEmpty, reason: e.key);
      }
    });

    test('KPI đậm, thân bài thường — không phải cả UI đều đậm', () {
      expect(TtType.metricLarge.fontWeight, FontWeight.w700);
      expect(TtType.body.fontWeight, FontWeight.w400);
      expect(TtType.bodyLarge.fontWeight, FontWeight.w400);
    });

    test('mặc định KHÔNG đổ bóng', () {
      expect(TtElevation.none, isEmpty);
      expect(TtElevation.soft, hasLength(1));
      expect(TtElevation.floating, hasLength(1));
    });
  });

  group('⛔ governance · chuyển động không được là tiến trình giả', () {
    test('token chuyển động chỉ có ba mốc, không có "thời lượng loading"', () {
      // Một hằng số kiểu `loadingDuration` là chỗ để đặt một thanh chạy giả vào
      // ngày mai — §16 và §21 đều cấm.
      final code = File('lib/core/design/tt_tokens.dart')
          .readAsLinesSync()
          .where(
            (l) =>
                !l.trimLeft().startsWith('//') &&
                !l.trimLeft().startsWith('///'),
          )
          .join('\n');

      expect(code, contains('class TtMotion'));
      for (final banned in const [
        'loadingDuration',
        'progressDuration',
        'splashDuration',
        'fakeProgress',
      ]) {
        expect(code.contains(banned), isFalse, reason: banned);
      }
      expect(TtMotion.fast.inMilliseconds, 120);
      expect(TtMotion.normal.inMilliseconds, 200);
      expect(TtMotion.slow.inMilliseconds, 300);
    });
  });
}
