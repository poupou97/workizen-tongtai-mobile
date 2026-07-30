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
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// P0 §3 (WTM-146) — restart/persistence over a REAL SQLite FILE.
///
/// The §1 acceptance scenario proved the one-source model over in-memory
/// repositories; this suite proves it across an actual process "restart":
/// a brand-new [AppDatabase] instance opened on the SAME .db file must see
/// exactly what the previous instance persisted — seeded samples, user rows,
/// edits, and sample removal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-restart-');
    dbFile = File('${tempDir.path}/tongtai.db');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  AppDatabase open() => AppDatabase.forExecutor(NativeDatabase(dbFile));

  ({
    AppDatabase db,
    DriftCustomerRepository customers,
    DriftProductRepository products,
    DriftOrderRepository orders,
    DriftBusinessGoalRepository goals,
    DriftFinanceRepository finance,
    SampleDataSeeder seeder,
  })
  graph() {
    final db = open();
    final customers = DriftCustomerRepository(db);
    final products = DriftProductRepository(db);
    final orders = DriftOrderRepository(db);
    final goals = DriftBusinessGoalRepository(db);
    final finance = DriftFinanceRepository(db);
    return (
      db: db,
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      finance: finance,
      seeder: SampleDataSeeder(
        customers: customers,
        products: products,
        orders: orders,
        goals: goals,
        finance: finance,
      ),
    );
  }

  Customer user(String id) => Customer(
    id: id,
    name: 'Khách thật',
    phone: '+84900000001',
    location: 'Đà Nẵng',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: DateTime(2026, 7, 30),
    email: 'that@example.com',
  );

  test(
    'seed → RESTART → data intact; removeAll → RESTART → user survives',
    () async {
      // Session 1: seed samples + one real user row.
      final s1 = graph();
      await s1.seeder.seed();
      await s1.customers.upsert(user('7c9e6679-7425-40de-963d-e35b1566ac1f'));
      final seededCustomers = (await s1.customers.loadAll()).length;
      final seededProducts = (await s1.products.loadAll()).length;
      final seededOrders = (await s1.orders.loadAll()).length;
      final seededGoals = (await s1.goals.loadAll()).length;
      final seededTxns = (await s1.finance.loadAll()).length;
      expect(seededCustomers, greaterThan(1)); // samples + user row
      await s1.db.close();

      // Session 2 (restart): a NEW database instance on the SAME file.
      final s2 = graph();
      expect((await s2.customers.loadAll()).length, seededCustomers);
      expect((await s2.products.loadAll()).length, seededProducts);
      expect((await s2.orders.loadAll()).length, seededOrders);
      expect((await s2.goals.loadAll()).length, seededGoals);
      expect((await s2.finance.loadAll()).length, seededTxns);
      expect(
        (await s2.customers.loadAll()).any((c) => c.name == 'Khách thật'),
        isTrue,
      );

      // Still session 2: remove ALL samples — only `sample-` rows disappear.
      await s2.seeder.removeAll();
      final afterRemove = await s2.customers.loadAll();
      expect(afterRemove.map((c) => c.name), contains('Khách thật'));
      expect(
        afterRemove.where((c) => c.id.startsWith(kSampleIdPrefix)),
        isEmpty,
      );
      await s2.db.close();

      // Session 3 (second restart): the removal itself persisted.
      final s3 = graph();
      final finalCustomers = await s3.customers.loadAll();
      expect(finalCustomers.length, 1);
      expect(finalCustomers.single.name, 'Khách thật');
      expect(await s3.seeder.hasSamples(), isFalse);
      expect((await s3.products.loadAll()), isEmpty);
      expect((await s3.orders.loadAll()), isEmpty);
      expect((await s3.goals.loadAll()), isEmpty);
      expect((await s3.finance.loadAll()), isEmpty);
      await s3.db.close();
    },
  );

  test('editing a sample row persists across restart (ordinary row)', () async {
    final s1 = graph();
    await s1.seeder.seed();
    final sample = (await s1.customers.loadAll()).firstWhere(
      (c) => c.id.startsWith(kSampleIdPrefix),
    );
    await s1.customers.upsert(sample.copyWith(name: 'Đã sửa tay'));
    await s1.db.close();

    final s2 = graph();
    final edited = (await s2.customers.loadAll()).firstWhere(
      (c) => c.id == sample.id,
    );
    expect(edited.name, 'Đã sửa tay');
    // Edited sample keeps its prefix — removeAll still cleans it up.
    await s2.seeder.removeAll();
    expect(
      (await s2.customers.loadAll()).where((c) => c.id == sample.id),
      isEmpty,
    );
    await s2.db.close();
  });
}
