import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import '../consumer/customer_directory_service.dart';
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

/// Revenue + units for one product — a row in the top-products widget (WTM-97).
@immutable
class ProductRevenue {
  const ProductRevenue({
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
      (other is ProductRevenue &&
          other.name == name &&
          other.revenue == revenue &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(name, revenue, quantity);

  @override
  String toString() => 'ProductRevenue($name, $revenue, x$quantity)';
}

/// Spend + order count for one customer — a row in the top-customers widget
/// (WTM-97). [name] is resolved from the customer directory; falls back to the
/// id when unknown.
@immutable
class CustomerSpend {
  const CustomerSpend({
    required this.customerId,
    required this.name,
    required this.spend,
    required this.orders,
  });

  final String customerId;
  final String name;
  final double spend;
  final int orders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerSpend &&
          other.customerId == customerId &&
          other.name == name &&
          other.spend == spend &&
          other.orders == orders);

  @override
  int get hashCode => Object.hash(customerId, name, spend, orders);

  @override
  String toString() => 'CustomerSpend($name, $spend, $orders orders)';
}

/// The window a Reports **breakdown** is scoped to (WTM-115). The four headline
/// KPIs stay canonical/all-business (BusinessMetrics, ADR-TON-011); only the
/// breakdown sections (categories/products/customers) respond to this.
enum ReportPeriod {
  thisMonth,
  thisQuarter,
  thisYear,
  allTime;

  String get labelVi => switch (this) {
    ReportPeriod.thisMonth => 'Tháng này',
    ReportPeriod.thisQuarter => 'Quý này',
    ReportPeriod.thisYear => 'Năm nay',
    ReportPeriod.allTime => 'Tất cả',
  };

  String get labelEn => switch (this) {
    ReportPeriod.thisMonth => 'This month',
    ReportPeriod.thisQuarter => 'This quarter',
    ReportPeriod.thisYear => 'This year',
    ReportPeriod.allTime => 'All time',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// The inclusive `[start, end]` calendar window as of [now]. `allTime` spans
  /// everything. `thisYear` equals the classic year-to-date breakdown window.
  (DateTime, DateTime) range(DateTime now) {
    switch (this) {
      case ReportPeriod.thisMonth:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case ReportPeriod.thisQuarter:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(now.year, startMonth, 1),
          DateTime(now.year, startMonth + 3, 0, 23, 59, 59, 999),
        );
      case ReportPeriod.thisYear:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59, 999),
        );
      case ReportPeriod.allTime:
        return (DateTime.utc(1970), DateTime(9999, 12, 31, 23, 59, 59, 999));
    }
  }
}

/// The sales breakdown over a chosen [ReportPeriod] (WTM-115) — the period-scoped
/// half of the dashboard, alongside the all-business headline KPIs.
@immutable
class PeriodBreakdown {
  const PeriodBreakdown({
    required this.revenue,
    required this.orders,
    required this.topCategories,
    required this.topProducts,
    required this.topCustomers,
  });

  static const PeriodBreakdown empty = PeriodBreakdown(
    revenue: 0,
    orders: 0,
    topCategories: [],
    topProducts: [],
    topCustomers: [],
  );

  /// Billable revenue booked in the window.
  final double revenue;

  /// Billable order count in the window.
  final int orders;

  final List<CategoryRevenue> topCategories;
  final List<ProductRevenue> topProducts;
  final List<CustomerSpend> topCustomers;

  bool get hasSales => orders > 0;
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
    this.topProducts = const [],
    this.topCustomers = const [],
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

  /// Products by YTD revenue, highest first (WTM-97 top-products widget).
  final List<ProductRevenue> topProducts;

  /// Customers by YTD spend, highest first (WTM-97 top-customers widget).
  final List<CustomerSpend> topCustomers;

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
  ReportsService(
    List<CustomerOrder> orders, {
    this.monthsBack = 6,
    List<Customer> customers = const [],
  }) : assert(monthsBack > 0, 'monthsBack must be positive'),
       _orders = List.unmodifiable(orders),
       _customerNames = {for (final c in customers) c.id: c.name};

  /// Seeded with the built-in sample orders + customers — the same fixtures the
  /// customer history uses, so the dashboard shows coherent numbers in demos and
  /// the closed beta.
  factory ReportsService.sample({int monthsBack = 6}) => ReportsService(
    kSampleCustomerOrders,
    monthsBack: monthsBack,
    customers: kSampleCustomers,
  );

  final List<CustomerOrder> _orders;

  /// The orders this service reports over (WTM-127) — read-only, so callers can
  /// derive [BusinessMetrics] from the same data without a second load.
  List<CustomerOrder> get all => List.unmodifiable(_orders);

  /// customerId → display name, for the top-customers widget (WTM-97).
  final Map<String, String> _customerNames;

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
      topProducts: _productSeries(ytd),
      topCustomers: _customerSeries(ytd),
    );
  }

  /// The sales breakdown scoped to [period] as of [now] (WTM-115).
  PeriodBreakdown breakdownFor(DateTime now, ReportPeriod period) {
    final (start, end) = period.range(now);
    return breakdownForRange(start, end);
  }

  /// The sales breakdown over an explicit inclusive `[start, end]` window
  /// (WTM-115). Only the breakdown sections are period-scoped — the headline
  /// KPIs remain all-business (BusinessMetrics).
  PeriodBreakdown breakdownForRange(DateTime start, DateTime end) {
    final inRange = _billable
        .where((o) => !o.date.isBefore(start) && !o.date.isAfter(end))
        .toList(growable: false);
    return PeriodBreakdown(
      revenue: _sum(inRange),
      orders: inRange.length,
      topCategories: _categorySeries(inRange),
      topProducts: _productSeries(inRange),
      topCustomers: _customerSeries(inRange),
    );
  }

  double _sum(Iterable<CustomerOrder> orders) =>
      orders.fold(0, (total, o) => total + o.totalAmount);

  /// Products by YTD revenue (from order line items), highest first, top 5.
  List<ProductRevenue> _productSeries(List<CustomerOrder> ytd) {
    final revenue = <String, double>{};
    final quantity = <String, int>{};
    for (final order in ytd) {
      for (final item in order.items) {
        revenue.update(
          item.productName,
          (r) => r + item.lineTotal,
          ifAbsent: () => item.lineTotal,
        );
        quantity.update(
          item.productName,
          (q) => q + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final products =
        revenue.entries
            .map(
              (e) => ProductRevenue(
                name: e.key,
                revenue: e.value,
                quantity: quantity[e.key]!,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return products.take(5).toList();
  }

  /// Customers by YTD spend, highest first, top 5.
  List<CustomerSpend> _customerSeries(List<CustomerOrder> ytd) {
    final spend = <String, double>{};
    final orders = <String, int>{};
    for (final order in ytd) {
      spend.update(
        order.customerId,
        (s) => s + order.totalAmount,
        ifAbsent: () => order.totalAmount,
      );
      orders.update(order.customerId, (n) => n + 1, ifAbsent: () => 1);
    }
    final customers =
        spend.entries
            .map(
              (e) => CustomerSpend(
                customerId: e.key,
                name: _customerNames[e.key] ?? e.key,
                spend: e.value,
                orders: orders[e.key]!,
              ),
            )
            .toList()
          ..sort((a, b) => b.spend.compareTo(a.spend));
    return customers.take(5).toList();
  }

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
