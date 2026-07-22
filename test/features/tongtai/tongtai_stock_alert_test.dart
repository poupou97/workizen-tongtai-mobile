import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert.dart';

/// Unit tests for the WTM-70 [StockAlert] domain model: level derivation from
/// quantity vs. threshold, the catalog-wide minimum-threshold floor, shortfall
/// math, labels and equality.
void main() {
  Product product({
    String id = 'p1',
    String name = 'Widget',
    int quantity = 10,
    int reorderLevel = 5,
  }) {
    return Product(
      id: id,
      sku: 'SKU-$id',
      name: name,
      category: 'Electronics',
      quantity: quantity,
      pricePerUnit: 1000,
      reorderLevel: reorderLevel,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('forProduct level derivation', () {
    test('healthy stock (above threshold) raises no alert', () {
      expect(
        StockAlert.forProduct(product(quantity: 10, reorderLevel: 5)),
        isNull,
      );
    });

    test('quantity at the threshold is low stock', () {
      final alert = StockAlert.forProduct(
        product(quantity: 5, reorderLevel: 5),
      );
      expect(alert, isNotNull);
      expect(alert!.level, StockAlertLevel.lowStock);
      expect(alert.threshold, 5);
    });

    test('quantity below the threshold is low stock', () {
      final alert = StockAlert.forProduct(
        product(quantity: 3, reorderLevel: 5),
      );
      expect(alert!.level, StockAlertLevel.lowStock);
    });

    test('zero quantity is out of stock', () {
      final alert = StockAlert.forProduct(
        product(quantity: 0, reorderLevel: 5),
      );
      expect(alert!.level, StockAlertLevel.outOfStock);
    });

    test('out of stock even when the threshold is zero', () {
      final alert = StockAlert.forProduct(
        product(quantity: 0, reorderLevel: 0),
      );
      expect(alert!.level, StockAlertLevel.outOfStock);
    });
  });

  group('minimumThreshold floor (WTM-70 set-threshold)', () {
    test(
      'raising the floor turns a healthy product into a low-stock alert',
      () {
        final p = product(quantity: 8, reorderLevel: 5);
        expect(StockAlert.forProduct(p), isNull);

        final alert = StockAlert.forProduct(p, minimumThreshold: 10);
        expect(alert, isNotNull);
        expect(alert!.level, StockAlertLevel.lowStock);
        // Effective threshold is the larger of reorderLevel and the floor.
        expect(alert.threshold, 10);
      },
    );

    test(
      'the per-product reorderLevel wins when it is higher than the floor',
      () {
        final alert = StockAlert.forProduct(
          product(quantity: 40, reorderLevel: 50),
          minimumThreshold: 10,
        );
        expect(alert!.threshold, 50);
      },
    );

    test('a negative floor is rejected by assertion', () {
      expect(
        () => StockAlert.forProduct(product(), minimumThreshold: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('shortfall', () {
    test('is the gap between threshold and quantity for a low-stock item', () {
      final alert = StockAlert.forProduct(
        product(quantity: 3, reorderLevel: 5),
      );
      expect(alert!.shortfall, 2);
    });

    test('equals the threshold when out of stock', () {
      final alert = StockAlert.forProduct(
        product(quantity: 0, reorderLevel: 5),
      );
      expect(alert!.shortfall, 5);
    });

    test('is never negative and is zero when threshold is zero', () {
      final alert = StockAlert.forProduct(
        product(quantity: 0, reorderLevel: 0),
      );
      expect(alert!.shortfall, 0);
    });
  });

  group('labels', () {
    test('English and Vietnamese labels are distinct per level', () {
      expect(StockAlertLevel.outOfStock.labelEn, 'Out of stock');
      expect(StockAlertLevel.lowStock.labelEn, 'Low stock');
      expect(StockAlertLevel.outOfStock.labelVi, 'Hết hàng');
      expect(StockAlertLevel.lowStock.labelVi, 'Sắp hết hàng');
    });

    test('label() switches on language code', () {
      expect(StockAlertLevel.lowStock.label('vi'), 'Sắp hết hàng');
      expect(StockAlertLevel.lowStock.label('en'), 'Low stock');
      expect(StockAlertLevel.lowStock.label('fr'), 'Low stock');
    });
  });

  group('equality', () {
    test('alerts for the same product, level and threshold are equal', () {
      final a = StockAlert.forProduct(product(id: 'x', quantity: 2));
      final b = StockAlert.forProduct(product(id: 'x', quantity: 2));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('alerts for different products are not equal', () {
      final a = StockAlert.forProduct(product(id: 'x', quantity: 2));
      final b = StockAlert.forProduct(product(id: 'y', quantity: 2));
      expect(a, isNot(equals(b)));
    });
  });

  test('quantity is forwarded from the product', () {
    final alert = StockAlert.forProduct(product(quantity: 4, reorderLevel: 10));
    expect(alert!.quantity, 4);
  });
}
