import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_more_action.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/tongtai_app_shell.dart';

/// P0 §3 (WTM-146) — navigation & action availability.
///
/// Every capability entry point must be reachable in EVERY data state: the 5
/// bottom-nav tabs always render and switch, the More menu always exposes its
/// full entry list, and create/seed actions never disappear (the §1 field bug
/// was exactly this class: entry points vanishing after onboarding-gating).
/// Production wiring: real shell, real providers over in-memory repositories.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    SharedPreferences.setMockInitialValues({});
  });

  SampleDataSeeder seeder() => SampleDataSeeder(
    customers: customerRepo,
    products: productRepo,
    orders: orderRepo,
    goals: goalRepo,
    finance: financeRepo,
  );

  Future<Widget> shell() async => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      customerRepositoryProvider.overrideWithValue(customerRepo),
      productRepositoryProvider.overrideWithValue(productRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
      businessGoalRepositoryProvider.overrideWithValue(goalRepo),
      financeRepositoryProvider.overrideWithValue(financeRepo),
      tongtaiSearchFavoritesStoreProvider.overrideWithValue(
        InMemorySupplierFavoritesStore(),
      ),
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

  Future<void> pumpShell(WidgetTester tester) async {
    // The shell mounts all 5 tabs (IndexedStack) — give async loads room.
    tester.view.physicalSize = const Size(400 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await shell());
    await tester.pumpAndSettle();
  }

  /// Selects a tab by **index**, not by its translated label (WTM-192).
  Future<void> tapNav(WidgetTester tester, int tab) async {
    await tester.tap(find.byKey(Key('nav-tab-$tab')));
    await tester.pumpAndSettle();
  }

  /// Opens More from whatever tab is showing. It left the bottom bar in
  /// WTM-192 and now lives in every screen's AppBar; this suite exists to prove
  /// that move cost the seller nothing.
  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(find.byKey(TongtaiMoreAction.actionKey));
    await tester.pumpAndSettle();
  }

  testWidgets('all 5 tabs render and switch on a FRESH empty business', (
    tester,
  ) async {
    await pumpShell(tester);

    // Every tab is present, found by key so the assertion survives
    // translation (WTM-192 — the labels are localized now).
    for (var tab = TongtaiTabs.home; tab <= TongtaiTabs.opportunity; tab++) {
      expect(
        find.byKey(Key('nav-tab-$tab')),
        findsOneWidget,
        reason: 'tab $tab',
      );
    }

    // Switching tabs actually swaps the visible screen.
    await tapNav(tester, TongtaiTabs.opportunity);
    expect(find.byType(TongtaiOpportunityFeedScreen), findsOneWidget);

    // …and More is still one tap away, from the AppBar.
    await openMore(tester);
    expect(find.byType(TongtaiMoreScreen), findsOneWidget);
    expect(find.byKey(const Key('more-demo-mode')), findsOneWidget);

    Navigator.of(tester.element(find.byType(TongtaiMoreScreen))).pop();
    await tester.pumpAndSettle();
    await tapNav(tester, TongtaiTabs.home);
    expect(find.byType(TongtaiHomeScreen), findsOneWidget);
  });

  testWidgets('every core capability is reachable from Home or the tab bar', (
    tester,
  ) async {
    // WTM-206 — the rule, not the one-screen patch. Finance was reachable only
    // through More: three taps into the toolbox for the "money management
    // hub", while the journey asked the seller to record expenses (WTM-198)
    // and Home showed their revenue on the KPI row. The Concept's core
    // capabilities live on the tab bar or one tap off Home; More is the full
    // directory, not the only door.
    await pumpShell(tester);

    // On the tab bar (WTM-192): Producer, Inventory, Consumer, Opportunity.
    for (var tab = TongtaiTabs.home; tab <= TongtaiTabs.opportunity; tab++) {
      expect(
        find.byKey(Key('nav-tab-$tab')),
        findsOneWidget,
        reason: 'tab $tab',
      );
    }

    // One tap off Home: Reports, Finance, Journey (WTM-187), Chat (AI).
    for (final key in const [
      'home-open-reports',
      'home-open-finance',
      'home-open-journey',
      'home-open-chat',
    ]) {
      expect(
        find.byKey(Key(key)),
        findsOneWidget,
        reason: '$key missing — that capability is buried in the More toolbox',
      );
    }
  });

  testWidgets('More menu exposes the full entry list in EVERY data state', (
    tester,
  ) async {
    Future<void> expectMoreEntries(WidgetTester tester) async {
      for (final key in const [
        'more-demo-mode',
        'more-load-history',
        'more-export',
        'more-reports',
        'more-timeline',
        'more-finance',
        'more-forecast',
        'more-customer-risk',
        'more-language',
      ]) {
        final finder = find.byKey(Key(key));
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find
              .descendant(
                of: find.byType(TongtaiMoreScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(finder, findsOneWidget, reason: 'More entry $key');
      }
    }

    // Empty business.
    await pumpShell(tester);
    await openMore(tester);
    await expectMoreEntries(tester);

    // Seeded business — same entries, plus remove-samples appears.
    await seeder().seed();
    await tester.pumpWidget(const SizedBox(key: Key('reset')));
    await tester.pumpWidget(await shell());
    await tester.pumpAndSettle();
    await openMore(tester);
    await expectMoreEntries(tester);
    final remove = find.byKey(const Key('more-remove-sample'));
    await tester.scrollUntilVisible(
      remove,
      200,
      scrollable: find
          .descendant(
            of: find.byType(TongtaiMoreScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(remove, findsOneWidget);
  });

  testWidgets('create paths never disappear: empty AND populated states', (
    tester,
  ) async {
    // Empty: Home shows the Get-started CTAs (seed/demo entry among them).
    await pumpShell(tester);
    expect(find.byKey(const Key('home-cta-demo')), findsOneWidget);

    // Populated: quick-create actions replace the CTAs — all four present.
    await seeder().seed();
    await tester.pumpWidget(const SizedBox(key: Key('reset2')));
    await tester.pumpWidget(await shell());
    await tester.pumpAndSettle();
    for (final key in const [
      'home-quick-customer',
      'home-quick-product',
      'home-quick-order',
      'home-quick-goal',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: 'quick action $key');
    }
  });
}
