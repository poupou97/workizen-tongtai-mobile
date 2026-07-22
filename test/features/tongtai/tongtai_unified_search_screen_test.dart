import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/search/tongtai_search_service.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_history_store.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_unified_search_screen.dart';

/// Widget tests for the WTM-73 Unified Search screen, driven against a real
/// in-memory FTS5 database so the on-screen results are genuinely produced by
/// the search index. Covers: typing → grouped tab results, quick-repeat from
/// history, advanced-filter refinement, the empty state and autocomplete
/// suggestions.
void main() {
  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 2400);
  }

  Future<TongtaiSearchService> buildSeededService(WidgetTester tester) async {
    final db = AppDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    await _seed(db);
    return TongtaiSearchService(db);
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required TongtaiSearchService service,
    List<String>? history,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiUnifiedSearchScreen(
          searchService: service,
          historyStore: InMemoryTongtaiSearchHistoryStore(seed: history),
          debounce: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets('typing a query shows grouped results across the three tabs',
      (tester) async {
    useTallViewport(tester);
    final service = await buildSeededService(tester);
    await pumpScreen(tester, service: service);

    await search(tester, 'ca phe');

    // Tab labels carry live counts.
    expect(find.text('Suppliers (1)'), findsOneWidget);
    expect(find.text('Products (1)'), findsOneWidget);
    expect(find.text('Collections (2)'), findsOneWidget);

    // Suppliers tab is active first.
    expect(find.text('Cà Phê Đắk Lắk'), findsOneWidget);

    // Products tab shows the product hit.
    await tester.tap(find.text('Products (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Cà phê Robusta'), findsOneWidget);

    // Collections tab groups both entity types under section headers.
    await tester.tap(find.text('Collections (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Suppliers (1)'), findsWidgets); // section header + tab
    expect(find.text('Cà Phê Đắk Lắk'), findsOneWidget);
    expect(find.text('Cà phê Robusta'), findsOneWidget);
  });

  testWidgets('recent searches offer one-tap quick-repeat', (tester) async {
    useTallViewport(tester);
    final service = await buildSeededService(tester);
    await pumpScreen(tester, service: service, history: ['tech']);

    // Idle view lists the recent query as a chip.
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'tech'), findsOneWidget);

    // Tapping it re-runs the search.
    await tester.tap(find.widgetWithText(ActionChip, 'tech'));
    await tester.pumpAndSettle();
    expect(find.text('TechPro Wholesale'), findsOneWidget);
  });

  testWidgets('advanced filters refine the result scope', (tester) async {
    useTallViewport(tester);
    final service = await buildSeededService(tester);
    await pumpScreen(tester, service: service);

    await search(tester, 'vietnam');
    // Two Vietnamese suppliers before filtering.
    expect(find.text('Cà Phê Đắk Lắk'), findsOneWidget);
    expect(find.text('Saigon Textile'), findsOneWidget);

    // Open the advanced-filter panel and narrow to one category.
    await tester.tap(find.byTooltip('Advanced filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dệt may'));
    await tester.pumpAndSettle();

    expect(find.text('Saigon Textile'), findsOneWidget);
    expect(find.text('Cà Phê Đắk Lắk'), findsNothing);
  });

  testWidgets('an unmatched query shows the empty state', (tester) async {
    useTallViewport(tester);
    final service = await buildSeededService(tester);
    await pumpScreen(tester, service: service);

    await search(tester, 'zzznomatch');
    expect(find.text('Suppliers (0)'), findsOneWidget);
    expect(find.text('No results'), findsWidgets);
  });

  testWidgets('autocomplete suggestions appear while typing', (tester) async {
    useTallViewport(tester);
    final service = await buildSeededService(tester);
    await pumpScreen(tester, service: service, history: ['technology']);

    // Type without submitting — the field keeps focus so suggestions show.
    await tester.enterText(find.byType(TextField), 'tech');
    await tester.pumpAndSettle();

    // The suggestions list uses a north-west "insert" icon per row.
    expect(find.byIcon(Icons.north_west), findsWidgets);
    // The recent-search 'technology' is offered as a completion.
    expect(find.text('technology'), findsOneWidget);

    // Selecting it dismisses the suggestions.
    await tester.tap(find.text('technology'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.north_west), findsNothing);
  });
}

const String _ownerId = 'owner-screen';
const String _businessId = 'biz-screen';

Future<void> _seed(AppDatabase db) async {
  await db.into(db.usersTable).insert(
        UsersTableCompanion.insert(
          id: _ownerId,
          email: 'owner@screen.test',
          name: 'Chủ tiệm',
        ),
      );
  await db.into(db.businessesTable).insert(
        BusinessesTableCompanion.insert(
          id: _businessId,
          ownerId: _ownerId,
          name: 'Cửa hàng',
          country: const Value('VN'),
        ),
      );

  Future<void> supplier(
      String id, String name, String category, String country) {
    return db.into(db.producersTable).insert(
          ProducersTableCompanion.insert(
            id: id,
            businessId: _businessId,
            name: name,
            category: Value(category),
            country: Value(country),
            rating: const Value(4.5),
          ),
        );
  }

  Future<void> product(String id, String name, String category) {
    return db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(
            id: id,
            businessId: _businessId,
            sku: 'SKU-$id',
            name: name,
            listPrice: 100000,
            category: Value(category),
          ),
        );
  }

  await supplier('sup-cafe', 'Cà Phê Đắk Lắk', 'Nông sản', 'Vietnam');
  await supplier('sup-tech', 'TechPro Wholesale', 'Điện tử', 'China');
  await supplier('sup-textile', 'Saigon Textile', 'Dệt may', 'Vietnam');
  await product('p-robusta', 'Cà phê Robusta', 'Nông sản');
  await product('p-fan', 'Quạt mini cầm tay', 'Điện tử');
}
