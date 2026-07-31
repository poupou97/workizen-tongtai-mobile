import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_predictive_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart';

/// WTM-161 — the **Customer Risk screen**, through PRODUCTION wiring.
///
/// No screen-level mocks: the real `customerRiskProvider` runs the real
/// [CustomerRiskRule] over the real `CustomerCapabilityContext`, itself built
/// from the production `customerRepositoryProvider` / `orderRepositoryProvider`
/// (in-memory implementations of the same interfaces Drift implements). What
/// this suite locks:
///
/// - **Summary Count == Visible Records** (ADR-TON-015 §2): each lifecycle
///   counter equals the number of rows actually on screen for that stage;
/// - the **id → name join** happens in the UI and only in the UI — the row shows
///   the customer's name while the assessment object still carries no PII
///   (D-7 / ADR-TON-005);
/// - "no data" is rendered as no data, never as an assessment of zeros
///   (Testing Bible P-03).
///
/// The capability context reads `DateTime.now()` (production has no clock seam
/// on the Riverpod provider), so every fixture order is dated **relative to
/// today** — the lifecycle stages below are therefore the same on any day the
/// suite runs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();

  /// A calendar date [days] before today — `wholeDaysBetween` is date-only, so
  /// this yields exactly [days] of recency whatever time the test runs.
  DateTime daysAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  Customer customer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
    email: 'khach@example.com',
  );

  var nextOrder = 0;
  CustomerOrder order(String customerId, DateTime date, double amount) {
    nextOrder += 1;
    return CustomerOrder(
      id: 'o$nextOrder',
      customerId: customerId,
      orderNumber: 'DH-$nextOrder',
      date: date,
      status: OrderStatus.delivered,
      items: [
        OrderItem(
          productName: 'Khăn lụa',
          category: 'Fashion',
          quantity: 1,
          unitPrice: amount,
        ),
      ],
    );
  }

  // ── The directory ────────────────────────────────────────────────────────
  //
  //  id            orders (days ago)   cadence  recency  ratio   stage
  //  c-active      90 · 60 · 30        30 d     30 d     1.0     active
  //  c-single      10                  —        10 d     fixed   active
  //  c-cooling     130 · 70            60 d     70 d     1.17    cooling
  //  c-at-risk     140 · 100           40 d     100 d    2.5     at risk
  //  c-churned     400 · 380           20 d     380 d    19.0    churned
  //  c-never       —                   —        —        —       never bought
  const churnedName = 'Nguyễn Thị Mai';
  const atRiskName = 'Trần Văn Hùng';

  final directory = <Customer>[
    customer('c-active', 'Lê Thu Hà'),
    customer('c-single', 'Phạm Quốc Anh'),
    customer('c-cooling', 'Đỗ Minh Châu'),
    customer('c-at-risk', atRiskName),
    customer('c-churned', churnedName),
    customer('c-never', 'Vũ Hoàng Nam'),
  ];

  final orders = <CustomerOrder>[
    order('c-active', daysAgo(90), 1000000),
    order('c-active', daysAgo(60), 1000000),
    order('c-active', daysAgo(30), 1000000),
    order('c-single', daysAgo(10), 300000),
    order('c-cooling', daysAgo(130), 800000),
    order('c-cooling', daysAgo(70), 800000),
    order('c-at-risk', daysAgo(140), 2000000),
    order('c-at-risk', daysAgo(100), 2000000),
    order('c-churned', daysAgo(400), 5000000),
    order('c-churned', daysAgo(380), 5000000),
  ];

  /// The production graph over in-memory repositories. [twin] is supplied only
  /// by the refusal test, which needs a twin state the rule cannot produce from
  /// data today (see there).
  Widget host({
    List<Customer> customers = const [],
    List<CustomerOrder> orders = const [],
    RuleTwinResult<CustomerRiskAssessment>? twin,
  }) => ProviderScope(
    overrides: [
      customerRepositoryProvider.overrideWithValue(
        InMemoryCustomerRepository(customers),
      ),
      orderRepositoryProvider.overrideWithValue(
        InMemoryOrderRepository(orders),
      ),
      if (twin != null) customerRiskProvider.overrideWith((ref) async => twin),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('vi')],
      home: TongtaiCustomerRiskScreen(),
    ),
  );

  Future<void> pump(WidgetTester tester, Widget app) async {
    // Tall surface so EVERY row of the ranked list is built — the contract is
    // about records the user can see, and a lazily-unbuilt row would make the
    // count check pass for the wrong reason.
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  /// Every rendered risk row, found by its stable id key.
  Finder riskRows() => find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('risk-item-');
  });

  /// The number rendered inside a `risk-summary-*` tile.
  int summaryCount(WidgetTester tester, String key) {
    final tile = find.byKey(Key(key));
    expect(tile, findsOneWidget, reason: 'summary tile $key must be on screen');
    final numbers = tester
        .widgetList<Text>(
          find.descendant(of: tile, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => int.tryParse(t) != null)
        .toList();
    expect(numbers, hasLength(1), reason: '$key must render exactly one count');
    return int.parse(numbers.single);
  }

  Future<RuleTwinResult<CustomerRiskAssessment>> twinOf(
    WidgetTester tester,
  ) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TongtaiCustomerRiskScreen)),
    );
    return container.read(customerRiskProvider.future);
  }

  testWidgets('empty directory → the empty state, and NOT a single row', (
    tester,
  ) async {
    await pump(tester, host());

    expect(find.byKey(const Key('risk-empty')), findsOneWidget);
    expect(riskRows(), findsNothing);
    // An empty directory is a fact, not a failed computation: the "cannot
    // assess" notice must NOT be what the user sees.
    expect(find.byKey(const Key('risk-insufficient')), findsNothing);
    expect(find.text(const AppStringsEn().riskEmpty), findsOneWidget);
  });

  testWidgets(
    'Summary Count == Visible Records: every stage counter equals its rows',
    (tester) async {
      await pump(tester, host(customers: directory, orders: orders));
      final twin = await twinOf(tester);
      final assessment = twin.result!;

      // The fixtures really do cover every stage — otherwise the contract
      // below would be satisfied by an all-zero assessment.
      expect(
        assessment.entryFor('c-active')!.stage,
        CustomerLifecycleStage.active,
      );
      expect(
        assessment.entryFor('c-single')!.stage,
        CustomerLifecycleStage.active,
      );
      expect(
        assessment.entryFor('c-cooling')!.stage,
        CustomerLifecycleStage.cooling,
      );
      expect(
        assessment.entryFor('c-at-risk')!.stage,
        CustomerLifecycleStage.atRisk,
      );
      expect(
        assessment.entryFor('c-churned')!.stage,
        CustomerLifecycleStage.churned,
      );
      expect(
        assessment.entryFor('c-never')!.stage,
        CustomerLifecycleStage.neverPurchased,
      );

      // Every customer in the directory is on screen, keyed by id.
      for (final entry in assessment.entries) {
        expect(
          find.byKey(Key('risk-item-${entry.customerId}')),
          findsOneWidget,
          reason: 'no row for ${entry.customerId}',
        );
      }
      expect(riskRows(), findsNWidgets(assessment.totalCustomers));

      // Per stage: the counter == the rows the user can actually see.
      for (final stage in CustomerLifecycleStage.values) {
        final ids = assessment.entries
            .where((e) => e.stage == stage)
            .map((e) => e.customerId)
            .toList();
        expect(
          summaryCount(tester, 'risk-summary-${tongtaiRiskStageKey(stage)}'),
          ids.length,
          reason: 'summary counter for ${stage.name}',
        );
        for (final id in ids) {
          expect(find.byKey(Key('risk-item-$id')), findsOneWidget);
        }
      }

      // Win-back is an overlapping count, and it drives the advice below.
      expect(
        summaryCount(tester, 'risk-summary-win-back'),
        assessment.winBackCount,
      );
      expect(assessment.winBackCount, 2); // c-at-risk + c-churned

      // Provenance: deterministic, not AI (ADR-TON-016).
      expect(find.byKey(const Key('risk-confidence')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('risk-confidence')),
          matching: find.text(const AppStringsEn().forecastRuleBased),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('risk-confidence')),
          matching: find.textContaining(twin.confidence.label('en')),
        ),
        findsOneWidget,
      );

      // Ranked: the riskiest customer is the churned one, and the list is in
      // the twin's own order (the screen never re-sorts).
      expect(assessment.entries.first.customerId, 'c-churned');

      // Recommended actions exist for exactly the win-back candidates, and are
      // suggestions only — nothing here contacts anybody (ADR-TON-016).
      for (final id in const ['c-at-risk', 'c-churned']) {
        expect(find.byKey(Key('risk-action-contact-$id')), findsOneWidget);
        expect(find.byKey(Key('risk-action-offer-$id')), findsOneWidget);
      }
      for (final id in const ['c-active', 'c-cooling', 'c-never']) {
        expect(find.byKey(Key('risk-action-contact-$id')), findsNothing);
        expect(find.byKey(Key('risk-action-offer-$id')), findsNothing);
      }
    },
  );

  testWidgets('the row shows the NAME joined from the repository, while the '
      'assessment itself still holds no PII', (tester) async {
    await pump(tester, host(customers: directory, orders: orders));
    final assessment = (await twinOf(tester)).result!;

    // UI side: the seller sees who, and the days since their last purchase.
    final row = find.byKey(const Key('risk-item-c-churned'));
    expect(
      find.descendant(of: row, matching: find.text(churnedName)),
      findsOneWidget,
      reason: 'the id→name join must happen in the screen',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('risk-item-c-at-risk')),
        matching: find.text(atRiskName),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.text(const AppStringsEn().daysSincePurchase(380)),
      ),
      findsOneWidget,
    );
    // …and a customer who never bought has no "days since" at all — 0 would be
    // a fabricated fact.
    expect(assessment.entryFor('c-never')!.recencyDays, isNull);

    // Domain side: the object the AI layer and telemetry could see carries the
    // id and numbers only (D-7 / ADR-TON-005 red-line).
    final entry = assessment.entryFor('c-churned')!;
    expect(entry.customerId, 'c-churned');
    for (final pii in const [
      churnedName,
      '+84912345678',
      'khach@example.com',
    ]) {
      expect(entry.toString(), isNot(contains(pii)));
      expect(assessment.toString(), isNot(contains(pii)));
    }
  });

  testWidgets('insufficient data → the honest refusal with its reasons, and '
      'NOT an assessment of zeros', (tester) async {
    // The rule's only refusal today is an empty directory (rendered as the
    // empty state above), so the refusal BRANCH is exercised by handing the
    // screen an insufficient twin — exactly what a future threshold, or a
    // version bump of the rule, would produce.
    await pump(
      tester,
      host(
        customers: directory,
        orders: orders,
        twin: RuleTwinResult<CustomerRiskAssessment>.insufficient(
          reasonCodes: const [ReasonCode.notEnoughHistory],
          version: CustomerRiskRule.version,
          generatedAt: today,
        ),
      ),
    );

    expect(find.byKey(const Key('risk-insufficient')), findsOneWidget);
    expect(riskRows(), findsNothing);
    expect(find.byKey(const Key('risk-summary-at-risk')), findsNothing);
    expect(find.text(const AppStringsEn().riskNoData), findsOneWidget);
    // The user is told WHY, in their language.
    expect(find.text(ReasonCode.notEnoughHistory.label('en')), findsOneWidget);
  });

  testWidgets('reason codes render as localized text, per customer', (
    tester,
  ) async {
    await pump(tester, host(customers: directory, orders: orders));
    final assessment = (await twinOf(tester)).result!;

    expect(
      assessment.entryFor('c-churned')!.reasonCodes,
      contains(ReasonCode.inactiveBeyondChurnWindow),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('risk-item-c-churned')),
        matching: find.text(ReasonCode.inactiveBeyondChurnWindow.label('en')),
      ),
      findsOneWidget,
      reason: 'the row must quote the SAME code the rule emitted',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('risk-item-c-single')),
        matching: find.text(ReasonCode.singlePurchaseOnly.label('en')),
      ),
      findsOneWidget,
    );
  });
}
