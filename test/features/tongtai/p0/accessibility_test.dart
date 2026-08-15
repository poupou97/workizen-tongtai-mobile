import 'package:drift/native.dart';
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
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goal_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goals_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_search_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_transaction_form_screen.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart'
    show kSampleCustomers;
import 'package:tongtai/features/tongtai/inventory/product_catalog_controller.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart'
    show kSampleProducts;
import 'package:tongtai/features/tongtai/journey/business_goal.dart'
    show kSampleBusinessGoals;
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart'
    show kSampleOpportunities;
import 'package:tongtai/features/tongtai/producer/supplier_favorites_controller.dart';
import 'package:tongtai/features/tongtai/producer/supplier_search_service.dart'
    show kSampleSuppliers;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_create_order_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_history_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_goal_detail_screen.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_picker_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_onboarding_v2_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_detail_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_stock_alerts_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_detail_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_favorites_screen.dart';

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
  AppDatabase? sharedDb;

  /// One in-memory database per test.
  ///
  /// The opportunity feed reads the seller's stored reactions now (WTM-190), so
  /// it needs a database. Without this override the harness reaches for the
  /// real one and dies on `path_provider` — which is the harness failing, not
  /// the screen.
  AppDatabase memoryDb() =>
      sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());

  tearDown(() async {
    await sharedDb?.close();
    sharedDb = null;
  });

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
      tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
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

  // ⚠️ **GIỚI HẠN ĐÃ BIẾT — cổng này quét TRẠNG THÁI KHỞI ĐẦU** (WTM-432).
  //
  // Mỗi mục dưới đây dựng màn ở trạng thái vừa mở. Widget chỉ sinh ra **sau
  // tương tác** — một dòng đơn hàng vừa thêm, kết quả tìm kiếm, thẻ lỗi sau khi
  // bấm — **không tồn tại** lúc guideline chạy, nên cổng không thể kiểm chúng.
  //
  // Đã trả giá một lần: nút xoá dòng ở `create-order` sống suốt mà không có
  // nhãn, dù màn ấy CÓ trong danh sách này. `_items` khởi tạo rỗng ⇒
  // `itemBuilder` không dựng dòng nào ⇒ không có nút để kiểm.
  //
  // ⇒ Màn "đã được phủ" ở đây **không** có nghĩa là mọi trạng thái của nó đã
  // được kiểm. Khẳng định cho trạng thái sau tương tác phải sống trong test
  // riêng của màn, nơi test đã lái được màn tới đó — khuôn mẫu:
  // `orders/tongtai_create_order_screen_test.dart` (WTM-432).
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
    'customer-risk': () => const TongtaiCustomerRiskScreen(),
    'forecast': () => const TongtaiForecastScreen(),
    // Every screen that constructs without a caller-supplied entity. The rest
    // need a customer/goal/supplier to exist first and are exercised by their
    // own widget tests.
    //
    // AI key and Chat are deliberately absent: they reach for
    // flutter_secure_storage and a real database on mount, so here they fail on
    // a missing plugin rather than on accessibility. Their contrast fixes are
    // in this change; their own widget tests cover the rest. A governance suite
    // that goes red for infrastructure reasons stops being read.
    'customer-form': () => const TongtaiCustomerFormScreen(),
    'customer-list': () => const TongtaiCustomerListScreen(),
    'goal-form': () => const TongtaiGoalFormScreen(),
    'goals': () => const TongtaiGoalsScreen(),
    'product-form': () => const TongtaiProductFormScreen(),
    'supplier-search': () => const TongtaiSupplierSearchScreen(),
    'transaction-form': () => const TongtaiTransactionFormScreen(),
    // Screens that need an entity to exist. They are the ones a seller reaches
    // by tapping something, which is most of the app.
    'onboarding': () => TongtaiOnboardingV2Screen(onDone: (_) {}),
    'supplier-detail': () =>
        TongtaiSupplierDetailScreen.forSupplier(kSampleSuppliers.first),
    'supplier-favorites': () => TongtaiSupplierFavoritesScreen(
      favorites: SupplierFavoritesController.inMemory(),
    ),
    'inventory-picker': () =>
        TongtaiInventoryPickerScreen(products: kSampleProducts),
    'stock-alerts': () =>
        TongtaiStockAlertsScreen(catalog: ProductCatalogController.sample()),
    'goal-detail': () =>
        TongtaiGoalDetailScreen(goal: kSampleBusinessGoals.first),
    'opportunity-detail': () =>
        TongtaiOpportunityDetailScreen(opportunity: kSampleOpportunities.first),
    'customer-history': () =>
        TongtaiCustomerHistoryScreen(customer: kSampleCustomers.first),
    'create-order': () => TongtaiCreateOrderScreen(
      customer: kSampleCustomers.first,
      products: kSampleProducts,
    ),
  };

  /// Checks one screen against one guideline, returning the failure text
  /// instead of throwing — so one run reports every screen that is wrong
  /// rather than only the first.
  Future<String?> check(
    WidgetTester tester,
    Widget screen,
    String locale,
    AccessibilityGuideline guideline, {
    double textScale = 1.0,
  }) async {
    final handle = tester.ensureSemantics();
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // Capture layout overflow here rather than letting it explode anonymously:
    // by the time the default handler prints, the widget is DEFUNCT and the
    // message cannot say WHICH screen broke — which makes it unfixable.
    final overflows = <String>[];
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        priorOnError?.call(details);
      }
    };

    await tester.pumpWidget(await host(screen, locale));
    await tester.pumpAndSettle();
    String? failure;
    try {
      await expectLater(tester, meetsGuideline(guideline));
    } on TestFailure catch (e) {
      failure = e.message;
    }
    await tester.pumpWidget(const SizedBox());
    FlutterError.onError = priorOnError;
    handle.dispose();
    if (overflows.isNotEmpty) {
      failure = '${failure ?? ''}\nLAYOUT OVERFLOW: ${overflows.join(' | ')}';
    }
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

  // A seller who has turned the system font up is the person most likely to
  // need a 48 dp target too — the two accessibility settings arrive together,
  // so they have to be tested together.
  testWidgets('tap targets survive a 2.0x system font', (tester) async {
    await seeder().seed();
    final failures = <String>[];
    for (final entry in screens.entries) {
      final failure = await check(
        tester,
        entry.value(),
        'vi',
        androidTapTargetGuideline,
        textScale: 2.0,
      );
      if (failure != null) {
        failures.add('── [vi 2.0x ${entry.key}] ─────\n$failure');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n\n'));
  });
}
