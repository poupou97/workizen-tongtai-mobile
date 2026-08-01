import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/core/prefs.dart';

import '../../support/pump_until.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_reaction_repository.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/tongtai_app_shell.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';

/// WTM-91 — Opportunity Feed: controller unit tests (filter/sort/reactions)
/// and widget tests for every AC including the swipe gestures.
void main() {
  Opportunity make(
    String id, {
    OpportunityType type = OpportunityType.trend,
    double roi = 1.5,
    double score = 50,
    DateTime? at,
    OpportunityReaction reaction = OpportunityReaction.none,
  }) => Opportunity(
    id: id,
    type: type,
    title: 'Cơ hội $id',
    description: 'Mô tả $id',
    expectedImpact: 10000000,
    score: OpportunityScore.fixed(score),
    discoveredAt: at ?? DateTime(2026, 7, 20),
    reaction: reaction,
  );

  group('OpportunityFeedController', () {
    test('feed hides dismissed items but keeps them for the saved view', () {
      final controller = OpportunityFeedController([make('a'), make('b')]);
      controller.dismiss('a');

      expect(controller.feed(const OpportunityQuery()).map((o) => o.id), ['b']);
      // A dismissed item is not in the saved view either (it was never saved).
      expect(controller.feed(const OpportunityQuery(savedOnly: true)), isEmpty);
      // But it is restorable.
      controller.restore('a');
      expect(controller.feed(const OpportunityQuery()).map((o) => o.id), [
        'a',
        'b',
      ]);
    });

    test('type filter narrows the feed (AC2)', () {
      // WTM-182: the fixture used `arbitrage`, which the rule engine cannot
      // produce and which is now hidden from the feed. AC2 is unchanged — the
      // filter still has to narrow — so the fixture moved to two types that
      // can actually exist.
      final controller = OpportunityFeedController([
        make('a', type: OpportunityType.seasonal),
        make('b', type: OpportunityType.trend),
      ]);
      expect(
        controller
            .feed(const OpportunityQuery(type: OpportunityType.seasonal))
            .map((o) => o.id),
        ['a'],
      );
      expect(controller.availableTypes, [
        OpportunityType.seasonal,
        OpportunityType.trend,
      ]);
    });

    test('sorting by relevance and recency, descending (AC3)', () {
      final controller = OpportunityFeedController([
        make('a', score: 50, roi: 3.0, at: DateTime(2026, 7, 22)),
        make('b', score: 90, roi: 1.2, at: DateTime(2026, 7, 20)),
        make('c', score: 70, roi: 2.0, at: DateTime(2026, 7, 21)),
      ]);
      expect(
        controller
            .feed(const OpportunityQuery(sort: OpportunitySort.relevance))
            .map((o) => o.id),
        ['b', 'c', 'a'],
      );
      expect(
        controller
            .feed(const OpportunityQuery(sort: OpportunitySort.recency))
            .map((o) => o.id),
        ['a', 'c', 'b'],
      );
      // WTM-193: the ROI facet is hidden and falls back to relevance — it
      // sorted by a constant, so it never sorted by ROI in the first place.
      expect(
        controller
            .feed(const OpportunityQuery(sort: OpportunitySort.roi))
            .map((o) => o.id),
        ['b', 'c', 'a'],
      );
    });

    test('toggleSaved bookmarks and unbookmarks (AC4)', () {
      final controller = OpportunityFeedController([make('a')]);
      controller.toggleSaved('a');
      expect(controller.savedCount, 1);
      expect(
        controller
            .feed(const OpportunityQuery(savedOnly: true))
            .map((o) => o.id),
        ['a'],
      );
      controller.toggleSaved('a');
      expect(controller.savedCount, 0);
    });

    test(
      'markInterested keeps the item in the feed with the reaction (AC5)',
      () {
        final controller = OpportunityFeedController([make('a')]);
        controller.markInterested('a');
        final item = controller.feed(const OpportunityQuery()).single;
        expect(item.reaction, OpportunityReaction.interested);
      },
    );

    test('sample opportunities are well-formed', () {
      final ids = kSampleOpportunities.map((o) => o.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final o in kSampleOpportunities) {
        expect(o.title, isNotEmpty);
        expect(o.expectedImpact, greaterThan(0));
        expect(o.aiScore, inInclusiveRange(0, 100));
      }
    });
  });

  group('feed screen widgets', () {
    void useTallViewport(WidgetTester tester) {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 3400);
    }

    /// One database per test, created lazily.
    ///
    /// Shared rather than rebuilt on every `pumpWidget`, because constructing
    /// `AppDatabase` twice over one executor is the race condition drift warns
    /// about — and a warning nobody reads is how real corruption ships.
    AppDatabase? sharedDb;
    AppDatabase memoryDb() =>
        sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());
    tearDown(() async {
      await sharedDb?.close();
      sharedDb = null;
    });

    /// The screen persists every reaction now (WTM-190), so it needs a real
    /// provider scope even when the feed itself is injected — a harness that
    /// cannot supply one is not hosting the screen users get.
    Widget scoped(Widget child) => ProviderScope(
      overrides: [tongtaiDatabaseProvider.overrideWithValue(memoryDb())],
      child: child,
    );

    Widget host(OpportunityFeedController controller) => scoped(
      MaterialApp(home: TongtaiOpportunityFeedScreen(controller: controller)),
    );

    testWidgets('WTM-190: tapping save writes it to the database', (
      tester,
    ) async {
      // The defect this closes: the button worked on screen and changed
      // nothing on disk, so every save was gone by the next launch.
      useTallViewport(tester);
      final controller = OpportunityFeedController([make('a')]);
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));

      await tester.tap(find.byKey(const Key('opportunity-save-a')));
      await tester.pumpAndSettle();

      expect(await OpportunityReactionRepository(memoryDb()).loadAll(), {
        'a': OpportunityReaction.saved,
      });
    });

    testWidgets('WTM-190: un-saving removes it from the database', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([make('a')]);
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));

      await tester.tap(find.byKey(const Key('opportunity-save-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opportunity-save-a')));
      await tester.pumpAndSettle();

      expect(
        await OpportunityReactionRepository(memoryDb()).loadAll(),
        isEmpty,
        reason: 'the stored decision must follow the toggle, not lag it',
      );
    });

    testWidgets('AC1: cards show title, description and expected impact', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([
        make('a', type: OpportunityType.seasonal),
      ]);
      await tester.pumpWidget(host(controller));

      expect(find.text('Cơ hội a'), findsOneWidget);
      expect(find.text('Mô tả a'), findsOneWidget);
      expect(find.textContaining('+10.000.000 ₫'), findsOneWidget);
      expect(find.text(OpportunityType.seasonal.labelEn), findsWidgets);
    });

    testWidgets('WTM-130: rule-based signal badges render on a card', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([
        // seasonal → Urgent; ROI 1.5 < 2.0 → High Risk; impact 10M → not high value.
        make(
          'a',
          type: OpportunityType.seasonal,
          roi: 1.5,
          at: DateTime(2026, 7, 24),
        ),
      ]);
      await tester.pumpWidget(
        scoped(
          MaterialApp(
            home: TongtaiOpportunityFeedScreen(
              controller: controller,
              clock: () => DateTime(2026, 7, 25),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('opportunity-signal-urgent')),
        findsOneWidget,
      );
      // WTM-193: High Risk is no longer emitted — it compared a constant ROI
      // against a threshold, so it only restated which rule fired.
      expect(
        find.byKey(const Key('opportunity-signal-highRisk')),
        findsNothing,
      );
      expect(find.text('Urgent'), findsOneWidget);
      expect(
        find.byKey(const Key('opportunity-signal-highValue')),
        findsNothing,
      );
    });

    testWidgets('WTM-130: an old untouched opportunity shows the Stale badge', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([
        make('old', roi: 2.5, at: DateTime(2026, 7, 1)), // 24 days old
      ]);
      await tester.pumpWidget(
        scoped(
          MaterialApp(
            home: TongtaiOpportunityFeedScreen(
              controller: controller,
              clock: () => DateTime(2026, 7, 25),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('opportunity-signal-stale')), findsOneWidget);
      expect(find.text('Stale'), findsOneWidget);
    });

    testWidgets('AC2/AC3: type chips filter, sort chips re-order', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([
        make('a', type: OpportunityType.seasonal, score: 50, roi: 3.0),
        make('b', type: OpportunityType.trend, score: 90, roi: 1.0),
      ]);
      await tester.pumpWidget(host(controller));

      // Default sort = relevance → b (90) above a (50).
      final orderBefore = tester
          .widgetList<Text>(find.textContaining('Cơ hội '))
          .map((t) => t.data)
          .toList();
      expect(orderBefore, ['Cơ hội b', 'Cơ hội a']);

      // WTM-193: the ROI chip is gone — it sorted by a constant. What is left
      // must still be offered, and must still re-order.
      expect(find.byKey(const Key('opportunity-sort-roi')), findsNothing);
      await tester.tap(find.byKey(const Key('opportunity-sort-recency')));
      await tester.pumpAndSettle();
      final orderAfter = tester
          .widgetList<Text>(find.textContaining('Cơ hội '))
          .map((t) => t.data)
          .toList();
      expect(orderAfter, ['Cơ hội a', 'Cơ hội b']);

      // Filter by seasonal → only a.
      await tester.tap(find.byKey(const Key('opportunity-type-seasonal')));
      await tester.pumpAndSettle();
      expect(find.text('Cơ hội a'), findsOneWidget);
      expect(find.text('Cơ hội b'), findsNothing);
      expect(find.text('1 opportunity'), findsOneWidget);
    });

    testWidgets('AC4: bookmark toggles and the saved view filters to it', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([make('a'), make('b')]);
      await tester.pumpWidget(host(controller));

      await tester.tap(find.byKey(const Key('opportunity-save-a')));
      await tester.pumpAndSettle();
      expect(controller.savedCount, 1);

      await tester.tap(find.byKey(const Key('opportunity-saved-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Cơ hội a'), findsOneWidget);
      expect(find.text('Cơ hội b'), findsNothing);
    });

    testWidgets('AC5: swipe left dismisses with undo; undo restores', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([make('a'), make('b')]);
      await tester.pumpWidget(host(controller));

      // Swipe left (endToStart) on card a.
      await tester.drag(
        find.byKey(const Key('opportunity-card-a')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cơ hội a'), findsNothing);
      expect(find.textContaining('Dismissed'), findsOneWidget);

      // Undo via the snackbar action.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Cơ hội a'), findsOneWidget);
    });

    testWidgets('AC5: swipe right marks interested and keeps it listed', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([make('a'), make('b')]);
      await tester.pumpWidget(host(controller));

      await tester.drag(
        find.byKey(const Key('opportunity-card-a')),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();

      expect(
        controller.all.firstWhere((o) => o.id == 'a').reaction,
        OpportunityReaction.interested,
      );
      // Re-rendered with the reaction label.
      expect(find.text(OpportunityReaction.interested.labelEn), findsWidgets);
      // Flush the confirmation snackbar timer.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('type colors map to design tokens (pure function)', (
      tester,
    ) async {
      expect(
        tongtaiOpportunityTypeColor(OpportunityType.arbitrage),
        TongtaiDesignTokens.inventoryOrange,
      );
      expect(
        tongtaiOpportunityTypeColor(OpportunityType.seasonal),
        TongtaiDesignTokens.producerGreen,
      );
      expect(
        tongtaiOpportunityTypeColor(OpportunityType.crossBorder),
        TongtaiDesignTokens.consumerBlue,
      );
      expect(
        tongtaiOpportunityTypeColor(OpportunityType.trend),
        TongtaiDesignTokens.financePurple,
      );
    });

    testWidgets('Home "View all" switches to the Opportunity tab', (
      tester,
    ) async {
      useTallViewport(tester);
      // WTM-192: Opportunity is a tab now, so "view all" **selects** it rather
      // than pushing a copy — two instances of the same screen would each keep
      // their own filter and sort, the parallel state ADR-TON-015 forbids.
      // Hosted in the real shell, because "switches tab" is only meaningful
      // when there is a tab to switch to.
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
          child: const MaterialApp(home: TongtaiAppShell()),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('home-open-opportunities')),
      );

      await tester.tap(find.byKey(const Key('home-open-opportunities')));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiOpportunityFeedScreen), findsOneWidget);
      // …and it is the tab, not a pushed route: nothing to pop back from.
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets(
      'real mode shows rule-generated opportunities (WTM-140) — and the empty '
      'state for a brand-new business',
      (tester) async {
        useTallViewport(tester);
        // An out-of-stock product WITH sales → the rule engine generates a
        // restock opportunity that must appear in the real-mode feed.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                InMemoryOrderRepository([
                  CustomerOrder(
                    id: 'o1',
                    customerId: 'c1',
                    orderNumber: 'DH-o1',
                    date: DateTime(2026, 7, 20),
                    status: OrderStatus.delivered,
                    items: const [
                      OrderItem(
                        productName: 'Quạt mini',
                        category: 'Home',
                        quantity: 1,
                        unitPrice: 800000,
                      ),
                    ],
                  ),
                ]),
              ),
              customerRepositoryProvider.overrideWithValue(
                InMemoryCustomerRepository(),
              ),
              productRepositoryProvider.overrideWithValue(
                InMemoryProductRepository([
                  Product(
                    id: 'p1',
                    sku: 'SKU-p1',
                    name: 'Quạt mini',
                    category: 'Home',
                    quantity: 0,
                    pricePerUnit: 100000,
                    reorderLevel: 3,
                    updatedAt: DateTime(2026, 7, 1),
                  ),
                ]),
              ),
              businessGoalRepositoryProvider.overrideWithValue(
                InMemoryBusinessGoalRepository(),
              ),
              tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
            ],
            child: const MaterialApp(home: TongtaiOpportunityFeedScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Nhập lại Quạt mini'), findsOneWidget);

        // Tear the first tree down before building the second. Swapping one
        // ProviderScope for another in place makes Riverpod invalidate the
        // database-backed providers *during* the new build — an artifact of
        // this harness, not of the app, which never replaces its root scope.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // A brand-new business (empty repositories) → empty state.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                InMemoryOrderRepository(),
              ),
              customerRepositoryProvider.overrideWithValue(
                InMemoryCustomerRepository(),
              ),
              productRepositoryProvider.overrideWithValue(
                InMemoryProductRepository([]),
              ),
              businessGoalRepositoryProvider.overrideWithValue(
                InMemoryBusinessGoalRepository(),
              ),
              tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
            ],
            child: const MaterialApp(
              // A distinct key forces a fresh State (initState re-runs).
              home: TongtaiOpportunityFeedScreen(key: Key('fresh-empty')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No opportunities here yet.'), findsOneWidget);
      },
    );
  });
}
