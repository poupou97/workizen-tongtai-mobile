import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert.dart';

/// Unit tests for the WTM-70 [StockAlert] domain model: level derivation from
/// quantity vs. threshold, shortfall math, labels and equality.
///
/// WTM-213 removed the `minimumThreshold` catalog floor — a second rule for a
/// concept whose one owner is [Product.stockStatus] (P-27). The floor tests
/// were replaced by the agreement group at the bottom: the alert now IS the
/// status, so they cannot drift.
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

  group('one owner: the alert agrees with Product.stockStatus (WTM-213)', () {
    test('an alert exists exactly when the badge is not in-stock', () {
      // Sweep quantity × reorderLevel: if the list badge and the alert set
      // ever disagree, two screens describe one shelf with two truths — the
      // WTM-196/200/201/205 defect class, caught here at the source.
      for (var reorder = 0; reorder <= 6; reorder += 3) {
        for (var qty = 0; qty <= 8; qty++) {
          final p = product(quantity: qty, reorderLevel: reorder);
          final alert = StockAlert.forProduct(p);

          expect(
            alert != null,
            p.stockStatus != StockStatus.inStock,
            reason: 'qty=$qty reorder=$reorder: badge and alert disagree',
          );
          if (alert != null) {
            expect(
              alert.level == StockAlertLevel.outOfStock,
              p.stockStatus == StockStatus.outOfStock,
              reason: 'qty=$qty reorder=$reorder: urgency does not match',
            );
          }
        }
      }
    });

    test('the threshold shown is the product\'s own reorder level', () {
      // No catalog floor exists any more — the "SL x / y" line on the alerts
      // screen shows the number the seller typed on the product form.
      final alert = StockAlert.forProduct(
        product(quantity: 2, reorderLevel: 5),
      );
      expect(alert!.threshold, 5);
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
