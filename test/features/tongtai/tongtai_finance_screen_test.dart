import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_controller.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_finance_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_transaction_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';

/// WTM-27/113/120 — the Finance dashboard renders KPIs/chart/breakdown/feed from
/// its controller (hydrated from the repository) and persists new entries.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  /// Pumps the screen and lets the async hydrate() complete.
  Future<void> pump(
    WidgetTester tester, {
    FinanceController? controller,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiFinanceScreen(
            controller: controller ?? FinanceController.sample(),
            clock: fixedNow,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the four KPI cards with the right figures', (
    tester,
  ) async {
    await pump(tester);

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
    await pump(tester);

    expect(find.byKey(const Key('finance-cashflow-chart')), findsOneWidget);
    expect(find.text('Th7'), findsOneWidget);
    expect(find.text('Th2'), findsOneWidget);
    // In EN the legend labels (txnIncome/txnExpense) match the KPI card labels
    // (kpiIncome/kpiExpense), so each appears twice: KPI card + legend.
    expect(find.text('Income'), findsNWidgets(2));
    expect(find.text('Expense'), findsNWidgets(2));
  });

  testWidgets('lists the expense categories, largest first', (tester) async {
    await pump(tester);

    await tester.scrollUntilVisible(
      find.text('Nhập hàng'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nhập hàng'), findsOneWidget);
    expect(find.textContaining('12.900.000 ₫'), findsOneWidget);
  });

  testWidgets('empty ledger shows the fox empty state, no KPIs', (
    tester,
  ) async {
    await pump(tester, controller: FinanceController.inMemory());

    expect(find.byType(TongtaiFoxMascot), findsOneWidget);
    expect(find.text('No financial transactions yet'), findsOneWidget);
    expect(find.byKey(const Key('finance-kpi-income')), findsNothing);
  });

  testWidgets('the More menu opens the Finance dashboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Keep the dashboard off the real Drift database in the nav test.
        overrides: [
          financeRepositoryProvider.overrideWithValue(
            InMemoryFinanceRepository(),
          ),
        ],
        child: const MaterialApp(home: TongtaiMoreScreen()),
      ),
    );

    final entry = find.text('Finance');
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
    await pump(tester);

    await tester.tap(find.byKey(const Key('finance-add')));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiTransactionFormScreen), findsOneWidget);
  });

  testWidgets('adding a transaction updates the dashboard live (WTM-113)', (
    tester,
  ) async {
    final controller = FinanceController.inMemory();
    addTearDown(controller.dispose);
    await pump(tester, controller: controller);

    // Empty ledger → empty state, no KPIs.
    expect(find.text('No financial transactions yet'), findsOneWidget);

    await controller.add(
      FinanceTransaction(
        id: 'x1',
        type: TransactionType.income,
        category: 'Bán hàng',
        amount: 3000000,
        date: DateTime(2026, 7, 10),
      ),
    );
    await tester.pump();

    expect(find.text('No financial transactions yet'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('finance-kpi-income')),
        matching: find.text('3.000.000 ₫'),
      ),
      findsOneWidget,
    );
  });
}
