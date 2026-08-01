import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert_service.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_progress.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_rule_engine.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// **One concept, one truth** — Founder Directive, 2026-08-01.
///
/// > *"Không để hai màn hình cùng mô tả một khái niệm nhưng hiển thị hai sự
/// > thật khác nhau."*
///
/// ## Why this suite exists at all
/// Both defects it locks down were invisible to ordinary testing, because each
/// side was **internally consistent and had its own passing tests**. Nothing
/// asked the only question that mattered: *do the two agree?*
///
/// - WTM-196: Home counted orders, Finance counted hand-typed rows. A seller
///   with ten orders read ₫0 income.
/// - WTM-200: Home read a **stored** `achievedAmount` while Goals **derived**
///   it; and the win-back rule called a customer lapsed at a flat 30 days while
///   `customerLifecycleStage()` judged silence against the customer's own
///   rhythm.
///
/// Every test here compares **two producers of one number**. Adding a concept
/// to the app means adding it here, or accepting that the next disagreement
/// will be found by a seller.
void main() {
  final now = DateTime(2026, 8, 1);

  CustomerOrder order(
    String id, {
    required String customerId,
    required double amount,
    required DateTime date,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: 'DH-$id',
    date: date,
    status: OrderStatus.delivered,
    items: [
      OrderItem(
        productName: 'SP',
        category: 'Home',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  group('goal progress has one owner', () {
    BusinessGoal goal({required double achievedAmount}) => BusinessGoal(
      id: 'g1',
      name: 'Doanh thu quý',
      type: GoalType.revenue,
      targetAmount: 10000000,
      achievedAmount: achievedAmount,
      growthTarget: 0,
      growthAchieved: 0,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 9, 30),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

    test('the derived figure wins over whatever was stored', () {
      // The stored value is deliberately stale — WTM-138 stopped writing it,
      // so anything reading it is reading history. Home did exactly that, and
      // showed 40% while Goals showed 60% for the same goal on the same day.
      final orders = [
        order(
          'o1',
          customerId: 'c1',
          amount: 6000000,
          date: DateTime(2026, 7, 5),
        ),
      ];

      final derived = deriveGoalsProgress(
        [goal(achievedAmount: 4000000)],
        orders,
        now,
      ).single;

      expect(derived.achievedAmount, 6000000);
      expect(
        derived.progress,
        isNot(goal(achievedAmount: 4000000).progress),
        reason:
            'stored and derived disagree — which is why only one may be shown',
      );
    });

    test('no orders means no progress, not the stale stored number', () {
      final derived = deriveGoalsProgress(
        [goal(achievedAmount: 4000000)],
        const [],
        now,
      ).single;

      expect(derived.achievedAmount, 0);
    });
  });

  group('"this customer has gone quiet" has one owner', () {
    Customer customer(String id) => Customer(
      id: id,
      name: 'Khách $id',
      phone: '0900000000',
      location: 'HCM',
      orderCount: 0,
      totalSpent: 0,
      lastPurchaseDate: null,
    );

    /// Orders every [gapDays] apart, the last one [silentDays] before `now`.
    List<CustomerOrder> rhythm(
      String customerId, {
      required int gapDays,
      required int silentDays,
      int count = 4,
    }) {
      final last = now.subtract(Duration(days: silentDays));
      return [
        for (var i = 0; i < count; i++)
          order(
            '$customerId-$i',
            customerId: customerId,
            amount: 1000000,
            date: last.subtract(Duration(days: gapDays * i)),
          ),
      ];
    }

    /// What the Opportunity feed says, and what Consumer says, about one
    /// customer — the two sides that used to disagree.
    ({bool opportunitySaysQuiet, CustomerLifecycleStage consumerStage})
    verdicts(String id, List<CustomerOrder> orders) {
      final opportunities = const OpportunityRuleEngine().generate(
        products: const [],
        customers: [customer(id)],
        orders: orders,
        goals: const [],
        now: now,
      );
      final profile = CustomerRfmService.compute(
        [customer(id)],
        orders,
        now: now,
      ).single;
      return (
        opportunitySaysQuiet: opportunities.any(
          (o) => o.id == 'gen-winback-$id',
        ),
        consumerStage: customerLifecycleStage(profile),
      );
    }

    test('a quarterly buyer silent 35 days is quiet on neither screen', () {
      // The false alarm. A flat 30-day rule nagged the seller about a customer
      // who was behaving perfectly normally.
      final v = verdicts('c1', rhythm('c1', gapDays: 90, silentDays: 35));

      expect(v.consumerStage, CustomerLifecycleStage.active);
      expect(
        v.opportunitySaysQuiet,
        isFalse,
        reason:
            'Consumer calls them active — Opportunity must not contradict it',
      );
    });

    test('a weekly buyer silent 40 days is quiet on both screens', () {
      // The miss. Nearly six of their own cycles, and the flat rule needed only
      // 30 days — so it fired late, and for the wrong reason.
      final v = verdicts('c2', rhythm('c2', gapDays: 7, silentDays: 40));

      expect(v.consumerStage, isNot(CustomerLifecycleStage.active));
      expect(v.opportunitySaysQuiet, isTrue);
    });

    test('the two sides never disagree across a spread of rhythms', () {
      // The general contract, rather than two hand-picked cases.
      for (final gap in [7, 30, 90]) {
        for (final silent in [5, 20, 35, 100, 300]) {
          final id = 'c-$gap-$silent';
          final v = verdicts(id, rhythm(id, gapDays: gap, silentDays: silent));
          final consumerSaysQuiet =
              v.consumerStage == CustomerLifecycleStage.atRisk ||
              v.consumerStage == CustomerLifecycleStage.churned;

          expect(
            v.opportunitySaysQuiet,
            consumerSaysQuiet,
            reason:
                'gap ${gap}d, silent ${silent}d: Opportunity says '
                '${v.opportunitySaysQuiet}, Consumer says ${v.consumerStage.name}',
          );
        }
      }
    });
  });

  group('customer counters have one owner', () {
    Customer customer(String id) => Customer(
      id: id,
      name: 'Khách $id',
      phone: '0900000000',
      location: 'HCM',
      // Deliberately wrong stored values: nothing writes these when an order is
      // recorded, so whatever sits here is history (WTM-201).
      orderCount: 0,
      totalSpent: 0,
      lastPurchaseDate: null,
    );

    test('a recorded order shows up on the customer', () {
      final orders = [
        order(
          'o1',
          customerId: 'c1',
          amount: 400000,
          date: DateTime(2026, 7, 1),
        ),
        order(
          'o2',
          customerId: 'c1',
          amount: 600000,
          date: DateTime(2026, 7, 20),
        ),
      ];

      final derived = deriveCustomerCounters(
        [customer('c1')],
        orders,
        now: now,
      ).single;

      expect(derived.orderCount, 2);
      expect(derived.totalSpent, 1000000);
      expect(derived.lastPurchaseDate, DateTime(2026, 7, 20));
    });

    test('Consumer and RFM agree on how many orders a customer has', () {
      // The cross-check. Consumer read the stored counter, RFM counted real
      // orders; both were internally consistent and told the seller different
      // things — the third time that shape appeared in one day.
      final orders = [
        for (var i = 0; i < 5; i++)
          order(
            'o$i',
            customerId: 'c1',
            amount: 100000,
            date: DateTime(2026, 7, 1).add(Duration(days: i * 3)),
          ),
      ];

      final derived = deriveCustomerCounters(
        [customer('c1')],
        orders,
        now: now,
      ).single;
      final profile = CustomerRfmService.compute(
        [customer('c1')],
        orders,
        now: now,
      ).single;

      expect(derived.orderCount, profile.frequency);
      expect(derived.totalSpent, profile.monetary);
    });

    test(
      'a customer with no orders reads zero, not the stale stored value',
      () {
        final stale = customer(
          'c1',
        ).copyWith(orderCount: 9, totalSpent: 9000000);

        final derived = deriveCustomerCounters(
          [stale],
          const [],
          now: now,
        ).single;

        expect(derived.orderCount, 0);
        expect(derived.totalSpent, 0);
      },
    );

    test('a cancelled order counts for neither side', () {
      final orders = [
        order(
          'o1',
          customerId: 'c1',
          amount: 400000,
          date: DateTime(2026, 7, 1),
        ),
        CustomerOrder(
          id: 'x',
          customerId: 'c1',
          orderNumber: 'DH-x',
          date: DateTime(2026, 7, 2),
          status: OrderStatus.cancelled,
          items: [
            OrderItem(
              productName: 'SP',
              category: 'Home',
              quantity: 1,
              unitPrice: 9000000,
            ),
          ],
        ),
      ];

      final derived = deriveCustomerCounters(
        [customer('c1')],
        orders,
        now: now,
      ).single;

      expect(derived.orderCount, 1);
      expect(derived.totalSpent, 400000);
    });
  });

  group('"sắp hết hàng" has one owner (WTM-213)', () {
    // Product.stockStatus colors the Inventory list badge; StockAlertService
    // fills the alert banner + Stock Alerts screen. Until WTM-213 the service
    // accepted a `minimumThreshold` catalog floor — a second rule that, at any
    // value > 0, made the two surfaces disagree about the same shelf. The
    // engine now derives FROM stockStatus; this sweep pins the agreement.
    Product product(int quantity, int reorderLevel) => Product(
      id: 'p-$quantity-$reorderLevel',
      sku: 'SKU',
      name: 'SP',
      category: 'Home',
      quantity: quantity,
      pricePerUnit: 1000,
      reorderLevel: reorderLevel,
      updatedAt: DateTime(2026, 1, 1),
    );

    test('badge and alert set agree across the quantity × threshold plane', () {
      for (var reorder = 0; reorder <= 10; reorder += 5) {
        for (var qty = 0; qty <= 12; qty++) {
          final p = product(qty, reorder);
          final alerted = StockAlertService([
            p,
          ]).alerts.map((a) => a.product.id);

          expect(
            alerted.contains(p.id),
            p.stockStatus != StockStatus.inStock,
            reason:
                'qty=$qty reorder=$reorder: the list badge and the alerts '
                'screen describe the same shelf differently',
          );
        }
      }
    });
  });
}
