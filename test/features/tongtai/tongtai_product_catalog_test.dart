import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_catalog_controller.dart';

/// Real unit tests for the WTM-69 [ProductCatalogController]: add/replace via
/// upsert, SKU-uniqueness, the read-only service view, and change notification.
void main() {
  Product product({
    String id = 'p1',
    String sku = 'SKU-1',
    String name = 'Widget',
    String category = 'Electronics',
    int quantity = 10,
    double pricePerUnit = 1000,
    int reorderLevel = 5,
  }) {
    return Product(
      id: id,
      sku: sku,
      name: name,
      category: category,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      reorderLevel: reorderLevel,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('sample catalog is seeded with the built-in products', () {
    final catalog = ProductCatalogController.sample();
    expect(catalog.count, 28);
    expect(catalog.service.all.length, 28);
  });

  test('upsert of a new id appends and returns false', () {
    final catalog = ProductCatalogController([product(id: 'a', sku: 'A')]);
    final replaced = catalog.upsert(product(id: 'b', sku: 'B'));
    expect(replaced, isFalse);
    expect(catalog.count, 2);
    expect(catalog.products.map((p) => p.id), containsAll(<String>['a', 'b']));
  });

  test('upsert of an existing id replaces in place and returns true', () {
    final catalog = ProductCatalogController([product(id: 'a', name: 'Old')]);
    final replaced = catalog.upsert(product(id: 'a', name: 'New'));
    expect(replaced, isTrue);
    expect(catalog.count, 1);
    expect(catalog.products.single.name, 'New');
  });

  test('the service view reflects the latest mutations', () {
    final catalog = ProductCatalogController([product(id: 'a', name: 'Alpha')]);
    catalog.upsert(product(id: 'b', name: 'Bravo'));
    final names = catalog.service.all.map((p) => p.name).toSet();
    expect(names, {'Alpha', 'Bravo'});
  });

  group('isSkuTaken', () {
    final catalog = ProductCatalogController([
      product(id: 'a', sku: 'SKU-EL-001'),
      product(id: 'b', sku: 'SKU-AC-002'),
    ]);

    test('an existing SKU is taken (case-insensitive, trimmed)', () {
      expect(catalog.isSkuTaken('SKU-EL-001'), isTrue);
      expect(catalog.isSkuTaken('  sku-el-001 '), isTrue);
    });

    test('a fresh SKU is free', () {
      expect(catalog.isSkuTaken('SKU-NEW-999'), isFalse);
    });

    test('a blank SKU is never taken', () {
      expect(catalog.isSkuTaken('   '), isFalse);
    });

    test('exceptId lets a product keep its own SKU', () {
      expect(catalog.isSkuTaken('SKU-EL-001', exceptId: 'a'), isFalse);
      expect(catalog.isSkuTaken('SKU-EL-001', exceptId: 'b'), isTrue);
    });
  });

  test('upsert notifies listeners', () {
    final catalog = ProductCatalogController(const []);
    var notes = 0;
    catalog.addListener(() => notes++);
    catalog.upsert(product(id: 'a'));
    catalog.upsert(product(id: 'a', name: 'Edited'));
    expect(notes, 2);
  });
}
