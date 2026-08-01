import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_catalog_controller.dart';
import 'package:tongtai/features/tongtai/inventory/product_image_source.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_stock_alerts_screen.dart';

/// Widget tests for the WTM-70 Stock Alerts screen and the Inventory alert
/// banner: the alerting products are listed with their counts, the healthy state
/// shows when nothing is low, tapping a row opens the edit form, a restock drops
/// the alert live, and the Inventory banner navigates to the screen.
class _NoopImageSource implements ProductImageSource {
  @override
  Future<String?> pickFromGallery() async => null;
  @override
  Future<String?> captureFromCamera() async => null;
}

void main() {
  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3400);
  }

  Product product({
    required String id,
    required String name,
    required int quantity,
    int reorderLevel = 10,
  }) {
    return Product(
      id: id,
      sku: 'SKU-$id',
      name: name,
      category: 'Electronics',
      quantity: quantity,
      pricePerUnit: 10000,
      reorderLevel: reorderLevel,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  Widget alertsHost(ProductCatalogController catalog) => MaterialApp(
    home: TongtaiStockAlertsScreen(
      catalog: catalog,
      imageSource: _NoopImageSource(),
    ),
  );

  testWidgets('lists alerting products with summary counts', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'ok', name: 'Healthy Item', quantity: 100),
      product(id: 'low', name: 'Low Item', quantity: 3, reorderLevel: 10),
      product(id: 'out', name: 'Out Item', quantity: 0, reorderLevel: 10),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(alertsHost(catalog));
    await tester.pumpAndSettle();

    // Both alerting products are shown; the healthy one is not.
    expect(find.text('Low Item'), findsOneWidget);
    expect(find.text('Out Item'), findsOneWidget);
    expect(find.text('Healthy Item'), findsNothing);

    // Summary shows one out of stock and one low.
    expect(find.text('Out of stock'), findsWidgets);
    expect(find.text('Low stock'), findsWidgets);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('shows the healthy state when nothing is low', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'a', name: 'Plenty', quantity: 500),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(alertsHost(catalog));
    await tester.pumpAndSettle();

    expect(find.text('All stock levels healthy'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('tapping an alert row opens the product in the edit form', (
    tester,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'low', name: 'Low Item', quantity: 3, reorderLevel: 10),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(alertsHost(catalog));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Low Item'));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiProductFormScreen), findsOneWidget);
    expect(find.text('Edit Product'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-name-field')))
          .controller!
          .text,
      'Low Item',
    );
  });

  testWidgets('restocking a product drops its alert live', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'low', name: 'Low Item', quantity: 3, reorderLevel: 10),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(alertsHost(catalog));
    await tester.pumpAndSettle();
    expect(find.text('Low Item'), findsOneWidget);

    // Simulate a restock upsert (as the edit form would produce) — the screen
    // listens to the catalog, so the now-healthy product drops off the list.
    catalog.upsert(
      product(id: 'low', name: 'Low Item', quantity: 200, reorderLevel: 10),
    );
    await tester.pumpAndSettle();

    expect(find.text('Low Item'), findsNothing);
    expect(find.text('All stock levels healthy'), findsOneWidget);
  });

  testWidgets('a product above its own reorder level never appears (WTM-213)', (
    tester,
  ) async {
    // This test used to assert the OPPOSITE: a `minimumThreshold: 10` floor
    // pulled qty-8/reorder-5 "Border Item" onto this screen while the
    // Inventory list badge still said in-stock — two truths for one shelf.
    // WTM-213 removed the floor; the product's own reorder level is the one
    // rule, so the seller who set 5 is not alarmed at 8.
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'a', name: 'Border Item', quantity: 8, reorderLevel: 5),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(alertsHost(catalog));
    await tester.pumpAndSettle();

    expect(find.text('Border Item'), findsNothing);
    expect(find.text('All stock levels healthy'), findsOneWidget);
  });

  testWidgets('inventory banner shows counts and opens the alerts screen', (
    tester,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'ok', name: 'Healthy Item', quantity: 100),
      product(id: 'low', name: 'Low Item', quantity: 3, reorderLevel: 10),
      product(id: 'out', name: 'Out Item', quantity: 0, reorderLevel: 10),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiInventoryScreen(
            catalog: catalog,
            imageSource: _NoopImageSource(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // WTM-215: the WTM-70 text banner became the concept-1 low-stock strip;
    // the affordance keeps the banner's stable ID (found by Key, not display
    // text — the lesson the repo learned three times on 2026-07-31).
    expect(find.byKey(const Key('inventory-lowstock-low')), findsOneWidget);
    expect(find.byKey(const Key('inventory-lowstock-out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventory-open-stock-alerts')));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiStockAlertsScreen), findsOneWidget);
  });

  testWidgets('no low-stock strip when the catalog has no alerts', (
    tester,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'ok', name: 'Healthy Item', quantity: 500),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiInventoryScreen(
            catalog: catalog,
            imageSource: _NoopImageSource(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-open-stock-alerts')), findsNothing);
    expect(find.byKey(const Key('inventory-lowstock-ok')), findsNothing);
  });

  test('tongtaiStockAlertColor maps each level to its token', () {
    expect(
      tongtaiStockAlertColor(StockAlertLevel.outOfStock),
      TongtaiDesignTokens.error,
    );
    expect(
      tongtaiStockAlertColor(StockAlertLevel.lowStock),
      TongtaiDesignTokens.warning,
    );
  });
}
