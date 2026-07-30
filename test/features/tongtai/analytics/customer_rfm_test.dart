import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-149 — [CustomerRfmService] is the Aggregation Service the churn /
/// win-back twin reads. Recency, cadence and window filtering are hand-computed
/// from calendar dates below (2026 is not a leap year).
void main() {
  final now = DateTime(2026, 7, 15);

  var nextId = 0;
  CustomerOrder order(
    String customerId,
    DateTime date,
    double total, {
    OrderStatus status = OrderStatus.delivered,
  }) {
    nextId += 1;
    return CustomerOrder(
      id: 'o$nextId',
      customerId: customerId,
      orderNumber: 'DH-$nextId',
      date: date,
      status: status,
      items: [
        OrderItem(
          productName: 'X',
          category: 'Home',
          quantity: 1,
          unitPrice: total,
        ),
      ],
    );
  }

  Customer customer(String id) => Customer(
    id: id,
    name: id,
    phone: '',
    location: '',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  setUp(() => nextId = 0);

  group('compute — recency / frequency / monetary', () {
    test('a regular buyer: R = 10 days, F = 3, M = 600', () {
      final profiles = CustomerRfmService.compute(
        [customer('c1')],
        [
          order('c1', DateTime(2026, 5, 6), 300),
          order('c1', DateTime(2026, 6, 5), 200),
          order('c1', DateTime(2026, 7, 5), 100),
        ],
        now: now,
      );

      final c1 = profiles.single;
      expect(c1.customerId, 'c1');
      expect(c1.recencyDays, 10); // 5 Jul → 15 Jul
      expect(c1.frequency, 3);
      expect(c1.monetary, 600);
      expect(c1.firstOrderAt, DateTime(2026, 5, 6));
      expect(c1.lastOrderAt, DateTime(2026, 7, 5));
      expect(c1.ordersInWindow, 3);
      expect(c1.averageOrderValue, 200);
      expect(c1.hasOrders, isTrue);
      expect(c1.isSinglePurchase, isFalse);
    });

    test('recency counts whole calendar days, not elapsed hours', () {
      // 23:59 on the 14th → 00:00 on the 15th is "yesterday" = 1 day.
      final profiles = CustomerRfmService.compute(
        [customer('c1')],
        [order('c1', DateTime(2026, 7, 14, 23, 59), 100)],
        now: now,
      );
      expect(profiles.single.recencyDays, 1);
    });

    test('a long-lapsed single buyer: 186 days since 10 Jan 2026', () {
      final profiles = CustomerRfmService.compute(
        [customer('c3')],
        [order('c3', DateTime(2026, 1, 10), 5000000)],
        now: now,
      );

      final c3 = profiles.single;
      // day-of-year 196 (15 Jul) − 10 = 186
      expect(c3.recencyDays, 186);
      expect(c3.frequency, 1);
      expect(c3.isSinglePurchase, isTrue);
      expect(c3.medianGapDays, isNull); // one order says nothing about rhythm
      expect(c3.gapRatio, isNull);
    });

    test('a customer with no orders keeps every signal absent', () {
      final profiles = CustomerRfmService.compute(
        [customer('c2')],
        const [],
        now: now,
      );

      final c2 = profiles.single;
      expect(c2.customerId, 'c2');
      expect(c2.recencyDays, isNull); // NOT 0 — never bought ≠ bought today
      expect(c2.frequency, 0);
      expect(c2.monetary, 0);
      expect(c2.firstOrderAt, isNull);
      expect(c2.lastOrderAt, isNull);
      expect(c2.medianGapDays, isNull);
      expect(c2.ordersInWindow, 0);
      expect(c2.hasOrders, isFalse);
      expect(c2.averageOrderValue, 0);
      expect(c2, CustomerRfm.noOrders('c2'));
    });

    test('cancelled orders are invisible (shared billable rule)', () {
      final profiles = CustomerRfmService.compute(
        [customer('c1')],
        [
          order('c1', DateTime(2026, 5, 6), 300),
          order('c1', DateTime(2026, 6, 5), 200),
          order('c1', DateTime(2026, 7, 5), 100),
          // Would have made recency 5 days and monetary 1600 if it counted.
          order(
            'c1',
            DateTime(2026, 7, 10),
            1000,
            status: OrderStatus.cancelled,
          ),
        ],
        now: now,
      );

      expect(profiles.single.recencyDays, 10);
      expect(profiles.single.frequency, 3);
      expect(profiles.single.monetary, 600);
    });

    test('one profile per customer, in input order; empty in → empty out', () {
      final profiles = CustomerRfmService.compute(
        [customer('c3'), customer('c1'), customer('c2')],
        [
          order('c1', DateTime(2026, 6, 5), 200),
          order('ghost', DateTime(2026, 6, 5), 999), // unknown customer
        ],
        now: now,
      );

      expect(profiles.map((p) => p.customerId).toList(), ['c3', 'c1', 'c2']);
      expect(profiles[1].frequency, 1);
      expect(CustomerRfmService.compute(const [], const [], now: now), isEmpty);
    });
  });

  group('medianGapDays — the customer\'s own cadence', () {
    test('a regular monthly buyer → 30 days', () {
      final profiles = CustomerRfmService.compute(
        [customer('c1')],
        [
          order('c1', DateTime(2026, 5, 6), 1),
          order('c1', DateTime(2026, 6, 5), 1), // +30
          order('c1', DateTime(2026, 7, 5), 1), // +30
        ],
        now: now,
      );

      expect(profiles.single.medianGapDays, 30);
      // 10 days silent against a 30-day rhythm → a third of the way overdue.
      expect(profiles.single.gapRatio, closeTo(10 / 30, 1e-12));
    });

    test(
      'an irregular buyer: gaps 10 · 100 · 30 → median 30, not the mean 46.7',
      () {
        final profiles = CustomerRfmService.compute(
          [customer('c4')],
          [
            order('c4', DateTime(2026, 1, 1), 1),
            order('c4', DateTime(2026, 1, 11), 1), // +10
            order('c4', DateTime(2026, 4, 21), 1), // +100
            order('c4', DateTime(2026, 5, 21), 1), // +30
          ],
          now: now,
        );

        expect(profiles.single.medianGapDays, 30);
      },
    );

    test('gapRatioWithFloor never divides by a cadence below the floor', () {
      // A buyer who orders every 2 days, silent for 10 days.
      final profiles = CustomerRfmService.compute(
        [customer('c5')],
        [
          order('c5', DateTime(2026, 7, 1), 1),
          order('c5', DateTime(2026, 7, 3), 1), // +2
          order('c5', DateTime(2026, 7, 5), 1), // +2
        ],
        now: now,
      );

      final c5 = profiles.single;
      expect(c5.medianGapDays, 2);
      expect(c5.recencyDays, 10);
      expect(c5.gapRatio, closeTo(5, 1e-12)); // 10 / 2 — five cycles late
      expect(c5.gapRatioWithFloor(14), closeTo(10 / 14, 1e-12)); // floored
      // A cadence already above the floor is untouched…
      expect(c5.gapRatioWithFloor(1), closeTo(5, 1e-12));
      // …and a floor of 0 is exactly [gapRatio].
      expect(c5.gapRatioWithFloor(0), c5.gapRatio);
    });

    test('gapRatioWithFloor is null without a cadence or without orders', () {
      final profiles = CustomerRfmService.compute(
        [customer('c1'), customer('c2')],
        [order('c1', DateTime(2026, 6, 5), 100)],
        now: now,
      );

      expect(profiles[0].gapRatioWithFloor(14), isNull); // one order, no rhythm
      expect(profiles[1].gapRatioWithFloor(14), isNull); // never bought
    });

    test('even gap count averages the two middles: 10 and 20 → 15', () {
      final gap = CustomerRfmService.medianGapDays([
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 11), // +10
        DateTime(2026, 3, 31), // +20
      ]);
      expect(gap, 15);
    });

    test('unsorted input gives the same answer; < 2 dates → null', () {
      expect(
        CustomerRfmService.medianGapDays([
          DateTime(2026, 3, 31),
          DateTime(2026, 3, 1),
          DateTime(2026, 3, 11),
        ]),
        15,
      );
      expect(CustomerRfmService.medianGapDays([DateTime(2026, 3, 1)]), isNull);
      expect(CustomerRfmService.medianGapDays(const []), isNull);
    });
  });

  group('window filtering', () {
    test(
      'windowMonths counts calendar months and includes the running one',
      () {
        // windowMonths: 3 with now = 15 Jul 2026 → May, Jun, Jul 2026.
        final profiles = CustomerRfmService.compute(
          [customer('c1')],
          [
            order('c1', DateTime(2026, 4, 30), 50), // outside the window
            order('c1', DateTime(2026, 5, 6), 300),
            order('c1', DateTime(2026, 6, 5), 200),
            order(
              'c1',
              DateTime(2026, 7, 5),
              100,
            ), // running month still counts
          ],
          now: now,
          windowMonths: 3,
        );

        final c1 = profiles.single;
        expect(c1.ordersInWindow, 3);
        expect(c1.frequency, 4); // lifetime is never windowed
        expect(c1.monetary, 650);
        expect(c1.recencyDays, 10);
      },
    );

    test('a customer who has gone quiet has 0 orders in the window', () {
      final profiles = CustomerRfmService.compute(
        [customer('c3')],
        [order('c3', DateTime(2026, 1, 10), 5000000)],
        now: now,
        windowMonths: 3,
      );

      expect(profiles.single.ordersInWindow, 0);
      expect(profiles.single.frequency, 1);
    });
  });

  group('quantile banding helpers', () {
    late List<CustomerRfm> profiles;

    setUp(() {
      // Lifetime spend 0 · 100 · 200 · 300 (c2 never bought).
      profiles = CustomerRfmService.compute(
        [customer('c1'), customer('c2'), customer('c3'), customer('c4')],
        [
          order('c1', DateTime(2026, 6, 1), 100),
          order('c3', DateTime(2026, 6, 1), 200),
          order('c4', DateTime(2026, 6, 1), 150),
          order('c4', DateTime(2026, 6, 2), 150),
        ],
        now: now,
      );
    });

    test('monetaryQuantiles interpolates like a spreadsheet', () {
      final cutoffs = CustomerRfmService.monetaryQuantiles(profiles, const [
        0.5,
        0.75,
      ]);

      // sorted [0, 100, 200, 300]; p50 at position 1.5 → 150;
      // p75 at position 2.25 → 200 + 0.25·100 = 225.
      expect(cutoffs, hasLength(2));
      expect(cutoffs[0], closeTo(150, 1e-12));
      expect(cutoffs[1], closeTo(225, 1e-12));
    });

    test('frequencyQuantiles uses lifetime order counts', () {
      // sorted [0, 1, 1, 2]; p50 at position 1.5 → 1.
      expect(CustomerRfmService.frequencyQuantiles(profiles, const [0.5]), [
        closeTo(1, 1e-12),
      ]);
    });

    test('empty input → empty cut-offs, never a throw', () {
      expect(
        CustomerRfmService.monetaryQuantiles(const [], const [0.5]),
        isEmpty,
      );
      expect(
        CustomerRfmService.frequencyQuantiles(profiles, const []),
        isEmpty,
      );
    });

    test('band: a value exactly on a cut-off lands in the higher band', () {
      const cutoffs = [150.0, 225.0];
      expect(CustomerRfmService.band(0, cutoffs), 0);
      expect(CustomerRfmService.band(149.99, cutoffs), 0);
      expect(CustomerRfmService.band(150, cutoffs), 1);
      expect(CustomerRfmService.band(224, cutoffs), 1);
      expect(CustomerRfmService.band(225, cutoffs), 2);
      expect(CustomerRfmService.band(1000000, cutoffs), 2);
      expect(CustomerRfmService.band(5, const <double>[]), 0);
    });
  });
}
