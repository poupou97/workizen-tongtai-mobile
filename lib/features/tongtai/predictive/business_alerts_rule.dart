import 'package:flutter/foundation.dart';

import '../analytics/cashflow_series.dart';
import '../analytics/revenue_series.dart';
import '../capability/customer_capability.dart';
import '../capability/revenue_capability.dart';
import '../inventory/product.dart';
import '../inventory/stock_alert_service.dart';
import 'rule_twin.dart';

/// **Business Alerts Rule Twin** (WTM-157, ADR-TON-016) — the AUTHORITATIVE
/// deterministic answer to "what needs my attention today?".
///
/// Runs with **no AI, no network, no key**. Every signal is read from a
/// capability context or an existing aggregation service; nothing is recounted
/// here (ADR-TON-015 One Data Path):
///
/// | Alert | Source |
/// |---|---|
/// | [BusinessAlertKind.revenueDrop] | `RevenueCapabilityContext.comparison` |
/// | [BusinessAlertKind.ordersDrop] | `RevenueCapabilityContext.comparison` |
/// | [BusinessAlertKind.stockBelowReorder] | `StockAlertService` (WTM-70) |
/// | [BusinessAlertKind.negativeCashflow] | `CashflowSeries.monthsInDeficit` |
/// | [BusinessAlertKind.customerRisk] | `CustomerCapabilityContext` lifecycle |
///
/// **An empty alert list is a real answer.** "Nothing is wrong" is exactly what
/// a healthy business should be told, so the twin returns
/// [DataSufficiency.sufficient] with `result: <empty list>` — never
/// `insufficient`, which is reserved for "I cannot judge at all".

// ── Thresholds ──────────────────────────────────────────────────────────────
//
// Chosen so a Vietnamese SME's normal month-to-month wobble stays silent: a
// noise band of ±10% on the window-vs-window comparison (a quarter against the
// previous quarter by default — three months already absorb one freak week).

/// Fractional drop at which a revenue/orders alert is raised at all — below this
/// the movement is noise, and an alert that cries wolf gets muted by the user.
const double kBusinessAlertDropWarning = 0.10;

/// Fractional drop at which a revenue/orders alert becomes
/// [BusinessAlertSeverity.critical] — a third of the business, gone.
const double kBusinessAlertDropCritical = 0.30;

/// Band inside which the window-vs-window comparison is reported as
/// [ReasonCode.revenueFlat] rather than growing/declining.
const double kBusinessAlertTrendNoiseBand = kBusinessAlertDropWarning;

/// Share of the directory that must be lapsed (at risk + churned) before a
/// [BusinessAlertKind.customerRisk] alert is raised.
const double kBusinessAlertLapsedShareWarning = 0.20;

/// Lapsed share at which the customer alert becomes
/// [BusinessAlertSeverity.critical] — more than a third of the book is going.
const double kBusinessAlertLapsedShareCritical = 0.35;

/// Share of months in the window that may run a deficit while the alert stays
/// [BusinessAlertSeverity.info] — provided the window as a whole still profits.
/// One bad month in three is a restock month, not a crisis.
const double kBusinessAlertDeficitShareTolerated = 1 / 3;

/// How many independent signals must be readable before the twin claims
/// [ForecastConfidence.high].
const int kBusinessAlertHighConfidenceSources = 3;

/// What kind of thing is wrong.
enum BusinessAlertKind {
  revenueDrop,
  ordersDrop,
  stockBelowReorder,
  negativeCashflow,
  customerRisk;

  String get labelVi => switch (this) {
    BusinessAlertKind.revenueDrop => 'Doanh thu giảm',
    BusinessAlertKind.ordersDrop => 'Số đơn giảm',
    BusinessAlertKind.stockBelowReorder => 'Tồn kho dưới mức đặt lại',
    BusinessAlertKind.negativeCashflow => 'Dòng tiền âm',
    BusinessAlertKind.customerRisk => 'Khách hàng rủi ro',
  };
}

/// How loud the alert should be. Ordered ascending, so the enum index doubles
/// as the sort key (see [BusinessAlertsRule]'s ordering rule).
enum BusinessAlertSeverity {
  /// Worth knowing, nothing to do today.
  info,

