library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import '../core/tongtai_enums.dart';
import '../finance/finance_transaction.dart';
import '../inventory/product.dart';
import '../journey/business_goal.dart';
import '../orders/order.dart';
import 'sample_data_seeder.dart';

/// **Historical Data Generator** — the deterministic, parameterized history the
/// Predictive Foundation (ADR-TON-016 Rule Twins) is developed and tested
/// against (WTM-149, Founder-approved Predictive Foundation).
///
/// A forecast rule cannot be built — let alone trusted — against the 8 hand
/// written sample orders of ADR-TON-014: there is no trend, no season and no
/// churn in them. This generator produces **months to years** of internally
/// consistent business history from a small [HistoricalDataSpec], so every
/// predictive rule can be exercised over a *known* ground truth.
///
/// What it guarantees:
///
/// - **Deterministic.** All randomness comes from `Random(spec.seed)`, consumed
///   in a fixed order. `DateTime.now()` is never called inside generation — the
///   only clock is the injected [HistoricalDataGenerator.clock], and only to
///   resolve `spec.endMonth` when the caller left it null. Same spec ⇒
///   byte-identical output.
/// - **Internally consistent.** Every [OrderItem] references a generated
///   [Product]; every order references a generated [Customer]; each customer's
///   `orderCount` / `totalSpent` / `lastPurchaseDate` is recomputed FROM the
///   generated orders (billable only — cancelled orders are excluded, per the
///   ADR-TON-011 KPI rule); every income transaction mirrors exactly one
///   billable order.
/// - **One seeding path.** Persistence reuses [SampleDataSeeder] — the same
///   production repositories, the same `sample-` id prefix, the same
///   remove-then-insert idempotency and the same orders-first delete order that
///   the SQLite foreign key requires (ADR-TON-014 §4). There is no second demo
///   business and no parallel writer.
///
/// **Opportunities and Timeline events are NOT generated here.** They are
/// *derived*: `OpportunityRuleEngine` reads the repositories and produces
/// opportunities, `BusinessEventSources` / `TimelineService` derive events from
/// the same rows. Fabricating them would recreate exactly the parallel-world
/// bug ADR-TON-014 was written to kill. Seed this data, then let those engines
/// run — that is the point of the generator.

/// The kind of business the history describes. Drives catalogue size and shape,
/// the average-order-value band, purchase frequency and the cost structure.
enum BusinessProfile {
  /// A small shop selling mixed consumer goods — many small baskets.
  retailShop,

  /// A wholesaler moving cartons — few orders, very large baskets, thin margin.
  wholesale,

  /// A food & drink outlet — very frequent, very small baskets.
  foodAndBeverage;

  String get labelEn => switch (this) {
    BusinessProfile.retailShop => 'Retail shop',
    BusinessProfile.wholesale => 'Wholesale',
    BusinessProfile.foodAndBeverage => 'Food & beverage',
  };

