import 'package:flutter/foundation.dart';

import '../core/capability_context_provider.dart';
import '../finance/finance_repository.dart';
import '../journey/business_goal_repository.dart';
import '../opportunity/opportunity.dart';
import '../orders/order_repository.dart';
import 'business_event.dart';
import 'business_event_sources.dart';
import 'timeline_service.dart';

/// Timeline slice of the business snapshot (WTM-134, Progressive Aggregation).
///
/// Unlike the other slices, Timeline has **no repository of its own** — it is a
/// **derived projection** (an *activity stream*) that `TimelineService` merges
/// from the other capabilities' records. So this summary is a read-only *view*
/// of activity, complementary to the count slices — never a data source.
///
/// **It must not feed `BusinessContext.hasData`:** its events re-derive from
/// finance/orders/journey, which already drive `hasData`; counting it too would
/// double-count.
@immutable
class TimelineSummary {
  const TimelineSummary({
    required this.totalEvents,
    required this.byType,
    required this.recentCount,
    this.latestAt,
  });

  static const TimelineSummary empty = TimelineSummary(
    totalEvents: 0,
    byType: {},
    recentCount: 0,
  );

  /// All events across every source.
  final int totalEvents;

  /// Count of events of each [BusinessEventType].
  final Map<BusinessEventType, int> byType;

  /// Events within the trailing window (as of the snapshot's `now`) — the
  /// "recent activity" signal.
  final int recentCount;

  /// Timestamp of the most recent event, or null when there is no activity.
  final DateTime? latestAt;

  int type(BusinessEventType t) => byType[t] ?? 0;

  /// Whether the business has produced any event at all.
  bool get hasActivity => totalEvents > 0;

  factory TimelineSummary.from(
    List<BusinessEvent> events, {
    required DateTime now,
    int recentWindowDays = 7,
  }) {
    if (events.isEmpty) return empty;
    final cutoff = now.subtract(Duration(days: recentWindowDays));
    final byType = <BusinessEventType, int>{};
    DateTime? latest;
    var recent = 0;
    for (final e in events) {
      byType[e.type] = (byType[e.type] ?? 0) + 1;
      if (latest == null || e.timestamp.isAfter(latest)) latest = e.timestamp;
      if (e.timestamp.isAfter(cutoff)) recent++;
    }
    return TimelineSummary(
      totalEvents: events.length,
      byType: byType,
      recentCount: recent,
      latestAt: latest,
    );
  }
}

/// The Timeline capability's Context Provider (WTM-134). Builds a **real,
/// non-sample** [TimelineService] from the live repositories and projects it into
/// a [TimelineSummary] slice — pure Dart, no AI, no network.
///
/// **User Data First:** the wired repositories start empty, so a brand-new
/// business reads [TimelineSummary.empty]. Opportunity has no persisted source
/// yet (matches `OpportunityContextProvider`), so its events are injected only in
/// demo/tests.
class TimelineContextProvider
    implements CapabilityContextProvider<TimelineSummary> {
  const TimelineContextProvider(
    this._finance,
    this._orders,
    this._journey, {
    this.opportunities = const [],
    this.clock,
    this.recentWindowDays = 7,
  });

  final FinanceRepository _finance;
  final OrderRepository _orders;
  final BusinessGoalRepository _journey;

  /// Current opportunities to project (empty in the real app until a real source
  /// exists; injected in demo/tests).
  final List<Opportunity> opportunities;

  /// Injectable clock for the recent-window read; defaults to [DateTime.now].
  final DateTime Function()? clock;

  /// Trailing window (days) for [TimelineSummary.recentCount].
  final int recentWindowDays;

  @override
  Future<TimelineSummary> load() async {
    final service = TimelineService([
      FinanceEventSource(await _finance.loadAll()),
      OrderEventSource(await _orders.loadAll()),
      JourneyEventSource(await _journey.loadAll()),
      OpportunityEventSource(opportunities),
    ]);
    return TimelineSummary.from(
      service.timeline(),
      now: (clock ?? DateTime.now)(),
      recentWindowDays: recentWindowDays,
    );
  }
}
