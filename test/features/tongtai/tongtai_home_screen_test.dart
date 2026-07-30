import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';

/// WTM-128 + WTM-144 (P0 §1) — Home is User Data First over ONE source: the
/// production repositories. "Sample data" is ordinary rows seeded into those
/// repositories (ADR-TON-014); there is no parallel demo state. These tests
/// run through the real Riverpod wiring — the screen and the assertions read
/// the same container.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  /// One production-like set of in-memory repositories per test.
  late InMemoryCustomerRepository customerRepo;
  late InMemoryProductRepository productRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryBusinessGoalRepository goalRepo;
  late InMemoryFinanceRepository financeRepo;

  setUp(() {
    customerRepo = InMemoryCustomerRepository();
    productRepo = InMemoryProductRepository([]);
    orderRepo = InMemoryOrderRepository();
    goalRepo = InMemoryBusinessGoalRepository();
    financeRepo = InMemoryFinanceRepository();
  });

  SampleDataSeeder seeder() => SampleDataSeeder(
    customers: customerRepo,
    products: productRepo,
    orders: orderRepo,
    goals: goalRepo,
    finance: financeRepo,
  );

  Widget wrap(Widget home) => ProviderScope(
    overrides: [
      customerRepositoryProvider.overrideWithValue(customerRepo),
      productRepositoryProvider.overrideWithValue(productRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
      businessGoalRepositoryProvider.overrideWithValue(goalRepo),
      financeRepositoryProvider.overrideWithValue(financeRepo),
      tongtaiSearchFavoritesStoreProvider.overrideWithValue(
        InMemorySupplierFavoritesStore(),
      ),
    ],
    child: MaterialApp(home: home),
  );

  /// The REAL Home (no injected metrics — it loads from the repositories).
  Widget realHost() => wrap(TongtaiHomeScreen(clock: fixedNow));

  group('seeded sample data — production wiring (WTM-144/ADR-TON-014)', () {
    testWidgets('module tiles show the seeded counts from the repositories', (
      tester,
    ) async {
      await seeder().seed();
      await tester.pumpWidget(realHost());
      await tester.pumpAndSettle();

      expect(find.text('26'), findsOneWidget); // customers (seeded)
      expect(find.text('28'), findsOneWidget); // products (seeded)
      // Journey tile: 2 seeded goals.
      expect(find.text('2'), findsWidgets);
      // Producer counts persisted favourites — none seeded → 0 real.
      expect(find.text('Producer'), findsOneWidget);
    });

    testWidgets('KPIs + Healthy badge come from the seeded repositories', (
      tester,
    ) async {
      await seeder().seed();
      await tester.pumpWidget(realHost());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-kpi-revenue')), findsOneWidget);
      expect(find.text('4,06tr ₫'), findsOneWidget); // 4.058.000 billable
      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-orders')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('home-health-badge')),
          matching: find.text('Healthy'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the sample banner shows while samples exist — and only then', (
      tester,
    ) async {
      await seeder().seed();
      await tester.pumpWidget(realHost());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-sample-banner')), findsOneWidget);

      // Remove the samples → a fresh Home shows no banner.
      await seeder().removeAll();
      await tester.pumpWidget(
        wrap(TongtaiHomeScreen(key: const Key('fresh'), clock: fixedNow)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-sample-banner')), findsNothing);
    });

    testWidgets('quick actions show with data; Get-started without', (
      tester,
    ) async {
      await seeder().seed();
      await tester.pumpWidget(realHost());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-quick-customer')), findsOneWidget);
      expect(find.byKey(const Key('home-cta-customer')), findsNothing);

      await seeder().removeAll();
      await tester.pumpWidget(
        wrap(TongtaiHomeScreen(key: const Key('fresh2'), clock: fixedNow)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-cta-customer')), findsOneWidget);
      expect(find.byKey(const Key('home-quick-customer')), findsNothing);
    });
  });

  group('new business (User Data First, real wiring)', () {
    testWidgets('KPIs show real zeros (never "No Data") + CTAs', (
      tester,
    ) async {
      await tester.pumpWidget(realHost());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-orders')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.text('No Data'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('home-health-badge')),
          matching: find.text('Not enough data'),
        ),
        findsOneWidget,
      );
      expect(find.text('Create your first customer'), findsOneWidget);
      expect(find.text('Add your first product'), findsOneWidget);
      expect(find.text('Create your first order'), findsOneWidget);
      expect(find.text('Set your first business goal'), findsOneWidget);
      expect(find.text('Explore Demo Mode'), findsOneWidget);
    });

    testWidgets(
      '"Explore Demo Mode" seeds the PRODUCTION repositories in place — no '
      'parallel demo screen (WTM-144 regression: fails on the old code)',
      (tester) async {
        await tester.pumpWidget(realHost());
        await tester.pumpAndSettle();

        final demo = find.byKey(const Key('home-cta-demo'));
        await tester.ensureVisible(demo);
        await tester.pumpAndSettle();
        await tester.tap(demo);
        await tester.pumpAndSettle();

        // SAME screen (no push), now showing the seeded data + banner…
        expect(find.text('26'), findsOneWidget);
        expect(find.byKey(const Key('home-sample-banner')), findsOneWidget);
        // …and the repositories REALLY contain the sample rows (one source).
        final customers = await customerRepo.loadAll();
        expect(
          customers.where((c) => c.id.startsWith(kSampleIdPrefix)).length,
          26,
        );
      },
    );
  });

  group('More → sample lifecycle (production wiring)', () {
    testWidgets(
      'Load sample data seeds; Remove deletes ONLY sample rows — user data '
      'survives',
      (tester) async {
        // A user-created customer (UUID-style id) that must survive removal.
        await customerRepo.upsert(
          const Customer(
            id: 'f47ac10b-user',
            name: 'Khách Của Tôi',
            phone: '0900000000',
            location: 'HCM',
            orderCount: 0,
            totalSpent: 0,
            lastPurchaseDate: null,
          ),
        );

        await tester.pumpWidget(wrap(const TongtaiMoreScreen()));
        await tester.pumpAndSettle();

        // Seed via the More entry (confirm dialog).
        final seedEntry = find.byKey(const Key('more-demo-mode'));
        await tester.scrollUntilVisible(
          seedEntry,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(seedEntry);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('more-demo-confirm')));
        await tester.pumpAndSettle();
        expect((await customerRepo.loadAll()).length, 27); // 26 sample + 1 user

        // Remove via the More entry (confirm dialog).
        final removeEntry = find.byKey(const Key('more-remove-sample'));
        await tester.tap(removeEntry);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('more-remove-sample-confirm')));
        await tester.pumpAndSettle();

        final remaining = await customerRepo.loadAll();
        expect(remaining.single.name, 'Khách Của Tôi'); // user data intact
        expect(await productRepo.loadAll(), isEmpty);
        expect(await orderRepo.loadAll(), isEmpty);
        expect(await goalRepo.loadAll(), isEmpty);
        expect(await financeRepo.loadAll(), isEmpty);
      },
    );
  });

  testWidgets('empty goals fall back to the no-missions box', (tester) async {
    await tester.pumpWidget(
      wrap(
        TongtaiHomeScreen(
          // A business with sales but no goals (so CTAs stay hidden).
          metrics: BusinessMetrics.from(orders: const [], customersCount: 5),
          customerCount: 5,
          inventoryCount: 3,
          goals: const [],
          clock: fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Missions"), findsOneWidget);
    expect(find.text('No missions yet'), findsOneWidget);
  });

  testWidgets('the KPI header opens the full Reports dashboard', (
    tester,
  ) async {
    await seeder().seed();
    await tester.pumpWidget(realHost());
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('home-open-reports'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiReportsScreen), findsOneWidget);
  });
}
