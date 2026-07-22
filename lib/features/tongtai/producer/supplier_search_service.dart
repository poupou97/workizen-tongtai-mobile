import 'package:flutter/foundation.dart';

import 'supplier.dart';

/// The active supplier-search query + facet filters (WTM-63).
///
/// Immutable value object so the screen can hold one in state and rebuild
/// deterministically. [query] is free text; [category], [minRating] and
/// [location] are the three filter facets from the acceptance criteria.
@immutable
class SupplierSearchFilter {
  const SupplierSearchFilter({
    this.query = '',
    this.category,
    this.minRating,
    this.location,
  });

  /// Free-text query, matched against name, location and categories.
  final String query;

  /// Category facet, e.g. "Electronics"; null means "any".
  final String? category;

  /// Minimum rating facet (inclusive), e.g. 4.5; null means "any".
  final double? minRating;

  /// Country facet, e.g. "Vietnam"; null means "any".
  final String? location;

  /// Whether any facet filter is applied (ignores free text).
  bool get hasActiveFilters =>
      category != null || minRating != null || location != null;

  /// Whether there is nothing to search by (blank query and no facets).
  bool get isEmpty => query.trim().isEmpty && !hasActiveFilters;

  /// Copy with individual overrides. Pass `clearCategory` / `clearRating` /
  /// `clearLocation` to reset a facet to null (a plain null argument can't
  /// distinguish "leave unchanged" from "clear").
  SupplierSearchFilter copyWith({
    String? query,
    String? category,
    double? minRating,
    String? location,
    bool clearCategory = false,
    bool clearRating = false,
    bool clearLocation = false,
  }) {
    return SupplierSearchFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      location: clearLocation ? null : (location ?? this.location),
    );
  }
}

/// In-memory supplier search — local-first, no backend (ADR-002).
///
/// All matching, filtering, sorting and suggestion logic is pure Dart over an
/// in-memory list, so results return synchronously and effectively instantly
/// (well under the 500ms acceptance target, even over thousands of rows). A
/// Drift/remote-backed implementation can later replace the data source without
/// touching callers.
class SupplierSearchService {
  SupplierSearchService(List<Supplier> suppliers)
      : _suppliers = List.unmodifiable(suppliers);

  /// Convenience constructor seeded with the built-in sample directory.
  factory SupplierSearchService.sample() =>
      SupplierSearchService(kSampleSuppliers);

  final List<Supplier> _suppliers;

  /// The full, unfiltered directory.
  List<Supplier> get all => _suppliers;

  /// Distinct categories across the directory, alphabetically sorted.
  List<String> get categories {
    final set = <String>{for (final s in _suppliers) ...s.categories};
    final list = set.toList()..sort();
    return list;
  }

  /// Distinct supplier countries, alphabetically sorted.
  List<String> get countries {
    final set = <String>{for (final s in _suppliers) s.country};
    final list = set.toList()..sort();
    return list;
  }

  /// Applies [filter] and returns matching suppliers, best first.
  ///
  /// Sort order is deterministic: rating desc, then review count desc, then
  /// name asc — so equal-rated suppliers surface the most-reviewed one first.
  List<Supplier> search(SupplierSearchFilter filter) {
    final q = filter.query.trim().toLowerCase();
    final results = <Supplier>[
      for (final s in _suppliers)
        if (_matches(s, q, filter)) s,
    ];
    results.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      final byReviews = b.reviewCount.compareTo(a.reviewCount);
      if (byReviews != 0) return byReviews;
      return a.name.compareTo(b.name);
    });
    return results;
  }

  bool _matches(Supplier s, String q, SupplierSearchFilter filter) {
    if (q.isNotEmpty && !_matchesQuery(s, q)) return false;
    if (filter.category != null && !s.categories.contains(filter.category)) {
      return false;
    }
    if (filter.minRating != null && s.rating < filter.minRating!) return false;
    if (filter.location != null && s.country != filter.location) return false;
    return true;
  }

  bool _matchesQuery(Supplier s, String lowerQuery) {
    if (s.name.toLowerCase().contains(lowerQuery)) return true;
    if (s.location.toLowerCase().contains(lowerQuery)) return true;
    for (final c in s.categories) {
      if (c.toLowerCase().contains(lowerQuery)) return true;
    }
    return false;
  }

  /// Real-time typeahead suggestions for [query].
  ///
  /// Returns supplier names and category labels that match, de-duplicated,
  /// with prefix matches ranked ahead of substring matches, capped at [limit].
  /// A blank query yields no suggestions.
  List<String> suggestions(String query, {int limit = 5}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final prefixMatches = <String>[];
    final substringMatches = <String>[];
    final seen = <String>{};

    void consider(String label) {
      final key = label.toLowerCase();
      if (seen.contains(key)) return;
      if (key.startsWith(q)) {
        seen.add(key);
        prefixMatches.add(label);
      } else if (key.contains(q)) {
        seen.add(key);
        substringMatches.add(label);
      }
    }

    for (final s in _suppliers) {
      consider(s.name);
      for (final c in s.categories) {
        consider(c);
      }
    }

    return [...prefixMatches, ...substringMatches].take(limit).toList();
  }
}

