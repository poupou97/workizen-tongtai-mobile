import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/analytics/cashflow_series.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';

/// WTM-149 — [CashflowSeries] is the Aggregation Service the Finance context
/// and the `negativeCashflow` alert read. It shares the month-bucketing helper
/// with `RevenueSeries`, so "July" means the same thing in both.
void main() {
  final now = DateTime(2026, 7, 15);

  var nextId = 0;
  FinanceTransaction money(TransactionType type, DateTime date, double amount) {
    nextId += 1;
    return FinanceTransaction(
      id: 't$nextId',
      type: type,
      category: type == TransactionType.income
          ? FinanceCategory.sales
          : FinanceCategory.productCost,
      amount: amount,
      date: date,
    );
  }

  FinanceTransaction income(DateTime date, double amount) =>
      money(TransactionType.income, date, amount);
  FinanceTransaction expense(DateTime date, double amount) =>
      money(TransactionType.expense, date, amount);

  setUp(() => nextId = 0);

  group('fromTransactions — monthly income / expense / profit', () {
    late CashflowSeries series;

    setUp(() {
      // Window (months: 3, current excluded, now = 15 Jul 2026) → Apr, May, Jun.
      series = CashflowSeries.fromTransactions(
        [
          expense(DateTime(2026, 3, 31), 700000), // before the window
          income(DateTime(2026, 4, 10), 1000000),
          expense(DateTime(2026, 4, 12), 400000),
          // May: nothing recorded
          expense(DateTime(2026, 6, 3), 500000),
          income(DateTime(2026, 7, 2), 9000000), // running month, excluded
        ],
        now: now,
        months: 3,
      );
    });

    test('each month carries its own income, expense and profit', () {
      expect(series.length, 3);

      final april = series.points[0];
      expect(april.month, 4);
      expect(april.income, 1000000);
      expect(april.expense, 400000);
      expect(april.profit, 600000);
      expect(april.transactionCount, 2);
      expect(april.isDeficit, isFalse);

      final june = series.points[2];
      expect(june.month, 6);
      expect(june.income, 0);
      expect(june.expense, 500000);
      expect(june.profit, -500000);
      expect(june.isDeficit, isTrue);
    });

    test('a month with nothing recorded is an explicit zero point', () {
      final may = series.points[1];
      expect(may.month, 5);
      expect(may.income, 0);
      expect(may.expense, 0);
      expect(may.profit, 0);
      expect(may.transactionCount, 0);
      expect(may.isEmpty, isTrue);
      expect(may.isDeficit, isFalse); // flat is not a deficit
    });

    test('totals cover the window only', () {
      expect(series.totalIncome, 1000000); // the 9M July income is excluded
      expect(series.totalExpense, 900000); // the 700k March expense is excluded
      expect(series.totalProfit, 100000);
      expect(series.monthsInDeficit, 1);
      expect(series.hasTransactions, isTrue);
      expect(series.currentMonthExcluded, isTrue);
      expect(series.latest!.month, 6);
    });

    test('profit MoM is null when the earlier month was flat zero', () {
      expect(series.profitMonthOverMonthChange, isNull); // May profit = 0
    });
  });

  test('excludeCurrentMonth: false keeps the running month', () {
    final series = CashflowSeries.fromTransactions(
      [income(DateTime(2026, 7, 2), 9000000)],
      now: now,
      months: 1,
      excludeCurrentMonth: false,
    );

    expect(series.points.single.month, 7);
    expect(series.points.single.income, 9000000);
    expect(series.currentMonthExcluded, isFalse);
  });

  test(
    'month boundaries: 1st 00:00 and last day 23:59 stay in their month',
    () {
      final series = CashflowSeries.fromTransactions(
        [
          income(DateTime(2026, 6, 1, 0, 0), 100),
          income(DateTime(2026, 6, 30, 23, 59, 59), 200),
          income(DateTime(2026, 5, 31, 23, 59, 59), 400),
        ],
        now: now,
        months: 2,
      );

      expect(series.points[0].month, 5);
      expect(series.points[0].income, 400);
      expect(series.points[1].month, 6);
      expect(series.points[1].income, 300);
    },
  );

  test('trailing profit average and MoM on a hand-computed fixture', () {
    // now = 15 Jun 2026, months: 2, current excluded → Apr, May.
    final series = CashflowSeries.fromTransactions(
      [
        income(DateTime(2026, 4, 10), 1000000),
        expense(DateTime(2026, 4, 12), 400000), // Apr profit = 600 000
        income(DateTime(2026, 5, 10), 800000),
        expense(DateTime(2026, 5, 12), 500000), // May profit = 300 000
      ],
      now: DateTime(2026, 6, 15),
      months: 2,
    );

    expect(series.profits, [600000, 300000]);
    expect(series.trailingAverageProfit(2), 450000);
    expect(series.trailingAverageProfit(1), 300000);
    expect(series.trailingAverageProfit(0), 0);
    // (300 000 − 600 000) / 600 000 = −0.5
    expect(series.profitMonthOverMonthChange, closeTo(-0.5, 1e-12));
  });

  group('empty / degenerate input', () {
    test('no transactions still emits the full window as zeros', () {
      final series = CashflowSeries.fromTransactions(const [], now: now);

      expect(series.length, 12);
      expect(series.points.every((p) => p.isEmpty), isTrue);
      expect(series.totalIncome, 0);
      expect(series.totalExpense, 0);
      expect(series.totalProfit, 0);
      expect(series.monthsInDeficit, 0);
      expect(series.hasTransactions, isFalse);
      expect(series.profitMonthOverMonthChange, isNull);
      expect(series.trailingAverageProfit(3), 0);
    });

    test('non-positive months → empty, well-formed series', () {
      final series = CashflowSeries.fromTransactions(
        [income(DateTime(2026, 6, 1), 100)],
        now: now,
        months: 0,
      );

      expect(series.isEmpty, isTrue);
      expect(series.latest, isNull);
      expect(series.totalProfit, 0);
      expect(CashflowSeries.empty.isEmpty, isTrue);
      expect(CashflowSeries.empty.totalProfit, 0);
    });
  });
}
