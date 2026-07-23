import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import 'customer_order.dart';

/// Filters applied to a customer's purchase history (WTM-77 AC4): an optional
/// inclusive date range and an optional product category. Immutable so the
/// screen holds one in state and rebuilds deterministically.
@immutable
class OrderHistoryQuery {
  const OrderHistoryQuery({this.from, this.to, this.category});

  /// Earliest order date to include (inclusive); null = no lower bound.
  final DateTime? from;

  /// Latest order date to include (inclusive); null = no upper bound.
  final DateTime? to;

  /// Only orders containing at least one item of this category; null = all.
  final String? category;

  bool get hasDateRange => from != null || to != null;

  /// Copy with overrides. `clearFrom`/`clearTo`/`clearCategory` reset a bound
  /// to null (a plain null argument can't distinguish "leave unchanged").
  OrderHistoryQuery copyWith({
    DateTime? from,
    DateTime? to,
    String? category,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearCategory = false,
  }) {
    return OrderHistoryQuery(
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

/// Aggregate purchase metrics for one customer (WTM-77 AC5). Cancelled orders
/// are excluded — they represent no realized purchase.
@immutable
class OrderHistoryMetrics {
  const OrderHistoryMetrics({
    required this.orderCount,
    required this.totalSpent,
    required this.averageOrderValue,
    required this.repurchaseRate,
  });

  /// Metrics for a customer with no (non-cancelled) orders.
  static const OrderHistoryMetrics empty = OrderHistoryMetrics(
    orderCount: 0,
    totalSpent: 0,
    averageOrderValue: 0,
    repurchaseRate: 0,
  );

  /// Non-cancelled orders counted into the metrics.
  final int orderCount;

  /// Sum of order totals, in đồng.
  final double totalSpent;

  /// [totalSpent] / [orderCount] (AC5); 0 when there are no orders.
  final double averageOrderValue;

  /// Share of orders that are repeat purchases: (orderCount − 1) / orderCount
  /// (AC5). 0 for a customer with 0 or 1 orders — no repurchase yet.
  final double repurchaseRate;
}

/// In-memory purchase-history source for the Consumer screens (WTM-77) —
/// local-first, no backend; a Drift-backed implementation over `OrdersTable`
/// can replace this without touching callers (same convention as
/// `CustomerDirectoryService`).
class CustomerOrderHistoryService {
  CustomerOrderHistoryService(List<CustomerOrder> orders)
    : _orders = List.unmodifiable(orders);

  /// Convenience constructor seeded with the built-in sample orders.
  factory CustomerOrderHistoryService.sample() =>
      CustomerOrderHistoryService(kSampleCustomerOrders);

  final List<CustomerOrder> _orders;

  /// All orders across all customers (unfiltered, unsorted).
  List<CustomerOrder> get all => _orders;

  /// [customerId]'s orders, newest first (AC1), after applying [query]'s date
  /// range (inclusive on both bounds) and category filter (AC4).
  List<CustomerOrder> ordersFor(
    String customerId, [
    OrderHistoryQuery query = const OrderHistoryQuery(),
  ]) {
    final results = <CustomerOrder>[
      for (final order in _orders)
        if (order.customerId == customerId && _matches(order, query)) order,
    ];
    // Newest first; id tiebreak keeps equal dates stable.
    results.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return results;
  }

  /// Distinct item categories across [customerId]'s orders, sorted — the AC4
  /// category filter facet.
  List<String> categoriesFor(String customerId) {
    final set = <String>{
      for (final order in _orders)
        if (order.customerId == customerId) ...order.categories,
    };
    final list = set.toList()..sort();
    return list;
  }

  /// Purchase metrics over [customerId]'s non-cancelled orders (AC5).
  OrderHistoryMetrics metricsFor(String customerId) {
    final counted = [
      for (final order in _orders)
        if (order.customerId == customerId &&
            order.status != OrderStatus.cancelled)
          order,
    ];
    if (counted.isEmpty) return OrderHistoryMetrics.empty;
    final total = counted.fold<double>(0, (sum, o) => sum + o.totalAmount);
    return OrderHistoryMetrics(
      orderCount: counted.length,
      totalSpent: total,
      averageOrderValue: total / counted.length,
      repurchaseRate: (counted.length - 1) / counted.length,
    );
  }

  bool _matches(CustomerOrder order, OrderHistoryQuery query) {
    final from = query.from;
    if (from != null && order.date.isBefore(from)) return false;
    final to = query.to;
    if (to != null && order.date.isAfter(to)) return false;
    final category = query.category;
    if (category != null && !order.categories.contains(category)) return false;
    return true;
  }
}
