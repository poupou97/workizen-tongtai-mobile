import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';

/// WTM-193 (O-6) — the score has to mean something.
///
/// Before this, `aiScore` was a constant per rule (85/70/65/75/60), so "sort by
/// relevance" was "sort by which rule fired". These tests pin the two things
/// that matter: the arithmetic is real, and a factor with no data says so
/// instead of scoring zero.
void main() {
  group('profit potential (40%)', () {
    test('scales with size relative to the business, not absolute đồng', () {
      // ₫5m means something different to a ₫10m shop than to a ₫500m one. A
      // score that ignored that would rank every large shop's opportunities
      // identically.
      final small = profitPotentialFactor(impact: 5000000, baseline: 10000000);
      final large = profitPotentialFactor(impact: 5000000, baseline: 500000000);

      expect(small.score, greaterThan(large.score!));
    });

    test('tops out rather than running away', () {
      final huge = profitPotentialFactor(impact: 999999999, baseline: 1000000);

      expect(huge.score, 100);
    });

    test('a business with no revenue yet is insufficient, not zero', () {
      final f = profitPotentialFactor(impact: 5000000, baseline: 0);

      expect(f.isAvailable, isFalse);
      expect(
        f.score,
        isNull,
        reason: 'null means unknown; 0 would mean worthless',
      );
      expect(
        f.unavailableCode,
        OpportunityFactorUnavailable.noBusinessBaseline,
      );
    });
  });

  group('demand volume (30%)', () {
    test('more orders scores higher', () {
      expect(
        demandVolumeFactor(orders: 6).score,
        greaterThan(demandVolumeFactor(orders: 2).score!),
      );
    });

    test('no order history is insufficient, not zero', () {
      final f = demandVolumeFactor(orders: 0);

      expect(f.score, isNull);
      expect(f.unavailableCode, OpportunityFactorUnavailable.noDemandHistory);
    });
  });

  group('the two factors this device cannot compute', () {
    test('supplier quality says why: the directory is sample data', () {
      // Scoring on invented ratings would be the fabrication ADR-TON-016
      // forbids, dressed up as arithmetic.
      expect(supplierQualityFactor.score, isNull);
      expect(
        supplierQualityFactor.unavailableCode,
        OpportunityFactorUnavailable.supplierDirectoryIsSample,
      );
    });

    test('competition says why: it needs market data (D-5, no backend)', () {
      expect(competitionFactor.score, isNull);
      expect(
        competitionFactor.unavailableCode,
        OpportunityFactorUnavailable.needsMarketData,
      );
    });
  });

  group('the combined score', () {
    test('rests on 70% of the Concept weight, and says so', () {
      final score = scoreOpportunity(
        impact: 2000000,
        baseline: 10000000,
        orders: 4,
      );

      expect(score.coverage, closeTo(0.7, 1e-9));
      expect(score.isPartial, isTrue);
      expect(score.factors, hasLength(4), reason: 'all four stay in the model');
    });

    test('a missing factor does not drag the score down as a zero', () {
      // Renormalisation is the whole point: supplier quality and competition
      // are unknown, not bad.
      final score = scoreOpportunity(
        impact: 5000000,
        baseline: 10000000,
        orders: 8,
      );

      // Both available factors are at 100, so the score must be 100 — not 70.
      expect(score.value, closeTo(100, 1e-9));
    });

    test('different opportunities get different scores', () {
      // The test that fails against the old code: `aiScore` was a constant, so
      // two genuinely different opportunities scored identically.
      final strong = scoreOpportunity(
        impact: 4000000,
        baseline: 10000000,
        orders: 7,
      );
      final weak = scoreOpportunity(
        impact: 200000,
        baseline: 10000000,
        orders: 1,
      );

      expect(strong.value, greaterThan(weak.value!));
    });

    test(
      'nothing computable at all yields no score rather than a made-up one',
      () {
        final score = scoreOpportunity(impact: 0, baseline: 0, orders: 0);

        expect(score.value, isNull);
        expect(score.coverage, 0);
      },
    );

    test('every factor carries a canonical code, never a label', () {
      // Same rule as `.ttbk` v2: a stored or logged label changes meaning when
      // the seller switches language.
      for (final kind in OpportunityFactorKind.values) {
        expect(kind.code, matches(RegExp(r'^[a-z_]+$')));
      }
    });

    test('the weights are the Concept weights', () {
      // 40/30/20/10 — if someone re-tunes these, it should be a decision, not
      // a drive-by edit.
      expect(OpportunityFactorKind.profitPotential.weight, 0.40);
      expect(OpportunityFactorKind.demandVolume.weight, 0.30);
      expect(OpportunityFactorKind.supplierQuality.weight, 0.20);
      expect(OpportunityFactorKind.competition.weight, 0.10);
      final total = OpportunityFactorKind.values.fold<double>(
        0,
        (s, k) => s + k.weight,
      );
      expect(total, closeTo(1.0, 1e-9));
    });
  });

  group('the ROI facet (WTM-193 → WTM-207)', () {
    test('appears only when at least one opportunity has a real return', () {
      // WTM-193 hid it while `estimatedRoi` was a constant; WTM-207 shows it
      // again, but only over data — the WTM-182 empty-facet rule.
      final none = [
        Opportunity(
          id: 'a',
          type: OpportunityType.trend,
          title: 't',
          description: 'd',
          expectedImpact: 1,
          impactBasis: OpportunityImpactBasis.estimatedGain,
          score: OpportunityScore.fixed(50),
          discoveredAt: DateTime(2026, 8, 1),
        ),
      ];
      final one = [
        none.first,
        ...[
          Opportunity(
            id: 'b',
            type: OpportunityType.trend,
            title: 't',
            description: 'd',
            expectedImpact: 1,
            impactBasis: OpportunityImpactBasis.estimatedGain,
            roi: 1.4,
            score: OpportunityScore.fixed(50),
            discoveredAt: DateTime(2026, 8, 1),
          ),
        ],
      ];

      expect(
        OpportunitySort.visibleFor(none),
        isNot(contains(OpportunitySort.roi)),
      );
      expect(OpportunitySort.visibleFor(one), contains(OpportunitySort.roi));
    });
  });
}
