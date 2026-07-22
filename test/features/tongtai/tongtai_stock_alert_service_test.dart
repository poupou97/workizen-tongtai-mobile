import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert_service.dart';

/// Unit tests for the WTM-70 [StockAlertService] engine: which products alert,
/// the counts, the most-urgent-first ordering, the minimum-threshold floor, and
/// the empty case.
void main() {
  Product product({
    required String id,
    String? name,
    required int quantity,
    int reorderLevel = 10,
  }) {
    return Product(
      id: id,
      sku: 'SKU-$id',
      name: name ?? 'Product $id',
      category: 'Electronics',
      quantity: quantity,
      pricePerUnit: 1000,
      reorderLevel: reorderLevel,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('a catalog with no alerting products has no alerts', () {
    final service = StockAlertService([
      product(id: 'a', quantity: 100),
      product(id: 'b', quantity: 50),
    ]);
    expect(service.hasAlerts, isFalse);
    expect(service.totalCount, 0);
    expect(service.alerts, isEmpty);
  });

  test('an empty catalog has no alerts', () {
    final service = StockAlertService(const []);
    expect(service.hasAlerts, isFalse);
    expect(service.totalCount, 0);
  });

  test('counts split low-stock and out-of-stock products', () {
    final service = StockAlertService([
      product(id: 'ok', quantity: 100), // healthy
      product(id: 'low1', quantity: 5, reorderLevel: 10), // low
      product(id: 'low2', quantity: 10, reorderLevel: 10), // low (at threshold)
      product(id: 'out', quantity: 0, reorderLevel: 10), // out
    ]);
    expect(service.hasAlerts, isTrue);
    expect(service.totalCount, 3);
    expect(service.outOfStockCount, 1);
    expect(service.lowStockCount, 2);
    expect(service.outOfStockAlerts.single.product.id, 'out');
    expect(
      service.lowStockAlerts.map((a) => a.product.id),
      containsAll(<String>['low1', 'low2']),
    );
  });

  test(
    'alerts are ordered out-of-stock first, then by shortfall descending',
    () {
      final service = StockAlertService([
        product(id: 'low-small', quantity: 8, reorderLevel: 10), // shortfall 2
        product(id: 'low-big', quantity: 2, reorderLevel: 10), // shortfall 8
        product(id: 'out', quantity: 0, reorderLevel: 10), // out of stock
      ]);
      expect(service.alerts.map((a) => a.product.id).toList(), [
        'out',
        'low-big',
        'low-small',
      ]);
    },
  );

  test('equal level and shortfall tie-break by product name', () {
    final service = StockAlertService([
      product(id: 'z', name: 'Zebra fan', quantity: 3, reorderLevel: 5),
      product(id: 'a', name: 'Apple charger', quantity: 3, reorderLevel: 5),
    ]);
    // Same level (low) and same shortfall (2) -> alphabetical by name.
    expect(service.alerts.map((a) => a.product.name).toList(), [
      'Apple charger',
      'Zebra fan',
    ]);
  });

  test(
    'the minimumThreshold floor pulls extra products into the alert set',
    () {
      final products = [
        product(id: 'a', quantity: 8, reorderLevel: 5), // healthy at floor 0
        product(id: 'b', quantity: 30, reorderLevel: 5), // healthy at floor 0
      ];
      expect(StockAlertService(products).hasAlerts, isFalse);

      final raised = StockAlertService(products, minimumThreshold: 10);
      expect(raised.lowStockCount, 1); // only 'a' (qty 8) falls under floor 10
      expect(raised.alerts.single.product.id, 'a');
      expect(raised.alerts.single.threshold, 10);
    },
  );

  test('a negative minimumThreshold is rejected by assertion', () {
    expect(
      () => StockAlertService(const [], minimumThreshold: -5),
      throwsA(isA<AssertionError>()),
    );
  });

  test('every returned entry is genuinely at or below its threshold', () {
    final service = StockAlertService([
      product(id: 'a', quantity: 0, reorderLevel: 10),
      product(id: 'b', quantity: 4, reorderLevel: 5),
      product(id: 'c', quantity: 999, reorderLevel: 5),
    ]);
    for (final alert in service.alerts) {
      expect(alert.quantity <= alert.threshold, isTrue);
    }
    expect(service.alerts.map((a) => a.product.id), isNot(contains('c')));
  });

  test('the sample catalog surfaces its known low/out products', () {
    // kSampleProducts has a mix of healthy, low and out-of-stock SKUs.
    final service = StockAlertService(kSampleProducts);
    expect(service.hasAlerts, isTrue);
    // p03 (qty 0), p09 (qty 0), p16 (qty 0), p25 (qty 0) are out of stock.
    expect(service.outOfStockCount, 4);
    expect(service.totalCount, greaterThan(service.outOfStockCount));
  });
}
