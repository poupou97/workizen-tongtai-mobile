import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_create_order_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart'
    show kSampleCustomers;
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart'
    show kSampleProducts;
import 'package:tongtai/database/database.dart';

/// **Nokia 6.1 — máy tham chiếu tầm thấp.** Số đo THẬT, không phải số nhớ được.
///
/// ```
/// adb shell wm size     → Physical size: 1080x1920
/// adb shell wm density  → Physical density: 420      ⇒ ratio 420/160 = 2.625
///                       ⇒ 1080/2.625 x 1920/2.625 = 411.4 x 731.4 dp
/// ```
///
/// ⚠️ **WTM-399.** Bản đầu ghi `Size(1080, 2160)` — chiều cao 18:9 của một lớp
/// máy khác, trong khi Nokia 6.1 là **16:9**. `2160/2.625 = 823 dp`, và bản tóm
/// tắt audit gọi đó là *"kích thước logic của Nokia"*. Rộng đúng, **cao sai 92 dp
/// (12,6%)**.
///
/// Kết luận "thứ tự đọc sạch" nhiều khả năng vẫn đúng — thứ tự duyệt hiếm khi
/// phụ thuộc chiều cao. Nhưng guard khi ấy đo ở một kích thước **không máy nào
/// có**: màn cao hơn chứa được nhiều nội dung hơn trước khi phải cuộn, nên một
/// khiếm khuyết chỉ lộ khi nội dung dồn ở chiều cao thật sẽ lọt qua.
///
/// Đặt tên cho con số vì **số chép tay là chỗ sai lần sau**. Test nào cần trung
/// thực với thiết bị thì dùng hằng này; test nào chỉ cần một khung cao để tránh
/// tràn thì cứ khai thẳng như vậy — một khung nói *"tôi là canvas cao"* là trung
/// thực, một khung nói *"tôi là Nokia"* mà không phải thì không.
const double kNokia61PixelRatio = 2.625;
const Size kNokia61PhysicalSize = Size(1080, 1920);

/// WTM-277 (Option C) — a screen reader's *structural* affordances, read from
/// Flutter's own semantics tree.
///
/// This is deliberately **not** a "TalkBack pass". A blind person judging
/// whether the app *reads naturally* — whether the order sounds right, whether
/// a control is over-verbose, whether there is enough context without sight —
/// stays a human/device gate (Founder decision 2026-08-13). What a machine
/// **can** prove, and what this guards, are the semantic *roles* the on-device
/// audit (2026-08-13, Nokia 6.1) relied on and that WTM-168's guideline suite
/// (`labeledTapTargetGuideline`, `androidTapTargetGuideline`,
/// `textContrastGuideline`) does not check:
///
/// - **Every content screen names its route and marks a header.** TalkBack
///   announces the screen on entry (`namesRoute`) and lets the user jump by
///   heading (`isHeader`). Replace the semantic app-bar title with a plain
///   `Text` and both affordances vanish silently — the guideline suite would
///   still pass. This test would not.
/// - **Search screens expose an editable field** (`isTextField`), so the search
///   box is announced as something you can type into, not read as static text.
///
/// The live `flutter run` + `S` dump does **not** help here: Flutter only
/// builds a semantics tree when the platform asks (i.e. TalkBack is on), and
/// turning TalkBack on corrupts the very measurement (TESTING-BIBLE P-36).
/// `tester.ensureSemantics()` builds the identical tree in-process with no
/// assistive service running — the only clean way to read it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryCustomerRepository customerRepo;
  late InMemoryProductRepository productRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryBusinessGoalRepository goalRepo;
  late InMemoryFinanceRepository financeRepo;
  AppDatabase? sharedDb;
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

  /// The main-flow content screens a seller lands on. Each is a titled route.
  /// Onboarding is intentionally excluded — it is a full-screen welcome flow,
  /// not a titled route, and carries neither `isHeader` nor `namesRoute`
  /// (confirmed by the 2026-08-13 dump); asserting it here would be wrong.
  final contentScreens = <String, Widget Function()>{
    'home': () => TongtaiHomeScreen(clock: () => DateTime(2026, 7, 30)),
    'inventory': () => const TongtaiInventoryScreen(),
    'customer-list': () => const TongtaiCustomerListScreen(),
    'create-order': () => TongtaiCreateOrderScreen(
      customer: kSampleCustomers.first,
      products: kSampleProducts,
    ),
    'reports': () => const TongtaiReportsScreen(),
    'consumer': () => const TongtaiConsumerScreen(),
    'more': () => const TongtaiMoreScreen(),
  };

  /// Screens whose top control is a search box.
  final searchScreens = <String, Widget Function()>{
    'inventory': () => const TongtaiInventoryScreen(),
    'customer-list': () => const TongtaiCustomerListScreen(),
  };

  List<SemanticsData> semanticsOf(WidgetTester tester) {
    // The semantics owner lives on a child pipeline owner (one per view) under
    // the root — reach it without the deprecated RendererBinding.pipelineOwner.
    SemanticsNode? root;
    void findRoot(PipelineOwner owner) {
      root ??= owner.semanticsOwner?.rootSemanticsNode;
      owner.visitChildren(findRoot);
    }

    findRoot(tester.binding.rootPipelineOwner);

    final out = <SemanticsData>[];
    void walk(SemanticsNode node) {
      out.add(node.getSemanticsData());
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    if (root != null) walk(root!);
    return out;
  }

  Future<List<SemanticsData>> render(
    WidgetTester tester,
    Widget screen,
    String locale,
  ) async {
    tester.view.devicePixelRatio = kNokia61PixelRatio;
    tester.view.physicalSize = kNokia61PhysicalSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await host(screen, locale));
    await tester.pumpAndSettle();
    final data = semanticsOf(tester);
    await tester.pumpWidget(const SizedBox());
    return data;
  }

  testWidgets('every content screen names its route + marks a header, both '
      'locales', (tester) async {
    await seeder().seed();
    final handle = tester.ensureSemantics();
    final failures = <String>[];
    for (final locale in ['vi', 'en']) {
      for (final entry in contentScreens.entries) {
        final data = await render(tester, entry.value(), locale);
        final titled = data.any(
          (d) => d.flagsCollection.isHeader && d.flagsCollection.namesRoute,
        );
        if (!titled) {
          failures.add(
            '[$locale ${entry.key}] no node carries isHeader+namesRoute — '
            'TalkBack cannot announce the screen or offer heading navigation',
          );
        }
      }
    }
    handle.dispose();
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  testWidgets('search screens expose an editable text field', (tester) async {
    await seeder().seed();
    final handle = tester.ensureSemantics();
    final failures = <String>[];
    for (final entry in searchScreens.entries) {
      final data = await render(tester, entry.value(), 'vi');
      final hasField = data.any((d) => d.flagsCollection.isTextField);
      if (!hasField) {
        failures.add(
          '[${entry.key}] no isTextField node — the search box is not '
          'announced as editable',
        );
      }
    }
    handle.dispose();
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
