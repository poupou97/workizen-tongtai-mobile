import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_recommendation.dart';
import 'package:tongtai/features/tongtai/ai/business_summary.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
import 'package:tongtai/features/tongtai/consumer/customer_context.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_context.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context_service.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/reports/business_report.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_context.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';

/// WTM-95/96 — the Reports dashboard renders KPIs, the revenue chart and the
/// category breakdown. WTM-127 — the four headline KPIs come from the KPI source
/// of truth (BusinessMetricsService); the screen derives them from the injected
/// service's orders under test.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  Widget host({ReportsService? service}) => ProviderScope(
    child: MaterialApp(
      home: TongtaiReportsScreen(
        service: service ?? ReportsService.sample(),
        clock: fixedNow,
      ),
    ),
  );

  testWidgets('shows the four canonical KPI cards from BusinessMetrics', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reports-kpi-revenue')), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-orders')), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-customers')), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-aov')), findsOneWidget);

    // Sample fixtures: 7 billable orders (one cancelled), 4.058.000 ₫ revenue,
    // across 3 distinct customers.
    expect(
      find.descendant(
        of: find.byKey(const Key('reports-kpi-revenue')),
        matching: find.text('4.058.000 ₫'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('reports-kpi-orders')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('reports-kpi-customers')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the revenue trend chart and its month ticks', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // The AI card (G-3A/B/C) sits above the chart — bring the chart into the
    // lazy ListView's viewport first.
    await tester.scrollUntilVisible(
      find.byKey(const Key('reports-revenue-chart')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('reports-revenue-chart')), findsOneWidget);
    expect(find.text('Th7'), findsOneWidget);
    expect(find.text('Th2'), findsOneWidget);
  });

  testWidgets('lists the top categories, highest first', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Home'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Fashion'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    expect(find.textContaining('1.970.000 ₫'), findsOneWidget);
  });

  testWidgets('top products + customers rank widgets render (WTM-97)', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.byKey(const Key('reports-top-products')),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Nồi chiên không dầu'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('reports-top-customers')),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Thu Hà'), findsOneWidget);
    expect(find.text('4 orders'), findsOneWidget);
  });

  testWidgets('opportunity pipeline card renders count + value (WTM-98)', (
    tester,
  ) async {
    // One-source (WTM-144): the screen no longer falls back to samples —
    // fixtures are injected explicitly.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiReportsScreen(
            service: ReportsService.sample(),
            clock: fixedNow,
            opportunities: kSampleOpportunities,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('reports-pipeline'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.descendant(of: card, matching: find.text('5')), findsOneWidget);
    expect(find.text('160tr ₫'), findsOneWidget);
    // WTM-193: the headline is whichever opportunity the **real** scoring
    // function ranks highest, computed here rather than written by hand — a
    // test that pins a title pins the old constant score behind it.
    final top = kSampleOpportunities.reduce(
      (a, b) => (a.score.value ?? -1) >= (b.score.value ?? -1) ? a : b,
    );
    expect(find.text(top.title), findsOneWidget);
  });

  testWidgets('the period selector scopes the breakdown sections (WTM-115)', (
    tester,
  ) async {
    // One category sold in June, another in July; "today" is Jul 24.
    CustomerOrder o(String id, DateTime date, String category, double price) =>
        CustomerOrder(
          id: id,
          customerId: 'c1',
          orderNumber: id,
          date: date,
          status: OrderStatus.delivered,
          items: [
            OrderItem(
              productName: '$category-item',
              category: category,
              quantity: 1,
              unitPrice: price,
            ),
          ],
        );
    final service = ReportsService([
      o('jun', DateTime(2026, 6, 10), 'JuneCat', 400000),
      o('jul', DateTime(2026, 7, 10), 'JulyCat', 600000),
    ]);

    await tester.pumpWidget(host(service: service));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;

    // Default this-year → both categories present.
    await tester.scrollUntilVisible(
      find.text('JuneCat'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('JuneCat'), findsOneWidget);
    expect(find.text('JulyCat'), findsOneWidget);

    // Scope to this month → only July's category remains.
    await tester.scrollUntilVisible(
      find.byKey(const Key('reports-period-thisMonth')),
      -300,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const Key('reports-period-thisMonth')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('JulyCat'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('JulyCat'), findsOneWidget);
    expect(find.text('JuneCat'), findsNothing);
  });

  testWidgets(
    'AI summary card: tap → deterministic rule-based summary when AI is off '
    '(WTM-116 / G-3A)',
    (tester) async {
      // A real BusinessSummaryService with an in-memory context (1 order, 1
      // customer) and NO provider keys → the deterministic rule-based path.
      DateTime clock() => DateTime(2026, 7, 24);
      final orderRepo = InMemoryOrderRepository([
        CustomerOrder(
          id: 'o1',
          customerId: 'c1',
          orderNumber: 'DH-o1',
          date: DateTime(2026, 7, 10),
          status: OrderStatus.delivered,
          items: const [
            OrderItem(
              productName: 'X',
              category: 'Home',
              quantity: 1,
              unitPrice: 500000,
            ),
          ],
        ),
      ]);
      final customerRepo = InMemoryCustomerRepository([]);
      final goalRepo = InMemoryBusinessGoalRepository();
      final financeRepo = InMemoryFinanceRepository();
      final contextService = BusinessContextService(
        BusinessMetricsService(orderRepo, customerRepo),
        CustomerContextProvider(customerRepo),
        OrderContextProvider(orderRepo),
        InventoryContextProvider(InMemoryProductRepository([])),
        OpportunityContextProvider(clock: clock),
        JourneyContextProvider(goalRepo, clock: clock),
        FinanceContextProvider(financeRepo, clock: clock),
        TimelineContextProvider(financeRepo, orderRepo, goalRepo, clock: clock),
        clock: clock,
      );
      final summaryService = BusinessSummaryService(
        TongtaiAiService(InMemoryTongtaiAiKeyStore()), // no keys → rule path
        contextService,
        clock: clock,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TongtaiReportsScreen(
              service: ReportsService.sample(),
              clock: clock,
              summaryService: summaryService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reports-ai-summary')), findsOneWidget);
      await tester.tap(find.byKey(const Key('reports-ai-summary-run')));
      await tester.pumpAndSettle();

      // Rule-based summary rendered with its provenance chip.
      expect(find.byKey(const Key('reports-ai-summary-text')), findsOneWidget);
      expect(find.text('Rule-based'), findsOneWidget);
      expect(find.textContaining('500.000 ₫'), findsWidgets);

      // G-3B (WTM-135): the Recommend action shares the card — rule twin
      // renders actionable suggestions with the same provenance chip.
      final recommendationService = BusinessRecommendationService(
        TongtaiAiService(InMemoryTongtaiAiKeyStore()), // no keys → rule path
        contextService,
        clock: clock,
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TongtaiReportsScreen(
              service: ReportsService.sample(),
              clock: clock,
              summaryService: summaryService,
              recommendationService: recommendationService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reports-ai-recommend-run')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reports-ai-summary-text')), findsOneWidget);
      expect(find.text('Rule-based'), findsOneWidget);
      expect(find.textContaining('Recommendations'), findsWidgets);
    },
  );

  testWidgets('empty order book shows the fox empty state, no KPIs', (
    tester,
  ) async {
    await tester.pumpWidget(host(service: ReportsService([])));
    await tester.pumpAndSettle();

    // Scoped to the empty state (WTM-216 added a header fox) — the claim is
    // "the empty state greets you with the fox", not "one fox exists".
    expect(
      find.descendant(
        of: find.byKey(const Key('reports-empty')),
        matching: find.byType(TongtaiFoxMascot),
      ),
      findsOneWidget,
    );
    expect(find.text('No revenue to report yet'), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-revenue')), findsNothing);
  });

  testWidgets('the More menu opens the Reports dashboard (real, empty)', (
    tester,
  ) async {
    // The real (no-service) Reports screen loads from the repositories; override
    // them with empty in-memory sources so it stays off the real Drift database.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
          customerRepositoryProvider.overrideWithValue(
            InMemoryCustomerRepository(),
          ),
          // The generated-opportunities source (WTM-139) also reads these.
          productRepositoryProvider.overrideWithValue(
            InMemoryProductRepository([]),
          ),
          businessGoalRepositoryProvider.overrideWithValue(
            InMemoryBusinessGoalRepository(),
          ),
        ],
        child: const MaterialApp(home: TongtaiMoreScreen()),
      ),
    );

    final entry = find.text('Reports & Analytics');
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiReportsScreen), findsOneWidget);
    // Empty repositories → User Data First empty state.
    expect(find.text('No revenue to report yet'), findsOneWidget);
  });
}
