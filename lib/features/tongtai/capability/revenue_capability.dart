import 'package:flutter/foundation.dart';

import '../analytics/revenue_series.dart';
import '../core/capability_context_provider.dart';
import '../core/tongtai_enums.dart';
import '../core/tongtai_formatters.dart';
import '../orders/order.dart';
import '../orders/order_context.dart';
import '../orders/order_repository.dart';
import 'capability_context.dart';

/// Machine name of the Revenue capability — the `capability` field of
/// [RevenueCapabilityContext] and the prefix a Rule Twin version string uses.
const String kRevenueCapability = 'revenue';

/// Schema version of [RevenueCapabilityContext]. Bump on any field/meaning
/// change (ADR-TON-016).
const int kRevenueCapabilityVersion = 1;

/// Default analysis window: 12 **completed** months — enough for a seasonal
/// index (`RevenueSeries.seasonalIndex` needs exactly that) and short enough to
/// still describe the business as it is today.
const int kRevenueCapabilityWindowMonths = 12;

/// Default like-for-like comparison: the last quarter against the one before
/// it. Three months is the shortest window that survives one freak month.
const int kRevenueCapabilityComparisonMonths = 3;

/// **Revenue Capability Context** (WTM-153, ADR-TON-016) — the deep revenue
/// analysis, loaded on demand by the Revenue Forecast screen and by the revenue
/// Rule Twin.
///
/// It carries the monthly [series] plus the derived shape of the business:
/// totals, AOV, growth (month-over-month **and** window-vs-window), trend
/// slope, volatility and — when a full year exists — the seasonal index. None
/// of that lives on `BusinessContext`, which keeps only the flat KPI summary
/// (the God-Object rule).
///
/// **Every number is delegated to `analytics/`**: this class does no bucketing,
/// no billable filtering and no statistics of its own. It composes
/// [RevenueSeries] (billable-only, `isBillableOrder`) with the existing
/// lifetime [OrderSummary]; if a number is missing here, it is added to the
/// analytics layer, never computed inline.
///
/// Read-only value object: no widgets, no mutation, no repository. The clock is
/// supplied by [RevenueCapabilityProvider], so the same orders and the same
/// `now` always produce the same context.
@immutable
class RevenueCapabilityContext implements CapabilityContext {
  /// Prefer [RevenueCapabilityContext.from] — this constructor exists so a test
  /// or a future cache can rebuild an exact context from its parts.
  const RevenueCapabilityContext({
    required this.generatedAt,
    required this.series,
    required this.orderHistory,
    required this.windowMonths,
    required this.comparisonMonths,
  });

  /// Builds the context from raw [orders] at instant [now].
  ///
  /// - [windowMonths] completed calendar months end at (but exclude) the
  ///   running month — a partial month always reads as a collapse next to full
  ///   ones, so it never enters the analysable base;
  /// - [comparisonMonths] sizes the like-for-like window comparison;
  /// - cancelled orders are excluded from revenue by [RevenueSeries] itself
  ///   (the shared `isBillableOrder` rule), so this context can never disagree
  ///   with `BusinessMetrics` or Reports;
  /// - [orderHistory] is the **lifetime** lifecycle breakdown of every order
  ///   (all statuses, no window) — the same [OrderSummary] the business
  ///   snapshot uses, reused rather than recounted.
  factory RevenueCapabilityContext.from({
    required Iterable<CustomerOrder> orders,
    required DateTime now,
    int windowMonths = kRevenueCapabilityWindowMonths,
    int comparisonMonths = kRevenueCapabilityComparisonMonths,
  }) {
    final all = orders.toList(growable: false);
    return RevenueCapabilityContext(
      generatedAt: now,
      series: RevenueSeries.fromOrders(all, now: now, months: windowMonths),
      orderHistory: OrderSummary.from(all),
      windowMonths: windowMonths,
      comparisonMonths: comparisonMonths,
    );
  }

  /// The monthly billable-revenue history, oldest → newest, one point per month
  /// in the window (empty months included as explicit zeros).
  final RevenueSeries series;

