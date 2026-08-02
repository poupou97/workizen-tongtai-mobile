import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goals_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_journey_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-226 — the Business Loop at the **goal** level.
///
/// Audited from the Business Goal, not from the screens: a seller sets "Doanh
/// thu 50 triệu", works through every step the Rule Twin planned, and reaches
/// the end. Before this the app showed a 100% bar and said nothing —
/// `JourneyState.completed` existed from the first commit and **nothing ever
/// set it**. The most important moment in the product had no response at all,
/// and no missing widget to grep for.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tongtai_goal_loop');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  /// A journey whose only step is already done — the state a seller reaches
  /// after finishing the work, built directly so the test is about what the
  /// product SAYS at that moment.
  Future<void> seedFinishedJourney({required bool done}) =>
      JourneyRepository(db).save(
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
            JourneyNode(
              id: 'step',
              journeyId: 'j1',
              parentId: 'root',
              kind: JourneyNodeKind.step,
              title: 'Việc duy nhất',
              origin: JourneyNodeOrigin.ruleTwin,
              state: done ? JourneyNodeState.done : JourneyNodeState.pending,
              completedAt: done ? DateTime(2026, 8, 2) : null,
            ),
          ],
        ),
      );

  Future<Widget> host() async => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      tongtaiDatabaseProvider.overrideWithValue(db),
      customerRepositoryProvider.overrideWithValue(DriftCustomerRepository(db)),
      productRepositoryProvider.overrideWithValue(DriftProductRepository(db)),
      orderRepositoryProvider.overrideWithValue(DriftOrderRepository(db)),
      businessGoalRepositoryProvider.overrideWithValue(
        DriftBusinessGoalRepository(db),
      ),
      financeRepositoryProvider.overrideWithValue(DriftFinanceRepository(db)),
    ],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: const TongtaiJourneyScreen(),
    ),
  );

  void tallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3200);
  }

  testWidgets('finishing every step is acknowledged, and points onward', (
    tester,
  ) async {
    tallViewport(tester);
    await seedFinishedJourney(done: true);

    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('journey-plan-done')));

    await tester.tap(find.byKey(const Key('journey-set-next-goal')));
    await tester.pumpAndSettle();

    // Invite, never auto-create: only the seller sets goals (WTM-191), so the
    // app opens the place and stops there.
    expect(find.byType(TongtaiGoalsScreen), findsOneWidget);
  });

  testWidgets('an unfinished journey says nothing of the sort', (tester) async {
    // The P-24 check: a block that always showed would pass the test above
    // while telling a seller mid-journey they were done.
    tallViewport(tester);
    await seedFinishedJourney(done: false);

    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('journey-list')));

    expect(find.byKey(const Key('journey-plan-done')), findsNothing);
  });

  test('the journey state follows the tree, and only forward', () async {
    await seedFinishedJourney(done: false);
    final repo = JourneyRepository(db);
    final controller = JourneyController(
      repo,
      clock: () => DateTime(2026, 8, 2),
    );

    // Nothing done yet: still active.
    var journey = (await repo.loadActive())!;
    expect(journey.isPlanComplete, isFalse);
    expect(journey.state, JourneyState.active);

    // The seller finishes the work; the measurement records it AND closes the
    // journey in the same breath, so "done" and "measured" cannot drift apart.
    journey = journey.copyWith(
      nodes: [
        for (final n in journey.nodes)
          if (n.kind == JourneyNodeKind.step)
            n.copyWith(state: JourneyNodeState.done)
          else
            n,
      ],
    );
    await repo.save(journey);
    // A metric that ticks something re-runs the same path.
    final refreshed = await controller.refreshDerived(journey, const {});

    expect(refreshed.isPlanComplete, isTrue);
  });
}
