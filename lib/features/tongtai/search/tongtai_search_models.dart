/// Value models + pure helpers for the Tổng Tài Unified Search screen (WTM-73).
///
/// This file is the UI-agnostic core of unified search: it maps the FTS5 base
/// rows ([ProducersTableData] / [ProductsTableData], see
/// `tongtai_search_service.dart`) into lightweight, immutable view models, and
/// provides the pure functions the screen and controller rely on — advanced
/// filtering, autocomplete-suggestion building, and facet-option extraction.
///
/// Keeping this logic pure (no Flutter, no Drift beyond the `fromRow` mappers)
/// means the ranking-preserving filter, the suggestion ordering and the tab
/// counts are all directly unit-testable without a widget or a database.
library;

import 'package:flutter/foundation.dart';

import '../../../database/database.dart';

/// The three result groupings shown as tabs on the unified search screen
/// (WTM-73 AC: "Results organized in tabs: Suppliers | Products | Collections").
///
/// [collections] is the aggregated cross-entity view — the whole *collection* of
/// matches across the catalogue, grouped by type (the backlog's "searches across
/// all entity types. Grouped results.").
enum TongtaiSearchTab {
  suppliers,
  products,
  collections;

  /// English tab label.
  String get labelEn => switch (this) {
        TongtaiSearchTab.suppliers => 'Suppliers',
        TongtaiSearchTab.products => 'Products',
        TongtaiSearchTab.collections => 'Collections',
      };

  /// Vietnamese tab label (this is a Vietnamese-first product).
  String get labelVi => switch (this) {
        TongtaiSearchTab.suppliers => 'Nhà cung cấp',
        TongtaiSearchTab.products => 'Sản phẩm',
        TongtaiSearchTab.collections => 'Tổng hợp',
      };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) =>
      languageCode == 'vi' ? labelVi : labelEn;
}

/// A supplier row projected for the search UI.
///
/// Decoupled from Drift so the filter/suggestion helpers and the widgets can be
/// tested by constructing these directly; [fromRow] does the one-way mapping
/// from the FTS-joined base row.
@immutable
class TongtaiSupplierResult {
  const TongtaiSupplierResult({
    required this.id,
    required this.name,
    this.category,
    this.country,
    this.rating,
    this.reviewCount,
    this.updatedAt,
    this.createdAt,
  });

  factory TongtaiSupplierResult.fromRow(ProducersTableData row) =>
      TongtaiSupplierResult(
        id: row.id,
        name: row.name,
        category: row.category,
        country: row.country,
        rating: row.rating,
        // No review-count column yet; the WTM-74 ranker treats null as "review
        // volume unknown" and trusts the rating as-is — populated later when a
        // reviews feature lands.
        reviewCount: null,
        updatedAt: row.updatedAt,
        createdAt: row.createdAt,
      );

  final String id;
  final String name;
  final String? category;
  final String? country;

  /// Supplier rating 0–5 (WTM-74 AC2 ranking signal); null when unrated.
  final double? rating;

  /// Number of reviews behind [rating], used to weight rating confidence
  /// (WTM-74 AC2). Null means "unknown volume".
  final int? reviewCount;

  /// When the supplier row was last added/updated — the WTM-74 recency signal.
  final DateTime? updatedAt;

  /// When the supplier was first added.
  final DateTime? createdAt;
}

/// A product row projected for the search UI.
@immutable
class TongtaiProductResult {
  const TongtaiProductResult({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.price,
    required this.stock,
    this.rating,
    this.reviewCount,
    this.updatedAt,
    this.createdAt,
  });

  factory TongtaiProductResult.fromRow(ProductsTableData row) =>
      TongtaiProductResult(
        id: row.id,
        name: row.name,
        description: row.description,
        category: row.category,
        // Prefer the live selling price when set, else the list price.
        price: row.currentPrice ?? row.listPrice,
        stock: row.totalStock,
        // Products carry no rating/reviews column; the WTM-74 ranker scores a
        // null rating as neutral, so products rank on text/recency/personalization.
        rating: null,
        reviewCount: null,
        updatedAt: row.updatedAt,
        createdAt: row.createdAt,
      );

  final String id;
  final String name;
  final String? description;
  final String? category;
  final double price;
  final double stock;

  /// Product rating 0–5 (WTM-74 AC2 ranking signal); null when unrated (today
  /// products are unrated, so this is null).
  final double? rating;

  /// Number of reviews behind [rating] (WTM-74 AC2); null means unknown.
  final int? reviewCount;

  /// When the product row was last added/updated — the WTM-74 recency signal.
  final DateTime? updatedAt;

  /// When the product was first added.
  final DateTime? createdAt;
}

/// The full, ranked result set of a single query, grouped by entity type.
///
/// The two lists preserve the FTS5 `bm25` relevance order handed back by
/// [TongtaiSearchService] (best first). Filtering only *removes* rows, never
/// reorders them, so relevance ranking (WTM-73 AC5) is preserved end-to-end.
@immutable
class TongtaiSearchResults {
  const TongtaiSearchResults({
    this.suppliers = const [],
    this.products = const [],
  });

  static const TongtaiSearchResults empty = TongtaiSearchResults();

