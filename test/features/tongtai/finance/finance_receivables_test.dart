import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_summary.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-211 (D-11) — receivables: derived from orders, feeding the Journey.
///
/// The point is not a stronger Finance module. It is a smarter Journey: money
/// the seller already earned is the cheapest revenue there is, and the plan
/// should say so — but only when the debt is real and material.
void main() {
  final now = DateTime(2026, 8, 1);

  CustomerOrder order(
    String id, {
    required String customerId,
    required double amount,
    String? paymentStatus,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: 'DH-$id',
    date: DateTime(2026, 7, 10),
    status: OrderStatus.delivered,
    paymentStatus: paymentStatus,
    items: [
      OrderItem(
        productName: 'SP',
        category: 'Home',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  group('receivables are derived, and only from what the seller said', () {
    test('unpaid and partial orders count; paid ones do not', () {
      final summary = FinanceService(
        const [],
        orders: [
          order(
            'a',
            customerId: 'c1',
            amount: 3000000,
            paymentStatus: kPaymentUnpaid,
          ),
          order(
            'b',
            customerId: 'c2',
            amount: 1000000,
            paymentStatus: kPaymentPartial,
          ),
          order(
            'c',
            customerId: 'c3',
            amount: 9000000,
            paymentStatus: kPaymentPaid,
          ),
        ],
      ).summaryAsOf(now);

      expect(summary.receivables, 4000000);
      expect(summary.debtorCount, 2);
    });

    test('"not recorded" is not debt', () {
      // Every order written before WTM-211 has a null paymentStatus. Counting
      // them as unpaid would invent receivables out of thin air the day the
      // feature ships — the loudest possible way to lose a seller's trust.
      final summary = FinanceService(
        const [],
        orders: [order('a', customerId: 'c1', amount: 5000000)],
      ).summaryAsOf(now);

      expect(summary.receivables, 0);
      expect(summary.debtorCount, 0);
    });

    test('one customer with three unpaid orders is one debtor', () {
      final summary = FinanceService(
        const [],
        orders: [
          for (var i = 0; i < 3; i++)
            order(
              'o$i',
              customerId: 'c1',
              amount: 500000,
              paymentStatus: kPaymentUnpaid,
            ),
        ],
      ).summaryAsOf(now);

      expect(summary.receivables, 1500000);
      expect(summary.debtorCount, 1);
    });
  });

  group('the journey learns about stuck money (D-11)', () {
    BusinessGoal goal() => BusinessGoal(
      id: 'g1',
      name: 'Doanh thu',
      type: GoalType.revenue,
      targetAmount: 50000000,
      achievedAmount: 0,
      growthTarget: 20,
      growthAchieved: 0,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 12, 31),
      createdAt: now,
      updatedAt: now,
    );

    JourneyPlanInput input({double receivables = 0, int debtors = 0}) =>
        JourneyPlanInput(
          goal: goal(),
          productCount: 10,
          customerCount: 5,
          orderCount: 3,
          expenseCount: 5,
          receivables: receivables,
          debtorCount: debtors,
        );

    test('material debt produces a collect-the-debt step', () {
      final nodes = planJourney(
        input(receivables: 8000000, debtors: 3),
        journeyId: 'j1',
      ).nodes;

      final step = nodes.firstWhere(
        (n) =>
            n.reasonCodes.contains(JourneyReason.dataReceivables) &&
            n.title.contains('Thu nợ'),
        orElse: () => fail('no collect-the-debt step despite 8M stuck'),
      );
      expect(step.title, contains('3 khách'));
    });

    test('a small debt does not nag', () {
      // 2M against a 50M target is not worth a milestone of its own — a shop
      // with one small unpaid order must not be scolded.
      final nodes = planJourney(
        input(receivables: 2000000, debtors: 1),
        journeyId: 'j1',
      ).nodes;

      expect(
        nodes.any((n) => n.reasonCodes.contains(JourneyReason.dataReceivables)),
        isFalse,
      );
    });

    test('no debt, no step — the P-24 check', () {
      final withDebt = planJourney(
        input(receivables: 8000000, debtors: 3),
        journeyId: 'j1',
      ).nodes.map((n) => n.title).toSet();
      final without = planJourney(
        input(),
        journeyId: 'j1',
      ).nodes.map((n) => n.title).toSet();

      expect(
        withDebt,
        isNot(without),
        reason: 'a planner that ignores receivables has not looked',
      );
    });
  });
}
