import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_segment.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';

/// **Phân khúc khách hàng** — WTM-381.
///
/// ⚠️ Lỗi tìm thấy trên **Nokia 6.1**, không phải trong suite: màn Khách hàng
/// hiện mười một chip, trộn tiếng Việt với mã máy (`new`, `one_time`,
/// `dormant`, `returning`, `vip`) — và *"Khách mới (6)"* đứng ngay cạnh
/// *"new (8)"*.
///
/// Cùng một phân khúc, hai tên, **hai con số**. Đó là Business Truth mâu thuẫn
/// trên một màn hình, không phải một lỗi hiển thị.
///
/// 2690 test xanh không thấy gì, vì không test nào hỏi *"thứ hiện ra có phải
/// chữ người đọc được không"*. Suite này hỏi đúng câu đó.
void main() {
  group('⛔ mã máy KHÔNG bao giờ tới mắt người bán', () {
    test('mọi mã canonical phân giải được và có nhãn tiếng Việt', () {
      for (final s in CustomerSegment.values) {
        expect(CustomerSegment.parse(s.code), s, reason: s.code);
        expect(s.labelVi, isNotEmpty, reason: s.code);
        expect(s.labelEn, isNotEmpty, reason: s.code);
      }
    });

    test('⭐ đúng năm mã đã thấy trên máy đều hiện thành chữ Việt', () {
      // Danh sách này chép từ ảnh chụp màn hình, không phải bịa ra cho đủ.
      const onDevice = ['new', 'one_time', 'vip', 'dormant', 'returning'];
      for (final raw in onDevice) {
        final label = CustomerSegment.display(raw, 'vi');
        expect(label, isNot(raw), reason: '$raw vẫn hiện nguyên mã máy');
        expect(
          RegExp(r'^[a-z_]+$').hasMatch(label),
          isFalse,
          reason: '$label trông vẫn như một mã máy',
        );
      }
    });

    test('⭐ "Khách mới" và "new" gộp làm MỘT — hết đếm đôi', () {
      // Đây là vế quan trọng nhất: không phải dịch cho đẹp, mà là **hợp nhất**
      // hai dòng đang nói cùng một chuyện bằng hai con số.
      expect(
        CustomerSegment.normalise('new'),
        CustomerSegment.normalise('Khách mới'),
      );
      expect(
        CustomerSegment.normalise('returning'),
        CustomerSegment.normalise('Khách quay lại'),
      );
      expect(
        CustomerSegment.normalise('churned'),
        CustomerSegment.normalise('Đã rời bỏ'),
      );
    });

    test('nhãn tiếng Việt CŨ vẫn phân giải được — dữ liệu đã seed tự lành', () {
      // Máy người dùng đang chứa nhãn hiển thị. Bắt họ nạp lại chỉ để sửa một
      // cái tên là đổi giá phải trả sang phía sai người.
      for (final s in CustomerSegment.values) {
        expect(CustomerSegment.parse(s.labelVi), s, reason: s.labelVi);
        expect(CustomerSegment.parse(s.labelVi.toUpperCase()), s);
      }
    });

    test('⛔ chuỗi người dùng tự đặt KHÔNG bị nuốt mất', () {
      // Im lặng bỏ đi một phân khúc người bán tự tạo còn tệ hơn in ra mã máy.
      const own = 'Khách sỉ chợ Bến Thành';
      expect(CustomerSegment.parse(own), isNull);
      expect(CustomerSegment.normalise(own), own);
      expect(CustomerSegment.display(own, 'vi'), own);
    });

    test('chuỗi rỗng không thành một phân khúc', () {
      expect(CustomerSegment.parse('   '), isNull);
      expect(CustomerSegment.parse(''), isNull);
    });
  });

  group('⛔ dữ liệu lưu xuống là MÃ, không phải nhãn (ADR-TON-018)', () {
    test('mọi hành vi của bộ sinh đều ánh xạ sang một phân khúc', () {
      for (final b in CustomerBehaviour.values) {
        expect(b.segment, isA<CustomerSegment>(), reason: b.name);
      }
    });

    test('⭐ bộ sinh KHÔNG còn ghi nhãn hiển thị xuống ổ đĩa', () {
      // Trước WTM-381: `segments: [plan.behaviour.labelVi]` — nhãn tiếng Việt
      // đi thẳng xuống SQLite và vào cả `.ttbk`.
      final code = File(
        'lib/features/tongtai/sample/historical_data_generator.dart',
      ).readAsStringSync();
      expect(
        code.contains('segments: [plan.behaviour.labelVi]'),
        isFalse,
        reason: 'bộ sinh lưu nhãn hiển thị — ADR-TON-018 cấm',
      );
      expect(code, contains('plan.behaviour.segment.code'));
    });

    test('⛔ màn Khách hàng KHÔNG in mã lưu trữ như thể là nhãn', () {
      // ⚠️ Cửa này ĐỔI KHOÁ ở WTM-419, không bị gỡ (P-37).
      //
      // Mối nguy vẫn y nguyên: một **mã** lưu dưới SQLite (`vip`, `at_risk`)
      // bị in thẳng lên chip như thể nó là chữ cho người đọc. Nhưng cách khoá
      // đã đổi: màn không còn phân giải chuỗi nữa, nó đọc thẳng **enum** từ
      // phép suy RFM, nên `CustomerSegment.display`/`normalise` biến mất một
      // cách hợp lệ — bậc thang ấy chỉ tồn tại để cứu một chuỗi.
      //
      // Cửa mới canh đúng hai điều còn lại:
      //   1. phân khúc canonical phải đi qua `.label(` (theo ngôn ngữ), và
      //   2. KHÔNG được lặp thẳng trên `c.segments` để in ra.
      final code = File(
        'lib/features/tongtai/ui/screens/tongtai_consumer_screen.dart',
      ).readAsStringSync();

      expect(
        code,
        contains('.label(l10n.languageCode)'),
        reason: 'phân khúc canonical phải ra chữ theo ngôn ngữ, không ra mã',
      );
      expect(
        RegExp(r'for \(final \w+ in c\.segments\)').hasMatch(code),
        isFalse,
        reason:
            'lặp thẳng trên `segments` rồi in ra — đúng hình dạng WTM-381. '
            'Nhãn người bán tự đặt đi qua `CustomerSegmentView.customLabels`, '
            'nơi mã canonical đã bị loại trước.',
      );
    });
  });
}
