import 'package:flutter/foundation.dart';

import '../consumer/customer_order.dart';
import '../core/capability_context_provider.dart';
import 'business_goal.dart';
import 'business_goal_repository.dart';
import 'journey_progress.dart';

/// Business-Journey slice of the business snapshot (WTM-133, Progressive
/// Aggregation Phase 2). Business Journey *is* the goal-orchestration capability,
/// so this single provider covers the Founder snapshot's Journey/Goals concern
/// (one Context Provider per capability, WTM-131).
///
/// [GoalPace] is time-relative, so the counts are taken as of a `now` the
/// provider supplies (mirrors OpportunityContextProvider) — no AI, no network.
@immutable
class JourneySummary {
  const JourneySummary({required this.total, required this.byPace});

  static const JourneySummary empty = JourneySummary(total: 0, byPace: {});

  /// All goals the seller has defined.
  final int total;

  /// Count of goals at each [GoalPace] as of the snapshot's `now`.
  final Map<GoalPace, int> byPace;

  int pace(GoalPace p) => byPace[p] ?? 0;

  /// Goals already achieved.
  int get completedCount => pace(GoalPace.completed);

  /// Goals still in flight (everything not completed).
  int get activeCount => total - completedCount;

  /// Goals falling behind their timeline — the attention signal (like Orders'
  /// openCount or Inventory's lowStockCount).
  int get atRiskCount => pace(GoalPace.behind);

  factory JourneySummary.from(
    List<BusinessGoal> goals, {
    required DateTime now,
  }) {
    final byPace = <GoalPace, int>{};
    for (final g in goals) {
      final p = g.pace(now);
      byPace[p] = (byPace[p] ?? 0) + 1;
    }
    return JourneySummary(total: goals.length, byPace: byPace);
  }
}

/// The Business Journey capability's Context Provider (WTM-133). Loads goals from
/// the repository and produces the [JourneySummary] slice for BusinessContext.
///
/// **User Data First:** the real app wires a Drift repository that starts empty,
/// so a brand-new business reads an empty summary; demo/tests inject goals.
class JourneyContextProvider
    implements CapabilityContextProvider<JourneySummary> {
  const JourneyContextProvider(this._repository, {this.orders, this.clock});

  final BusinessGoalRepository _repository;

  /// Optional order source for **auto-derived progress** (WTM-138, Founder
  /// default): when present, revenue-goal progress is derived from real booked
  /// orders before the pace counts. Absent → the goals' own values are used.
  final Future<List<CustomerOrder>> Function()? orders;

  /// Injectable clock for the time-relative pace counts; defaults to
  /// [DateTime.now].
  final DateTime Function()? clock;

  @override
  Future<JourneySummary> load() async {
    final now = (clock ?? DateTime.now)();
    var goals = await _repository.loadAll();
    if (orders != null) {
      goals = deriveGoalsProgress(goals, await orders!(), now);
    }
    return JourneySummary.from(goals, now: now);
  }
}
