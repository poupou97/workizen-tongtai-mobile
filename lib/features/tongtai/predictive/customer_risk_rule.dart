import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../analytics/customer_rfm.dart';
import '../analytics/month_bucket.dart';
import '../capability/customer_capability.dart';
import 'rule_twin.dart';

/// **Customer Risk Rule Twin** (WTM-156, ADR-TON-016) — the AUTHORITATIVE
/// deterministic answer to "which customers am I about to lose?".
///
/// Runs with **no AI, no network, no key**: it reads a
/// [CustomerCapabilityContext] (itself built from `analytics/customer_rfm.dart`)
/// and applies policy — nothing here re-derives recency, cadence, quantiles or
/// bands (ADR-TON-015 One Data Path: a calculation exists in exactly one place).
///
/// **Privacy (D-7 / ADR-TON-005 red-line):** the assessment carries customer
/// **ids** and numbers only. No name, phone, email or address can appear,
/// because the context this rule reads never had them — the guarantee is
/// structural, not a filter someone could forget to apply. The UI joins ids back
/// to names from the repository; the AI layer only ever sees ids and reason
/// codes.

// ── Scoring weights ─────────────────────────────────────────────────────────
//
// riskScore = 100 × ( 0.60 × lateness + 0.25 × loyaltyRisk + 0.15 × valueWeight )
//
// Three questions a seller actually asks, in the order they matter:
//   1. "Are they late?"       — measured against the customer's OWN cadence.
//   2. "Have they slowed?"    — recent activity vs the rhythm they proved.
//   3. "Do they matter?"      — losing a top-band spender costs more.
//
// Lateness dominates because it is the only component that can move a customer
// from "fine" to "gone"; value never *creates* risk on its own (a top spender
// who bought yesterday scores ~15/100), it only ranks two equally-late
// customers.

/// Weight of the recency-vs-own-cadence component (the dominant signal).
const double kCustomerRiskLatenessWeight = 0.60;

/// Weight of the frequency-trend component ("used to buy often, now slowing").
const double kCustomerRiskLoyaltyWeight = 0.25;

/// Weight of the monetary-band component (what the loss would cost).
const double kCustomerRiskValueWeight = 0.15;

// ── Lateness curve ──────────────────────────────────────────────────────────
//
// Piecewise-linear in the **equivalent gap ratio**, anchored on exactly the
// ladder [customerLifecycleStage] uses (1.0× / 1.5× / 3.0× of the customer's own
// median gap), so the score can never disagree with the stage shown next to it:
//
//   ratio 0.0 → 0.00   ratio 1.0 → 0.20   ratio 1.5 → 0.50
//   ratio 3.0 → 0.85   ratio ≥ 6.0 → 1.00

/// Lateness at the end of the *active* band (ratio 1.0×).
const double kCustomerRiskLatenessAtActiveEdge = 0.20;

/// Lateness at the end of the *cooling* band (ratio 1.5×).
const double kCustomerRiskLatenessAtCoolingEdge = 0.50;

/// Lateness at the end of the *at-risk* band (ratio 3.0×) — beyond this the
/// customer is churned and the curve only has 0.15 left to give: once someone is
/// gone, being "more gone" barely changes what you do about it.
const double kCustomerRiskLatenessAtRiskEdge = 0.85;

/// Gap ratio at which lateness saturates at 1.0 — twice the churn threshold.
const double kCustomerRiskLatenessSaturationRatio =
    2 * kCustomerChurnedGapRatio;

// ── Loyalty / frequency trend ───────────────────────────────────────────────

/// Loyalty risk assigned to a customer who has bought exactly once.
///
/// They never proved they come back, so there is no cadence to be late against
/// — but "one order" is genuinely more fragile than "ten orders on schedule".
/// 0.60 keeps a single-purchase customer below a customer who demonstrably
/// stopped buying (1.0) and well above a customer still on rhythm (0.0).
const double kCustomerRiskSinglePurchaseLoyalty = 0.60;

/// Loyalty risk assigned to a customer in the directory who has never bought.
const double kCustomerRiskNeverPurchasedLoyalty = 1.0;

/// Shortfall against a customer's own expected order count at which
/// [ReasonCode.frequencyDropping] is raised: they placed **≤ 65%** of the orders
/// their proven cadence predicted for the time they have been a customer.
const double kCustomerRiskFrequencyDropThreshold = 0.35;

/// Average days per calendar month, used to convert the context's analysis
/// window into the days a cadence is measured in.
const double kCustomerRiskDaysPerMonth = 30.44;

