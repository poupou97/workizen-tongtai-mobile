import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_catalog_controller.dart';
import 'package:tongtai/features/tongtai/inventory/product_image_source.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_form_screen.dart';

/// End-to-end widget tests for the WTM-69 wiring on the Inventory screen: the
/// "+" button opens the Add form and a saved product lands in the list; tapping
/// a row opens the same form in Edit mode.
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

  Product product(String id, String name, String sku) => Product(
    id: id,
    sku: sku,
    name: name,
    category: 'Electronics',
    quantity: 5,
    pricePerUnit: 10000,
    reorderLevel: 2,
    updatedAt: DateTime(2026, 1, 1),
  );

  Widget host(ProductCatalogController catalog) => MaterialApp(
    home: TongtaiInventoryScreen(
      catalog: catalog,
      imageSource: _NoopImageSource(),
    ),
  );

  // Flushes the invalid-save SnackBar's auto-dismiss timer so it isn't left
  // pending at teardown (which fails the test).
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('the + button opens the Add Product form', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController([product('a', 'Alpha', 'SKU-A')]);
    await tester.pumpWidget(host(catalog));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add product'));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiProductFormScreen), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
  });

  testWidgets('adding a product through the form lands it in the list', (
    tester,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController([product('a', 'Alpha', 'SKU-A')]);
    await tester.pumpWidget(host(catalog));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add product'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Bravo',
    );
    await tester.enterText(find.byKey(const Key('product-sku-field')), 'SKU-B');
    await tester.enterText(
      find.byKey(const Key('product-category-field')),
      'Electronics',
    );
    await tester.enterText(
      find.byKey(const Key('product-price-field')),
      '5000',
    );
    await tester.enterText(
      find.byKey(const Key('product-quantity-field')),
      '9',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Product'));
    await tester.pumpAndSettle();

    // Back on the inventory list with the new product present.
    expect(find.byType(TongtaiProductFormScreen), findsNothing);
    expect(catalog.count, 2);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('2 products'), findsOneWidget);
  });

  testWidgets('tapping a product row opens it in Edit mode', (tester) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController([product('a', 'Alpha', 'SKU-A')]);
    await tester.pumpWidget(host(catalog));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Product'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-name-field')))
          .controller!
          .text,
      'Alpha',
    );
  });

  // Guards the edit-mode SKU-uniqueness wiring on the Inventory screen
  // (`isSkuTaken: (sku) => _catalog.isSkuTaken(sku, exceptId: product?.id)`).
  // Without the exceptId, a product would collide with its own SKU and *no*
  // edit that keeps the SKU could ever be saved — this test would catch that.
  testWidgets('editing a product and keeping its own SKU is allowed', (
    tester,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController([
      product('a', 'Alpha', 'SKU-A'),
      product('b', 'Bravo', 'SKU-B'),
    ]);
    await tester.pumpWidget(host(catalog));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    // Change only the name; leave the SKU (which already exists as this
    // product's own) untouched.
    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Alpha 2',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Save went through: back on the list with the renamed product, SKU kept.
    expect(find.byType(TongtaiProductFormScreen), findsNothing);
    expect(find.text('Alpha 2'), findsOneWidget);
    expect(catalog.count, 2);
    final edited = catalog.products.firstWhere((p) => p.id == 'a');
    expect(edited.name, 'Alpha 2');
    expect(edited.sku, 'SKU-A');
  });

  testWidgets('editing a product to reuse another product\'s SKU is rejected', (
    tester,
  ) async {
    useTallViewport(tester);
    final catalog = ProductCatalogController([
      product('a', 'Alpha', 'SKU-A'),
      product('b', 'Bravo', 'SKU-B'),
    ]);
    await tester.pumpWidget(host(catalog));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    // Collide Alpha's SKU with Bravo's.
    await tester.enterText(
      find.byKey(const Key('product-sku-field')),
      'SKU-B',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Blocked on the form with the uniqueness error; the catalog is untouched.
    expect(find.text('SKU already exists'), findsOneWidget);
    expect(find.text('Edit Product'), findsOneWidget);
    expect(catalog.products.firstWhere((p) => p.id == 'a').sku, 'SKU-A');
    await dismissSnackBar(tester);
  });
}