  String get labelVi => switch (this) {
    BusinessProfile.retailShop => 'Cửa hàng bán lẻ',
    BusinessProfile.wholesale => 'Bán sỉ',
    BusinessProfile.foodAndBeverage => 'Ăn uống',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// The long-run trend applied on top of seasonality, as a compounding annual
/// factor (see [kGrowthAnnualFactors]).
enum GrowthPattern { flat, moderateGrowth, fastGrowth, decline }

/// Annual multiplier per [GrowthPattern]; a month's growth factor is
/// `pow(annual, monthIndex / 12)`, so the shape is smooth and window-length
/// independent.
const Map<GrowthPattern, double> kGrowthAnnualFactors = {
  GrowthPattern.flat: 1.0,
  GrowthPattern.moderateGrowth: 1.5,
  GrowthPattern.fastGrowth: 3.0,
  GrowthPattern.decline: 0.55,
};

/// The repeating within-year shape.
enum SeasonalityPattern {
  /// Every month weighs the same — the control case for trend tests.
  none,

  /// Vietnamese retail year (see [kVietnamRetailMonthlyMultipliers]).
  vietnamRetail,
}

/// Monthly demand multipliers for [SeasonalityPattern.vietnamRetail], indexed
/// `month - 1` (January first). Three features are deliberately modelled:
///
/// - **Tết peak** — the lunar new year falls in late Jan / Feb, and the buying
///   run-up starts weeks earlier: Jan `1.45`, Feb `1.55`, followed by the
///   well-known post-Tết trough in Mar (`0.75`) / Apr (`0.85`).
/// - **Summer bump** — Jun `1.15`, Jul `1.10` (school holidays, hot season).
/// - **Year-end push** — Nov `1.20` (11.11 / 12.12 sales) and Dec `1.35`
///   (year-end spending plus Tết stocking).
const List<double> kVietnamRetailMonthlyMultipliers = [
  1.45, // Jan — Tết run-up
  1.55, // Feb — Tết peak
  0.75, // Mar — post-Tết trough
  0.85, // Apr — post-Tết trough
  1.00, // May
  1.15, // Jun — summer bump
  1.10, // Jul — summer bump
  0.90, // Aug
  0.95, // Sep
  1.00, // Oct
  1.20, // Nov — year-end push
  1.35, // Dec — year-end push
];

/// How a generated customer behaves over the window. The behaviour is not a
/// label bolted onto a random customer — it *shapes the orders*: when the
/// customer started, the cadence between purchases and how long ago they last
/// bought (see [HistoricalDataGenerator]).
enum CustomerBehaviour {
  /// First bought inside the last few months of the window.
  newcomer,

  /// Buys on a regular monthly cadence, right up to the end of the window.
  loyal,

  /// Buys every couple of months; last purchase is recent.
  returning,

  /// Was regular, gaps are widening; last purchase a few months back.
  slowing,

  /// Stopped buying — silent longer than their own cadence, but still inside
  /// the churn window ([kHistoricalChurnWindowDays]).
  atRisk,

  /// Silent for longer than the churn window.
  churned;

  String get labelEn => switch (this) {
    CustomerBehaviour.newcomer => 'New customer',
    CustomerBehaviour.loyal => 'Loyal',
    CustomerBehaviour.returning => 'Returning',
    CustomerBehaviour.slowing => 'Slowing down',
    CustomerBehaviour.atRisk => 'At risk',
    CustomerBehaviour.churned => 'Churned',
  };

  String get labelVi => switch (this) {
    CustomerBehaviour.newcomer => 'Khách mới',
    CustomerBehaviour.loyal => 'Khách trung thành',
    CustomerBehaviour.returning => 'Khách quay lại',
    CustomerBehaviour.slowing => 'Đang giảm nhịp',
    CustomerBehaviour.atRisk => 'Nguy cơ rời bỏ',
    CustomerBehaviour.churned => 'Đã rời bỏ',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Silence beyond this many days counts as churned. Used by the generator to
/// place [CustomerBehaviour.churned] last purchases, and shared with the
/// predictive rules so data and rule agree on one threshold.
const int kHistoricalChurnWindowDays = 180;

/// Every generated row carries this id prefix. It **starts with**
/// [kSampleIdPrefix], so `SampleDataSeeder.removeAll()` deletes generated
/// history too — one prefix, one removal path (ADR-TON-014 §4). The extra
/// `hist-` segment lets callers tell generated history from the 8 hand-written
/// fixtures without a second lifecycle.
const String kHistoricalIdPrefix = '${kSampleIdPrefix}hist-';

/// The distribution of [CustomerBehaviour] across the generated customers.
/// Fractions must sum to 1.0 (asserted); the generator apportions them with the
/// largest-remainder method, so counts sum exactly to the customer total.
@immutable
class CustomerMix {
  const CustomerMix({
    this.newcomers = 0.15,
    this.loyal = 0.20,
    this.returning = 0.30,
    this.slowing = 0.15,
    this.atRisk = 0.10,
    this.churned = 0.10,
  }) : assert(
         newcomers + loyal + returning + slowing + atRisk + churned >
                 0.999999 &&
             newcomers + loyal + returning + slowing + atRisk + churned <
                 1.000001,
         'CustomerMix fractions must sum to 1.0',
       ),
       assert(
         newcomers >= 0 &&
             loyal >= 0 &&
             returning >= 0 &&
             slowing >= 0 &&
             atRisk >= 0 &&
             churned >= 0,
         'CustomerMix fractions must be non-negative',
       );

  final double newcomers;
  final double loyal;
  final double returning;
  final double slowing;
  final double atRisk;
  final double churned;

  /// The requested fraction for [behaviour].
  double fractionOf(CustomerBehaviour behaviour) => switch (behaviour) {
    CustomerBehaviour.newcomer => newcomers,
    CustomerBehaviour.loyal => loyal,
    CustomerBehaviour.returning => returning,
    CustomerBehaviour.slowing => slowing,
    CustomerBehaviour.atRisk => atRisk,
    CustomerBehaviour.churned => churned,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerMix &&
          other.newcomers == newcomers &&
          other.loyal == loyal &&
          other.returning == returning &&
          other.slowing == slowing &&
          other.atRisk == atRisk &&
          other.churned == churned);

  @override
  int get hashCode =>
      Object.hash(newcomers, loyal, returning, slowing, atRisk, churned);
}

/// Everything the generator needs. There is **no hard-coded dataset** behind
/// it: change a knob and the whole history changes accordingly.
@immutable
class HistoricalDataSpec {
  const HistoricalDataSpec({
    this.months = 12,
    this.seed = 20260730,
    this.profile = BusinessProfile.retailShop,
    this.growth = GrowthPattern.moderateGrowth,
    this.seasonality = SeasonalityPattern.vietnamRetail,
    this.customerMix = const CustomerMix(),
    this.endMonth,
  }) : assert(months > 0, 'months must be at least 1');

  /// How many consecutive year-months to generate (3 / 12 / 24 / 36 / 60 are
  /// all supported). Every month in the window carries at least one order.
  final int months;

  /// The only source of randomness. Same seed ⇒ identical output.
  final int seed;

  final BusinessProfile profile;
  final GrowthPattern growth;
  final SeasonalityPattern seasonality;
  final CustomerMix customerMix;

  /// The last month generated (day/time ignored). Defaults to the month of the
  /// generator's injected clock.
  final DateTime? endMonth;

  HistoricalDataSpec copyWith({
    int? months,
    int? seed,
    BusinessProfile? profile,
    GrowthPattern? growth,
    SeasonalityPattern? seasonality,
    CustomerMix? customerMix,
    DateTime? endMonth,
  }) => HistoricalDataSpec(
    months: months ?? this.months,
    seed: seed ?? this.seed,
    profile: profile ?? this.profile,
    growth: growth ?? this.growth,
    seasonality: seasonality ?? this.seasonality,
    customerMix: customerMix ?? this.customerMix,
    endMonth: endMonth ?? this.endMonth,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoricalDataSpec &&
          other.months == months &&
          other.seed == seed &&
          other.profile == profile &&
          other.growth == growth &&
          other.seasonality == seasonality &&
          other.customerMix == customerMix &&
          other.endMonth == endMonth);

  @override
  int get hashCode => Object.hash(
    months,
    seed,
    profile,
    growth,
    seasonality,
    customerMix,
    endMonth,
  );

  @override
  String toString() =>
      'HistoricalDataSpec(months: $months, seed: $seed, '
      'profile: ${profile.name}, growth: ${growth.name}, '
      'seasonality: ${seasonality.name})';
}

/// The generated history, in memory — the pure result of
/// [HistoricalDataGenerator.generate], so rules and tests can work without a
/// database.
@immutable
class HistoricalDataSet {
  const HistoricalDataSet({
    required this.spec,
    required this.windowStart,
    required this.windowEnd,
    required this.customers,
    required this.products,
    required this.orders,
    required this.transactions,
    required this.goals,
    required this.behaviours,
  });

  final HistoricalDataSpec spec;

  /// First instant of the first generated month.
  final DateTime windowStart;

  /// Last instant of the last generated month — the "now" the data was built
  /// around, and the reference point for every recency assertion.
  final DateTime windowEnd;

  final List<Customer> customers;
  final List<Product> products;

  /// Chronological (oldest first); ids and order numbers increase with time.
  final List<CustomerOrder> orders;

  /// Chronological. Income mirrors billable orders 1:1; expenses are the
  /// monthly cost structure of the profile.
  final List<FinanceTransaction> transactions;

  final List<BusinessGoal> goals;

  /// customer id → the behaviour the generator planned for them. The orders
  /// remain the observable truth; this is the *intent* behind them, so tests
  /// and previews can group customers without re-deriving the behaviour.
  final Map<String, CustomerBehaviour> behaviours;

  CustomerBehaviour? behaviourOf(String customerId) => behaviours[customerId];

  /// Customers generated with [behaviour], in id order.
  List<Customer> customersWith(CustomerBehaviour behaviour) => [
    for (final c in customers)
      if (behaviours[c.id] == behaviour) c,
  ];

  /// Orders that count toward revenue — cancelled orders never do
  /// (ADR-TON-011).
  Iterable<CustomerOrder> get billableOrders =>
      orders.where((o) => o.status != OrderStatus.cancelled);

  List<CustomerOrder> ordersFor(String customerId) => [
    for (final o in orders)
      if (o.customerId == customerId) o,
  ];

  /// The months in the window, first day of each, oldest first.
  List<DateTime> get monthKeys => [
    for (var i = 0; i < spec.months; i++)
      DateTime(windowStart.year, windowStart.month + i),
  ];

  /// Billable revenue per month (first-day key), every month present.
  Map<DateTime, double> get revenueByMonth {
    final byMonth = <DateTime, double>{for (final m in monthKeys) m: 0};
    for (final o in billableOrders) {
      final key = DateTime(o.date.year, o.date.month);
      byMonth[key] = (byMonth[key] ?? 0) + o.totalAmount;
    }
    return byMonth;
  }

  /// Billable order count per month (first-day key), every month present.
  Map<DateTime, int> get orderCountByMonth {
    final byMonth = <DateTime, int>{for (final m in monthKeys) m: 0};
    for (final o in billableOrders) {
      final key = DateTime(o.date.year, o.date.month);
      byMonth[key] = (byMonth[key] ?? 0) + 1;
    }
    return byMonth;
  }

  double get totalRevenue =>
      billableOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

  @override
  String toString() =>
      'HistoricalDataSet(${spec.months} months, ${customers.length} customers, '
      '${products.length} products, ${orders.length} orders, '
      '${transactions.length} transactions)';
}

/// Generates a [HistoricalDataSet] from a [HistoricalDataSpec]. Pure and
/// deterministic — see the library doc for the guarantees.
class HistoricalDataGenerator {
  const HistoricalDataGenerator({this.clock});

  /// Injected clock. Used **only** to resolve [HistoricalDataSpec.endMonth]
  /// when the caller left it null; nothing inside generation reads the wall
  /// clock. Defaults to [DateTime.now] (the repo-wide convention).
  final DateTime Function()? clock;

  HistoricalDataSet generate(HistoricalDataSpec spec) {
    final rand = Random(spec.seed);
    final traits = _traitsFor(spec.profile);

    final now = (clock ?? DateTime.now)();
    final rawEnd = spec.endMonth ?? now;
    final endMonth = DateTime(rawEnd.year, rawEnd.month);
    final windowStart = DateTime(
      endMonth.year,
      endMonth.month - spec.months + 1,
    );
    final windowEnd = _endOfMonth(endMonth);
    final months = [
      for (var i = 0; i < spec.months; i++)
        DateTime(windowStart.year, windowStart.month + i),
    ];

    // ── 1. Catalogue ──────────────────────────────────────────────────────
    // Products exist before orders because every order line snapshots a real
    // product (Founder WTM-126). Stock levels are filled in afterwards, from
    // what the generated orders actually consumed.
    final catalogue = traits.catalogue;
    var products = <Product>[
      for (var i = 0; i < catalogue.length; i++)
        Product(
          id: '${kHistoricalIdPrefix}p${_pad(i + 1, 3)}',
          sku: catalogue[i].sku,
          name: catalogue[i].name,
          category: catalogue[i].category,
          quantity: 0,
          pricePerUnit: catalogue[i].price,
          reorderLevel: 0,
          updatedAt: windowEnd,
          description:
              '${catalogue[i].name} — ${catalogue[i].category}, '
              'đơn vị: ${catalogue[i].unit}.',
        ),
    ];

    // ── 2. Customers (identity + behaviour + activity plan) ───────────────
    final customerCount =
        traits.baseCustomers + (spec.months * traits.customersPerMonth).round();
    final behaviours = _apportionBehaviours(customerCount, spec.customerMix);
    final plans = <_PersonPlan>[];
    for (var i = 0; i < customerCount; i++) {
      final behaviour = behaviours[i];
      plans.add(
        _PersonPlan(
          id: '${kHistoricalIdPrefix}c${_pad(i + 1, 4)}',
          name: _nameFor(i),
          phone: '+84${900000000 + i * 1373}',
          // Only some customers left an email — a real CRM is never complete.
          email: i % 3 == 0 ? 'khach${_pad(i + 1, 3)}@example.com' : '',
          location: _kLocations[i % _kLocations.length],
          behaviour: behaviour,
          activeMonths: _activeMonths(behaviour, spec.months, rand),
        ),
      );
    }

    // ── 3. Orders ─────────────────────────────────────────────────────────
    final drafts = <_OrderDraft>[];
    for (final plan in plans) {
      for (final monthIndex in plan.activeMonths) {
        final multiplier = _monthMultiplier(
          spec,
          months[monthIndex],
          monthIndex,
        );
        // Orders in a cadence month = the profile's base frequency × the month
        // multiplier, split into a whole part plus a coin flip for the
        // fraction. Stochastic rounding keeps the EXPECTATION exactly
        // proportional to the multiplier, which is what makes a season or a
        // trend readable in the aggregate instead of being rounded away.
        var count = _stochasticRound(
          traits.ordersPerActiveMonth * multiplier,
          rand,
        );
        // A weak month may drop an order entirely — but never the customer's
        // first or last one, which anchor their recency story.
        final isEdge =
            monthIndex == plan.activeMonths.first ||
            monthIndex == plan.activeMonths.last;
        if (isEdge && count < 1) count = 1;
        if (count > 6) count = 6;
        for (var k = 0; k < count; k++) {
          drafts.add(
            _buildOrderDraft(
              plan: plan,
              month: months[monthIndex],
              monthsFromEnd: spec.months - 1 - monthIndex,
              multiplier: multiplier,
              traits: traits,
              products: products,
              catalogue: catalogue,
              rand: rand,
              seqHint: drafts.length,
            ),
          );
        }
      }
    }
    _ensureEveryMonthCovered(
      drafts: drafts,
      plans: plans,
      months: months,
      spec: spec,
      traits: traits,
      products: products,
      catalogue: catalogue,
      rand: rand,
    );

    // A customer's most recent order is never cancelled: their recency (and so
    // the behaviour the data is supposed to show) must not hinge on a coin
    // flip.
    for (final plan in plans) {
      final mine = drafts.where((d) => d.customerId == plan.id).toList()
        ..sort(_compareDrafts);
      if (mine.isEmpty) continue;
      if (mine.last.status == OrderStatus.cancelled) {
        mine.last.status = OrderStatus.delivered;
      }
    }

    drafts.sort(_compareDrafts);
    final orders = <CustomerOrder>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      orders.add(
        CustomerOrder(
          id: '${kHistoricalIdPrefix}o${_pad(i + 1, 5)}',
          customerId: d.customerId,
          orderNumber: 'DH-${d.date.year}-${_pad(i + 1, 5)}',
          date: d.date,
          status: d.status,
          items: d.items,
        ),
      );
    }

    // ── 4. Stock levels, from what actually sold ──────────────────────────
    final soldLastMonth = <String, int>{};
    final lastMonth = months.last;
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      if (o.date.year != lastMonth.year || o.date.month != lastMonth.month) {
        continue;
      }
      for (final item in o.items) {
        soldLastMonth[item.productId] =
            (soldLastMonth[item.productId] ?? 0) + item.quantity;
      }
    }
    products = [
      for (var i = 0; i < products.length; i++)
        _withStock(products[i], soldLastMonth[products[i].id] ?? 0, i, rand),
    ];

    // ── 5. Customers, reconciled with the orders ──────────────────────────
    final customers = <Customer>[];
    for (final plan in plans) {
      final billable = orders.where(
        (o) => o.customerId == plan.id && o.status != OrderStatus.cancelled,
      );
      var spent = 0.0;
      var count = 0;
      DateTime? last;
      for (final o in billable) {
        spent += o.totalAmount;
        count++;
        if (last == null || o.date.isAfter(last)) last = o.date;
      }
      customers.add(
        Customer(
          id: plan.id,
          name: plan.name,
          phone: plan.phone,
          location: plan.location,
          orderCount: count,
          totalSpent: spent,
          lastPurchaseDate: last,
          email: plan.email,
          // The behaviour is readable from the orders; the segment simply
          // names what the data already shows, so the Consumer facets and the
          // predictive rules agree instead of contradicting each other.
          segments: [plan.behaviour.labelVi],
        ),
      );
    }

    // ── 6. Finance ────────────────────────────────────────────────────────
    final transactions = _buildTransactions(
      orders: orders,
      months: months,
      traits: traits,
      rand: rand,
    );

    // ── 7. Goals, sized from the history that was just generated ──────────
    final goals = _buildGoals(
      orders: orders,
      customers: customers,
      months: months,
      windowEnd: windowEnd,
    );

    return HistoricalDataSet(
      spec: spec,
      windowStart: windowStart,
      windowEnd: windowEnd,
      customers: customers,
      products: products,
      orders: orders,
      transactions: transactions,
      goals: goals,
      behaviours: {for (final p in plans) p.id: p.behaviour},
    );
  }

  // ── month shape ─────────────────────────────────────────────────────────

  /// Demand multiplier for a month = long-run growth × within-year season.
  ///
  /// It drives the **order count** proportionally (so a `fastGrowth` year
  /// really does triple, and Feb really does out-sell March by the ratio of
  /// their multipliers), plus a damped effect on basket size — a peak month
  /// brings both more orders and slightly fuller ones.
  double _monthMultiplier(
    HistoricalDataSpec spec,
    DateTime month,
    int monthIndex,
  ) {
    final annual = kGrowthAnnualFactors[spec.growth]!;
    final growth = pow(annual, monthIndex / 12).toDouble();
    final season = spec.seasonality == SeasonalityPattern.none
        ? 1.0
        : kVietnamRetailMonthlyMultipliers[month.month - 1];
    return growth * season;
  }

  // ── customers ───────────────────────────────────────────────────────────

  /// Largest-remainder apportionment, so the behaviour counts sum EXACTLY to
  /// [total] and each is within one of `total × fraction`.
  List<CustomerBehaviour> _apportionBehaviours(int total, CustomerMix mix) {
    final quotas = [
      for (final b in CustomerBehaviour.values) total * mix.fractionOf(b),
    ];
    final counts = [for (final q in quotas) q.floor()];
    var assigned = counts.fold(0, (a, b) => a + b);
    final byRemainder =
        [for (var i = 0; i < quotas.length; i++) (i, quotas[i] - counts[i])]
          ..sort((a, b) {
            final c = b.$2.compareTo(a.$2);
            return c != 0 ? c : a.$1.compareTo(b.$1);
          });
    var k = 0;
    while (assigned < total && byRemainder.isNotEmpty) {
      counts[byRemainder[k % byRemainder.length].$1]++;
      assigned++;
      k++;
    }
    return [
      for (var i = 0; i < counts.length; i++)
        ...List.filled(counts[i], CustomerBehaviour.values[i]),
    ];
  }

  /// How many months before the end of the window the customer last bought.
  /// This is what makes a behaviour *visible in the data*.
  int _monthsSinceLastPurchase(
    CustomerBehaviour behaviour,
    int months,
    Random rand,
  ) {
    final int raw = switch (behaviour) {
      CustomerBehaviour.newcomer => 0,
      CustomerBehaviour.loyal => 0,
      CustomerBehaviour.returning => rand.nextInt(2),
      CustomerBehaviour.slowing => 2 + rand.nextInt(2),
      // Silent, but still inside the ~6-month churn window.
      CustomerBehaviour.atRisk => (months * 0.25).round().clamp(3, 5),
      // Silent for longer than the churn window whenever the window is long
      // enough to express it (>= 12 months); otherwise as far back as the
      // window allows.
      CustomerBehaviour.churned => max((months * 0.5).round(), 8),
    };
    return raw.clamp(0, months - 1);
  }

  /// The month indices in which a customer places orders — start, cadence and
  /// stop, derived from their behaviour.
  List<int> _activeMonths(
    CustomerBehaviour behaviour,
    int months,
    Random rand,
  ) {
    final lastIndex =
        months - 1 - _monthsSinceLastPurchase(behaviour, months, rand);
    // Everyone except a newcomer was already a customer when the window opens.
    // Staggering their first order instead would starve the first months and
    // bake a phantom ramp-up into every window — a trend rule would then
    // "discover" growth that is a generator artefact, not a business fact.
    final int firstIndex = switch (behaviour) {
      // Newcomers only exist in the last few months of the window.
      CustomerBehaviour.newcomer => max(
        0,
        months - 1 - rand.nextInt(max(1, min(3, months))),
      ),
      _ => 0,
    }.clamp(0, lastIndex);

    if (behaviour == CustomerBehaviour.slowing) {
      // Widening gaps: walk BACKWARDS from the last purchase with a shrinking
      // step, so read forwards the gaps grow (1, 2, 3, …) and the last order
      // still lands exactly on lastIndex.
      final indices = <int>[];
      var step = max(2, months ~/ 6);
      var idx = lastIndex;
      while (idx >= firstIndex) {
        indices.add(idx);
        idx -= step;
        step = max(1, step - 1);
      }
      return indices.reversed.toList();
    }

    final int cadence = switch (behaviour) {
      CustomerBehaviour.loyal => 1,
      CustomerBehaviour.newcomer => 1,
      CustomerBehaviour.returning => 2 + rand.nextInt(2),
      CustomerBehaviour.atRisk => 1 + rand.nextInt(2),
      CustomerBehaviour.churned => 1 + rand.nextInt(2),
      CustomerBehaviour.slowing => 1, // handled above
    };
    final indices = <int>[];
    var i = lastIndex;
    while (i >= firstIndex) {
      indices.add(i);
      // Jitter the step, otherwise every customer on the same cadence buys in
      // the same months and the series alternates between crowded and empty
      // months — a parity artefact a seasonality rule would happily "detect".
      i -= cadence == 1 ? 1 : max(1, cadence - 1 + rand.nextInt(3));
    }
    return indices.reversed.toList();
  }

  // ── orders ──────────────────────────────────────────────────────────────

  _OrderDraft _buildOrderDraft({
    required _PersonPlan plan,
    required DateTime month,
    required int monthsFromEnd,
    required double multiplier,
    required _ProfileTraits traits,
    required List<Product> products,
    required List<_CatalogueEntry> catalogue,
    required Random rand,
    required int seqHint,
  }) {
    final day = 1 + rand.nextInt(_daysInMonth(month));
    final date = DateTime(month.year, month.month, day, 9 + rand.nextInt(9));
    // The month multiplier is DEMAND: it drives how many orders land in the
    // month (see the caller). Basket size follows it only weakly — a Tết
    // basket is a bit fuller, but the season shows up mostly as frequency.
    final basketFactor = 1 + (multiplier - 1) * 0.25;
    final target =
        traits.averageOrderValue *
        basketFactor *
        (0.75 + rand.nextDouble() * 0.5);
    final lineCount = 1 + rand.nextInt(traits.maxLinesPerOrder);
    final share = target / lineCount;
    // Only pick products a basket of this size could plausibly contain:
    // dropping a 1.25M ₫ appliance into a 450k ₫ basket would swamp the order
    // value with catalogue noise and drown the signal the data is meant to
    // carry.
    final affordable = [
      for (final p in products)
        if (p.pricePerUnit <= share * 1.6) p,
    ];
    final pool = affordable.isEmpty
        ? [products.reduce((a, b) => a.pricePerUnit <= b.pricePerUnit ? a : b)]
        : affordable;
    final startIndex = rand.nextInt(pool.length);
    final items = <OrderItem>[];
    for (var l = 0; l < lineCount; l++) {
      final product = pool[(startIndex + l * 3) % pool.length];
      final index = products.indexOf(product);
      // Stochastic rounding again: a 1.4-unit line becomes 1 or 2 units with
      // the right odds, so a fuller basket really is fuller across the month
      // instead of rounding back to the same integer.
      final quantity = max(
        1,
        _stochasticRound(share / product.pricePerUnit, rand),
      );
      // 1 line in 10 is discounted — the sold price is an immutable snapshot
      // and may differ from the inventory price (WTM-126).
      final discounted = rand.nextInt(10) == 0;
      final soldPrice = discounted
          ? (product.pricePerUnit * 0.9 / 1000).roundToDouble() * 1000
          : product.pricePerUnit;
      items.add(
        OrderItem.fromProduct(
          product,
          quantity: quantity,
          soldPrice: soldPrice,
          unit: catalogue[index].unit,
        ),
      );
    }
    return _OrderDraft(
      customerId: plan.id,
      date: date,
      items: items,
      status: _pickStatus(monthsFromEnd, rand),
      seqHint: seqHint,
    );
  }

  /// Recent orders are still in flight; older ones have landed. ~6% cancel.
  OrderStatus _pickStatus(int monthsFromEnd, Random rand) {
    final r = rand.nextDouble();
    if (monthsFromEnd == 0) {
      if (r < 0.30) return OrderStatus.pending;
      if (r < 0.60) return OrderStatus.confirmed;
      if (r < 0.90) return OrderStatus.shipped;
      if (r < 0.96) return OrderStatus.cancelled;
      return OrderStatus.delivered;
    }
    if (monthsFromEnd == 1) {
      if (r < 0.10) return OrderStatus.shipped;
      if (r < 0.16) return OrderStatus.cancelled;
      return OrderStatus.delivered;
    }
    if (r < 0.06) return OrderStatus.cancelled;
    return OrderStatus.delivered;
  }

  /// Every month in the window must carry at least one order — otherwise a
  /// "months" window silently produces fewer month buckets than requested and
  /// every downstream trend rule sees a hole that is an artefact, not a fact.
  /// The filler always comes from a customer who is *supposed* to be active
  /// across the window (loyal → returning → slowing), so it never contradicts
  /// the behaviour the data is meant to show.
  void _ensureEveryMonthCovered({
    required List<_OrderDraft> drafts,
    required List<_PersonPlan> plans,
    required List<DateTime> months,
    required HistoricalDataSpec spec,
    required _ProfileTraits traits,
    required List<Product> products,
    required List<_CatalogueEntry> catalogue,
    required Random rand,
  }) {
    final covered = <int>{};
    for (final d in drafts) {
      for (var i = 0; i < months.length; i++) {
        if (d.date.year == months[i].year && d.date.month == months[i].month) {
          covered.add(i);
          break;
        }
      }
    }
    if (covered.length == months.length) return;

    _PersonPlan? filler;
    for (final behaviour in const [
      CustomerBehaviour.loyal,
      CustomerBehaviour.returning,
      CustomerBehaviour.slowing,
    ]) {
      for (final p in plans) {
        if (p.behaviour == behaviour) {
          filler = p;
          break;
        }
      }
      if (filler != null) break;
    }
    filler ??= plans.isEmpty ? null : plans.first;
    if (filler == null) return;

    for (var i = 0; i < months.length; i++) {
      if (covered.contains(i)) continue;
      drafts.add(
        _buildOrderDraft(
          plan: filler,
          month: months[i],
          monthsFromEnd: months.length - 1 - i,
          multiplier: _monthMultiplier(spec, months[i], i),
          traits: traits,
          products: products,
          catalogue: catalogue,
          rand: rand,
          seqHint: drafts.length,
        ),
      );
    }
  }

  static int _compareDrafts(_OrderDraft a, _OrderDraft b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.seqHint.compareTo(b.seqHint);
  }

  // ── inventory ───────────────────────────────────────────────────────────

  Product _withStock(
    Product product,
    int soldLastMonth,
    int index,
    Random rand,
  ) {
    final monthlyDemand = max(soldLastMonth, 4);
    final reorderLevel = max(5, (monthlyDemand * 0.6).round());
    // Every 7th product is deliberately short so stock alerts / the reorder
    // rules have something real to fire on.
    final int quantity;
    if (index % 7 == 3) {
      quantity = rand.nextInt(2) == 0
          ? 0
          : max(1, (reorderLevel * 0.6).round());
    } else {
      quantity = (monthlyDemand * (1.4 + rand.nextDouble() * 1.6)).round();
    }
    return product.copyWith(quantity: quantity, reorderLevel: reorderLevel);
  }

  // ── finance ─────────────────────────────────────────────────────────────

  /// Income mirrors billable order revenue 1:1; expenses are the profile's
  /// cost structure. Rent and payroll are FIXED for the whole window (derived
  /// once from average monthly revenue) while goods and marketing scale with
  /// the month — which is what makes operating leverage visible: weak months
  /// lose money, strong months earn.
  List<FinanceTransaction> _buildTransactions({
    required List<CustomerOrder> orders,
    required List<DateTime> months,
    required _ProfileTraits traits,
    required Random rand,
  }) {
    final revenueByMonth = <int, double>{
      for (var i = 0; i < months.length; i++) i: 0,
    };
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      for (var i = 0; i < months.length; i++) {
        if (o.date.year == months[i].year && o.date.month == months[i].month) {
          revenueByMonth[i] = revenueByMonth[i]! + o.totalAmount;
          break;
        }
      }
    }
    final totalRevenue = revenueByMonth.values.fold(0.0, (a, b) => a + b);
    final averageMonthly = months.isEmpty ? 0.0 : totalRevenue / months.length;
    final rent = _floorTo(
      max(500000.0, averageMonthly * traits.rentRatio),
      100000,
    );
    final payroll = _floorTo(
      max(500000.0, averageMonthly * traits.payrollRatio),
      100000,
    );

    final drafts = <_TransactionDraft>[];
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      drafts.add(
        _TransactionDraft(
          type: TransactionType.income,
          category: 'Bán hàng',
          amount: o.totalAmount,
          date: o.date,
          description: 'Doanh thu đơn ${o.orderNumber}',
          paymentMethod:
              _kPaymentMethods[rand.nextInt(_kPaymentMethods.length)],
          rank: 0,
        ),
      );
    }
    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final revenue = revenueByMonth[i] ?? 0;
      final lastDay = _daysInMonth(month);
      void expense(String category, double amount, int day, String note) {
        if (amount <= 0) return;
        drafts.add(
          _TransactionDraft(
            type: TransactionType.expense,
            category: category,
            amount: _floorTo(amount, 1000),
            date: DateTime(month.year, month.month, min(day, lastDay)),
            description: note,
            paymentMethod: category == 'Thuê mặt bằng'
                ? 'cash'
                : 'bankTransfer',
            rank: 1,
          ),
        );
      }

      expense(
        'Thuê mặt bằng',
        rent,
        1,
        'Tiền thuê mặt bằng tháng ${month.month}',
      );
      expense(
        'Nhập hàng',
        revenue * traits.cogsRatio,
        5,
        'Nhập hàng cho tháng ${month.month}',
      );
      expense(
        'Quảng cáo',
        revenue * traits.marketingRatio,
        12,
        'Chi phí marketing tháng ${month.month}',
      );
      expense(
        'Lương nhân viên',
        payroll,
        28,
        'Lương nhân viên tháng ${month.month}',
      );
    }

