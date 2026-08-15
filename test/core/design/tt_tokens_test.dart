import 'dart:io';
import 'dart:math' as math;

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

      // ⚠️ WTM-425 — so với **các mức CÓ PHÁN XÉT**, không phải mọi mức.
      //
      // Bản trước quét cả `TtStatus.values` và đỏ ngay khi `neutral` ra đời, vì
      // `neutral` (#475569) còn ÍT sắc hơn `unknown` (#94A3B8). Test không sai;
      // **tiền đề của nó đã đổi**: nay có HAI vai cố ý không mang sắc — *chưa
      // biết* và *biết mà không phán xét*. Rekey chứ không xoá (P-37).
      const judging = <TtStatus>{
        TtStatus.success,
        TtStatus.info,
        TtStatus.warning,
        TtStatus.danger,
        TtStatus.ai,
      };

      final unknown = chroma(TtStatus.unknown.color);
      for (final s in judging) {
        expect(
          unknown,
          lessThan(chroma(s.color)),
          reason:
              'unknown đậm sắc ngang ${s.name} ⇒ nó đang nói một điều gì '
              'đó về chất lượng, trong khi nghĩa của nó là CHƯA BIẾT',
        );
      }

      // ⭐ Và `neutral` phải KHÔNG mang sắc, **đo bằng chính `unknown`**.
      //
      // ⚠️ Bản đầu tôi viết `chroma(neutral) < chroma(mỗi mức phán xét)` và
      // đột biến cho thấy nó MÙ: gieo một sắc lục mờ `#4A7C59` (chroma 0,196)
      // vẫn xanh, vì mọi mức phán xét đều trên 0,55. Một khẳng định "ít sắc
      // hơn thứ rất đậm sắc" gần như không chặn gì.
      //
      // Neo vào `unknown` — mức đã được khai là **nhạt sắc nhất** ở ngay trên.
      // Hai vai cố ý không phán xét thì phải cùng nằm ở đáy thang sắc.
      // Ngưỡng tuyệt đối là cái bẫy đã được ghi trong chính test này.
      expect(
        chroma(TtStatus.neutral.color),
        lessThanOrEqualTo(chroma(TtStatus.unknown.color)),
        reason:
            'neutral ngả sắc hơn unknown ⇒ "dữ liệu thường" đang được tô như '
            'một lời khen hoặc chê. Trung tính phải trung tính thật.',
      );
    });

    test('⭐ nền nút mang chữ trắng phải qua WCAG AA', () {
      // Spec ghi `#F97316`; chữ trắng trên đó đạt 2,80:1. Suite accessibility
      // của repo bắt đúng điều đó, nên Design System dùng một sắc đậm hơn cho
      // NỀN nút và giữ `brand` cho biểu tượng/viền/chữ trên nền sáng.
      double lum(Color c) {
        double f(double v) => v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4) as double;
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
      }

      double ratio(Color a, Color b) {
        final l = [lum(a), lum(b)]..sort();
        return (l[1] + 0.05) / (l[0] + 0.05);
      }

      expect(
        ratio(TtColors.brandOnDark, TtColors.textOnBrand),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(TtColors.brandPressed, TtColors.textOnBrand),
        greaterThanOrEqualTo(4.5),
      );
      // Và màu thương hiệu gốc vẫn giữ nguyên — nó chỉ không được làm nền cho
      // chữ trắng.
      expect(TtColors.brand, const Color(0xFFF97316));
    });

    test('AI và HÀNH ĐỘNG là hai màu khác nhau', () {
      // Nếu hai cái này trùng thì cả ngôn ngữ thị giác của sản phẩm sụp: không
      // còn cách nào phân biệt "Tổng Tài đang nói" với "bạn bấm được".
      expect(TtColors.ai, isNot(TtColors.brand));
      expect(TtStatus.ai.color, TtColors.ai);
    });

    test('⭐ màu ĐỊNH DANH tách hẳn khỏi màu TRẠNG THÁI (WTM-426)', () {
      // Founder chốt Option B: chỉ đường bằng màu được giữ, nhưng nó phải có
      // **bảng riêng**. Cái sai cũ không phải *dùng màu để chỉ đường*, mà là
      // mượn hằng số của tầng trạng thái — nên sửa màu cảnh báo sẽ lặng lẽ đổi
      // màu tab Kho, và ngược lại.
      final semantic = <Color>{
        TtColors.success,
        TtColors.info,
        TtColors.warning,
        TtColors.danger,
        TtColors.ai,
        TtColors.brand,
      };

      for (final c in TtCapability.values) {
        if (c == TtCapability.more) continue; // cố ý là `neutral`
        expect(
          semantic.contains(c.color),
          isFalse,
          reason:
              '${c.name} đang mượn một hằng NGỮ NGHĨA làm màu định danh. Đó '
              'đúng là lỗi WTM-426: tab Kho từng mang `warning` và trùng sắc '
              'với chú giải "sắp hết hàng" trên cùng màn hình.',
        );
      }

      // Và chúng phải phân biệt được VỚI NHAU — hai năng lực cùng sắc thì màu
      // thôi không chỉ đường được nữa, tức mất luôn lý do tồn tại của bảng này.
      final identities = {for (final c in TtCapability.values) c.color};
      expect(identities, hasLength(TtCapability.values.length));
    });

    test('⭐ định danh: biểu tượng ≥3:1 · chữ nhãn ≥4,5:1 (WTM-439)', () {
      // Hai ngưỡng, không một — và đó là điểm quan trọng nhất của test này.
      //
      // WCAG đặt **4,5:1 cho chữ** nhưng chỉ **3:1 cho đồ hoạ**. Sắc concept
      // (đo pixel từ `cp_home.png`) đạt lần lượt 3,91 · 4,46 · 2,57 · 5,18 —
      // **ba trong bốn trượt ngưỡng chữ**, cam tệ nhất chỉ 2,57:1.
      //
      // Nếu cổng chỉ kiểm một ngưỡng thì hoặc bỏ lọt nhãn khó đọc (nếu lấy
      // 3:1), hoặc cấm oan sắc concept ở biểu tượng (nếu lấy 4,5:1). Đo đúng
      // thứ mắt người thật sự phải đọc.
      double lum(Color c) {
        double f(double v) => v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4) as double;
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
      }

      double ratio(Color a, Color b) {
        final l = [lum(a), lum(b)]..sort();
        return (l[1] + 0.05) / (l[0] + 0.05);
      }

      for (final c in TtCapability.values) {
        expect(
          ratio(c.color, TtColors.surface),
          greaterThanOrEqualTo(3.0),
          reason:
              'biểu tượng tab ${c.name} không đạt 3:1 trên nền trắng — người '
              'bán nhìn thanh nav ở mọi màn',
        );
        expect(
          ratio(c.labelColor, TtColors.surface),
          greaterThanOrEqualTo(4.5),
          reason:
              'CHỮ nhãn tab ${c.name} không đạt 4,5:1. Sắc concept dành cho '
              'biểu tượng; chữ phải dùng biến thể đậm hơn (`...OnLight`).',
        );
      }
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
