import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_controller.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goal_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goals_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';

/// Widget tests for the WTM-87 goal screens: multi-step form (template →
/// details → review), validation surfacing, edit flow, list rendering and
/// the More-screen entry point.
void main() {
  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3400);
  }

  final now = DateTime(2026, 7, 22, 10);

  BusinessGoal existing() => BusinessGoal(
    id: 'g1',
    name: 'Đạt 100 triệu ₫ trong quý 3',
    type: GoalType.revenue,
    targetAmount: 100000000,
    achievedAmount: 62000000,
    growthTarget: 200,
    growthAchieved: 118,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 9, 30),
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 20),
  );

  // The goals screen is a ConsumerStatefulWidget (WTM-124) and does not hydrate
  // an injected controller, so the test hydrates it before pumping and wraps the
  // app in a ProviderScope.
  Future<void> pumpGoals(
    WidgetTester tester,
    BusinessGoalController controller,
  ) async {
    await controller.hydrate();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiGoalsScreen(controller: controller, clock: () => now),
        ),
      ),
    );
  }

  group('goals list (AC4/AC5)', () {
    testWidgets('renders progress, pace badge and recommendation', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = BusinessGoalController.inMemory([existing()]);
      await pumpGoals(tester, controller);
      await tester.pumpAndSettle();

      expect(find.text('Đạt 100 triệu ₫ trong quý 3'), findsOneWidget);
      expect(find.text('62%'), findsOneWidget); // progress
      // 2026-07-22 is ~23% into Jul 1→Sep 30; 62% ≥ 23%+10 → ahead.
      expect(find.text(GoalPace.ahead.labelVi), findsOneWidget);
      expect(
        find.textContaining('vượt tiến độ', findRichText: false),
        findsOneWidget,
      );
    });

    testWidgets('empty state invites creating the first goal', (tester) async {
      useTallViewport(tester);
      final controller = BusinessGoalController.inMemory(const []);
      await pumpGoals(tester, controller);
      expect(
        find.text('Đặt mục tiêu kinh doanh đầu tiên của bạn'),
        findsOneWidget,
      );
    });

    testWidgets('pace colors map correctly (pure function)', (tester) async {
      expect(tongtaiGoalPaceColor(GoalPace.ahead), TongtaiDesignTokens.success);
      expect(tongtaiGoalPaceColor(GoalPace.onTrack), TongtaiDesignTokens.info);
      expect(tongtaiGoalPaceColor(GoalPace.behind), TongtaiDesignTokens.error);
      expect(
        tongtaiGoalPaceColor(GoalPace.completed),
        TongtaiDesignTokens.success,
      );
      expect(
        tongtaiGoalPaceColor(GoalPace.notStarted),
        TongtaiDesignTokens.neutral,
      );
    });
  });

  group('multi-step add flow (AC1/AC2)', () {
    testWidgets(
      'template → details → review → create lands the goal in the list',
      (tester) async {
        useTallViewport(tester);
        final controller = BusinessGoalController.inMemory(const []);
        await pumpGoals(tester, controller);

        await tester.tap(find.widgetWithText(FloatingActionButton, 'New goal'));
        await tester.pumpAndSettle();

        // Step 1: template picker (AC2).
        expect(find.text('New Business Goal'), findsOneWidget);
        await tester.tap(find.byKey(const Key('goal-template-revenue')));
        await tester.pumpAndSettle();

        // Step 2: details prefilled from the template.
        final nameField = tester.widget<TextField>(
          find.byKey(const Key('goal-name-field')),
        );
        expect(nameField.controller!.text, 'Đạt 100 triệu ₫ trong quý');
        final targetField = tester.widget<TextField>(
          find.byKey(const Key('goal-target-field')),
        );
        expect(targetField.controller!.text, '100000000');

        await tester.tap(find.byKey(const Key('goal-next')));
        await tester.pumpAndSettle();

        // Step 3: review shows the recommendation seam and saves.
        expect(find.text('Create Goal'), findsOneWidget);
        await tester.tap(find.byKey(const Key('goal-save')));
        await tester.pumpAndSettle();

        expect(controller.count, 1);
        expect(find.text('Đạt 100 triệu ₫ trong quý'), findsOneWidget);
        expect(controller.goals.single.targetAmount, 100000000);
        expect(controller.goals.single.startDate, DateTime(2026, 7, 22));
      },
    );

    testWidgets('custom (blank) goal validates before review', (tester) async {
      useTallViewport(tester);
      final controller = BusinessGoalController.inMemory(const []);
      await pumpGoals(tester, controller);
      await tester.tap(find.widgetWithText(FloatingActionButton, 'New goal'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('goal-template-blank')));
      await tester.pumpAndSettle();

      // No name, no targets → Review must refuse and flag fields (AC1).
      await tester.tap(find.byKey(const Key('goal-next')));
      await tester.pumpAndSettle();
      expect(find.text('Goal name is required'), findsOneWidget);
      expect(
        find.text('Set a revenue target or a metric target'),
        findsOneWidget,
      );
      expect(controller.count, 0);

      // Let the validation SnackBar auto-dismiss so it no longer overlays
      // the bottom bar's Review button.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Fix the fields → review → create.
      await tester.enterText(
        find.byKey(const Key('goal-name-field')),
        'Thêm 50 khách sỉ',
      );
      await tester.enterText(
        find.byKey(const Key('goal-growth-target-field')),
        '50',
      );
      await tester.tap(find.byKey(const Key('goal-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal-save')));
      await tester.pumpAndSettle();

      expect(controller.count, 1);
      expect(controller.goals.single.growthTarget, 50);
      // Blank flow seeds a 30-day timeline from the injected clock.
      expect(controller.goals.single.startDate, DateTime(2026, 7, 22));
      expect(controller.goals.single.endDate, DateTime(2026, 8, 21));
    });
  });

  group('edit flow (AC3)', () {
    testWidgets('tapping a card opens edit; save updates progress fields', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = BusinessGoalController.inMemory([existing()]);
      await pumpGoals(tester, controller);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('goal-card-g1')));
      await tester.pumpAndSettle();

      // The card now opens the detail (WTM-88); its pencil opens the edit form.
      await tester.tap(find.byKey(const Key('goal-detail-edit')));
      await tester.pumpAndSettle();

      // Edit mode: no template step, achieved fields visible.
      expect(find.text('Edit Goal'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('goal-achieved-field')),
        '80000000',
      );
      await tester.tap(find.byKey(const Key('goal-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal-save')));
      await tester.pumpAndSettle();

      expect(controller.count, 1);
      final updated = controller.goals.single;
      expect(updated.id, 'g1');
      expect(updated.achievedAmount, 80000000);
      expect(updated.createdAt, DateTime(2026, 7, 1)); // preserved
      expect(find.text('80%'), findsOneWidget);
    });
  });

  group('More screen entry point', () {
    testWidgets('"Business Goals" opens the goals screen', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(const _MoreHost());
      await tester.ensureVisible(find.text('Business Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Business Goals'));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiGoalsScreen), findsOneWidget);
      expect(find.text('Business Goals'), findsOneWidget); // app bar title
    });
  });

  group('form standalone', () {
    testWidgets('pops null on cancel in edit mode (no upsert)', (tester) async {
      useTallViewport(tester);
      BusinessGoal? result = existing();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<BusinessGoal>(
                    MaterialPageRoute(
                      builder: (_) => TongtaiGoalFormScreen(
                        goal: existing(),
                        clock: () => now,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });
}

/// Hosts the More screen inside the Riverpod scope it needs. The ProviderScope
/// wraps the MaterialApp (above the Navigator) so the route pushed on tap — the
/// real (no-controller) goals screen, which hydrates from
/// [businessGoalRepositoryProvider] — inherits the in-memory override and the
/// smoke test stays off the real Drift database (WTM-124).
class _MoreHost extends StatelessWidget {
  const _MoreHost();

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      businessGoalRepositoryProvider.overrideWithValue(
        InMemoryBusinessGoalRepository(),
      ),
    ],
    child: const MaterialApp(home: TongtaiMoreScreen()),
  );
}
