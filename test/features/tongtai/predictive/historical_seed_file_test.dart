import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// **WTM-149 device defect 2 — the bulk seeding path writes the same data.**
///
/// "Load 12 months of sample data" used to write every generated record with
/// its own `upsert` — hundreds of orders and thousands of finance rows, each a
/// separate Drift statement and therefore a separate implicit transaction. On a
/// Galaxy S24 Ultra that took ~4–5 minutes with the UI frozen, and Android's
/// low-memory killer restarted the app mid-seed. The repositories now expose a
/// bulk write (`upsertAll` / `addAll`) backed by a single Drift `batch`.
///
/// Speed is worthless if the rows change, so this suite pins the *contract*
/// rather than the clock: seeding into a **REAL SQLite file** (the
/// `p0/drift_restart_test.dart` pattern — in-memory repositories cannot prove
/// anything about batching, transactions or the foreign key) must persist
/// EXACTLY the [HistoricalDataSet] the generator produced — same row counts,
/// same ids, same money — and must stay idempotent and fully removable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  AppDatabase? open;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-seed-file-');
    dbFile = File('${tempDir.path}/tongtai.db');
  });

  tearDown(() async {
    await open?.close();
    open = null;
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ({
    AppDatabase db,
    DriftCustomerRepository customers,
    DriftProductRepository products,
    DriftOrderRepository orders,
    DriftBusinessGoalRepository goals,
    DriftFinanceRepository finance,
    SampleDataSeeder sampleSeeder,
    HistoricalDataSeeder historySeeder,
  })
  session() {
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
        // Pinned: the persisted rows must not depend on the wall clock.
        clock: () => DateTime(2026, 7, 15, 9, 30),
      ),
    );
  }

  /// The 12 months the More screen's "Load 12 months of sample data" seeds.
  const spec = HistoricalDataSpec();

  test('12 months seeded into a REAL SQLite file persist EXACTLY the generated '
      'HistoricalDataSet (batch path ≡ per-row path)', () async {
    final s = session();
    final data = s.historySeeder.generate(spec);

    // The fixture must actually be big enough to be worth batching —
    // otherwise this test would pass on a dataset that never had the problem.
    expect(
      data.orders.length,
      greaterThan(200),
      reason: '12 tháng phải sinh ra hàng trăm đơn hàng',
    );
    expect(
      data.transactions.length,
      greaterThan(200),
      reason: 'mỗi đơn hợp lệ sinh một giao dịch thu + chi phí hàng tháng',
    );

    final stopwatch = Stopwatch()..start();
    await s.historySeeder.seed(spec);
    stopwatch.stop();
    // Reported, never asserted: wall-clock on CI hardware is not a contract.
    // ignore: avoid_print
    print(
      'seed(12 months): ${stopwatch.elapsedMilliseconds} ms for '
      '${data.customers.length} customers, ${data.products.length} products, '
      '${data.orders.length} orders, ${data.goals.length} goals, '
      '${data.transactions.length} transactions',
    );

    final customers = await s.customers.loadAll();
    final products = await s.products.loadAll();
    final orders = await s.orders.loadAll();
    final goals = await s.goals.loadAll();
    final finance = await s.finance.loadAll();

    // 1. Row counts match the generated set exactly — nothing dropped by the
    //    batch, nothing duplicated.
    expect(customers, hasLength(data.customers.length));
    expect(products, hasLength(data.products.length));
    expect(orders, hasLength(data.orders.length));
    expect(goals, hasLength(data.goals.length));
    expect(finance, hasLength(data.transactions.length));

    // 2. Identity matches exactly — same ids, no `sample-` contract drift.
    Set<String> idsOf(Iterable<dynamic> rows) => {
      for (final r in rows) r.id as String,
    };
    expect(idsOf(customers), idsOf(data.customers));
    expect(idsOf(products), idsOf(data.products));
    expect(idsOf(orders), idsOf(data.orders));
    expect(idsOf(goals), idsOf(data.goals));
    expect(idsOf(finance), idsOf(data.transactions));
    for (final id in idsOf(orders)) {
      expect(id, startsWith(kHistoricalIdPrefix));
      expect(id, startsWith(kSampleIdPrefix));
    }

    // 3. Money matches exactly — a batch that silently coerced a column would
    //    keep the counts and lose the numbers.
    double revenueOf(Iterable<dynamic> rows) =>
        rows.fold(0.0, (sum, o) => sum + (o.totalAmount as double));
    expect(revenueOf(orders), closeTo(revenueOf(data.orders), 1e-6));
    expect(
      finance.fold(0.0, (sum, t) => sum + t.amount),
      closeTo(data.transactions.fold(0.0, (sum, t) => sum + t.amount), 1e-6),
    );

    // 4. Foreign key holds: every persisted order points at a persisted
    //    customer (customers must be committed before the orders batch).
    final customerIds = idsOf(customers);
    for (final o in orders) {
      expect(customerIds, contains(o.customerId));
    }
  });

  test(
    're-seeding is idempotent and removal wipes every generated row',
    () async {
      final s = session();
      final data = s.historySeeder.generate(spec);

      await s.historySeeder.seed(spec);
      await s.historySeeder.seed(spec);

      // Finance is insert-only: a non-idempotent seed would double it (or throw
      // on the primary key).
      expect(await s.finance.loadAll(), hasLength(data.transactions.length));
      expect(await s.orders.loadAll(), hasLength(data.orders.length));
      expect(await s.customers.loadAll(), hasLength(data.customers.length));

      await s.historySeeder.removeAll();
      expect(await s.customers.loadAll(), isEmpty);
      expect(await s.products.loadAll(), isEmpty);
      expect(await s.orders.loadAll(), isEmpty);
      expect(await s.goals.loadAll(), isEmpty);
      expect(await s.finance.loadAll(), isEmpty);
      expect(await s.historySeeder.hasSamples(), isFalse);
    },
  );

  test(
    'a user order written against a seeded customer pins that customer through '
    'removal (WTM-162 foreign key)',
    () async {
      final s = session();
      await s.historySeeder.seed(spec);

      // The user records their own sale for a seeded contact (sample rows are
      // ordinary rows, ADR-TON-014) — that customer must survive the sweep, or
      // the delete hits SqliteException 787 and takes user data with it.
      final seededOrder = (await s.orders.loadAll()).first;
      final pinnedCustomerId = seededOrder.customerId;
      await s.orders.upsert(
        seededOrder.withIds(newId: '7c9e6679-7425-40de-963d-e35b1566ac1f'),
      );

      await s.historySeeder.removeAll();

      expect(
        (await s.customers.loadAll()).map((Customer c) => c.id),
        contains(pinnedCustomerId),
      );
      final remaining = await s.orders.loadAll();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, isNot(startsWith(kSampleIdPrefix)));
    },
  );
}
