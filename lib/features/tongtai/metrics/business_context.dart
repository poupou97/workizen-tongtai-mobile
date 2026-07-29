import 'package:flutter/foundation.dart';

import '../consumer/customer_context.dart';
import '../finance/finance_context.dart';
import '../inventory/inventory_context.dart';
import '../journey/journey_context.dart';
import '../opportunity/opportunity_context.dart';
import '../orders/order_context.dart';
import '../timeline/timeline_context.dart';
import 'business_health.dart';
import 'business_metrics.dart';

export '../consumer/customer_context.dart' show CustomerSummary;
export '../finance/finance_context.dart' show FinanceSummary;
export '../inventory/inventory_context.dart' show InventorySummary;
export '../journey/journey_context.dart' show JourneySummary;
export '../opportunity/opportunity_context.dart' show OpportunitySummary;
export '../orders/order_context.dart' show OrderSummary;
export '../timeline/timeline_context.dart' show TimelineSummary;

/// Schema version of the [BusinessContext] snapshot. Bump when the snapshot
/// shape changes so consumers (Home, AI) can reason about the structure.
const int kBusinessContextVersion = 1;

/// **The Business Snapshot / Aggregate Root** (WTM-129/132, Founder). A single
/// read-only snapshot assembled by `BusinessContextService` from **one Context
/// Provider per capability** (WTM-131) via **Progressive Aggregation** — Phase 1
/// covered [metrics] + [customers] + [orders] + [inventory] + [opportunity] + the
/// embedded [health]; Phase 2 (WTM-133) folded in [journey] + [finance]; WTM-134
/// adds [timeline] (a derived activity-stream projection). Carries a [version] +
/// [generatedAt] so consumers can reason about it as a versioned snapshot.
///
/// **AI boundary (absolute):** Workizen AI reads *only* the BusinessContext —
/// never a Repository, Store, or Drift. Home also consumes it. Chain:
/// `Repositories → Capability Context Providers → BusinessContext → Home → AI`.
@immutable
class BusinessContext {
  const BusinessContext({
    required this.generatedAt,
    required this.metrics,
    required this.customers,
    required this.orders,
    required this.inventory,
    required this.opportunity,
    required this.journey,
    required this.finance,
    required this.timeline,
    required this.health,
    this.version = kBusinessContextVersion,
  });

  static final BusinessContext empty = BusinessContext(
    generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    metrics: BusinessMetrics.empty,
    customers: CustomerSummary.empty,
    orders: OrderSummary.empty,
    inventory: InventorySummary.empty,
    opportunity: OpportunitySummary.empty,
    journey: JourneySummary.empty,
    finance: FinanceSummary.empty,
    timeline: TimelineSummary.empty,
    health: BusinessHealth.notEnoughData,
  );

  /// Snapshot schema version (see [kBusinessContextVersion]).
  final int version;

  /// When this snapshot was assembled.
  final DateTime generatedAt;

  /// The canonical KPIs (revenue/orders/customers/AOV) — the KPI source of truth.
  final BusinessMetrics metrics;
  final CustomerSummary customers;
  final OrderSummary orders;
  final InventorySummary inventory;
  final OpportunitySummary opportunity;

  /// Business Journey slice — the seller's goals and how they're pacing (WTM-133).
  final JourneySummary journey;

  /// Finance slice — income/expense/profit snapshot (WTM-133).
  final FinanceSummary finance;

  /// Timeline slice — a derived *activity-stream* projection over the other
  /// capabilities (WTM-134). Read-only view; deliberately **not** part of
  /// [hasData] (it re-derives from finance/orders/journey, which already are).
  final TimelineSummary timeline;

  /// The business-health read, embedded in the snapshot (WTM-132).
  final BusinessHealth health;

  /// Whether the business has any real data yet (User Data First).
  ///
  /// [timeline] is intentionally excluded — it is a projection of the slices
  /// below, so counting it would double-count.
  bool get hasData =>
      metrics.hasSales ||
      customers.total > 0 ||
      inventory.productCount > 0 ||
      orders.total > 0 ||
      opportunity.total > 0 ||
      journey.total > 0 ||
      finance.hasActivity;
}
