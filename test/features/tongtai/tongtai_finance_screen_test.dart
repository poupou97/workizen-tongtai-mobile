import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_controller.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_finance_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_transaction_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';

/// WTM-27 — the Finance dashboard renders income/expense/profit/margin KPIs, a
/// cashflow chart, the expense breakdown and a recent-activity feed from the
/// injected ledger at a fixed clock.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  Widget host({FinanceController? controller}) => MaterialApp(
    home: TongtaiFinanceScreen(
      controller: controller ?? FinanceController.sample(),
      clock: fixedNow,
    ),
  );

  testWidgets('shows the four KPI cards with the right figures', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.byKey(const Key('finance-kpi-income')), findsOneWidget);
    expect(find.byKey(const Key('finance-kpi-expense')), findsOneWidget);
    expect(find.byKey(const Key('finance-kpi-profit')), findsOneWidget);
    expect(find.byKey(const Key('finance-kpi-margin')), findsOneWidget);

    // Income 24.560.000, expense 18.020.000, profit 6.540.000, margin 27%.
    expect(find.text('24.560.000 ₫'), findsOneWidget);
    expect(find.text('18.020.000 ₫'), findsOneWidget);
    expect(find.text('6.540.000 ₫'), findsOneWidget);
    expect(find.text('27%'), findsOneWidget);
  });

  testWidgets('renders the cashflow chart with month ticks', (tester) async {
    await tester.pumpWidget(host());

    expect(find.byKey(const Key('finance-cashflow-chart')), findsOneWidget);
    expect(find.text('Th7'), findsOneWidget);
    expect(find.text('Th2'), findsOneWidget);
    // Legend labels.
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
  });

  testWidgets('lists the expense categories, largest first', (tester) async {
    await tester.pumpWidget(host());

    await tester.scrollUntilVisible(
      find.text('Nhập hàng'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nhập hàng'), findsOneWidget);
    // Nhập hàng leads at 12.900.000 ₫ · 72% of 18.020.000.
    expect(find.textContaining('12.900.000 ₫'), findsOneWidget);
  });

  testWidgets('empty ledger shows the fox empty state, no KPIs', (
    tester,
  ) async {
    await tester.pumpWidget(host(controller: FinanceController([])));

    expect(find.byType(TongtaiFoxMascot), findsOneWidget);
    expect(find.text('Chưa có giao dịch tài chính'), findsOneWidget);
    expect(find.byKey(const Key('finance-kpi-income')), findsNothing);
  });

  testWidgets('the More menu opens the Finance dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TongtaiMoreScreen())),
    );

    final entry = find.text('Finance · Tài chính');
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiFinanceScreen), findsOneWidget);
  });

  testWidgets('the FAB opens the transaction form (WTM-113)', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.byKey(const Key('finance-add')));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiTransactionFormScreen), findsOneWidget);
  });

  testWidgets('adding a transaction updates the dashboard live (WTM-113)', (
    tester,
  ) async {
    final controller = FinanceController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller: controller));

    // Empty ledger → empty state, no KPIs.
    expect(find.text('Chưa có giao dịch tài chính'), findsOneWidget);

    controller.add(
      FinanceTransaction(
        id: 'x1',
        type: TransactionType.income,
        category: 'Bán hàng',
        amount: 3000000,
        date: DateTime(2026, 7, 10),
      ),
    );
    await tester.pump();

    expect(find.text('Chưa có giao dịch tài chính'), findsNothing);
    // The income KPI card now shows the added amount (profit shows it too, so
    // scope the match to the income card).
    expect(
      find.descendant(
        of: find.byKey(const Key('finance-kpi-income')),
        matching: find.text('3.000.000 ₫'),
      ),
      findsOneWidget,
    );
  });
}
