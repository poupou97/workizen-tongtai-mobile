import 'package:flutter/foundation.dart';

import '../analytics/cashflow_series.dart';
import '../analytics/month_bucket.dart';
import '../consumer/customer_order.dart';
import '../core/tongtai_enums.dart';
import '../metrics/business_metrics.dart' show BillableOrders;
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
    this.salesIncomeMtd = 0,
    this.salesIncomeYtd = 0,
  });

  final double incomeMtd;
  final double incomeYtd;
  final double expenseMtd;
  final double expenseYtd;

  /// The part of [incomeMtd] / [incomeYtd] that comes from **orders** rather
  /// than hand-entered rows (WTM-196).
  ///
  /// Before this, Finance counted only what the seller typed in, so a shop with
  /// ten recorded orders opened Finance and read **₫0 income** while Home and
  /// Reports showed real revenue — two authoritative-looking answers to *"how
  /// much did I make"*.
  ///
  /// Kept as its own figure rather than folded in silently: the seller should
  /// be able to see which part of their income the app worked out and which
  /// part they told it.
  final double salesIncomeMtd;
  final double salesIncomeYtd;

  /// Income the seller entered by hand — everything that did not come from an
  /// order (a refund, a side job, an owner top-up).
  double get manualIncomeMtd => incomeMtd - salesIncomeMtd;
  double get manualIncomeYtd => incomeYtd - salesIncomeYtd;

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
    salesIncomeMtd: 0,
    salesIncomeYtd: 0,
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
  FinanceService(
    List<FinanceTransaction> transactions, {
    List<CustomerOrder> orders = const [],
    this.monthsBack = 6,
  }) : assert(monthsBack > 0, 'monthsBack must be positive'),
       _txns = List.unmodifiable(transactions),
       // Billable only — the same shared rule Home and Reports use, so the two
       // sides cannot drift apart on what counts as a sale (WTM-196).
       _sales = List.unmodifiable(orders.billable);

  /// Seeded with the built-in sample transactions.
  factory FinanceService.sample({int monthsBack = 6}) =>
      FinanceService(kSampleTransactions, monthsBack: monthsBack);

  final List<FinanceTransaction> _txns;

  /// Billable orders. **Read, never written**: sales revenue is derived from
  /// orders on every read rather than copied into a `FinanceTransaction`.
  ///
  /// Copying would be the parallel record One Data Path (ADR-TON-015) forbids —
  /// edit the order and the money row drifts, delete it and the money row is
  /// orphaned, and `.ttbk` would carry the same fact twice.
  final List<CustomerOrder> _sales;

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

    final salesMtd = salesIn(year: now.year, month: now.month);
    final salesYtd = salesIn(year: now.year);

    return FinanceSummary(
      incomeMtd: _sum(mtd, TransactionType.income) + salesMtd,
      incomeYtd: _sum(ytd, TransactionType.income) + salesYtd,
      salesIncomeMtd: salesMtd,
      salesIncomeYtd: salesYtd,
      expenseMtd: _sum(mtd, TransactionType.expense),
      expenseYtd: _sum(ytd, TransactionType.expense),
      expenseByCategory: _expenseByCategory(ytd),
      monthly: _monthlySeries(now),
    );
  }

  /// Revenue from billable orders in a year, or in one month of it.
  double salesIn({required int year, int? month}) => _sales
      .where(
        (o) => o.date.year == year && (month == null || o.date.month == month),
      )
      .fold(0.0, (total, o) => total + o.totalAmount);

  /// Billable orders in one month — the activity count the cashflow series
  /// reports alongside the money (WTM-205).
  int salesCountIn({required int year, required int month}) =>
      _sales.where((o) => o.date.year == year && o.date.month == month).length;

  /// Hand-entered rows in one month.
  List<FinanceTransaction> transactionsIn({
    required int year,
    required int month,
  }) => _txns
      .where((t) => t.date.year == year && t.date.month == month)
      .toList(growable: false);

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
            income:
                _sum(inMonth, TransactionType.income) +
                salesIn(year: anchor.year, month: anchor.month),
            expense: _sum(inMonth, TransactionType.expense),
          );
        }(),
    ];
  }

  /// Per-category YTD expense totals, highest first (income excluded).
  List<CategoryAmount> _expenseByCategory(List<FinanceTransaction> ytd) {
    // WTM-197: grouped by **code**, not by the display string. Grouping by
    // string made 'Nhập hàng' and 'nhập hàng' two separate rows in the seller's
    // expense breakdown.
    final byCategory = <String, double>{};
    for (final t in ytd.where((t) => t.isExpense)) {
      byCategory.update(
        t.category.code,
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

/// Builds the alert-facing cashflow series from the **same** arithmetic the
/// Finance dashboard uses (WTM-205).
///
/// The fourth appearance of the WTM-196 defect: `CashflowSeries
/// .fromTransactions` counted only hand-entered rows, so after sales revenue
/// joined Finance income the *negativeCashflow* alert kept seeing ₫0 income —
/// a seller with ten real orders and a few expenses was told their cashflow
/// was in deficit, and the Rule Twin would have had AI explain a hole that did
/// not exist.
///
/// Lives here, as an extension on [FinanceService], because the fix is not
/// "also add orders over there" — that would be a **second** implementation of
/// "sales in month X". One owner, one truth; any future change to how Finance
/// counts a month reaches the alert for free.
extension FinanceCashflow on FinanceService {
  /// One point per calendar month, oldest → newest, sales income included.
  ///
  /// [excludeCurrentMonth] defaults `true`, matching the old series: alerting
  /// on a half-finished month reads as a deficit every month until payday.
  CashflowSeries cashflowAsOf(
    DateTime now, {
    int? months,
    bool excludeCurrentMonth = true,
  }) {
    final window = monthWindow(
      now: now,
      months: months ?? monthsBack,
      excludeCurrentMonth: excludeCurrentMonth,
    );
    return CashflowSeries(
      points: List.unmodifiable([
        for (final key in window)
          () {
            final txns = transactionsIn(year: key.year, month: key.month);
            return MonthlyCashflowPoint(
              year: key.year,
              month: key.month,
              income:
                  txns
                      .where((t) => t.isIncome)
                      .fold(0.0, (s, t) => s + t.amount) +
                  salesIn(year: key.year, month: key.month),
              expense: txns
                  .where((t) => t.isExpense)
                  .fold(0.0, (s, t) => s + t.amount),
              transactionCount:
                  txns.length + salesCountIn(year: key.year, month: key.month),
            );
          }(),
      ]),
      currentMonthExcluded: excludeCurrentMonth,
    );
  }
}