/// Rating filter presets offered in the UI (WTM-63 rating facet).
const List<double> kSupplierRatingPresets = [4.0, 4.5, 4.8];

/// Sample supplier directory used until a real data source is wired in.
///
/// Mirrors the mock data in `docs/tongtai/SCREEN-PRODUCER.md`, extended to span
/// enough categories and countries that every filter facet has real options.
const List<Supplier> kSampleSuppliers = [
  Supplier(
    id: 's1',
    name: 'TechPro Wholesale',
    location: 'Shenzhen, China',
    rating: 4.8,
    reviewCount: 245,
    categories: ['Electronics', 'Accessories'],
    minOrderUnits: 100,
    leadTime: '7-14 days',
  ),
  Supplier(
    id: 's2',
    name: 'Global Trade Partners',
    location: 'Bangkok, Thailand',
    rating: 4.6,
    reviewCount: 189,
    categories: ['Apparel', 'Home Goods'],
    minOrderUnits: 50,
    leadTime: '10-21 days',
  ),
  Supplier(
    id: 's3',
    name: 'Vietnam Manufacturing Hub',
    location: 'Ho Chi Minh City, Vietnam',
    rating: 4.7,
    reviewCount: 156,
    categories: ['Textiles', 'Home Goods'],
    minOrderUnits: 200,
    leadTime: '5-10 days',
  ),
  Supplier(
    id: 's4',
    name: 'Indonesia Export Specialists',
    location: 'Jakarta, Indonesia',
    rating: 4.5,
    reviewCount: 134,
    categories: ['Agriculture', 'Coconut Products'],
    minOrderUnits: 500,
    leadTime: '14-21 days',
  ),
  Supplier(
    id: 's5',
    name: 'Saigon Textile Works',
    location: 'Ho Chi Minh City, Vietnam',
    rating: 4.9,
    reviewCount: 312,
    categories: ['Textiles', 'Apparel'],
    minOrderUnits: 150,
    leadTime: '6-12 days',
  ),
  Supplier(
    id: 's6',
    name: 'Shenzhen Smart Devices',
    location: 'Shenzhen, China',
    rating: 4.4,
    reviewCount: 98,
    categories: ['Electronics', 'Smart Home'],
    minOrderUnits: 80,
    leadTime: '7-14 days',
  ),
  Supplier(
    id: 's7',
    name: 'Bangkok Home Living',
    location: 'Bangkok, Thailand',
    rating: 4.2,
    reviewCount: 76,
    categories: ['Home Goods', 'Furniture'],
    minOrderUnits: 40,
    leadTime: '12-20 days',
  ),
  Supplier(
    id: 's8',
    name: 'Hanoi Handicraft Collective',
    location: 'Hanoi, Vietnam',
    rating: 4.6,
    reviewCount: 143,
    categories: ['Home Goods', 'Furniture'],
    minOrderUnits: 60,
    leadTime: '8-16 days',
  ),
  Supplier(
    id: 's9',
    name: 'Mumbai Apparel Exports',
    location: 'Mumbai, India',
    rating: 4.3,
    reviewCount: 210,
    categories: ['Apparel', 'Textiles'],
    minOrderUnits: 300,
    leadTime: '15-25 days',
  ),
  Supplier(
    id: 's10',
    name: 'Guangzhou Beauty Supply',
    location: 'Guangzhou, China',
    rating: 4.7,
    reviewCount: 187,
    categories: ['Cosmetics', 'Accessories'],
    minOrderUnits: 120,
    leadTime: '9-18 days',
  ),
  Supplier(
    id: 's11',
    name: 'Penang Electronics Trading',
    location: 'Penang, Malaysia',
    rating: 4.1,
    reviewCount: 64,
    categories: ['Electronics', 'Smart Home'],
    minOrderUnits: 90,
    leadTime: '10-18 days',
  ),
  Supplier(
    id: 's12',
    name: 'Da Nang Coconut Traders',
    location: 'Da Nang, Vietnam',
    rating: 4.8,
    reviewCount: 121,
    categories: ['Coconut Products', 'Agriculture'],
    minOrderUnits: 400,
    leadTime: '11-19 days',
  ),
];
