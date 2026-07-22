import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';

/// Real widget tests for the WTM-75 Customer list screen: the screen is built
/// and pumped and every acceptance criterion is exercised through the UI — the
/// customer rows (name / masked phone / location / order count / spend / last
/// purchase), VIP/high-value tier badges, the four sort controls, search +
/// location filtering, and 20-per-page pagination.
///
/// Each customer row shows a "₫" total-spent figure, so `find.textContaining('₫')`
/// counts the visible rows. A tall test viewport keeps the whole page laid out
/// (not lazily culled) so those counts are exact.
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TongtaiCustomerListScreen()),
    );
    await tester.pumpAndSettle();
  }

  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 3600);
  }

  testWidgets('renders header, search, filters and the results count',
      (tester) async {
    useTallViewport(tester);
    await pumpScreen(tester);

    expect(find.text('Customers'), findsOneWidget); // AppBar
    expect(find.byType(TextField), findsOneWidget); // search input
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);

    // The whole sample directory (26 customers) is counted, across two pages.
    expect(find.text('26 customers'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('a customer row shows name, phone, purchases and last purchase',
      (tester) async {
    await pumpScreen(tester);

    // Isolate a single customer by their full phone so the assertion doesn't
    // depend on which default-sorted page they land on.
    await tester.enterText(find.byType(TextField), '+84912345678');
    await tester.pumpAndSettle();

    expect(find.text('1 customer'), findsOneWidget);
    expect(find.text('Phương Nguyễn'), findsOneWidget); // name
    // Phone is masked in the list, alongside the location.
    expect(find.text('+84912***678 • Hà Nội'), findsOneWidget);
    expect(find.text('24 orders'), findsOneWidget); // purchase frequency
    expect(find.text('Last purchase 2026-07-10'), findsOneWidget); // recency
    expect(find.textContaining('₫'), findsOneWidget); // total spent
  });

  testWidgets('paginates 26 customers into two pages of 20', (tester) async {
    useTallViewport(tester);
    await pumpScreen(tester);

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.textContaining('₫'), findsNWidgets(20)); // 20 rows on page 1

    // Advance to page 2.
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.textContaining('₫'), findsNWidgets(6)); // remaining 6 rows

    // ...and back.
    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('search narrows the results by name', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'phương');
    await tester.pumpAndSettle();

    expect(find.text('1 customer'), findsOneWidget);
    expect(find.text('Phương Nguyễn'), findsOneWidget);
    expect(find.text('Page 1 of 1'), findsOneWidget);
  });

  testWidgets('location filter narrows the results', (tester) async {
    await pumpScreen(tester);

    final chip = find.widgetWithText(ChoiceChip, 'Hà Nội');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // Six sample customers are in Hà Nội.
    expect(find.text('6 customers'), findsOneWidget);
    expect(find.text('Page 1 of 1'), findsOneWidget);
  });

  testWidgets('shows a VIP tier badge for a high-value customer',
      (tester) async {
    await pumpScreen(tester);

    // "Phương Nguyễn" is the only match and is a VIP (45.6M ₫ lifetime spend).
    await tester.enterText(find.byType(TextField), '+84912345678');
    await tester.pumpAndSettle();

    expect(find.text('1 customer'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('Bronze'), findsNothing);
    // High-value tiers carry a star indicator.
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('sort chips select and the direction toggles', (tester) async {
    await pumpScreen(tester);

    // Default sort is Name, ascending.
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Name')).selected,
      isTrue,
    );
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Switch to Spent (purchase volume).
    await tester.tap(find.widgetWithText(ChoiceChip, 'Spent'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Spent')).selected,
      isTrue,
    );
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Name')).selected,
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
    expect(find.text('Page 2 of 2'), findsOneWidget);

    // Selecting a sort key should snap back to page 1.
    final frequencyChip = find.widgetWithText(ChoiceChip, 'Frequency');
    await tester.ensureVisible(frequencyChip);
    await tester.pumpAndSettle();
    await tester.tap(frequencyChip);
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'zzzznotacustomer');
    await tester.pumpAndSettle();

    expect(find.text('No customers match your search'), findsOneWidget);
    expect(find.text('0 customers'), findsOneWidget);
    // The pagination bar is hidden when there are no results.
    expect(find.byTooltip('Next page'), findsNothing);
  });

  testWidgets('accepts an injected service', (tester) async {
    final service = CustomerDirectoryService([
      // 3 customers → a single page, well under the 20-per-page bound.
      Customer(
        id: 'inj1',
        name: 'Injected One',
        phone: '+84900000001',
        location: 'Test City',
        orderCount: 20,
        totalSpent: 40000000, // VIP
        lastPurchaseDate: DateTime(2026, 1, 1),
      ),
      Customer(
        id: 'inj2',
        name: 'Injected Two',
        phone: '+84900000002',
        location: 'Test City',
        orderCount: 4,
        totalSpent: 5000000, // Silver
        lastPurchaseDate: DateTime(2026, 1, 2),
      ),
      Customer(
        id: 'inj3',
        name: 'Injected Three',
        phone: '+84900000003',
        location: 'Test City',
        orderCount: 1,
        totalSpent: 500000, // Bronze
        lastPurchaseDate: DateTime(2026, 1, 3),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: TongtaiCustomerListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 customers'), findsOneWidget);
    expect(find.text('Page 1 of 1'), findsOneWidget);
    expect(find.text('Injected One'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
  });
}
