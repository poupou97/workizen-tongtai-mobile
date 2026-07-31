import 'package:flutter/foundation.dart';

import '../metrics/business_metrics.dart';
import '../orders/order.dart';
import 'month_bucket.dart';
import 'series_math.dart';

/// Revenue booked in one local calendar month — one point of a [RevenueSeries].
///
/// A month with no billable orders still produces a point (all zeros): a gap in
/// the business must be **visible**, never a missing row that a chart silently
/// closes up.
@immutable
class MonthlyRevenuePoint {
  const MonthlyRevenuePoint({
    required this.year,
    required this.month,
    this.revenue = 0,
    this.orderCount = 0,
    this.customerCount = 0,
  });

  final int year;

  /// 1..12.
  final int month;

  /// Billable revenue booked in this month, in đồng (cancelled orders excluded
  /// — [isBillableOrder]).
  final double revenue;

  /// Billable orders booked in this month.
  final int orderCount;

  /// Distinct customers who bought in this month.
  final int customerCount;

  /// Revenue ÷ orders, or `0` when the month is empty — the same convention as
  /// [BusinessMetrics.averageOrderValue].
  double get averageOrderValue => orderCount == 0 ? 0 : revenue / orderCount;

  /// This point's position on the shared month grid.
  MonthKey get key => MonthKey(year, month);

  /// Whether the month booked nothing at all.
  bool get isEmpty => orderCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyRevenuePoint &&
          other.year == year &&
          other.month == month &&
          other.revenue == revenue &&
          other.orderCount == orderCount &&
          other.customerCount == customerCount);

  @override
  int get hashCode =>
      Object.hash(year, month, revenue, orderCount, customerCount);

  @override
  String toString() =>
      'MonthlyRevenuePoint($year-$month, revenue: $revenue, '
      'orders: $orderCount, customers: $customerCount)';
}

/// Last-vs-previous window comparison produced by [RevenueSeries.compareWindows]
/// — the shape behind "this quarter vs last quarter".
@immutable
class RevenueWindowComparison {
  const RevenueWindowComparison({
    required this.months,
    required this.recentRevenue,
    required this.previousRevenue,
    required this.recentOrders,
    required this.previousOrders,
    required this.hasBothWindows,
  });

  /// The answer when the series cannot cover **both** windows: all zeros, and
  /// [hasBothWindows] false so a twin reports `notEnoughHistory` instead of
  /// inventing a −100% collapse.
  const RevenueWindowComparison.insufficient(int months)
    : this(
        months: months,
        recentRevenue: 0,
        previousRevenue: 0,
        recentOrders: 0,
        previousOrders: 0,
        hasBothWindows: false,
      );

  /// Window size in months, as requested by the caller.
  final int months;

  final double recentRevenue;
  final double previousRevenue;
  final int recentOrders;
  final int previousOrders;

  /// True only when the series held `2 × months` points, i.e. the comparison is
  /// like-for-like.
  final bool hasBothWindows;

  double get revenueDelta => recentRevenue - previousRevenue;
  int get ordersDelta => recentOrders - previousOrders;

  /// Fractional revenue change, `null` when the previous window booked nothing
  /// (see [fractionalChange]).
  double? get revenueChange => fractionalChange(previousRevenue, recentRevenue);

  /// Fractional order-count change, `null` when the previous window had none.
  double? get ordersChange =>
      fractionalChange(previousOrders.toDouble(), recentOrders.toDouble());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevenueWindowComparison &&
          other.months == months &&
          other.recentRevenue == recentRevenue &&
          other.previousRevenue == previousRevenue &&
          other.recentOrders == recentOrders &&
          other.previousOrders == previousOrders &&
          other.hasBothWindows == hasBothWindows);

  @override
  int get hashCode => Object.hash(
    months,
    recentRevenue,
    previousRevenue,
    recentOrders,
    previousOrders,
    hasBothWindows,
  );

  @override
  String toString() =>
      'RevenueWindowComparison($months mo, recent: $recentRevenue, '
      'previous: $previousRevenue, bothWindows: $hasBothWindows)';
}

