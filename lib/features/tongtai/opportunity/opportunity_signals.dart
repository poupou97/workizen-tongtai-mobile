import '../core/tongtai_enums.dart';
import 'opportunity.dart';

/// Expected-impact floor (đồng) for the High Value signal.
const double kOpportunityHighValueImpact = 30000000; // ≥ 30M ₫

/// ROI multiple below which an opportunity reads as High Risk (thin return).
/// Kept for the day `Product` carries a cost price and **High Risk** can mean
/// something again (WTM-193). Unused today on purpose.
// ignore: unused_element
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
/// * **High Risk** — **not emitted in Phase 2** (WTM-193): it was derived from
///   a constant ROI, so it said nothing. Needs a cost price on `Product`.
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
  // WTM-193: the **High Risk** badge is gone. It compared `estimatedRoi`
  // against a threshold, and `estimatedRoi` was a **constant per rule** — so
  // the badge only ever restated which rule fired, while reading to the seller
  // as a judgement about their money. A real risk signal needs a cost price,
  // which `Product` does not carry. Same rule as the hidden ROI facet: keep the
  // signal in the domain, stop showing a number nobody computed.
  if (isStale) signals.add(OpportunitySignal.stale);
  if (!isStale &&
      (opportunity.type == OpportunityType.seasonal ||
          (isHighValue && ageDays <= kOpportunityUrgentFreshDays))) {
    signals.add(OpportunitySignal.urgent);
  }
  return signals;
}
