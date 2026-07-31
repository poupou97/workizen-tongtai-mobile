import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import '../metrics/business_metrics.dart';
import '../orders/order.dart';
import 'month_bucket.dart';
import 'series_math.dart';

/// One customer's Recency · Frequency · Monetary profile plus the cadence
/// signals a churn twin needs — the output of [CustomerRfmService].
///
/// Field scope is deliberate and fixed:
/// - [recencyDays], [frequency], [monetary], [firstOrderAt], [lastOrderAt] and
///   [medianGapDays] are **lifetime** (every billable order handed in), because
///   "high lifetime value at risk" and "never placed a second order" are
///   lifetime statements;
/// - [ordersInWindow] is the only window-scoped number — it is what makes
///   "used to buy often, now slowing down" measurable.
@immutable
class CustomerRfm {
  const CustomerRfm({
    required this.customerId,
    required this.recencyDays,
    required this.frequency,
    required this.monetary,
    required this.firstOrderAt,
    required this.lastOrderAt,
    required this.medianGapDays,
    required this.ordersInWindow,
  });

  /// The profile of a customer who has never bought — every signal absent, no
  /// zeros pretending to be data.
  const CustomerRfm.noOrders(this.customerId)
    : recencyDays = null,
      frequency = 0,
      monetary = 0,
      firstOrderAt = null,
      lastOrderAt = null,
      medianGapDays = null,
      ordersInWindow = 0;

  final String customerId;

  /// Whole calendar days since the last billable order, `null` when the
  /// customer has never bought (a fresh contact is **not** "0 days ago", and it
  /// is not "infinitely lapsed" either).
  final int? recencyDays;

  /// Lifetime billable order count.
  final int frequency;

  /// Lifetime billable spend, in đồng.
  final double monetary;

  /// First / last billable order date; `null` when there are none.
  final DateTime? firstOrderAt;
  final DateTime? lastOrderAt;

  /// The customer's own natural cadence: the median number of days between
  /// consecutive billable orders. `null` below two orders — a single purchase
  /// says nothing about rhythm.
  ///
  /// Median, not mean, so one long holiday gap does not redefine a weekly
  /// buyer as a quarterly one.
  final double? medianGapDays;

  /// Billable orders inside the analysis window (see
  /// [CustomerRfmService.compute]).
  final int ordersInWindow;

  bool get hasOrders => frequency > 0;

  /// Bought exactly once — the `singlePurchaseOnly` signal.
  bool get isSinglePurchase => frequency == 1;

  /// Lifetime spend ÷ lifetime orders, `0` when there are none.
  double get averageOrderValue => frequency == 0 ? 0 : monetary / frequency;

  /// How overdue this customer is against their **own** cadence: `2.0` means
  /// they have been silent for twice their usual gap.
  ///
  /// `null` when there is no cadence yet ([medianGapDays] null or zero) or the
  /// customer never bought — the caller must then fall back to an absolute
  /// churn window instead of guessing.
  double? get gapRatio => gapRatioWithFloor(0);

  /// [gapRatio] measured against a cadence of **at least** [minCadenceDays].
  ///
  /// A cadence shorter than the floor is treated as the floor, so a customer
  /// who happens to buy every two days is not declared lapsed after a quiet
  /// week: `recency / max(medianGapDays, minCadenceDays)`. Segmentation policy
  /// (which floor, and what ratio means "at risk") belongs to the caller — this
  /// only supplies the number.
  ///
  /// `null` under the same conditions as [gapRatio]: no cadence, or no orders.
  double? gapRatioWithFloor(double minCadenceDays) {
    final gap = medianGapDays;
    final recency = recencyDays;
    if (gap == null || gap <= 0 || recency == null) return null;
    return recency / (gap < minCadenceDays ? minCadenceDays : gap);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRfm &&
          other.customerId == customerId &&
          other.recencyDays == recencyDays &&
          other.frequency == frequency &&
          other.monetary == monetary &&
          other.firstOrderAt == firstOrderAt &&
          other.lastOrderAt == lastOrderAt &&
          other.medianGapDays == medianGapDays &&
          other.ordersInWindow == ordersInWindow);

  @override
  int get hashCode => Object.hash(
    customerId,
    recencyDays,
    frequency,
    monetary,
    firstOrderAt,
    lastOrderAt,
    medianGapDays,
    ordersInWindow,
  );

  @override
  String toString() =>
      'CustomerRfm($customerId, r: $recencyDays, f: $frequency, m: $monetary, '
      'gap: $medianGapDays, inWindow: $ordersInWindow)';
}

