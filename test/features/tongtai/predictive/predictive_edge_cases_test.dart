import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/analytics/month_bucket.dart';
import 'package:tongtai/features/tongtai/analytics/revenue_series.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';
import 'package:tongtai/features/tongtai/predictive/revenue_forecast_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// **WTM-162 — Data Sufficiency & Edge Cases** for the Predictive Foundation
/// (ADR-TON-016).
///
/// The rule twins are already unit-tested against hand-built contexts. This
/// suite proves the *whole path* instead — a REAL SQLite file, the PRODUCTION
/// Drift repositories, the production capability providers, the production
/// twins — over exactly the inputs a real seller produces and a unit test never
/// sees:
///
/// 1. month boundaries (23:59:59 vs 00:00:00) and the running month;
/// 2. a UTC-stored instant bucketed by the **local** calendar month
///    (`analytics/month_bucket.dart`'s documented decision);
/// 3. an app **restart** — a new `AppDatabase` on the same file must reproduce
///    the same forecast and the same risk ranking, byte for byte;
/// 4. **Reset sample data** — the twins must say "insufficient", not zero, and
///    user rows must survive;
/// 5. sample history and user rows **coexisting** — both are consumed;
/// 6. the sufficiency boundaries (2↔3 and 5↔6 months with revenue);
/// 7. degenerate businesses (all-zero months, one customer, zero spend).
///
/// Every asserted number is hand-computed from the fixture and written out next
/// to it, so a reviewer can defend it without running the code.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Fixed clocks ──────────────────────────────────────────────────────────
  // July 2026 is the running month, so the 12 completed months are
  // Jul 2025 … Jun 2026 and every forecast targets Jul 2026.
  final midMonth = DateTime(2026, 7, 15, 9, 30);
  final firstOfMonth = DateTime(2026, 7, 1);
  const lastCompleted = MonthKey(2026, 6);

  late Directory tempDir;
  late File dbFile;
  AppDatabase? open;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-predictive-');
    dbFile = File('${tempDir.path}/tongtai.db');
  });

  tearDown(() async {
    await open?.close();
    open = null;
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// One "app session": a fresh [AppDatabase] over the SAME file, wired to the
  /// production Drift repositories and the production capability providers.
  ({
    AppDatabase db,
    DriftCustomerRepository customers,
    DriftProductRepository products,
    DriftOrderRepository orders,
    DriftBusinessGoalRepository goals,
    DriftFinanceRepository finance,
    SampleDataSeeder sampleSeeder,
    HistoricalDataSeeder historySeeder,
    RevenueCapabilityProvider revenue,
    CustomerCapabilityProvider consumers,
  })
  session({DateTime? now}) {
    final clock = now ?? midMonth;
    final db = AppDatabase.forExecutor(NativeDatabase(dbFile));
    open = db;
    final customers = DriftCustomerRepository(db);
    final products = DriftProductRepository(db);
    final orders = DriftOrderRepository(db);
    final goals = DriftBusinessGoalRepository(db);
    final finance = DriftFinanceRepository(db);
    final sampleSeeder = SampleDataSeeder(
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      finance: finance,
    );
    return (
      db: db,
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      finance: finance,
      sampleSeeder: sampleSeeder,
      historySeeder: HistoricalDataSeeder(
        sampleSeeder: sampleSeeder,
        clock: () => clock,
      ),
      revenue: RevenueCapabilityProvider(orders, clock: () => clock),
      consumers: CustomerCapabilityProvider(
        customers,
        orders,
        clock: () => clock,
      ),
    );
  }

  // ── Fixture builders ──────────────────────────────────────────────────────

  Customer person(String id, {String name = 'Khách thật'}) => Customer(
    id: id,
    name: name,
    phone: '+84900000001',
    location: 'Đà Nẵng',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  /// One order worth exactly [amount] đồng (quantity 1 × unit price [amount]),
  /// so a fixture's month total is a sum a reader can do in their head.
  CustomerOrder sale({
    required String id,
    required String customerId,
    required DateTime date,
    required double amount,
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: 'DH-$id',
    date: date,
    status: status,
    items: [
      OrderItem(
        productName: 'Hàng hoá',
        category: 'Chung',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  /// The one point of [series] for [key] — asserts the month exists exactly
  /// once, so a missing bucket fails loudly instead of silently reading zero.
  MonthlyRevenuePoint pointFor(RevenueSeries series, MonthKey key) {
    final matches = series.points.where((point) => point.key == key);
    expect(matches, hasLength(1), reason: 'expected exactly one $key bucket');
    return matches.single;
  }

  /// Seeds [customerId] with one order per month for the last [months]
  /// completed months (ending Jun 2026), each worth [amount].
  Future<void> seedUniformMonths({
    required CustomerRepository customers,
    required OrderRepository orders,
    required String customerId,
    required int months,
    double amount = 1000000,
  }) async {
    await customers.upsert(person(customerId));
    for (var back = 0; back < months; back++) {
      final key = lastCompleted.addMonths(-back);
      await orders.upsert(
        sale(
          id: '$customerId-o$back',
          customerId: customerId,
          date: DateTime(key.year, key.month, 15, 10),
          amount: amount,
        ),
      );
    }
  }

  /// The 12-month generated history, pinned to Jun 2026 so nothing reads a
  /// wall clock.
  HistoricalDataSpec pinnedHistory() =>
      HistoricalDataSpec(months: 12, endMonth: DateTime(2026, 6));

  // ══ 1 · Month boundary ═════════════════════════════════════════════════════

  group('month boundary', () {
    // Apr 1.0M · May 2.0M · Jun 3.0M, where the May order sits on the very last
    // second of May and the Jun order on the very first second of June.
    const userId = '2f1c8b6a-0000-4000-8000-000000000001';
    const lastSecondOfMay = 2000000.0;
    const firstSecondOfJune = 3000000.0;

    Future<void> seedBoundary({
      required CustomerRepository customers,
      required OrderRepository orders,
    }) async {
      await customers.upsert(person(userId));
      await orders.upsert(
        sale(
          id: 'apr',
          customerId: userId,
          date: DateTime(2026, 4, 15, 12),
          amount: 1000000,
        ),
      );
      await orders.upsert(
        sale(
          id: 'may-last-second',
          customerId: userId,
          date: DateTime(2026, 5, 31, 23, 59, 59),
          amount: lastSecondOfMay,
        ),
      );
      await orders.upsert(
        sale(
          id: 'jun-first-second',
          customerId: userId,
          date: DateTime(2026, 6, 1),
          amount: firstSecondOfJune,
        ),
      );
    }

    test('23:59:59 on the 31st and 00:00:00 on the 1st are different '
        'months', () async {
      final s = session(now: firstOfMonth);
      await seedBoundary(customers: s.customers, orders: s.orders);

      final ctx = await s.revenue.load();

      // Had the two orders collapsed into one bucket, that month would read
      // 5.0M and the other 0 — both assertions below would fail.
      expect(pointFor(ctx.series, const MonthKey(2026, 5)).revenue, 2000000);
      expect(pointFor(ctx.series, const MonthKey(2026, 5)).orderCount, 1);
      expect(pointFor(ctx.series, const MonthKey(2026, 6)).revenue, 3000000);
      expect(pointFor(ctx.series, const MonthKey(2026, 6)).orderCount, 1);

      // The stored instants survived the round-trip to the second.
      final stored = await s.orders.loadAll();
      final may = stored.firstWhere((o) => o.id == 'may-last-second');
      final jun = stored.firstWhere((o) => o.id == 'jun-first-second');
      expect(may.date.isBefore(jun.date), isTrue);
      expect(
        jun.date.difference(may.date).inSeconds,
        1,
        reason: 'the two orders are one second apart, in different months',
      );
    });

    test('a forecast computed on the 1st excludes the empty running '
        'month', () async {
      final s = session(now: firstOfMonth);
      await seedBoundary(customers: s.customers, orders: s.orders);

      final ctx = await s.revenue.load();
      final twin = const RevenueForecastRule().forecast(ctx);

      // The window stops at the last COMPLETED month; July is not a point at
      // all, so a 1st-of-the-month run cannot read as a collapse to zero.
      expect(ctx.currentMonthExcluded, isTrue);
      expect(ctx.series.latest!.key, lastCompleted);
      expect(
        ctx.series.points.map((p) => p.key),
        isNot(contains(const MonthKey(2026, 7))),
      );

      expect(twin.sufficiency, DataSufficiency.partial);
      expect(twin.confidence, ForecastConfidence.low);
      expect(twin.reasonCodes, [
        ReasonCode.revenueGrowing,
        ReasonCode.partialMonthExcluded,
      ]);

      // basis = [1.0M, 2.0M, 3.0M] (leading empty months trimmed)
      // level  = (1·1 + 2·2 + 3·3)/6 M            = 2 333 333,33
      // slope  = 1 000 000 đ/month
      // base   = level + 0.7 × slope × 5/3        = 3 500 000
      // volatility: usable changes [+1.00, +0.50] → sd 0.25 / scale 0.75 = 1/3
      // band   = 0.10 + 0.5×(1/3) + 0.15 (3–5 mo) = 0.4166667 of max(3.5M, 2M)
      final forecast = twin.result!;
      expect(forecast.basis.map((p) => p.revenue), [1000000, 2000000, 3000000]);
      expect(forecast.targetMonth, const MonthKey(2026, 7));
      expect(forecast.nextMonthRevenue, closeTo(3500000, 0.5));
      expect(forecast.trendPerMonth, closeTo(1000000, 0.5));
      expect(forecast.lowerBound, closeTo(2041666.67, 0.5));
      expect(forecast.upperBound, closeTo(4958333.33, 0.5));
      expect(forecast.direction, RevenueTrendDirection.growing);
      expect(forecast.seasonalMultiplierApplied, isNull);
    });

    test('an order inside the running month never enters the base', () async {
      final s = session(now: firstOfMonth);
      await seedBoundary(customers: s.customers, orders: s.orders);
      // A huge sale on the first day of the RUNNING month.
      await s.orders.upsert(
        sale(
          id: 'jul-running',
          customerId: userId,
          date: DateTime(2026, 7, 1, 8),
          amount: 99000000,
        ),
      );

      final ctx = await s.revenue.load();
      final twin = const RevenueForecastRule().forecast(ctx);

      // 1.0M + 2.0M + 3.0M — the 99M July order is outside the window.
      expect(ctx.totalRevenue, 6000000);
      expect(twin.result!.nextMonthRevenue, closeTo(3500000, 0.5));
      expect(twin.reasonCodes, contains(ReasonCode.partialMonthExcluded));
      // …but the order itself is still a real record.
      expect((await s.orders.loadAll()).length, 4);
      expect(ctx.orderHistory.total, 4);
    });
  });

  // ══ 2 · Timezone ═══════════════════════════════════════════════════════════

  group('timezone — buckets follow the LOCAL calendar month', () {
    test('MonthKey.of converts a UTC instant to local first', () {
      // Two instants either side of a UTC month boundary. On any device east
      // of Greenwich the second one is already the next month locally; west of
      // it the first one is still the previous month. Deriving the expectation
      // from `toLocal()` (the documented rule) rather than from `MonthKey.of`
      // keeps this a real assertion in every timezone.
      for (final instant in [
        DateTime.utc(2026, 6, 1, 0, 30),
        DateTime.utc(2026, 5, 31, 23, 30),
      ]) {
        final local = instant.toLocal();
        expect(
          MonthKey.of(instant),
          MonthKey(local.year, local.month),
          reason: 'a UTC instant must bucket by the seller\'s local month',
        );
      }
    });

    test('a UTC-stored order buckets by the month the seller saw', () async {
      // The seller typed this order at 00:30 on 1 June, local time. Stored as
      // a UTC instant it reads 31 May in UTC+7 — bucketing on the raw instant
      // would move it into May and disagree with the seller's own books.
      final localMoment = DateTime(2026, 6, 1, 0, 30);
      final storedUtc = localMoment.toUtc();
      expect(storedUtc.isUtc, isTrue);

      const userId = '2f1c8b6a-0000-4000-8000-000000000002';
      final s = session();
      await s.customers.upsert(person(userId));
      await s.orders.upsert(
        sale(
          id: 'utc-order',
          customerId: userId,
          date: storedUtc,
          amount: 4000000,
        ),
      );
      // A second order on the last local second of May, also stored as UTC.
      await s.orders.upsert(
        sale(
          id: 'utc-may',
          customerId: userId,
          date: DateTime(2026, 5, 31, 23, 59, 59).toUtc(),
          amount: 500000,
        ),
      );

      final ctx = await s.revenue.load();

      // Expectation derived from the instant's LOCAL fields, not from the
      // production bucketing helper.
      final expectedJune = storedUtc.toLocal();
      expect(
        pointFor(
          ctx.series,
          MonthKey(expectedJune.year, expectedJune.month),
        ).revenue,
        4000000,
      );
      expect(pointFor(ctx.series, const MonthKey(2026, 6)).revenue, 4000000);
      expect(pointFor(ctx.series, const MonthKey(2026, 5)).revenue, 500000);
      expect(ctx.totalRevenue, 4500000);

      // The instant itself round-tripped through SQLite unchanged.
      final reloaded = (await s.orders.loadAll()).firstWhere(
        (o) => o.id == 'utc-order',
      );
      expect(reloaded.date.toUtc(), storedUtc);
    });
  });

  // ══ 3 · Restart ════════════════════════════════════════════════════════════

  test('RESTART: a new AppDatabase on the same file reproduces the exact '
      'forecast and the exact risk ranking', () async {
    // 12 completed months, pinned to Jun 2026 so generation never reads a
    // wall clock. Same seed ⇒ same history ⇒ the ONLY variable is the restart.
    final s1 = session();
    await s1.historySeeder.seed(pinnedHistory());

    final revenue1 = await s1.revenue.load();
    final consumers1 = await s1.consumers.load();
    final forecast1 = const RevenueForecastRule().forecast(revenue1);
    final risk1 = const CustomerRiskRule().assess(consumers1);

    // Guard against a vacuous comparison: both twins must actually answer.
    expect(forecast1.hasAnswer, isTrue);
    expect(forecast1.sufficiency, DataSufficiency.sufficient);
    expect(risk1.hasAnswer, isTrue);
    expect(risk1.result!.entries, isNotEmpty);
    final seededOrders = (await s1.orders.loadAll()).length;
    final seededCustomers = (await s1.customers.loadAll()).length;
    expect(seededOrders, greaterThan(20));

    await s1.db.close();

    // ── restart ──────────────────────────────────────────────────────────────
    final s2 = session();
    expect((await s2.orders.loadAll()).length, seededOrders);
    expect((await s2.customers.loadAll()).length, seededCustomers);

    final revenue2 = await s2.revenue.load();
    final consumers2 = await s2.consumers.load();
    final forecast2 = const RevenueForecastRule().forecast(revenue2);
    final risk2 = const CustomerRiskRule().assess(consumers2);

    // Forecast: the same number, band, slope, direction, season and basis.
    expect(forecast2.result, forecast1.result);
    expect(
      forecast2.result!.nextMonthRevenue,
      forecast1.result!.nextMonthRevenue,
    );
    expect(forecast2.result!.lowerBound, forecast1.result!.lowerBound);
    expect(forecast2.result!.upperBound, forecast1.result!.upperBound);
    expect(forecast2.confidence, forecast1.confidence);
    expect(forecast2.sufficiency, forecast1.sufficiency);
    expect(forecast2.reasonCodes, forecast1.reasonCodes);
    expect(forecast2.version, forecast1.version);
    expect(forecast2.provenance, forecast1.provenance);

    // Risk: the same ORDER and the same scores, customer for customer.
    final ranking1 = [for (final e in risk1.result!.entries) e.customerId];
    final ranking2 = [for (final e in risk2.result!.entries) e.customerId];
    expect(ranking2, orderedEquals(ranking1));
    expect([
      for (final e in risk2.result!.entries) e.riskScore,
    ], orderedEquals([for (final e in risk1.result!.entries) e.riskScore]));
    expect(risk2.result!.entries, orderedEquals(risk1.result!.entries));
    expect(risk2.result!.stageCounts, risk1.result!.stageCounts);
    expect(risk2.result!.winBackCount, risk1.result!.winBackCount);
    expect(risk2.confidence, risk1.confidence);
    expect(risk2.sufficiency, risk1.sufficiency);
    expect(risk2.reasonCodes, risk1.reasonCodes);
    expect(risk2.provenance, risk1.provenance);
  });

  // ══ 4 · Reset sample data ══════════════════════════════════════════════════

  group('reset sample data', () {
    test('after removeAll the twins refuse — no fabricated zeros', () async {
      final s = session();
      await s.historySeeder.seed(pinnedHistory());
      expect(
        const RevenueForecastRule().forecast(await s.revenue.load()).hasAnswer,
        isTrue,
        reason: 'the reset must be observable — start from a real answer',
      );

      await s.sampleSeeder.removeAll();

      final revenue = await s.revenue.load();
      final forecast = const RevenueForecastRule().forecast(revenue);
      expect(revenue.hasData, isFalse);
      expect(forecast.sufficiency, DataSufficiency.insufficient);
      expect(
        forecast.result,
        isNull,
        reason: 'a refusal MUST be null, never a 0 ₫ forecast',
      );
      expect(forecast.confidence, ForecastConfidence.none);
      expect(forecast.reasonCodes, [
        ReasonCode.noRevenueYet,
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);

      final risk = const CustomerRiskRule().assess(await s.consumers.load());
      expect(risk.sufficiency, DataSufficiency.insufficient);
      expect(risk.result, isNull);
      expect(risk.reasonCodes, [ReasonCode.noCustomers]);
    });

    test('a user-created customer + order survive removeAll and stay in the '
        'recomputed risk assessment', () async {
      // UUID ids — the ADR-TON-014 marker of user data. NOT `sample-` prefixed.
      const userCustomerId = '7c9e6679-7425-40de-963d-e35b1566ac1f';
      const userOrderId = 'b21f3d5c-9a44-4f7e-91aa-0f2c6d8e4b10';

      final s = session();
      await s.historySeeder.seed(pinnedHistory());
      await s.customers.upsert(person(userCustomerId, name: 'Khách của tôi'));
      await s.orders.upsert(
        sale(
          id: userOrderId,
          customerId: userCustomerId,
          date: DateTime(2026, 6, 15, 10),
          amount: 2500000,
        ),
      );

      await s.sampleSeeder.removeAll();

      // Only the user's rows are left, and none of them is sample-prefixed.
      final customers = await s.customers.loadAll();
      final orders = await s.orders.loadAll();
      expect(customers.map((c) => c.id), [userCustomerId]);
      expect(orders.map((o) => o.id), [userOrderId]);
      expect(
        [
          ...customers.map((c) => c.id),
          ...orders.map((o) => o.id),
        ].where((id) => id.startsWith(kSampleIdPrefix)),
        isEmpty,
      );

      // Risk still assesses the survivor — by id, on the real order.
      final risk = const CustomerRiskRule().assess(await s.consumers.load());
      expect(risk.sufficiency, DataSufficiency.sufficient);
      expect(risk.result!.entries.map((e) => e.customerId), [userCustomerId]);
      expect(risk.result!.entries.single.lifetimeOrders, 1);
      expect(risk.result!.entries.single.lifetimeValue, 2500000);

      // The forecast now has ONE month of revenue: too thin to answer, but it
      // must not claim `noRevenueYet` — money was made.
      final forecast = const RevenueForecastRule().forecast(
        await s.revenue.load(),
      );
      expect(forecast.sufficiency, DataSufficiency.insufficient);
      expect(forecast.result, isNull);
      expect(forecast.reasonCodes, [
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);
      expect(forecast.reasonCodes, isNot(contains(ReasonCode.noRevenueYet)));
    });

    test('REGRESSION (WTM-162): resetting samples after the user recorded a '
        'real order for a SAMPLE customer must not crash', () async {
      // Sample rows are ordinary rows (ADR-TON-014), so recording a real sale
      // for a sample contact is legitimate. Before the fix, `removeAll()` then
      // deleted that contact while the user's UUID order still pointed at it:
      //   SqliteException(787): FOREIGN KEY constraint failed
      // — thrown from DriftCustomerRepository.deleteByIdPrefix, leaving the
      // reset half-applied (sample orders gone, everything else still there).
      const userOrderId = '9f8e7d6c-5b4a-4392-8171-0a1b2c3d4e5f';

      final s = session();
      await s.sampleSeeder.seed();
      final sampleCustomer = (await s.customers.loadAll()).firstWhere(
        (c) => c.id.startsWith(kSampleIdPrefix),
      );
      await s.orders.upsert(
        sale(
          id: userOrderId,
          customerId: sampleCustomer.id,
          date: DateTime(2026, 6, 20, 10),
          amount: 1500000,
        ),
      );

      await expectLater(s.sampleSeeder.removeAll(), completes);

      // The user's order survives — and so does the one row it cannot exist
      // without. Every other sample row is gone.
      final customers = await s.customers.loadAll();
      final orders = await s.orders.loadAll();
      expect(orders.map((o) => o.id), [userOrderId]);
      expect(customers.map((c) => c.id), [sampleCustomer.id]);
      expect((await s.products.loadAll()), isEmpty);
      expect((await s.goals.loadAll()), isEmpty);
      expect((await s.finance.loadAll()), isEmpty);

      // The twins read the survivors, not a half-deleted business.
      final risk = const CustomerRiskRule().assess(await s.consumers.load());
      expect(risk.sufficiency, DataSufficiency.sufficient);
      expect(risk.result!.entries.map((e) => e.customerId), [
        sampleCustomer.id,
      ]);
      expect(risk.result!.entries.single.lifetimeValue, 1500000);

      // A second reset is a clean no-op, not a second crash.
      await expectLater(s.sampleSeeder.removeAll(), completes);
      expect((await s.orders.loadAll()).map((o) => o.id), [userOrderId]);
    });
  });

  // ══ 5 · User data coexistence ══════════════════════════════════════════════

  test('sample history and user rows are BOTH consumed — no prefix filtering '
      'in the predictive path', () async {
    const userCustomerId = '7c9e6679-7425-40de-963d-e35b1566ac1f';

    final s = session();
    await s.historySeeder.seed(pinnedHistory());
    await s.customers.upsert(person(userCustomerId, name: 'Khách của tôi'));
    // Two user orders inside the completed window.
    await s.orders.upsert(
      sale(
        id: 'e4f1c2d3-0001-4000-8000-000000000001',
        customerId: userCustomerId,
        date: DateTime(2026, 5, 20, 11),
        amount: 3300000,
      ),
    );
    await s.orders.upsert(
      sale(
        id: 'e4f1c2d3-0001-4000-8000-000000000002',
        customerId: userCustomerId,
        date: DateTime(2026, 6, 20, 11),
        amount: 4400000,
      ),
    );

    /// Whether [date] falls in the 12 completed months ending Jun 2026 —
    /// plain arithmetic, independent of `month_bucket.dart`.
    bool inWindow(DateTime date) {
      final local = date.isUtc ? date.toLocal() : date;
      final ordinal = local.year * 12 + (local.month - 1);
      const last = 2026 * 12 + (6 - 1);
      return ordinal <= last && ordinal > last - 12;
    }

    final allOrders = await s.orders.loadAll();
    var sampleTotal = 0.0;
    var userTotal = 0.0;
    for (final order in allOrders) {
      if (order.status == OrderStatus.cancelled) continue;
      if (!inWindow(order.date)) continue;
      if (order.id.startsWith(kSampleIdPrefix)) {
        sampleTotal += order.totalAmount;
      } else {
        userTotal += order.totalAmount;
      }
    }
    expect(sampleTotal, greaterThan(0));
    expect(userTotal, 7700000);

    final revenue = await s.revenue.load();
    expect(
      revenue.totalRevenue,
      closeTo(sampleTotal + userTotal, 0.01),
      reason: 'the capability window total must be repository sample + user',
    );

    final consumers = await s.consumers.load();
    final risk = const CustomerRiskRule().assess(consumers);
    final allCustomers = await s.customers.loadAll();
    expect(consumers.totalCustomers, allCustomers.length);
    expect(risk.result!.totalCustomers, allCustomers.length);

    final assessedIds = risk.result!.entries.map((e) => e.customerId).toSet();
    expect(assessedIds, contains(userCustomerId));
    expect(
      assessedIds.where((id) => id.startsWith(kHistoricalIdPrefix)),
      isNotEmpty,
      reason: 'generated history customers must be assessed too',
    );
    expect(assessedIds.length, allCustomers.length);
    expect(risk.result!.entryFor(userCustomerId)!.lifetimeValue, 7700000);
  });

  test('no predictive/capability/analytics source filters by the sample id '
      'prefix', () {
    final offenders = <String>[];
    for (final dir in const [
      'lib/features/tongtai/predictive',
      'lib/features/tongtai/capability',
      'lib/features/tongtai/analytics',
    ]) {
      for (final file
          in Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trimLeft();
          if (trimmed.startsWith('//')) continue;
          if (lines[i].contains('kSampleIdPrefix') ||
              lines[i].contains("'sample-") ||
              lines[i].contains(r'"sample-')) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Sample rows are ORDINARY rows (ADR-TON-014). A twin that skips them '
          'would predict from a different business than the one the screens '
          'show:\n${offenders.join('\n')}',
    );
  });

  // ══ 6 · Sufficiency boundaries ═════════════════════════════════════════════

  group('sufficiency boundaries (months WITH revenue)', () {
    const userId = '2f1c8b6a-0000-4000-8000-000000000003';

    Future<RuleTwinResult<RevenueForecast>> forecastFor(int months) async {
      final s = session();
      await seedUniformMonths(
        customers: s.customers,
        orders: s.orders,
        customerId: userId,
        months: months,
      );
      return const RevenueForecastRule().forecast(await s.revenue.load());
    }

    test('2 months → insufficient (refuses, result null)', () async {
      final twin = await forecastFor(2);
      expect(twin.sufficiency, DataSufficiency.insufficient);
      expect(twin.result, isNull);
      expect(twin.confidence, ForecastConfidence.none);
      // Two months DID book revenue, so `noRevenueYet` would be a lie.
      expect(twin.reasonCodes, [
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);
    });

    test('3 months → partial + low (the flip)', () async {
      final twin = await forecastFor(3);
      expect(twin.sufficiency, DataSufficiency.partial);
      expect(twin.confidence, ForecastConfidence.low);
      // `notEnoughHistory` is gone: the rule's stated minimum IS met.
      expect(twin.reasonCodes, [
        ReasonCode.revenueFlat,
        ReasonCode.partialMonthExcluded,
      ]);

      // basis = [1.0M, 1.0M, 1.0M] → level 1.0M, slope 0, base 1.0M.
      // volatility 0 (every change is 0) → band = 0.10 + 0 + 0.15 = 0.25
      // of max(1.0M, 1.0M) = 250 000.
      final forecast = twin.result!;
      expect(forecast.nextMonthRevenue, closeTo(1000000, 0.5));
      expect(forecast.trendPerMonth, closeTo(0, 0.5));
      expect(forecast.lowerBound, closeTo(750000, 0.5));
      expect(forecast.upperBound, closeTo(1250000, 0.5));
      expect(forecast.direction, RevenueTrendDirection.flat);
      expect(forecast.basis, hasLength(3));
    });

    test('5 months → still partial + low', () async {
      final twin = await forecastFor(5);
      expect(twin.sufficiency, DataSufficiency.partial);
      expect(twin.confidence, ForecastConfidence.low);
      expect(twin.reasonCodes, [
        ReasonCode.revenueFlat,
        ReasonCode.partialMonthExcluded,
      ]);
      // Thin-history band penalty still 0.15 → ±250 000 on a 1.0M forecast.
      expect(twin.result!.lowerBound, closeTo(750000, 0.5));
      expect(twin.result!.upperBound, closeTo(1250000, 0.5));
    });

    test('6 months → sufficient + medium (the flip)', () async {
      final twin = await forecastFor(6);
      expect(twin.sufficiency, DataSufficiency.sufficient);
      expect(twin.confidence, ForecastConfidence.medium);
      expect(twin.reasonCodes, [
        ReasonCode.revenueFlat,
        ReasonCode.partialMonthExcluded,
      ]);
      // History penalty drops 0.15 → 0.05, so the band narrows to ±10%+5%.
      expect(twin.result!.nextMonthRevenue, closeTo(1000000, 0.5));
      expect(twin.result!.lowerBound, closeTo(850000, 0.5));
      expect(twin.result!.upperBound, closeTo(1150000, 0.5));
    });
  });

  // ══ 7 · Empty / degenerate businesses ══════════════════════════════════════

  group('empty and degenerate businesses return well-formed envelopes', () {
    test('a brand-new, empty database', () async {
      final s = session();

      final revenue = await s.revenue.load();
      final consumers = await s.consumers.load();
      final forecast = const RevenueForecastRule().forecast(revenue);
      final risk = const CustomerRiskRule().assess(consumers);

      expect(revenue.hasData, isFalse);
      expect(revenue.series.length, 12); // 12 explicit zero months, not empty
      expect(forecast.sufficiency, DataSufficiency.insufficient);
      expect(forecast.result, isNull);
      expect(forecast.reasonCodes, [
        ReasonCode.noRevenueYet,
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);
      expect(forecast.version, RevenueForecastRule.version);
      expect(forecast.generatedAt, midMonth);

      expect(consumers.hasData, isFalse);
      expect(risk.sufficiency, DataSufficiency.insufficient);
      expect(risk.result, isNull);
      expect(risk.reasonCodes, [ReasonCode.noCustomers]);
      // The refusal is still explainable: provenance is well-formed.
      expect(forecast.provenance, contains('sufficiency=insufficient'));
      expect(risk.provenance, contains('reasons=noCustomers'));
    });

    test('six months of orders that all booked ZERO revenue', () async {
      const userId = '2f1c8b6a-0000-4000-8000-000000000004';
      final s = session();
      await seedUniformMonths(
        customers: s.customers,
        orders: s.orders,
        customerId: userId,
        months: 6,
        amount: 0,
      );

      final revenue = await s.revenue.load();
      final forecast = const RevenueForecastRule().forecast(revenue);

      // Orders exist and are visible; revenue does not.
      expect(revenue.orderHistory.total, 6);
      expect(pointFor(revenue.series, lastCompleted).orderCount, 1);
      expect(pointFor(revenue.series, lastCompleted).revenue, 0);
      expect(revenue.monthsWithRevenue, 0);
      expect(revenue.hasData, isFalse);
      expect(forecast.sufficiency, DataSufficiency.insufficient);
      expect(forecast.result, isNull);
      expect(forecast.reasonCodes, [
        ReasonCode.noRevenueYet,
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);
      expect(revenue.promptBlock(), contains('CHƯA ĐỦ DỮ LIỆU'));

      // Risk still works: the customer bought six times, for nothing.
      final risk = const CustomerRiskRule().assess(await s.consumers.load());
      expect(risk.sufficiency, DataSufficiency.sufficient);
      final entry = risk.result!.entries.single;
      expect(entry.lifetimeOrders, 6);
      expect(entry.lifetimeValue, 0);
      expect(entry.riskScore, inInclusiveRange(0, 100));
      expect(entry.reasonCodes, isNotEmpty);
      // Zero spend can never buy a top monetary band…
      expect(entry.reasonCodes, isNot(contains(ReasonCode.highValueAtRisk)));
      expect(entry.winBackCandidate, isFalse);
    });

    test('one customer, one order', () async {
      const userId = '2f1c8b6a-0000-4000-8000-000000000005';
      final s = session();
      await s.customers.upsert(person(userId));
      await s.orders.upsert(
        sale(
          id: 'only-order',
          customerId: userId,
          date: DateTime(2026, 6, 15, 10),
          amount: 1800000,
        ),
      );

      final forecast = const RevenueForecastRule().forecast(
        await s.revenue.load(),
      );
      expect(forecast.sufficiency, DataSufficiency.insufficient);
      expect(forecast.result, isNull);
      expect(forecast.reasonCodes, [
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);

      final risk = const CustomerRiskRule().assess(await s.consumers.load());
      expect(risk.sufficiency, DataSufficiency.sufficient);
      expect(risk.confidence, ForecastConfidence.medium);

      // recency = 15 Jun → 15 Jul = 30 whole days, inside the fixed active
      // window, and there is no cadence (one order):
      //   ratio    = 1.0 × 30/30                    = 1.00
      //   lateness = 0.20 × 1.00/1.0                = 0.20
      //   loyalty  = single-purchase constant       = 0.60
      //   value    = band 2 of 2 (only spender)     = 1.00
      //   score    = 100 × (0.6×0.20 + 0.25×0.60 + 0.15×1.00) = 42.0
      final entry = risk.result!.entries.single;
      expect(entry.customerId, userId);
      expect(entry.recencyDays, 30);
      expect(entry.lifetimeOrders, 1);
      expect(entry.riskScore, closeTo(42, 0.05));
      expect(entry.reasonCodes, [
        ReasonCode.recentPurchase,
        ReasonCode.singlePurchaseOnly,
      ]);
      expect(entry.winBackCandidate, isFalse);
      expect(risk.reasonCodes, [
        ReasonCode.singlePurchaseOnly,
        ReasonCode.recentPurchase,
      ]);
    });

    test('a directory whose customers never bought', () async {
      final s = session();
      for (var i = 1; i <= 3; i++) {
        await s.customers.upsert(
          person('2f1c8b6a-0000-4000-8000-00000000010$i'),
        );
      }

      final consumers = await s.consumers.load();
      final risk = const CustomerRiskRule().assess(consumers);

      // A directory IS data — but nothing about churn can be claimed from it.
      expect(consumers.hasData, isTrue);
      expect(risk.sufficiency, DataSufficiency.partial);
      expect(risk.confidence, ForecastConfidence.low);
      expect(risk.reasonCodes.first, ReasonCode.noRevenueYet);
      expect(risk.result!.totalCustomers, 3);
      expect(risk.result!.lapsedCount, 0);
      expect(
        risk.result!.stage(CustomerLifecycleStage.neverPurchased),
        3,
        reason: 'a contact who never arrived never left',
      );
      for (final entry in risk.result!.entries) {
        expect(entry.recencyDays, isNull);
        expect(entry.lifetimeValue, 0);
        expect(entry.reasonCodes, isEmpty);
      }
    });
  });
}
