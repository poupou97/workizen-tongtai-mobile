/// State + orchestration for the Tổng Tài Unified Search screen (WTM-73).
///
/// A [ChangeNotifier] that ties together the FTS5 search service, the recent-
/// search history store and the pure filter/suggestion helpers. It owns the
/// query text, the running FTS results, the debounced live-search, the recent
/// history, and derives the filtered results + autocomplete suggestions on
/// demand. The screen listens to it and stays a thin render layer.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../database/search/tongtai_search_service.dart';
import '../producer/supplier_favorites_store.dart';
import 'tongtai_ranking.dart';
import 'tongtai_search_history_store.dart';
import 'tongtai_search_models.dart';
import '../core/screen_state.dart';

class TongtaiUnifiedSearchController extends ChangeNotifier {
  TongtaiUnifiedSearchController(
    this._searchService,
    this._historyStore, {
    Duration debounce = const Duration(milliseconds: 250),
    int resultLimit = 50,
    this._ranker = const TongtaiSearchRanker(),
    this._favoritesStore,
    this._experiment,
    this._unitIdLoader,
    DateTime Function()? clock,
  }) : _debounceDuration = debounce,
       _limit = resultLimit,
       _clock = clock ?? DateTime.now;

  final TongtaiSearchService _searchService;
  final TongtaiSearchHistoryStore _historyStore;
  final Duration _debounceDuration;
  final int _limit;

  /// Active ranking algorithm (WTM-74). Replaced by the A/B-assigned variant in
  /// [init] when an [_experiment] + [_unitIdLoader] are supplied.
  TongtaiSearchRanker _ranker;

  /// Optional favourites source for the personalization signal (WTM-74 AC4).
  final SupplierFavoritesStore? _favoritesStore;

  /// Optional A/B experiment; assigns a sticky ranking variant per user (AC5).
  final TongtaiRankingExperiment? _experiment;

  /// Loads the stable per-user id used to bucket the [_experiment].
  final Future<String> Function()? _unitIdLoader;

  /// Clock for the recency signal (injectable for deterministic tests).
  final DateTime Function() _clock;

  String _query = '';
  TongtaiSearchFilters _filters = TongtaiSearchFilters.none;
  TongtaiSearchResults _rawResults = TongtaiSearchResults.empty;
  List<String> _recent = const <String>[];
  Set<String> _favoriteSupplierIds = const <String>{};
  TongtaiRankingVariant? _activeVariant;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _disposed = false;

  Timer? _debounceTimer;

  /// Monotonic counter used to drop stale async responses: only the newest
  /// in-flight search is allowed to publish its results.
  int _searchSeq = 0;

  // ── Public state ───────────────────────────────────────────────────────────

  /// The current query text.
  String get query => _query;

  /// The active advanced filters.
  TongtaiSearchFilters get filters => _filters;

  /// Recent searches, most-recent-first (WTM-73 AC3).
  List<String> get recent => _recent;

  /// Whether an FTS query is currently in flight.
  bool get isSearching => _isSearching;

  /// Set when the last search threw; null once a search starts or succeeds.
  /// The screen renders it through the shared seam (ADR-TON-017).
  TongtaiFailure? get failure => _failure;
  TongtaiFailure? _failure;

  /// Whether at least one non-empty search has completed — lets the screen tell
  /// "nothing searched yet" apart from "searched, no matches".
  bool get hasSearched => _hasSearched;

  /// The results after applying [filters] (relevance order preserved).
  TongtaiSearchResults get results =>
      applyTongtaiSearchFilters(_rawResults, _filters);

  /// The unfiltered results — used to source the facet options so selecting a
  /// filter never removes the other options from the panel.
  TongtaiSearchResults get rawResults => _rawResults;

  /// Category facet options for the advanced-filter panel.
  List<String> get availableCategories => tongtaiResultCategories(_rawResults);

  /// Supplier-country facet options for the advanced-filter panel.
  List<String> get availableCountries => tongtaiResultCountries(_rawResults);

  /// Autocomplete suggestions for the current query (WTM-73 AC1).
  List<String> get suggestions => buildTongtaiSearchSuggestions(
    query: _query,
    history: _recent,
    results: results,
  );

  /// The A/B ranking variant this session was assigned, once [init] resolves it
  /// (WTM-74 AC5). Null until assigned / when no experiment is configured.
  TongtaiRankingVariant? get activeVariant => _activeVariant;

  // ── Lifecycle / mutations ────────────────────────────────────────────────

  /// Loads the persisted recent-search history, the user's favourites (for
  /// personalization) and — if configured — the A/B-assigned ranking variant.
  /// Call once when the screen opens.
  Future<void> init() async {
    _recent = await _historyStore.load();
    await _loadFavorites();
    await _assignVariant();
    _safeNotify();
  }

