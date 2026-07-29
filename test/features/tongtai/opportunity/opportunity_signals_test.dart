import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_signals.dart';

/// WTM-130 — rule-based opportunity signals (Phase 1, no AI).
void main() {
  final now = DateTime(2026, 7, 25);

  Opportunity opp({
    OpportunityType type = OpportunityType.trend,
    double impact = 10000000,
    double roi = 2.5,
    DateTime? discoveredAt,
    OpportunityReaction reaction = OpportunityReaction.none,
  }) => Opportunity(
    id: 'o',
    type: type,
    title: 't',
    description: 'd',
    expectedImpact: impact,
    estimatedRoi: roi,
    aiScore: 50,
    discoveredAt: discoveredAt ?? DateTime(2026, 7, 24),
    reaction: reaction,
  );

  test('High Value when impact ≥ 30M', () {
    expect(
      opportunitySignals(opp(impact: 30000000), now: now),
      contains(OpportunitySignal.highValue),
    );
    expect(
      opportunitySignals(opp(impact: 29999999), now: now),
      isNot(contains(OpportunitySignal.highValue)),
    );
  });

  test('High Risk when ROI < 2.0', () {
    expect(
      opportunitySignals(opp(roi: 1.9), now: now),
      contains(OpportunitySignal.highRisk),
    );
    expect(
      opportunitySignals(opp(roi: 2.0), now: now),
      isNot(contains(OpportunitySignal.highRisk)),
    );
  });

  test('Urgent for a seasonal opportunity', () {
    expect(
      opportunitySignals(opp(type: OpportunityType.seasonal), now: now),
      contains(OpportunitySignal.urgent),
    );
  });

  test('Urgent for a fresh (≤3d) high-value opportunity', () {
    final o = opp(
      impact: 40000000,
      discoveredAt: DateTime(2026, 7, 23), // 2 days old
    );
    expect(opportunitySignals(o, now: now), contains(OpportunitySignal.urgent));
  });

  test('Stale when > 14 days old and untouched', () {
    final o = opp(discoveredAt: DateTime(2026, 7, 1)); // 24 days
    final signals = opportunitySignals(o, now: now);
    expect(signals, contains(OpportunitySignal.stale));
    // A stale opportunity is not also flagged urgent.
    expect(signals, isNot(contains(OpportunitySignal.urgent)));
  });

  test('a reacted-on old opportunity is not stale', () {
    final o = opp(
      discoveredAt: DateTime(2026, 7, 1),
      reaction: OpportunityReaction.interested,
    );
    expect(
      opportunitySignals(o, now: now),
      isNot(contains(OpportunitySignal.stale)),
    );
  });

  test('an old untouched seasonal opportunity is stale, not urgent', () {
    final o = opp(
      type: OpportunityType.seasonal,
      discoveredAt: DateTime(2026, 7, 1),
    );
    final signals = opportunitySignals(o, now: now);
    expect(signals, contains(OpportunitySignal.stale));
    expect(signals, isNot(contains(OpportunitySignal.urgent)));
  });

  test('bilingual labels', () {
    expect(OpportunitySignal.highValue.label('vi'), 'Giá trị cao');
    expect(OpportunitySignal.highRisk.label('en'), 'High risk');
    expect(OpportunitySignal.urgent.label('vi'), 'Khẩn');
    expect(OpportunitySignal.stale.label('en'), 'Stale');
  });
}
