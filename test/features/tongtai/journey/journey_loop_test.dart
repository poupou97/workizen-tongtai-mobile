import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_metric.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_finance_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_journey_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-220 — the journey's loop closes: **đi tới được · hoàn thành được luồng ·
/// quay lại Journey** (luật Founder 2026-08-02).
///
/// Before this, Business Journey — the product's centre (D-11) — managed only
/// the first third. The journey screen had no `onTap`, no `Navigator`, no
/// button: it named the work and abandoned the seller. And `refreshDerived`,
/// the engine that ticks a measured step, had **no production caller at all**,
/// so even a seller who found their own way to Finance and recorded five
/// expenses came back to a journey that still said "Ghi 5 khoản chi đầu tiên".
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tongtai_journey_loop');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  BusinessGoal goal() => BusinessGoal(
    id: 'g1',
    name: 'Doanh thu 50 triệu',
    type: GoalType.revenue,
    targetAmount: 50000000,
    achievedAmount: 0,
    growthTarget: 20,
    growthAchieved: 0,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  /// A business with a goal, one customer and no expenses — so the planner
  /// produces the "Ghi 5 khoản chi đầu tiên" step this test drives.
  Future<void> seed() async {
    await DriftBusinessGoalRepository(db).upsert(goal());
    await DriftCustomerRepository(db).upsert(
      const Customer(
        id: 'c1',
        name: 'Khách 1',
        phone: '0900000000',
        location: 'HCM',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
      ),
    );
    await JourneyController(
      JourneyRepository(db),
      clock: () => DateTime(2026, 8, 1),
    ).startJourney(
      JourneyPlanInput(
        goal: goal(),
        productCount: 10,
        customerCount: 1,
        orderCount: 3,
        expenseCount: 0,
      ),
      journeyId: 'j1',
    );
  }

  Future<Widget> host(Widget home) async => ProviderScope(
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
      home: home,
    ),
  );

  void tallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3200);
  }

  /// The open, measured step for expenses — the one the seller is asked to do.
  Future<JourneyNode> expenseStep() async {
    final journey = await JourneyRepository(db).loadActive();
    return journey!.nodes.firstWhere(
      (n) => n.derivedMetric == JourneyMetric.expenses.code,
    );
  }

  testWidgets('a step opens the capability where its work happens', (
    tester,
  ) async {
    tallViewport(tester);
    await seed();
    final step = await expenseStep();

    await tester.pumpWidget(await host(const TongtaiJourneyScreen()));
    await pumpUntilFound(tester, find.byKey(Key('journey-step-do-${step.id}')));

    await tester.tap(find.byKey(Key('journey-step-do-${step.id}')));
    await tester.pumpAndSettle();

    // "Ghi 5 khoản chi" lands on Finance, where expenses are actually recorded
    // — not on a Reports dashboard that only shows money already spent.
    expect(find.byType(TongtaiFinanceScreen), findsOneWidget);
  });

  testWidgets(
    'doing the work and coming back ticks the step — the loop closes',
    (tester) async {
      tallViewport(tester);
      await seed();
      final step = await expenseStep();
      expect(step.isDone, isFalse);

      await tester.pumpWidget(await host(const TongtaiJourneyScreen()));
      await pumpUntilFound(
        tester,
        find.byKey(Key('journey-step-do-${step.id}')),
      );
      await tester.tap(find.byKey(Key('journey-step-do-${step.id}')));
      await tester.pumpAndSettle();

      // The seller records the five expenses the journey asked for. Writing
      // them through the repository is the same path the Finance form takes.
      await tester.runAsync(() async {
        await DriftFinanceRepository(db).addAll([
          for (var i = 0; i < 5; i++)
            FinanceTransaction(
              id: 'tx$i',
              type: TransactionType.expense,
              category: FinanceCategory.other,
              amount: 100000,
              date: DateTime(2026, 8, 1),
            ),
        ]);
      });

      // …and goes back to the journey.
      Navigator.of(tester.element(find.byType(TongtaiFinanceScreen))).pop();
      await tester.pumpAndSettle();

      final after = await expenseStep();
      expect(
        after.isDone,
        isTrue,
        reason:
            'the journey must notice work the seller did — refreshDerived had '
            'no production caller before WTM-220',
      );
      // And the button is gone, because there is nothing left to do here.
      expect(find.byKey(Key('journey-step-do-${step.id}')), findsNothing);
    },
  );

  testWidgets('a step with nowhere honest to go offers no button', (
    tester,
  ) async {
    // The P-24 check: if every step grew a button regardless, the two tests
    // above would pass while the seller got sent somewhere arbitrary.
    tallViewport(tester);
    await seed();
    final journey = await JourneyRepository(db).loadActive();
    final milestones = journey!.nodes.where(
      (n) => n.kind == JourneyNodeKind.milestone,
    );

    await tester.pumpWidget(await host(const TongtaiJourneyScreen()));
    await pumpUntilFound(tester, find.byKey(const Key('journey-list')));

    for (final m in milestones) {
      expect(
        find.byKey(Key('journey-step-do-${m.id}')),
        findsNothing,
        reason: 'a milestone is not a piece of work — it has no door',
      );
    }
  });

  group('the destination rule (one owner, pure)', () {
    JourneyNode node({String? metric, String? fromOpportunity}) => JourneyNode(
      id: 'n1',
      journeyId: 'j1',
      parentId: 'root',
      kind: JourneyNodeKind.step,
      title: 'b',
      origin: JourneyNodeOrigin.ruleTwin,
      orderIndex: 0,
      completion: metric == null
          ? JourneyCompletion.manual
          : JourneyCompletion.derived,
      derivedMetric: metric,
      derivedTarget: metric == null ? null : 5,
      sourceOpportunityId: fromOpportunity,
    );

    test('each metric sends the seller where that work is done', () {
      expect(
        journeyNodeDestination(node(metric: JourneyMetric.expenses.code)),
        JourneyDestination.finance,
      );
      expect(
        journeyNodeDestination(node(metric: JourneyMetric.customers.code)),
        JourneyDestination.customers,
      );
      expect(
        journeyNodeDestination(node(metric: JourneyMetric.products.code)),
        JourneyDestination.inventory,
      );
      expect(
        journeyNodeDestination(node(metric: JourneyMetric.revenue.code)),
        JourneyDestination.customers,
      );
    });

    test('a step from an opportunity goes back to the opportunity', () {
      expect(
        journeyNodeDestination(
          node(metric: JourneyMetric.expenses.code, fromOpportunity: 'opp-1'),
        ),
        JourneyDestination.opportunity,
        reason: 'provenance wins: the seller asks "what was this again?"',
      );
    });

    test('an unknown metric is not guessed at', () {
      // A `.ttbk` from a newer build may name a metric this one never heard
      // of. Guessing would send the seller off to do the wrong work
      // (ADR-TON-018 applied to a step instead of a row).
      expect(journeyNodeDestination(node(metric: 'chi-phi-quang-cao')), isNull);
      expect(journeyNodeDestination(node()), isNull);
    });
  });

  group('the metrics snapshot has one owner', () {
    test('receivables are deliberately absent — they complete by falling', () {
      final metrics = journeyMetrics(
        productCount: 3,
        customerCount: 2,
        expenseCount: 5,
        revenue: 1000,
      );

      expect(metrics[JourneyMetric.expenses.code], 5);
      expect(metrics[JourneyMetric.revenue.code], 1000);
      expect(
        metrics.containsKey(JourneyMetric.receivables.code),
        isFalse,
        reason:
            'refreshDerived only moves forward; feeding receivables in would '
            'mark "thu nợ" done the moment the debt GREW',
      );
    });
  });
}
