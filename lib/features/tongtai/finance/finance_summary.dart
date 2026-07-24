import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import 'finance_transaction.dart';

/// Income vs. expense booked in one calendar month — a column pair in the
/// Finance cashflow chart (WTM-27).
@immutable
class MonthlyCashflow {
  const MonthlyCashflow({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  final int year;

  /// 1..12.
  final int month;

  final double income;
  final double expense;

  /// Net cashflow that month (may be negative).
  double get net => income - expense;

  /// Short month label, e.g. "Th7" (VI) — the x-axis tick.
  String get shortLabelVi => 'Th$month';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyCashflow &&
          other.year == year &&
          other.month == month &&
          other.income == income &&
          other.expense == expense);

  @override
  int get hashCode => Object.hash(year, month, income, expense);

  @override
  String toString() => 'MonthlyCashflow($year-$month, +$income/-$expense)';
}

/// An amount attributed to one category — a row in the expense breakdown.
@immutable
class CategoryAmount {
  const CategoryAmount({required this.category, required this.amount});

  final String category;
  final double amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryAmount &&
          other.category == category &&
          other.amount == amount);

  @override
  int get hashCode => Object.hash(category, amount);

  @override
  String toString() => 'CategoryAmount($category, $amount)';
}

/// A snapshot of the business's finances for the Finance dashboard (WTM-27).
///
/// All figures are in Vietnamese đồng. Income and expenses are gross positive
/// totals; profit is income − expense.
@immutable
class FinanceSummary {
  const FinanceSummary({
    required this.incomeMtd,
    required this.incomeYtd,
    required this.expenseMtd,
    required this.expenseYtd,
    required this.expenseByCategory,
    required this.monthly,
  });

  final double incomeMtd;
  final double incomeYtd;
  final double expenseMtd;
  final double expenseYtd;

  /// Expense categories, highest first (income excluded).
  final List<CategoryAmount> expenseByCategory;

  /// Income vs. expense per month over the trailing window, oldest first.
  final List<MonthlyCashflow> monthly;

  double get profitMtd => incomeMtd - expenseMtd;
  double get profitYtd => incomeYtd - expenseYtd;

  /// Profit as a share of YTD income (0..1); 0 when there is no income.
  double get marginYtd => incomeYtd <= 0 ? 0 : profitYtd / incomeYtd;

  /// The largest single-month income or expense — the cashflow chart's y-axis
  /// top. 0 when the window is empty.
  double get peakMonthlyFlow => monthly.fold(0, (peak, m) {
    final larger = m.income > m.expense ? m.income : m.expense;
    return larger > peak ? larger : peak;
  });

  /// True once any money has moved this year — the screen shows the empty
  /// state until then.
  bool get hasActivity => incomeYtd > 0 || expenseYtd > 0;

  static const FinanceSummary empty = FinanceSummary(
    incomeMtd: 0,
    incomeYtd: 0,
    expenseMtd: 0,
    expenseYtd: 0,
    expenseByCategory: [],
    monthly: [],
  );
}

/// Aggregates [FinanceTransaction]s into a [FinanceSummary] (WTM-27).
///
/// Pure Dart over the in-memory transaction list — no database, no `intl`, no
/// clock of its own (the caller passes `now`) — so every figure is
/// deterministically unit-testable, mirroring [ReportsService].
class FinanceService {
  FinanceService(List<FinanceTransaction> transactions, {this.monthsBack = 6})
    : assert(monthsBack > 0, 'monthsBack must be positive'),
      _txns = List.unmodifiable(transactions);

  /// Seeded with the built-in sample transactions.
  factory FinanceService.sample({int monthsBack = 6}) =>
      FinanceService(kSampleTransactions, monthsBack: monthsBack);

  final List<FinanceTransaction> _txns;

  /// How many trailing months the cashflow chart spans (inclusive of `now`).
  final int monthsBack;

  /// The [limit] most recent transactions, newest first — the dashboard's
  /// activity feed.
  List<FinanceTransaction> recent({int limit = 6}) {
    final sorted = [..._txns]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Builds the dashboard snapshot as of [now].
  FinanceSummary summaryAsOf(DateTime now) {
    final mtd = _txns
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList(growable: false);
    final ytd = _txns
        .where((t) => t.date.year == now.year)
        .toList(growable: false);

    return FinanceSummary(
      incomeMtd: _sum(mtd, TransactionType.income),
      incomeYtd: _sum(ytd, TransactionType.income),
      expenseMtd: _sum(mtd, TransactionType.expense),
      expenseYtd: _sum(ytd, TransactionType.expense),
      expenseByCategory: _expenseByCategory(ytd),
      monthly: _monthlySeries(now),
    );
  }

  double _sum(Iterable<FinanceTransaction> txns, TransactionType type) =>
      txns.where((t) => t.type == type).fold(0, (total, t) => total + t.amount);

  /// [monthsBack] consecutive months ending with `now`'s month, oldest first.
  /// `DateTime` normalises month underflow, so December of the prior year is
  /// handled without special-casing.
  List<MonthlyCashflow> _monthlySeries(DateTime now) {
    return [
      for (var i = monthsBack - 1; i >= 0; i--)
        () {
          final anchor = DateTime(now.year, now.month - i);
          final inMonth = _txns.where(
            (t) => t.date.year == anchor.year && t.date.month == anchor.month,
          );
          return MonthlyCashflow(
            year: anchor.year,
            month: anchor.month,
            income: _sum(inMonth, TransactionType.income),
            expense: _sum(inMonth, TransactionType.expense),
          );
        }(),
    ];
  }

  /// Per-category YTD expense totals, highest first (income excluded).
  List<CategoryAmount> _expenseByCategory(List<FinanceTransaction> ytd) {
    final byCategory = <String, double>{};
    for (final t in ytd.where((t) => t.isExpense)) {
      byCategory.update(
        t.category,
        (running) => running + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    return byCategory.entries
        .map((e) => CategoryAmount(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}
