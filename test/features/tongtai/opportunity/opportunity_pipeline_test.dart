import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_pipeline.dart';

/// WTM-98 — the open opportunity pipeline summary.
void main() {
  Opportunity opp(
    String id, {
    double impact = 1000000,
    double score = 50,
    OpportunityReaction reaction = OpportunityReaction.none,
  }) => Opportunity(
    id: id,
    type: OpportunityType.trend,
    title: 'Cơ hội $id',
    description: 'd',
    expectedImpact: impact,
    estimatedRoi: 2,
    aiScore: score,
    discoveredAt: DateTime(2026, 7, 1),
    reaction: reaction,
  );

  test('sample opportunities: 5 active, 160M pipeline, top score 92', () {
    final pipeline = opportunityPipeline(kSampleOpportunities);
    expect(pipeline.activeCount, 5);
    expect(pipeline.pipelineValue, 160000000);
    expect(pipeline.top!.aiScore, 92);
    expect(pipeline.top!.title, 'Quạt tích điện sắp vào mùa nóng');
    expect(pipeline.hasActive, isTrue);
  });

  test('dismissed opportunities are excluded from the pipeline', () {
    final pipeline = opportunityPipeline([
      opp('a', impact: 2000000, score: 60),
      opp(
        'b',
        impact: 5000000,
        score: 90,
        reaction: OpportunityReaction.dismissed,
      ),
      opp('c', impact: 3000000, score: 70),
    ]);
    expect(pipeline.activeCount, 2);
    expect(pipeline.pipelineValue, 5000000); // a + c, not the dismissed b
    expect(pipeline.top!.id, 'c'); // highest score among active
  });

  test('an all-dismissed / empty list yields the empty pipeline', () {
    expect(opportunityPipeline(const []).hasActive, isFalse);
    expect(
      opportunityPipeline([
        opp('x', reaction: OpportunityReaction.dismissed),
      ]).hasActive,
      isFalse,
    );
    expect(OpportunityPipeline.empty.pipelineValue, 0);
    expect(OpportunityPipeline.empty.top, isNull);
  });
}
