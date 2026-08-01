import 'package:flutter/foundation.dart';

import '../finance/finance_transaction.dart';
import 'month_bucket.dart';
import 'series_math.dart';

/// Money in, money out and what is left, for one local calendar month — one
/// point of a [CashflowSeries].
///
/// A month with no transactions still produces a point (all zeros): a month the
/// seller recorded nothing must be visibly empty, not silently skipped.
@immutable
class MonthlyCashflowPoint {
  const MonthlyCashflowPoint({
    required this.year,
    required this.month,
    this.income = 0,
    this.expense = 0,
    this.transactionCount = 0,
  });

  final int year;

  /// 1..12.
  final int month;

  /// Money in, in đồng — always positive (direction lives in the transaction
  /// type, per [FinanceTransaction]).
  final double income;

  /// Money out, in đồng — always positive.
  final double expense;

  /// Transactions recorded in this month (income + expense).
  final int transactionCount;

  /// Income − expense: negative is a deficit month.
  double get profit => income - expense;

  /// Whether the month spent more than it earned — the `negativeCashflow`
  /// signal.
  bool get isDeficit => profit < 0;

  /// This point's position on the shared month grid.
  MonthKey get key => MonthKey(year, month);

  bool get isEmpty => transactionCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyCashflowPoint &&
          other.year == year &&
          other.month == month &&
          other.income == income &&
          other.expense == expense &&
          other.transactionCount == transactionCount);

  @override
  int get hashCode =>
      Object.hash(year, month, income, expense, transactionCount);

  @override
  String toString() =>
      'MonthlyCashflowPoint($year-$month, income: $income, '
      'expense: $expense, profit: $profit)';
}

/// The monthly cashflow history — an **Aggregation Service** on the One Data
/// Path `Repository → Aggregation Services → Capability Context → Rule Twin`
/// (Founder directive "Capability-Driven Predictive Foundation", 2026-07-30).
///
/// The Finance context and the business-alert twin read this series; neither
/// re-buckets transactions. Bucketing (and the local-timezone decision) is the
/// **same** helper the revenue series uses — `month_bucket.dart` — so a "July"
/// in Finance is byte-for-byte the same July as in Reports.
///
/// Pure: no clock read, no repository, no Riverpod, no widgets.
@immutable
class CashflowSeries {
  const CashflowSeries({
    required this.points,
    this.currentMonthExcluded = true,
  });

  /// A business with nothing to analyse — well-formed, never null.
  static const CashflowSeries empty = CashflowSeries(
    points: <MonthlyCashflowPoint>[],
  );

  /// Buckets [transactions] into the [months] calendar months ending at [now],
  /// oldest → newest.
  ///
  /// ⚠️ **Hand-entered rows only — this cannot see sales revenue.** Feeding it
  /// to the negative-cashflow alert told a seller with ten real orders that
  /// their cashflow was in deficit (WTM-205). Anything judging the business's
  /// money must use `FinanceService.cashflowAsOf`, the same arithmetic the
  /// Finance dashboard shows. This factory remains for series that are
  /// genuinely about the hand-kept ledger alone.
  ///
  /// Same rules as `RevenueSeries.fromOrders`: every month in the window emits
  /// a point (empty ones as zeros), [excludeCurrentMonth] (default `true`)
  /// drops the incomplete running month, transactions outside the window are
  /// ignored, and a non-positive [months] yields an empty series rather than an
  /// exception.
  factory CashflowSeries.fromTransactions(
    Iterable<FinanceTransaction> transactions, {
    required DateTime now,
    int months = 12,
    bool excludeCurrentMonth = true,
  }) {
    final window = monthWindow(
      now: now,
      months: months,
      excludeCurrentMonth: excludeCurrentMonth,
    );
    if (window.isEmpty) {
      return CashflowSeries(
        points: const <MonthlyCashflowPoint>[],
        currentMonthExcluded: excludeCurrentMonth,
      );
    }
    final buckets = bucketByMonth<FinanceTransaction>(
      transactions,
      (transaction) => transaction.date,
    );
    return CashflowSeries(
      points: List<MonthlyCashflowPoint>.unmodifiable([
        for (final key in window) _pointFor(key, buckets[key]),
      ]),
      currentMonthExcluded: excludeCurrentMonth,
    );
  }

  static MonthlyCashflowPoint _pointFor(
    MonthKey key,
    List<FinanceTransaction>? bucket,
  ) {
    if (bucket == null || bucket.isEmpty) {
      return MonthlyCashflowPoint(year: key.year, month: key.month);
    }
    var income = 0.0;
    var expense = 0.0;
    for (final transaction in bucket) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }
    return MonthlyCashflowPoint(
      year: key.year,
      month: key.month,
      income: income,
      expense: expense,
      transactionCount: bucket.length,
    );
  }

  /// One point per month in the window, **oldest → newest**.
  final List<MonthlyCashflowPoint> points;

  /// Whether the running (partial) month was left out of this series.
  final bool currentMonthExcluded;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  /// The most recent complete month, or `null` for an empty series.
  MonthlyCashflowPoint? get latest => points.isEmpty ? null : points.last;

  double get totalIncome => points.fold(0, (sum, point) => sum + point.income);
  double get totalExpense =>
      points.fold(0, (sum, point) => sum + point.expense);

  /// Income − expense across the window; negative means the window burned cash.
  double get totalProfit => totalIncome - totalExpense;

  /// How many months in the window spent more than they earned — the count a
  /// `negativeCashflow` alert is built on.
  int get monthsInDeficit => points.where((point) => point.isDeficit).length;

  /// Whether anything at all was recorded in the window.
  bool get hasTransactions => points.any((point) => point.transactionCount > 0);

  /// Monthly profit values in series order.
  List<double> get profits => [for (final point in points) point.profit];

  /// Mean profit over the last [n] months (fewer when the series is shorter);
  /// `0` for an empty series or a non-positive [n].
  double trailingAverageProfit(int n) => mean(trailing(profits, n));

  /// Fractional change in profit from the second-to-last month to the last.
  /// `null` below two months or when the earlier month's profit was zero.
  double? get profitMonthOverMonthChange {
    if (points.length < 2) return null;
    return fractionalChange(
      points[points.length - 2].profit,
      points.last.profit,
    );
  }

  @override
  String toString() =>
      'CashflowSeries(${points.length} months, profit: $totalProfit, '
      'currentMonthExcluded: $currentMonthExcluded)';
}
