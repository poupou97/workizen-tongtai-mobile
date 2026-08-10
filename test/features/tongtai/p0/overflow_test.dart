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
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_export_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_finance_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_forecast_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_producer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';

/// P0 §3 (WTM-146) — layout overflow governance.
///
/// Every key screen must render WITHOUT RenderFlex overflow in BOTH shipped
/// locales on a narrow phone (320 logical px) at an accessibility text scale
/// of 1.3 — in the empty state AND with seeded data. A 2.0-scale pass on the
/// two text-heaviest screens stands in for a "long locale" until a third
/// language ships (AppStrings is N-language-ready; the app ships vi+en today —
/// gap documented in the P0 Review Package).
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

  /// Pumps [screen] at 320x640 logical px with [textScale], collecting every
  /// RenderFlex overflow error instead of failing mid-frame.
  Future<List<String>> overflowsFor(
    WidgetTester tester,
    Widget screen, {
    required String locale,
    required double textScale,
  }) async {
    final overflows = <String>[];
    final prior = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString());
      } else {
        prior?.call(details);
      }
    };
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    await tester.pumpWidget(await host(screen, locale));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    FlutterError.onError = prior;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    return overflows;
  }

  final screens = <String, Widget Function()>{
    'home': () => TongtaiHomeScreen(clock: () => DateTime(2026, 7, 30)),
    // The three shell tabs were missing from this list until WTM-169 — and
    // Inventory turned out to clip by 103 px at a 2.0x system font. A screen
    // absent from a governance suite is not a screen that passed it.
    'producer': () => const TongtaiProducerScreen(),
    'inventory': () => const TongtaiInventoryScreen(),
    'consumer': () => const TongtaiConsumerScreen(),
    'more': () => const TongtaiMoreScreen(),
    'reports': () => const TongtaiReportsScreen(),
    'opportunity-feed': () => const TongtaiOpportunityFeedScreen(),
    'export': () => const TongtaiExportScreen(),
    'backup': () => const TongtaiBackupScreen(),
    'finance': () => const TongtaiFinanceScreen(),
    'customer-risk': () => const TongtaiCustomerRiskScreen(),
    'forecast': () => const TongtaiForecastScreen(),
  };

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] no overflow @320px/1.3x — empty AND seeded states', (
      tester,
    ) async {
      final all = <String>[];
      for (final entry in screens.entries) {
        final empty = await overflowsFor(
          tester,
          entry.value(),
          locale: locale,
          textScale: 1.3,
        );
        all.addAll(empty.map((e) => '[$locale empty ${entry.key}] $e'));
      }
      await seeder().seed();
      for (final entry in screens.entries) {
        final seeded = await overflowsFor(
          tester,
          entry.value(),
          locale: locale,
          textScale: 1.3,
        );
        all.addAll(seeded.map((e) => '[$locale seeded ${entry.key}] $e'));
      }
      expect(all, isEmpty, reason: all.join('\n'));
    });
  }

  testWidgets('long-content proxy: More + Home @320px/2.0x do not overflow', (
    tester,
  ) async {
    await seeder().seed();
    final all = <String>[];
    for (final locale in ['vi', 'en']) {
      for (final entry in [
        MapEntry('more', const TongtaiMoreScreen() as Widget),
        MapEntry('home', TongtaiHomeScreen(clock: () => DateTime(2026, 7, 30))),
      ]) {
        final o = await overflowsFor(
          tester,
          entry.value,
          locale: locale,
          textScale: 2.0,
        );
        all.addAll(o.map((e) => '[$locale 2.0x ${entry.key}] $e'));
      }
    }
    expect(all, isEmpty, reason: all.join('\n'));
  });
}