  /// Lifetime order-lifecycle summary — total and per-status counts across the
  /// whole history, **not** windowed and **not** billable-filtered. It answers
  /// "how many orders exist and how many are still open", which the windowed
  /// [series] deliberately cannot.
  final OrderSummary orderHistory;

  /// Requested analysis window, in completed calendar months.
  final int windowMonths;

  /// Requested size of each side of [comparison].
  final int comparisonMonths;

  @override
  final DateTime generatedAt;

  @override
  String get capability => kRevenueCapability;

  @override
  int get version => kRevenueCapabilityVersion;

  /// True when at least one completed month in the window booked billable
  /// revenue. A directory of cancelled or out-of-window orders is **not** data
  /// for this capability — see the honesty rule on [CapabilityContext].
  @override
  bool get hasData => series.hasRevenue;

  /// Total billable revenue inside the window, in đồng.
  double get totalRevenue => series.totalRevenue;

  /// Billable orders inside the window.
  int get billableOrders => series.totalOrders;

  /// Average order value across the window (`0` when it booked nothing).
  double get averageOrderValue => series.averageOrderValue;

  /// Months in the window that booked something — the sufficiency signal.
  int get monthsWithRevenue => series.monthsWithRevenue;

  /// The most recent **completed** month, or `null` for an empty window.
  MonthlyRevenuePoint? get latestMonth => series.latest;

  /// Whether the running month was left out of the base (always true for the
  /// default window; surfaced so a twin can state the caveat).
  bool get currentMonthExcluded => series.currentMonthExcluded;

  /// Last month vs the month before, as a fraction (`0.25` = +25%). `null` with
  /// fewer than two months or when the earlier month booked nothing.
  double? get monthOverMonthGrowth => series.monthOverMonthChange;

  /// The last [comparisonMonths] months against the [comparisonMonths] before
  /// them. `hasBothWindows` is false when the history cannot cover both.
  RevenueWindowComparison get comparison =>
      series.compareWindows(comparisonMonths);

  /// Least-squares trend over the window, in **đồng per month**. `null` below
  /// two months — "no trend known" is not the same as a flat 0.
  double? get trendSlopePerMonth => series.linearTrendSlope();

  /// Relative dispersion of the month-over-month changes: `0` is a steady
  /// rhythm, `≈ 1` and above is a wild business. `null` below two usable
  /// changes.
  double? get volatility => series.volatility();

  /// Per-calendar-month multipliers against the window mean (`{7: 1.85}` =
  /// July books 1.85× an average month). `null` below 12 months or with no
  /// revenue — a yearly shape cannot be claimed from less.
  Map<int, double>? get seasonalIndex => series.seasonalIndex();

