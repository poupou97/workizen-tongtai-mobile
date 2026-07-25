import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
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
    estimatedRoi: roi,
    aiScore: score,
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
      final controller = OpportunityFeedController([
        make('a', type: OpportunityType.seasonal),
        make('b', type: OpportunityType.arbitrage),
      ]);
      expect(
        controller
            .feed(const OpportunityQuery(type: OpportunityType.seasonal))
            .map((o) => o.id),
        ['a'],
      );
      expect(controller.availableTypes, [
        OpportunityType.arbitrage,
        OpportunityType.seasonal,
      ]);
    });

    test('sorting by relevance, recency and ROI, descending (AC3)', () {
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
      expect(
        controller
            .feed(const OpportunityQuery(sort: OpportunitySort.roi))
            .map((o) => o.id),
        ['a', 'c', 'b'],
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

    Widget host(OpportunityFeedController controller) =>
        MaterialApp(home: TongtaiOpportunityFeedScreen(controller: controller));

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
      expect(find.text(OpportunityType.seasonal.labelVi), findsWidgets);
    });

    testWidgets('AC2/AC3: type chips filter, sort chips re-order', (
      tester,
    ) async {
      useTallViewport(tester);
      final controller = OpportunityFeedController([
        make('a', type: OpportunityType.seasonal, score: 50, roi: 3.0),
        make('b', type: OpportunityType.arbitrage, score: 90, roi: 1.0),
      ]);
      await tester.pumpWidget(host(controller));

      // Default sort = relevance → b (90) above a (50).
      final orderBefore = tester
          .widgetList<Text>(find.textContaining('Cơ hội '))
          .map((t) => t.data)
          .toList();
      expect(orderBefore, ['Cơ hội b', 'Cơ hội a']);

      // ROI sort → a (3.0) first.
      await tester.tap(find.byKey(const Key('opportunity-sort-roi')));
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
      expect(find.textContaining('Đã bỏ qua'), findsOneWidget);

      // Undo via the snackbar action.
      await tester.tap(find.text('Hoàn tác'));
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
      expect(find.text(OpportunityReaction.interested.labelVi), findsWidgets);
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

    testWidgets('Home "View all" opens the feed', (tester) async {
      useTallViewport(tester);
      // Home loads its KPIs/counts from the repositories (WTM-128); keep it off
      // the real Drift database with an in-memory override.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tongtaiDatabaseProvider.overrideWithValue(
              AppDatabase.forExecutor(NativeDatabase.memory()),
            ),
          ],
          child: const MaterialApp(home: TongtaiHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-open-opportunities')));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiOpportunityFeedScreen), findsOneWidget);
      expect(find.text('Opportunities'), findsOneWidget);
    });
  });
}
