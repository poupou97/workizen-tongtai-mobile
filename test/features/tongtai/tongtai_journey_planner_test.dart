import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-186 (J2) — the Rule Twin planner.
///
/// The property that matters most: **nothing in this file needs AI**. There is
/// no provider to stub, no key to inject and no network to fake — which is the
/// whole point, because most target users have no API key (WTM-176).
void main() {
  BusinessGoal goal({
    GoalType type = GoalType.revenue,
    double target = 50000000,
    int growth = 20,
  }) => BusinessGoal(
    id: 'g1',
    name: 'Mục tiêu',
    type: type,
    targetAmount: target,
    achievedAmount: 0,
    growthTarget: growth,
    growthAchieved: 0,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  JourneyPlanInput input({
    GoalType type = GoalType.revenue,
    BusinessProfile profile = BusinessProfile.empty,
    int products = 10,
    int customers = 5,
    int orders = 3,
  }) => JourneyPlanInput(
    goal: goal(type: type),
    profile: profile,
    productCount: products,
    customerCount: customers,
    orderCount: orders,
  );

  JourneyPlanResult plan(JourneyPlanInput i) => planJourney(i, journeyId: 'j1');

  group('it runs without AI', () {
    test('every goal type produces a plan', () {
      for (final type in GoalType.values) {
        final result = plan(input(type: type));
        expect(result.isSufficient, isTrue, reason: type.name);
        expect(result.nodes, isNotEmpty, reason: type.name);
      }
    });

    test('an empty profile still produces a plan', () {
      // A seller who skipped onboarding must not be locked out of the
      // capability the Concept calls P0.
      final result = plan(input(profile: BusinessProfile.empty));
      expect(result.isSufficient, isTrue);
      expect(result.reasonCodes, contains(JourneyReason.profileUnknown));
    });
  });

  group('insufficient is an answer, not a failure', () {
    test('a brand-new business gets a refusal, not invented steps', () {
      final result = plan(input(products: 0, customers: 0, orders: 0));
      expect(result.isSufficient, isFalse);
      expect(result.nodes, isEmpty);
      expect(result.reasonCodes, contains(JourneyReason.dataEmptyCatalog));
    });

    test('having only products is enough to plan', () {
      expect(plan(input(products: 5, customers: 0)).isSufficient, isTrue);
    });

    test('having only customers is enough to plan', () {
      expect(plan(input(products: 0, customers: 5)).isSufficient, isTrue);
    });
  });

  group('determinism', () {
    test('same input produces an identical plan', () {
      final a = plan(input());
      final b = plan(input());
      expect(
        a.nodes.map((n) => '${n.id}|${n.title}|${n.kind.code}'),
        b.nodes.map((n) => '${n.id}|${n.title}|${n.kind.code}'),
      );
      expect(a.reasonCodes, b.reasonCodes);
    });

    test('ids are supplied, never invented', () {
      final result = planJourney(input(), journeyId: 'j1', idPrefix: 'x');
      expect(result.nodes.every((n) => n.id.startsWith('x-')), isTrue);
    });
  });

  group('the profile changes the plan — this is why WTM-177 exists', () {
    test('an online seller and an offline seller get different plans', () {
      final online = plan(
        input(
          type: GoalType.newChannel,
          profile: const BusinessProfile(channels: [SalesChannel.shopee]),
        ),
      );
      final offline = plan(
        input(
          type: GoalType.newChannel,
          profile: const BusinessProfile(channels: [SalesChannel.shop]),
        ),
      );
      expect(
        online.nodes.map((n) => n.title),
        isNot(offline.nodes.map((n) => n.title)),
        reason: 'a shop already on Shopee needs different advice from a stall',
      );
    });

    test('a seasonal business gets a seasonal step', () {
      final seasonal = plan(
        input(
          type: GoalType.productLaunch,
          profile: const BusinessProfile(seasonality: BusinessSeasonality.tet),
        ),
      );
      expect(
        seasonal.nodes.any(
          (n) => n.reasonCodes.contains(JourneyReason.profileSeasonal),
        ),
        isTrue,
      );
      expect(seasonal.reasonCodes, contains(JourneyReason.profileSeasonal));
    });

    test('a non-seasonal business does not get that step', () {
      final flat = plan(
        input(
          type: GoalType.productLaunch,
          profile: const BusinessProfile(seasonality: BusinessSeasonality.none),
        ),
      );
      expect(flat.reasonCodes, isNot(contains(JourneyReason.profileSeasonal)));
    });
  });

  group('ADR-TON-016 — every node is authored by the rule', () {
    test('no node claims to come from AI', () {
      for (final type in GoalType.values) {
        for (final node in plan(input(type: type)).nodes) {
          expect(
            node.origin,
            JourneyNodeOrigin.ruleTwin,
            reason: 'the planner is a rule; AI may explain, never author',
          );
        }
      }
    });

    test('no node starts out done', () {
      for (final node in plan(input()).nodes) {
        expect(node.state, JourneyNodeState.pending);
      }
    });
  });

  group('the tree is well formed', () {
    test('steps hang off milestones, milestones are roots', () {
      final nodes = plan(input()).nodes;
      final ids = {for (final n in nodes) n.id};
      for (final n in nodes) {
        if (n.kind == JourneyNodeKind.milestone) {
          expect(n.parentId, isNull);
        } else {
          expect(n.parentId, isNotNull);
          expect(ids, contains(n.parentId));
        }
      }
    });

    test('every node belongs to the journey it was planned for', () {
      for (final n in planJourney(input(), journeyId: 'jX').nodes) {
        expect(n.journeyId, 'jX');
      }
    });
  });

  group('derived completion ties steps to real numbers', () {
    test('the revenue goal ends on a measurable step', () {
      final nodes = plan(input(type: GoalType.revenue)).nodes;
      final measured = nodes.where(
        (n) => n.completion == JourneyCompletion.derived,
      );
      expect(measured, isNotEmpty);
      expect(measured.any((n) => n.derivedMetric == 'revenue'), isTrue);
    });

    test('a derived step always names its metric and target', () {
      // Without both, "am I on track" cannot be answered and the step is just
      // a checkbox wearing a measurement's clothes.
      for (final type in GoalType.values) {
        for (final n in plan(input(type: type)).nodes) {
          if (n.completion == JourneyCompletion.derived) {
            expect(n.derivedMetric, isNotNull, reason: n.title);
            expect(n.derivedTarget, isNotNull, reason: n.title);
          }
        }
      }
    });

    test('the customer-growth target comes from the goal, not a constant', () {
      final nodes = planJourney(
        JourneyPlanInput(
          goal: BusinessGoal(
            id: 'g1',
            name: 'Mục tiêu',
            type: GoalType.customerGrowth,
            targetAmount: 0,
            achievedAmount: 0,
            growthTarget: 37,
            growthAchieved: 0,
            startDate: DateTime(2026, 8, 1),
            endDate: DateTime(2026, 12, 31),
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
          productCount: 5,
          customerCount: 5,
        ),
        journeyId: 'j1',
      ).nodes;
      expect(nodes.any((n) => n.derivedTarget == 37), isTrue);
    });
  });

  group('reason codes', () {
    test('are fixed tokens, safe for telemetry', () {
      for (final type in GoalType.values) {
        final result = plan(input(type: type));
        for (final code in [
          ...result.reasonCodes,
          ...result.nodes.expand((n) => n.reasonCodes),
        ]) {
          expect(
            code,
            matches(RegExp(r'^[a-z]+\.[a-z_]+$')),
            reason: 'a code built from data could leak business detail',
          );
        }
      }
    });

    test('name the goal that produced the plan', () {
      expect(
        plan(input(type: GoalType.newChannel)).reasonCodes,
        contains(JourneyReason.goalNewChannel),
      );
    });
  });

  group('dogfood — a business with no stock (found by running Workizen)', () {
    test('a services business is not told to import stock', () {
      // Running this planner against Workizen's own shape produced "nhập hàng
      // và ghi giá vốn". A business with nothing to warehouse does not import
      // stock, and advice that assumes it reads as software that has not
      // understood you.
      final services = plan(
        input(
          type: GoalType.productLaunch,
          profile: const BusinessProfile(trade: BusinessTrade.services),
        ),
      );
      expect(
        services.nodes.map((n) => n.title).join(' | '),
        isNot(contains('Nhập hàng')),
      );
      expect(services.reasonCodes, contains(JourneyReason.profileNoStock));
    });

    test('a goods business still gets the stock step', () {
      final goods = plan(
        input(
          type: GoalType.productLaunch,
          profile: const BusinessProfile(trade: BusinessTrade.fashion),
        ),
      );
      expect(
        goods.nodes.map((n) => n.title).join(' | '),
        contains('Nhập hàng'),
      );
      expect(goods.reasonCodes, isNot(contains(JourneyReason.profileNoStock)));
    });

    test('an unknown trade defaults to the goods plan', () {
      // Guessing "no stock" for someone who never told us would drop the step
      // most sellers need. Absent information falls back to the common case.
      final unknown = plan(input(type: GoalType.productLaunch));
      expect(
        unknown.nodes.map((n) => n.title).join(' | '),
        contains('Nhập hàng'),
      );
    });
  });
}
