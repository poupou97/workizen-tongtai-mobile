import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-153 — the Revenue Capability Context, built through the **real**
/// `RevenueCapabilityProvider` over an in-memory `OrderRepository` (the
/// production seam; only the storage is swapped). Every expectation is
/// hand-computed from the fixtures, and the clock is always injected — the
/// provider must never read one itself.
void main() {
  // Fixed clock. July 2026 is the running month, so the default 12-month window
  // is the completed months Jul 2025 … Jun 2026.
  final now = DateTime(2026, 7, 15, 9, 30);

  // Identity-shaped fixture values: none of these may ever appear in the
  // PII-free prompt block (ADR-TON-016 / D-7).
  const customerId = 'c-nguyen-thi-mai';
  const orderNumber = 'DH-2026-0142';
  const productName = 'Áo dài lụa Hà Đông';

  var nextId = 0;
  CustomerOrder order(
    DateTime date,
    double total, {
    OrderStatus status = OrderStatus.delivered,
  }) {
    nextId += 1;
    return CustomerOrder(
      id: 'o$nextId',
      customerId: customerId,
      orderNumber: orderNumber,
      date: date,
      status: status,
      items: [
        OrderItem(
          productName: productName,
          category: 'Fashion',
          quantity: 1,
          unitPrice: total,
        ),
      ],
    );
  }

  /// One order of the given amount in each listed month of 2026.
  List<CustomerOrder> monthly2026(Map<int, double> revenueByMonth) => [
    for (final entry in revenueByMonth.entries)
      order(DateTime(2026, entry.key, 15), entry.value),
  ];

  Future<RevenueCapabilityContext> load(
    List<CustomerOrder> orders, {
    int windowMonths = kRevenueCapabilityWindowMonths,
    int comparisonMonths = kRevenueCapabilityComparisonMonths,
  }) => RevenueCapabilityProvider(
    InMemoryOrderRepository(orders),
    clock: () => now,
    windowMonths: windowMonths,
    comparisonMonths: comparisonMonths,
  ).load();

  setUp(() => nextId = 0);

  group('provider + metadata', () {
    test(
      'default window: 12 completed months, running month excluded',
      () async {
        final context = await load(monthly2026({6: 100000}));

        expect(context.capability, 'revenue');
        expect(context.version, kRevenueCapabilityVersion);
        expect(context.series.length, 12);
        expect(context.series.points.first.year, 2025);
        expect(context.series.points.first.month, 7);
        expect(context.series.points.last.year, 2026);
        expect(context.series.points.last.month, 6);
        expect(context.windowMonths, 12);
        expect(context.comparisonMonths, 3);
        expect(context.currentMonthExcluded, isTrue);
      },
    );

    test('generatedAt is the injected clock, never DateTime.now()', () async {
      final context = await load(monthly2026({6: 100000}));
      expect(context.generatedAt, now);
    });

    test('a different clock moves the window — the clock is the only input '
        'that is not the orders', () async {
      final orders = monthly2026({6: 100000});
      final later = await RevenueCapabilityProvider(
        InMemoryOrderRepository(orders),
        clock: () => DateTime(2027, 1, 5),
        windowMonths: 3,
      ).load();

      // Oct, Nov, Dec 2026 — June is out of the window, so no revenue.
      expect(later.series.points.map((p) => p.month), [10, 11, 12]);
      expect(later.hasData, isFalse);
      expect(later.generatedAt, DateTime(2027, 1, 5));
    });

    test('the running month never enters the analysable base', () async {
      final context = await load([
        order(DateTime(2026, 7, 2), 900000), // running month
        order(DateTime(2026, 6, 10), 100000),
      ], windowMonths: 3);

      expect(context.totalRevenue, 100000);
      expect(context.latestMonth!.month, 6);
    });
  });

  group('billable exclusion (the shared isBillableOrder rule)', () {
    test('cancelled orders are not revenue, but stay in the lifetime '
        'order history', () async {
      final context = await load([
        order(DateTime(2026, 6, 10), 100000),
        order(DateTime(2026, 6, 11), 900000, status: OrderStatus.cancelled),
        order(DateTime(2026, 6, 12), 50000, status: OrderStatus.pending),
      ], windowMonths: 1);

      expect(context.totalRevenue, 150000);
      expect(context.billableOrders, 2);
      expect(context.averageOrderValue, 75000);
      // Lifetime lifecycle summary counts every order, all statuses.
      expect(context.orderHistory.total, 3);
      expect(context.orderHistory.status(OrderStatus.cancelled), 1);
      expect(context.orderHistory.openCount, 1); // the pending one
    });

    test(
      'a window of nothing but cancelled orders is honestly "no data"',
      () async {
        final context = await load([
          order(DateTime(2026, 6, 10), 900000, status: OrderStatus.cancelled),
        ], windowMonths: 3);

        expect(context.hasData, isFalse);
        expect(context.totalRevenue, 0);
        expect(context.orderHistory.total, 1);
      },
    );
  });

  group('growth · trend · comparison — ramp 100k…600k (Jan–Jun 2026)', () {
    late RevenueCapabilityContext context;

    setUp(() async {
      context = await load(
        monthly2026({
          1: 100000,
          2: 200000,
          3: 300000,
          4: 400000,
          5: 500000,
          6: 600000,
        }),
        windowMonths: 6,
      );
    });

    test('totals and AOV', () {
      expect(context.hasData, isTrue);
      expect(context.series.length, 6);
      expect(context.monthsWithRevenue, 6);
      expect(context.totalRevenue, 2100000);
      expect(context.billableOrders, 6);
      expect(context.averageOrderValue, 350000); // 2.1M / 6
      expect(context.latestMonth!.revenue, 600000);
    });

    test('month-over-month growth = (600k − 500k) / 500k = +20%', () {
      expect(context.monthOverMonthGrowth, closeTo(0.2, 1e-12));
    });

    test('trend slope = a perfect +100k per month', () {
      expect(context.trendSlopePerMonth, closeTo(100000, 1e-6));
    });

    test('window comparison: Apr–Jun 1.5M vs Jan–Mar 600k = +150%', () {
      final comparison = context.comparison;

      expect(comparison.hasBothWindows, isTrue);
      expect(comparison.months, 3);
      expect(comparison.recentRevenue, 1500000);
      expect(comparison.previousRevenue, 600000);
      expect(comparison.revenueChange, closeTo(1.5, 1e-12));
      expect(comparison.recentOrders, 3);
      expect(comparison.previousOrders, 3);
    });

    test('comparison refuses a half-covered window', () async {
      final wide = await load(
        monthly2026({
          1: 100000,
          2: 200000,
          3: 300000,
          4: 400000,
          5: 500000,
          6: 600000,
        }),
        windowMonths: 6,
        comparisonMonths: 4,
      );

      expect(wide.comparison.hasBothWindows, isFalse);
      expect(wide.comparison.recentRevenue, 0);
      expect(wide.comparison.months, 4);
    });

    test('seasonality needs a full year — 6 months yields none', () {
      expect(context.seasonalIndex, isNull);
    });
  });

  group('volatility + seasonality delegate to the analytics series', () {
    test('swinging 100·200·100·200 → the analytics-proven 0.8485…', () async {
      final context = await load(
        monthly2026({3: 100000, 4: 200000, 5: 100000, 6: 200000}),
        windowMonths: 4,
      );

      expect(context.volatility, closeTo(0.8485281374, 1e-9));
    });

    test(
      '12 months with a 2× July → a seasonal index above 1 for July',
      () async {
        // Window Jul 2025 … Jun 2026 — every calendar month appears once.
        final context = await load([
          order(DateTime(2025, 7, 15), 200000),
          for (var back = 1; back < 12; back++)
            order(DateTime(2025, 7 + back, 15), 100000),
        ]);

        final seasonal = context.seasonalIndex!;
        expect(seasonal.length, 12);
        // mean = (200k + 11·100k)/12 = 108,333.33
        expect(seasonal[7], closeTo(200000 / (1300000 / 12), 1e-9));
        expect(seasonal[1], closeTo(100000 / (1300000 / 12), 1e-9));
        expect(context.promptBlock(), contains('Mùa vụ: cao nhất T7'));
      },
    );
  });

  group('hasData honesty', () {
    test('an empty repository has no data and says so plainly', () async {
      final context = await load(const []);

      expect(context.hasData, isFalse);
      expect(context.totalRevenue, 0);
      expect(context.orderHistory.total, 0);

      final block = context.promptBlock();
      expect(block, contains('CHƯA ĐỦ DỮ LIỆU'));
      expect(block, contains('0 đơn'));
      expect(
        block,
        contains('Không được suy ra xu hướng, tăng trưởng hay dự báo'),
      );
      // No zero-shaped statistics that an LLM would read as real numbers.
      expect(block, isNot(contains('AOV')));
      expect(block, isNot(contains('Tăng trưởng')));
      expect(block, isNot(contains('Xu hướng tuyến tính')));
      expect(block, isNot(contains('Độ biến động')));
    });

    test(
      'orders exist but all fall outside the window → still no data',
      () async {
        final context = await load([
          order(DateTime(2024, 6, 10), 5000000),
        ], windowMonths: 3);

        expect(context.hasData, isFalse);
        final block = context.promptBlock();
        expect(block, contains('CHƯA ĐỦ DỮ LIỆU'));
        expect(block, contains('1 đơn'));
        expect(block, contains('không đơn nào rơi vào cửa sổ'));
      },
    );
  });

  group('promptBlock — the AI-facing surface', () {
    test('states the numbers a forecast needs, hand-checked', () async {
      final context = await load(
        monthly2026({
          1: 100000,
          2: 200000,
          3: 300000,
          4: 400000,
          5: 500000,
          6: 600000,
        }),
        windowMonths: 6,
      );

      final block = context.promptBlock();
      expect(block, startsWith('# Capability: revenue (v1)'));
      expect(block, contains('Cửa sổ phân tích: 6 tháng hoàn chỉnh'));
      expect(block, contains('Doanh thu billable: 2.100.000 ₫ · 6 đơn'));
      expect(block, contains('AOV 350.000 ₫'));
      expect(block, contains('Tháng có doanh thu: 6/6'));
      expect(block, contains('Tháng gần nhất 2026-06: 600.000 ₫'));
      expect(block, contains('+20,0%')); // month over month
      expect(block, contains('+150,0%')); // window comparison
      expect(block, contains('100.000 ₫/tháng')); // trend slope
      expect(block, contains('Lịch sử đơn (toàn bộ vòng đời): 6 đơn'));
    });

    test(
      'carries no identity: no customer id, order number or product name',
      () async {
        final context = await load(
          monthly2026({4: 100000, 5: 200000, 6: 300000}),
        );

        final block = context.promptBlock();
        expect(block, isNot(contains(customerId)));
        expect(block, isNot(contains(orderNumber)));
        expect(block, isNot(contains(productName)));
        expect(block, isNot(contains('Mai'))); // the name hidden in the id
        expect(block, isNot(contains('DH-')));
      },
    );

    test('is pure: same orders + same clock → byte-identical block', () async {
      final orders = monthly2026({4: 100000, 5: 200000, 6: 300000});
      final first = await load(orders);
      final second = await load(orders.reversed.toList());

      expect(first.promptBlock(), second.promptBlock());
    });
  });
}
