/// How an opportunity's score is built, and what it cannot know (WTM-193).
///
/// ## The problem this replaces
/// `aiScore` was a **constant per rule** — `85`/`70` for restock, `65` for
/// win-back, `75` for a slipping goal, `60` for category momentum. It carried
/// no information beyond *which rule fired*, so "sort by relevance" was really
/// "sort by rule". `estimatedRoi` was a constant too, which made the ROI sort
/// the **same order** under a different name.
///
/// ## What the Concept asks for
/// `SCREEN-OPPORTUNITY-HUB.md` (Business Rules #1) weights four factors:
/// profit potential **40%** · demand volume **30%** · supplier quality **20%** ·
/// competition **10%**.
///
/// ## Two of the four cannot be computed on this device
/// - **supplier quality** — the directory is `SupplierSearchService.sample()`,
///   i.e. invented ratings. Scoring on them would be the fabrication
///   ADR-TON-016 forbids, dressed as arithmetic.
/// - **competition** — needs market data. Phase 2 is local-first with no
///   backend (D-5).
///
/// Neither is removed from the model. They are **declared unavailable**, with a
/// reason, which is the Founder's Future Capability rule applied to a formula
/// instead of a screen: the Concept keeps its shape, and the product stops
/// pretending.
///
/// ## Why the whole score is not `insufficient`
/// 70% of the weight is real. Refusing to score would leave the feed with no
/// order at all, which serves the seller worse than an honest partial answer.
/// So `insufficient` lives at the **factor** level, and [OpportunityScore]
/// reports its own [OpportunityScore.coverage] so a caller can never mistake a
/// 70%-covered score for a complete one.
library;

import 'package:flutter/foundation.dart';

/// One weighted input to an opportunity's score.
enum OpportunityFactorKind {
  /// How much money this is worth relative to what the business already makes.
  profitPotential('profit_potential', 0.40),

  /// How strong the demand signal behind it is.
  ///
  /// ⚠️ On this device it is **the seller's own demand**, read from their order
  /// history — not market demand. The Concept's definition (Google Trends,
  /// platform APIs) needs a backend. Callers must present it as *"your
  /// customers"*, never as *"the market"*.
  demandVolume('demand_volume', 0.30),

  /// Quality of the suppliers behind it. Unavailable in Phase 2.
  supplierQuality('supplier_quality', 0.20),

  /// How crowded the space is. Unavailable in Phase 2.
  competition('competition', 0.10);

  const OpportunityFactorKind(this.code, this.weight);

  /// Canonical code — never a display label (ADR-TON-018), and safe for
  /// telemetry.
  final String code;

  /// Share of the total score, straight from the Concept.
  final double weight;
}

/// Why a factor could not be scored. Fixed tokens, never built from data, so
/// they stay safe to log (same discipline as `TongtaiFailure.code`).
abstract final class OpportunityFactorUnavailable {
  /// The supplier directory is sample data, so any rating-derived number would
  /// be invented.
  static const String supplierDirectoryIsSample = 'supplier_directory_sample';

  /// Needs market data the device does not have (D-5: no backend).
  static const String needsMarketData = 'needs_market_data';

  /// The business has no baseline to compare against yet — a brand-new shop
  /// with no revenue cannot say whether ₫2m is a lot.
  static const String noBusinessBaseline = 'no_business_baseline';

  /// No order history behind this opportunity.
  static const String noDemandHistory = 'no_demand_history';
}

/// One factor's contribution, or an honest statement that it has none.
class OpportunityFactor {
  const OpportunityFactor.scored(this.kind, double score)
    : score = score,
      unavailableCode = null,
      assert(score >= 0 && score <= 100, 'factor scores are 0–100');

  const OpportunityFactor.unavailable(this.kind, this.unavailableCode)
    : score = null;

  final OpportunityFactorKind kind;

  /// 0–100, or `null` when this factor has no data.
  ///
  /// `null` is **not** zero. A zero says *"this is worthless"*; `null` says
  /// *"nobody knows"*, and treating the second as the first is how a product
  /// starts lying with a straight face.
  final double? score;

  /// Set when [score] is `null`. One of [OpportunityFactorUnavailable].
  final String? unavailableCode;

  bool get isAvailable => score != null;

  double get weight => kind.weight;
}

/// An opportunity's score and the reasoning behind it.
class OpportunityScore {
  const OpportunityScore(this.factors);

