import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_progress.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-89 — realized revenue is the sales actually booked during a goal's active
/// window (billable orders only), an additive data-first read that never mutates
/// the goal's own manual progress.
void main() {
  const service = JourneyProgressService();
  final now = DateTime(2026, 7, 25);

  BusinessGoal goal({
    double target = 100000000,
    DateTime? start,
    DateTime? end,
  }) => BusinessGoal(
    id: 'g',
    name: 'g',
    type: GoalType.revenue,
    targetAmount: target,
    achievedAmount: 0,
    growthTarget: 0,
    growthAchieved: 0,
    startDate: start ?? DateTime(2026, 7, 1),
    endDate: end ?? DateTime(2026, 9, 30),
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );

  CustomerOrder order(
    String id, {
    required DateTime date,
    double amount = 1000000,
    OrderStatus status = OrderStatus.confirmed,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: date,
    status: status,
    items: [
      OrderItem(
        productName: 'X',
        category: 'Home',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  test('sums billable orders within the goal window', () {
    final r = service.realizedRevenue(goal(), [
      order('a', date: DateTime(2026, 7, 5), amount: 2000000),
      order('b', date: DateTime(2026, 7, 20), amount: 3000000),
    ], now);
    expect(r, 5000000);
  });

  test('excludes cancelled orders', () {
    final r = service.realizedRevenue(goal(), [
      order('a', date: DateTime(2026, 7, 5), amount: 2000000),
      order(
        'b',
        date: DateTime(2026, 7, 6),
        amount: 9000000,
        status: OrderStatus.cancelled,
      ),
    ], now);
    expect(r, 2000000);
  });

  test('excludes orders before the start and after now', () {
    final r = service.realizedRevenue(goal(start: DateTime(2026, 7, 10)), [
      order('before', date: DateTime(2026, 7, 1), amount: 5000000),
      order('in', date: DateTime(2026, 7, 15), amount: 4000000),
      order('future', date: DateTime(2026, 8, 1), amount: 6000000),
    ], now);
    expect(r, 4000000);
  });

  test('caps the window at the goal end date', () {
    final r = service.realizedRevenue(
      goal(end: DateTime(2026, 7, 20)),
      [
        order('in', date: DateTime(2026, 7, 15), amount: 4000000),
        order('afterEnd', date: DateTime(2026, 7, 22), amount: 8000000),
      ],
      DateTime(2026, 8, 1), // now is past the goal end
    );
    expect(r, 4000000);
  });

  test('returns 0 before the goal starts', () {
    final r = service.realizedRevenue(
      goal(start: DateTime(2026, 8, 1)),
      [order('a', date: DateTime(2026, 7, 15), amount: 4000000)],
      now, // Jul 25 is before the Aug 1 start
    );
    expect(r, 0);
  });

  group('deriveGoalProgress (WTM-138, Founder auto-derive)', () {
    test('revenue goal: achievedAmount becomes booked revenue in window', () {
      final derived = deriveGoalProgress(goal(target: 100000000), [
        order('a', date: DateTime(2026, 7, 5), amount: 30000000),
      ], now);
      expect(derived.achievedAmount, 30000000);
      expect(derived.progress, 0.3);
      expect(derived.id, 'g'); // same goal, view-derived
    });

    test('growth-metric goal (no revenue target) keeps manual values', () {
      final manual = BusinessGoal(
        id: 'growth',
        name: 'growth',
        type: GoalType.customerGrowth,
        targetAmount: 0,
        achievedAmount: 0,
        growthTarget: 100,
        growthAchieved: 40,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      );
      final derived = deriveGoalProgress(manual, [
        order('a', date: DateTime(2026, 7, 5), amount: 30000000),
      ], now);
      expect(identical(derived, manual), isTrue); // untouched
      expect(derived.progress, 0.4); // still the manual growth metric
    });

    test('deriveGoalsProgress preserves order', () {
      final derived = deriveGoalsProgress(
        [goal(), goal(target: 0)],
        [order('a', date: DateTime(2026, 7, 5))],
        now,
      );
      expect(derived, hasLength(2));
      expect(derived.first.achievedAmount, 1000000);
    });
  });

  test(
    'realizedShare = realized / target, clamped; 0 for non-revenue goals',
    () {
      final orders = [order('a', date: DateTime(2026, 7, 5), amount: 25000000)];
      expect(service.realizedShare(goal(target: 100000000), orders, now), 0.25);

      final over = [order('a', date: DateTime(2026, 7, 5), amount: 200000000)];
      expect(service.realizedShare(goal(target: 100000000), over, now), 1.0);

      expect(service.realizedShare(goal(target: 0), orders, now), 0);
    },
  );
}