  /// Act this week.
  warning,

  /// Act now.
  critical;

  String get labelVi => switch (this) {
    BusinessAlertSeverity.info => 'Thông tin',
    BusinessAlertSeverity.warning => 'Cảnh báo',
    BusinessAlertSeverity.critical => 'Nghiêm trọng',
  };
}

/// One raised business alert.
///
/// [metricValue] / [comparisonValue] are "the number, and what it is judged
/// against", per kind:
///
/// | Kind | metricValue | comparisonValue | affectedCount |
/// |---|---|---|---|
/// | revenueDrop | recent-window revenue (đ) | previous-window revenue (đ) | months per window |
/// | ordersDrop | recent-window orders | previous-window orders | months per window |
/// | stockBelowReorder | products at/below reorder | products in the catalog | products at/below reorder |
/// | negativeCashflow | months in deficit | months in the window | months in deficit |
/// | customerRisk | lapsed customers | customers in the directory | lapsed customers |
///
/// Money is allowed here (this object drives the UI); the PII-free string that
/// reaches the AI and telemetry is [RuleTwinResult.provenance], which carries
/// codes and bands only.
@immutable
class BusinessAlert {
  const BusinessAlert({
    required this.kind,
    required this.severity,
    required this.reasonCodes,
    required this.metricValue,
    required this.comparisonValue,
    required this.affectedCount,
  });

  final BusinessAlertKind kind;
  final BusinessAlertSeverity severity;

  /// Why — from the shared [ReasonCode] contract, never empty.
  final List<ReasonCode> reasonCodes;

  final double metricValue;
  final double comparisonValue;

  /// How many things (products, months, customers) this alert covers.
  final int affectedCount;

  /// [metricValue] as a fraction of [comparisonValue]; `null` when there is
  /// nothing to divide by.
  double? get share =>
      comparisonValue == 0 ? null : metricValue / comparisonValue;

  /// Signed fractional change from [comparisonValue] to [metricValue] — e.g.
  /// `-0.4` for a 40% drop. `null` when the comparison base is zero.
  double? get change => comparisonValue == 0
      ? null
      : (metricValue - comparisonValue) / comparisonValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessAlert &&
          other.kind == kind &&
          other.severity == severity &&
          other.metricValue == metricValue &&
          other.comparisonValue == comparisonValue &&
          other.affectedCount == affectedCount &&
          listEquals(other.reasonCodes, reasonCodes));

  @override
  int get hashCode => Object.hash(
    kind,
    severity,
    metricValue,
    comparisonValue,
    affectedCount,
    Object.hashAll(reasonCodes),
  );

  @override
  String toString() =>
      'BusinessAlert(${kind.name}, ${severity.name}, '
      'metric: $metricValue vs $comparisonValue, affected: $affectedCount, '
      'reasons: ${reasonCodes.map((r) => r.code).join(',')})';
}

/// Evaluates the deterministic business-alert rules across capabilities.
///
/// Pure: no clock read (`revenue.generatedAt` is the instant), no repository,
/// no Riverpod, no AI. Same inputs → byte-identical alert list and ordering.
class BusinessAlertsRule {
  const BusinessAlertsRule();

  /// Formula version — bump when a threshold, a severity band or a reason-code
  /// meaning changes (ADR-TON-016).
  static const String version = 'business-alerts/1';