  Future<void> _loadFavorites() async {
    final store = _favoritesStore;
    if (store == null) return;
    final favorites = await store.loadAll();
    _favoriteSupplierIds = {for (final f in favorites) f.supplierId};
  }

  Future<void> _assignVariant() async {
    final experiment = _experiment;
    final loader = _unitIdLoader;
    if (experiment == null || loader == null) return;
    final unitId = await loader();
    _activeVariant = experiment.assign(unitId);
    _ranker = TongtaiSearchRanker(weights: _activeVariant!.weights);
  }

  /// Updates the query as the user types and schedules a debounced live search.
  /// Live searches do not touch history — only an explicit [submit] does.
  void setQuery(String value) {
    _query = value;
    _safeNotify(); // reflect the text + refresh suggestions immediately
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      _clearResults();
      return;
    }
    if (_debounceDuration == Duration.zero) {
      unawaited(_runSearch());
    } else {
      _debounceTimer = Timer(_debounceDuration, () => unawaited(_runSearch()));
    }
  }

  /// Runs a search immediately and records it in history (WTM-73 AC3).
  ///
  /// Used for the search action (keyboard "search"/enter) and suggestion taps.
  /// If [value] is given it becomes the new query first.
  Future<void> submit([String? value]) async {
    _debounceTimer?.cancel();
    if (value != null) _query = value;
    final trimmed = _query.trim();
    await _runSearch();
    if (trimmed.isNotEmpty) {
      _recent = await _historyStore.add(trimmed);
      _safeNotify();
    }
  }

  /// Repeats a search from a recent-history entry (quick-repeat, WTM-73 AC3).
  Future<void> repeat(String query) => submit(query);

  /// Replaces the advanced filters and re-derives the visible results.
  void setFilters(TongtaiSearchFilters filters) {
    _filters = filters;
    _safeNotify();
  }

  /// Clears all advanced filters.
  void clearFilters() => setFilters(TongtaiSearchFilters.none);

  /// Clears the query and results (the "×" in the search field).
  void clearQuery() {
    _query = '';
    _debounceTimer?.cancel();
    _clearResults();
  }

  /// Clears the persisted recent-search history.
  Future<void> clearHistory() async {
    await _historyStore.clear();
    _recent = const <String>[];
    _safeNotify();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<void> _runSearch() async {
    final q = _query.trim();
    final seq = ++_searchSeq;

    if (q.isEmpty) {
      _clearResults();
      return;
    }

    _isSearching = true;
    _failure = null;
    _safeNotify();

    final TongtaiSearchResults ftsResults;
    try {
      final suppliers = await _searchService.searchSuppliers(q, limit: _limit);
      final products = await _searchService.searchProducts(q, limit: _limit);
      ftsResults = TongtaiSearchResults(
        suppliers: suppliers.map(TongtaiSupplierResult.fromRow).toList(),
        products: products.map(TongtaiProductResult.fromRow).toList(),
      );
    } catch (error, stackTrace) {
      // WTM-148: an FTS failure used to leave `_isSearching` true forever —
      // a search box that spins for a query that will never come back. Now it
      // is a classified failure the screen can render and the user can retry.
      if (seq != _searchSeq || _disposed) return;
      _isSearching = false;
      _failure = TongtaiFailure.from(error, stackTrace);
      _safeNotify();
      return;
    }

    // A newer search (or a dispose) superseded this one — discard its results.
    if (seq != _searchSeq || _disposed) return;

    // FTS hands rows back in bm25 order; re-rank them with the WTM-74 signals
    // (text quality, rating, recency, personalization) before they are exposed.
    // Filtering downstream only removes rows, so this ranked order is preserved.
    _rawResults = _ranker.rank(
      ftsResults,
      query: q,
      now: _clock(),
      favoriteSupplierIds: _favoriteSupplierIds,
      historyTerms: _historyTermsExcluding(q),
    );
    _isSearching = false;
    _hasSearched = true;
    _safeNotify();
  }

  /// Recent searches with the active query removed, so a search does not boost
  /// its own matches via the history-personalization signal (WTM-74 AC4).
  List<String> _historyTermsExcluding(String query) {
    final active = query.trim().toLowerCase();
    return [
      for (final term in _recent)
        if (term.trim().toLowerCase() != active) term,
    ];
  }

  void _clearResults() {
    // Bump the sequence so any in-flight search won't publish over the clear.
    _searchSeq++;
    _rawResults = TongtaiSearchResults.empty;
    _isSearching = false;
    _hasSearched = false;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
