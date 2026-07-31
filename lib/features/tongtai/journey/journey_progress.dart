import '../consumer/customer_order.dart';
import '../metrics/business_metrics.dart';
import 'business_goal.dart';

/// Reconciles a [BusinessGoal] against **real recorded sales** (WTM-89).
///
/// A goal is aspirational and its `achievedAmount` is the seller's own manual
/// tracking. This service adds the **data-first** view: how much revenue the
/// business actually booked *during the goal's active window* — the same
/// billable rule the reports use (cancelled orders excluded). It is purely
/// additive: it never mutates the goal or its manual progress, so the seller
/// stays in control of the goal while also seeing the ground truth from orders.
///
/// Pure Dart over the order list — no database, no clock of its own (the caller
/// passes `now`) — so every figure is deterministically unit-testable, mirroring
/// [ReportsService].
class JourneyProgressService {
  const JourneyProgressService();

  /// Revenue booked toward [goal] — billable orders whose date falls within the
  /// goal's active window `[startDate, min(now, endDate)]` (inclusive). Returns 0
  /// before the goal starts.
  double realizedRevenue(
    BusinessGoal goal,
    Iterable<CustomerOrder> orders,
    DateTime now,
  ) {
    // The window never runs past the goal's own end, nor into the future.
    final windowEnd = now.isBefore(goal.endDate) ? now : goal.endDate;
    if (windowEnd.isBefore(goal.startDate)) return 0;
    return orders.billable
        .where(
          (o) => !o.date.isBefore(goal.startDate) && !o.date.isAfter(windowEnd),
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  /// Realized revenue as a fraction of the goal's revenue target (0..1, clamped).
  /// Returns 0 when the goal has no revenue target — see [BusinessGoal.progress]
  /// for the goal's own (manual) progress in that case.
  double realizedShare(
    BusinessGoal goal,
    Iterable<CustomerOrder> orders,
    DateTime now,
  ) {
    if (goal.targetAmount <= 0) return 0;
    return (realizedRevenue(goal, orders, now) / goal.targetAmount).clamp(
      0.0,
      1.0,
    );
  }
}

/// **Auto-derive (WTM-138, Founder default → ADR-TON-013):** goal progress is
/// derived from real business data; manual entry remains only for KPIs that
/// cannot be derived.
///
/// For a **revenue-denominated** goal the derivable KPI is booked revenue in
/// the goal window, so its `achievedAmount` is replaced with
/// [JourneyProgressService.realizedRevenue] — progress/pace/recommendation all
/// follow. Growth-metric goals (units/customers — no derivable source yet) are
/// returned unchanged and keep manual entry. Pure view derivation: the
/// persisted goal is never mutated.
BusinessGoal deriveGoalProgress(
  BusinessGoal goal,
  Iterable<CustomerOrder> orders,
  DateTime now,
) {
  if (goal.targetAmount <= 0) return goal;
  return goal.copyWith(
    achievedAmount: const JourneyProgressService().realizedRevenue(
      goal,
      orders,
      now,
    ),
  );
}

/// [deriveGoalProgress] over a list, preserving order.
List<BusinessGoal> deriveGoalsProgress(
  List<BusinessGoal> goals,
  Iterable<CustomerOrder> orders,
  DateTime now,
) => [for (final g in goals) deriveGoalProgress(g, orders, now)];
