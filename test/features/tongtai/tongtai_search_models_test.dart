import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_models.dart';

/// Pure unit tests for the WTM-73 unified-search value models + helpers:
/// filter application (relevance order preserved), facet extraction, the
/// autocomplete-suggestion builder and the tab count/label logic.
void main() {
  TongtaiSupplierResult supplier(
    String id,
    String name, {
    String? category,
    String? country,
    double? rating,
  }) => TongtaiSupplierResult(
    id: id,
    name: name,
    category: category,
    country: country,
    rating: rating,
  );

  TongtaiProductResult product(
    String id,
    String name, {
    String? category,
    double price = 1000,
    double stock = 10,
  }) => TongtaiProductResult(
    id: id,
    name: name,
    category: category,
    price: price,
    stock: stock,
  );

  group('TongtaiSearchTab', () {
    test('labels resolve per language', () {
      expect(TongtaiSearchTab.suppliers.label('en'), 'Suppliers');
      expect(TongtaiSearchTab.suppliers.label('vi'), 'Nhà cung cấp');
      expect(TongtaiSearchTab.products.label('vi'), 'Sản phẩm');
      // Unknown language falls back to English.
      expect(TongtaiSearchTab.collections.label('fr'), 'Collections');
    });
  });

  group('TongtaiSearchResults counts', () {
    final results = TongtaiSearchResults(
      suppliers: [supplier('s1', 'A'), supplier('s2', 'B')],
      products: [product('p1', 'C')],
    );

    test('per-tab counts (collections spans both)', () {
      expect(results.countFor(TongtaiSearchTab.suppliers), 2);
      expect(results.countFor(TongtaiSearchTab.products), 1);
      expect(results.countFor(TongtaiSearchTab.collections), 3);
      expect(results.totalCount, 3);
      expect(results.isEmpty, isFalse);
    });

    test('empty results report empty', () {
      expect(TongtaiSearchResults.empty.isEmpty, isTrue);
      expect(
        TongtaiSearchResults.empty.countFor(TongtaiSearchTab.collections),
        0,
      );
    });
  });

  group('TongtaiSearchFilters', () {
    test('hasAny / activeCount reflect set facets', () {
      expect(TongtaiSearchFilters.none.hasAny, isFalse);
      expect(TongtaiSearchFilters.none.activeCount, 0);

      const f = TongtaiSearchFilters(category: 'Electronics', minRating: 4.0);
      expect(f.hasAny, isTrue);
      expect(f.activeCount, 2);
    });

    test('copyWith clear flags reset a facet to null', () {
      const f = TongtaiSearchFilters(
        category: 'Textiles',
        country: 'Vietnam',
        minRating: 4.5,
      );
      final cleared = f.copyWith(clearCountry: true);
      expect(cleared.country, isNull);
      expect(cleared.category, 'Textiles'); // untouched
      expect(cleared.minRating, 4.5);
    });
  });

  group('applyTongtaiSearchFilters', () {
    final results = TongtaiSearchResults(
      suppliers: [
        supplier(
          's1',
          'Alpha',
          category: 'Electronics',
          country: 'China',
          rating: 4.8,
        ),
        supplier(
          's2',
          'Beta',
          category: 'Textiles',
          country: 'Vietnam',
          rating: 4.1,
        ),
        supplier(
          's3',
          'Gamma',
          category: 'Electronics',
          country: 'Vietnam',
          rating: 3.5,
        ),
      ],
      products: [
        product('p1', 'Widget', category: 'Electronics'),
        product('p2', 'Fabric', category: 'Textiles'),
      ],
    );

    test('no filter is a pass-through (same instance)', () {
      expect(
        identical(
          applyTongtaiSearchFilters(results, TongtaiSearchFilters.none),
          results,
        ),
        isTrue,
      );
    });

    test('category narrows BOTH suppliers and products', () {
      final out = applyTongtaiSearchFilters(
        results,
        const TongtaiSearchFilters(category: 'Electronics'),
      );
      expect(out.suppliers.map((s) => s.id), ['s1', 's3']);
      expect(out.products.map((p) => p.id), ['p1']);
    });

    test('country narrows suppliers only; products untouched', () {
      final out = applyTongtaiSearchFilters(
        results,
        const TongtaiSearchFilters(country: 'Vietnam'),
      );
      expect(out.suppliers.map((s) => s.id), ['s2', 's3']);
      expect(out.products.map((p) => p.id), ['p1', 'p2']); // unaffected
    });

    test('minRating drops low-rated suppliers', () {
      final out = applyTongtaiSearchFilters(
        results,
        const TongtaiSearchFilters(minRating: 4.5),
      );
      expect(out.suppliers.map((s) => s.id), ['s1']);
    });

    test('filtering preserves the input (relevance) order', () {
      // Suppliers arrive already ranked s1,s2,s3; the Electronics filter must
      // keep them in that order (s1 before s3), never reorder.
      final out = applyTongtaiSearchFilters(
        results,
        const TongtaiSearchFilters(category: 'Electronics'),
      );
      expect(out.suppliers.map((s) => s.id), orderedEquals(['s1', 's3']));
    });

    test('case-insensitive category match', () {
      final out = applyTongtaiSearchFilters(
        results,
        const TongtaiSearchFilters(category: 'electronics'),
      );
      expect(out.suppliers.map((s) => s.id), ['s1', 's3']);
    });
  });

  group('facet options', () {
    final results = TongtaiSearchResults(
      suppliers: [
        supplier('s1', 'A', category: 'Electronics', country: 'China'),
        supplier('s2', 'B', category: 'Textiles', country: 'Vietnam'),
      ],
      products: [
        product('p1', 'C', category: 'Electronics'),
        product('p2', 'D', category: 'Food'),
      ],
    );

    test('categories are the sorted union across suppliers + products', () {
      expect(tongtaiResultCategories(results), [
        'Electronics',
        'Food',
        'Textiles',
      ]);
    });

    test('countries come from suppliers only, sorted', () {
      expect(tongtaiResultCountries(results), ['China', 'Vietnam']);
    });
  });

  group('buildTongtaiSearchSuggestions', () {
    final results = TongtaiSearchResults(
      suppliers: [supplier('s1', 'Cà phê Đắk Lắk')],
      products: [product('p1', 'Cà phê Robusta'), product('p2', 'Cà phê sữa')],
    );

    test('blank query yields no suggestions', () {
      expect(
        buildTongtaiSearchSuggestions(
          query: '   ',
          history: const ['coffee'],
          results: results,
        ),
        isEmpty,
      );
    });

    test('history matches come before live result names', () {
      final out = buildTongtaiSearchSuggestions(
        query: 'cà',
        history: const ['Cà phê ngon'],
        results: results,
      );
      expect(out.first, 'Cà phê ngon');
      expect(out, contains('Cà phê Robusta'));
    });

    test('the exact current query is not suggested back', () {
      final out = buildTongtaiSearchSuggestions(
        query: 'Cà phê Robusta',
        history: const [],
        results: results,
      );
      expect(out, isNot(contains('Cà phê Robusta')));
    });

    test('suggestions are de-duplicated and capped at max', () {
      final out = buildTongtaiSearchSuggestions(
        query: 'ca',
        history: const ['cafe', 'cafe', 'CAFE'],
        results: TongtaiSearchResults(
          products: [
            for (var i = 0; i < 20; i++) product('p$i', 'Cargo box $i'),
          ],
        ),
        max: 4,
      );
      expect(out.length, 4);
      // Only one 'cafe' survives the case-insensitive de-dup.
      expect(out.where((s) => s.toLowerCase() == 'cafe').length, 1);
    });

    test('only candidates containing the typed text are kept', () {
      final out = buildTongtaiSearchSuggestions(
        query: 'zzz',
        history: const ['coffee', 'tea'],
        results: results,
      );
      expect(out, isEmpty);
    });
  });
}
