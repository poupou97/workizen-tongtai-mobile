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
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';

import '../../support/pump_until.dart';

/// WTM-210 (D-11) — Home's mission block reads the JOURNEY.
///
/// The tiles used to render **goals** wearing a mission label, so Home and the
/// Journey screen described "today's work" from two different sources — the
/// same defect class as the SSoT chain (WTM-196/200/201/205). D-11 raises the
/// stakes: the Journey is the product's centre, and Home's mission block is
/// its front door.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tongtai_home_missions');
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

  Future<void> seedBusiness() async {
    await DriftBusinessGoalRepository(db).upsert(goal());
    // Customer BEFORE orders: `orders.customer_id` is a real foreign key
    // (the SqliteException 787 the restore work keeps meeting).
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
    await DriftProductRepository(db).upsertAll([
      for (var i = 0; i < 10; i++)
        Product(
          id: 'p$i',
          sku: 'SKU-$i',
          name: 'SP $i',
          category: 'Home',
          quantity: 5,
          pricePerUnit: 100000,
          reorderLevel: 2,
          updatedAt: DateTime(2026, 7, 1),
        ),
    ]);
    await DriftOrderRepository(db).upsertAll([
      for (var i = 0; i < 3; i++)
        CustomerOrder(
          id: 'o$i',
          customerId: 'c1',
          orderNumber: 'DH-$i',
          date: DateTime(2026, 7, 10 + i),
          status: OrderStatus.delivered,
          items: const [
            OrderItem(
              productName: 'SP 1',
              category: 'Home',
              quantity: 1,
              unitPrice: 100000,
            ),
          ],
        ),
    ]);
  }

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
      home: TongtaiHomeScreen(clock: () => DateTime(2026, 8, 1)),
    ),
  );

  void tallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3200);
  }

  testWidgets('with a journey, the tiles are journey nodes — not goals', (
    tester,
  ) async {
    tallViewport(tester);
    await seedBusiness();
    final journey =
        await JourneyController(
          JourneyRepository(db),
          clock: () => DateTime(2026, 8, 1),
        ).startJourney(
          JourneyPlanInput(
            goal: goal(),
            productCount: 10,
            customerCount: 1,
            orderCount: 3,
          ),
          journeyId: 'j1',
        );
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-open-journey')));

    final firstPending = journey!.nodes.firstWhere(
      (n) => !n.isDone && n.kind != JourneyNodeKind.milestone,
    );
    expect(
      find.byKey(Key('home-mission-${firstPending.id}')),
      findsOneWidget,
      reason: 'the mission block must show the journey, not goals in costume',
    );
    expect(find.byKey(const Key('home-start-journey')), findsNothing);
  });

  testWidgets('a goal but no journey invites starting one — right there', (
    tester,
  ) async {
    tallViewport(tester);
    await seedBusiness();
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-start-journey')));

    // The WTM-187 leftover closed: `startJourney` gets a production caller.
    await tester.tap(find.byKey(const Key('home-start-journey')));
    await tester.pumpAndSettle();

    final saved = await JourneyRepository(db).loadActive();
    expect(saved, isNotNull, reason: 'the tap must plan and store a journey');
    expect(saved!.nodes, isNotEmpty);
    // And the block now shows the freshly planned missions.
    expect(find.byKey(const Key('home-start-journey')), findsNothing);
  });

  testWidgets('no goal and no journey says what to do first', (tester) async {
    tallViewport(tester);
    // Nothing seeded: no goal to plan for.
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-open-journey')));

    expect(find.byKey(const Key('home-start-journey')), findsNothing);
    expect(
      find.textContaining('mục tiêu trước'),
      findsOneWidget,
      reason: 'an honest instruction beats goals dressed as missions',
    );
  });
}