    drafts.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.rank.compareTo(b.rank);
    });
    return [
      for (var i = 0; i < drafts.length; i++)
        FinanceTransaction(
          id: '${kHistoricalIdPrefix}t${_pad(i + 1, 5)}',
          type: drafts[i].type,
          category: drafts[i].category,
          amount: drafts[i].amount,
          date: drafts[i].date,
          description: drafts[i].description,
          paymentMethod: drafts[i].paymentMethod,
        ),
    ];
  }

  // ── goals ───────────────────────────────────────────────────────────────

  /// Goals are *sized from the generated history* (last quarter + last half
  /// year), so Journey progress and pace are real rather than decorative.
  List<BusinessGoal> _buildGoals({
    required List<CustomerOrder> orders,
    required List<Customer> customers,
    required List<DateTime> months,
    required DateTime windowEnd,
  }) {
    final quarterStart = months[max(0, months.length - 3)];
    final halfStart = months[max(0, months.length - 6)];

    var quarterRevenue = 0.0;
    var quarterOrders = 0;
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      if (o.date.isBefore(quarterStart)) continue;
      quarterRevenue += o.totalAmount;
      quarterOrders++;
    }
    final newCustomers = customers
        .where(
          (c) =>
              c.lastPurchaseDate != null &&
              c.orderCount > 0 &&
              !_firstOrderDate(orders, c.id)!.isBefore(halfStart),
        )
        .length;

    return [
      BusinessGoal(
        id: '${kHistoricalIdPrefix}g001',
        name: 'Tăng doanh thu quý tới 20%',
        type: GoalType.revenue,
        targetAmount: _floorTo(quarterRevenue * 1.2, 1000000),
        achievedAmount: quarterRevenue,
        growthTarget: (quarterOrders * 1.2).round(),
        growthAchieved: quarterOrders,
        startDate: quarterStart,
        endDate: windowEnd,
        notes: 'Mục tiêu suy ra từ doanh thu 3 tháng gần nhất.',
        createdAt: quarterStart,
        updatedAt: windowEnd,
      ),
      BusinessGoal(
        id: '${kHistoricalIdPrefix}g002',
        name: 'Thêm khách hàng mới',
        type: GoalType.customerGrowth,
        targetAmount: 0,
        achievedAmount: 0,
        growthTarget: max(1, (newCustomers * 1.3).round()),
        growthAchieved: newCustomers,
        startDate: halfStart,
        endDate: windowEnd,
        notes: 'Mục tiêu suy ra từ số khách mua lần đầu 6 tháng gần nhất.',
        createdAt: halfStart,
        updatedAt: windowEnd,
      ),
    ];
  }

  DateTime? _firstOrderDate(List<CustomerOrder> orders, String customerId) {
    DateTime? first;
    for (final o in orders) {
      if (o.customerId != customerId) continue;
      if (o.status == OrderStatus.cancelled) continue;
      if (first == null || o.date.isBefore(first)) first = o.date;
    }
    return first;
  }
}

