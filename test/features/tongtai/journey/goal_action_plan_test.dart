import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/goal_action_plan.dart';

/// WTM-88 — the rule-based goal action plan, tuned by archetype and pace.
void main() {
  BusinessGoal goal({
    GoalType type = GoalType.revenue,
    double achieved = 50000000,
  }) => BusinessGoal(
    id: 'g1',
    name: 'Mục tiêu quý 3',
    type: type,
    targetAmount: 100000000,
    achievedAmount: achieved,
    growthTarget: 0,
    growthAchieved: 0,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final now = DateTime(2026, 7, 1);

  test('every archetype yields a plan that closes on weekly tracking', () {
    for (final type in GoalType.values) {
      final plan = goalActionPlan(goal(type: type), now);
      expect(plan.length, greaterThanOrEqualTo(4), reason: type.name);
      expect(plan.last.titleVi, 'Theo dõi hằng tuần', reason: type.name);
    }
  });

  test('a goal behind pace opens with an urgency step', () {
    // 5% achieved at ~50% of the timeline → behind.
    final behind = goal(achieved: 5000000);
    final plan = goalActionPlan(behind, now);
    expect(plan.first.titleVi, 'Đang chậm tiến độ — ưu tiên ngay');
  });

  test('an on-track goal has no urgency step', () {
    // 50% achieved at ~50% elapsed → on track.
    final plan = goalActionPlan(goal(), now);
    expect(plan.first.titleVi, isNot('Đang chậm tiến độ — ưu tiên ngay'));
    expect(plan.first.titleVi, 'Tăng giá trị mỗi đơn');
  });

  test('guidance tips exist for every archetype and differ', () {
    final firstTips = <String>{};
    for (final type in GoalType.values) {
      final tips = goalGuidanceTips(type);
      expect(tips, isNotEmpty, reason: type.name);
      firstTips.add(tips.first);
    }
    expect(firstTips, hasLength(GoalType.values.length));
  });
}
