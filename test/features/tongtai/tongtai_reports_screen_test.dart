import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/reports/business_report.dart';
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
    expect(find.text('4 đơn'), findsOneWidget);
  });

  testWidgets('opportunity pipeline card renders count + value (WTM-98)', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('reports-pipeline'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.descendant(of: card, matching: find.text('5')), findsOneWidget);
    expect(find.text('160tr ₫'), findsOneWidget);
    expect(find.text('Quạt tích điện sắp vào mùa nóng'), findsOneWidget);
  });

  testWidgets('empty order book shows the fox empty state, no KPIs', (
    tester,
  ) async {
    await tester.pumpWidget(host(service: ReportsService([])));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiFoxMascot), findsOneWidget);
    expect(find.text('Chưa có doanh thu để báo cáo'), findsOneWidget);
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
        ],
        child: const MaterialApp(home: TongtaiMoreScreen()),
      ),
    );

    final entry = find.text('Reports & Analytics · Báo cáo');
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiReportsScreen), findsOneWidget);
    // Empty repositories → User Data First empty state.
    expect(find.text('Chưa có doanh thu để báo cáo'), findsOneWidget);
  });
}
