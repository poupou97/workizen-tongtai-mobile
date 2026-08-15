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

/// Bỏ chú thích trước khi soi mã.
///
/// Cổng §3c suýt tự bắn vào chân mình: chú thích trong `connections_screen`
/// *kể lại* rằng bản cũ dùng `Colors.green`/`Colors.orange` thô — và mọi chú
/// thích giải thích một luật đều phải trích dẫn thứ mà luật ấy cấm. Một cổng
/// đọc văn xuôi như đọc mã sẽ phạt đúng những người ghi lại bài học.
String _stripComments(String src) => src
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .split('\n')
    .map((l) {
      final i = l.indexOf('//');
      return i < 0 ? l : l.substring(0, i);
    })
    .join('\n');

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

    test('⭐ §3 KHÔNG tiêm `Color` thô vào component (toàn `ui/`)', () {
      // ⚠️ WTM-427 — tên test này TRƯỚC ĐÂY là "§2+§3 KHÔNG tự dựng huy hiệu
      // trạng thái, KHÔNG tiêm Color thô", nhưng trong thân chỉ có MỘT bộ dò
      // (`final Color color;`). Phần "§2 không tự dựng huy hiệu" **không có mã
      // nào kiểm cả**.
      //
      // Một cổng mang tên hứa nhiều hơn nó làm thì **tệ hơn không có cổng**:
      // người đọc danh sách test tin rằng vùng ấy đã được canh, nên không ai đi
      // canh nữa. Nên tên đã đổi cho đúng thứ nó kiểm. Bộ dò §2 thật cần một
      // đợt audit riêng (16 tệp tự dựng viên bo tròn, mà **chip lọc không phải
      // huy hiệu** — cùng hình dáng ≠ cùng vai, cấm quét mù) → **WTM-428**.
      //
      // ## Ba giả định ngầm đã bỏ (WTM-427)
      //
      // Bộ dò cũ chỉ nhìn `/ui/screens/` + đúng chữ `final Color color;`. Cả ba
      // giả định đều sai, và đo được: cổng thấy **9 tệp**, sự thật là **17**.
      //
      //   * component không chỉ sống trong `screens/` — `tongtai_bottom_nav`
      //     nằm ở gốc `ui/`, `tt_metric_card` ở `ui/widgets/`;
      //   * `final Color? color;` (**có dấu hỏi**) đi lọt hoàn toàn;
      //   * trường không phải lúc nào cũng tên `color` — thực tế còn `accent`
      //     (5 tệp), `iconColor` (3), `trackColor`, `tint`, `paceColor`.
      //
      // Tám tệp vô hình, trong đó có đúng cái mà WTM-426 tìm ra **bằng mắt trên
      // máy thật** chứ không phải bằng cổng. Lần thứ ba trong một phiên gặp
      // P-45: *cổng chỉ bắt thứ nó được viết để tìm*.
      // ⚠️ DS-3 (WTM-423) hạ 2 tệp, mỗi tệp một lý do khác nhau:
      //   * `stock_alerts` truyền đúng `danger`/`warning` — tức VAI ngữ nghĩa,
      //     mà mapper `tongtaiStockAlertTone` đã có chủ từ DS-2. Màn đang tự
      //     dịch lại một thứ đã được trả lời.
      //   * `producer` truyền CÙNG MỘT màu ở cả sáu lời gọi ⇒ tham số không
      //     phân biệt được gì, chỉ mở đường cho một sắc lạ đi vào sau này.
      //
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
        // `tongtai_forecast_screen.dart` RA KHỎI danh sách ở WTM-425: `_Chip`
        // nhận `TtStatus`. Nó mắc kẹt với `Color` thô vì hai trong ba lời gọi
        // là nhãn **trung tính** (độ tin cậy · xuất xứ "số này do quy tắc
        // tính") — và trước WTM-425, `TtStatus` KHÔNG CÓ vai trung tính để
        // nhận. Thiếu một vai trong enum đẻ ra nợ ở tầng màn.
        'lib/features/tongtai/ui/screens/tongtai_goal_detail_screen.dart',
        // `tongtai_import_screen.dart` RA KHỎI danh sách ở WTM-424: `_IssueBlock`
        // nhận `TtStatus` thay `Color`, vì hai lời gọi của nó truyền đúng hai
        // VAI (lỗi · cảnh báo) — mà một trong hai đang truyền **sai màu**.
        'lib/features/tongtai/ui/screens/tongtai_onboarding_v2_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_opportunity_detail_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart',
        // `tongtai_startup_screen.dart` RA KHỎI danh sách ở WTM-416: hàng ba
        // cột `_Value(color:)` bị gỡ cùng lúc màn dựng lại theo nhận diện mới.
        // Nợ giảm thì baseline phải giảm theo — chính cổng này bắt tôi hạ.
        'lib/features/tongtai/ui/screens/tongtai_transaction_form_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_unified_search_screen.dart',
        // ── Tám tệp dưới đây lộ ra khi nới bộ dò ở WTM-427 ────────────────
        // Chúng KHÔNG phải nợ mới; chúng luôn ở đó, chỉ là cổng không nhìn tới.
        //
        // Vai **visualization** — `Color` là màu thật của một dải dữ liệu:
        'lib/features/tongtai/ui/widgets/tt_sparkline.dart',
        // ⛔ **ĐANG CHỜ QUYẾT ĐỊNH FOUNDER — WTM-426.** Thanh tab gán một màu
        // TRẠNG THÁI cho mỗi tab làm màu ĐỊNH DANH: tab "Kho" mang
        // `TtColors.warning`, trong khi chấm chú giải "sắp hết hàng" trên cùng
        // màn cũng `#F59E0B`. Một sắc, hai nghĩa, một khung hình. Không tự sửa
        // được vì đây là hai chỉ dẫn của Founder chỏi nhau (luật màu vs. chỉ
        // đường bằng màu). Gỡ khỏi baseline này khi WTM-426 chốt A/B/C.
        'lib/features/tongtai/ui/tongtai_bottom_nav.dart',
        // Nợ đã đo, **chưa audit vai** — trường tên `accent`/`iconColor`/`tint`
        // nên bộ dò cũ (chỉ tìm chữ `color`) không thấy:
        'lib/features/tongtai/ui/screens/tongtai_customer_form_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_finance_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_product_form_screen.dart',
        'lib/features/tongtai/ui/screens/tongtai_reports_screen.dart',
        'lib/features/tongtai/ui/widgets/tongtai_screen_data.dart',
        'lib/features/tongtai/ui/widgets/tt_metric_card.dart',
      };

      // Bắt **mọi tên trường**, kể cả nullable, trên **toàn** `ui/` — không chỉ
      // `screens/`. Ba giả định cũ đã nêu ở đầu test.
      final offenders = _filesWhere(
        (path, src) =>
            path.contains('/features/tongtai/ui/') &&
            RegExp(
              r'^\s+final Color\??\s+\w+;',
              multiLine: true,
            ).hasMatch(_stripComments(src)),
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

    test('⭐ §2 KHÔNG dựng thêm viên bo tròn tự chế (ratchet, WTM-428)', () {
      // ## Vì sao cổng này CHỈ chặn tăng, không ép migrate
      //
      // Tên test cũ hứa *"§2 không tự dựng huy hiệu trạng thái"* nhưng không có
      // mã nào kiểm (WTM-427 đã đổi tên cho đúng). Đây là bộ dò thật — nhưng nó
      // cố ý **không** cố phân biệt huy hiệu với chip, vì **không phân biệt
      // được bằng cú pháp**, và một bộ dò gần đúng ở đây nguy hiểm hơn không có:
      // nó sẽ đỏ ở chip lọc hợp lệ, người sau sửa cho xanh bằng cách **migrate
      // sai**, và cổng tự tạo ra đúng lỗi nó định ngăn.
      //
      // Viên bo tròn nền nhạt là hình dáng chung của **ít nhất bốn vai**:
      //
      //   | vai | ví dụ | có phải huy hiệu |
      //   |---|---|---|
      //   | huy hiệu trạng thái | "Hết hàng" · "Đã thanh toán" | ✅ `TtStatusBadge` |
      //   | chip **lọc/chọn** | "Tất cả" · "Xu hướng" | ❌ bấm được, đổi truy vấn |
      //   | nhãn phân loại | "Gia dụng" · "Mẹ & Bé" | ❌ không mang mức nghiêm trọng |
      //   | dải năng lực | "Chấm điểm cơ hội" | ❌ định danh |
      //
      // ## Đo lại vì số cũ SAI
      //
      // Ticket WTM-428 ghi "16 tệp". Sai: phép đếm ấy quét mọi
      // `BorderRadius.circular(TtRadius.full)`, nên nó đếm cả **thanh tiến độ**
      // (`ClipRRect` bọc `LinearProgressIndicator`) ở màn Tài chính · Khởi động ·
      // Tổng kết tuần. Ba "huy hiệu" ấy không phải huy hiệu, mà là thanh bo
      // tròn. Số thật: **21 viên / 15 tệp**, chỉ tính viên dựng bằng
      // `BoxDecoration`.
      //
      // Bài học lặp lại của cả đợt: *bộ đếm trả lời đúng câu hỏi nó được viết
      // ra, không phải câu mình tưởng mình đang hỏi.*
      const baseline = <String, int>{
        'lib/features/tongtai/ui/screens/tongtai_autonomy_screen.dart': 1,
        'lib/features/tongtai/ui/screens/tongtai_customer_list_screen.dart': 1,
        'lib/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart': 3,
        'lib/features/tongtai/ui/screens/tongtai_forecast_screen.dart': 2,
        'lib/features/tongtai/ui/screens/tongtai_goal_detail_screen.dart': 1,
        'lib/features/tongtai/ui/screens/tongtai_goals_screen.dart': 1,
        'lib/features/tongtai/ui/screens/tongtai_home_screen.dart': 4,
        'lib/features/tongtai/ui/screens/tongtai_opportunity_detail_screen.dart':
            1,
        'lib/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart':
            1,
        'lib/features/tongtai/ui/screens/tongtai_reports_screen.dart': 2,
        'lib/features/tongtai/ui/screens/tongtai_stock_alerts_screen.dart': 1,
        'lib/features/tongtai/ui/screens/tongtai_supplier_search_screen.dart':
            1,
        'lib/features/tongtai/ui/widgets/tongtai_brief_widgets.dart': 1,
        'lib/features/tongtai/ui/widgets/tongtai_opportunity_signal_badges.dart':
            1,
        'lib/features/tongtai/ui/widgets/tongtai_screen_data.dart': 1,
      };

      /// Đếm viên dựng bằng `BoxDecoration` — **bỏ** `ClipRRect` (thanh tiến độ).
      int pills(String src) {
        var n = 0;
        for (final m in RegExp(
          r'BorderRadius\.circular\(TtRadius\.full\)',
        ).allMatches(src)) {
          final before = src.substring(
            m.start - 220 < 0 ? 0 : m.start - 220,
            m.start,
          );
          if (before.contains('BoxDecoration') &&
              !before
                  .substring(before.length - 120 < 0 ? 0 : before.length - 120)
                  .contains('ClipRRect')) {
            n++;
          }
        }
        return n;
      }

      final counts = <String, int>{};
      for (final f in _filesWhere(
        (path, src) => path.contains('/features/tongtai/ui/'),
      )) {
        final n = pills(_stripComments(File(f).readAsStringSync()));
        if (n > 0) counts[f] = n;
      }

      for (final e in counts.entries) {
        expect(
          e.value,
          lessThanOrEqualTo(baseline[e.key] ?? 0),
          reason:
              'viên bo tròn tự chế MỚI trong ${e.key}. Trước khi thêm, hỏi nó '
              'đóng vai nào trong bảng ở đầu test: nếu là **huy hiệu trạng '
              'thái** thì dùng `TtStatusBadge`; nếu là chip lọc / nhãn phân '
              'loại / dải năng lực thì nó KHÔNG phải huy hiệu — thêm vào '
              'baseline kèm lý do.',
        );
      }
      // ⚠️ Chiều NÀY, không phải chiều kia. Bản đầu tôi viết
      // `counts <= baseline` — trùng đúng khẳng định ở trên, nên khai baseline
      // = 9 cho một tệp có 1 viên vẫn XANH. Đột biến bắt được.
      //
      // Một baseline nói quá nợ là **chỗ trống để nợ mới mọc lại** đúng vào
      // vùng vừa dọn, mà không cổng nào kêu.
      for (final e in baseline.entries) {
        expect(
          e.value,
          lessThanOrEqualTo(counts[e.key] ?? 0),
          reason:
              'baseline khai ${e.value} viên ở ${e.key} nhưng thật chỉ có '
              '${counts[e.key] ?? 0} — hạ nó xuống, nếu không phần dôi ra là '
              'chỗ trống cho nợ mới mọc lại mà không ai thấy',
        );
      }
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

    test('⭐ §3c KHÔNG dùng bảng màu Material (`Colors.<tên>`) — KHÔNG baseline', () {
      // ## Vì sao phải có cổng thứ ba
      //
      // §3b bắt `Color(0xFF...)`. Nhưng `Colors.orange` **không phải mã hex**,
      // nên nó đi lọt cả §3b lẫn §3 (§3 chỉ bắt component *nhận* màu, không bắt
      // màn *chọn* màu tại chỗ). Hậu quả hiển thị thì y hệt.
      //
      // Cùng họ P-44: **cổng chỉ bắt thứ nó được viết để tìm.** Cổng này được
      // viết cho mã hex, nên một cái tên đi qua tự do suốt từ DS-2.
      //
      // ## Nó đã để lọt cái gì (WTM-424)
      //
      // Màn Nhập liệu tô khối **cảnh báo** bằng `Colors.orange`. Theo luật màu
      // Founder, **cam = Brand/Primary Action** — nên chỗ đang báo có vấn đề
      // lại đọc ra *"bấm vào đây"*. Đúng lỗi mà chú thích trong
      // `tongtai_connections_screen.dart` đã gọi là *"nặng nhất"* khi DS-2 dọn
      // màn Kết nối. Dọn một màn không dọn được màn khác, vì không có cổng.
      //
      // ## Vì sao KHÔNG baseline
      //
      // Đo thật: chỉ 7 lần dùng, 2 tệp có mã chạy (lần ở `connections` nằm
      // trong chú thích). Số nhỏ ⇒ **đóng hẳn**. Một baseline rỗng là lời hứa
      // mạnh hơn một baseline nhỏ: không có chỗ nào để nợ mới nấp vào.
      //
      // ⚠️ `white`/`black`/`transparent` KHÔNG tính: chúng không mang vai ngữ
      // nghĩa nào (nền, lớp phủ, chỗ trống). Ép chúng vào `TtStatus` là lỗi
      // ngược lại — *cùng kiểu dữ liệu KHÔNG phải cùng vai*.
      final offenders = _filesWhere(
        (path, src) =>
            path.startsWith('lib/features/tongtai/ui/') &&
            RegExp(
              r'\bColors\.(?!white|black|transparent)[a-z]\w*',
            ).hasMatch(_stripComments(src)),
      );

      expect(
        offenders,
        isEmpty,
        reason:
            'bảng màu Material trong tầng UI. `Colors.orange` không phải một '
            'VAI — nó là một sắc độ mượn từ Material, không ai đổi được từ một '
            'chỗ, và nó có thể mâu thuẫn với luật màu (cam = Brand, KHÔNG phải '
            'cảnh báo). Dùng `TtStatus.<vai>` hoặc `TtColors.<tên ngữ nghĩa>`.',
      );
    });
  });

  test('⭐ §5 `TtStatus.unknown` chỉ mang MỘT nghĩa: thiếu dữ liệu (WTM-425)', () {
    // ## Vì sao cần cổng cho một enum
    //
    // Luật màu Founder khai **hai** vai xám khác nhau: *"Chưa biết"* và
    // *"Neutral = dữ liệu thường"*. Enum chỉ có `unknown`, nên **4/5 chỗ dùng
    // đã mượn nó** cho vai còn lại: `paused` (người dùng tự dừng) ·
    // `ConnectionReadiness.demo` (biết chắc là demo) · `churned`/`dormant`
    // (kết luận đã có) · thẻ không có mức đổi để so.
    //
    // Đó là **P-27 lộn ngược**: thay vì một khái niệm nhiều chủ, ở đây **một
    // chủ gánh hai khái niệm**. Hậu quả cùng loại — sửa màu cho *"thiếu dữ
    // liệu"* sẽ lặng lẽ đổi màu của *"tạm dừng"*, và không ai thấy cho tới
    // lúc nhìn màn hình.
    //
    // WTM-425 tách `neutral` ra. Cổng này giữ cho hai nghĩa không nhập lại:
    // `unknown` chỉ còn được dùng ở **thẻ thiếu dữ liệu** trong DS.
    //
    // ⚠️ **Cổng này CHỈ bắt `TtStatus.unknown`, KHÔNG bắt `TtColors.unknown`**
    // — và tôi ghi ra thay vì để cái tên đứng canh thay cho mã (P-45, kiểu
    // thứ tư). Đo thật: còn **12 chỗ** dùng thẳng `TtColors.unknown`, phần
    // lớn cũng là *"biết rõ mà không phán xét"* (`CustomerTier.silver` ·
    // `BriefDecision.dismissed` · xu hướng `flat` · `neverPurchased`). Mỗi
    // chỗ phải audit riêng — cùng hình dáng chưa chắc cùng vai — nên chúng
    // đi theo **WTM-431**, không nhét vội vào đây. Ít nhất một chỗ (`home:885`)
    // có vẻ KHÔNG phải neutral — *"không khoẻ"* là một phán xét, tô xám là
    // làm nhẹ một cảnh báo. Đổi hàng loạt sẽ nuốt đúng chỗ ấy.
    const allowed = <String>{
      // Thẻ "chưa đủ dữ liệu" — icon dấu hỏi. Đây là nghĩa DUY NHẤT còn lại.
      'lib/core/design/tt_cards.dart',
      // Nơi khai enum + bảng ánh xạ.
      'lib/core/design/tt_tokens.dart',
    };

    final offenders = _filesWhere(
      (path, src) =>
          path.startsWith('lib/') &&
          _stripComments(src).contains('TtStatus.unknown'),
    ).toSet();

    expect(
      offenders.difference(allowed),
      isEmpty,
      reason:
          '`TtStatus.unknown` nghĩa là **thiếu dữ liệu để kết luận**. Nếu chỗ '
          'này thật ra BIẾT RÕ mà chỉ không phán xét (tạm dừng · đã rời bỏ · '
          'không có mức đổi để so · nhãn xuất xứ), dùng `TtStatus.neutral`. '
          'Hai nghĩa trên một hằng là P-27 lộn ngược.',
    );
    expect(
      allowed.difference(offenders),
      isEmpty,
      reason: 'đã dọn bớt mà chưa hạ danh sách',
    );
  });
}
