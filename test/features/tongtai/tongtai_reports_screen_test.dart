import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/reports/business_report.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';

/// WTM-95/96 — the Reports dashboard renders KPIs, the revenue chart and the
/// category breakdown from the injected service at a fixed clock.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  Widget host({ReportsService? service}) => MaterialApp(
    home: TongtaiReportsScreen(
      service: service ?? ReportsService.sample(),
      clock: fixedNow,
    ),
  );

  testWidgets('shows the four headline KPI cards with formatted đồng values', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.byKey(const Key('reports-kpi-revenue-mtd')), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-revenue-ytd')), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-orders')), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-aov')), findsOneWidget);

    // MTD 848.000, YTD 4.058.000, 7 orders (from the sample fixtures).
    expect(find.text('848.000 ₫'), findsOneWidget);
    expect(find.text('4.058.000 ₫'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('renders the revenue trend chart and its month ticks', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.byKey(const Key('reports-revenue-chart')), findsOneWidget);
    // Six month ticks, current month included.
    expect(find.text('Th7'), findsOneWidget);
    expect(find.text('Th2'), findsOneWidget);
  });

  testWidgets('lists the top categories, highest first', (tester) async {
    await tester.pumpWidget(host());

    // The categories card sits below the fold; scroll it into view (the
    // ListView builds its slivers lazily).
    await tester.scrollUntilVisible(
      find.text('Home'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Fashion'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    // Home leads at 1.970.000 ₫ · 49% of 4.058.000.
    expect(find.textContaining('1.970.000 ₫'), findsOneWidget);
  });

  testWidgets('top products + customers rank widgets render (WTM-97)', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.byKey(const Key('reports-top-products')),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Nồi chiên không dầu'), findsOneWidget); // #1 product

    await tester.scrollUntilVisible(
      find.byKey(const Key('reports-top-customers')),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Thu Hà'), findsOneWidget); // #1 customer
    expect(find.text('4 đơn'), findsOneWidget);
  });

  testWidgets('opportunity pipeline card renders count + value (WTM-98)', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    final card = find.byKey(const Key('reports-pipeline'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // Active count "5" — scoped to the card (rank chips elsewhere also show 5).
    expect(find.descendant(of: card, matching: find.text('5')), findsOneWidget);
    expect(find.text('160tr ₫'), findsOneWidget); // combined pipeline value
    expect(find.text('Quạt tích điện sắp vào mùa nóng'), findsOneWidget); // top
  });

  testWidgets('empty order book shows the fox empty state, no KPIs', (
    tester,
  ) async {
    await tester.pumpWidget(host(service: ReportsService([])));

    expect(find.byType(TongtaiFoxMascot), findsOneWidget);
    expect(find.text('Chưa có doanh thu để báo cáo'), findsOneWidget);
    expect(find.byKey(const Key('reports-kpi-revenue-mtd')), findsNothing);
  });

  testWidgets('the More menu opens the Reports dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TongtaiMoreScreen())),
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
  });
}
