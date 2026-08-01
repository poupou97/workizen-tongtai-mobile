import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
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
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_producer_screen.dart';
import 'package:tongtai/features/tongtai/ui/tongtai_app_shell.dart';

import '../../../support/count_list_contract.dart';

/// P0 Founder Correction 2026-07-30 — **Summary Count == Domain Visible
/// Records** contract (WTM-144/WTM-146).
///
/// Field repro on the Founder's device: Home said Consumer = 1 while the
/// bottom-nav Consumer tab showed nothing — the tab was a static design shell
/// that read NO data. This suite locks the contract for EVERY count/list pair
/// through PRODUCTION wiring on a REAL SQLite file:
///
///   Home tile count == domain screen count == repository records,
///   for sample AND user-created rows, before AND after an app restart.
///
/// No per-screen mocks: every screen reads the same Riverpod providers the
/// app ships, backed by Drift repositories over one .db file.
void main() {
  // One in-memory database per test — shared rather than rebuilt, because
  // constructing `AppDatabase` twice over one executor is the race drift warns
  // about (WTM-192).
  AppDatabase? sharedDb;
  AppDatabase memoryDb() =>
      sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());
  tearDown(() async {
    await sharedDb?.close();
    sharedDb = null;
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  AppDatabase? db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-contract-');
    dbFile = File('${tempDir.path}/tongtai.db');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await db?.close();
    db = null;
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  const userCustomerId = '7c9e6679-7425-40de-963d-e35b1566ac1f';
  const userCustomerName = 'Khách Thật Contract';

  /// One "app session": a fresh AppDatabase over the SAME file, wired through
  /// the SAME providers production uses.
  Future<
    ({
      Widget app,
      DriftCustomerRepository customers,
      DriftProductRepository products,
      DriftOrderRepository orders,
      DriftBusinessGoalRepository goals,
      DriftFinanceRepository finance,
      SupplierFavoritesStore favorites,
      SampleDataSeeder seeder,
    })
  >
  session() async {
    await db?.close();
    final database = AppDatabase.forExecutor(NativeDatabase(dbFile));
    db = database;
    final customers = DriftCustomerRepository(database);
    final products = DriftProductRepository(database);
    final orders = DriftOrderRepository(database);
    final goals = DriftBusinessGoalRepository(database);
    final finance = DriftFinanceRepository(database);
    final favorites = DriftSupplierFavoritesStore(database);
    final app = ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        customerRepositoryProvider.overrideWithValue(customers),
        productRepositoryProvider.overrideWithValue(products),
        orderRepositoryProvider.overrideWithValue(orders),
        businessGoalRepositoryProvider.overrideWithValue(goals),
        financeRepositoryProvider.overrideWithValue(finance),
        tongtaiSearchFavoritesStoreProvider.overrideWithValue(favorites),
        // WTM-192: the Opportunity tab is part of the shell now, and it reads
        // stored reactions — without a database the harness dies on
        // `path_provider`, which is the harness failing, not the screen.
        tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('vi')],
        home: TongtaiAppShell(),
      ),
    );
    return (
      app: app,
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      finance: finance,
      favorites: favorites,
      seeder: SampleDataSeeder(
        customers: customers,
        products: products,
        orders: orders,
        goals: goals,
        finance: finance,
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(400 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    // Real SQLite I/O completes off the test clock — give it wall time,
    // then settle the resulting setState frames.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  /// The count rendered inside a Home module tile (title Text + count Text).
  int tileCount(WidgetTester tester, String tileKey) {
    expect(
      find.byKey(Key(tileKey)),
      findsOneWidget,
      reason: 'tile $tileKey must be on screen',
    );
    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(Key(tileKey)),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .whereType<String>();
    final numeric = texts.where((t) => int.tryParse(t) != null).toList();
    expect(
      numeric,
      hasLength(1),
      reason: '$tileKey must render exactly one count, got $texts',
    );
    return int.parse(numeric.single);
  }

  /// Selects a tab by **index**, not by its translated label (WTM-192).
  Future<void> tapNav(WidgetTester tester, int tab) async {
    await tester.tap(find.byKey(Key('nav-tab-$tab')));
    await tester.pumpAndSettle();
  }

  testWidgets('FOUNDER REPRO + full pair audit: counts == visible records, '
      'sample + user rows, across a real restart', (tester) async {
    // ── Session 1: seed samples + the user-created record class ─────────
    final s1 = await session();
    await s1.seeder.seed();
    await s1.customers.upsert(
      Customer(
        id: userCustomerId,
        name: userCustomerName,
        phone: '+84900000009',
        location: 'Đà Nẵng',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
        email: 'contract@example.com',
      ),
    );
    await s1.favorites.add('s1');

    final expectedCustomers = (await s1.customers.loadAll()).length;
    final expectedProducts = (await s1.products.loadAll()).length;
    final expectedGoals = (await s1.goals.loadAll()).length;
    // KPI counts BILLABLE orders (cancelled excluded — the legitimate
    // ADR-TON-011 filter shared by Reports/Home; the orders list still
    // shows cancelled rows WITH their status chip).
    final expectedOrders = (await s1.orders.loadAll())
        .where((o) => o.status != OrderStatus.cancelled)
        .length;
    expect(expectedCustomers, greaterThan(1)); // samples + user row

    Future<void> verifyAllPairs(
      WidgetTester tester, {
      required Widget app,
    }) async {
      await pumpApp(tester, app);
      await tapNav(tester, TongtaiTabs.home);

      // Home tile counts against the repositories (single source).
      expect(tileCount(tester, 'home-tile-consumer'), expectedCustomers);
      expect(tileCount(tester, 'home-tile-inventory'), expectedProducts);
      expect(tileCount(tester, 'home-tile-journey'), expectedGoals);
      expect(tileCount(tester, 'home-tile-producer'), 1); // 1 favourite
      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-orders')),
          matching: find.text('$expectedOrders'),
        ),
        findsOneWidget,
      );

      // ── Consumer pair (the Founder repro) ─────────────────────────────
      await tapNav(tester, TongtaiTabs.consumer);
      final badge = tester.widget<Text>(
        find.byKey(const Key('consumer-count-badge')),
      );
      expect(
        badge.data,
        '$expectedCustomers',
        reason:
            'Consumer tab badge must equal the Home Consumer tile — '
            'both read customerRepository',
      );

      // The records Home counted are VISIBLE in the domain list:
      // user-created AND sample rows, found through the real list screen.
      await tester.tap(find.byKey(const Key('consumer-view-all')));
      await tester.pumpAndSettle();
      expect(find.byType(TongtaiCustomerListScreen), findsOneWidget);
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, userCustomerName);
      await tester.pumpAndSettle();
      expect(
        find.text(userCustomerName),
        findsWidgets,
        reason: 'user-created customer must be visible in the list',
      );
      await tester.enterText(searchField, 'Phương Nguyễn');
      await tester.pumpAndSettle();
      expect(
        find.text('Phương Nguyễn'),
        findsWidgets,
        reason: 'seeded sample customer must be visible in the list',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      // ── Producer pair ─────────────────────────────────────────────────
      await tapNav(tester, TongtaiTabs.producer);
      final favCount = tester.widget<Text>(
        find.byKey(const Key('producer-fav-count')),
      );
      expect(
        favCount.data,
        '1',
        reason: 'Producer tab must show the same favourites Home counts',
      );
      expect(find.text('TechPro Wholesale'), findsOneWidget);

      // The summary line carries the SAME generated-opportunity count the
      // feed/Home read (rule engine over these repositories).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TongtaiProducerScreen)),
      );
      final generated = await container.read(
        generatedOpportunitiesProvider.future,
      );
      final summary = tester.widget<Text>(
        find.byKey(const Key('producer-summary-line')),
      );
      expect(summary.data, contains('${generated.length} '));

      // ── Inventory pair: sample product findable in the domain list ────
      await tapNav(tester, TongtaiTabs.inventory);
      final invSearch = find
          .descendant(
            of: find.byType(TongtaiInventoryScreen),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(invSearch, 'Quạt mini');
      await tester.pumpAndSettle();
      // WTM-215 put overview + low-stock chrome above the list; at this 800px
      // viewport the row starts below the fold, so reach it the way a user
      // does — by scrolling the inventory scroll view.
      await tester.scrollUntilVisible(
        find.text('Quạt mini cầm tay'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(TongtaiInventoryScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Quạt mini cầm tay'), findsWidgets);
      await tester.enterText(invSearch, '');
      await tester.pumpAndSettle();
    }

    await verifyAllPairs(tester, app: s1.app);

    // ── Session 2: RESTART (new database + container over the same file);
    // every pair must still agree. ────────────────────────────────────────
    await tester.pumpWidget(const SizedBox(key: Key('teardown')));
    await tester.pumpAndSettle();
    final s2 = await session();
    await verifyAllPairs(tester, app: s2.app);
  });

  testWidgets(
    'consumer tab derives EVERYTHING from the repository (no static zeros)',
    (tester) async {
      final s = await session();
      // WTM-201: the counters are **derived from orders** now, so a fixture
      // that hand-sets `orderCount: 3` is setting a static value — exactly what
      // this test's own name forbids. Seed real orders instead.
      await s.customers.upsert(
        Customer(
          id: userCustomerId,
          name: userCustomerName,
          phone: '+84900000009',
          location: 'Đà Nẵng',
          orderCount: 0,
          totalSpent: 0,
          lastPurchaseDate: null,
          email: 'contract@example.com',
          segments: const ['bán sỉ'],
        ),
      );
      await s.orders.upsertAll([
        for (var i = 0; i < 3; i++)
          CustomerOrder(
            id: 'contract-o$i',
            customerId: userCustomerId,
            orderNumber: 'DH-contract-$i',
            date: DateTime(2026, 7, 20).subtract(Duration(days: i * 5)),
            status: OrderStatus.delivered,
            items: [
              const OrderItem(
                productName: 'SP',
                category: 'Home',
                quantity: 1,
                unitPrice: 500000,
              ),
            ],
          ),
      ]);
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            customerRepositoryProvider.overrideWithValue(s.customers),
            orderRepositoryProvider.overrideWithValue(s.orders),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('vi')],
            home: TongtaiConsumerScreen(clock: () => DateTime(2026, 7, 30)),
          ),
        ),
      );

      final badge = tester.widget<Text>(
        find.byKey(const Key('consumer-count-badge')),
      );
      expect(badge.data, '1');
      // Repeat purchaser with a recent order: active, retained, segmented.
      expect(find.text('bán sỉ (1)'), findsOneWidget);
      expect(find.text(userCustomerName), findsOneWidget); // recent interaction
    },
  );

  testWidgets('REUSABLE contract: registered domains inherit '
      'Summary Count == Visible Records', (tester) async {
    // Demonstrates the inheritance path a NEW domain uses: describe the
    // domain once with CountListContract, the shared verifier does the rest
    // (test/support/count_list_contract.dart, ADR-TON-015 §2).
    final s = await session();
    await s.seeder.seed();
    await s.customers.upsert(
      Customer(
        id: userCustomerId,
        name: userCustomerName,
        phone: '+84900000009',
        location: 'Đà Nẵng',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
        email: 'contract@example.com',
      ),
    );
    await pumpApp(tester, s.app);
    await tapNav(tester, TongtaiTabs.home);

    final contracts = <CountListContract>[
      CountListContract(
        domain: 'consumer',
        summaryKey: const Key('home-tile-consumer'),
        repositoryCount: () async => (await s.customers.loadAll()).length,
        openDomain: (t) async {
          await tapNav(t, TongtaiTabs.consumer);
          await t.tap(find.byKey(const Key('consumer-view-all')));
          await t.pumpAndSettle();
        },
        itemKeyPrefix: 'customer-item-',
        mustBeVisible: [
          // Paginated list: a real user searches for the record — the
          // contract asserts REACHABLE, not "happens to be on page 1".
          ContractRecord(
            'customer-item-$userCustomerId',
            reveal: (t) async {
              await t.enterText(
                find.byKey(const Key('customer-search-field')),
                userCustomerName,
              );
              await t.pumpAndSettle();
            },
          ),
        ],
      ),
      CountListContract(
        domain: 'inventory',
        summaryKey: const Key('home-tile-inventory'),
        repositoryCount: () async => (await s.products.loadAll()).length,
        openSummary: (t) async {
          await t.pageBack();
          await t.pumpAndSettle();
          await tapNav(t, TongtaiTabs.home);
        },
        openDomain: (t) async => tapNav(t, TongtaiTabs.inventory),
        itemKeyPrefix: 'inventory-item-',
      ),
    ];

    for (final contract in contracts) {
      await verifyCountListContract(tester, contract);
    }
  });
}
