import 'package:flutter/foundation.dart';

import '../analytics/week_bucket.dart';
import '../metrics/business_metrics.dart';
import '../orders/order.dart';
import 'rule_twin.dart';

/// **Weekly Review Rule Twin** (WTM-376, Epic WTM-179 · ADR-TON-016) — the
/// AUTHORITATIVE deterministic answer to *"tuần rồi thế nào?"*.
///
/// Runs with **no AI, no network, no key**. The AI layer added later may only
/// *explain* what this returns; it may never change a number (ADR-TON-016).
///
/// ## Ba câu khác nhau mà bản tổng kết phải nói được
///
/// | Tình huống | Trả về |
/// |---|---|
/// | chưa có tuần nào hoàn chỉnh | `insufficient` · `result == null` |
/// | tuần rồi **không bán được gì** | `sufficient` · một tuần với `orders == 0` |
/// | tuần rồi có bán | `sufficient` · số thật + so sánh |
///
/// Hàng giữa là hàng dễ mất nhất. *"Tuần rồi không bán được gì"* là một **câu
/// trả lời thật** và người bán cần nghe nó; gộp nó vào *"chưa xét được"* là
/// giấu mất đúng tin họ phải biết (Testing Bible P-03).
///
/// ## Tuần đang chạy bị loại
///
/// Bản tổng kết mở sáng thứ Hai nói về **tuần rồi**, không nói về bốn tiếng vừa
/// trôi qua. Một tuần dở luôn đọc thành sụp đổ khi đặt cạnh những tuần trọn —
/// cùng lý do `monthWindow` loại tháng đang chạy. Twin nói rõ điều đó bằng
/// [ReasonCode.partialWeekExcluded].
///
/// ## Không đếm lại tiền
///
/// Doanh thu = tổng `order.totalAmount` của các đơn **billable**, dùng đúng
/// [isBillableOrder] mà `RevenueSeries`, Reports và Trang chủ đang dùng. Lưới
/// thời gian có hai (tháng · tuần); **luật tính tiền chỉ có một**.

/// Formula version — bump when the maths changes (ADR-TON-016).
const String kWeeklyReviewRuleVersion = 'weekly-review/1';

/// How many completed weeks the twin looks back over.
///
/// Bốn tuần: đủ để một tuần lạ (lễ, đơn sỉ bất thường) không tự nó thành xu
/// hướng, và vẫn đủ ngắn để nói về *doanh nghiệp hôm nay*.
const int kWeeklyReviewWindowWeeks = 4;

/// Fractional move inside which the week-vs-week comparison is called *flat*.
///
/// ±10 %: nhịp lên xuống bình thường của một tuần bán lẻ. Báo động dưới mức này
/// là dạy người bán tắt thông báo.
const double kWeeklyReviewNoiseBand = 0.10;

/// One completed week, as the review reads it.
@immutable
class WeeklyReviewPoint {
  const WeeklyReviewPoint({
    required this.week,
    required this.revenue,
    required this.orderCount,
    required this.customerCount,
    required this.topProduct,
  });

  final WeekKey week;

  /// Billable revenue booked in this week.
  final double revenue;

  /// Billable orders booked in this week.
  final int orderCount;

  /// Distinct customers who bought in this week.
  final int customerCount;

  /// Best-selling product of the week by billable revenue — `null` when the
  /// week sold nothing.
  ///
  /// Nằm ở đây chứ không tính lại trong màn hình: cùng một mớ đơn mà gộp hai
  /// lần là hai kết quả có thể lệch nhau (ADR-TON-015 One Data Path).
  final WeeklyTopProduct? topProduct;

  /// Revenue ÷ orders, or `0` for an empty week — same convention as
  /// `MonthlyRevenuePoint.averageOrderValue`.
  double get averageOrderValue => orderCount == 0 ? 0 : revenue / orderCount;

