import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import '../core/tongtai_enums.dart';
import '../inventory/product.dart';
import '../orders/order.dart';
import 'business_metrics.dart';

/// Customer-capability slice of the business snapshot (WTM-129).
@immutable
class CustomerSummary {
  const CustomerSummary({required this.total, required this.byTier});

  static const CustomerSummary empty = CustomerSummary(total: 0, byTier: {});

  final int total;

  /// Count of customers in each value tier (VIP/Gold/Silver/Bronze).
  final Map<CustomerTier, int> byTier;

  int tier(CustomerTier t) => byTier[t] ?? 0;

  factory CustomerSummary.from(List<Customer> customers) {
    final byTier = <CustomerTier, int>{};
    for (final c in customers) {
      byTier[c.tier] = (byTier[c.tier] ?? 0) + 1;
    }
    return CustomerSummary(total: customers.length, byTier: byTier);
  }
}

/// Order-capability slice of the business snapshot (WTM-129).
@immutable
class OrderSummary {
  const OrderSummary({required this.total, required this.byStatus});

  static const OrderSummary empty = OrderSummary(total: 0, byStatus: {});

  final int total;

  /// Count of orders in each lifecycle status.
  final Map<OrderStatus, int> byStatus;

  int status(OrderStatus s) => byStatus[s] ?? 0;

  /// Orders still open (not delivered or cancelled) — a useful attention signal.
  int get openCount =>
      total - status(OrderStatus.delivered) - status(OrderStatus.cancelled);

  factory OrderSummary.from(List<CustomerOrder> orders) {
    final byStatus = <OrderStatus, int>{};
    for (final o in orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
    }
    return OrderSummary(total: orders.length, byStatus: byStatus);
  }
}

/// Inventory-capability slice of the business snapshot (WTM-129).
@immutable
class InventorySummary {
  const InventorySummary({
    required this.productCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.stockValue,
  });

  static const InventorySummary empty = InventorySummary(
    productCount: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    stockValue: 0,
  );

  final int productCount;
  final int lowStockCount;
  final int outOfStockCount;

  /// On-hand stock value in đồng (Σ price × quantity).
  final double stockValue;

  factory InventorySummary.from(List<Product> products) {
    var low = 0;
    var out = 0;
    var value = 0.0;
    for (final p in products) {
      value += p.stockValue;
      switch (p.stockStatus) {
        case StockStatus.lowStock:
          low += 1;
        case StockStatus.outOfStock:
          out += 1;
        case StockStatus.inStock:
          break;
      }
    }
    return InventorySummary(
      productCount: products.length,
      lowStockCount: low,
      outOfStockCount: out,
      stockValue: value,
    );
  }
}

/// **The Aggregate Root of the business** (WTM-129, Founder). A single read-only
/// snapshot assembled by [BusinessContextService] via **Progressive
/// Aggregation** — Phase 1 covers [metrics] + [customers] + [orders] +
/// [inventory]; Opportunity/Journey/Timeline/Goals/Finance are added later
/// without changing this contract.
///
/// **AI boundary (absolute):** Workizen AI reads *only* the BusinessContext —
/// never a Repository, Store, or Drift. Home also consumes it. Chain:
/// `Repositories → BusinessMetricsService → BusinessContext → BusinessHealth →
/// Home → AI`.
@immutable
class BusinessContext {
  const BusinessContext({
    required this.metrics,
    required this.customers,
    required this.orders,
    required this.inventory,
  });

  static const BusinessContext empty = BusinessContext(
    metrics: BusinessMetrics.empty,
    customers: CustomerSummary.empty,
    orders: OrderSummary.empty,
    inventory: InventorySummary.empty,
  );

  /// The canonical KPIs (revenue/orders/customers/AOV) — the KPI source of truth.
  final BusinessMetrics metrics;
  final CustomerSummary customers;
  final OrderSummary orders;
  final InventorySummary inventory;

  /// Whether the business has any real data yet (User Data First).
  bool get hasData =>
      metrics.hasSales ||
      customers.total > 0 ||
      inventory.productCount > 0 ||
      orders.total > 0;
}