  /// PII-free revenue block for the AI layer.
  ///
  /// Aggregates only — this capability never touches customer identity, so
  /// there is nothing personal to leak. When [hasData] is false it states the
  /// insufficiency instead of printing a wall of zeros.
  @override
  String promptBlock() {
    final buffer = StringBuffer()
      ..writeln(capabilityPromptHeader(this))
      ..writeln(
        '- Cửa sổ phân tích: $windowMonths tháng'
        '${currentMonthExcluded ? ' hoàn chỉnh (tháng đang chạy bị loại trừ vì chưa xong)' : ' (gồm cả tháng đang chạy)'}',
      );

    if (!hasData) {
      buffer
        ..writeln(
          '- CHƯA ĐỦ DỮ LIỆU: không tháng nào trong cửa sổ ghi nhận doanh thu '
          'billable.',
        )
        ..writeln(
          '- Lịch sử đơn (toàn bộ vòng đời): ${orderHistory.total} đơn'
          '${orderHistory.total == 0 ? '' : ' — không đơn nào rơi vào cửa sổ hoặc tất cả đã hủy'}.',
        )
        ..write(
          '- Không được suy ra xu hướng, tăng trưởng hay dự báo từ khối này.',
        );
      return buffer.toString();
    }

    buffer
      ..writeln(
        '- Doanh thu billable: ${TongtaiFormatters.vnd(totalRevenue)}'
        ' · $billableOrders đơn'
        ' · AOV ${TongtaiFormatters.vnd(averageOrderValue)}',
      )
      ..writeln('- Tháng có doanh thu: $monthsWithRevenue/${series.length}');

    final latest = latestMonth;
    if (latest != null) {
      buffer.writeln(
        '- Tháng gần nhất ${latest.key}: ${TongtaiFormatters.vnd(latest.revenue)}'
        ' · ${latest.orderCount} đơn'
        ' · ${latest.customerCount} khách',
      );
    }

    buffer.writeln(
      '- Tăng trưởng tháng gần nhất so với tháng trước: '
      '${capabilityPercent(monthOverMonthGrowth)}',
    );

    final window = comparison;
    if (window.hasBothWindows) {
      buffer.writeln(
        '- ${window.months} tháng gần nhất so với ${window.months} tháng trước đó: '
        '${TongtaiFormatters.vnd(window.recentRevenue)} so với '
        '${TongtaiFormatters.vnd(window.previousRevenue)} '
        '(${capabilityPercent(window.revenueChange)})'
        ' · đơn ${window.recentOrders} so với ${window.previousOrders} '
        '(${capabilityPercent(window.ordersChange)})',
      );
    } else {
      buffer.writeln(
        '- So sánh ${window.months} tháng: chưa đủ lịch sử cho cả hai cửa sổ.',
      );
    }

    final slope = trendSlopePerMonth;
    buffer
      ..writeln(
        '- Xu hướng tuyến tính: '
        '${slope == null ? 'không xác định' : '${TongtaiFormatters.vnd(slope)}/tháng'}',
      )
      ..writeln(
        '- Độ biến động (phân tán của thay đổi theo tháng): '
        '${capabilityDecimal(volatility)}',
      );

    final seasonal = seasonalIndex;
    if (seasonal == null || seasonal.isEmpty) {
      buffer.writeln('- Mùa vụ: chưa xác định (cần đủ 12 tháng có doanh thu).');
    } else {
      final ranked = seasonal.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final peak = ranked.first;
      final trough = ranked.last;
      buffer.writeln(
        '- Mùa vụ: cao nhất T${peak.key} ${capabilityDecimal(peak.value)}×'
        ' · thấp nhất T${trough.key} ${capabilityDecimal(trough.value)}×',
      );
    }

    buffer.write(
      '- Lịch sử đơn (toàn bộ vòng đời): ${orderHistory.total} đơn'
      ' · đang mở ${orderHistory.openCount}'
      ' · đã hủy ${orderHistory.status(OrderStatus.cancelled)}',
    );
    return buffer.toString();
  }

  @override
  String toString() =>
      'RevenueCapabilityContext(v$version, $windowMonths mo, '
      'revenue: $totalRevenue, orders: $billableOrders, hasData: $hasData)';
}

/// The Revenue capability's **on-demand** context provider (WTM-153) — the same
/// [CapabilityContextProvider] seam every capability uses (WTM-131), but this
/// one is deliberately **not** wired into `BusinessContextService`: the deep
/// analysis is loaded by the screen/twin that asks for it, so Home does not pay
/// for a 12-month series it never renders (ADR-TON-016).
class RevenueCapabilityProvider
    implements CapabilityContextProvider<RevenueCapabilityContext> {
  const RevenueCapabilityProvider(
    this._orders, {
    this.clock = DateTime.now,
    this.windowMonths = kRevenueCapabilityWindowMonths,
    this.comparisonMonths = kRevenueCapabilityComparisonMonths,
  });

  final OrderRepository _orders;

  /// The only clock in the chain — read once per [load], never inside the
  /// computation, so tests pin it and get a deterministic context.
  final DateTime Function() clock;

  final int windowMonths;
  final int comparisonMonths;

  @override
  Future<RevenueCapabilityContext> load() async =>
      RevenueCapabilityContext.from(
        orders: await _orders.loadAll(),
        now: clock(),
        windowMonths: windowMonths,
        comparisonMonths: comparisonMonths,
      );
}
