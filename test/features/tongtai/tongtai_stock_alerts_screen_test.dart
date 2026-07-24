import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('minimumThreshold floor surfaces extra products', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'a', name: 'Border Item', quantity: 8, reorderLevel: 5),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiStockAlertsScreen(
          catalog: catalog,
          imageSource: _NoopImageSource(),
          minimumThreshold: 10,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // qty 8 is above its own reorderLevel 5 but below the floor of 10.
    expect(find.text('Border Item'), findsOneWidget);
    expect(find.text('All stock levels healthy'), findsNothing);
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
      MaterialApp(
        home: TongtaiInventoryScreen(
          catalog: catalog,
          imageSource: _NoopImageSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Banner text summarises both states.
    expect(find.textContaining('1 out of stock'), findsOneWidget);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiStockAlertsScreen), findsOneWidget);
  });

  testWidgets('no banner when the catalog has no alerts', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory([
      product(id: 'ok', name: 'Healthy Item', quantity: 500),
    ]);
    await catalog.hydrate();
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiInventoryScreen(
          catalog: catalog,
          imageSource: _NoopImageSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View'), findsNothing);
    expect(find.textContaining('Stock alerts:'), findsNothing);
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
