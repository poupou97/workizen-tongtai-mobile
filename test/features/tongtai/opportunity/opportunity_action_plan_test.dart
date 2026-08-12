import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_action_plan.dart';

/// WTM-92 — the rule-based action plan derived from an opportunity's archetype.
void main() {
  Opportunity opp(OpportunityType type, {double roi = 2.0}) => Opportunity(
    id: 'o',
    type: type,
    title: 't',
    description: 'd',
    expectedImpact: 1000000,
    impactBasis: OpportunityImpactBasis.estimatedGain,
    score: OpportunityScore.fixed(80),
    discoveredAt: DateTime(2026, 7, 1),
  );

  test('every archetype yields a multi-step plan', () {
    for (final type in OpportunityType.values) {
      final plan = opportunityActionPlan(opp(type));
      expect(plan.length, greaterThanOrEqualTo(3), reason: type.name);
    }
  });

  test(
    'the plan closes on the scale decision, phrased with the real impact',
    () {
      // It used to quote an ROI percentage from `estimatedRoi` — a constant per
      // rule (WTM-193). The seller read a specific-looking target nobody had
      // computed. Expected impact comes from their own orders.
      final plan = opportunityActionPlan(opp(OpportunityType.arbitrage));
      expect(plan.last.titleVi, 'Quyết định scale');
      expect(plan.last.detailVi, contains('1.000.000'));
      expect(
        plan.last.detailVi,
        isNot(contains('%')),
        reason: 'no percentage nobody computed',
      );
    },
  );

  test('archetypes produce distinct first steps', () {
    final firsts = {
      for (final type in OpportunityType.values)
        opportunityActionPlan(opp(type)).first.titleVi,
    };
    // Four archetypes → four different opening moves.
    expect(firsts, hasLength(OpportunityType.values.length));
  });

  test('arbitrage plan verifies both prices first', () {
    final plan = opportunityActionPlan(opp(OpportunityType.arbitrage));
    expect(plan.first.titleVi, 'Xác minh giá 2 nguồn');
  });
}
