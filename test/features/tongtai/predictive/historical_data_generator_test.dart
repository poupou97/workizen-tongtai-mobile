import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// WTM-149 (Predictive Foundation) — the **Historical Data Generator**.
///
/// The generator is the ground truth every Rule Twin will be measured against,
/// so these tests assert the properties a forecast depends on: determinism, the
/// requested window length, a visible season, a visible trend, a customer book
/// whose behaviour is readable FROM THE ORDERS, and aggregates that agree with
/// those orders. Ratios — never magic numbers — so the tests keep meaning when
/// the generator is tuned.
void main() {
  /// A fixed end month keeps every assertion independent of the wall clock.
  DateTime clock() => DateTime(2026, 12, 15, 10, 30);
  final generator = HistoricalDataGenerator(clock: clock);

  /// A total-order fingerprint of a data set: ids, dates and amounts of every
  /// generated record. Two runs that agree here are identical.
  String fingerprint(HistoricalDataSet d) {
    final buffer = StringBuffer()
      ..writeln('window ${d.windowStart.toIso8601String()}')
      ..writeln('..${d.windowEnd.toIso8601String()}');
    for (final c in d.customers) {
      buffer.writeln(
        'C|${c.id}|${c.name}|${c.phone}|${c.location}|${c.orderCount}|'
        '${c.totalSpent}|${c.lastPurchaseDate?.toIso8601String()}|'
        '${c.segments.join(',')}',
      );
    }
    for (final p in d.products) {
      buffer.writeln(
        'P|${p.id}|${p.sku}|${p.name}|${p.quantity}|${p.pricePerUnit}|'
        '${p.reorderLevel}|${p.updatedAt.toIso8601String()}',
      );
    }
    for (final o in d.orders) {
      buffer.writeln(
        'O|${o.id}|${o.customerId}|${o.orderNumber}|'
        '${o.date.toIso8601String()}|${o.status.name}|${o.totalAmount}|'
        '${o.items.map((i) => '${i.productId}x${i.quantity}@${i.unitPrice}').join(';')}',
      );
    }
    for (final t in d.transactions) {
      buffer.writeln(
        'T|${t.id}|${t.type.name}|${t.category}|${t.amount}|'
        '${t.date.toIso8601String()}|${t.description}|${t.paymentMethod}',
      );
    }
    for (final g in d.goals) {
      buffer.writeln(
        'G|${g.id}|${g.name}|${g.type.name}|${g.targetAmount}|'
        '${g.achievedAmount}|${g.growthTarget}|${g.growthAchieved}|'
        '${g.startDate.toIso8601String()}|${g.endDate.toIso8601String()}',
      );
    }
    return buffer.toString();
  }

  double revenueBetween(HistoricalDataSet d, int fromIndex, int toIndex) {
    final keys = d.monthKeys.sublist(fromIndex, toIndex);
    final revenue = d.revenueByMonth;
    return keys.fold(0.0, (sum, k) => sum + (revenue[k] ?? 0));
  }

  // ── 1. Determinism ──────────────────────────────────────────────────────

  group('determinism', () {
    test('same spec + seed twice ⇒ identical ids, dates and amounts', () {
      const spec = HistoricalDataSpec(months: 12, seed: 20260730);
      expect(
        fingerprint(generator.generate(spec)),
        fingerprint(generator.generate(spec)),
        reason: 'the generator must never depend on anything but the spec',
      );
    });

    test(
      'the default end month follows the injected clock, not the wall clock',
      () {
        const spec = HistoricalDataSpec(months: 3);
        final data = generator.generate(spec);
        expect(data.windowEnd.year, 2026);
        expect(data.windowEnd.month, 12);
        expect(data.windowStart, DateTime(2026, 10));
        // A different clock ⇒ a different window, from the SAME spec.
        final other = HistoricalDataGenerator(
          clock: () => DateTime(2025, 5, 2),
        ).generate(spec);
        expect(other.windowStart, DateTime(2025, 3));
      },
    );

    test('a different seed produces different data', () {
      const a = HistoricalDataSpec(months: 12, seed: 1);
      const b = HistoricalDataSpec(months: 12, seed: 2);
      expect(
        fingerprint(generator.generate(a)),
        isNot(fingerprint(generator.generate(b))),
      );
    });
  });

  // ── 2. Window length ────────────────────────────────────────────────────

  group('months parameter', () {
    for (final months in [3, 12, 24]) {
      test('$months months ⇒ $months distinct year-months of orders', () {
        final data = generator.generate(HistoricalDataSpec(months: months));
        final yearMonths = {
          for (final o in data.orders) DateTime(o.date.year, o.date.month),
        };
        expect(
          yearMonths,
          hasLength(months),
          reason: 'every month in the window must carry at least one order',
        );
        expect(data.monthKeys, hasLength(months));
        expect(yearMonths, containsAll(data.monthKeys));
        expect(data.windowStart, data.monthKeys.first);
        // No order may fall outside the window.
        for (final o in data.orders) {
          expect(o.date.isBefore(data.windowStart), isFalse);
          expect(o.date.isAfter(data.windowEnd), isFalse);
        }
      });
    }

    test('longer windows really do produce more history', () {
      final short = generator.generate(const HistoricalDataSpec(months: 3));
      final long = generator.generate(const HistoricalDataSpec(months: 24));
      expect(long.orders.length, greaterThan(short.orders.length * 3));
      expect(long.customers.length, greaterThan(short.customers.length));
    });
  });

  // ── 3. Seasonality ──────────────────────────────────────────────────────

  group('seasonality', () {
    // Growth OFF so the only signal in the data is the season.
    const seasonal = HistoricalDataSpec(
      months: 12,
      growth: GrowthPattern.flat,
      seasonality: SeasonalityPattern.vietnamRetail,
      endMonth: null,
    );

    double tetOverTrough(HistoricalDataSet d) {
      final revenue = d.revenueByMonth;
      double monthTotal(int month) => revenue.entries
          .where((e) => e.key.month == month)
          .fold(0.0, (sum, e) => sum + e.value);
      final tet = monthTotal(1) + monthTotal(2); // Jan + Feb — Tết
      final trough = monthTotal(3) + monthTotal(4); // Mar + Apr — post-Tết
      expect(trough, greaterThan(0));
      return tet / trough;
    }

    test('Tết months earn materially more than the post-Tết trough', () {
      final ratio = tetOverTrough(generator.generate(seasonal));
      expect(
        ratio,
        greaterThan(1.4),
        reason:
            'Tết (Jan/Feb) must stand clearly above the Mar/Apr trough — '
            'got a ratio of ${ratio.toStringAsFixed(2)}',
      );
    });

    test('the peak comes from the pattern, not from the calendar', () {
      final withSeason = tetOverTrough(generator.generate(seasonal));
      final withoutSeason = tetOverTrough(
        generator.generate(
          seasonal.copyWith(seasonality: SeasonalityPattern.none),
        ),
      );
      expect(
        withSeason,
        greaterThan(withoutSeason * 1.4),
        reason:
            'SeasonalityPattern.none must flatten the Tết peak '
            '(seasonal ${withSeason.toStringAsFixed(2)} vs '
            'flat ${withoutSeason.toStringAsFixed(2)})',
      );
    });

    test('summer bump and year-end push are modelled', () {
      // The multipliers are the contract the revenue shape is built from.
      expect(kVietnamRetailMonthlyMultipliers, hasLength(12));
      final may = kVietnamRetailMonthlyMultipliers[4];
      expect(kVietnamRetailMonthlyMultipliers[5], greaterThan(may)); // Jun
      expect(kVietnamRetailMonthlyMultipliers[6], greaterThan(may)); // Jul
      final oct = kVietnamRetailMonthlyMultipliers[9];
      expect(kVietnamRetailMonthlyMultipliers[10], greaterThan(oct)); // Nov
      expect(kVietnamRetailMonthlyMultipliers[11], greaterThan(oct)); // Dec
      // Tết peak above every other month.
      final tetPeak = kVietnamRetailMonthlyMultipliers[1];
      for (var i = 2; i < 12; i++) {
        expect(kVietnamRetailMonthlyMultipliers[i], lessThan(tetPeak));
      }
    });
  });

  // ── 4. Growth ───────────────────────────────────────────────────────────

  group('growth', () {
    // Seasonality OFF so the only signal in the data is the trend.
    const base = HistoricalDataSpec(
      months: 12,
      seasonality: SeasonalityPattern.none,
    );

    ({double first, double last}) quarters(HistoricalDataSet d) =>
        (first: revenueBetween(d, 0, 3), last: revenueBetween(d, 9, 12));

    test('fastGrowth: last quarter clearly beats the first', () {
      final q = quarters(
        generator.generate(base.copyWith(growth: GrowthPattern.fastGrowth)),
      );
      expect(
        q.last,
        greaterThan(q.first * 1.5),
        reason: 'first=${q.first}, last=${q.last}',
      );
    });

    test('decline: last quarter falls below the first', () {
      final q = quarters(
        generator.generate(base.copyWith(growth: GrowthPattern.decline)),
      );
      expect(
        q.last,
        lessThan(q.first * 0.9),
        reason: 'first=${q.first}, last=${q.last}',
      );
    });

    test('fastGrowth outgrows moderateGrowth outgrows flat', () {
      double lift(GrowthPattern g) {
        final q = quarters(generator.generate(base.copyWith(growth: g)));
        return q.last / q.first;
      }

      final fast = lift(GrowthPattern.fastGrowth);
      final moderate = lift(GrowthPattern.moderateGrowth);
      final flat = lift(GrowthPattern.flat);
      expect(fast, greaterThan(moderate));
      expect(moderate, greaterThan(flat * 0.9));
      expect(fast, greaterThan(1.5));
    });
  });

  // ── 5. Customer mix ─────────────────────────────────────────────────────

  group('customer mix', () {
    const spec = HistoricalDataSpec(months: 24);
    late HistoricalDataSet data;

    setUp(() => data = generator.generate(spec));

    test('behaviour counts match the requested distribution (± rounding)', () {
      const mix = CustomerMix();
      final total = data.customers.length;
      expect(total, greaterThan(20));
      var sum = 0;
      for (final behaviour in CustomerBehaviour.values) {
        final actual = data.customersWith(behaviour).length;
        final expected = total * mix.fractionOf(behaviour);
        expect(
          (actual - expected).abs(),
          lessThan(1.0),
          reason:
              '${behaviour.name}: expected ≈ ${expected.toStringAsFixed(1)} '
              'of $total, got $actual',
        );
        sum += actual;
      }
      expect(sum, total, reason: 'every customer has exactly one behaviour');
    });

    test('a custom mix is honoured', () {
      final data = generator.generate(
        spec.copyWith(
          customerMix: const CustomerMix(
            newcomers: 0,
            loyal: 0.5,
            returning: 0.5,
            slowing: 0,
            atRisk: 0,
            churned: 0,
          ),
        ),
      );
      expect(data.customersWith(CustomerBehaviour.churned), isEmpty);
      expect(data.customersWith(CustomerBehaviour.newcomer), isEmpty);
      expect(
        data.customersWith(CustomerBehaviour.loyal).length +
            data.customersWith(CustomerBehaviour.returning).length,
        data.customers.length,
      );
    });

    test('churned are silent beyond the churn window, loyal are current', () {
      final churned = data.customersWith(CustomerBehaviour.churned);
      final loyal = data.customersWith(CustomerBehaviour.loyal);
      expect(churned, isNotEmpty);
      expect(loyal, isNotEmpty);

      for (final c in churned) {
        expect(c.lastPurchaseDate, isNotNull, reason: '${c.id} never bought');
        final silentDays = data.windowEnd
            .difference(c.lastPurchaseDate!)
            .inDays;
        expect(
          silentDays,
          greaterThan(kHistoricalChurnWindowDays),
          reason:
              '${c.id} is churned but last bought only $silentDays days '
              'before the end of the window',
        );
      }
      for (final c in loyal) {
        final silentDays = data.windowEnd
            .difference(c.lastPurchaseDate!)
            .inDays;
        expect(
          silentDays,
          lessThanOrEqualTo(35),
          reason: '${c.id} is loyal but has been silent for $silentDays days',
        );
      }
    });

    test('at-risk sit between loyal and churned; newcomers are recent', () {
      double averageSilence(CustomerBehaviour behaviour) {
        final rows = data.customersWith(behaviour);
        return rows.fold<int>(
              0,
              (sum, c) =>
                  sum + data.windowEnd.difference(c.lastPurchaseDate!).inDays,
            ) /
            rows.length;
      }

      expect(
        averageSilence(CustomerBehaviour.atRisk),
        greaterThan(averageSilence(CustomerBehaviour.slowing)),
      );
      expect(
        averageSilence(CustomerBehaviour.churned),
        greaterThan(averageSilence(CustomerBehaviour.atRisk)),
      );

      // Newcomers only exist in the last months of the window.
      final cutoff = data.monthKeys[data.monthKeys.length - 4];
      for (final c in data.customersWith(CustomerBehaviour.newcomer)) {
        for (final o in data.ordersFor(c.id)) {
          expect(
            o.date.isBefore(cutoff),
            isFalse,
            reason: '${c.id} is a newcomer but ordered on ${o.date}',
          );
        }
      }
    });

    test('slowing customers have widening gaps', () {
      final slowing = data.customersWith(CustomerBehaviour.slowing);
      expect(slowing, isNotEmpty);
      var widening = 0;
      for (final c in slowing) {
        final dates = data.ordersFor(c.id).map((o) => o.date).toList()..sort();
        if (dates.length < 4) continue;
        final firstGap = dates[1].difference(dates[0]).inDays;
        final lastGap = dates.last.difference(dates[dates.length - 2]).inDays;
        if (lastGap > firstGap) widening++;
      }
      expect(
        widening,
        greaterThan(0),
        reason: 'slowing customers must show growing gaps between orders',
      );
    });
  });

  // ── 6. Internal consistency ─────────────────────────────────────────────

  group('consistency', () {
    for (final profile in BusinessProfile.values) {
      test('${profile.name}: aggregates, links and money all agree', () {
        final data = generator.generate(
          HistoricalDataSpec(months: 12, profile: profile),
        );
        final productIds = {for (final p in data.products) p.id};
        final customerIds = {for (final c in data.customers) c.id};
        expect(data.products, isNotEmpty);
        expect(data.orders, isNotEmpty);

        // Orders → real customers, order items → real products.
        for (final o in data.orders) {
          expect(o.id, startsWith(kHistoricalIdPrefix));
          expect(o.id, startsWith(kSampleIdPrefix));
          expect(customerIds, contains(o.customerId));
          expect(o.items, isNotEmpty);
          for (final item in o.items) {
            expect(
              productIds,
              contains(item.productId),
              reason: 'order ${o.id} references an unknown product',
            );
            expect(item.quantity, greaterThan(0));
            expect(item.unitPrice, greaterThan(0));
            expect(item.productName, isNotEmpty);
            expect(item.unit, isNotEmpty);
          }
        }

        // Customer aggregates == what the billable orders imply.
        for (final c in data.customers) {
          final billable = data
              .ordersFor(c.id)
              .where((o) => o.status != OrderStatus.cancelled)
              .toList();
          final spent = billable.fold(0.0, (sum, o) => sum + o.totalAmount);
          expect(
            c.orderCount,
            billable.length,
            reason: '${c.id} orderCount disagrees with its orders',
          );
          expect(
            c.totalSpent,
            closeTo(spent, 0.01),
            reason: '${c.id} totalSpent disagrees with its orders',
          );
          if (billable.isEmpty) {
            expect(c.lastPurchaseDate, isNull);
          } else {
            final latest = billable
                .map((o) => o.date)
                .reduce((a, b) => a.isAfter(b) ? a : b);
            expect(c.lastPurchaseDate, latest);
          }
        }

        // Cancelled orders exist, and are excluded from revenue everywhere.
        final cancelled = data.orders.where(
          (o) => o.status == OrderStatus.cancelled,
        );
        expect(
          cancelled,
          isNotEmpty,
          reason: 'a realistic history contains cancelled orders',
        );
        final billableTotal = data.billableOrders.fold(
          0.0,
          (sum, o) => sum + o.totalAmount,
        );
        expect(data.totalRevenue, closeTo(billableTotal, 0.01));
        expect(
          data.customers.fold(0.0, (sum, c) => sum + c.totalSpent),
          closeTo(billableTotal, 0.01),
        );

        // Income mirrors billable order revenue 1:1.
        final income = data.transactions.where((t) => t.isIncome).toList();
        expect(income, hasLength(data.billableOrders.length));
        expect(
          income.fold(0.0, (sum, t) => sum + t.amount),
          closeTo(billableTotal, 0.01),
        );

        // Realistic expenses, every month, in the expected categories.
        final expenseCategories = {
          for (final t in data.transactions.where((t) => t.isExpense))
            t.category,
        };
        expect(
          expenseCategories,
          containsAll(<FinanceCategory>[
            FinanceCategory.productCost,
            FinanceCategory.rent,
            FinanceCategory.marketing,
            FinanceCategory.staff,
          ]),
        );
        for (final month in data.monthKeys) {
          final rent = data.transactions.where(
            (t) =>
                t.category == FinanceCategory.rent &&
                t.date.year == month.year &&
                t.date.month == month.month,
          );
          expect(rent, hasLength(1), reason: 'rent is due every month');
        }
        // Rent is a FIXED cost — the same amount all window long.
        final rents = data.transactions
            .where((t) => t.category == FinanceCategory.rent)
            .map((t) => t.amount)
            .toSet();
        expect(rents, hasLength(1));

        // The demo business is profitable over the whole window.
        final expenses = data.transactions
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);
        expect(
          expenses,
          lessThan(billableTotal),
          reason: '${profile.name} must not burn cash across the window',
        );

        // Every id is removable by the ONE sample lifecycle.
        for (final row in [
          ...data.customers.map((c) => c.id),
          ...data.products.map((p) => p.id),
          ...data.orders.map((o) => o.id),
          ...data.transactions.map((t) => t.id),
          ...data.goals.map((g) => g.id),
        ]) {
          expect(row, startsWith(kSampleIdPrefix));
        }

        // Goals are sized from the generated history, not invented.
        expect(data.goals, isNotEmpty);
        for (final g in data.goals) {
          expect(g.endDate, data.windowEnd);
          expect(g.startDate.isBefore(g.endDate), isTrue);
          expect(g.growthAchieved, lessThanOrEqualTo(g.growthTarget));
          expect(g.achievedAmount, lessThanOrEqualTo(g.targetAmount));
        }
      });
    }

    test('order ids and numbers run in chronological order', () {
      final data = generator.generate(const HistoricalDataSpec(months: 12));
      for (var i = 1; i < data.orders.length; i++) {
        expect(
          data.orders[i].date.isBefore(data.orders[i - 1].date),
          isFalse,
          reason: 'orders must be emitted oldest first',
        );
      }
      expect(
        data.orders.map((o) => o.id).toSet(),
        hasLength(data.orders.length),
      );
      expect(
        data.orders.map((o) => o.orderNumber).toSet(),
        hasLength(data.orders.length),
      );
    });

    test('profiles differ in catalogue size, basket and frequency', () {
      final retail = generator.generate(
        const HistoricalDataSpec(
          months: 12,
          profile: BusinessProfile.retailShop,
        ),
      );
      final wholesale = generator.generate(
        const HistoricalDataSpec(
          months: 12,
          profile: BusinessProfile.wholesale,
        ),
      );
      final fnb = generator.generate(
        const HistoricalDataSpec(
          months: 12,
          profile: BusinessProfile.foodAndBeverage,
        ),
      );

      double aov(HistoricalDataSet d) =>
          d.totalRevenue / d.billableOrders.length;

      expect(aov(wholesale), greaterThan(aov(retail)));
      expect(aov(retail), greaterThan(aov(fnb)));
      expect(fnb.orders.length, greaterThan(wholesale.orders.length));
      expect(
        {
          retail.products.length,
          wholesale.products.length,
          fnb.products.length,
        },
        hasLength(3),
        reason: 'each profile ships its own catalogue size',
      );
    });
  });

  // ── 7. Persistence through the ONE sample lifecycle ─────────────────────

  group('persistence', () {
    late InMemoryCustomerRepository customers;
    late InMemoryProductRepository products;
    late InMemoryOrderRepository orders;
    late InMemoryBusinessGoalRepository goals;
    late InMemoryFinanceRepository finance;
    late HistoricalDataSeeder seeder;

    const spec = HistoricalDataSpec(months: 6);

    setUp(() {
      customers = InMemoryCustomerRepository();
      products = InMemoryProductRepository([]);
      orders = InMemoryOrderRepository();
      goals = InMemoryBusinessGoalRepository();
      finance = InMemoryFinanceRepository();
      seeder = HistoricalDataSeeder(
        sampleSeeder: SampleDataSeeder(
          customers: customers,
          products: products,
          orders: orders,
          goals: goals,
          finance: finance,
        ),
        clock: clock,
      );
    });

    test('seed writes the generated history into every repository', () async {
      await seeder.seed(spec);
      final expected = seeder.generate(spec);

      expect(await customers.loadAll(), hasLength(expected.customers.length));
      expect(await products.loadAll(), hasLength(expected.products.length));
      expect(await orders.loadAll(), hasLength(expected.orders.length));
      expect(await goals.loadAll(), hasLength(expected.goals.length));
      expect(await finance.loadAll(), hasLength(expected.transactions.length));
      expect(await seeder.hasSamples(), isTrue);

      // Links survive persistence.
      final storedIds = {for (final c in await customers.loadAll()) c.id};
      for (final o in await orders.loadAll()) {
        expect(storedIds, contains(o.customerId));
      }
    });

    test('re-seeding never duplicates (incl. insert-only finance)', () async {
      await seeder.seed(spec);
      final firstRun = (await orders.loadAll()).length;
      final firstFinance = (await finance.loadAll()).length;
      await seeder.seed(spec);
      await seeder.seed(spec);

      expect(await orders.loadAll(), hasLength(firstRun));
      expect(await finance.loadAll(), hasLength(firstFinance));
    });

    test('removeAll deletes ONLY sample rows — user data survives', () async {
      await seeder.seed(spec);
      await customers.upsert(
        const Customer(
          id: 'a1b2c3d4-user',
          name: 'Khách Thật',
          phone: '+84900000001',
          location: 'Hà Nội',
          orderCount: 0,
          totalSpent: 0,
          lastPurchaseDate: null,
        ),
      );
      await orders.upsert(
        CustomerOrder(
          id: 'e5f6-user-order',
          customerId: 'a1b2c3d4-user',
          orderNumber: 'DH-USER',
          date: DateTime(2026, 12, 1),
          status: OrderStatus.delivered,
          items: const [
            OrderItem(
              productName: 'Hàng thật',
              category: 'Home',
              quantity: 1,
              unitPrice: 100000,
            ),
          ],
        ),
      );

      await seeder.removeAll();

      expect((await customers.loadAll()).single.name, 'Khách Thật');
      expect((await orders.loadAll()).single.orderNumber, 'DH-USER');
      expect(await products.loadAll(), isEmpty);
      expect(await goals.loadAll(), isEmpty);
      expect(await finance.loadAll(), isEmpty);
      expect(await seeder.hasSamples(), isFalse);
    });

    test('the hand-written fixtures and generated history share ONE '
        'lifecycle', () async {
      final fixtures = SampleDataSeeder(
        customers: customers,
        products: products,
        orders: orders,
        goals: goals,
        finance: finance,
      );
      await fixtures.seed(); // ADR-TON-014 fixtures
      await seeder.seed(spec); // then generated history over the same repos

      // The generated seed removed the fixtures — one prefix, one lifecycle.
      for (final c in await customers.loadAll()) {
        expect(c.id, startsWith(kHistoricalIdPrefix));
      }
      await fixtures.removeAll(); // the OLD seeder removes generated rows too
      expect(await customers.loadAll(), isEmpty);
      expect(await orders.loadAll(), isEmpty);
      expect(await finance.loadAll(), isEmpty);
    });
  });
}
