import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';

/// Real widget tests for the WTM-68 Inventory screen: the screen is built and
/// pumped and every acceptance criterion is exercised through the UI — the
/// product rows (name/SKU/quantity/price), color-coded stock status, the four
/// sort controls, search + category filtering, and 20-per-page pagination.
///
/// Each product row shows a "₫" price, so `find.textContaining('₫')` counts the
/// visible rows. A tall test viewport keeps the whole page laid out (not lazily
/// culled) so those counts are exact.
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    // The real screen starts empty (User Data First, WTM-121); inject the sample
    // catalogue so the list-UI tests (sort/filter/paging) have data to exercise.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TongtaiInventoryScreen(
            service: ProductInventoryService(kSampleProducts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 3200);
  }

  testWidgets('renders header, search, filters and the results count', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpScreen(tester);

    expect(find.text('Inventory'), findsOneWidget); // AppBar
    expect(find.byType(TextField), findsOneWidget); // search input
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);

    // The whole sample catalog (28 products) is counted, across two pages.
    expect(find.text('28 products'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/2',
    );
  });

  testWidgets('a product row shows name, SKU, quantity and price', (
    tester,
  ) async {
    // WTM-215 put the overview + low-stock chrome above the list, so the rows
    // start below a default 600px fold — the tall viewport keeps them built.
    useTallViewport(tester);
    await pumpScreen(tester);

    // Isolate a single product by its SKU so the assertion doesn't depend on
    // which default-sorted page it lands on.
    await tester.enterText(find.byType(TextField), 'SKU-EL-001');
    await tester.pumpAndSettle();

    expect(find.text('1 product'), findsOneWidget);
    expect(find.text('Quạt mini cầm tay'), findsOneWidget); // name
    // Exact row text (not the search field's echo of the SKU).
    expect(find.text('SKU-EL-001 • Electronics'), findsOneWidget); // SKU
    expect(find.text('Qty 195'), findsOneWidget); // quantity
    // Price on the row + the overview card's stock-value KPI (WTM-215).
    expect(find.textContaining('₫'), findsNWidgets(2));
  });

  testWidgets('paginates 28 products into two pages of 20', (tester) async {
    useTallViewport(tester);
    await pumpScreen(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/2',
    );
    // 20 rows on page 1 + the overview stock-value KPI (WTM-215).
    expect(find.textContaining('₫'), findsNWidgets(21));

    // Advance to page 2.
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 2/2',
    );
    // Remaining 8 rows + the overview stock-value KPI (WTM-215).
    expect(find.textContaining('₫'), findsNWidgets(9));

    // ...and back.
    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/2',
    );
  });

  testWidgets('search narrows the results by name', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'bluetooth');
    await tester.pumpAndSettle();

    // "Tai nghe bluetooth" + "Loa bluetooth mini".
    expect(find.text('2 products'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/1',
    );
  });

  testWidgets('category filter narrows the results', (tester) async {
    await pumpScreen(tester);

    final chip = find.widgetWithText(ChoiceChip, 'Electronics');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // Seven sample products are Electronics.
    expect(find.text('7 products'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/1',
    );
  });

  testWidgets('shows a color-coded status label for an out-of-stock product', (
    tester,
  ) async {
    useTallViewport(tester); // rows sit below the WTM-215 chrome
    await pumpScreen(tester);

    // "Khăn tắm cotton" is the only match and is out of stock (quantity 0).
    await tester.enterText(find.byType(TextField), 'Khăn tắm');
    await tester.pumpAndSettle();

    expect(find.text('1 product'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('In stock'), findsNothing);
  });

  testWidgets('sort chips select and the direction toggles', (tester) async {
    useTallViewport(tester); // the sort bar sits below the WTM-215 chrome
    await pumpScreen(tester);

    // Default sort is Name, ascending.
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Name'))
          .selected,
      isTrue,
    );
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Switch to Price.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Price'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Price'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Name'))
          .selected,
      isFalse,
    );

    // Toggle to descending.
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('changing sort resets to the first page', (tester) async {
    useTallViewport(tester);
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 2/2',
    );

    // Selecting a sort key should snap back to page 1.
    final quantityChip = find.widgetWithText(ChoiceChip, 'Quantity');
    await tester.ensureVisible(quantityChip);
    await tester.pumpAndSettle();
    await tester.tap(quantityChip);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/2',
    );
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    useTallViewport(tester); // the empty state sits below the WTM-215 chrome
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'zzzznotaproduct');
    await tester.pumpAndSettle();

    expect(find.text('No products match your search'), findsOneWidget);
    expect(find.text('0 products'), findsOneWidget);
    // The pagination bar is hidden when there are no results.
    expect(find.byTooltip('Next page'), findsNothing);
  });

  testWidgets('accepts an injected service', (tester) async {
    final service = ProductInventoryService([
      // 3 products → a single page, well under the 20-per-page bound.
      for (var i = 0; i < 3; i++)
        Product(
          id: 'inj$i',
          sku: 'SKU-INJ-$i',
          name: 'Injected $i',
          category: 'Test',
          quantity: i, // 0 → out of stock, others in stock
          pricePerUnit: 1000 * (i + 1),
          reorderLevel: 0,
          updatedAt: DateTime(2026, 1, i + 1),
        ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: TongtaiInventoryScreen(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 products'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('inventory-page-indicator')))
          .data,
      'Page 1/1',
    );
    expect(find.text('Injected 0'), findsOneWidget);
  });
}
