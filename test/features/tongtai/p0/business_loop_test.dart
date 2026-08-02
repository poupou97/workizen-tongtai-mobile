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
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_metric.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_data_invalidation.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';

import '../../../support/pump_until.dart';

/// P0 — **Business Loop** (Founder 2026-08-02).
///
/// > *"Một Capability chỉ thực sự hoàn thành khi người dùng: thấy vấn đề →
/// > hành động → **thấy kết quả** → **biết bước tiếp theo**."*
///
/// The audit is by **capability lifecycle**, not by screen — and that is what
/// exposed this: WTM-220 hung the journey's re-measurement on a *navigation
/// gesture* (popping back from the work), so a seller who records an expense
/// straight from the Finance tab — the ordinary path — was never noticed.
/// Fixing per-screen patches one route; the lifecycle question finds the rest.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tongtai_business_loop');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  BusinessGoal goal() => BusinessGoal(
    id: 'g1',
    name: 'Doanh thu 50 triệu',
    type: GoalType.revenue,
    targetAmount: 50000000,
    achievedAmount: 0,
    growthTarget: 20,
    growthAchieved: 0,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  Future<void> seedBusinessWithJourney() async {
    await DriftBusinessGoalRepository(db).upsert(goal());
    await DriftCustomerRepository(db).upsert(
      const Customer(
        id: 'c1',
        name: 'Khách 1',
        phone: '0900000000',
        location: 'HCM',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
      ),
    );
    await JourneyController(
      JourneyRepository(db),
      clock: () => DateTime(2026, 8, 1),
    ).startJourney(
      JourneyPlanInput(
        goal: goal(),
        productCount: 10,
        customerCount: 1,
        orderCount: 3,
        expenseCount: 0,
      ),
      journeyId: 'j1',
    );
  }

  ProviderContainer container() => ProviderContainer(
    overrides: [
      tongtaiDatabaseProvider.overrideWithValue(db),
      customerRepositoryProvider.overrideWithValue(DriftCustomerRepository(db)),
      productRepositoryProvider.overrideWithValue(DriftProductRepository(db)),
      orderRepositoryProvider.overrideWithValue(DriftOrderRepository(db)),
      businessGoalRepositoryProvider.overrideWithValue(
        DriftBusinessGoalRepository(db),
      ),
      financeRepositoryProvider.overrideWithValue(DriftFinanceRepository(db)),
      tongtaiSearchFavoritesStoreProvider.overrideWithValue(
        InMemorySupplierFavoritesStore(),
      ),
    ],
  );

  Future<void> recordFiveExpenses() => DriftFinanceRepository(db).addAll([
    for (var i = 0; i < 5; i++)
      FinanceTransaction(
        id: 'tx$i',
        type: TransactionType.expense,
        category: FinanceCategory.other,
        amount: 100000,
        date: DateTime(2026, 8, 1),
      ),
  ]);

  test(
    'nhịp 4 — ghi ở Finance, hành trình đo lại mà KHÔNG cần đi qua màn nào',
    () async {
      // The seller taps the Finance tab and records their expenses there. They
      // never open the journey. Before WTM-224 the step tied to `expenses >= 5`
      // stayed open forever, because the only thing that ever re-measured it
      // was popping back from a screen they never visited.
      await seedBusinessWithJourney();
      final c = container();
      addTearDown(c.dispose);

      final before = await c.read(activeJourneyProvider.future);
      final stepId = before!.nodes
          .firstWhere((n) => n.derivedMetric == JourneyMetric.expenses.code)
          .id;
      expect(before.nodes.firstWhere((n) => n.id == stepId).isDone, isFalse);

      await recordFiveExpenses();
      // The one signal every write is supposed to raise (WTM-174's seam).
      invalidateBusinessDataProvidersIn(c);

      final after = await c.read(activeJourneyProvider.future);
      expect(
        after!.nodes.firstWhere((n) => n.id == stepId).isDone,
        isTrue,
        reason:
            'hành trình phải nhận ra việc người bán vừa làm, dù họ không mở '
            'màn hành trình lần nào',
      );
    },
  );

  test('đo lại chỉ tiến, không lùi — một khoản chi bị xoá không mở lại bước đã '
      'xong', () async {
    // `refreshDerived` is forward-only on purpose: a refund or a corrected
    // entry must not un-finish work the seller already did. Reading the metric
    // live would break exactly that, so the completion stays recorded.
    await seedBusinessWithJourney();
    final c = container();
    addTearDown(c.dispose);

    await recordFiveExpenses();
    invalidateBusinessDataProvidersIn(c);
    final done = await c.read(activeJourneyProvider.future);
    final stepId = done!.nodes
        .firstWhere((n) => n.derivedMetric == JourneyMetric.expenses.code)
        .id;
    expect(done.nodes.firstWhere((n) => n.id == stepId).isDone, isTrue);

    await DriftFinanceRepository(db).deleteByIdPrefix('tx0');
    invalidateBusinessDataProvidersIn(c);

    final after = await c.read(activeJourneyProvider.future);
    expect(
      after!.nodes.firstWhere((n) => n.id == stepId).isDone,
      isTrue,
      reason: 'công việc đã làm không bị rút lại vì một số liệu tụt xuống',
    );
  });

  group('nhịp 3 — kết quả hiện ra ngoài màn vừa ghi', () {
    Future<Widget> home() async => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        tongtaiDatabaseProvider.overrideWithValue(db),
        customerRepositoryProvider.overrideWithValue(
          DriftCustomerRepository(db),
        ),
        productRepositoryProvider.overrideWithValue(DriftProductRepository(db)),
        orderRepositoryProvider.overrideWithValue(DriftOrderRepository(db)),
        businessGoalRepositoryProvider.overrideWithValue(
          DriftBusinessGoalRepository(db),
        ),
        financeRepositoryProvider.overrideWithValue(DriftFinanceRepository(db)),
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

    testWidgets('a customer added elsewhere shows on Home without a restart', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 3600);

      await tester.pumpWidget(await home());
      await pumpUntilFound(tester, find.byKey(const Key('home-hero')));
      await tester.pumpAndSettle();

      // Another capability writes — exactly what the Consumer tab does.
      await tester.runAsync(() async {
        await DriftCustomerRepository(db).upsert(
          const Customer(
            id: 'c-new',
            name: 'Khách mới',
            phone: '0911111111',
            location: 'HN',
            orderCount: 0,
            totalSpent: 0,
            lastPurchaseDate: null,
          ),
        );
      });
      final element = tester.element(find.byType(TongtaiHomeScreen));
      invalidateBusinessDataProvidersIn(ProviderScope.containerOf(element));
      await tester.pumpAndSettle();

      expect(
        find.text('1'),
        findsWidgets,
        reason: 'Home phải thấy khách vừa thêm ở capability khác',
      );
    });
  });

  group('governance — mọi đường ghi dữ liệu kinh doanh phải phát tín hiệu', () {
    /// Screens that call `runTongtaiAction` but do NOT change the business
    /// data, each with the reason. An entry here is a claim someone can check.
    const notBusinessData = <String, String>{
      'tongtai_ai_key_screen.dart':
          'BYOK key → secure storage, not business data',
      'tongtai_key_scan_screen.dart': 'camera permission only',
      'tongtai_feedback_screen.dart': 'shares text out; writes nothing',
      'tongtai_export_screen.dart': 'writes a FILE; the business is unchanged',
      'tongtai_chat_screen.dart': 'chat transcript, not business records',
      'tongtai_unified_search_screen.dart': 'seeds the FTS index, derived data',
      'tongtai_customer_risk_screen.dart':
          'read-only screen; the guarded call '
          'is a repository READ (WTM-171)',
      'tongtai_supplier_favorites_screen.dart':
          'favourites belong to Producer, '
          'a Future Capability whose data is sample-only (WTM-218) — nothing '
          'downstream reads them but the Producer tab itself',
      'tongtai_supplier_search_screen.dart':
          'same as favourites; and the screen '
          'has no journey into it at all yet (WTM-218)',
      'tongtai_onboarding_conversation_screen.dart':
          'writes the profile before '
          'any of the readers exist — the app has not started yet',
      'tongtai_opportunity_detail_screen.dart':
          'writes journey nodes and '
          'invalidates the journey providers directly (WTM-191/223)',
    };

    test('a screen that writes business data raises the one signal', () {
      final offenders = <String>[];
      for (final f in Directory(
        'lib/features/tongtai/ui/screens',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final name = f.uri.pathSegments.last;
        final src = f.readAsStringSync();
        if (!src.contains('runTongtaiAction(')) continue;
        if (notBusinessData.containsKey(name)) continue;
        if (!src.contains('invalidateBusinessDataProviders(')) {
          offenders.add(name);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Ghi xong mà không phát tín hiệu ⇒ chỉ màn vừa ghi thấy thay đổi: '
            'KPI Home đứng im, capability context giữ số cũ, và hành trình '
            'không bao giờ biết người bán vừa làm xong việc nó giao. Gọi '
            '`invalidateBusinessDataProviders(ref)` sau khi ghi thành công, '
            'hoặc khai vào `notBusinessData` kèm lý do:\n'
            '${offenders.join('\n')}',
      );
    });

    test('danh sách miễn trừ không mục — file phải còn tồn tại', () {
      for (final name in notBusinessData.keys) {
        expect(
          File('lib/features/tongtai/ui/screens/$name').existsSync(),
          isTrue,
          reason: '$name không còn tồn tại — gỡ khỏi danh sách',
        );
      }
    });
  });
}