  /// Raises every alert the data supports, **most severe first** (then by
  /// [BusinessAlertKind] declaration order, so the list is totally ordered).
  ///
  /// **Sufficiency** — measured on how many of the four signals are readable
  /// (revenue comparison · customers · stock · cashflow):
  /// - none readable → [DataSufficiency.insufficient] (a brand-new business has
  ///   nothing to be alerted about, and saying "all clear" would be a lie);
  /// - readable, but the revenue window-vs-window comparison is missing →
  ///   [DataSufficiency.partial] with [ForecastConfidence.low]: the headline
  ///   signal is absent and the caller must say so;
  /// - otherwise [DataSufficiency.sufficient], [ForecastConfidence.high] once
  ///   at least [kBusinessAlertHighConfidenceSources] signals are readable,
  ///   else [ForecastConfidence.medium].
  RuleTwinResult<List<BusinessAlert>> evaluate({
    required RevenueCapabilityContext revenue,
    required CustomerCapabilityContext customers,
    CashflowSeries? cashflow,
    List<Product> products = const [],
  }) {
    final now = revenue.generatedAt;
    final comparison = revenue.comparison;
    final revenueComparable =
        comparison.hasBothWindows && comparison.previousRevenue > 0;
    final ordersComparable =
        comparison.hasBothWindows && comparison.previousOrders > 0;
    final customersKnown = customers.hasData;
    final stockKnown = products.isNotEmpty;
    final cashKnown = cashflow != null && cashflow.hasTransactions;

    final readable = [
      revenueComparable || ordersComparable,
      customersKnown,
      stockKnown,
      cashKnown,
    ].where((known) => known).length;

    if (readable == 0) {
      return RuleTwinResult<List<BusinessAlert>>.insufficient(
        reasonCodes: [
          ReasonCode.notEnoughHistory,
          if (!customersKnown) ReasonCode.noCustomers,
          if (!revenue.hasData) ReasonCode.noRevenueYet,
        ],
        version: version,
        generatedAt: now,
      );
    }

    final alerts = <BusinessAlert>[
      ?_revenueDrop(comparison, revenueComparable),
      ?_ordersDrop(comparison, ordersComparable),
      ?_stock(products),
      ?_cashflow(cashflow),
      ?_customerRisk(customers),
    ]..sort(_compare);

    final reasons = <ReasonCode>[
      for (final alert in alerts) ...alert.reasonCodes,
    ];
    // Nothing wrong is still an answer — say what the revenue is doing instead
    // of returning an empty "why", which the envelope forbids.
    if (!alerts.any((a) => a.kind == BusinessAlertKind.revenueDrop)) {
      final trend = _trendCode(comparison, revenueComparable);
      if (trend != null) reasons.add(trend);
    }
    if (!revenueComparable && !ordersComparable) {
      reasons.add(ReasonCode.notEnoughHistory);
    }
    if (revenue.currentMonthExcluded) {
      reasons.add(ReasonCode.partialMonthExcluded);
    }

    final partial = !revenueComparable;
    return RuleTwinResult<List<BusinessAlert>>(
      result: List<BusinessAlert>.unmodifiable(alerts),
      confidence: partial
          ? ForecastConfidence.low
          : (readable >= kBusinessAlertHighConfidenceSources
                ? ForecastConfidence.high
                : ForecastConfidence.medium),
      sufficiency: partial
          ? DataSufficiency.partial
          : DataSufficiency.sufficient,
      reasonCodes: List<ReasonCode>.unmodifiable(_distinct(reasons)),
      version: version,
      generatedAt: now,
    );
  }

  // ── Individual rules ──────────────────────────────────────────────────────

  BusinessAlert? _revenueDrop(
    RevenueWindowComparison comparison,
    bool comparable,
  ) {
    if (!comparable) return null;
    final change = comparison.revenueChange;
    if (change == null || change > -kBusinessAlertDropWarning) return null;
    return BusinessAlert(
      kind: BusinessAlertKind.revenueDrop,
      severity: change <= -kBusinessAlertDropCritical
          ? BusinessAlertSeverity.critical
          : BusinessAlertSeverity.warning,
      reasonCodes: const [
        ReasonCode.revenueDropVsPrevious,
        ReasonCode.revenueDeclining,
      ],
      metricValue: comparison.recentRevenue,
      comparisonValue: comparison.previousRevenue,
      affectedCount: comparison.months,
    );
  }

  BusinessAlert? _ordersDrop(
    RevenueWindowComparison comparison,
    bool comparable,
  ) {
    if (!comparable) return null;
    final change = comparison.ordersChange;
    if (change == null || change > -kBusinessAlertDropWarning) return null;
    return BusinessAlert(
      kind: BusinessAlertKind.ordersDrop,
      severity: change <= -kBusinessAlertDropCritical
          ? BusinessAlertSeverity.critical
          : BusinessAlertSeverity.warning,
      reasonCodes: const [ReasonCode.ordersDropVsPrevious],
      metricValue: comparison.recentOrders.toDouble(),
      comparisonValue: comparison.previousOrders.toDouble(),
      affectedCount: comparison.months,
    );
  }

