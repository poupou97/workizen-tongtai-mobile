import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-154 — the Customer Capability Context, built through the **real**
/// `CustomerCapabilityProvider` over in-memory repositories.
///
/// The directory below is hand-built so every bucket is checkable on a calendar:
/// a loyal recent buyer, a cooling one, an at-risk one, a churned one, a
/// never-bought one, plus the two cases where the customer's **own cadence**
/// must beat the fixed 30/60/90-day windows in both directions.
void main() {
  final now = DateTime(2026, 7, 15);

  // Real-looking PII on every fixture customer — none of it may reach the
  // prompt block (ADR-TON-016 / D-7 privacy red-line).
  const fixtureName = 'Nguyễn Thị Mai';
  const fixturePhone = '+84912345678';

  Customer customer(String id) => Customer(
    id: id,
    name: fixtureName,
    phone: fixturePhone,
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
    email: 'mai@example.com',
  );

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
          productName: 'Khăn lụa',
          category: 'Fashion',
          quantity: 1,
          unitPrice: total,
        ),
      ],
    );
  }

  // ── The directory ────────────────────────────────────────────────────────
  //
  //  id            orders                              recency  cadence  spend
  //  c-loyal       15/4, 15/5, 15/6, 5/7 2026            10 d    30 d    2.0M
  //  c-cooling     31/5/2026 (single)                    45 d    —       300k
  //  c-at-risk     1/5/2026 (single)                     75 d    —       5.0M
  //  c-churned     27/12/2025 (single)                  200 d    —       100k
  //  c-never       none                                   —      —          0
  //  c-weekly      1/5, 8/5, 15/5, 22/5 2026             54 d     7 d    1.0M
  //  c-quarterly   1/10/2025, 1/1/2026, 1/4/2026        105 d    91 d    6.0M
  //  c-new         10/7/2026 (single, first ever)         5 d     —      400k
  const ids = [
    'c-loyal',
    'c-cooling',
    'c-at-risk',
    'c-churned',
    'c-never',
    'c-weekly',
    'c-quarterly',
    'c-new',
  ];

  List<CustomerOrder> fixtureOrders() => [
    // Monthly buyer, bought 10 days ago → well inside their own 30-day rhythm.
    order('c-loyal', DateTime(2026, 4, 15), 500000),
    order('c-loyal', DateTime(2026, 5, 15), 500000),
    order('c-loyal', DateTime(2026, 6, 15), 500000),
    order('c-loyal', DateTime(2026, 7, 5), 500000),
    // Single purchases — no cadence, so the fixed windows decide.
    order('c-cooling', DateTime(2026, 5, 31), 300000), // 45 days
    order('c-at-risk', DateTime(2026, 5, 1), 5000000), // 75 days
    order('c-churned', DateTime(2025, 12, 27), 100000), // 200 days
    // Weekly buyer gone quiet for 54 days: "cooling" by the fixed ladder,
    // churned against their own rhythm.
    order('c-weekly', DateTime(2026, 5, 1), 250000),
    order('c-weekly', DateTime(2026, 5, 8), 250000),
    order('c-weekly', DateTime(2026, 5, 15), 250000),
    order('c-weekly', DateTime(2026, 5, 22), 250000),
    // Quarterly buyer 105 days silent: "churned" by the fixed ladder, but only
    // 1.15× their own 91-day gap.
    order('c-quarterly', DateTime(2025, 10, 1), 2000000),
    order('c-quarterly', DateTime(2026, 1, 1), 2000000),
    order('c-quarterly', DateTime(2026, 4, 1), 2000000),
    // Just acquired.
    order('c-new', DateTime(2026, 7, 10), 400000),
  ];

  Future<CustomerCapabilityContext> load({
    List<String> directory = ids,
    List<CustomerOrder>? orders,
  }) => CustomerCapabilityProvider(
    InMemoryCustomerRepository([for (final id in directory) customer(id)]),
    InMemoryOrderRepository(orders ?? fixtureOrders()),
    clock: () => now,
  ).load();

  CustomerLifecycleStage stageOf(
    CustomerCapabilityContext context,
    String id,
  ) => customerLifecycleStage(
    context.profiles.singleWhere((profile) => profile.customerId == id),
  );

  setUp(() => nextId = 0);

  group('provider + metadata', () {
    test(
      'one profile per customer, in directory order, clock injected',
      () async {
        final context = await load();

        expect(context.capability, 'customer');
        expect(context.version, kCustomerCapabilityVersion);
        expect(context.generatedAt, now);
        expect(context.windowMonths, kCustomerCapabilityWindowMonths);
        expect(context.profiles.map((p) => p.customerId).toList(), ids);
        expect(context.totalCustomers, 8);
        expect(context.purchasingCustomers, 7);
      },
    );

    test('recency + monetary come straight from the RFM service', () async {
      final context = await load();
      final byId = {
        for (final profile in context.profiles) profile.customerId: profile,
      };

      expect(byId['c-loyal']!.recencyDays, 10);
      expect(byId['c-loyal']!.medianGapDays, 30); // gaps 30 · 31 · 20
      expect(byId['c-loyal']!.monetary, 2000000);
      expect(byId['c-cooling']!.recencyDays, 45);
      expect(byId['c-at-risk']!.recencyDays, 75);
      expect(byId['c-churned']!.recencyDays, 200);
      expect(byId['c-weekly']!.recencyDays, 54);
      expect(byId['c-weekly']!.medianGapDays, 7);
      expect(byId['c-quarterly']!.recencyDays, 105);
      expect(byId['c-quarterly']!.medianGapDays, 91); // gaps 92 · 90
      expect(byId['c-never']!.recencyDays, isNull); // never bought ≠ 0 days
    });
  });

  group('lifecycle segmentation', () {
    test('each fixture lands in its expected bucket', () async {
      final context = await load();

      expect(stageOf(context, 'c-loyal'), CustomerLifecycleStage.active);
      expect(stageOf(context, 'c-new'), CustomerLifecycleStage.active);
      expect(stageOf(context, 'c-cooling'), CustomerLifecycleStage.cooling);
      expect(stageOf(context, 'c-at-risk'), CustomerLifecycleStage.atRisk);
      expect(stageOf(context, 'c-churned'), CustomerLifecycleStage.churned);
      expect(
        stageOf(context, 'c-never'),
        CustomerLifecycleStage.neverPurchased,
      );
    });

    test(
      'a customer\'s own cadence beats the fixed window — both ways',
      () async {
        final context = await load();

        // 54 days of silence: the fixed ladder says "cooling" (31–60), but this
        // customer buys weekly — 54 / max(7, 14) = 3.86× their rhythm → churned.
        expect(stageOf(context, 'c-weekly'), CustomerLifecycleStage.churned);

        // 105 days of silence: the fixed ladder says "churned" (> 90), but a
        // quarterly buyer is only 105 / 91 = 1.15× overdue → cooling.
        expect(stageOf(context, 'c-quarterly'), CustomerLifecycleStage.cooling);
      },
    );

    test('the cadence floor protects very frequent buyers', () async {
      // Buys every 2 days, silent for 10 — without the 14-day floor this would
      // read as 5× overdue (churned); with it, 10/14 = 0.71 → still active.
      final context = await load(
        directory: const ['c-daily'],
        orders: [
          order('c-daily', DateTime(2026, 7, 1), 100000),
          order('c-daily', DateTime(2026, 7, 3), 100000),
          order('c-daily', DateTime(2026, 7, 5), 100000),
        ],
      );

      expect(context.profiles.single.recencyDays, 10);
      expect(context.profiles.single.medianGapDays, 2);
      expect(stageOf(context, 'c-daily'), CustomerLifecycleStage.active);
    });

    test(
      'stage counts are mutually exclusive and sum to the directory',
      () async {
        final context = await load();

        expect(context.stage(CustomerLifecycleStage.active), 2); // loyal, new
        expect(
          context.stage(CustomerLifecycleStage.cooling),
          2,
        ); // cooling, qtr
        expect(context.stage(CustomerLifecycleStage.atRisk), 1);
        expect(
          context.stage(CustomerLifecycleStage.churned),
          2,
        ); // churned, wkly
        expect(context.stage(CustomerLifecycleStage.neverPurchased), 1);
        expect(
          context.stageCounts.values.fold<int>(0, (sum, n) => sum + n),
          context.totalCustomers,
        );
      },
    );

    test('overlapping counts: new · returning · win-back', () async {
      final context = await load();

      // Only c-new placed its first order inside the 30-day window.
      expect(context.newCount, 1);
      // ≥ 2 lifetime orders: loyal (4), weekly (4), quarterly (3).
      expect(context.returningCount, 3);
      // Lapsed = at-risk + churned = 3 (at-risk, churned, weekly).
      expect(context.lapsedCount, 3);
      // Worth chasing: c-at-risk (top spend band) and c-weekly (4 orders).
      // c-churned bought once for 100k — no evidence they come back.
      expect(context.winBackCandidateCount, 2);
    });

    test('cancelled orders are invisible to the segmentation', () async {
      final context = await load(
        directory: const ['c-x'],
        orders: [
          order('c-x', DateTime(2026, 1, 10), 100000),
          // Would have made this customer "active" if it counted.
          order(
            'c-x',
            DateTime(2026, 7, 14),
            900000,
            status: OrderStatus.cancelled,
          ),
        ],
      );

      expect(context.profiles.single.monetary, 100000);
      expect(stageOf(context, 'c-x'), CustomerLifecycleStage.churned);
    });
  });

  group('recency distribution + bands', () {
    test('the raw histogram uses the fixed windows, not the cadence', () async {
      final context = await load();

      // c-weekly (54 d) sits in 31–60 here even though its *stage* is churned,
      // and c-quarterly (105 d) sits in > 90 even though its stage is cooling.
      expect(context.recency(CustomerRecencyBand.days0to30), 2);
      expect(context.recency(CustomerRecencyBand.days31to60), 2);
      expect(context.recency(CustomerRecencyBand.days61to90), 1);
      expect(context.recency(CustomerRecencyBand.over90), 2);
      expect(context.recency(CustomerRecencyBand.never), 1);
      expect(
        context.recencyDistribution.values.fold<int>(0, (sum, n) => sum + n),
        8,
      );
    });

    test('monetary bands: p50 = 700k, p80 = 3.8M over the 8 spends', () async {
      final context = await load();

      // Sorted lifetime spend: 0 · 100k · 300k · 400k · 1.0M · 2.0M · 5.0M · 6.0M
      // p50 at position 3.5 → 400k + 0.5·600k = 700k
      // p80 at position 5.6 → 2.0M + 0.6·3.0M = 3.8M
      expect(context.monetaryCutoffs, hasLength(2));
      expect(context.monetaryCutoffs[0], closeTo(700000, 1e-6));
      expect(context.monetaryCutoffs[1], closeTo(3800000, 1e-6));
      expect(context.monetaryBandCounts, [4, 2, 2]);
    });

    test('frequency bands: p50 = 1 order, p80 = 3.6 orders', () async {
      final context = await load();

      // Sorted lifetime orders: 0 · 1 · 1 · 1 · 1 · 3 · 4 · 4
      // p50 at position 3.5 → 1; p80 at position 5.6 → 3 + 0.6 = 3.6
      expect(context.frequencyCutoffs[0], closeTo(1, 1e-9));
      expect(context.frequencyCutoffs[1], closeTo(3.6, 1e-9));
      expect(context.frequencyBandCounts, [1, 5, 2]);
    });
  });

  group('hasData honesty', () {
    test('an empty directory has no data and says so plainly', () async {
      final context = await load(directory: const [], orders: const []);

      expect(context.hasData, isFalse);
      expect(context.totalCustomers, 0);
      expect(context.monetaryCutoffs, isEmpty);

      final block = context.promptBlock();
      expect(block, contains('CHƯA ĐỦ DỮ LIỆU'));
      expect(block, contains('danh bạ khách hàng đang trống'));
      expect(block, isNot(contains('Vòng đời')));
      expect(block, isNot(contains('Phân bố recency')));
    });

    test('a directory where nobody has bought is still real data', () async {
      final context = await load(
        directory: const ['c-a', 'c-b'],
        orders: const [],
      );

      expect(context.hasData, isTrue);
      expect(context.stage(CustomerLifecycleStage.neverPurchased), 2);
      expect(context.promptBlock(), contains('chưa mua: 2'));
    });
  });

  group('promptBlock — the AI-facing surface', () {
    test('reports the segmentation with its thresholds', () async {
      final block = (await load()).promptBlock();

      expect(block, startsWith('# Capability: customer (v1)'));
      expect(block, contains('hoạt động ≤30 ngày'));
      expect(block, contains('rời bỏ >90'));
      expect(block, contains('sàn 14 ngày'));
      expect(block, contains('Khách hàng: 8 · đã từng mua: 7 · chưa mua: 1'));
      expect(block, contains('đang hoạt động 2'));
      expect(block, contains('đã rời bỏ 2'));
      expect(block, contains('ứng viên win-back: 2/3'));
      expect(block, contains('≤30 ngày 2'));
    });

    test('is PII-free: no name, phone, email or customer id', () async {
      final block = (await load()).promptBlock();

      expect(block, isNot(contains(fixtureName)));
      expect(block, isNot(contains(fixturePhone)));
      expect(block, isNot(contains('Mai')));
      expect(block, isNot(contains('@')));
      expect(block, isNot(contains('Hà Nội')));
      for (final id in ids) {
        expect(block, isNot(contains(id)));
      }
    });

    test(
      'is pure: same directory + same clock → byte-identical block',
      () async {
        final first = await load();
        final second = await load();
        expect(first.promptBlock(), second.promptBlock());
      },
    );
  });
}