  /// Whether the week booked nothing at all. **Not** the same as "unknown".
  bool get isEmpty => orderCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyReviewPoint &&
          other.week == week &&
          other.revenue == revenue &&
          other.orderCount == orderCount &&
          other.customerCount == customerCount &&
          other.topProduct == topProduct);

  @override
  int get hashCode =>
      Object.hash(week, revenue, orderCount, customerCount, topProduct);
}

/// The week's best seller, by billable revenue.
@immutable
class WeeklyTopProduct {
  const WeeklyTopProduct({
    required this.name,
    required this.revenue,
    required this.quantity,
  });

  final String name;
  final double revenue;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyTopProduct &&
          other.name == name &&
          other.revenue == revenue &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(name, revenue, quantity);
}

/// Which way the week moved against the one before it.
enum WeeklyTrend {
  up,
  flat,
  down;

  /// The reason code this trend quotes, so the UI and the AI say the same word.
  ReasonCode get reason => switch (this) {
    WeeklyTrend.up => ReasonCode.revenueGrowing,
    WeeklyTrend.flat => ReasonCode.revenueFlat,
    WeeklyTrend.down => ReasonCode.revenueDeclining,
  };
}

/// The review itself — *"tuần rồi thế nào"*.
@immutable
class WeeklyReview {
  const WeeklyReview({
    required this.week,
    required this.previous,
    required this.history,
    required this.trend,
  });

  /// The completed week this review is about.
  final WeeklyReviewPoint week;

  /// The week before it, or `null` when the window holds only one week.
  ///
  /// `null` means *"không có gì để so"*, and the UI must say that rather than
  /// draw a 0 % change — a comparison against nothing is not a comparison.
  final WeeklyReviewPoint? previous;

  /// Every completed week in the window, oldest → newest, [week] last. Empty
  /// weeks are present as zero points, never missing rows.
  final List<WeeklyReviewPoint> history;

  /// Direction of [week] versus [previous]. [WeeklyTrend.flat] when there is
  /// nothing to compare against — the twin does not guess a direction.
  final WeeklyTrend trend;

  /// Revenue change as a fraction, or `null` when it is genuinely undefined:
  /// no previous week, or a previous week of exactly zero (dividing by which
  /// would report an infinite rise for the first đồng ever earned).
  double? get revenueChange {
    final before = previous?.revenue;
    if (before == null || before == 0) return null;
    return (week.revenue - before) / before;
  }

  /// Order-count change as a fraction — `null` on the same two conditions.
  double? get ordersChange {
    final before = previous?.orderCount;
    if (before == null || before == 0) return null;
    return (week.orderCount - before) / before;
  }
}

/// Computes [WeeklyReview] from orders. Pure: same orders + same `now` → same
/// result. The clock is injected, never read here.
class WeeklyReviewRule {
  const WeeklyReviewRule({this.windowWeeks = kWeeklyReviewWindowWeeks});

  final int windowWeeks;

