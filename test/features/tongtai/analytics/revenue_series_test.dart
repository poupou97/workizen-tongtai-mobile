import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/revenue_series.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-149 — [RevenueSeries] is the Aggregation Service every revenue-shaped
/// prediction reads (One Data Path: `Repository → Aggregation Services →
/// Capability Context → Rule Twin`). Every expectation below is hand-computed:
/// the fixtures are chosen so the arithmetic can be checked on paper, never
/// "whatever the code returned".
void main() {
  // Fixed clock — the service never reads one, the test always supplies it.
  final now = DateTime(2026, 7, 15, 10, 30);

  var nextId = 0;
  CustomerOrder order(
    DateTime date,
    double total, {
    OrderStatus status = OrderStatus.delivered,
    String customerId = 'c1',
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

  /// One order of [revenue] đồng in each listed month of 2026.
  List<CustomerOrder> monthly(Map<int, double> revenueByMonth2026) => [
    for (final entry in revenueByMonth2026.entries)
      order(DateTime(2026, entry.key, 15), entry.value),
  ];

  setUp(() => nextId = 0);

  group('fromOrders — window shape', () {
    test(
      'emits one point per month, oldest → newest, current month dropped',
      () {
        final series = RevenueSeries.fromOrders(const [], now: now);

        // now = Jul 2026; the running month is excluded, so the window is the 12
        // complete months Jul 2025 … Jun 2026.
        expect(series.length, 12);
        expect(series.points.first.year, 2025);
        expect(series.points.first.month, 7);
        expect(series.points.last.year, 2026);
        expect(series.points.last.month, 6);
        expect(series.currentMonthExcluded, isTrue);
      },
    );

    test('excludeCurrentMonth: false ends on the running month', () {
      final series = RevenueSeries.fromOrders(
        const [],
        now: now,
        excludeCurrentMonth: false,
      );

      expect(series.length, 12);
      expect(series.points.first.month, 8); // Aug 2025
      expect(series.points.first.year, 2025);
      expect(series.points.last.month, 7); // Jul 2026
      expect(series.currentMonthExcluded, isFalse);
    });

    test('non-positive months yields an empty, well-formed series', () {
      final series = RevenueSeries.fromOrders(
        monthly({5: 100}),
        now: now,
        months: 0,
      );

      expect(series.isEmpty, isTrue);
      expect(series.totalRevenue, 0);
      expect(
        series.averageOrderValue,
        0,
      ); // no orders → no average, not a throw
      expect(series.latest, isNull);
      expect(series.monthOverMonthChange, isNull);
      expect(series.trailingAverage(3), 0);
      expect(series.weightedTrailingAverage(3), 0);
      expect(series.linearTrendSlope(), isNull);
      expect(series.volatility(), isNull);
      expect(series.seasonalIndex(), isNull);
      expect(series.compareWindows(3).hasBothWindows, isFalse);
    });

    test('RevenueSeries.empty is a usable zero snapshot', () {
      expect(RevenueSeries.empty.isEmpty, isTrue);
      expect(RevenueSeries.empty.totalRevenue, 0);
      expect(RevenueSeries.empty.hasRevenue, isFalse);
    });
  });

  group('fromOrders — bucketing', () {
    test(
      'month boundaries: 1st 00:00 and last day 23:59 stay in their month',
      () {
        final series = RevenueSeries.fromOrders(
          [
            order(DateTime(2026, 6, 1, 0, 0), 100),
            order(DateTime(2026, 6, 30, 23, 59, 59), 200),
            order(DateTime(2026, 5, 31, 23, 59, 59), 400),
          ],
          now: now,
          months: 3,
        );

        // months: 3, current excluded → Apr, May, Jun 2026.
        expect(series.length, 3);
        expect(series.points[0].month, 4);
        expect(series.points[0].revenue, 0);
        expect(series.points[1].month, 5);
        expect(series.points[1].revenue, 400);
        expect(series.points[2].month, 6);
        expect(series.points[2].revenue, 300); // 100 + 200
        expect(series.points[2].orderCount, 2);
        expect(series.totalRevenue, 700);
      },
    );

    test('the running month is excluded from the analysable base', () {
      final orders = [
        order(DateTime(2026, 7, 1, 0, 0), 800), // current month
        order(DateTime(2026, 6, 10), 100),
      ];

      final analysed = RevenueSeries.fromOrders(orders, now: now, months: 3);
      expect(analysed.totalRevenue, 100);
      expect(analysed.points.last.month, 6);

      final withCurrent = RevenueSeries.fromOrders(
        orders,
        now: now,
        months: 3,
        excludeCurrentMonth: false,
      );
      expect(withCurrent.totalRevenue, 900);
      expect(withCurrent.points.last.month, 7);
      expect(withCurrent.points.last.revenue, 800);
    });

    test('months without orders are emitted as explicit zeros, not gaps', () {
      final series = RevenueSeries.fromOrders(monthly({3: 500}), now: now);

      expect(series.length, 12);
      expect(series.points.where((p) => p.isEmpty).length, 11);
      expect(series.monthsWithRevenue, 1);
      expect(series.hasRevenue, isTrue);
      final march = series.points.singleWhere((p) => p.month == 3);
      expect(march.revenue, 500);
      for (final point in series.points.where((p) => p.month != 3)) {
        expect(point.revenue, 0);
        expect(point.orderCount, 0);
        expect(point.customerCount, 0);
        expect(point.averageOrderValue, 0);
      }
    });

    test('cancelled orders never count as revenue (shared billable rule)', () {
      final series = RevenueSeries.fromOrders(
        [
          order(DateTime(2026, 6, 10), 100),
          order(DateTime(2026, 6, 11), 900, status: OrderStatus.cancelled),
          order(DateTime(2026, 6, 12), 50, status: OrderStatus.pending),
        ],
        now: now,
        months: 1,
      );

      expect(series.points.single.revenue, 150);
      expect(series.points.single.orderCount, 2);
    });

    test('orders outside the window are ignored', () {
      final series = RevenueSeries.fromOrders(
        [
          order(DateTime(2024, 6, 10), 999999),
          order(DateTime(2026, 6, 10), 100),
        ],
        now: now,
        months: 3,
      );

      expect(series.totalRevenue, 100);
      expect(series.totalOrders, 1);
    });

    test('a point counts distinct customers and derives AOV', () {
      final series = RevenueSeries.fromOrders(
        [
          order(DateTime(2026, 6, 2), 100),
          order(DateTime(2026, 6, 12), 200),
          order(DateTime(2026, 6, 22), 300, customerId: 'c2'),
        ],
        now: now,
        months: 1,
      );

      final june = series.points.single;
      expect(june.revenue, 600);
      expect(june.orderCount, 3);
      expect(june.customerCount, 2);
      expect(june.averageOrderValue, 200);
      expect(june.isEmpty, isFalse);
    });
  });

  group(
    'statistics — linear fixture 100·200·300·400·500·600 (Jan–Jun 2026)',
    () {
      late RevenueSeries series;

      setUp(() {
        series = RevenueSeries.fromOrders(
          monthly({1: 100, 2: 200, 3: 300, 4: 400, 5: 500, 6: 600}),
          now: now,
          months: 6,
        );
      });

      test('totals', () {
        expect(series.length, 6);
        expect(series.totalRevenue, 2100);
        expect(series.totalOrders, 6);
        expect(series.monthsWithRevenue, 6);
        expect(series.latest!.revenue, 600);
      });

      test('averageOrderValue over the window: 2100 / 6 = 350', () {
        expect(series.averageOrderValue, 350);
      });

      test('monthOverMonthChange = (600 − 500) / 500 = 0.2', () {
        expect(series.monthOverMonthChange, closeTo(0.2, 1e-12));
      });

      test('trailingAverage: (400+500+600)/3 = 500; whole series = 350', () {
        expect(series.trailingAverage(3), 500);
        expect(series.trailingAverage(6), 350);
        expect(series.trailingAverage(99), 350); // clamps to what exists
        expect(series.trailingAverage(0), 0);
        expect(series.trailingAverage(-1), 0);
      });

      test(
        'weightedTrailingAverage(3): (1·400 + 2·500 + 3·600)/6 = 533.33…',
        () {
          expect(series.weightedTrailingAverage(3), closeTo(3200 / 6, 1e-9));
          expect(series.weightedTrailingAverage(1), 600);
        },
      );

      test('linearTrendSlope: a perfect +100/month ramp', () {
        expect(series.linearTrendSlope(), closeTo(100, 1e-9));
      });

      test('compareWindows(3): 1500 vs 600 = +150%, orders flat', () {
        final comparison = series.compareWindows(3);

        expect(comparison.hasBothWindows, isTrue);
        expect(comparison.months, 3);
        expect(comparison.recentRevenue, 1500); // Apr+May+Jun
        expect(comparison.previousRevenue, 600); // Jan+Feb+Mar
        expect(comparison.revenueDelta, 900);
        expect(comparison.revenueChange, closeTo(1.5, 1e-12));
        expect(comparison.recentOrders, 3);
        expect(comparison.previousOrders, 3);
        expect(comparison.ordersChange, 0);
      });

      test('compareWindows refuses a half-covered comparison', () {
        // 6 points cannot serve two 4-month windows.
        final comparison = series.compareWindows(4);

        expect(comparison.hasBothWindows, isFalse);
        expect(comparison.recentRevenue, 0);
        expect(comparison.previousRevenue, 0);
        expect(comparison.revenueChange, isNull);
        expect(comparison.months, 4);
        expect(series.compareWindows(0).hasBothWindows, isFalse);
      });
    },
  );

  group('monthOverMonthChange edge cases', () {
    test('null with fewer than two months', () {
      final series = RevenueSeries.fromOrders(
        monthly({6: 100}),
        now: now,
        months: 1,
      );
      expect(series.monthOverMonthChange, isNull);
    });

    test(
      'null when the earlier month booked nothing (no growth from zero)',
      () {
        final series = RevenueSeries.fromOrders(
          monthly({6: 100}),
          now: now,
          months: 2,
        ); // May = 0, Jun = 100
        expect(series.monthOverMonthChange, isNull);
      },
    );
  });

  group('volatility', () {
    test(
      'swinging 100·200·100·200 → σ 0.70710678 / mean|Δ| 0.83333 = 0.848528',
      () {
        final series = RevenueSeries.fromOrders(
          monthly({3: 100, 4: 200, 5: 100, 6: 200}),
          now: now,
          months: 4,
        );

        // changes = [+1.0, −0.5, +1.0]; mean = 0.5; mean|Δ| = 2.5/3;
        // population σ = sqrt((0.25 + 1 + 0.25)/3) = sqrt(0.5) = 0.70710678…
        expect(series.volatility(), closeTo(0.8485281374, 1e-9));
      },
    );

    test('steady +10% every month → 0 (no dispersion)', () {
      final series = RevenueSeries.fromOrders(
        monthly({4: 100, 5: 110, 6: 121}),
        now: now,
        months: 3,
      );
      expect(series.volatility(), closeTo(0, 1e-9));
    });

    test('null with fewer than two usable changes', () {
      final two = RevenueSeries.fromOrders(
        monthly({5: 100, 6: 200}),
        now: now,
        months: 2,
      );
      expect(two.volatility(), isNull);

      final none = RevenueSeries.fromOrders(const [], now: now);
      expect(none.volatility(), isNull); // all-zero history has no changes
    });

    test('a jump out of a zero month is skipped, not treated as +∞', () {
      // Window Mar–Jun = 0 · 100 · 200 · 400. Mar→Apr is skipped (nothing to
      // grow from); the usable changes are [+1.0, +1.0] → no dispersion → 0.
      final series = RevenueSeries.fromOrders(
        monthly({3: 0, 4: 100, 5: 200, 6: 400}),
        now: now,
        months: 4,
      );
      expect(series.volatility(), closeTo(0, 1e-12));
    });
  });

  group('seasonalIndex', () {
    test('null below 12 months — a yearly shape needs a year', () {
      final series = RevenueSeries.fromOrders(
        monthly({1: 100, 2: 100, 3: 100}),
        now: now,
        months: 11,
      );
      expect(series.length, 11);
      expect(series.seasonalIndex(), isNull);
    });

    test('null when 12 months booked nothing at all', () {
      final series = RevenueSeries.fromOrders(const [], now: now);
      expect(series.length, 12);
      expect(series.seasonalIndex(), isNull);
    });

    test(
      '12 months: a 200 July against eleven 100s → mean 108.33, index 1.846',
      () {
        // Window Jul 2025 … Jun 2026 — every calendar month appears exactly once.
        final series = RevenueSeries.fromOrders([
          order(DateTime(2025, 7, 15), 200),
          for (var back = 1; back < 12; back++)
            order(DateTime(2025, 7 + back, 15), 100),
        ], now: now);

        final index = series.seasonalIndex()!;
        expect(index.length, 12);
        // mean = (200 + 11·100) / 12 = 1300/12 = 108.3333…
        expect(index[7], closeTo(200 / (1300 / 12), 1e-9)); // 1.846153…
        expect(index[1], closeTo(100 / (1300 / 12), 1e-9)); // 0.923076…
        expect(index[7]! > index[1]!, isTrue);
      },
    );
  });

  test('purity: same orders + same now → identical points', () {
    final orders = monthly({4: 100, 5: 200, 6: 300});
    final first = RevenueSeries.fromOrders(orders, now: now, months: 3);
    final second = RevenueSeries.fromOrders(
      orders.reversed,
      now: now,
      months: 3,
    );

    expect(first.points, second.points); // order of input is irrelevant
    expect(first.volatility(), second.volatility());
  });
}
