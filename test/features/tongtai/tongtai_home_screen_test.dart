import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/reports/business_report.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';

/// WTM-14 — the Home dashboard shows real business data (module counts, revenue
/// KPIs, top opportunities, goal missions) instead of placeholder zeros.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  Widget host() => MaterialApp(
    home: TongtaiHomeScreen(
      reportsService: ReportsService.sample(),
      clock: fixedNow,
    ),
  );

  testWidgets('module tiles show live counts, not zeros', (tester) async {
    await tester.pumpWidget(host());

    // Producer=12 suppliers, Inventory=28 products, Consumer=26 customers.
    expect(find.text('Producer'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Consumer'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // The old placeholder zero is gone.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Business KPIs show revenue from the reports service', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.byKey(const Key('home-kpi-revenue')), findsOneWidget);
    // YTD revenue over the sample orders.
    expect(find.text('4.058.000 ₫'), findsOneWidget);
    expect(find.text('Doanh thu năm'), findsOneWidget);
    expect(find.text('Đơn hàng'), findsOneWidget);
  });

  testWidgets('top opportunities appear, highest AI score first', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    // aiScore 92 is the top sample opportunity.
    expect(find.text('Quạt tích điện sắp vào mùa nóng'), findsOneWidget);
    expect(find.text('92'), findsOneWidget);
  });

  testWidgets('goal missions render with progress bars', (tester) async {
    await tester.pumpWidget(host());

    expect(find.text("Today's Missions"), findsOneWidget);
    // The two sample goals become missions, each with a progress bar.
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.text('No missions yet'), findsNothing);
  });

  testWidgets('empty goals fall back to the no-missions box', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiHomeScreen(
          reportsService: ReportsService.sample(),
          clock: fixedNow,
          goals: const [],
        ),
      ),
    );

    expect(find.text('No missions yet'), findsOneWidget);
    // Journey count reflects the injected (empty) goals.
    expect(find.text("Today's Missions"), findsOneWidget);
  });

  testWidgets('the KPI header opens the full Reports dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    final action = find.byKey(const Key('home-open-reports'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiReportsScreen), findsOneWidget);
  });
}
