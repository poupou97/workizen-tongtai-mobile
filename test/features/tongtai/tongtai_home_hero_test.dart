import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/metrics/home_headline.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
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
import 'package:tongtai/features/tongtai/ui/screens/tongtai_chat_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';

import '../../support/pump_until.dart';

/// WTM-221 — Home's opening line (concept-1).
///
/// The Concept opens Home with the app **saying something about this
/// business**, not with a row of numbers the seller must read for themselves.
/// That sentence is only worth having if it is true, so the tests below are
/// mostly about the three states being distinguishable: found something ·
/// looked and found nothing · not enough business to look at.
void main() {
  late AppDatabase db;
  late InMemoryCustomerRepository customerRepo;
  late InMemoryProductRepository productRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryBusinessGoalRepository goalRepo;
  late InMemoryFinanceRepository financeRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    customerRepo = InMemoryCustomerRepository();
    productRepo = InMemoryProductRepository([]);
    orderRepo = InMemoryOrderRepository();
    goalRepo = InMemoryBusinessGoalRepository();
    financeRepo = InMemoryFinanceRepository();
  });

  tearDown(() => db.close());

  SampleDataSeeder seeder() => SampleDataSeeder(
    customers: customerRepo,
    products: productRepo,
    orders: orderRepo,
    goals: goalRepo,
    finance: financeRepo,
  );

  Future<Widget> host() async => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      tongtaiDatabaseProvider.overrideWithValue(db),
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
      locale: const Locale('vi'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: TongtaiHomeScreen(clock: () => DateTime(2026, 8, 2)),
    ),
  );

  void tallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3600);
  }

  String headlineText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('home-hero-headline'))).data!;

  testWidgets('a brand-new business is told what to do, not given a zero', (
    tester,
  ) async {
    // "0 cơ hội" on the very first screen reads as a verdict on the seller's
    // business instead of on their empty database (ADR-TON-017: empty ≠
    // insufficient).
    tallViewport(tester);
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-hero')));

    expect(headlineText(tester), contains('Thêm'));
    expect(headlineText(tester), isNot(contains('0')));
  });

  testWidgets('with a real business the line carries the real count', (
    tester,
  ) async {
    tallViewport(tester);
    await seeder().seed();
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-hero')));
    await tester.pumpAndSettle();

    // The number is whatever the Rule Engine produced for THIS data — the
    // assertion is that the sentence and the feed agree, not that it is 12.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TongtaiHomeScreen)),
    );
    final List<Opportunity> generated = await container.read(
      generatedOpportunitiesProvider.future,
    );
    if (generated.isEmpty) {
      // Data exists but nothing stood out: that is an answer, and it must not
      // be dressed up as "not enough data".
      expect(headlineText(tester), contains('nổi bật'));
    } else {
      expect(headlineText(tester), contains('${generated.length}'));
    }
  });

  testWidgets('the ask box opens the conversation', (tester) async {
    tallViewport(tester);
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-ask')));

    await tester.tap(find.byKey(const Key('home-ask')));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiChatScreen), findsOneWidget);
  });

  testWidgets('no microphone — voice is a Future Capability', (tester) async {
    // Founder kept voice input out of scope (WTM-208 group B). A mic icon that
    // does nothing is the WTM-169 defect wearing a new icon.
    tallViewport(tester);
    await tester.pumpWidget(await host());
    await pumpUntilFound(tester, find.byKey(const Key('home-hero')));

    expect(
      find.descendant(
        of: find.byKey(const Key('home-hero')),
        matching: find.byIcon(Icons.mic),
      ),
      findsNothing,
    );
  });

  group('information hierarchy — Concept order (WTM-222)', () {
    testWidgets('today\'s missions come first, above KPIs and opportunities', (
      tester,
    ) async {
      // Order on a screen IS a statement about what matters. This block used
      // to sit at the very BOTTOM of Home: a seller scrolled past revenue and
      // opportunities to reach the one thing they were meant to do today —
      // while D-11 says the Journey is the product's centre. The assertion is
      // on positions, because "the widget exists somewhere" was already true
      // when the hierarchy was wrong.
      tallViewport(tester);
      await seeder().seed();
      await tester.pumpWidget(await host());
      await pumpUntilFound(tester, find.byKey(const Key('home-open-journey')));
      await tester.pumpAndSettle();

      double top(String key) => tester.getTopLeft(find.byKey(Key(key))).dy;

      expect(top('home-hero'), lessThan(top('home-open-journey')));
      expect(
        top('home-open-journey'),
        lessThan(top('home-open-opportunities')),
        reason: 'việc phải làm hôm nay đứng trước cơ hội',
      );
      expect(
        top('home-open-journey'),
        lessThan(top('home-open-reports')),
        reason: 'việc phải làm hôm nay đứng trước hàng KPI',
      );
    });
  });

  group('the rule behind the sentence', () {
    test('found something wins over everything else', () {
      expect(
        homeHeadlineKind(opportunityCount: 3, hasData: true),
        HomeHeadlineKind.opportunities,
      );
      expect(
        homeHeadlineKind(opportunityCount: 3, hasData: false),
        HomeHeadlineKind.opportunities,
        reason: 'if the engine found work, the business is not empty',
      );
    });

    test('nothing found: data decides which honest answer applies', () {
      expect(
        homeHeadlineKind(opportunityCount: 0, hasData: true),
        HomeHeadlineKind.noneToday,
      );
      expect(
        homeHeadlineKind(opportunityCount: 0, hasData: false),
        HomeHeadlineKind.notEnoughData,
      );
    });
  });
}
