import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_detail_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';

/// WTM-92 — the Opportunity detail screen shows the full opportunity with its
/// AI score, key numbers and action plan, and its reactions call back.
void main() {
  final sample = Opportunity(
    id: 'o1',
    type: OpportunityType.seasonal,
    title: 'Quạt tích điện sắp vào mùa nóng',
    description: 'Nhu cầu quạt tích điện tăng mạnh khi vào hè.',
    expectedImpact: 5200000,
    estimatedRoi: 2.4,
    aiScore: 92,
    discoveredAt: DateTime(2026, 7, 18),
  );

  testWidgets('renders title, AI score, ROI and the action plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TongtaiOpportunityDetailScreen(opportunity: sample)),
    );

    expect(find.byKey(const Key('opportunity-detail-title')), findsOneWidget);
    expect(find.text('Quạt tích điện sắp vào mùa nóng'), findsOneWidget);
    expect(find.text('92'), findsOneWidget); // AI score badge
    expect(find.text('240%'), findsOneWidget); // ROI 2.4×
    expect(find.text('+5,2tr ₫'), findsOneWidget); // expected impact, compact
    expect(find.byKey(const Key('opportunity-detail-plan')), findsOneWidget);
    // A seasonal plan starts with demand forecasting and ends on the scale gate.
    expect(find.text('Dự báo nhu cầu mùa'), findsOneWidget);
    expect(find.text('Quyết định scale'), findsOneWidget);
  });

  testWidgets('the Interested button calls back', (tester) async {
    var interested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiOpportunityDetailScreen(
          opportunity: sample,
          onInterested: () => interested = true,
        ),
      ),
    );

    // The reaction buttons sit at the bottom of the scrolling detail.
    final button = find.byKey(const Key('opportunity-detail-interested'));
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(interested, isTrue);
  });

  testWidgets('the save action toggles the bookmark and calls back', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiOpportunityDetailScreen(
          opportunity: sample,
          onToggleSaved: () => toggles++,
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    await tester.tap(find.byKey(const Key('opportunity-detail-save')));
    await tester.pump();

    expect(toggles, 1);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('tapping a feed card opens the detail screen', (tester) async {
    final controller = OpportunityFeedController.sample();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: TongtaiOpportunityFeedScreen(controller: controller)),
    );

    // The highest AI-scored sample opportunity sits at the top of the feed
    // (default relevance sort); tapping its card body opens the detail.
    final topCard = find.text('Quạt tích điện sắp vào mùa nóng');
    expect(topCard, findsOneWidget);
    await tester.tap(topCard);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiOpportunityDetailScreen), findsOneWidget);
  });

  testWidgets(
    'WTM-94: "Tạo mục tiêu" creates an idempotent Journey goal from the '
    'opportunity',
    (tester) async {
      final repo = InMemoryBusinessGoalRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [businessGoalRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: TongtaiOpportunityDetailScreen(
              opportunity: sample,
              clock: () => DateTime(2026, 7, 29),
            ),
          ),
        ),
      );

      final button = find.byKey(const Key('opportunity-create-goal'));
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();

      final goals = await repo.loadAll();
      final goal = goals.single;
      expect(goal.id, 'goal-from-o1');
      expect(goal.name, 'Quạt tích điện sắp vào mùa nóng');
      expect(goal.targetAmount, 5200000); // expectedImpact
      expect(goal.endDate, DateTime(2026, 7, 29).add(const Duration(days: 45)));
      expect(find.textContaining('Created goal'), findsOneWidget);

      // Idempotent: a second tap upserts the same id — no duplicates.
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(await repo.loadAll(), hasLength(1));
    },
  );
}