// ── plumbing ──────────────────────────────────────────────────────────────

class _PersonPlan {
  _PersonPlan({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.location,
    required this.behaviour,
    required this.activeMonths,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String location;
  final CustomerBehaviour behaviour;
  final List<int> activeMonths;
}

class _OrderDraft {
  _OrderDraft({
    required this.customerId,
    required this.date,
    required this.items,
    required this.status,
    required this.seqHint,
  });

  final String customerId;
  final DateTime date;
  final List<OrderItem> items;
  final int seqHint;
  OrderStatus status;
}

class _TransactionDraft {
  const _TransactionDraft({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    required this.paymentMethod,
    required this.rank,
  });

  final TransactionType type;
  final String category;
  final double amount;
  final DateTime date;
  final String description;
  final String paymentMethod;

  /// Ties on the same day: income first, then the month's expenses.
  final int rank;
}

@immutable
class _CatalogueEntry {
  const _CatalogueEntry(
    this.sku,
    this.name,
    this.category,
    this.unit,
    this.price,
  );

  final String sku;
  final String name;
  final String category;
  final String unit;
  final double price;
}

@immutable
class _ProfileTraits {
  const _ProfileTraits({
    required this.catalogue,
    required this.baseCustomers,
    required this.customersPerMonth,
    required this.ordersPerActiveMonth,
    required this.averageOrderValue,
    required this.maxLinesPerOrder,
    required this.cogsRatio,
    required this.marketingRatio,
    required this.rentRatio,
    required this.payrollRatio,
  });

  final List<_CatalogueEntry> catalogue;

  /// Customers present from the start, plus [customersPerMonth] per generated
  /// month — a longer history means a bigger book of customers.
  final int baseCustomers;
  final double customersPerMonth;

  /// Purchase frequency: expected orders in a month the customer is active,
  /// before the month multiplier applies.
  final double ordersPerActiveMonth;

  /// Centre of the order-value band; each order jitters ±25% around it.
  final double averageOrderValue;
  final int maxLinesPerOrder;

  /// Cost ratios against revenue. They sum to well under 1 so the demo
  /// business is profitable on average, thinly for wholesale.
  final double cogsRatio;
  final double marketingRatio;
  final double rentRatio;
  final double payrollRatio;
}

_ProfileTraits _traitsFor(BusinessProfile profile) => switch (profile) {
  BusinessProfile.retailShop => const _ProfileTraits(
    catalogue: _kRetailCatalogue,
    baseCustomers: 12,
    customersPerMonth: 2.5,
    ordersPerActiveMonth: 1.4,
    averageOrderValue: 450000,
    maxLinesPerOrder: 3,
    cogsRatio: 0.55,
    marketingRatio: 0.05,
    rentRatio: 0.07,
    payrollRatio: 0.12,
  ),
  BusinessProfile.wholesale => const _ProfileTraits(
    catalogue: _kWholesaleCatalogue,
    baseCustomers: 8,
    customersPerMonth: 1.5,
    ordersPerActiveMonth: 1.0,
    averageOrderValue: 18000000,
    maxLinesPerOrder: 2,
    cogsRatio: 0.74,
    marketingRatio: 0.02,
    rentRatio: 0.04,
    payrollRatio: 0.08,
  ),
  BusinessProfile.foodAndBeverage => const _ProfileTraits(
    catalogue: _kFoodAndBeverageCatalogue,
    baseCustomers: 20,
    customersPerMonth: 4,
    ordersPerActiveMonth: 2.4,
    averageOrderValue: 180000,
    maxLinesPerOrder: 3,
    cogsRatio: 0.36,
    marketingRatio: 0.05,
    rentRatio: 0.14,
    payrollRatio: 0.24,
  ),
};

const List<_CatalogueEntry> _kRetailCatalogue = [
  _CatalogueEntry(
    'SKU-EL-101',
    'Quạt tích điện mini',
    'Electronics',
    'cái',
    289000,
  ),
  _CatalogueEntry(
    'SKU-EL-102',
    'Sạc dự phòng 10.000mAh',
    'Electronics',
    'cái',
    250000,
  ),
  _CatalogueEntry(
    'SKU-EL-103',
    'Tai nghe bluetooth',
    'Electronics',
    'cái',
    420000,
  ),
  _CatalogueEntry(
    'SKU-EL-104',
    'Máy pha cà phê mini',
    'Electronics',
    'cái',
    349000,
  ),
  _CatalogueEntry('SKU-HO-105', 'Đèn ngủ LED cảm ứng', 'Home', 'cái', 145000),
  _CatalogueEntry('SKU-HO-106', 'Bình giữ nhiệt 500ml', 'Home', 'cái', 165000),
  _CatalogueEntry(
    'SKU-HO-107',
    'Nồi chiên không dầu 4L',
    'Home',
    'cái',
    1250000,
  ),
  _CatalogueEntry('SKU-HO-108', 'Bộ dao nhà bếp', 'Home', 'bộ', 390000),
  _CatalogueEntry('SKU-TX-109', 'Áo thun cotton', 'Textiles', 'cái', 120000),
  _CatalogueEntry('SKU-FA-110', 'Váy linen', 'Fashion', 'cái', 350000),
  _CatalogueEntry('SKU-FA-111', 'Khăn lụa', 'Fashion', 'cái', 180000),
  _CatalogueEntry(
    'SKU-AC-112',
    'Túi chống nước du lịch',
    'Accessories',
    'cái',
    145000,
  ),
  _CatalogueEntry('SKU-AC-113', 'Ví da nam', 'Accessories', 'cái', 260000),
  _CatalogueEntry(
    'SKU-AC-114',
    'Giá đỡ điện thoại',
    'Accessories',
    'cái',
    65000,
  ),
];

const List<_CatalogueEntry> _kWholesaleCatalogue = [
  _CatalogueEntry(
    'SKU-WS-201',
    'Thùng quạt tích điện (20 cái)',
    'Electronics',
    'thùng',
    4800000,
  ),
  _CatalogueEntry(
    'SKU-WS-202',
    'Thùng sạc dự phòng (30 cái)',
    'Electronics',
    'thùng',
    5400000,
  ),
  _CatalogueEntry(
    'SKU-WS-203',
    'Thùng áo thun cotton (50 cái)',
    'Textiles',
    'thùng',
    3900000,
  ),
  _CatalogueEntry(
    'SKU-WS-204',
    'Kiện khăn bông (100 cái)',
    'Textiles',
    'kiện',
    5200000,
  ),
  _CatalogueEntry(
    'SKU-WS-205',
    'Thùng nồi chiên không dầu (6 cái)',
    'Home',
    'thùng',
    6300000,
  ),
  _CatalogueEntry(
    'SKU-WS-206',
    'Thùng bình giữ nhiệt (40 cái)',
    'Home',
    'thùng',
    4600000,
  ),
  _CatalogueEntry(
    'SKU-WS-207',
    'Thùng ly giữ nhiệt (24 cái)',
    'Home',
    'thùng',
    3600000,
  ),
  _CatalogueEntry(
    'SKU-WS-208',
    'Thùng bột giặt 5kg (12 túi)',
    'Home',
    'thùng',
    1850000,
  ),
  _CatalogueEntry(
    'SKU-WS-209',
    'Kiện dép nhựa (200 đôi)',
    'Fashion',
    'kiện',
    3400000,
  ),
  _CatalogueEntry(
    'SKU-WS-210',
    'Kiện túi vải không dệt (500 cái)',
    'Accessories',
    'kiện',
    2750000,
  ),
];

const List<_CatalogueEntry> _kFoodAndBeverageCatalogue = [
  _CatalogueEntry('SKU-FB-301', 'Cà phê sữa đá', 'Đồ uống', 'ly', 29000),
  _CatalogueEntry('SKU-FB-302', 'Trà đào cam sả', 'Đồ uống', 'ly', 45000),
  _CatalogueEntry('SKU-FB-303', 'Trà sữa trân châu', 'Đồ uống', 'ly', 39000),
  _CatalogueEntry('SKU-FB-304', 'Sinh tố bơ', 'Đồ uống', 'ly', 42000),
  _CatalogueEntry('SKU-FB-305', 'Nước ép cam tươi', 'Đồ uống', 'chai', 38000),
  _CatalogueEntry('SKU-FB-306', 'Bánh mì thịt nướng', 'Đồ ăn', 'ổ', 35000),
  _CatalogueEntry('SKU-FB-307', 'Cơm gà xối mỡ', 'Đồ ăn', 'phần', 55000),
  _CatalogueEntry('SKU-FB-308', 'Bún bò Huế', 'Đồ ăn', 'tô', 60000),
  _CatalogueEntry('SKU-FB-309', 'Combo cơm văn phòng', 'Combo', 'phần', 89000),
  _CatalogueEntry('SKU-FB-310', 'Set tiệc nhỏ 4 người', 'Combo', 'set', 450000),
  _CatalogueEntry('SKU-FB-311', 'Chè khúc bạch', 'Tráng miệng', 'ly', 30000),
  _CatalogueEntry('SKU-FB-312', 'Bánh flan', 'Tráng miệng', 'cái', 20000),
];

const List<String> _kLocations = [
  'Hà Nội',
  'TP.HCM',
  'Đà Nẵng',
  'Hải Phòng',
  'Cần Thơ',
  'Bình Dương',
  'Nghệ An',
  'Khánh Hòa',
];

const List<String> _kGivenNames = [
  'Phương', 'Minh', 'Huy', 'Lan', 'Thu', 'Bảo', 'Anh', 'Khánh', //
  'Ngọc', 'Quân', 'Trang', 'Hải', 'Duy', 'Yến', 'Tuấn', 'Hạnh', //
  'Nam', 'Chi', 'Sơn', 'Mai', 'Long', 'Vy', 'Đức', 'Thảo',
];

const List<String> _kFamilyNames = [
  'Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', //
  'Võ', 'Đặng', 'Bùi', 'Đỗ', 'Hồ', 'Ngô', 'Dương', 'Lý',
];

const List<String> _kPaymentMethods = ['cash', 'bankTransfer', 'momo'];

/// Deterministic, collision-free for the first 384 customers (24 × 16).
String _nameFor(int index) =>
    '${_kGivenNames[index % _kGivenNames.length]} '
    '${_kFamilyNames[(index ~/ _kGivenNames.length) % _kFamilyNames.length]}';

String _pad(int value, int width) => value.toString().padLeft(width, '0');

/// Rounds [value] to a whole number **keeping its expectation**: 1.4 becomes 1
/// with probability 0.6 and 2 with probability 0.4. Plain `round()` would
/// quantize a demand multiplier away (1.0 and 1.4 units both become 1), which
/// is exactly how a season or a trend disappears from generated data.
int _stochasticRound(double value, Random rand) {
  if (value <= 0) return 0;
  final whole = value.floor();
  return rand.nextDouble() < value - whole ? whole + 1 : whole;
}

int _daysInMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0).day;

DateTime _endOfMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0, 23, 59, 59);