  final List<TongtaiSupplierResult> suppliers;
  final List<TongtaiProductResult> products;

  int get supplierCount => suppliers.length;
  int get productCount => products.length;
  int get totalCount => suppliers.length + products.length;
  bool get isEmpty => suppliers.isEmpty && products.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// The number of results shown under [tab] (Collections spans both types).
  int countFor(TongtaiSearchTab tab) => switch (tab) {
        TongtaiSearchTab.suppliers => supplierCount,
        TongtaiSearchTab.products => productCount,
        TongtaiSearchTab.collections => totalCount,
      };
}

/// The advanced-filter facets that refine the search scope (WTM-73 AC4).
///
/// [category] narrows both suppliers and products; [country] and [minRating]
/// are supplier-only facets (products carry neither), so setting them refines
/// the supplier list without discarding product matches.
@immutable
class TongtaiSearchFilters {
  const TongtaiSearchFilters({this.category, this.country, this.minRating});

  static const TongtaiSearchFilters none = TongtaiSearchFilters();

  /// Category facet (case-insensitive exact match); null means "any".
  final String? category;

  /// Supplier country facet; null means "any".
  final String? country;

  /// Minimum supplier rating (inclusive); null means "any".
  final double? minRating;

  /// Whether any facet is active.
  bool get hasAny => category != null || country != null || minRating != null;

  /// The number of active facets — handy for a badge on the filter toggle.
  int get activeCount =>
      (category != null ? 1 : 0) +
      (country != null ? 1 : 0) +
      (minRating != null ? 1 : 0);

  /// Copy with individual overrides. Pass a `clear*` flag to reset a facet to
  /// null (a plain null argument can't distinguish "leave" from "clear").
  TongtaiSearchFilters copyWith({
    String? category,
    String? country,
    double? minRating,
    bool clearCategory = false,
    bool clearCountry = false,
    bool clearRating = false,
  }) {
    return TongtaiSearchFilters(
      category: clearCategory ? null : (category ?? this.category),
      country: clearCountry ? null : (country ?? this.country),
      minRating: clearRating ? null : (minRating ?? this.minRating),
    );
  }
}

/// Applies [filters] to [results], preserving the FTS relevance order.
///
/// A no-op when no facet is set. Category narrows both entity types; country and
/// rating narrow suppliers only.
TongtaiSearchResults applyTongtaiSearchFilters(
  TongtaiSearchResults results,
  TongtaiSearchFilters filters,
) {
  if (!filters.hasAny) return results;

  final category = filters.category?.toLowerCase();
  final country = filters.country?.toLowerCase();
  final minRating = filters.minRating;

  bool supplierPasses(TongtaiSupplierResult s) {
    if (category != null && s.category?.toLowerCase() != category) return false;
    if (country != null && s.country?.toLowerCase() != country) return false;
    if (minRating != null && (s.rating ?? 0) < minRating) return false;
    return true;
  }

  bool productPasses(TongtaiProductResult p) {
    // Only the category facet applies to products.
    if (category != null && p.category?.toLowerCase() != category) return false;
    return true;
  }

  return TongtaiSearchResults(
    suppliers: results.suppliers.where(supplierPasses).toList(),
    products: results.products.where(productPasses).toList(),
  );
}

/// The distinct, sorted category facet options present in [results].
///
/// Drawn from both suppliers and products so the filter offers every category a
/// query actually returned.
List<String> tongtaiResultCategories(TongtaiSearchResults results) {
  final set = <String>{};
  for (final s in results.suppliers) {
    final c = s.category;
    if (c != null && c.isNotEmpty) set.add(c);
  }
  for (final p in results.products) {
    final c = p.category;
    if (c != null && c.isNotEmpty) set.add(c);
  }
  final list = set.toList()..sort();
  return list;
}

/// The distinct, sorted supplier-country facet options present in [results].
List<String> tongtaiResultCountries(TongtaiSearchResults results) {
  final set = <String>{};
  for (final s in results.suppliers) {
    final c = s.country;
    if (c != null && c.isNotEmpty) set.add(c);
  }
  final list = set.toList()..sort();
  return list;
}

/// Builds up to [max] autocomplete suggestions for [query] (WTM-73 AC1).
///
/// Order: the user's own recent searches that relate to what they've typed
/// come first (fastest path to repeat a prior search), then live entity names
/// from the current result set (suppliers before products). Everything is
/// case-insensitively de-duplicated, the exact current query is never suggested,
/// and only candidates containing the typed text are kept. Returns an empty list
/// for a blank query (nothing to complete).
List<String> buildTongtaiSearchSuggestions({
  required String query,
  required List<String> history,
  required TongtaiSearchResults results,
  int max = 6,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];

  final out = <String>[];
  final seen = <String>{};

  void consider(Iterable<String> candidates) {
    for (final raw in candidates) {
      if (out.length >= max) return;
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (key == needle) continue; // don't suggest exactly what's typed
      if (!key.contains(needle)) continue; // must relate to the query
      if (seen.add(key)) out.add(value);
    }
  }

  consider(history);
  consider(results.suppliers.map((s) => s.name));
  consider(results.products.map((p) => p.name));
  return out;
}