  RuleTwinResult<WeeklyReview> evaluate({
    required List<CustomerOrder> orders,
    required DateTime now,
  }) {
    final window = weekWindow(now: now, weeks: windowWeeks);
    if (window.isEmpty) {
      return RuleTwinResult<WeeklyReview>.insufficient(
        reasonCodes: const [ReasonCode.notEnoughHistory],
        version: kWeeklyReviewRuleVersion,
        generatedAt: now,
      );
    }

    final billable = orders.where(isBillableOrder).toList();
    final buckets = bucketByWeek(billable, (o) => o.date);

    // Mọi tuần trong cửa sổ đều phát ra một điểm — tuần trống là số 0 nhìn
    // thấy được, không phải một dòng biến mất.
    final history = <WeeklyReviewPoint>[
      for (final key in window) _pointFor(key, buckets[key] ?? const []),
    ];

    final week = history.last;
    final previous = history.length >= 2 ? history[history.length - 2] : null;

    // ⛔ Cửa duy nhất trả `insufficient`: **chưa có gì trong cả cửa sổ**.
    //
    // Một tuần trống giữa những tuần có bán vẫn là câu trả lời thật. Nhưng bốn
    // tuần liền không có đơn nào ở một máy vừa cài thì không phải *"làm ăn kém"*
    // — mà là *"chưa có dữ liệu để xét"*, và nói nhầm hai thứ đó là bịa.
    if (history.every((p) => p.isEmpty)) {
      return RuleTwinResult<WeeklyReview>.insufficient(
        reasonCodes: const [
          ReasonCode.notEnoughHistory,
          ReasonCode.noRevenueYet,
        ],
        version: kWeeklyReviewRuleVersion,
        generatedAt: now,
      );
    }

    final trend = _trendOf(week, previous);
    final reasons = <ReasonCode>[
      trend.reason,
      // Twin luôn khai rằng tuần đang chạy bị loại — nếu không, người bán mở
      // app trưa thứ Tư sẽ tưởng con số là của hôm nay.
      ReasonCode.partialWeekExcluded,
      if (previous == null) ReasonCode.notEnoughHistory,
      if (week.isEmpty) ReasonCode.noRevenueYet,
    ];

    return RuleTwinResult<WeeklyReview>(
      result: WeeklyReview(
        week: week,
        previous: previous,
        history: List.unmodifiable(history),
        trend: trend,
      ),
      confidence: _confidenceOf(history),
      sufficiency: previous == null
          ? DataSufficiency.partial
          : DataSufficiency.sufficient,
      reasonCodes: reasons,
      version: kWeeklyReviewRuleVersion,
      generatedAt: now,
    );
  }

  WeeklyReviewPoint _pointFor(WeekKey key, List<CustomerOrder> orders) =>
      WeeklyReviewPoint(
        week: key,
        revenue: orders.fold<double>(0, (sum, o) => sum + o.totalAmount),
        orderCount: orders.length,
        customerCount: orders.map((o) => o.customerId).toSet().length,
        topProduct: _topProductOf(orders),
      );

  /// Best seller by **revenue**, not by quantity.
  ///
  /// Bán 200 chiếc túi nilon không phải *"hàng bán chạy nhất tuần"* — nó là
  /// hàng đi kèm. Người bán hỏi câu này để biết nên nhập gì, nên đơn vị đúng là
  /// tiền. Hoà nhau thì lấy tên đứng trước theo bảng chữ cái, để cùng dữ liệu
  /// luôn cho cùng câu trả lời.
  WeeklyTopProduct? _topProductOf(List<CustomerOrder> orders) {
    final revenue = <String, double>{};
    final quantity = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        revenue[item.productName] =
            (revenue[item.productName] ?? 0) + item.lineTotal;
        quantity[item.productName] =
            (quantity[item.productName] ?? 0) + item.quantity;
      }
    }
    if (revenue.isEmpty) return null;
    final best = revenue.entries.reduce(
      (a, b) =>
          b.value > a.value ||
              (b.value == a.value && b.key.compareTo(a.key) < 0)
          ? b
          : a,
    );
    return WeeklyTopProduct(
      name: best.key,
      revenue: best.value,
      quantity: quantity[best.key] ?? 0,
    );
  }

  /// Direction, with the noise band applied. No previous week ⇒ *flat*, because
  /// the twin refuses to name a direction it cannot see.
  WeeklyTrend _trendOf(WeeklyReviewPoint week, WeeklyReviewPoint? previous) {
    final before = previous?.revenue;
    if (before == null || before == 0) return WeeklyTrend.flat;
    final change = (week.revenue - before) / before;
    if (change > kWeeklyReviewNoiseBand) return WeeklyTrend.up;
    if (change < -kWeeklyReviewNoiseBand) return WeeklyTrend.down;
    return WeeklyTrend.flat;
  }

  /// Confidence is about **how much the twin could see**, not about how good
  /// the news is: it counts completed weeks that actually booked something.
  ForecastConfidence _confidenceOf(List<WeeklyReviewPoint> history) {
    final active = history.where((p) => !p.isEmpty).length;
    if (active >= kWeeklyReviewWindowWeeks) return ForecastConfidence.high;
    if (active >= 2) return ForecastConfidence.medium;
    return ForecastConfidence.low;
  }
}
