import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart'
    show TongtaiFormatters;
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_commerce_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_business_inputs_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_finance_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goals_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_journey_screen.dart';

/// WTM-462 — **the five Home tiles read the same source the screen they open
/// reads** (One Data Path, ADR-TON-015 · "Summary Count == Domain Visible
/// Records").
///
/// WTM-461 patched ONE tile (`home-tile-producer`, which counted favourites
/// while its tap opened the Business-Inputs screen) and left the shape to audit
/// on the other four. This gate closes the debt PR #298 owed: it does the
/// **two-legged** check WTM-461 introduced — the number the tile shows AND the
/// records visible on the screen it navigates to — for **all five** tiles at
/// once, through production wiring.
///
/// The shape it defends against ([[P-50]]): a summary tile whose number comes
/// from a *different source* than the screen its tap opens. Two of the five were
/// divergent when this gate was written:
///   • `home-tile-journey` counted goals (`businessGoalRepository`) but opened
///     the Journey plan screen (`journeyRepository`) — a different domain. Now
///     it opens the Goals screen, which lists the goals it counts.
///   • `home-tile-finance` showed receivables derived from **orders**, but the
///     Finance screen's controller built `FinanceService` with no orders, so its
///     receivables were always 0 and the receivables block never rendered. The
///     controller now reads orders too.
///
/// No per-screen mocks: Home renders in its real (non-injected) mode and every
/// tile's number comes from the same Riverpod repositories the app ships.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A single in-memory Drift db backs the providers that still read one
  // (opportunity feed, capability contexts). The domain repos below are
  // in-memory doubles overridden onto their providers, so each tile's number
  // has exactly one owner.
  AppDatabase? sharedDb;
  AppDatabase memoryDb() =>
      sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());
  tearDown(() async {
    await sharedDb?.close();
    sharedDb = null;
  });

  late InMemoryCustomerRepository customerRepo;
  late InMemoryProductRepository productRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryBusinessGoalRepository goalRepo;
  late InMemoryFinanceRepository financeRepo;
  late InMemoryBusinessInputRepository inputRepo;
  late InMemorySupplierFavoritesStore favorites;

  setUp(() {
    customerRepo = InMemoryCustomerRepository();
    productRepo = InMemoryProductRepository([]);
    orderRepo = InMemoryOrderRepository();
    goalRepo = InMemoryBusinessGoalRepository();
    financeRepo = InMemoryFinanceRepository();
    inputRepo = InMemoryBusinessInputRepository();
    favorites = InMemorySupplierFavoritesStore();
  });

  Widget host() => ProviderScope(
    overrides: [
      tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
      customerRepositoryProvider.overrideWithValue(customerRepo),
      productRepositoryProvider.overrideWithValue(productRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
      businessGoalRepositoryProvider.overrideWithValue(goalRepo),
      financeRepositoryProvider.overrideWithValue(financeRepo),
      businessInputRepositoryProvider.overrideWithValue(inputRepo),
      tongtaiSearchFavoritesStoreProvider.overrideWithValue(favorites),
      // Keep the Finance screen off Drift for the settlement book — the
      // WTM-460 coexistence note is not what this gate measures.
      settlementRepositoryProvider.overrideWithValue(
        InMemorySettlementRepository(const []),
      ),
    ],
    // Real (non-injected) Home mode: no `metrics`, so `_read()` runs and every
    // tile — including Finance, which only renders when the summary loaded —
    // is on screen.
    child: const MaterialApp(home: TongtaiHomeScreen()),
  );

  /// Pumps and drains the async reads (Drift I/O completes off the test clock).
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// The single numeric Text rendered inside the keyed tile.
  int tileCount(WidgetTester tester, String tileKey) {
    final numeric = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(Key(tileKey)),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => int.tryParse(t) != null)
        .toList();
    expect(
      numeric,
      hasLength(1),
      reason: '$tileKey must render exactly one count, got $numeric',
    );
    return int.parse(numeric.single);
  }

  Future<void> tapTile(WidgetTester tester, String tileKey) async {
    final tile = find.byKey(Key(tileKey));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await settle(tester);
  }

  // ── Domain fixtures ──────────────────────────────────────────────────────
  Customer customer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '+8490000${id.hashCode.abs() % 10000}',
    location: 'Đà Nẵng',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
    email: '$id@example.com',
  );

  Product product(String id, String name) => Product(
    id: id,
    sku: 'SKU-$id',
    name: name,
    category: 'Test',
    quantity: 5,
    pricePerUnit: 120000,
    reorderLevel: 0,
    updatedAt: DateTime(2026, 1, 1),
  );

  BusinessGoal goal(String id, String name) => BusinessGoal(
    id: id,
    name: name,
    type: GoalType.revenue,
    targetAmount: 10000000,
    achievedAmount: 0,
    growthTarget: 0,
    growthAchieved: 0,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  BusinessInput input(String id, String name, BusinessInputKind kind) =>
      BusinessInput(
        id: id,
        name: name,
        kind: kind,
        cadence: InputCadence.monthly,
        expectedAmount: 100000,
      );

  /// An **unpaid** billable order — the only kind that becomes a receivable.
  /// Dated `now` so it lands in the current YTD window the Finance screen reads.
  CustomerOrder unpaidOrder(
    String id,
    String customerId,
    double amount,
    DateTime now,
  ) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: 'DH-$id',
    date: now,
    status: OrderStatus.delivered,
    paymentStatus: kPaymentUnpaid,
    items: [
      OrderItem(
        productName: 'SP',
        category: 'Test',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  testWidgets('all five Home tiles == the source their destination screen '
      'reads (Summary Count == Domain Visible Records)', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Orders must be "now" so the Finance screen's YTD window (real
    // DateTime.now on the pushed screen) contains them.
    final now = DateTime.now();

    // Consumer: two customers, one uniquely named so we can reveal it.
    await customerRepo.upsertAll([
      customer('cust-1', 'GateCustomerAlpha'),
      customer('cust-2', 'Khách nền'),
    ]);
    // Inventory: two products.
    await productRepo.upsertAll([
      product('prod-1', 'GateProductAlpha'),
      product('prod-2', 'Sản phẩm nền'),
    ]);
    // Journey tile counts GOALS: two of them.
    await goalRepo.upsertAll([
      goal('goal-1', 'GateGoalAlpha'),
      goal('goal-2', 'Mục tiêu nền'),
    ]);
    // Producer: three business inputs...
    await inputRepo.upsertAll([
      input('in-1', 'Máy chủ VPS', BusinessInputKind.infrastructure),
      input('in-2', 'Workizen AI', BusinessInputKind.provider),
      input('in-3', 'Xưởng may', BusinessInputKind.supplier),
    ]);
    // ...with a DIFFERENT number of favourites as the WTM-461 decoy: if the
    // producer tile ever regressed to the favourites store it would read 5.
    for (final f in ['fav-a', 'fav-b', 'fav-c', 'fav-d', 'fav-e']) {
      await favorites.add(f);
    }
    // Finance: two unpaid orders for two different customers ⇒ receivables
    // 5,000,000 across 2 debtors. No finance transactions at all — so if the
    // Finance screen still ignored orders, its income would be 0, it would show
    // the empty state, and the receivables block would never render.
    await orderRepo.upsertAll([
      unpaidOrder('o1', 'cust-1', 4000000, now),
      unpaidOrder('o2', 'cust-2', 1000000, now),
    ]);
    const expectedReceivables = 5000000.0;

    await tester.pumpWidget(host());
    await settle(tester);

    // ── The number leg — every tile equals the repo the TILE reads ─────────
    expect(
      tileCount(tester, 'home-tile-producer'),
      (await inputRepo.loadAll()).length,
      reason: 'producer tile == business inputs (NOT the 5 favourites)',
    );
    expect(tileCount(tester, 'home-tile-producer'), 3);
    expect(
      tileCount(tester, 'home-tile-inventory'),
      (await productRepo.loadAll()).length,
      reason: 'inventory tile == product repository',
    );
    expect(
      tileCount(tester, 'home-tile-consumer'),
      (await customerRepo.loadAll()).length,
      reason: 'consumer tile == customer repository',
    );
    expect(
      tileCount(tester, 'home-tile-journey'),
      (await goalRepo.loadAll()).length,
      reason: 'journey tile == goal repository',
    );
    // Finance tile is money, not a count: it shows the receivables it derives
    // from orders.
    expect(
      find.descendant(
        of: find.byKey(const Key('home-tile-finance')),
        matching: find.text(TongtaiFormatters.vndShort(expectedReceivables)),
      ),
      findsOneWidget,
      reason: 'finance tile shows receivables derived from orders',
    );

    // ── The visible-records leg — the screen each tile OPENS shows exactly
    //    the records/figure the tile counted ───────────────────────────────

    // Producer → Business Inputs screen shows all three inputs it counted.
    await tapTile(tester, 'home-tile-producer');
    expect(find.byType(TongtaiBusinessInputsScreen), findsOneWidget);
    final inputRows = tester.allWidgets
        .map((w) => w.key)
        .whereType<ValueKey<String>>()
        .where(
          (k) =>
              k.value.startsWith('inputs-item-') &&
              !k.value.endsWith('-monthly') &&
              !k.value.endsWith('-delete'),
        )
        .toSet()
        .length;
    expect(inputRows, 3, reason: 'destination lists the 3 inputs counted');
    await tester.pageBack();
    await settle(tester);

    // Inventory → Inventory screen; the counted product is reachable.
    await tapTile(tester, 'home-tile-inventory');
    expect(find.byType(TongtaiInventoryScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('inventory-search-field')),
      'GateProductAlpha',
    );
    await tester.pumpAndSettle();
    expect(find.text('GateProductAlpha'), findsWidgets);
    await tester.pageBack();
    await settle(tester);

    // Consumer → Customer list; the counted customer is reachable.
    await tapTile(tester, 'home-tile-consumer');
    expect(find.byType(TongtaiCustomerListScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('customer-search-field')),
      'GateCustomerAlpha',
    );
    await tester.pumpAndSettle();
    expect(find.text('GateCustomerAlpha'), findsWidgets);
    await tester.pageBack();
    await settle(tester);

    // Journey → **Goals** screen (WTM-462 redirect), which lists the goals the
    // tile counted — NOT the Journey plan screen (a different source).
    await tapTile(tester, 'home-tile-journey');
    expect(
      find.byType(TongtaiGoalsScreen),
      findsOneWidget,
      reason: 'the goals tile must open the screen that lists goals',
    );
    expect(
      find.byType(TongtaiJourneyScreen),
      findsNothing,
      reason: 'the goals count must NOT land on the Journey plan (journeyRepo)',
    );
    expect(find.text('GateGoalAlpha'), findsWidgets);
    await tester.pageBack();
    await settle(tester);

    // Finance → Finance screen shows the receivables block with the SAME
    // figure the tile derived. If orders were not wired into the controller,
    // this block would be absent (receivables 0 ⇒ empty state).
    await tapTile(tester, 'home-tile-finance');
    expect(find.byType(TongtaiFinanceScreen), findsOneWidget);
    final receivablesBlock = find.byKey(const Key('finance-receivables'));
    await tester.scrollUntilVisible(
      receivablesBlock,
      200,
      scrollable: find
          .descendant(
            of: find.byType(TongtaiFinanceScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      receivablesBlock,
      findsOneWidget,
      reason: 'finance screen must show the receivables the tile derived',
    );
    expect(
      find.descendant(
        of: receivablesBlock,
        matching: find.textContaining(
          TongtaiFormatters.vnd(expectedReceivables),
        ),
      ),
      findsOneWidget,
      reason: 'the receivables amount must match what the tile showed',
    );
  });

  testWidgets('finance tile & screen stay one source with orders but zero '
      'transactions — the sharp regression WTM-462 fixes', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    await customerRepo.upsert(customer('cust-1', 'GateCustomerAlpha'));
    // Only an unpaid order — no FinanceTransaction anywhere. The pre-WTM-462
    // Finance screen built FinanceService(_txns) with no orders, so income was
    // 0, the screen showed its empty state, and receivables never appeared —
    // while Home's tile showed the receivable. That contradiction is the bug.
    await orderRepo.upsert(unpaidOrder('o1', 'cust-1', 2500000, now));

    await tester.pumpWidget(host());
    await settle(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('home-tile-finance')),
        matching: find.text(TongtaiFormatters.vndShort(2500000)),
      ),
      findsOneWidget,
    );

    await tapTile(tester, 'home-tile-finance');
    expect(find.byType(TongtaiFinanceScreen), findsOneWidget);
    // The screen is NOT in its empty state, and the receivables block is shown.
    expect(find.byKey(const Key('finance-receivables')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('finance-receivables')),
        matching: find.textContaining(TongtaiFormatters.vnd(2500000)),
      ),
      findsOneWidget,
    );
  });
}