/// Majority of the directory that must be *returning* customers before the twin
/// claims [ForecastConfidence.high]: without ≥ 2 orders there is no cadence to
/// judge lateness against, only the blunt fixed windows.
const double kCustomerRiskHighConfidenceReturningShare = 0.5;

/// One customer's deterministic risk verdict — **ids and numbers only**.
///
/// Deliberately carries no name, phone or email: this object travels to the AI
/// layer and into telemetry-shaped strings, where PII must not exist by
/// construction (see the class docs above).
@immutable
class CustomerRiskEntry {
  const CustomerRiskEntry({
    required this.customerId,
    required this.stage,
    required this.recencyDays,
    required this.lifetimeOrders,
    required this.lifetimeValue,
    required this.riskScore,
    required this.reasonCodes,
    required this.winBackCandidate,
  });

  /// The customer's stable id — the **only** identifying field, by design.
  final String customerId;

  /// Where this customer sits in the lifecycle, from
  /// [customerLifecycleStage] (never recomputed here).
  final CustomerLifecycleStage stage;

  /// Whole days since the last billable order; `null` when they never bought.
  final int? recencyDays;

  /// Lifetime billable order count.
  final int lifetimeOrders;

  /// Lifetime billable spend, in đồng.
  final double lifetimeValue;

  /// 0..100, higher = more urgent. Deterministic: same profile → same score.
  final double riskScore;

  /// Why, most significant first. **May be empty** for a customer who has never
  /// purchased: no [ReasonCode] describes "in the directory, never bought", and
  /// the frozen `rule_twin.dart` contract is not extended from here — [stage]
  /// carries that fact instead.
  final List<ReasonCode> reasonCodes;

  /// Whether chasing this customer is worth it — the shared
  /// [isWinBackCandidate] policy, not a second opinion.
  final bool winBackCandidate;

  /// True once the customer has stopped being merely "not due yet".
  bool get isLapsed =>
      stage == CustomerLifecycleStage.atRisk ||
      stage == CustomerLifecycleStage.churned;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRiskEntry &&
          other.customerId == customerId &&
          other.stage == stage &&
          other.recencyDays == recencyDays &&
          other.lifetimeOrders == lifetimeOrders &&
          other.lifetimeValue == lifetimeValue &&
          other.riskScore == riskScore &&
          other.winBackCandidate == winBackCandidate &&
          listEquals(other.reasonCodes, reasonCodes));

  @override
  int get hashCode => Object.hash(
    customerId,
    stage,
    recencyDays,
    lifetimeOrders,
    lifetimeValue,
    riskScore,
    winBackCandidate,
    Object.hashAll(reasonCodes),
  );

  @override
  String toString() =>
      'CustomerRiskEntry($customerId, ${stage.name}, score: $riskScore, '
      'r: $recencyDays, f: $lifetimeOrders, '
      'reasons: ${reasonCodes.map((r) => r.code).join(',')})';
}

/// The whole directory, scored and ranked — the result carried by
/// [CustomerRiskRule]'s [RuleTwinResult].
@immutable
class CustomerRiskAssessment {
  const CustomerRiskAssessment({
    required this.entries,
    required this.stageCounts,
    required this.atRiskCount,
    required this.churnedCount,
    required this.winBackCount,
  });

  /// Every customer, **highest risk first** (ties: larger lifetime value first,
  /// then id ascending — so the order is total and reproducible).
  final List<CustomerRiskEntry> entries;

  /// Customers per lifecycle stage; every stage present (0 rather than absent),
  /// summing to [totalCustomers].
  final Map<CustomerLifecycleStage, int> stageCounts;

  /// Customers in [CustomerLifecycleStage.atRisk].
  final int atRiskCount;

  /// Customers in [CustomerLifecycleStage.churned].
  final int churnedCount;

  /// Lapsed customers worth chasing — see [isWinBackCandidate].
  final int winBackCount;

  int get totalCustomers => entries.length;

  /// Lapsed = at risk + churned.
  int get lapsedCount => atRiskCount + churnedCount;

  /// Count for [stage] — always defined.
  int stage(CustomerLifecycleStage stage) => stageCounts[stage] ?? 0;

  /// The [n] most urgent customers (fewer when the directory is smaller).
  List<CustomerRiskEntry> top(int n) =>
      entries.take(n < 0 ? 0 : n).toList(growable: false);

  /// The entry for [customerId], or `null` when unknown.
  CustomerRiskEntry? entryFor(String customerId) {
    for (final entry in entries) {
      if (entry.customerId == customerId) return entry;
    }
    return null;
  }

  @override
  String toString() =>
      'CustomerRiskAssessment(${entries.length} customers, '
      'atRisk: $atRiskCount, churned: $churnedCount, winBack: $winBackCount)';
}

