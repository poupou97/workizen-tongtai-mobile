import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_catalog_controller.dart';
import 'package:tongtai/features/tongtai/inventory/product_image_source.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_stock_alerts_screen.dart';

/// WTM-215 (concept-1 nhóm C) — the Inventory overview card and the
/// horizontally scrolling low-stock strip.
///
/// The contract under test is ADR-TON-015's "Summary Count == Domain Visible
/// Records", applied to chrome: the donut/KPIs come from [InventorySummary]
/// and the strip from `StockAlertService` — the same producers every other
/// surface reads — so the numbers here must equal what the rows below show.
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
    double price = 100000,
  }) {
    return Product(
      id: id,
      sku: 'SKU-$id',
      name: name,
      category: 'Electronics',
      quantity: quantity,
      pricePerUnit: price,
      reorderLevel: reorderLevel,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  /// 4 products: 2 healthy, 1 low, 1 out — value 100k×(20+15) + 100k×3 + 0.
  List<Product> mixedCatalog() => [
    product(id: 'a', name: 'Plenty A', quantity: 20),
    product(id: 'b', name: 'Plenty B', quantity: 15),
    product(id: 'low', name: 'Low Item', quantity: 3),
    product(id: 'out', name: 'Out Item', quantity: 0),
  ];

  Future<ProductCatalogController> pumpInventory(
    WidgetTester tester,
    List<Product> products,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController.inMemory(products);
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
    return catalog;
  }

  group('overview card reads InventorySummary — the one producer', () {
    testWidgets('KPIs match the summary computed from the same catalog', (
      tester,
    ) async {
      final products = mixedCatalog();
      await pumpInventory(tester, products);

      final summary = InventorySummary.from(products);
      expect(
        find.descendant(
          of: find.byKey(const Key('inventory-overview-count')),
          matching: find.text('${summary.productCount}'),
        ),
        findsOneWidget,
      );
      // Legend percentages derive from the same counts: 2/4 · 1/4 · 1/4.
      expect(find.textContaining('50%'), findsOneWidget);
      expect(find.textContaining('25%'), findsNWidgets(2));
      expect(find.byKey(const Key('inventory-overview-donut')), findsOneWidget);
    });

    testWidgets('an empty catalog shows no overview card', (tester) async {
      await pumpInventory(tester, const []);

      expect(find.byKey(const Key('inventory-overview')), findsNothing);
    });
  });

  group('low-stock strip IS the alert set (WTM-213 owner)', () {
    testWidgets('one card per alerting product; healthy ones absent', (
      tester,
    ) async {
      await pumpInventory(tester, mixedCatalog());

      expect(find.byKey(const Key('inventory-lowstock-low')), findsOneWidget);
      expect(find.byKey(const Key('inventory-lowstock-out')), findsOneWidget);
      expect(find.byKey(const Key('inventory-lowstock-a')), findsNothing);
      expect(find.byKey(const Key('inventory-lowstock-b')), findsNothing);
    });

    testWidgets('all healthy → no strip at all', (tester) async {
      await pumpInventory(tester, [
        product(id: 'a', name: 'Plenty A', quantity: 20),
      ]);

      expect(
        find.byKey(const Key('inventory-open-stock-alerts')),
        findsNothing,
      );
    });

    testWidgets('"view all" opens the Stock Alerts screen — same stable ID '
        'the old banner carried', (tester) async {
      await pumpInventory(tester, mixedCatalog());

      await tester.tap(find.byKey(const Key('inventory-open-stock-alerts')));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiStockAlertsScreen), findsOneWidget);
    });

    testWidgets('tapping a card opens that product in the edit form', (
      tester,
    ) async {
      await pumpInventory(tester, mixedCatalog());

      await tester.tap(find.byKey(const Key('inventory-lowstock-low')));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiProductFormScreen), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('product-name-field')))
            .controller!
            .text,
        'Low Item',
      );
    });
  });
}
