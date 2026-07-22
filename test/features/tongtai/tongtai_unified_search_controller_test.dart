import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/search/tongtai_search_service.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_history_store.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_models.dart';
import 'package:tongtai/features/tongtai/search/tongtai_unified_search_controller.dart';

/// Integration tests for the WTM-73 unified-search controller against a REAL
/// in-memory FTS5 database, so the query path, relevance-ranked results,
/// filtering, history recording and suggestions are all genuinely exercised.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TongtaiUnifiedSearchController controller;
  late InMemoryTongtaiSearchHistoryStore history;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    await _seed(db);
    history = InMemoryTongtaiSearchHistoryStore();
    controller = TongtaiUnifiedSearchController(
      TongtaiSearchService(db),
      history,
      debounce: Duration.zero,
    );
    await controller.init();
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('init loads persisted history', () async {
    final seeded = InMemoryTongtaiSearchHistoryStore(seed: ['pho', 'coffee']);
    final c = TongtaiUnifiedSearchController(
      TongtaiSearchService(db),
      seeded,
      debounce: Duration.zero,
    );
    await c.init();
    expect(c.recent, ['pho', 'coffee']);
    c.dispose();
  });

  test('submit runs FTS and groups suppliers + products', () async {
    await controller.submit('ca phe');

    expect(controller.hasSearched, isTrue);
    expect(
      controller.results.suppliers.map((s) => s.id),
      contains('sup-cafe'),
    );
    expect(
      controller.results.products.map((p) => p.id),
      contains('p-robusta'),
    );
    // Collections spans both entity types.
    final r = controller.results;
    expect(r.countFor(TongtaiSearchTab.collections),
        r.supplierCount + r.productCount);
  });

  test('submit records the query in history (quick-repeat source)', () async {
    await controller.submit('ca phe');
    await controller.submit('vietnam');
    expect(controller.recent, ['vietnam', 'ca phe']);

    // Repeating an older search bumps it back to the front and re-runs it.
    await controller.repeat('ca phe');
    expect(controller.recent, ['ca phe', 'vietnam']);
    expect(controller.query, 'ca phe');
    expect(controller.results.suppliers.map((s) => s.id), contains('sup-cafe'));
  });

  test('advanced filters refine the scope (category)', () async {
    // "vietnam" matches two suppliers in different categories.
    await controller.submit('vietnam');
    expect(
      controller.results.suppliers.map((s) => s.id),
      containsAll(['sup-cafe', 'sup-textile']),
    );

    controller.setFilters(const TongtaiSearchFilters(category: 'Dệt may'));
    expect(controller.results.suppliers.map((s) => s.id), ['sup-textile']);

    controller.clearFilters();
    expect(
      controller.results.suppliers.map((s) => s.id),
      containsAll(['sup-cafe', 'sup-textile']),
    );
  });

  test('facet options come from the unfiltered result set', () async {
    await controller.submit('vietnam');
    controller.setFilters(const TongtaiSearchFilters(category: 'Dệt may'));
    // Selecting a category must not shrink the available category options.
    expect(
      controller.availableCategories,
      containsAll(['Dệt may', 'Nông sản']),
    );
    expect(controller.availableCountries, contains('Vietnam'));
  });

  test('suggestions surface live result names for the typed text', () async {
    await controller.submit('tech');
    // History holds 'tech' but the exact query is never suggested back; the live
    // supplier name is.
    expect(controller.suggestions, contains('TechPro Wholesale'));
    expect(controller.suggestions, isNot(contains('tech')));
  });

  test('debounced live search (setQuery) runs without recording history',
      () async {
    controller.setQuery('tech');
    await _settle(() => controller.results.isNotEmpty);

    expect(controller.results.suppliers.map((s) => s.id), contains('sup-tech'));
    // Typing does not write history — only an explicit submit does.
    expect(controller.recent, isEmpty);
  });

  test('clearQuery empties the query and results', () async {
    await controller.submit('tech');
    expect(controller.results.isNotEmpty, isTrue);

    controller.clearQuery();
    expect(controller.query, isEmpty);
    expect(controller.results.isEmpty, isTrue);
    expect(controller.hasSearched, isFalse);
  });

  test('clearHistory empties recent searches', () async {
    await controller.submit('tech');
    expect(controller.recent, isNotEmpty);
    await controller.clearHistory();
    expect(controller.recent, isEmpty);
    expect(await history.load(), isEmpty);
  });

  test('a blank submit yields no results and no history', () async {
    await controller.submit('   ');
    expect(controller.results.isEmpty, isTrue);
    expect(controller.recent, isEmpty);
  });
}

/// Polls until [done] is true (or a generous timeout), letting the real async
/// FTS queries settle. In-memory SQLite resolves in well under a millisecond.
Future<void> _settle(bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

const String _ownerId = 'owner-search';
const String _businessId = 'biz-search';

Future<void> _seed(AppDatabase db) async {
  await db.into(db.usersTable).insert(
        UsersTableCompanion.insert(
          id: _ownerId,
          email: 'owner@search.test',
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

  Future<void> supplier(String id, String name, String category,
      String country, double rating) {
    return db.into(db.producersTable).insert(
          ProducersTableCompanion.insert(
            id: id,
            businessId: _businessId,
            name: name,
            category: Value(category),
            country: Value(country),
            rating: Value(rating),
          ),
        );
  }

  Future<void> product(String id, String name, String category, String desc) {
    return db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(
            id: id,
            businessId: _businessId,
            sku: 'SKU-$id',
            name: name,
            listPrice: 100000,
            category: Value(category),
            description: Value(desc),
          ),
        );
  }

  await supplier('sup-cafe', 'Cà Phê Đắk Lắk', 'Nông sản', 'Vietnam', 4.8);
  await supplier('sup-tech', 'TechPro Wholesale', 'Điện tử', 'China', 4.2);
  await supplier('sup-textile', 'Saigon Textile', 'Dệt may', 'Vietnam', 4.5);
  await product('p-robusta', 'Cà phê Robusta', 'Nông sản', 'Cà phê nguyên chất');
  await product('p-fan', 'Quạt mini cầm tay', 'Điện tử', 'Quạt sạc USB');
}
