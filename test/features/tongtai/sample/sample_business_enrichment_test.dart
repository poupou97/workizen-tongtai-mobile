import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_enricher.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_business_seeder.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// WTM-335 — the generator v2 is **additive** (§17): after the sample business
/// is seeded, the 100 products still exist AND DYNAMIC attributes were created
/// on top; and the v1 file-bridge import still runs unchanged. Real Drift, real
/// bundled dataset — the same file that ships in the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final demoFile = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
  final now = DateTime(2026, 8, 12, 9);

  late AppDatabase db;
  late DriftProductRepository products;
  late AttributeRepository attributes;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    products = DriftProductRepository(db);
    attributes = AttributeRepository(db);
  });
  tearDown(() => db.close());

  SampleBusinessSeeder seeder() {
    final samples = SampleDataSeeder(
      customers: DriftCustomerRepository(db),
      products: products,
      orders: DriftOrderRepository(db),
      goals: DriftBusinessGoalRepository(db),
      finance: DriftFinanceRepository(db),
    );
    return SampleBusinessSeeder(
      history: HistoricalDataSeeder(sampleSeeder: samples, clock: () => now),
      importer: CommerceImporter(
        database: db,
        products: products,
        customers: DriftCustomerRepository(db),
        orders: DriftOrderRepository(db),
        settlements: DriftSettlementRepository(db),
        commerce: CommerceRepository(db),
        shipments: ShipmentRepository(db),
        now: () => now,
        newId: () => 'bundled',
      ),
      commerce: CommerceRepository(db),
      samples: samples,
      customers: DriftCustomerRepository(db),
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      products: products,
      enricher: ProductAttributeEnricher(attributes),
      bundledSource: () async => XlsxCommerceSource(
        bytes: demoFile.readAsBytesSync(),
        fileName: demoFile.uri.pathSegments.last,
        now: now,
      ),
    );
  }

  test(
    'seed is ADDITIVE — 100 products remain AND attributes are created',
    () async {
      final report = await seeder().seed();

      // The dataset is untouched: the 100 imported products are all still there.
      final all = await products.loadAll();
      expect(all.length, greaterThanOrEqualTo(100));
      expect(report.products, greaterThanOrEqualTo(100));

      // Enrichment happened ON TOP: definitions + at least some products carry
      // per-industry values.
      expect(await attributes.loadDefinitions(), isNotEmpty);
      expect(await attributes.loadGroups(), isNotEmpty);
      expect(report.enrichedProducts, greaterThan(0));
      expect(
        report.enrichedProducts,
        lessThanOrEqualTo(all.length),
        reason: 'never more products enriched than exist',
      );
      expect(await attributes.loadAllValues(), isNotEmpty);
    },
  );

  test('not every product is enriched — sparse by industry (§17)', () async {
    final report = await seeder().seed();
    final total = (await products.loadAll()).length;
    expect(
      report.enrichedProducts,
      lessThan(total),
      reason: 'categories outside the four industries stay attribute-free',
    );
  });

  test(
    're-seeding stays additive and does not duplicate attribute rows',
    () async {
      await seeder().seed();
      final defsAfterFirst = (await attributes.loadDefinitions()).length;

      await seeder().seed();
      expect((await attributes.loadDefinitions()).length, defsAfterFirst);
      // Products remain the full set (the importer replaced its own job).
      expect((await products.loadAll()).length, greaterThanOrEqualTo(100));
    },
  );

  test('v1 file-bridge import still works after enrichment exists', () async {
    // Seed once so the attribute catalog + values are present.
    await seeder().seed();

    // Now run the production file-bridge import path AGAIN on the same file —
    // the v1 path must be unbroken by the new attribute layer.
    final preview = await XlsxCommerceSource(
      bytes: demoFile.readAsBytesSync(),
      fileName: demoFile.uri.pathSegments.last,
      now: now,
    ).read();
    final importer = CommerceImporter(
      database: db,
      products: products,
      customers: DriftCustomerRepository(db),
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      commerce: CommerceRepository(db),
      shipments: ShipmentRepository(db),
      now: () => now,
      newId: () => 'rerun',
    );
    final result = await importer.apply(
      preview,
      sourceVendor: ImportVendor.bundledDemo,
      isDemo: true,
    );
    expect(
      result.counts['products'],
      greaterThanOrEqualTo(100),
      reason: 'the v1 import path imports the products unchanged',
    );
  });
}
