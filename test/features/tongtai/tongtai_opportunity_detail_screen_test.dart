import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_journey_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_detail_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';

import '../../support/tap_by_key.dart';

/// WTM-92 — the Opportunity detail screen shows the full opportunity with its
/// AI score, key numbers and action plan, and its reactions call back.
void main() {
  final sample = Opportunity(
    id: 'o1',
    type: OpportunityType.seasonal,
    title: 'Quạt tích điện sắp vào mùa nóng',
    description: 'Nhu cầu quạt tích điện tăng mạnh khi vào hè.',
    expectedImpact: 5200000,
    impactBasis: OpportunityImpactBasis.estimatedGain,
    score: OpportunityScore.fixed(92),
    discoveredAt: DateTime(2026, 7, 18),
  );

  testWidgets('renders title, score and the action plan', (tester) async {
    await tester.pumpWidget(
      // WTM-223: the screen now READS the journey in `build` (to show whether
      // this opportunity is already in it), so it needs a scope — these bare
      // pumps only ever worked because nothing touched `ref`.
      ProviderScope(
        child: MaterialApp(
          home: TongtaiOpportunityDetailScreen(opportunity: sample),
        ),
      ),
    );

    expect(find.byKey(const Key('opportunity-detail-title')), findsOneWidget);
    expect(find.text('Quạt tích điện sắp vào mùa nóng'), findsOneWidget);
    expect(find.text('92'), findsOneWidget); // AI score badge
    // The ROI tile is gone (WTM-193): it displayed a constant.
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('+5,2tr ₫'), findsOneWidget); // expected impact, compact
    expect(find.byKey(const Key('opportunity-detail-plan')), findsOneWidget);
    // A seasonal plan starts with demand forecasting and ends on the scale gate.
    expect(find.text('Dự báo nhu cầu mùa'), findsOneWidget);
    expect(find.text('Quyết định scale'), findsOneWidget);
  });

  testWidgets('the Interested button calls back', (tester) async {
    var interested = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiOpportunityDetailScreen(
            opportunity: sample,
            onInterested: () => interested = true,
          ),
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
      ProviderScope(
        child: MaterialApp(
          home: TongtaiOpportunityDetailScreen(
            opportunity: sample,
            onToggleSaved: () => toggles++,
          ),
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
      // WTM-190: the feed writes reactions, so it needs a provider scope.
      ProviderScope(
        overrides: [
          tongtaiDatabaseProvider.overrideWithValue(
            AppDatabase.forExecutor(NativeDatabase.memory()),
          ),
        ],
        child: MaterialApp(
          home: TongtaiOpportunityFeedScreen(controller: controller),
        ),
      ),
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

  group('WTM-191 · đưa cơ hội vào hành trình', () {
    late Directory dir;
    late AppDatabase db;
    late JourneyRepository journeys;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tongtai_opp_to_journey');
      db = AppDatabase.forExecutor(
        NativeDatabase(File('${dir.path}/t.sqlite')),
      );
      journeys = JourneyRepository(db);
    });

    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    /// A viewport tall enough that every control is on screen.
    ///
    /// The same pattern the feed suite uses: this test is about what the tap
    /// *does*, and reachability on a small screen is what
    /// `p0/accessibility_test.dart` measures.
    void useTallViewport(WidgetTester tester) {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 2400);
    }

    Widget host() => ProviderScope(
      overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: TongtaiOpportunityDetailScreen(
          opportunity: sample,
          clock: () => DateTime(2026, 8, 1),
        ),
      ),
    );

    Future<void> seedActiveJourney() => journeys.save(
      Journey(
        id: 'j1',
        goalId: 'g1',
        state: JourneyState.active,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        nodes: [
          JourneyNode(
            id: 'root',
            journeyId: 'j1',
            kind: JourneyNodeKind.milestone,
            title: 'Mốc đầu',
            origin: JourneyNodeOrigin.ruleTwin,
          ),
        ],
      ),
    );

    /// `tapByKey`, not `tester.tap`: a miss only warns, and a test that keeps
    /// running after a missed tap asserts against a screen nobody touched.
    Future<void> tapAdd(WidgetTester tester) => tester.tapByKey(
      'opportunity-detail-add-to-journey',
      scrollableUnder: 'opportunity-detail-list',
    );

    testWidgets('creates a seller-authored node in the active journey', (
      tester,
    ) async {
      useTallViewport(tester);
      await seedActiveJourney();
      await tester.pumpWidget(host());

      await tapAdd(tester);

      final node = (await journeys.loadAll()).single.nodes.firstWhere(
        (n) => n.sourceOpportunityId == 'o1',
      );
      expect(node.title, 'Quạt tích điện sắp vào mùa nóng');
      expect(node.origin, JourneyNodeOrigin.user);
      expect(node.state, JourneyNodeState.pending);
    });

    testWidgets('says what to do first when no journey is running', (
      tester,
    ) async {
      useTallViewport(tester);
      // An honest refusal beats inventing a journey the seller never asked
      // for — a journey belongs to a goal, and only the seller sets goals.
      await tester.pumpWidget(host());

      await tapAdd(tester);

      expect(await journeys.loadAll(), isEmpty);
      expect(find.textContaining('No journey is running'), findsOneWidget);
    });

    testWidgets('the RESULT replaces the button, and leads on to the journey', (
      tester,
    ) async {
      // Business Loop beats 3 and 4 (Founder 2026-08-02): "thấy kết quả" and
      // "biết bước tiếp theo" must OUTLIVE the action. A snackbar is
      // explicitly not the end of a business flow — it vanishes in seconds,
      // leaving a seller who looked away with a decision they made and no
      // trace of where it went.
      //
      // This replaces the old "tapping twice does not duplicate" test: the
      // second tap is now impossible because the button is gone once the
      // work exists. The repository-level guard in `_addToJourney` stays as
      // defence in depth for a stale screen.
      useTallViewport(tester);
      await seedActiveJourney();
      await tester.pumpWidget(host());

      await tapAdd(tester);
      await tester.pumpAndSettle();
      // Let every snackbar time out: whatever remains is the real answer.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(
        (await journeys.loadAll()).single.nodes.where(
          (n) => n.sourceOpportunityId == 'o1',
        ),
        hasLength(1),
      );
      expect(find.byKey(const Key('opportunity-in-journey')), findsOneWidget);
      expect(
        find.byKey(const Key('opportunity-detail-add-to-journey')),
        findsNothing,
        reason: 'the button is replaced by its result, not left to repeat',
      );

      await tester.tapByKey(
        'opportunity-open-journey',
        scrollableUnder: 'opportunity-detail-list',
      );
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiJourneyScreen), findsOneWidget);
    });
  });
}
