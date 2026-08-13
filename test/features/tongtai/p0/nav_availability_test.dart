import 'dart:io';

import 'package:tongtai/database/database.dart';
import 'package:drift/native.dart';
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
  AppDatabase? sharedDb;
  AppDatabase memoryDb() =>
      sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());
  tearDown(() async {
    await sharedDb?.close();
    sharedDb = null;
  });

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
      // WTM-210: Home reads the journey repository — needs a database.
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
    //
    // ⚠️ WTM-404 đổi **cánh cửa**, không đổi **lời hứa**. Nút chữ "Tài chính"
    // trong tiêu đề mục KPI bị bỏ vì thẻ năng lực `home-tile-finance` mở đúng
    // màn ấy bằng một cú chạm — và còn nói luôn công nợ đang là bao nhiêu. Hai
    // cửa vào cùng một phòng làm gãy tiêu đề mục trên Nokia 6.1.
    //
    // Nên phép kiểm giữ nguyên câu hỏi (*"Tài chính có nằm cách Home một cú
    // chạm không"*) và chỉ đổi khoá của phần tử đang trả lời nó. ⛔ KHÔNG được
    // xoá `finance` khỏi danh sách này: cái nó canh là "đừng chôn năng lực vào
    // hộp More", và điều đó không hết hạn.
    for (final key in const [
      'home-open-reports',
      'home-tile-finance',
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
        'more-export',
        'more-reports',
        'more-finance',
        'more-forecast',
        'more-customer-risk',
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

  group('no orphan screens (WTM-218)', () {
    // Why this scan exists: `TongtaiSupplierSearchScreen` — ~600 lines, L3,
    // with its own tests — has had NO production caller since the repo was
    // bootstrapped, and SIX governance passes (WTM-146/147/148/168/171/194)
    // edited that file without one of them asking whether a seller could open
    // it. Every suite measured the QUALITY of a screen; none measured its
    // REACHABILITY. Same family as WTM-217's showcase, and the same shape as
    // the lesson learned four times over in WTM-190→194: governance catches
    // only what it was written to look for.
    //
    // A screen may be intentionally unbuilt — but then it must say so here,
    // with a reason, instead of hiding as an oversight.
    const intentionallyUnreached = <String, String>{
      'tongtai_supplier_search_screen.dart':
          'Producer = Future Capability (Founder 2026-08-01, "Không cố xây AI '
          'bằng dữ liệu giả"): the directory is SupplierSearchService'
          '.sample(), so wiring this into navigation would show a real '
          'seller a catalogue of invented suppliers. Waits on a real data '
          'source — a Founder gate, not an oversight.',
    };

    /// Which screen files some OTHER file under `lib/` imports.
    ///
    /// The question is asked per FILE, not per class: a screen is often built
    /// by a small route/host wrapper living beside it (Unified Search), and a
    /// per-class rule calls that pattern an orphan. What actually matters is
    /// whether any other code can reach into the file at all.
    Set<String> importedScreenFiles() {
      final imported = <String>{};
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        // The barrel re-exports everything, so it proves nothing about reach.
        if (f.path.endsWith('features/tongtai/tongtai.dart')) continue;
        for (final m in RegExp(
          r"""import\s+'[^']*?([\w]+_screen\.dart)'""",
        ).allMatches(f.readAsStringSync())) {
          final target = m.group(1)!;
          if (!f.path.endsWith(target)) imported.add(target);
        }
      }
      return imported;
    }

    test('every screen file is reached from lib/, or says why not', () {
      final imported = importedScreenFiles();
      final orphans = <String>[];
      for (final file in Directory(
        'lib/features/tongtai/ui/screens',
      ).listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        if (!name.endsWith('.dart')) continue;
        if (intentionallyUnreached.containsKey(name)) continue;
        if (!imported.contains(name)) orphans.add(name);
      }

      expect(
        orphans,
        isEmpty,
        reason:
            'Không file nào trong lib/ import những màn này ⇒ người bán không '
            'có đường tới. Nối vào navigation, xoá, hoặc khai vào '
            '`intentionallyUnreached` kèm lý do đọc được:\n${orphans.join('\n')}',
      );
    });

    test('the exception list stays honest — no stale entries', () {
      // An exception that outlives its reason is worse than none: it hides a
      // screen that HAS been wired, and the next reader trusts the note.
      final imported = importedScreenFiles();
      for (final entry in intentionallyUnreached.entries) {
        expect(
          File('lib/features/tongtai/ui/screens/${entry.key}').existsSync(),
          isTrue,
          reason: '${entry.key} no longer exists — drop the exception',
        );
        expect(
          imported.contains(entry.key),
          isFalse,
          reason:
              '${entry.key} IS reachable now — remove it from '
              '`intentionallyUnreached`',
        );
      }
    });
  });
}
