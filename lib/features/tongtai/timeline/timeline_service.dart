import 'package:flutter/foundation.dart';

import '../consumer/customer_order.dart';
import '../finance/finance_transaction.dart';
import '../journey/business_goal_controller.dart';
import '../opportunity/opportunity.dart';
import 'business_event.dart';
import 'business_event_sources.dart';

/// One day's worth of events on the timeline (WTM-114) — newest day first,
/// events within a day newest first.
@immutable
class TimelineDay {
  const TimelineDay(this.date, this.events);

  /// Date-only (midnight) key for the group.
  final DateTime date;
  final List<BusinessEvent> events;
}

/// Merges business events from every registered [BusinessEventSource] into one
/// chronological timeline (WTM-114).
///
/// The service knows nothing about orders, finance, etc. — only [BusinessEvent].
/// Sources are the seam: a Drift-backed or streaming source replaces a sample
/// one without touching the service or the UI.
class TimelineService {
  TimelineService(this._sources);

  /// Wires the built-in sample sources — finance, orders, opportunities and
  /// journey goals — so the timeline has coherent data in Phase 2.
  factory TimelineService.sample() => TimelineService([
    FinanceEventSource(kSampleTransactions),
    OrderEventSource(kSampleCustomerOrders),
    OpportunityEventSource(kSampleOpportunities),
    JourneyEventSource(kSampleBusinessGoals),
  ]);

  final List<BusinessEventSource> _sources;

  /// All events across sources, newest first; capped at [limit] when given.
  List<BusinessEvent> timeline({int? limit}) {
    final all = [for (final s in _sources) ...s.events()]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return limit == null ? all : all.take(limit).toList();
  }

  /// The timeline grouped into days, newest day first.
  List<TimelineDay> groupedByDay({int? limit}) =>
      groupEventsByDay(timeline(limit: limit));

  /// True when no source produced any event.
  bool get isEmpty => _sources.every((s) => s.events().isEmpty);
}

/// Groups an already-descending list of events into days, newest day first
/// (insertion order is preserved). Shared by [TimelineService] and the screen's
/// type filter so both group identically.
List<TimelineDay> groupEventsByDay(List<BusinessEvent> events) {
  final grouped = <DateTime, List<BusinessEvent>>{};
  for (final e in events) {
    final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
    (grouped[day] ??= []).add(e);
  }
  return [
    for (final entry in grouped.entries) TimelineDay(entry.key, entry.value),
  ];
}
