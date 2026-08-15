import 'package:meta/meta.dart';

import '../consumer/customer.dart';
import '../consumer/customer_segment.dart';
import 'customer_rfm.dart';
import 'customer_segment_rule.dart';

/// **Một nguồn duy nhất cho mọi con số phân khúc trên màn Khách hàng** —
/// WTM-419 bước 1.
///
/// ## Lỗi có thật mà cái này sửa
///
/// Dogfood Nokia 2026-08-15 (build +17): trên **cùng một màn hình**, cách nhau
/// khoảng 600px, app hiện `VIP: 0` ở ô tóm tắt và `Khách VIP (8)` ở chip ngay
/// dưới. `Mới: 4` và `Khách mới (14)` cũng vậy.
///
/// Không phải hai chủ mà **ba**, mỗi cái trả lời một câu hỏi khác nhau nhưng
/// đội chung một cái nhãn:
///
///   1. `c.tier == CustomerTier.vip` — một **trường xếp hạng** mà không đường
///      ghi nào trong app set ⇒ luôn 0;
///   2. `c.orderCount == 0` gắn nhãn *"Mới"* — thật ra là **chưa mua lần nào**,
///      tức gần như ngược nghĩa: một liên hệ chưa từng mua bị đếm như khách
///      vừa đến;
///   3. `c.segments` — **nhãn lưu sẵn** đến từ file nhập.
///
/// 2863 test xanh không thấy gì, vì không test nào hỏi *"hai con số này có nói
/// cùng một chuyện không"*.
///
/// ## Luật
///
/// Mọi con số phân khúc trên màn phải đi ra từ **một** [customerSegmentsFrom].
/// Ô tóm tắt và chip là hai cách **trình bày** cùng một bảng đếm, không phải
/// hai phép đo.
@immutable
class CustomerSegmentView {
  const CustomerSegmentView({
    required this.tally,
    required this.customLabels,
    required this.notPurchased,
    required this.total,
  });

  /// Không đọc được đơn hàng ⇒ **không đếm gì**, và màn nói ra là chưa biết.
  /// KHÔNG rơi về nhãn lưu sẵn: quay lại nguồn cũ chính là quay lại mâu thuẫn.
  static const CustomerSegmentView unknown = CustomerSegmentView(
    tally: {},
    customLabels: {},
    notPurchased: 0,
    total: 0,
  );

  final Map<CustomerSegment, int> tally;

  /// Nhãn **người bán tự đặt** ("bán sỉ", "khách quen chợ Lớn"…) — giữ nguyên,
  /// đếm riêng.
  ///
  /// ⚠️ Bản đầu của WTM-419 gộp luôn cả những nhãn này vào phép suy RFM và
  /// **xoá sạch chúng khỏi màn**. Cổng `count_list_contract_test` bắt được.
  ///
  /// Chúng không mâu thuẫn với gì cả: RFM trả lời *"khách này đang ở đâu trong
  /// vòng đời"*, còn nhãn tự đặt trả lời *"người bán gọi họ là gì"*. Hai câu
  /// hỏi khác nhau ⇒ hai chủ khác nhau là đúng, không phải lỗi. Chỉ những nhãn
  /// **trùng tên** với phân khúc canonical mới là chỗ sinh mâu thuẫn, và đúng
  /// những nhãn ấy bị loại ở đây.
  final Map<String, int> customLabels;

  /// Khách trong danh bạ **chưa mua lần nào** — không có phân khúc, và đó là
  /// một con số riêng chứ không phải một phân khúc.
  final int notPurchased;

  final int total;

  /// Suy từ danh bạ + đơn hàng thật.
  factory CustomerSegmentView.derive({
    required List<Customer> customers,
    required List<CustomerRfm> profiles,
    required DateTime now,
  }) {
    final segments = customerSegmentsFrom(profiles: profiles, now: now);
    final tally = <CustomerSegment, int>{};
    for (final s in segments.values) {
      tally[s] = (tally[s] ?? 0) + 1;
    }

    final custom = <String, int>{};
    for (final c in customers) {
      for (final raw in c.segments) {
        final label = raw.trim();
        if (label.isEmpty) continue;
        // Nhãn nào phân giải được thành phân khúc canonical thì BỎ: đó chính
        // là nhãn lưu sẵn từng nói ngược với RFM.
        if (CustomerSegment.parse(label) != null) continue;
        custom[label] = (custom[label] ?? 0) + 1;
      }
    }

    return CustomerSegmentView(
      tally: Map.unmodifiable(tally),
      customLabels: Map.unmodifiable(custom),
      notPurchased: customers.length - segments.length,
      total: customers.length,
    );
  }

  int of(CustomerSegment segment) => tally[segment] ?? 0;

  /// Khách **đang hoạt động**: còn trong nhịp mua của chính họ.
  ///
  /// Suy từ đúng bảng đếm ở trên, nên nó không thể lệch với các chip — trước
  /// đây con số này dùng cửa sổ cố định 90 ngày trong khi phân khúc dùng nhịp
  /// riêng của từng khách, và hai cách ấy bất đồng với nhau ở mọi khách mua
  /// theo quý.
  int get active =>
      of(CustomerSegment.newcomer) +
      of(CustomerSegment.oneTime) +
      of(CustomerSegment.returning) +
      of(CustomerSegment.loyal) +
      of(CustomerSegment.vip);

  /// Tổng khách **đã được xếp phân khúc**.
  ///
  /// ⚠️ Bất biến của ADR-TON-015 ở màn này: `segmented + notPurchased == total`.
  /// Nếu lệch thì có khách biến mất khỏi mọi cách đếm.
  int get segmented => tally.values.fold(0, (a, b) => a + b);

  bool get isEmpty =>
      segmented == 0 && notPurchased == 0 && customLabels.isEmpty;
}