  /// A score pinned to [value], for fixtures that care about the number and
  /// not the breakdown.
  ///
  /// `@visibleForTesting` on purpose: production code must build a score from
  /// real factors. A hand-written number in `lib/` is exactly the defect
  /// WTM-193 removed, and the analyzer will now say so.
  @visibleForTesting
  factory OpportunityScore.fixed(double value) => OpportunityScore([
    OpportunityFactor.scored(OpportunityFactorKind.profitPotential, value),
    demandVolumeFactor(orders: 0),
    supplierQualityFactor,
    competitionFactor,
  ]);

  final List<OpportunityFactor> factors;

  Iterable<OpportunityFactor> get available =>
      factors.where((f) => f.isAvailable);

  /// Share of the Concept's total weight this score actually rests on.
  ///
  /// `0.7` today, because supplier quality and competition are unavailable.
  /// Exposed rather than hidden so no caller can mistake a partial score for a
  /// complete one.
  double get coverage {
    var sum = 0.0;
    for (final f in available) {
      sum += f.weight;
    }
    return sum;
  }

  /// 0–100, or `null` when **no** factor could be scored.
  ///
  /// Renormalised over the available factors: a missing factor must not drag
  /// the score down as though it had scored zero.
  double? get value {
    final total = coverage;
    if (total <= 0) return null;
    var weighted = 0.0;
    for (final f in available) {
      weighted += f.score! * f.weight;
    }
    return weighted / total;
  }

  /// True when at least one factor is missing — the caller should say so.
  bool get isPartial => coverage < 1.0;
}

// ── the factors, as pure functions ───────────────────────────────────────────
//
// Each one is computed and tested on its own. They take numbers, not
// repositories, so a test can pin the arithmetic without a database, and the
// Rule Twin can run them with no AI, no network and no key (ADR-TON-016).

/// How big this opportunity is next to what the business already earns.
///
/// [baseline] is the business's revenue over the same window. An opportunity
/// worth a tenth of it scores modestly; one worth as much as everything else
/// scores at the top. Ratios rather than absolute đồng, because ₫5m means
/// something different to a shop turning over ₫10m than to one turning over
/// ₫500m — and a score that ignores that would rank every large shop's
/// opportunities identically.
OpportunityFactor profitPotentialFactor({
  required double impact,
  required double baseline,
}) {
  if (baseline <= 0) {
    return const OpportunityFactor.unavailable(
      OpportunityFactorKind.profitPotential,
      OpportunityFactorUnavailable.noBusinessBaseline,
    );
  }
  final ratio = impact / baseline;
  // Half the business's window revenue is treated as the top of the scale:
  // above that the difference stops being decision-relevant — everything that
  // big deserves attention.
  final scaled = (ratio / 0.5).clamp(0.0, 1.0);
  return OpportunityFactor.scored(
    OpportunityFactorKind.profitPotential,
    scaled * 100,
  );
}

/// How strong the seller's **own** demand signal is behind this.
///
/// [orders] is how many billable orders touched the thing the opportunity is
/// about, in the window. Not market demand — see [OpportunityFactorKind
/// .demandVolume].
OpportunityFactor demandVolumeFactor({required int orders}) {
  if (orders <= 0) {
    return const OpportunityFactor.unavailable(
      OpportunityFactorKind.demandVolume,
      OpportunityFactorUnavailable.noDemandHistory,
    );
  }
  // Eight orders in the window is a strong signal for the shop size this
  // product serves; past that the extra orders do not change the decision.
  final scaled = (orders / 8).clamp(0.0, 1.0);
  return OpportunityFactor.scored(
    OpportunityFactorKind.demandVolume,
    scaled * 100,
  );
}

/// Always unavailable in Phase 2 — the supplier directory is sample data.
const OpportunityFactor supplierQualityFactor = OpportunityFactor.unavailable(
  OpportunityFactorKind.supplierQuality,
  OpportunityFactorUnavailable.supplierDirectoryIsSample,
);

/// Always unavailable in Phase 2 — needs market data, and there is no backend.
const OpportunityFactor competitionFactor = OpportunityFactor.unavailable(
  OpportunityFactorKind.competition,
  OpportunityFactorUnavailable.needsMarketData,
);

/// Builds the full four-factor score from the two the device can compute.
OpportunityScore scoreOpportunity({
  required double impact,
  required double baseline,
  required int orders,
}) => OpportunityScore([
  profitPotentialFactor(impact: impact, baseline: baseline),
  demandVolumeFactor(orders: orders),
  supplierQualityFactor,
  competitionFactor,
]);
