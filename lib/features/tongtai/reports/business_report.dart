import 'package:flutter/foundation.dart';

import '../consumer/customer_order.dart';
import '../core/tongtai_enums.dart';

/// Revenue booked in one calendar month — a single bar in the dashboard's
/// revenue trend (WTM-95).
@immutable
class MonthlyRevenue {
  const MonthlyRevenue({
    required this.year,
    required this.month,
    required this.revenue,
  });

  final int year;

  /// 1..12.
  final int month;

  /// Total đồng booked that month (cancelled orders excluded).
  final double revenue;

  /// Short month label, e.g. "Th7" (VI) — the x-axis tick.
  String get shortLabelVi => 'Th$month';

  /// Short month label, e.g. "Jul" (EN).
  String get shortLabelEn => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyRevenue &&
          other.year == year &&
          other.month == month &&
          other.revenue == revenue);

  @override
  int get hashCode => Object.hash(year, month, revenue);

  @override
  String toString() => 'MonthlyRevenue($year-$month, $revenue)';
}

/// Revenue attributed to one product category — a row in the dashboard's
/// top-categories widget (WTM-95).
@immutable
class CategoryRevenue {
  const CategoryRevenue({required this.category, required this.revenue});

  final String category;
  final double revenue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRevenue &&
          other.category == category &&
          other.revenue == revenue);

  @override
  int get hashCode => Object.hash(category, revenue);

  @override
  String toString() => 'CategoryRevenue($category, $revenue)';
}

/// A snapshot of the business's sales performance for the Reports & Analytics
/// dashboard (WTM-95 layout/widgets, WTM-96 revenue KPI).
///
/// All money figures are in Vietnamese đồng and exclude cancelled orders, the
/// same billable rule the customer-history metrics use (WTM-77).
@immutable
class BusinessReport {
  const BusinessReport({
    required this.revenueMtd,
    required this.revenueYtd,
    required this.ordersMtd,
    required this.ordersYtd,
    required this.averageOrderValue,
    required this.monthlyRevenue,
    required this.topCategories,
  });

  /// Revenue booked in the current calendar month (WTM-96 — MTD).
  final double revenueMtd;

  /// Revenue booked since 1 January of the current year (WTM-96 — YTD).
  final double revenueYtd;

  /// Billable orders this month.
  final int ordersMtd;

  /// Billable orders this year.
  final int ordersYtd;

  /// YTD average order value; 0 when there are no billable orders this year.
  final double averageOrderValue;

  /// Revenue per month over the trailing window, oldest first (WTM-95 chart).
  final List<MonthlyRevenue> monthlyRevenue;

  /// Categories by YTD revenue, highest first (WTM-95 top-categories widget).
  final List<CategoryRevenue> topCategories;

  /// The largest single month in [monthlyRevenue] — the chart's y-axis top.
  /// 0 when the window is empty or every month is zero.
  double get peakMonthlyRevenue =>
      monthlyRevenue.fold(0, (peak, m) => m.revenue > peak ? m.revenue : peak);

  /// True once at least one billable order exists this year — the screen shows
  /// the empty state until then.
  bool get hasSales => ordersYtd > 0;

  /// A report with no data (the seed for an empty business).
  static const BusinessReport empty = BusinessReport(
    revenueMtd: 0,
    revenueYtd: 0,
    ordersMtd: 0,
    ordersYtd: 0,
    averageOrderValue: 0,
    monthlyRevenue: [],
    topCategories: [],
  );
}

/// Aggregates sales orders into a [BusinessReport] (WTM-95/96).
///
/// Pure Dart over the in-memory [CustomerOrder] list — no database, no `intl`,
/// no clock of its own (the caller passes `now`) — so every figure is
/// deterministically unit-testable, mirroring [CustomerOrderHistoryService].
/// Swap the order source for a Drift-backed one later without touching the
/// dashboard.
class ReportsService {
  ReportsService(List<CustomerOrder> orders, {this.monthsBack = 6})
    : assert(monthsBack > 0, 'monthsBack must be positive'),
      _orders = List.unmodifiable(orders);

  /// Seeded with the built-in sample orders — the same fixtures the customer
  /// history uses, so the dashboard shows coherent numbers in demos and the
  /// closed beta.
  factory ReportsService.sample({int monthsBack = 6}) =>
      ReportsService(kSampleCustomerOrders, monthsBack: monthsBack);

  final List<CustomerOrder> _orders;

  /// How many trailing months the revenue trend spans (inclusive of `now`).
  final int monthsBack;

  /// Orders that count toward revenue: everything except cancelled, matching
  /// [OrderHistoryMetrics]'s billable rule.
  Iterable<CustomerOrder> get _billable =>
      _orders.where((o) => o.status != OrderStatus.cancelled);

  /// Builds the dashboard snapshot as of [now].
  BusinessReport reportAsOf(DateTime now) {
    final billable = _billable.toList(growable: false);

    final mtd = billable
        .where((o) => o.date.year == now.year && o.date.month == now.month)
        .toList(growable: false);
    final ytd = billable
        .where((o) => o.date.year == now.year)
        .toList(growable: false);

    final revenueYtd = _sum(ytd);

    return BusinessReport(
      revenueMtd: _sum(mtd),
      revenueYtd: revenueYtd,
      ordersMtd: mtd.length,
      ordersYtd: ytd.length,
      averageOrderValue: ytd.isEmpty ? 0 : revenueYtd / ytd.length,
      monthlyRevenue: _monthlySeries(billable, now),
      topCategories: _categorySeries(ytd),
    );
  }

  double _sum(Iterable<CustomerOrder> orders) =>
      orders.fold(0, (total, o) => total + o.totalAmount);

  /// [monthsBack] consecutive months ending with `now`'s month, oldest first.
  /// `DateTime` normalises month underflow, so December of the prior year is
  /// handled without special-casing.
  List<MonthlyRevenue> _monthlySeries(
    List<CustomerOrder> billable,
    DateTime now,
  ) {
    return [
      for (var i = monthsBack - 1; i >= 0; i--)
        () {
          final anchor = DateTime(now.year, now.month - i);
          return MonthlyRevenue(
            year: anchor.year,
            month: anchor.month,
            revenue: _sum(
              billable.where(
                (o) =>
                    o.date.year == anchor.year && o.date.month == anchor.month,
              ),
            ),
          );
        }(),
    ];
  }

  /// Per-category YTD revenue (from order line items), highest first.
  List<CategoryRevenue> _categorySeries(List<CustomerOrder> ytd) {
    final byCategory = <String, double>{};
    for (final order in ytd) {
      for (final item in order.items) {
        byCategory.update(
          item.category,
          (running) => running + item.lineTotal,
          ifAbsent: () => item.lineTotal,
        );
      }
    }
    return byCategory.entries
        .map((e) => CategoryRevenue(category: e.key, revenue: e.value))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }
}
