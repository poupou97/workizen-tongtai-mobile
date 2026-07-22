import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/producer/supplier.dart';
import 'package:tongtai/features/tongtai/producer/supplier_search_service.dart';

/// Real unit tests for the WTM-63 supplier search logic: free-text query, the
/// three filter facets (category, rating, location), typeahead suggestions,
/// deterministic ranking, and the <500ms search-latency acceptance criterion.
void main() {
  final service = SupplierSearchService.sample();

  group('Supplier model', () {
    test('country is the segment after the last comma', () {
      const s = Supplier(
        id: 'x',
        name: 'X',
        location: 'Ho Chi Minh City, Vietnam',
        rating: 4.0,
        reviewCount: 1,
        categories: ['Textiles'],
        minOrderUnits: 10,
        leadTime: '5 days',
      );
      expect(s.country, 'Vietnam');
    });

    test('country falls back to whole string when no comma', () {
      const s = Supplier(
        id: 'y',
        name: 'Y',
        location: 'Singapore',
        rating: 4.0,
        reviewCount: 1,
        categories: [],
        minOrderUnits: 10,
        leadTime: '5 days',
      );
      expect(s.country, 'Singapore');
    });

    test('equality is by id', () {
      const a = Supplier(
        id: 'same',
        name: 'A',
        location: 'L, C',
        rating: 4.0,
        reviewCount: 1,
        categories: [],
        minOrderUnits: 1,
        leadTime: '1 day',
      );
      const b = Supplier(
        id: 'same',
        name: 'B',
        location: 'M, D',
        rating: 3.0,
        reviewCount: 2,
        categories: [],
        minOrderUnits: 2,
        leadTime: '2 days',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('facets exposed for the filter UI', () {
    test('categories are distinct and sorted', () {
      final categories = service.categories;
      expect(categories, contains('Electronics'));
      expect(categories, contains('Textiles'));
      // Distinct (no duplicates) ...
      expect(categories.toSet().length, categories.length);
      // ... and sorted.
      final sorted = [...categories]..sort();
      expect(categories, sorted);
    });

    test('countries are distinct, sorted, and derived from locations', () {
      final countries = service.countries;
      expect(countries, contains('Vietnam'));
      expect(countries, contains('China'));
      expect(countries.toSet().length, countries.length);
      final sorted = [...countries]..sort();
      expect(countries, sorted);
    });
  });

  group('search — free text query', () {
    test('empty filter returns the whole directory', () {
      final results = service.search(const SupplierSearchFilter());
      expect(results.length, service.all.length);
    });

    test('matches supplier name case-insensitively', () {
      final results =
          service.search(const SupplierSearchFilter(query: 'techpro'));
      expect(results, isNotEmpty);
      expect(results.every((s) => s.name.toLowerCase().contains('techpro')),
          isTrue);
    });

    test('matches on location text', () {
      final results =
          service.search(const SupplierSearchFilter(query: 'vietnam'));
      expect(results, isNotEmpty);
      expect(
        results.every((s) => s.location.toLowerCase().contains('vietnam')),
        isTrue,
      );
    });

    test('matches on category text', () {
      final results =
          service.search(const SupplierSearchFilter(query: 'coconut'));
      expect(results, isNotEmpty);
      expect(
        results.every((s) => s.categories
            .any((c) => c.toLowerCase().contains('coconut'))),
        isTrue,
      );
    });

    test('a query with no matches returns an empty list', () {
      final results = service.search(
        const SupplierSearchFilter(query: 'zzzznotasupplier'),
      );
      expect(results, isEmpty);
    });
  });

  group('search — facet filters', () {
    test('category filter keeps only suppliers in that category', () {
      final results = service.search(
        const SupplierSearchFilter(category: 'Electronics'),
      );
      expect(results, isNotEmpty);
      expect(results.every((s) => s.categories.contains('Electronics')), isTrue);
    });

    test('rating filter keeps only suppliers at or above the threshold', () {
      final results =
          service.search(const SupplierSearchFilter(minRating: 4.8));
      expect(results, isNotEmpty);
      expect(results.every((s) => s.rating >= 4.8), isTrue);
    });

    test('location filter keeps only suppliers in that country', () {
      final results =
          service.search(const SupplierSearchFilter(location: 'Vietnam'));
      expect(results, isNotEmpty);
      expect(results.every((s) => s.country == 'Vietnam'), isTrue);
    });

    test('facets combine (AND) with each other and the query', () {
      final results = service.search(
        const SupplierSearchFilter(
          query: 'textile',
          location: 'Vietnam',
          minRating: 4.8,
        ),
      );
      expect(results, isNotEmpty);
      for (final s in results) {
        expect(s.country, 'Vietnam');
        expect(s.rating, greaterThanOrEqualTo(4.8));
        final matchesQuery = s.name.toLowerCase().contains('textile') ||
            s.location.toLowerCase().contains('textile') ||
            s.categories.any((c) => c.toLowerCase().contains('textile'));
        expect(matchesQuery, isTrue);
      }
    });

    test('over-constrained filters yield no results', () {
      final results = service.search(
        const SupplierSearchFilter(category: 'Electronics', location: 'India'),
      );
      expect(results, isEmpty);
    });
  });

  group('search — ranking', () {
    test('results are ordered by rating desc, then reviews desc', () {
      final results = service.search(const SupplierSearchFilter());
      for (var i = 0; i + 1 < results.length; i++) {
        final a = results[i];
        final b = results[i + 1];
        expect(a.rating, greaterThanOrEqualTo(b.rating));
        if (a.rating == b.rating) {
          expect(a.reviewCount, greaterThanOrEqualTo(b.reviewCount));
        }
      }
    });
  });

  group('suggestions — real-time typeahead', () {
    test('blank query yields no suggestions', () {
      expect(service.suggestions(''), isEmpty);
      expect(service.suggestions('   '), isEmpty);
    });

    test('returns matching names/categories, de-duplicated', () {
      final suggestions = service.suggestions('elect');
      expect(suggestions, contains('Electronics'));
      // De-duplicated even though several suppliers share the category.
      expect(suggestions.toSet().length, suggestions.length);
    });

    test('prefix matches rank ahead of substring matches', () {
      // "home" is a prefix of the "Home Goods" category and a substring of
      // several supplier names ("Bangkok Home Living", "Hanoi Handicraft"...).
      final suggestions = service.suggestions('home');
      expect(suggestions.first.toLowerCase().startsWith('home'), isTrue);
    });

    test('respects the limit', () {
      final suggestions = service.suggestions('a', limit: 3);
      expect(suggestions.length, lessThanOrEqualTo(3));
    });
  });

  group('performance — AC: results within 500ms', () {
    test('search over a large directory completes well under 500ms', () {
      // Build a synthetic directory far larger than production to give the
      // latency target real teeth.
      const categories = ['Electronics', 'Apparel', 'Home Goods', 'Textiles'];
      const countries = ['Vietnam', 'China', 'Thailand', 'India'];
      final many = <Supplier>[
        for (var i = 0; i < 5000; i++)
          Supplier(
            id: 'gen$i',
            name: 'Supplier $i',
            location: 'City $i, ${countries[i % countries.length]}',
            rating: 4.0 + (i % 10) / 10,
            reviewCount: i % 500,
            categories: [categories[i % categories.length]],
            minOrderUnits: 50 + i % 500,
            leadTime: '7-14 days',
          ),
      ];
      final bigService = SupplierSearchService(many);

      final stopwatch = Stopwatch()..start();
      final results = bigService.search(
        const SupplierSearchFilter(
          query: 'Supplier',
          category: 'Electronics',
          minRating: 4.5,
          location: 'Vietnam',
        ),
      );
      stopwatch.stop();

      expect(results, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
