import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import '../orders/order.dart';

/// The canonical top-level business KPIs (WTM-127, Founder) — a read-only
/// aggregate produced by [BusinessMetricsService], the single source of truth
/// for KPIs across the product. Reports, Home and (later) BusinessContext + AI
/// **reuse** these values instead of each computing their own.
///
/// Initial KPIs: revenue · orders count · customers count · average order value.
/// Future KPIs (top products, repeat customers, monthly trends, CLV, forecast…)
/// extend this aggregate + [BusinessMetricsService] rather than duplicating the
/// calculation anywhere else.
@immutable
class BusinessMetrics {
  const BusinessMetrics({
    required this.revenue,
    required this.ordersCount,
    required this.customersCount,
    required this.averageOrderValue,
  });

  /// A zero snapshot — a brand-new business with no data (User Data First).
  static const BusinessMetrics empty = BusinessMetrics(
    revenue: 0,
    ordersCount: 0,
    customersCount: 0,
    averageOrderValue: 0,
  );

  /// Total billable revenue in đồng (cancelled orders excluded).
  final double revenue;

  /// Number of billable orders (cancelled orders excluded).
  final int ordersCount;

  /// Number of customers in the directory.
  final int customersCount;

  /// Revenue ÷ billable order count, or 0 when there are no billable orders.
  final double averageOrderValue;

  /// Whether the business has any billable sales yet.
  bool get hasSales => ordersCount > 0;

  /// Computes the canonical KPIs from persisted [orders] + a [customersCount].
  /// Cancelled orders are excluded (the billable rule, matching the Reports
  /// aggregation). This is the ONE place order revenue is turned into KPIs.
  factory BusinessMetrics.from({
    required List<CustomerOrder> orders,
    required int customersCount,
  }) {
    var revenue = 0.0;
    var count = 0;
    for (final order in orders) {
      if (order.status == OrderStatus.cancelled) continue;
      revenue += order.totalAmount;
      count += 1;
    }
    return BusinessMetrics(
      revenue: revenue,
      ordersCount: count,
      customersCount: customersCount,
      averageOrderValue: count == 0 ? 0 : revenue / count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessMetrics &&
          other.revenue == revenue &&
          other.ordersCount == ordersCount &&
          other.customersCount == customersCount &&
          other.averageOrderValue == averageOrderValue);

  @override
  int get hashCode =>
      Object.hash(revenue, ordersCount, customersCount, averageOrderValue);

  @override
  String toString() =>
      'BusinessMetrics(revenue: $revenue, orders: $ordersCount, '
      'customers: $customersCount, aov: $averageOrderValue)';
}