/// The monthly revenue history of the business — an **Aggregation Service**
/// (Founder directive "Capability-Driven Predictive Foundation", 2026-07-30).
///
/// ```
/// Repository → Aggregation Services → Capability Context → Rule Twin → AI
/// ```
///
/// This is the shared maths: the Revenue capability context, the revenue
/// forecast twin and the business-alert twin all read **this** series instead
/// of each bucketing orders their own way (duplicate aggregation is forbidden —
/// ADR-TON-015 One Data Path).
///
/// Everything here is **pure**: no clock read (the caller passes `now`), no
/// repository, no Riverpod, no widgets. Same orders + same `now` → same series,
/// which is what makes a deterministic twin testable.
///
/// Month bucketing, including the local-timezone decision, lives in
/// `month_bucket.dart`.
@immutable
class RevenueSeries {
  const RevenueSeries({required this.points, this.currentMonthExcluded = true});

  /// A business with nothing to analyse — well-formed, never null.
  static const RevenueSeries empty = RevenueSeries(
    points: <MonthlyRevenuePoint>[],
  );

  /// Buckets **billable** [orders] into the [months] calendar months ending at
  /// [now], oldest → newest.
  ///
  /// - Billable = the shared [isBillableOrder] rule (cancelled orders never
  ///   count as revenue), so the series can never disagree with
  ///   [BusinessMetrics] or the Reports dashboard.
  /// - Every month in the window emits a point, empty ones included.
  /// - [excludeCurrentMonth] (default `true`) drops the running month: it is
  ///   incomplete, so comparing it against full months always reads as a
  ///   collapse. The caller surfaces `ReasonCode.partialMonthExcluded`; the
  ///   flag is kept on [currentMonthExcluded] so a twin can state it.
  /// - Orders outside the window are ignored; a non-positive [months] yields an
  ///   empty series rather than an exception.
  factory RevenueSeries.fromOrders(
    Iterable<CustomerOrder> orders, {
    required DateTime now,
    int months = 12,
    bool excludeCurrentMonth = true,
  }) {
    final window = monthWindow(
      now: now,
      months: months,
      excludeCurrentMonth: excludeCurrentMonth,
    );
    if (window.isEmpty) {
      return RevenueSeries(
        points: const <MonthlyRevenuePoint>[],
        currentMonthExcluded: excludeCurrentMonth,
      );
    }
    final buckets = bucketByMonth<CustomerOrder>(
      orders.billable,
      (order) => order.date,
    );
    return RevenueSeries(
      points: List<MonthlyRevenuePoint>.unmodifiable([
        for (final key in window) _pointFor(key, buckets[key]),
      ]),
      currentMonthExcluded: excludeCurrentMonth,
    );
  }

  static MonthlyRevenuePoint _pointFor(
    MonthKey key,
    List<CustomerOrder>? bucket,
  ) {
    if (bucket == null || bucket.isEmpty) {
      return MonthlyRevenuePoint(year: key.year, month: key.month);
    }
    var revenue = 0.0;
    final customers = <String>{};
    for (final order in bucket) {
      revenue += order.totalAmount;
      customers.add(order.customerId);
    }
    return MonthlyRevenuePoint(
      year: key.year,
      month: key.month,
      revenue: revenue,
      orderCount: bucket.length,
      customerCount: customers.length,
    );
  }

  /// One point per month in the window, **oldest → newest**.
  final List<MonthlyRevenuePoint> points;

  /// Whether the running (partial) month was left out of this series.
  final bool currentMonthExcluded;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  /// The most recent complete month, or `null` for an empty series.
  MonthlyRevenuePoint? get latest => points.isEmpty ? null : points.last;

  /// Revenue over the whole window.
  double get totalRevenue =>
      points.fold(0, (sum, point) => sum + point.revenue);

  /// Billable orders over the whole window.
  int get totalOrders => points.fold(0, (sum, point) => sum + point.orderCount);

  /// Window-wide revenue ÷ window-wide billable orders, `0` when the window
  /// booked none.
  ///
  /// The same convention as [BusinessMetrics.averageOrderValue] and
  /// [MonthlyRevenuePoint.averageOrderValue], one level up: the AOV **of the
  /// analysable window**, which is what the Revenue capability context reports
  /// (the lifetime AOV stays on [BusinessMetrics]).
  double get averageOrderValue =>
      totalOrders == 0 ? 0 : totalRevenue / totalOrders;

  /// How many months actually booked revenue — the cheapest sufficiency signal
  /// a twin has (`noRevenueYet` when this is 0).
  int get monthsWithRevenue => points.where((p) => p.revenue > 0).length;

  bool get hasRevenue => monthsWithRevenue > 0;

  /// Revenue values in series order — the input of every calculation below.
  List<double> get revenues => [for (final point in points) point.revenue];