/// Turns customers + orders into [CustomerRfm] profiles — an **Aggregation
/// Service** on the One Data Path
/// `Repository → Aggregation Services → Capability Context → Rule Twin`
/// (Founder directive "Capability-Driven Predictive Foundation", 2026-07-30).
///
/// The Consumer context, the churn/win-back twin and any segmentation feature
/// read these profiles instead of walking orders themselves. Pure and
/// stateless: no clock read (`now` is passed in), no repository, no Riverpod.
abstract final class CustomerRfmService {
  /// Profiles every customer in [customers] — including those with **no**
  /// orders, which are exactly the ones a "never converted" rule needs.
  ///
  /// - Only billable orders count ([isBillableOrder]); cancelled orders are
  ///   invisible here, matching KPIs and Reports.
  /// - Orders referencing an unknown customer id are ignored (the customer
  ///   directory is the source of truth for who exists).
  /// - [windowMonths] is a **calendar-month** window that *includes* the
  ///   running month — for recency work the partial month is the whole point,
  ///   the opposite of the revenue series' completed-months rule.
  /// - Output order mirrors [customers], so the result is deterministic and a
  ///   caller can zip the two lists.
  static List<CustomerRfm> compute(
    Iterable<Customer> customers,
    Iterable<CustomerOrder> orders, {
    required DateTime now,
    int windowMonths = 12,
  }) {
    final customerList = customers.toList(growable: false);
    if (customerList.isEmpty) return const <CustomerRfm>[];

    final known = {for (final customer in customerList) customer.id};
    final window = monthWindow(
      now: now,
      months: windowMonths,
      excludeCurrentMonth: false,
    ).toSet();

    final byCustomer = <String, List<CustomerOrder>>{};
    for (final order in orders.billable) {
      if (!known.contains(order.customerId)) continue;
      byCustomer
          .putIfAbsent(order.customerId, () => <CustomerOrder>[])
          .add(order);
    }

    return List<CustomerRfm>.unmodifiable([
      for (final customer in customerList)
        _profile(customer.id, byCustomer[customer.id], now, window),
    ]);
  }

  static CustomerRfm _profile(
    String customerId,
    List<CustomerOrder>? orders,
    DateTime now,
    Set<MonthKey> window,
  ) {
    if (orders == null || orders.isEmpty) {
      return CustomerRfm.noOrders(customerId);
    }
    final dates = [for (final order in orders) order.date]..sort();
    final last = dates.last;
    var monetary = 0.0;
    var inWindow = 0;
    for (final order in orders) {
      monetary += order.totalAmount;
      if (window.contains(MonthKey.of(order.date))) inWindow += 1;
    }
    return CustomerRfm(
      customerId: customerId,
      recencyDays: wholeDaysBetween(last, now),
      frequency: orders.length,
      monetary: monetary,
      firstOrderAt: dates.first,
      lastOrderAt: last,
      medianGapDays: medianGapDays(dates),
      ordersInWindow: inWindow,
    );
  }

  /// Median days between consecutive orders in [orderDates] — the customer's
  /// natural cadence. Pure helper, exposed so a twin or a test can compute a
  /// cadence from any date list.
  ///
  /// The dates need not be sorted. `null` below two dates. Even counts average
  /// the two middle gaps, so a 20/40-day buyer reads as 30.
  static double? medianGapDays(Iterable<DateTime> orderDates) {
    final sorted = orderDates.toList()..sort();
    if (sorted.length < 2) return null;
    final gaps = <double>[
      for (var i = 1; i < sorted.length; i++)
        wholeDaysBetween(sorted[i - 1], sorted[i]).toDouble(),
    ];
    return median(gaps);
  }

  /// Cut-offs for banding customers by lifetime spend — e.g.
  /// `monetaryQuantiles(profiles, const [0.5, 0.8])` returns the median and the
  /// top-20% threshold, in ascending order.
  ///
  /// Customers with no orders are included (their monetary is 0), because a
  /// band is about the whole directory. Empty for an empty input.
  static List<double> monetaryQuantiles(
    Iterable<CustomerRfm> profiles,
    List<double> fractions,
  ) => _quantilesOf([for (final p in profiles) p.monetary], fractions);

  /// Cut-offs for banding customers by lifetime order count — see
  /// [monetaryQuantiles].
  static List<double> frequencyQuantiles(
    Iterable<CustomerRfm> profiles,
    List<double> fractions,
  ) => _quantilesOf([
    for (final p in profiles) p.frequency.toDouble(),
  ], fractions);

  /// The band [value] falls into, given [ascendingCutoffs]: `0` is below the
  /// first cut-off, `cutoffs.length` is at or above the last. A value exactly
  /// on a cut-off lands in the **higher** band, so a threshold is inclusive
  /// upward (a seller reading "≥ 10M ₫ = Gold" expects 10M to be Gold).
  static int band(num value, List<double> ascendingCutoffs) {
    var index = 0;
    for (final cutoff in ascendingCutoffs) {
      if (value < cutoff) break;
      index += 1;
    }
    return index;
  }

  static List<double> _quantilesOf(
    List<double> values,
    List<double> fractions,
  ) {
    if (values.isEmpty || fractions.isEmpty) return const <double>[];
    return List<double>.unmodifiable([
      for (final fraction in fractions) quantile(values, fraction) ?? 0,
    ]);
  }
}
