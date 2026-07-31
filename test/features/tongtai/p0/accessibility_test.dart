import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
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
import 'package:tongtai/features/tongtai/ui/screens/tongtai_backup_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_export_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_finance_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_forecast_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_producer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_timeline_screen.dart';

/// WTM-167 — accessibility, measured by Flutter's own guidelines rather than
/// by opinion.
///
/// Three of these are shipped matchers, so the bar is Android's, not ours:
///
/// - **tap target** — every tappable is at least 48×48 dp. A seller counting
///   stock with one hand does not get to try again on a 24 dp icon.
/// - **labeled tap target** — every tappable has a name a screen reader can
///   speak. An unlabelled button is announced as nothing at all.
/// - **text contrast** — text stays legible against its background.
///
/// Run in **both shipped locales**: Vietnamese is longer than English almost
/// everywhere, so a control that only just fits in `en` is the one that breaks.
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

  Future<Widget> host(Widget screen, String locale) async => ProviderScope(
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
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: screen,
    ),
  );

  final screens = <String, Widget Function()>{
    'home': () => TongtaiHomeScreen(clock: () => DateTime(2026, 7, 30)),
    'producer': () => const TongtaiProducerScreen(),
    'inventory': () => const TongtaiInventoryScreen(),
    'consumer': () => const TongtaiConsumerScreen(),
    'more': () => const TongtaiMoreScreen(),
    'reports': () => const TongtaiReportsScreen(),
    'opportunity-feed': () => const TongtaiOpportunityFeedScreen(),
    'export': () => const TongtaiExportScreen(),
    'backup': () => const TongtaiBackupScreen(),
    'finance': () => const TongtaiFinanceScreen(),
    'timeline': () => const TongtaiTimelineScreen(),
    'customer-risk': () => const TongtaiCustomerRiskScreen(),
    'forecast': () => const TongtaiForecastScreen(),
  };

  /// Checks one screen against one guideline, returning the failure text
  /// instead of throwing — so one run reports every screen that is wrong
  /// rather than only the first.
  Future<String?> check(
    WidgetTester tester,
    Widget screen,
    String locale,
    AccessibilityGuideline guideline,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(await host(screen, locale));
    await tester.pumpAndSettle();
    String? failure;
    try {
      await expectLater(tester, meetsGuideline(guideline));
    } on TestFailure catch (e) {
      failure = e.message;
    }
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
    return failure;
  }

  for (final guideline in <String, AccessibilityGuideline>{
    'tap target ≥48dp': androidTapTargetGuideline,
    'every tappable is named': labeledTapTargetGuideline,
    'text contrast': textContrastGuideline,
  }.entries) {
    testWidgets('${guideline.key} — every screen, both locales, with data', (
      tester,
    ) async {
      await seeder().seed();
      final failures = <String>[];
      for (final locale in ['vi', 'en']) {
        for (final entry in screens.entries) {
          final failure = await check(
            tester,
            entry.value(),
            locale,
            guideline.value,
          );
          if (failure != null) {
            failures.add('── [$locale ${entry.key}] ─────\n$failure');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n\n'));
    });
  }
}