  /// Fractional change from the second-to-last month to the last, e.g. `0.25`
  /// for +25%.
  ///
  /// `null` when there are fewer than two months **or** the earlier month was
  /// zero — growth from nothing has no percentage.
  double? get monthOverMonthChange {
    if (points.length < 2) return null;
    return fractionalChange(
      points[points.length - 2].revenue,
      points.last.revenue,
    );
  }

  /// Mean revenue of the last [n] months. Uses however many months exist when
  /// the series is shorter, and returns `0` for an empty series or a
  /// non-positive [n] (a well-formed "nothing", never a throw).
  double trailingAverage(int n) => mean(trailing(revenues, n));

  /// Like [trailingAverage] but linearly weighted, newest heaviest: over three
  /// months the weights are 1 · 2 · 3.
  ///
  /// This is the default forecast base — recency matters more than a
  /// year-old month, but a single last month is noise.
  double weightedTrailingAverage(int n) =>
      linearWeightedAverage(trailing(revenues, n));

  /// Least-squares slope over the whole series, in **đồng per month**.
  ///
  /// Positive = growing. `null` when there are fewer than two months, so a twin
  /// can distinguish "no trend known" from "flat" (a real 0.0 slope).
  double? linearTrendSlope() => leastSquaresSlope(revenues);

  /// How erratic the business is: the relative dispersion (coefficient of
  /// variation) of the month-over-month changes — the standard deviation of
  /// those changes divided by their **mean absolute** size.
  ///
  /// - `0` = a perfectly steady rhythm (e.g. +10% every single month);
  ///   `≈ 1` and above = wild swings — the input for `highVolatility`.
  /// - The mean *absolute* change is used as the scale on purpose: dividing by
  ///   the plain mean would explode toward infinity for a symmetric
  ///   up-down-up-down business, which is the most volatile case, not an
  ///   undefined one.
  /// - Pairs whose earlier month booked zero are skipped (an infinite jump out
  ///   of nothing is not volatility). `null` when fewer than two usable changes
  ///   remain — with one change there is no dispersion to speak of.
  double? volatility() {
    final changes = <double>[];
    for (var i = 1; i < points.length; i++) {
      final change = fractionalChange(points[i - 1].revenue, points[i].revenue);
      if (change != null) changes.add(change);
    }
    if (changes.length < 2) return null;
    final scale = mean([for (final change in changes) change.abs()]);
    if (scale == 0) return 0;
    return populationStandardDeviation(changes) / scale;
  }

  /// Per-calendar-month multipliers against the series mean, e.g. `{7: 1.8}`
  /// means July typically books 1.8× an average month.
  ///
  /// `null` unless the series holds at least 12 points (a yearly shape cannot
  /// be claimed from less) and booked some revenue. Keys are 1..12, present
  /// only for months the series covers.
  Map<int, double>? seasonalIndex() {
    if (points.length < 12) return null;
    final overall = mean(revenues);
    if (overall <= 0) return null;
    final byMonth = <int, List<double>>{};
    for (final point in points) {
      byMonth.putIfAbsent(point.month, () => <double>[]).add(point.revenue);
    }
    return Map<int, double>.unmodifiable({
      for (final entry in byMonth.entries)
        entry.key: mean(entry.value) / overall,
    });
  }

  /// The last [n] months against the [n] months before them.
  ///
  /// Returns [RevenueWindowComparison.insufficient] when the series cannot
  /// cover both windows (`length < 2 × n`) or [n] is non-positive — a
  /// half-filled comparison would read as a crash that never happened.
  RevenueWindowComparison compareWindows(int n) {
    if (n <= 0 || points.length < 2 * n) {
      return RevenueWindowComparison.insufficient(n);
    }
    final recent = points.sublist(points.length - n);
    final previous = points.sublist(points.length - 2 * n, points.length - n);
    return RevenueWindowComparison(
      months: n,
      recentRevenue: recent.fold(0, (sum, p) => sum + p.revenue),
      previousRevenue: previous.fold(0, (sum, p) => sum + p.revenue),
      recentOrders: recent.fold(0, (sum, p) => sum + p.orderCount),
      previousOrders: previous.fold(0, (sum, p) => sum + p.orderCount),
      hasBothWindows: true,
    );
  }

  @override
  String toString() =>
      'RevenueSeries(${points.length} months, total: $totalRevenue, '
      'currentMonthExcluded: $currentMonthExcluded)';
}
