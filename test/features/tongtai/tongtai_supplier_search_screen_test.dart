import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_search_screen.dart';

/// Real widget tests for the WTM-63 Supplier Search screen: the screen is built
/// and pumped, and every acceptance criterion is exercised through the UI —
/// text input, the three filter facets, real-time suggestions, the empty state,
/// and the portrait/landscape responsive reflow.
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TongtaiSupplierSearchScreen()),
    );
    await tester.pumpAndSettle();
  }

  group('supplierResultColumns (responsive helper)', () {
    test('portrait phone width → single column', () {
      expect(supplierResultColumns(390), 1);
    });

    test('landscape phone / small tablet width → two columns', () {
      expect(supplierResultColumns(720), 2);
    });

    test('large tablet width → three columns', () {
      expect(supplierResultColumns(1024), 3);
    });
  });

  testWidgets('renders search field, filters and results', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Supplier Search'), findsOneWidget); // AppBar
    expect(find.byType(TextField), findsOneWidget); // search input

    // Filter facet labels are present (AC: category, rating, location).
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);

    // The whole sample directory (12 suppliers) is shown by default.
    expect(find.text('12 suppliers'), findsOneWidget);
    expect(find.text('TechPro Wholesale'), findsWidgets); // a result card
  });

  testWidgets('accepts a text query and filters the results', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'techpro');
    await tester.pumpAndSettle();

    // Only TechPro Wholesale matches → header reflects the count.
    expect(find.text('1 supplier'), findsOneWidget);
  });

  testWidgets('shows real-time suggestions and applies one on tap',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'tech');
    await tester.pumpAndSettle();

    // A suggestion tile appears as the user types.
    final suggestionTile =
        find.widgetWithText(ListTile, 'TechPro Wholesale');
    expect(suggestionTile, findsOneWidget);

    await tester.tap(suggestionTile);
    await tester.pumpAndSettle();

    // Applying the suggestion fills the query, hides the list and filters down.
    expect(find.widgetWithText(ListTile, 'TechPro Wholesale'), findsNothing);
    expect(find.text('1 supplier'), findsOneWidget);
  });

  testWidgets('category filter narrows the results', (tester) async {
    await pumpScreen(tester);

    // Tap the Electronics *chip* (not a supplier-card category tag). It lives in
    // a horizontal scroll row, so reveal it first.
    final chip = find.widgetWithText(ChoiceChip, 'Electronics');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // 3 sample suppliers serve Electronics.
    expect(find.text('3 suppliers'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('rating filter narrows the results', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, '4.8★+'));
    await tester.pumpAndSettle();

    // Three sample suppliers are rated >= 4.8 (4.8, 4.9, 4.8).
    expect(find.text('3 suppliers'), findsOneWidget);
  });

  testWidgets('location filter narrows the results', (tester) async {
    await pumpScreen(tester);

    final chip = find.widgetWithText(ChoiceChip, 'Vietnam');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // Four sample suppliers are located in Vietnam.
    expect(find.text('4 suppliers'), findsOneWidget);
  });

  testWidgets('clear filters resets the facets', (tester) async {
    await pumpScreen(tester);

    final chip = find.widgetWithText(ChoiceChip, 'Electronics');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('3 suppliers'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('12 suppliers'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'zzzznotasupplier');
    await tester.pumpAndSettle();

    expect(find.text('No suppliers match your search'), findsOneWidget);
    expect(find.text('0 suppliers'), findsOneWidget);
  });

  testWidgets('results grid reflows: single column in portrait', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 900); // portrait phone

    await pumpScreen(tester);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 1);
  });

  testWidgets('results grid reflows: two columns in landscape',
      (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(844, 390); // landscape phone

    await pumpScreen(tester);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });
}
