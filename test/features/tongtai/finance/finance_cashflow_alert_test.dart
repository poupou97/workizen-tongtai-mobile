import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/finance/finance_summary.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-205 — the negative-cashflow alert sees sales revenue.
///
/// The fourth appearance of the WTM-196 defect: `CashflowSeries
/// .fromTransactions` counted only hand-entered rows. A seller with ten real
/// orders and a few expenses was told *"Dòng tiền âm"* — while Finance, right
/// next door, showed a profit — and the Rule Twin would have had AI explain a
/// deficit that did not exist.
///
/// The fix is one owner, not a second implementation: the series is built by
/// `FinanceService`, the same object that computes the Finance dashboard.
void main() {
  final now = DateTime(2026, 8, 15);

  CustomerOrder order(
    String id, {
    required double amount,
    required DateTime date,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: date,
    status: OrderStatus.delivered,
    items: [
      OrderItem(
        productName: 'SP',
        category: 'Home',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  FinanceTransaction expense(
    String id, {
    required double amount,
    required DateTime date,
  }) => FinanceTransaction(
    id: id,
    type: TransactionType.expense,
    category: FinanceCategory.productCost,
    amount: amount,
    date: date,
  );

  test('a profitable seller is not told their cashflow is in deficit', () {
    // The false alarm, pinned. Sales comfortably exceed expenses every month;
    // the only reason the old series saw a deficit was that it never looked at
    // the orders.
    final service = FinanceService(
      [
        for (var m = 5; m <= 7; m++)
          expense('e$m', amount: 1000000, date: DateTime(2026, m, 10)),
      ],
      orders: [
        for (var m = 5; m <= 7; m++)
          order('o$m', amount: 5000000, date: DateTime(2026, m, 12)),
      ],
    );

    // `negativeCashflow` fires from `monthsInDeficit` (the rule's own contract
    // table); the wiring itself is covered by business_alerts_rule_test.
    expect(
      service.cashflowAsOf(now, months: 3).monthsInDeficit,
      0,
      reason: 'sales 5M/month vs expenses 1M/month is not a deficit',
    );
  });

  test('a genuine deficit still alerts — the alarm was not simply removed', () {
    final service = FinanceService(
      [
        for (var m = 5; m <= 7; m++)
          expense('e$m', amount: 5000000, date: DateTime(2026, m, 10)),
      ],
      orders: [
        for (var m = 5; m <= 7; m++)
          order('o$m', amount: 1000000, date: DateTime(2026, m, 12)),
      ],
    );

    expect(
      service.cashflowAsOf(now, months: 3).monthsInDeficit,
      3,
      reason: 'spending 5M against 1M of sales is a real deficit, every month',
    );
  });

  test('the alert series and the Finance chart agree month by month', () {
    // The cross-check (P-27): FinanceSummary.monthly and the alert's series
    // used to be two machines computing "cashflow per month" — WTM-196 fixed
    // one, the other stood still. Same service, same numbers, by construction
    // — and this test keeps it that way.
    final service = FinanceService(
      [
        expense('e1', amount: 700000, date: DateTime(2026, 6, 5)),
        expense('e2', amount: 900000, date: DateTime(2026, 7, 5)),
      ],
      orders: [
        order('o1', amount: 2000000, date: DateTime(2026, 6, 9)),
        order('o2', amount: 3000000, date: DateTime(2026, 7, 9)),
      ],
      monthsBack: 3,
    );

    final chart = service.summaryAsOf(now).monthly;
    final alertSeries = service.cashflowAsOf(now, excludeCurrentMonth: false);

    for (final point in alertSeries.points) {
      final month = chart.firstWhere(
        (m) => m.year == point.year && m.month == point.month,
      );
      expect(point.income, month.income, reason: 'income ${point.month}');
      expect(point.expense, month.expense, reason: 'expense ${point.month}');
    }
  });

  test('order activity counts as activity', () {
    // `hasTransactions` gates the whole alert. A seller who only records
    // orders — never a hand-typed row — still has a cashflow worth watching.
    final service = FinanceService(
      const [],
      orders: [order('o1', amount: 2000000, date: DateTime(2026, 7, 9))],
    );

    expect(
      service.cashflowAsOf(now, months: 3).hasTransactions,
      isTrue,
      reason: 'ten orders and no typed rows is not "nothing recorded"',
    );
  });
}