/// Scores and ranks every customer's churn risk from a
/// [CustomerCapabilityContext].
///
/// Pure: no clock read (the context's `generatedAt` is the instant), no
/// repository, no Riverpod, no AI. Same context → byte-identical assessment.
class CustomerRiskRule {
  const CustomerRiskRule();

  /// Formula version — bump when a weight, a curve anchor or a reason-code
  /// meaning changes (ADR-TON-016).
  static const String version = 'customer-risk/1';

  /// Assesses every customer in [ctx].
  ///
  /// **Sufficiency**
  /// - no customers at all → [DataSufficiency.insufficient] +
  ///   [ReasonCode.noCustomers] (result `null`, confidence `none`);
  /// - customers exist but **none** has ever bought →
  ///   [DataSufficiency.partial] + [ReasonCode.noRevenueYet], confidence
  ///   [ForecastConfidence.low]: the directory can still be listed, but nothing
  ///   about churn can be claimed from contacts who never arrived;
  /// - otherwise [DataSufficiency.sufficient], with confidence
  ///   [ForecastConfidence.high] only when a strict majority of the directory
  ///   are returning customers (≥ 2 orders → a real cadence to be late
  ///   against), else [ForecastConfidence.medium].
  RuleTwinResult<CustomerRiskAssessment> assess(CustomerCapabilityContext ctx) {
    final now = ctx.generatedAt;

    if (!ctx.hasData) {
      return RuleTwinResult<CustomerRiskAssessment>.insufficient(
        reasonCodes: const [ReasonCode.noCustomers],
        version: version,
        generatedAt: now,
      );
    }

    final entries = <CustomerRiskEntry>[
      for (final profile in ctx.profiles) _score(profile, ctx, now),
    ]..sort(_compare);

    final stageCounts = <CustomerLifecycleStage, int>{
      for (final stage in CustomerLifecycleStage.values) stage: 0,
    };
    var winBackCount = 0;
    for (final entry in entries) {
      stageCounts[entry.stage] = stageCounts[entry.stage]! + 1;
      if (entry.winBackCandidate) winBackCount += 1;
    }

    final assessment = CustomerRiskAssessment(
      entries: List<CustomerRiskEntry>.unmodifiable(entries),
      stageCounts: Map<CustomerLifecycleStage, int>.unmodifiable(stageCounts),
      atRiskCount: stageCounts[CustomerLifecycleStage.atRisk]!,
      churnedCount: stageCounts[CustomerLifecycleStage.churned]!,
      winBackCount: winBackCount,
    );

    final noneEverBought = ctx.purchasingCustomers == 0;
    final reasons = <ReasonCode>[
      if (noneEverBought) ReasonCode.noRevenueYet,
      ..._distinctReasons(entries),
    ];

    if (noneEverBought) {
      return RuleTwinResult<CustomerRiskAssessment>(
        result: assessment,
        confidence: ForecastConfidence.low,
        sufficiency: DataSufficiency.partial,
        reasonCodes: List<ReasonCode>.unmodifiable(reasons),
        version: version,
        generatedAt: now,
      );
    }

    final returningMajority =
        ctx.returningCount >
        ctx.totalCustomers * kCustomerRiskHighConfidenceReturningShare;

    return RuleTwinResult<CustomerRiskAssessment>(
      result: assessment,
      confidence: returningMajority
          ? ForecastConfidence.high
          : ForecastConfidence.medium,
      sufficiency: DataSufficiency.sufficient,
      reasonCodes: List<ReasonCode>.unmodifiable(reasons),
      version: version,
      generatedAt: now,
    );
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  CustomerRiskEntry _score(
    CustomerRfm profile,
    CustomerCapabilityContext ctx,
    DateTime now,
  ) {
    final stage = customerLifecycleStage(profile);
    final ratio = equivalentGapRatio(profile);
    final lateness = latenessFromRatio(ratio);
    final loyaltyRisk = _loyaltyRisk(profile, ctx.windowMonths, now);
    final valueWeight = _valueWeight(profile, ctx.monetaryCutoffs);

    final raw =
        100 *
        (kCustomerRiskLatenessWeight * lateness +
            kCustomerRiskLoyaltyWeight * loyaltyRisk +
            kCustomerRiskValueWeight * valueWeight);
    // One decimal: enough resolution to rank, stable enough that a re-run can
    // never reshuffle two customers because of float dust.
    final score = (raw * 10).roundToDouble() / 10;

    final winBack = isWinBackCandidate(
      profile,
      stage: stage,
      monetaryCutoffs: ctx.monetaryCutoffs,
    );

    return CustomerRiskEntry(
      customerId: profile.customerId,
      stage: stage,
      recencyDays: profile.recencyDays,
      lifetimeOrders: profile.frequency,
      lifetimeValue: profile.monetary,
      riskScore: score,
      reasonCodes: List<ReasonCode>.unmodifiable(
        _entryReasons(
          profile: profile,
          stage: stage,
          loyaltyRisk: loyaltyRisk,
          valueWeight: valueWeight,
        ),
      ),
      winBackCandidate: winBack,
    );
  }

  /// How overdue [profile] is, expressed on the **same** ladder
  /// [customerLifecycleStage] uses (1.0× / 1.5× / 3.0×).
  ///
  /// With a proven cadence (≥ 2 orders) this is exactly
  /// [CustomerRfm.gapRatioWithFloor]. Without one, the fixed 30/60/90-day
  /// windows are mapped onto the same anchors (30 d → 1.0×, 60 d → 1.5×,
  /// 90 d → 3.0×, then linear), so a single-purchase customer and a repeat
  /// customer at the same stage sit on one comparable scale.
  ///
  /// `null` when the customer never bought — there is nothing to be late for.
  @visibleForTesting
  static double? equivalentGapRatio(CustomerRfm profile) {
    final cadence = profile.gapRatioWithFloor(kCustomerCadenceFloorDays);
    if (cadence != null) return cadence;

    final recency = profile.recencyDays;
    if (recency == null) return null;

    if (recency <= kCustomerActiveMaxDays) {
      return kCustomerCoolingGapRatio * recency / kCustomerActiveMaxDays;
    }
    if (recency <= kCustomerCoolingMaxDays) {
      return _lerp(
        kCustomerCoolingGapRatio,
        kCustomerAtRiskGapRatio,
        (recency - kCustomerActiveMaxDays) /
            (kCustomerCoolingMaxDays - kCustomerActiveMaxDays),
      );
    }
    if (recency <= kCustomerAtRiskMaxDays) {
      return _lerp(
        kCustomerAtRiskGapRatio,
        kCustomerChurnedGapRatio,
        (recency - kCustomerCoolingMaxDays) /
            (kCustomerAtRiskMaxDays - kCustomerCoolingMaxDays),
      );
    }
    // Past the fixed churn window: one further churn-window of silence doubles
    // the ratio, saturating with the curve below.
    return kCustomerChurnedGapRatio *
        (1 + (recency - kCustomerAtRiskMaxDays) / kCustomerAtRiskMaxDays);
  }

  /// The 0..1 lateness component of the score — see the curve documented at the
  /// top of this file. Monotonically non-decreasing in [ratio], which is what
  /// guarantees "silent past 3× their cadence" always outranks "silent past
  /// 1.5×".
  @visibleForTesting
  static double latenessFromRatio(double? ratio) {
    if (ratio == null || ratio <= 0) return 0;
    if (ratio <= kCustomerCoolingGapRatio) {
      return kCustomerRiskLatenessAtActiveEdge *
          ratio /
          kCustomerCoolingGapRatio;
    }
    if (ratio <= kCustomerAtRiskGapRatio) {
      return _lerp(
        kCustomerRiskLatenessAtActiveEdge,
        kCustomerRiskLatenessAtCoolingEdge,
        (ratio - kCustomerCoolingGapRatio) /
            (kCustomerAtRiskGapRatio - kCustomerCoolingGapRatio),
      );
    }
    if (ratio <= kCustomerChurnedGapRatio) {
      return _lerp(
        kCustomerRiskLatenessAtCoolingEdge,
        kCustomerRiskLatenessAtRiskEdge,
        (ratio - kCustomerAtRiskGapRatio) /
            (kCustomerChurnedGapRatio - kCustomerAtRiskGapRatio),
      );
    }
    if (ratio >= kCustomerRiskLatenessSaturationRatio) return 1;
    return _lerp(
      kCustomerRiskLatenessAtRiskEdge,
      1,
      (ratio - kCustomerChurnedGapRatio) /
          (kCustomerRiskLatenessSaturationRatio - kCustomerChurnedGapRatio),
    );
  }

  /// The 0..1 frequency-trend component: how far this customer fell short of
  /// the order count their **own** proven cadence predicted.
  ///
  /// Expectation is capped at the time they have actually been a customer
  /// (`min(window, days since first order)`), so a monthly buyer acquired last
  /// month is not judged against twelve months they were never around for. The
  /// cadence floor ([kCustomerCadenceFloorDays]) is the same one segmentation
  /// uses, so a two-day buyer cannot generate an impossible expectation.
  double _loyaltyRisk(CustomerRfm profile, int windowMonths, DateTime now) {
    if (!profile.hasOrders) return kCustomerRiskNeverPurchasedLoyalty;
    if (profile.frequency < kCustomerReturningMinOrders) {
      return kCustomerRiskSinglePurchaseLoyalty;
    }
    final cadence = profile.medianGapDays;
    final first = profile.firstOrderAt;
    if (cadence == null || cadence <= 0 || first == null) return 0;

    final windowDays = windowMonths * kCustomerRiskDaysPerMonth;
    final tenureDays = wholeDaysBetween(first, now).toDouble();
    final observedDays = math.min(windowDays, tenureDays);
    if (observedDays <= 0) return 0;

    final effectiveCadence = math.max(cadence, kCustomerCadenceFloorDays);
    final expected = observedDays / effectiveCadence;
    if (expected <= 0) return 0;

    final achieved = profile.ordersInWindow / expected;
    return (1 - achieved).clamp(0.0, 1.0);
  }

  /// The 0..1 monetary component: the customer's lifetime-spend band as a
  /// fraction of the top band, using the context's own quantile cut-offs.
  ///
  /// Zero spend never scores — otherwise a directory where nobody has bought
  /// would put every contact in the "top band" (the cut-offs would all be 0).
  double _valueWeight(CustomerRfm profile, List<double> monetaryCutoffs) {
    if (monetaryCutoffs.isEmpty || profile.monetary <= 0) return 0;
    return CustomerRfmService.band(profile.monetary, monetaryCutoffs) /
        monetaryCutoffs.length;
  }

  /// Per-entry reason codes, most significant first.
  ///
  /// Exactly **one** lifecycle code is emitted (the strongest true statement):
  /// `inactiveBeyondChurnWindow` ▸ `purchaseGapExceeded` ▸ `recentPurchase`.
  /// A never-purchased customer gets none — see [CustomerRiskEntry.reasonCodes].
  List<ReasonCode> _entryReasons({
    required CustomerRfm profile,
    required CustomerLifecycleStage stage,
    required double loyaltyRisk,
    required double valueWeight,
  }) {
    final codes = <ReasonCode>[];
    switch (stage) {
      case CustomerLifecycleStage.churned:
        codes.add(ReasonCode.inactiveBeyondChurnWindow);
      case CustomerLifecycleStage.atRisk:
      case CustomerLifecycleStage.cooling:
        codes.add(ReasonCode.purchaseGapExceeded);
      case CustomerLifecycleStage.active:
        codes.add(ReasonCode.recentPurchase);
      case CustomerLifecycleStage.neverPurchased:
        break;
    }
    final lapsed =
        stage == CustomerLifecycleStage.atRisk ||
        stage == CustomerLifecycleStage.churned;
    if (lapsed && valueWeight >= 1) codes.add(ReasonCode.highValueAtRisk);
    if (profile.frequency >= kCustomerReturningMinOrders &&
        loyaltyRisk >= kCustomerRiskFrequencyDropThreshold) {
      codes.add(ReasonCode.frequencyDropping);
    }
    if (profile.isSinglePurchase) codes.add(ReasonCode.singlePurchaseOnly);
    return codes;
  }

  // ── Ordering & aggregation ────────────────────────────────────────────────

  /// Highest risk first; ties by lifetime value (desc) then id (asc) so the
  /// order is total — two runs can never disagree.
  static int _compare(CustomerRiskEntry a, CustomerRiskEntry b) {
    final byScore = b.riskScore.compareTo(a.riskScore);
    if (byScore != 0) return byScore;
    final byValue = b.lifetimeValue.compareTo(a.lifetimeValue);
    if (byValue != 0) return byValue;
    return a.customerId.compareTo(b.customerId);
  }

  /// The distinct entry reason codes, in a fixed significance order (never the
  /// iteration order of the directory, which would make the twin's provenance
  /// depend on row order).
  static List<ReasonCode> _distinctReasons(List<CustomerRiskEntry> entries) {
    const significance = <ReasonCode>[
      ReasonCode.inactiveBeyondChurnWindow,
      ReasonCode.highValueAtRisk,
      ReasonCode.purchaseGapExceeded,
      ReasonCode.frequencyDropping,
      ReasonCode.singlePurchaseOnly,
      ReasonCode.recentPurchase,
    ];
    final present = <ReasonCode>{
      for (final entry in entries) ...entry.reasonCodes,
    };
    return [
      for (final code in significance)
        if (present.contains(code)) code,
    ];
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}