/// Rounds down to a whole [step] (đồng) — money in the demo data never carries
/// meaningless fractions.
double _floorTo(double value, int step) =>
    (value / step).floorToDouble() * step;

/// Persists a generated [HistoricalDataSet] through the **existing** sample
/// lifecycle: same repositories, same `sample-` prefix, same idempotent
/// remove-then-insert, same orders-first deletion (ADR-TON-014 §4).
///
/// This is a wrapper, not a second seeding path — [removeAll] and [hasSamples]
/// delegate straight to [SampleDataSeeder], so "Xóa dữ liệu mẫu" removes
/// generated history exactly the way it removes the hand-written fixtures.
class HistoricalDataSeeder {
  const HistoricalDataSeeder({required this.sampleSeeder, this.clock});

  final SampleDataSeeder sampleSeeder;

  /// Injected clock, forwarded to the generator (see
  /// [HistoricalDataGenerator.clock]).
  final DateTime Function()? clock;

  HistoricalDataGenerator get generator =>
      HistoricalDataGenerator(clock: clock);

  /// Pure generation — no I/O. Exposed so rules, previews and tests can work on
  /// the records without a database.
  HistoricalDataSet generate(HistoricalDataSpec spec) =>
      generator.generate(spec);

  /// Generates and persists a full history. Idempotent: existing sample rows
  /// (fixtures AND previously generated history) are removed first, so
  /// re-seeding never duplicates — including in the insert-only finance
  /// repository.
  ///
  /// Insert order is customers/products → orders → goals → finance: the SQLite
  /// `orders_table.customer_id` foreign key requires the customer to exist
  /// first.
  Future<void> seed(HistoricalDataSpec spec) async {
    final data = generate(spec);
    await sampleSeeder.removeAll();

    for (final c in data.customers) {
      await sampleSeeder.customers.upsert(c);
    }
    for (final p in data.products) {
      await sampleSeeder.products.upsert(p);
    }
    for (final o in data.orders) {
      await sampleSeeder.orders.upsert(o);
    }
    for (final g in data.goals) {
      await sampleSeeder.goals.upsert(g);
    }
    for (final t in data.transactions) {
      await sampleSeeder.finance.add(t);
    }
  }

  /// Removes every sample row — hand-written fixtures and generated history
  /// alike. User rows (UUID ids) are untouched.
  Future<void> removeAll() => sampleSeeder.removeAll();

  /// Whether any sample row is currently present.
  Future<bool> hasSamples() => sampleSeeder.hasSamples();
}
