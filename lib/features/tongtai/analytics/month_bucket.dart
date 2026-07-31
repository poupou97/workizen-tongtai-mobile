import 'package:flutter/foundation.dart';

/// Calendar-month bucketing — the **one** month grid every analytics series in
/// Tổng Tài is built on (Founder directive "Capability-Driven Predictive
/// Foundation", 2026-07-30; One Data Path, ADR-TON-015).
///
/// `RevenueSeries`, `CashflowSeries` and every future monthly series MUST reuse
/// [monthWindow] + [bucketByMonth] instead of writing their own
/// `date.year == y && date.month == m` loop. Duplicate bucketing is how two
/// screens end up disagreeing about the same month.
///
/// ## Timezone decision — **local calendar time**
///
/// A month bucket is the seller's *local* calendar month, not a UTC month.
///
/// - Tổng Tài is local-first and single-device: an order dated "1/7" was typed
///   by a seller looking at a local calendar, and the seller's month-end
///   reconciliation is a local-midnight-to-local-midnight affair. Bucketing in
///   UTC would move a 1 Jul 00:30 (UTC+7) order into June and make the app
///   disagree with the seller's own books.
/// - A [DateTime] that arrives in UTC (`isUtc == true`) is converted with
///   [DateTime.toLocal] first, so a UTC-stored timestamp still lands in the
///   month the seller experienced.
///
/// The only environmental input is therefore the device timezone — a
/// process-level constant, never a clock read. Every function here is pure:
/// same inputs (and same timezone) → same output. Tests construct *local*
/// `DateTime`s, so they behave identically in every timezone.
@immutable
class MonthKey implements Comparable<MonthKey> {
  /// A month identified by its [year] and 1-based [month].
  const MonthKey(this.year, this.month);

  /// The local calendar month that contains [moment] (see the timezone note on
  /// this library).
  factory MonthKey.of(DateTime moment) {
    final local = moment.isUtc ? moment.toLocal() : moment;
    return MonthKey(local.year, local.month);
  }

  final int year;

  /// 1..12.
  final int month;

  /// Months since year 0 — a total order that makes month arithmetic trivial.
  int get ordinal => year * 12 + (month - 1);

  /// Local midnight on the first day of this month (inclusive bucket start).
  DateTime get start => DateTime(year, month);

  /// Local midnight on the first day of the *next* month (exclusive bucket end).
  DateTime get endExclusive => DateTime(year, month + 1);

  /// This month shifted by [delta] months (negative shifts back). Year
  /// roll-over is handled by [DateTime]'s own normalisation.
  MonthKey addMonths(int delta) {
    final shifted = DateTime(year, month + delta);
    return MonthKey(shifted.year, shifted.month);
  }

  /// How many months [other] lies before this one (negative when it is after).
  int monthsSince(MonthKey other) => ordinal - other.ordinal;

  /// Whether [moment] falls inside this local calendar month.
  bool contains(DateTime moment) => MonthKey.of(moment) == this;

  @override
  int compareTo(MonthKey other) => ordinal.compareTo(other.ordinal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthKey && other.year == year && other.month == month);

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// The analysable month grid ending at [now], oldest → newest.
///
/// [months] is the number of buckets to emit; a non-positive value yields an
/// empty window (well-formed, never an exception).
///
/// When [excludeCurrentMonth] is true (the default for *analysis*) the running
/// month is dropped, because a partial month always reads as a collapse against
/// complete ones — the caller then reports `ReasonCode.partialMonthExcluded`.
/// Pass `false` when the current month is the point (e.g. "orders this month").
List<MonthKey> monthWindow({
  required DateTime now,
  required int months,
  bool excludeCurrentMonth = true,
}) {
  if (months <= 0) return const <MonthKey>[];
  final current = MonthKey.of(now);
  final last = excludeCurrentMonth ? current.addMonths(-1) : current;
  return List<MonthKey>.unmodifiable([
    for (var back = months - 1; back >= 0; back--) last.addMonths(-back),
  ]);
}

/// Groups [items] into local calendar months, keyed by [MonthKey].
///
/// [dateOf] extracts the item's business date. Months with no items are simply
/// absent from the map — callers pair this with [monthWindow] so **every**
/// month in the window still emits a point (a gap must be a visible zero,
/// never a missing row).
Map<MonthKey, List<T>> bucketByMonth<T>(
  Iterable<T> items,
  DateTime Function(T item) dateOf,
) {
  final buckets = <MonthKey, List<T>>{};
  for (final item in items) {
    buckets.putIfAbsent(MonthKey.of(dateOf(item)), () => <T>[]).add(item);
  }
  return buckets;
}

/// Whole calendar days from [from] to [to] (negative when [to] is earlier).
///
/// Compares *dates*, not instants: 31 Dec 23:59 → 1 Jan 00:01 is 1 day, which
/// is what a seller means by "yesterday". Both ends are read in local time (see
/// the timezone note) and the subtraction is done on UTC-normalised midnights
/// so a DST jump can never turn a day into 23 hours.
int wholeDaysBetween(DateTime from, DateTime to) {
  final start = from.isUtc ? from.toLocal() : from;
  final end = to.isUtc ? to.toLocal() : to;
  return DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
}
