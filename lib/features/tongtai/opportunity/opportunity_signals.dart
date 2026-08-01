import '../core/tongtai_enums.dart';
import 'opportunity.dart';

/// Expected-impact floor (đồng) for the High Value signal.
const double kOpportunityHighValueImpact = 30000000; // ≥ 30M ₫

/// ROI multiple below which an opportunity reads as High Risk (thin return).
/// The return multiple below which a restock reads as thin (WTM-207).
///
/// Profit/investment: 2.0 means the seller doubles the money they put in.
/// Kept through WTM-193 (when High Risk was removed for judging a constant)
/// exactly for the day the ROI became real — that day is WTM-204 + WTM-207.
const double kOpportunityHighRiskRoi = 2.0;

/// Age (days) beyond which an untouched opportunity is Stale.
const int kOpportunityStaleDays = 14;

/// Age (days) within which a High Value opportunity still counts as fresh — and
/// therefore Urgent (act while it is relevant).
const int kOpportunityUrgentFreshDays = 3;

/// A **rule-based** opportunity signal (WTM-130, Founder Phase 1 — no AI). The
/// AI signals (Win Probability, Recommendation, Summary) are Phase 2, behind the
/// AI gate. These four are derived purely from the opportunity's own data.
enum OpportunitySignal {
  highValue,
  highRisk,
  urgent,
  stale;

  String get labelEn => switch (this) {
    OpportunitySignal.highValue => 'High value',
    OpportunitySignal.highRisk => 'High risk',
    OpportunitySignal.urgent => 'Urgent',
    OpportunitySignal.stale => 'Stale',
  };

  String get labelVi => switch (this) {
    OpportunitySignal.highValue => 'Giá trị cao',
    OpportunitySignal.highRisk => 'Rủi ro cao',
    OpportunitySignal.urgent => 'Khẩn',
    OpportunitySignal.stale => 'Nguội',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Classifies [opportunity] into its rule-based [OpportunitySignal]s as of [now]
/// (WTM-130). Pure + deterministic — no AI, no persistence — so it is trivially
/// testable and reusable by the feed, detail and (later) a BusinessContext
/// summary. Rules:
///
/// * **High Value** — expected impact ≥ [kOpportunityHighValueImpact].
/// * **High Risk** — real return under [kOpportunityHighRiskRoi]× (WTM-207).
///   Emitted **only** from a computed ROI; a null ROI raises nothing.
/// * **Stale** — surfaced > [kOpportunityStaleDays] days ago and still untouched
///   (no seller reaction).
/// * **Urgent** — not stale, and either a seasonal (closing-window) opportunity
///   or a fresh (≤ [kOpportunityUrgentFreshDays] days) High Value one.
Set<OpportunitySignal> opportunitySignals(
  Opportunity opportunity, {
  required DateTime now,
}) {
  final signals = <OpportunitySignal>{};
  final ageDays = now.difference(opportunity.discoveredAt).inDays;
  final isHighValue = opportunity.expectedImpact >= kOpportunityHighValueImpact;
  final isStale =
      ageDays > kOpportunityStaleDays &&
      opportunity.reaction == OpportunityReaction.none;

  if (isHighValue) signals.add(OpportunitySignal.highValue);
  // High Risk is back (WTM-207) — on **real** returns only. WTM-193 removed it
  // because `estimatedRoi` was a constant per rule; WTM-204 gave products a
  // cost price and the rule engine now computes profit/investment from it.
  // A null ROI raises nothing: "nobody knows" is not "risky", and alarming on
  // the unknown would re-teach sellers to ignore the badge.
  if (opportunity.roi case final roi? when roi < kOpportunityHighRiskRoi) {
    signals.add(OpportunitySignal.highRisk);
  }
  if (isStale) signals.add(OpportunitySignal.stale);
  if (!isStale &&
      (opportunity.type == OpportunityType.seasonal ||
          (isHighValue && ageDays <= kOpportunityUrgentFreshDays))) {
    signals.add(OpportunitySignal.urgent);
  }
  return signals;
}
