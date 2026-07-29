import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_controller.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goal_detail_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goals_screen.dart';

/// WTM-88 — the goal detail screen shows progress, pace, the action plan and
/// tips, and its edit action calls back.
void main() {
  final now = DateTime(2026, 7, 1);
  DateTime clock() => now;

  BusinessGoal buildGoal() => BusinessGoal(
    id: 'g1',
    name: 'Mục tiêu quý 3',
    type: GoalType.revenue,
    targetAmount: 100000000,
    achievedAmount: 55000000,
    growthTarget: 0,
    growthAchieved: 0,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  testWidgets('renders name, progress, pace and the action plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiGoalDetailScreen(goal: buildGoal(), clock: clock),
      ),
    );

    expect(find.byKey(const Key('goal-detail-title')), findsOneWidget);
    expect(find.text('Mục tiêu quý 3'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget); // 55M / 100M progress
    expect(find.text('Đúng tiến độ'), findsOneWidget); // on-track pace
    expect(find.byKey(const Key('goal-detail-plan')), findsOneWidget);

    // The revenue plan's first step (may sit just below the fold).
    await tester.scrollUntilVisible(
      find.text('Tăng giá trị mỗi đơn'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tăng giá trị mỗi đơn'), findsOneWidget);
  });

  testWidgets('the edit action calls onEdit', (tester) async {
    var edited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiGoalDetailScreen(
          goal: buildGoal(),
          clock: clock,
          onEdit: () => edited = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('goal-detail-edit')));
    await tester.pump();

    expect(edited, isTrue);
  });

  testWidgets('no edit action is shown when onEdit is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiGoalDetailScreen(goal: buildGoal(), clock: clock),
      ),
    );

    expect(find.byKey(const Key('goal-detail-edit')), findsNothing);
  });

  testWidgets(
    'shows the real-sales card when realizedRevenue is provided (WTM-89)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiGoalDetailScreen(
            goal: buildGoal(), // revenue target 100M
            clock: clock,
            realizedRevenue: 30000000, // 30% of target from real orders
          ),
        ),
      );

      expect(find.byKey(const Key('goal-detail-realized')), findsOneWidget);
      expect(find.textContaining('30% mục tiêu'), findsOneWidget);
      // The manual progress (55%) is untouched — both are shown.
      expect(find.text('55%'), findsOneWidget);
    },
  );

  testWidgets('hides the real-sales card when realizedRevenue is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiGoalDetailScreen(goal: buildGoal(), clock: clock),
      ),
    );

    expect(find.byKey(const Key('goal-detail-realized')), findsNothing);
  });

  testWidgets('tapping a goal card on the goals screen opens the detail', (
    tester,
  ) async {
    final controller = BusinessGoalController.inMemory([buildGoal()]);
    addTearDown(controller.dispose);
    await controller.hydrate();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiGoalsScreen(controller: controller, clock: clock),
        ),
      ),
    );

    await tester.tap(find.text('Mục tiêu quý 3'));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiGoalDetailScreen), findsOneWidget);
  });
}
