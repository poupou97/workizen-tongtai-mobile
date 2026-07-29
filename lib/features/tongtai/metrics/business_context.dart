import 'package:flutter/foundation.dart';

import '../consumer/customer_context.dart';
import '../inventory/inventory_context.dart';
import '../opportunity/opportunity_context.dart';
import '../orders/order_context.dart';
import 'business_metrics.dart';

export '../consumer/customer_context.dart' show CustomerSummary;
export '../inventory/inventory_context.dart' show InventorySummary;
export '../opportunity/opportunity_context.dart' show OpportunitySummary;
export '../orders/order_context.dart' show OrderSummary;

/// **The Aggregate Root of the business** (WTM-129, Founder). A single read-only
/// snapshot assembled by `BusinessContextService` from **one Context Provider
/// per capability** (WTM-131) via **Progressive Aggregation** — Phase 1 covers
/// [metrics] + [customers] + [orders] + [inventory] + [opportunity];
/// Journey/Timeline/Goals/Finance add their provider later without changing this
/// contract.
///
/// **AI boundary (absolute):** Workizen AI reads *only* the BusinessContext —
/// never a Repository, Store, or Drift. Home also consumes it. Chain:
/// `Repositories → Capability Context Providers → BusinessContext →
/// BusinessHealth → Home → AI`.
@immutable
class BusinessContext {
  const BusinessContext({
    required this.metrics,
    required this.customers,
    required this.orders,
    required this.inventory,
    required this.opportunity,
  });

  static const BusinessContext empty = BusinessContext(
    metrics: BusinessMetrics.empty,
    customers: CustomerSummary.empty,
    orders: OrderSummary.empty,
    inventory: InventorySummary.empty,
    opportunity: OpportunitySummary.empty,
  );

  /// The canonical KPIs (revenue/orders/customers/AOV) — the KPI source of truth.
  final BusinessMetrics metrics;
  final CustomerSummary customers;
  final OrderSummary orders;
  final InventorySummary inventory;
  final OpportunitySummary opportunity;

  /// Whether the business has any real data yet (User Data First).
  bool get hasData =>
      metrics.hasSales ||
      customers.total > 0 ||
      inventory.productCount > 0 ||
      orders.total > 0 ||
      opportunity.total > 0;
}
