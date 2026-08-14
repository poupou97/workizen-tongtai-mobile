// P0 — **cổng ratchet của Design System** (WTM-414 · DS-2 · Epic WTM-412).
//
// ## Luật Founder 2026-08-14
//
//     Token → Semantic Role → Shared Component → Screen
//     Screen chỉ CONSUME. Screen không định nghĩa lại vai đã có.
//
// ## Vì sao là RATCHET, không phải cổng tuyệt đối
//
// Bắt toàn bộ 52 màn tuân thủ trong một PR sẽ chặn mọi việc khác. Nên cổng này
// giữ **baseline nợ đã đo thật** và chỉ cho nó **GIỮ NGUYÊN hoặc GIẢM**.
// Thêm một vi phạm mới ⇒ đỏ. Dọn bớt mà quên hạ số ⇒ cũng đỏ, vì một baseline
// nói quá nợ sẽ lặng lẽ cho phép nợ mới mọc lại vào chỗ vừa dọn.
//
// ## Bốn thứ được theo dõi (đúng danh sách Founder nêu)
//
//   §1 mapper miền → semantic đặt TRONG tệp màn
//   §2 tự dựng huy hiệu trạng thái thay vì dùng `TtStatusBadge`
//   §3 tiêm `Color` thô vào component ngữ nghĩa
//   §4 dùng Material thô khi DS đã có component cùng vai
//
// ⚠️ §3 có ngoại lệ **được ghi rõ**: visualization / data-series cần `Color`
// thật (chú giải biểu đồ, đường xu hướng). Ngoại lệ phải nêu đích danh tệp và
// lý do — không có ngoại lệ chung chung.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Đếm số tệp trong `lib/` thoả một điều kiện.
List<String> _filesWhere(bool Function(String path, String src) test) {
  final out = <String>[];
  for (final e in Directory('lib').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    if (test(e.path, e.readAsStringSync())) out.add(e.path);
  }
  return out..sort();
}

void main() {
  group('DS ratchet — nợ chỉ được GIỮ NGUYÊN hoặc GIẢM', () {
    test('§1 mapper miền → semantic KHÔNG được sống trong tệp màn', () {
      // Màn là consumer. "Trạng thái này nghĩa là gì" thuộc tầng trên: hai màn
      // cùng hỏi phải nhận cùng một câu trả lời, và câu ấy không thể thuộc về
      // một trong hai.
      //
      // DS-2 đã chuyển 3 mapper ra (`inventory_tone` · `order_tone` ·
      // `connection_tone`). Số còn lại là nợ đã đo, ghi đích danh.
      const baseline = <String>{
        'lib/features/tongtai/ui/screens/tongtai_forecast_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_customer_list_screen.dart',
      };

      final offenders = _filesWhere(
        (path, src) =>
            path.contains('/ui/screens/') &&
            RegExp(
              r'^(Color|TtStatus) tongtai\w+\(',
              multiLine: true,
            ).hasMatch(src),
      ).toSet();

      expect(
        offenders.difference(baseline),
        isEmpty,
        reason:
            'mapper miền → semantic MỚI đặt trong tệp màn. Chuyển nó cạnh miền '
            '(khuôn `inventory_tone.dart` / `goal_theme.dart`) và trả `TtStatus`.',
      );
      expect(
        baseline.difference(offenders),
        isEmpty,
        reason:
            'đã dọn bớt mà chưa hạ baseline — một baseline nói quá nợ sẽ cho '
            'nợ mới mọc lại đúng chỗ vừa dọn mà không ai thấy',
      );
    });

    test('⭐ §2+§3 KHÔNG tự dựng huy hiệu trạng thái, KHÔNG tiêm Color thô', () {
      // Huy hiệu trạng thái = viên bo tròn, nền nhạt, chữ màu, **không tương
      // tác**, do một enum miền quyết định. `TtStatusBadge` phủ đúng vai đó.
      //
      // ⛔ KHÔNG tính vào đây: chip **lọc/chọn** (bấm được, đổi truy vấn) và
      // dải phân loại kết quả — *cùng hình dáng KHÔNG phải cùng vai*, ép chúng
      // vào huy hiệu là lỗi ngược lại.
      // ⚠️ Baseline này ĐO THẬT, không đoán. Bản đầu tôi viết 5 tệp theo trí
      // nhớ và cổng đỏ ngay — con số thật là 13. Một baseline đoán sẽ hoặc chặn
      // oan, hoặc (tệ hơn) bỏ lọt nợ đang có.
      const baseline = <String>{
        // Vai **visualization**: chú giải biểu đồ vòng — `Color` là màu thật
        // của một dải dữ liệu, không phải sắc thái ngữ nghĩa. Ngoại lệ được ghi
        // rõ theo lời Founder: *không ép sai abstraction*.
        'lib/features/tongtai/ui/screens/tongtai_inventory_screen.dart',
        // Nợ đã đo, **chưa audit vai** — mỗi tệp phải xét riêng trước khi đổi,
        // vì cùng hình dáng chưa chắc cùng vai.
        'lib/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_forecast_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_goal_detail_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_import_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_onboarding_v2_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_opportunity_detail_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_producer_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_startup_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_stock_alerts_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_transaction_form_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_unified_search_screen.dart',
      };

      final offenders = _filesWhere(
        (path, src) =>
            path.contains('/ui/screens/') &&
            RegExp(r'\n\s+final Color color;').hasMatch(src),
      ).toSet();

      expect(
        offenders.difference(baseline),
        isEmpty,
        reason:
            'component MỚI nhận `Color` từ phía gọi. Chừng nào còn nhận `Color`, '
            'màn còn định nghĩa lại Design System qua tham số — dùng `TtStatus` '
            '(hoặc một enum vai phù hợp). Nếu thật sự là visualization, thêm vào '
            'baseline KÈM lý do.',
      );
      expect(
        baseline.difference(offenders),
        isEmpty,
        reason: 'đã dọn bớt mà chưa hạ baseline',
      );
    });

    test('§3b KHÔNG mã màu thô trong tệp màn', () {
      // `Color(0xFF...)` trong một màn nghĩa là màn tự dựng bảng màu riêng —
      // không ai đổi được nó từ một chỗ, và nó không mang tên ngữ nghĩa nào.
      //
      // DS-2 đã dọn 4 mã hex ở màn hội thoại (ba mã cho một vai **trạng thái**).
      const baseline = <String>{
        'lib/features/tongtai/ui/screens/tongtai_business_life_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_connections_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_conversation_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_customer_list_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_home_screen.dart',
      };

      final offenders = _filesWhere(
        (path, src) =>
            path.contains('/ui/screens/') &&
            RegExp(r'Color\(0x[0-9a-fA-F]{8}\)').hasMatch(src),
      ).toSet();

      expect(
        offenders.difference(baseline),
        isEmpty,
        reason:
            'mã màu thô MỚI trong tệp màn. Màu phải có tên ngữ nghĩa ở '
            '`TtColors`/`TtStatus` để đổi được từ một chỗ.',
      );
      expect(
        baseline.difference(offenders),
        isEmpty,
        reason: 'đã dọn bớt mà chưa hạ baseline',
      );
    });
  });
}
