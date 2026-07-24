import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';

/// WTM-121 — product persistence over Drift with the structured-columns +
/// versioned-snapshot convention (ADR-TON-009).
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  Product product(
    String id, {
    String sku = 'SKU',
    String name = 'Quạt mini',
    int quantity = 12,
    double price = 89000,
    int reorder = 5,
    List<String> images = const [],
  }) => Product(
    id: id,
    sku: sku,
    name: name,
    category: 'Electronics',
    quantity: quantity,
    pricePerUnit: price,
    reorderLevel: reorder,
    updatedAt: DateTime(2026, 7, 10),
    description: 'mô tả',
    imagePaths: images,
  );

  test('a new catalogue starts EMPTY (no sample seeded)', () async {
    expect(await DriftProductRepository(db).loadAll(), isEmpty);
  });

  test('upsert persists structured fields and reads them back', () async {
    final repo = DriftProductRepository(db);
    await repo.upsert(product('p1', name: 'Quạt', quantity: 7, price: 120000));

    final all = await repo.loadAll();
    expect(all, hasLength(1));
    final p = all.single;
    expect(p.id, 'p1');
    expect(p.name, 'Quạt');
    expect(p.quantity, 7);
    expect(p.pricePerUnit, 120000);
    expect(p.reorderLevel, 5);
    expect(p.category, 'Electronics');
    expect(p.description, 'mô tả');
  });

  test(
    'extended fields (imagePaths) survive via the versioned snapshot',
    () async {
      final repo = DriftProductRepository(db);
      await repo.upsert(product('p1', images: ['/a.jpg', '/b.png']));
      final reloaded = await DriftProductRepository(db).loadAll();
      expect(reloaded.single.imagePaths, ['/a.jpg', '/b.png']);
    },
  );

  test('upsert replaces the product with the same id (edit)', () async {
    final repo = DriftProductRepository(db);
    await repo.upsert(product('p1', name: 'Old', quantity: 1));
    await repo.upsert(product('p1', name: 'New', quantity: 9));

    final all = await repo.loadAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'New');
    expect(all.single.quantity, 9);
  });

  test('data survives across a fresh repository over the same db', () async {
    await DriftProductRepository(db).upsert(product('p1'));
    final reloaded = await DriftProductRepository(db).loadAll();
    expect(reloaded.map((p) => p.id), ['p1']);
  });

  group('SampleProductRepository (demo, read-only)', () {
    test('returns the sample catalogue and never persists', () async {
      const repo = SampleProductRepository();
      final before = (await repo.loadAll()).length;
      expect(before, greaterThan(0));
      await repo.upsert(product('p1'));
      expect((await repo.loadAll()).length, before);
    });
  });
}