  /// Inventory alert — delegated wholesale to the existing [StockAlertService]
  /// (WTM-70). This twin adds no second opinion about what "low stock" means.
  BusinessAlert? _stock(List<Product> products) {
    if (products.isEmpty) return null;
    final service = StockAlertService(products);
    if (!service.hasAlerts) return null;
    return BusinessAlert(
      kind: BusinessAlertKind.stockBelowReorder,
      severity: service.outOfStockCount > 0
          ? BusinessAlertSeverity.critical
          : BusinessAlertSeverity.warning,
      reasonCodes: const [ReasonCode.stockBelowReorder],
      metricValue: service.totalCount.toDouble(),
      comparisonValue: products.length.toDouble(),
      affectedCount: service.totalCount,
    );
  }

  BusinessAlert? _cashflow(CashflowSeries? cashflow) {
    if (cashflow == null || cashflow.isEmpty) return null;
    final deficits = cashflow.monthsInDeficit;
    if (deficits == 0) return null;
    final share = deficits / cashflow.length;
    final severity = cashflow.totalProfit < 0
        ? BusinessAlertSeverity.critical
        : (share <= kBusinessAlertDeficitShareTolerated
              ? BusinessAlertSeverity.info
              : BusinessAlertSeverity.warning);
    return BusinessAlert(
      kind: BusinessAlertKind.negativeCashflow,
      severity: severity,
      reasonCodes: const [ReasonCode.negativeCashflow],
      metricValue: deficits.toDouble(),
      comparisonValue: cashflow.length.toDouble(),
      affectedCount: deficits,
    );
  }

  BusinessAlert? _customerRisk(CustomerCapabilityContext customers) {
    if (!customers.hasData) return null;
    final lapsed = customers.lapsedCount;
    if (lapsed == 0) return null;
    final share = lapsed / customers.totalCustomers;
    if (share < kBusinessAlertLapsedShareWarning) return null;
    final churned = customers.stage(CustomerLifecycleStage.churned);
    final codes = <ReasonCode>[
      if (customers.winBackCandidateCount > 0) ReasonCode.highValueAtRisk,
      if (churned > 0) ReasonCode.inactiveBeyondChurnWindow,
    ];
    return BusinessAlert(
      kind: BusinessAlertKind.customerRisk,
      severity: share >= kBusinessAlertLapsedShareCritical
          ? BusinessAlertSeverity.critical
          : BusinessAlertSeverity.warning,
      reasonCodes: codes.isEmpty
          ? const [ReasonCode.purchaseGapExceeded]
          : List<ReasonCode>.unmodifiable(codes),
      metricValue: lapsed.toDouble(),
      comparisonValue: customers.totalCustomers.toDouble(),
      affectedCount: lapsed,
    );
  }

  // ── Ordering & provenance ─────────────────────────────────────────────────

  /// Most severe first; ties by [BusinessAlertKind] declaration order.
  static int _compare(BusinessAlert a, BusinessAlert b) {
    final bySeverity = b.severity.index.compareTo(a.severity.index);
    if (bySeverity != 0) return bySeverity;
    return a.kind.index.compareTo(b.kind.index);
  }

  /// What revenue is doing when no drop alert fired — the "nothing wrong"
  /// answer's reason. `null` when the comparison cannot be made.
  static ReasonCode? _trendCode(
    RevenueWindowComparison comparison,
    bool comparable,
  ) {
    if (!comparable) return null;
    final change = comparison.revenueChange;
    if (change == null) return null;
    if (change >= kBusinessAlertTrendNoiseBand) {
      return ReasonCode.revenueGrowing;
    }
    if (change <= -kBusinessAlertTrendNoiseBand) {
      return ReasonCode.revenueDeclining;
    }
    return ReasonCode.revenueFlat;
  }

  static List<ReasonCode> _distinct(List<ReasonCode> codes) {
    final seen = <ReasonCode>{};
    return [
      for (final code in codes)
        if (seen.add(code)) code,
    ];
  }
}
