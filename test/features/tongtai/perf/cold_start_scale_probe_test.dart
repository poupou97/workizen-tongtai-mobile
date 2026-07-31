import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// WTM-166 — what the read amplification costs once a business has a year of
/// trading behind it.
///
/// **This asserts a ratio, never a duration.** The milliseconds here come from
/// a laptop and say nothing about a phone (the device numbers are measured
/// separately, on a release build, and live in the report). What *is* portable
/// is the shape: reading the same rows five times costs about five times one
/// read, whatever the machine.
///
/// The guard is deliberately loose — it exists to catch the day someone makes
/// a cold start read the whole order book ten times, not to police jitter.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late OrderRepository orders;
  late CustomerRepository customers;
  late ProductRepository products;
  late BusinessGoalRepository goals;
  late FinanceRepository finance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-scale-');
    db = AppDatabase.forExecutor(NativeDatabase(File('${tempDir.path}/t.db')));
    customers = DriftCustomerRepository(db);
    products = DriftProductRepository(db);
    orders = DriftOrderRepository(db);
    goals = DriftBusinessGoalRepository(db);
    finance = DriftFinanceRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test(
    'a year of trading: one read vs the reads a cold start actually does',
    () async {
      await HistoricalDataSeeder(
        sampleSeeder: SampleDataSeeder(
          customers: customers,
          products: products,
          orders: orders,
          goals: goals,
          finance: finance,
        ),
      ).seed(const HistoricalDataSpec());

      final orderRows = (await orders.loadAll()).length;
      final customerRows = (await customers.loadAll()).length;
      final financeRows = (await finance.loadAll()).length;

      // One read of every table a cold start touches — the floor.
      final once = Stopwatch()..start();
      await customers.loadAll();
      await products.loadAll();
      await orders.loadAll();
      await goals.loadAll();
      await finance.loadAll();
      once.stop();

      // What a cold start does today: customers ×4, products ×3, orders ×5,
      // goals ×4, finance ×2 (locked in by cold_start_read_amplification_test).
      final actual = Stopwatch()..start();
      for (var i = 0; i < 4; i++) {
        await customers.loadAll();
      }
      for (var i = 0; i < 3; i++) {
        await products.loadAll();
      }
      for (var i = 0; i < 5; i++) {
        await orders.loadAll();
      }
      for (var i = 0; i < 4; i++) {
        await goals.loadAll();
      }
      for (var i = 0; i < 2; i++) {
        await finance.loadAll();
      }
      actual.stop();

      // ignore: avoid_print
      print(
        'TT-SCALE rows: orders=$orderRows customers=$customerRows '
        'finance=$financeRows | once=${once.elapsedMilliseconds}ms '
        'coldStartReads=${actual.elapsedMilliseconds}ms '
        'ratio=${(actual.elapsedMicroseconds / once.elapsedMicroseconds).toStringAsFixed(1)}x',
      );

      expect(
        orderRows,
        greaterThan(100),
        reason:
            'a 12-month retail history should be a real workload, not a toy',
      );
      expect(
        actual.elapsedMicroseconds / once.elapsedMicroseconds,
        lessThan(6.0),
        reason:
            'a cold start should not cost more than the ~3.6 reads-per-table it '
            'was measured doing; if this trips, someone added another full-table '
            'read to the launch path',
      );
    },
  );
}
