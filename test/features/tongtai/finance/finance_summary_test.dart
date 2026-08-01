import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_summary.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';

/// WTM-27 — the Finance aggregator turns transactions into dashboard figures.
/// Sample fixtures are fixed and dated, so with an injected `now` every figure
/// is an exact number.
void main() {
  final now = DateTime(2026, 7, 24);

  FinanceTransaction txn(
    String id,
    TransactionType type,
    FinanceCategory category,
    double amount,
    DateTime date,
  ) => FinanceTransaction(
    id: id,
    type: type,
    category: category,
    amount: amount,
    date: date,
  );

  group('FinanceService over the sample transactions', () {
    final summary = FinanceService.sample().summaryAsOf(now);

    test('YTD income, expense and profit', () {
      expect(summary.incomeYtd, 24560000);
      expect(summary.expenseYtd, 18020000);
      expect(summary.profitYtd, 6540000);
    });

    test('YTD margin is profit over income', () {
      expect(summary.marginYtd, closeTo(6540000 / 24560000, 1e-9));
    });

    test('MTD (July) income, expense and profit', () {
      expect(summary.incomeMtd, 3660000);
      expect(summary.expenseMtd, 2850000);
      expect(summary.profitMtd, 810000);
    });

    test('has activity, so the dashboard renders', () {
      expect(summary.hasActivity, isTrue);
    });

    test('expense-by-category is ordered high→low and excludes income', () {
      final cats = summary.expenseByCategory;
      // Codes, not labels (WTM-197): grouping by the display string made two
      // spellings of one idea into two rows.
      expect(cats.map((c) => c.category), [
        FinanceCategory.productCost.code,
        FinanceCategory.rent.code,
        FinanceCategory.marketing.code,
        FinanceCategory.shipping.code,
        FinanceCategory.platformFee.code,
      ]);
      expect(cats.map((c) => c.amount), [
        12900000,
        3000000,
        1220000,
        600000,
        300000,
      ]);
      // No income category ("Bán hàng") leaks into the expense breakdown.
      expect(
        cats.any((c) => c.category == FinanceCategory.sales.code),
        isFalse,
      );
      // Category totals reconcile with total YTD expense.
      expect(cats.fold<double>(0, (s, c) => s + c.amount), summary.expenseYtd);
    });

    test('monthly cashflow is the trailing six months, oldest first', () {
      final m = summary.monthly;
      expect(m, hasLength(6));
      expect(m.map((e) => '${e.year}-${e.month}'), [
        '2026-2',
        '2026-3',
        '2026-4',
        '2026-5',
        '2026-6',
        '2026-7',
      ]);
      expect(m.map((e) => e.income), [
        3200000,
        4100000,
        3800000,
        4600000,
        5200000,
        3660000,
      ]);
      expect(m.map((e) => e.expense), [
        2300000,
        3050000,
        2800000,
        3320000,
        3700000,
        2850000,
      ]);
      // June is the peak flow (5.2M income).
      expect(summary.peakMonthlyFlow, 5200000);
      // Net cashflow reconciles.
      expect(m.first.net, 900000);
    });
  });

  group('FinanceService edge cases', () {
    test('an empty ledger yields the empty-state summary', () {
      final summary = FinanceService([]).summaryAsOf(now);
      expect(summary.hasActivity, isFalse);
      expect(summary.incomeYtd, 0);
      expect(summary.expenseYtd, 0);
      expect(summary.profitYtd, 0);
      expect(summary.marginYtd, 0);
      expect(summary.expenseByCategory, isEmpty);
      expect(summary.monthly, hasLength(6));
      expect(summary.peakMonthlyFlow, 0);
    });

    test('the window crosses the year boundary correctly', () {
      final service = FinanceService([
        txn(
          'a',
          TransactionType.income,
          FinanceCategory.sales,
          1000000,
          DateTime(2025, 12, 10),
        ),
        txn(
          'b',
          TransactionType.income,
          FinanceCategory.sales,
          2000000,
          DateTime(2026, 1, 9),
        ),
        txn(
          'c',
          TransactionType.expense,
          FinanceCategory.productCost,
          800000,
          DateTime(2026, 1, 12),
        ),
      ], monthsBack: 3);

      final summary = service.summaryAsOf(DateTime(2026, 1, 20));
      expect(summary.monthly.map((e) => '${e.year}-${e.month}'), [
        '2025-11',
        '2025-12',
        '2026-1',
      ]);
      // YTD is 2026 only — December 2025 income is excluded.
      expect(summary.incomeYtd, 2000000);
      expect(summary.expenseYtd, 800000);
      expect(summary.profitYtd, 1200000);
    });
  });
}
