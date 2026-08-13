import 'package:flutter/foundation.dart';

import '../analytics/revenue_series.dart';

/// Chuỗi tháng mà Trang chủ vẽ thành đường xu hướng, cùng mức đổi so tháng
/// liền trước — WTM-404 (concept-1 `cp_home.png`).
///
/// ## Vì sao là một lớp riêng, không phải mấy dòng trong `build()`
///
/// Ba luật dưới đây đều là **luật kinh doanh**, không phải chi tiết vẽ vời:
/// mốc nào được so, khi nào từ chối trả lời, và mức đổi tính ra sao. Để chúng
/// trong widget nghĩa là không suite nào chạm tới được, và lần sau ai thêm một
/// thẻ nữa sẽ viết lại chúng theo trí nhớ — đúng vết P-27/P-28 (*một khái niệm,
/// một chủ*).
///
/// ## Ba luật
///
/// 1. **Mốc so là tháng liền trước ĐÃ KẾT THÚC.** [RevenueSeries] loại tháng
///    đang chạy khỏi cửa sổ phân tích, vì một tháng dở luôn trông như sụp đổ
///    cạnh các tháng đủ. Nhãn hiển thị phải nói đúng mốc ấy — *"so với tháng
///    trước"*, không phải *"so với hôm qua"*.
/// 2. **Không có mốc ⇒ không có phần trăm.** Dưới hai điểm thì không có gì để
///    so, và [changePercent] trả `null` để phía gọi nói *không biết* thay vì
///    vẽ một mũi tên.
/// 3. **⛔ Mốc bằng 0 ⇒ vẫn `null`.** Tháng trước bằng 0 thì mọi mức tăng đều
///    ra vô cực; làm tròn nó thành `+100%` là bịa một con số. Đây chính là lớp
///    lỗi `estimatedGain` đội lốt `observedRevenue` (WTM-384) — một ước tính
///    mặc áo phép đo.
@immutable
class HomeTrend {
  const HomeTrend({
    required this.revenue,
    required this.orders,
    this.profit = const [],
  });

  /// Chưa đọc được gì — thẻ vẽ số trần, không đường, không mũi tên.
  static const HomeTrend none = HomeTrend(revenue: [], orders: []);

  /// Rút chuỗi từ [RevenueSeries] — **không tự cộng lại từ đơn hàng.**
  ///
  /// Chuỗi ấy đã lọc đơn huỷ bằng đúng luật `isBillableOrder` mà
  /// `BusinessMetrics` và màn Báo cáo dùng; cộng lại ở đây là tạo câu trả lời
  /// thứ hai cho cùng một câu hỏi (One Data Path — ADR-TON-015).
  ///
  /// [profitByMonth] đến từ `FinanceSummary.monthly` (`net` mỗi tháng) vì lợi
  /// nhuận cần **chi phí**, thứ chuỗi doanh thu không có. Hai chuỗi có thể dài
  /// khác nhau — mỗi cái giữ cửa sổ riêng của chủ nó, và ép chúng bằng nhau ở
  /// đây sẽ là ta tự bịa một cửa sổ thứ ba.
  factory HomeTrend.from(
    RevenueSeries series, {
    Iterable<double> profitByMonth = const [],
  }) => HomeTrend(
    revenue: List<double>.unmodifiable([
      for (final p in series.points) p.revenue,
    ]),
    orders: List<double>.unmodifiable([
      for (final p in series.points) p.orderCount.toDouble(),
    ]),
    profit: List<double>.unmodifiable(profitByMonth),
  );

  /// Doanh thu từng tháng, cũ → mới.
  final List<double> revenue;

  /// Số đơn từng tháng, cũ → mới.
  final List<double> orders;

  /// Lợi nhuận ròng từng tháng (thu − chi), cũ → mới.
  final List<double> profit;

  /// Mức đổi của tháng cuối so tháng liền trước, tính theo **phần trăm** —
  /// hoặc `null` khi không có mốc để so (luật 2 và 3 ở đầu file).
  static double? changePercent(List<double> values) {
    if (values.length < 2) return null;
    final previous = values[values.length - 2];
    if (previous == 0) return null;
    return (values.last - previous) / previous * 100;
  }

  double? get revenueChangePercent => changePercent(revenue);
  double? get ordersChangePercent => changePercent(orders);
  double? get profitChangePercent => changePercent(profit);
}
