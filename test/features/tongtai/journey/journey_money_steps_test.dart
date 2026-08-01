import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';

/// WTM-198 (F-3) — the journey talks about money, and what it says depends on
/// the seller's actual ledger.
///
/// The audit finding (WTM-195): the planner taught sellers to import stock,
/// nurture customers and push categories — then stayed completely silent about
/// whether any of it was **profitable**. Where money steps existed they were
/// manual ticks, which ADR-TON-021 calls out: progress must be an observation,
/// not a declaration.
///
/// Deliberately written **after** WTM-196: a money step that sent the seller to
/// a Finance screen showing ₫0 income would have been teaching them to open a
/// screen that lied.
void main() {
  BusinessGoal goal(GoalType type) => BusinessGoal(
    id: 'g1',
    name: 'Mục tiêu',
    type: type,
    targetAmount: 50000000,
    achievedAmount: 0,
    growthTarget: 20,
    growthAchieved: 0,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  JourneyPlanInput input(
    GoalType type, {
    int expenses = 0,
    int products = 10,
    int customers = 5,
    int orders = 3,
  }) => JourneyPlanInput(
    goal: goal(type),
    productCount: products,
    customerCount: customers,
    orderCount: orders,
    expenseCount: expenses,
  );

  List<JourneyNode> plan(JourneyPlanInput i) {
    final result = planJourney(i, journeyId: 'j1');
    expect(result.isSufficient, isTrue);
    return result.nodes;
  }

  group('an empty ledger gets a measured first step', () {
    test('revenue plan: five recorded expenses is an observation', () {
      final nodes = plan(input(GoalType.revenue, expenses: 0));

      final step = nodes.firstWhere(
        (n) => n.derivedMetric == 'expenses',
        orElse: () => fail('no measured expense step in the plan'),
      );
      expect(step.derivedTarget, 5);
      expect(
        step.completion,
        JourneyCompletion.derived,
        reason: 'ADR-TON-021: progress is measured, not declared',
      );
      expect(step.reasonCodes, contains(JourneyReason.dataEmptyExpenses));
    });

    test('customer-growth plan gets one too', () {
      final nodes = plan(input(GoalType.customerGrowth, expenses: 0));

      expect(
        nodes.any((n) => n.derivedMetric == 'expenses'),
        isTrue,
        reason:
            'a plan about acquiring customers must ask what acquiring costs',
      );
    });
  });

  group(
    'a seller already recording gets the next thing, not the first thing',
    () {
      test('revenue plan moves on to reading profit', () {
        final nodes = plan(input(GoalType.revenue, expenses: 12));

        expect(
          nodes.any((n) => n.derivedMetric == 'expenses'),
          isFalse,
          reason: 'they already record — asking for the first five is noise',
        );
        expect(
          nodes.any((n) => n.title.contains('lãi lỗ')),
          isTrue,
          reason: 'the point of recording is being able to read profit',
        );
      });

      test('the two ledger states produce different plans', () {
        // The test that fails if the planner returns fixed steps — the audit's
        // core complaint. Same goal, different data, different plan.
        final empty = plan(
          input(GoalType.revenue, expenses: 0),
        ).map((n) => n.title).toSet();
        final recording = plan(
          input(GoalType.revenue, expenses: 12),
        ).map((n) => n.title).toSet();

        expect(
          empty,
          isNot(recording),
          reason:
              'a plan that ignores the ledger has not looked at the business',
        );
      });
    },
  );

  test('every goal type produces at least one money step', () {
    // The audit finding, pinned: no plan may stay silent about money.
    const moneyWords = ['chi phí', 'chi đầu tiên', 'lãi', 'giá bán', 'sổ chi'];
    for (final type in GoalType.values) {
      final titles = plan(input(type)).map((n) => n.title.toLowerCase());

      expect(
        titles.any((t) => moneyWords.any(t.contains)),
        isTrue,
        reason: '${type.name} plan never mentions money',
      );
    }
  });

  test('money steps come from the rules, and say so', () {
    // Rule Twin authoritative (ADR-TON-016): no AI, no network, no key was
    // involved in producing these — and the origin field is what makes that
    // checkable rather than merely claimed.
    final nodes = plan(input(GoalType.revenue, expenses: 0));
    final step = nodes.firstWhere((n) => n.derivedMetric == 'expenses');

    expect(step.origin, JourneyNodeOrigin.ruleTwin);
  });
}
