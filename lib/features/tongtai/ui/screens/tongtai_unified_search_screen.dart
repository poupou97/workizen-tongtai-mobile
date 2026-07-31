import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../database/search/tongtai_search_service.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../producer/supplier_favorites_store.dart';
import '../../providers/tongtai_identity_provider.dart';
import '../../providers/tongtai_search_provider.dart';
import '../../search/tongtai_ranking.dart';
import '../../search/tongtai_search_history_store.dart';
import '../../search/tongtai_search_models.dart';
import '../../search/tongtai_unified_search_controller.dart';

/// Riverpod entry point for the Unified Search screen (WTM-73).
///
/// Wires the FTS5 search service + persisted history from the app providers,
/// kicks off a one-shot demo-catalogue seed (so a fresh install has something to
/// find), then hands an assembled controller to [TongtaiUnifiedSearchScreen].
/// The screen itself takes plain dependencies so it stays testable without
/// Riverpod.
class TongtaiUnifiedSearchRoute extends ConsumerStatefulWidget {
  const TongtaiUnifiedSearchRoute({super.key});

  @override
  ConsumerState<TongtaiUnifiedSearchRoute> createState() =>
      _TongtaiUnifiedSearchRouteState();
}

class _TongtaiUnifiedSearchRouteState
    extends ConsumerState<TongtaiUnifiedSearchRoute> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: seed the demo catalogue if empty. It's a handful of
    // inserts and the screen opens on an empty query, so it completes well
    // before the user types anything worth searching.
    final db = ref.read(tongtaiDatabaseProvider);
    ref.read(tongtaiCatalogSeederProvider).ensureSeeded(db);
  }

  @override
  Widget build(BuildContext context) {
    return TongtaiUnifiedSearchScreen(
      searchService: ref.read(tongtaiSearchServiceProvider),
      historyStore: ref.read(tongtaiSearchHistoryStoreProvider),
      // WTM-74: personalization source + sticky A/B ranking assignment.
      favoritesStore: ref.read(tongtaiSearchFavoritesStoreProvider),
      experiment: ref.read(tongtaiRankingExperimentProvider),
      unitIdLoader: ref.read(tongtaiIdentityServiceProvider).getOrCreateUserId,
    );
  }
}

/// Unified Search screen (WTM-73) — one input across suppliers, products and a
/// combined "Collections" view, powered by FTS5 relevance ranking.
///
/// Acceptance criteria realised here:
/// * single input with **autocomplete suggestions** (history + live names);
/// * results in **tabs** — Suppliers | Products | Collections;
/// * **recent-search history** with one-tap quick-repeat;
/// * **advanced filters** (category / country / rating) that refine the scope;
/// * **FTS5 relevance** ordering, preserved through filtering.
class TongtaiUnifiedSearchScreen extends StatefulWidget {
  const TongtaiUnifiedSearchScreen({
    super.key,
    required this.searchService,
    required this.historyStore,
    this.debounce = const Duration(milliseconds: 250),
    this.ranker = const TongtaiSearchRanker(),
    this.favoritesStore,
    this.experiment,
    this.unitIdLoader,
  });

  /// FTS5 search service (WTM-72).
  final TongtaiSearchService searchService;

  /// Recent-search history persistence.
  final TongtaiSearchHistoryStore historyStore;

  /// Live-search debounce. Tests pass [Duration.zero] for synchronous searches.
  final Duration debounce;

  /// Ranking algorithm applied to FTS results (WTM-74). Overridden by the
  /// A/B-assigned variant when [experiment] + [unitIdLoader] are supplied.
  final TongtaiSearchRanker ranker;

  /// Favourite-suppliers source for the personalization signal (WTM-74 AC4).
  final SupplierFavoritesStore? favoritesStore;

  /// A/B ranking experiment (WTM-74 AC5).
  final TongtaiRankingExperiment? experiment;

  /// Loads the stable per-user id used to bucket the [experiment].
  final Future<String> Function()? unitIdLoader;

  @override
  State<TongtaiUnifiedSearchScreen> createState() =>
      _TongtaiUnifiedSearchScreenState();
}

class _TongtaiUnifiedSearchScreenState extends State<TongtaiUnifiedSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TongtaiUnifiedSearchController _controller;
  late final TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  bool _filtersExpanded = false;

  static const List<TongtaiSearchTab> _tabs = [
    TongtaiSearchTab.suppliers,
    TongtaiSearchTab.products,
    TongtaiSearchTab.collections,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TongtaiUnifiedSearchController(
      widget.searchService,
      widget.historyStore,
      debounce: widget.debounce,
      ranker: widget.ranker,
      favoritesStore: widget.favoritesStore,
      experiment: widget.experiment,
      unitIdLoader: widget.unitIdLoader,
    );
    _tabController = TabController(length: _tabs.length, vsync: this);
    _queryFocus.addListener(() => setState(() {}));
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _queryController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  String get _lang =>
      Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

  void _onSubmit(String value) {
    _controller.submit(value);
    _queryFocus.unfocus();
  }

  void _applySuggestion(String value) {
    _queryController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _controller.submit(value);
    _queryFocus.unfocus();
  }

  void _repeatHistory(String value) {
    _queryController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _controller.repeat(value);
    _queryFocus.unfocus();
  }

  void _clearQuery() {
    _queryController.clear();
    _controller.clearQuery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.actionSearch),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => IconButton(
              key: const Key('search-action-toggle-filters'),
              tooltip: context.l10n.searchAdvancedFilters,
              onPressed: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              icon: Badge(
                isLabelVisible: _controller.filters.hasAny,
                label: Text('${_controller.filters.activeCount}'),
                child: Icon(
                  _filtersExpanded ? Icons.tune : Icons.tune_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final suggestions = _controller.suggestions;
            final showSuggestions =
                _queryFocus.hasFocus &&
                _controller.query.trim().isNotEmpty &&
                suggestions.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TongtaiDesignTokens.spacing4,
                    TongtaiDesignTokens.spacing3,
                    TongtaiDesignTokens.spacing4,
                    TongtaiDesignTokens.spacing2,
                  ),
                  child: _SearchField(
                    controller: _queryController,
                    focusNode: _queryFocus,
                    hintText: context.l10n.searchHint,
                    onChanged: _controller.setQuery,
                    onSubmitted: _onSubmit,
                    onClear: _controller.query.isEmpty ? null : _clearQuery,
                  ),
                ),
                if (showSuggestions)
                  _SuggestionsList(
                    suggestions: suggestions,
                    onSelected: _applySuggestion,
                  ),
                if (_filtersExpanded)
                  _AdvancedFilters(
                    lang: _lang,
                    filters: _controller.filters,
                    categories: _controller.availableCategories,
                    countries: _controller.availableCountries,
                    onChanged: _controller.setFilters,
                    onClear: _controller.clearFilters,
                  ),
                Expanded(
                  child: _controller.query.trim().isEmpty
                      ? _IdleView(
                          lang: _lang,
                          recent: _controller.recent,
                          onRepeat: _repeatHistory,
                          onClearHistory: _controller.clearHistory,
                        )
                      : _ResultsArea(
                          lang: _lang,
                          tabController: _tabController,
                          tabs: _tabs,
                          controller: _controller,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('search-field'),
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: context.l10n.actionClear,
                onPressed: onClear,
              ),
        filled: true,
        fillColor: TongtaiDesignTokens.lightHover,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.componentBorderRadius,
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TongtaiDesignTokens.spacing4,
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
      ),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
        boxShadow: TongtaiDesignTokens.elevation2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final suggestion in suggestions)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.north_west, size: 18),
                  title: Text(suggestion),
                  onTap: () => onSelected(suggestion),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced filters (WTM-73 AC4)
// ─────────────────────────────────────────────────────────────────────────────

/// Supplier min-rating presets offered by the advanced-filter panel.
const List<double> kTongtaiSearchRatingPresets = [4.5, 4.0, 3.5];

class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({
    required this.lang,
    required this.filters,
    required this.categories,
    required this.countries,
    required this.onChanged,
    required this.onClear,
  });

  final String lang;
  final TongtaiSearchFilters filters;
  final List<String> categories;
  final List<String> countries;
  final ValueChanged<TongtaiSearchFilters> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        0,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing2,
      ),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightHover,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.searchAdvancedFilters,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              const Spacer(),
              if (filters.hasAny)
                TextButton(
                  onPressed: onClear,
                  child: Text(l10n.searchClearFilters),
                ),
            ],
          ),
          if (categories.isNotEmpty)
            _FilterFacetRow(
              label: l10n.searchCategory,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: filters.category == category,
                    onSelected: (selected) => onChanged(
                      selected
                          ? filters.copyWith(category: category)
                          : filters.copyWith(clearCategory: true),
                    ),
                  ),
              ],
            ),
          if (countries.isNotEmpty)
            _FilterFacetRow(
              label: l10n.searchCountry,
              children: [
                for (final country in countries)
                  ChoiceChip(
                    label: Text(country),
                    selected: filters.country == country,
                    onSelected: (selected) => onChanged(
                      selected
                          ? filters.copyWith(country: country)
                          : filters.copyWith(clearCountry: true),
                    ),
                  ),
              ],
            ),
          _FilterFacetRow(
            label: l10n.searchRating,
            children: [
              for (final rating in kTongtaiSearchRatingPresets)
                ChoiceChip(
                  label: Text('${rating.toStringAsFixed(1)}★+'),
                  selected: filters.minRating == rating,
                  onSelected: (selected) => onChanged(
                    selected
                        ? filters.copyWith(minRating: rating)
                        : filters.copyWith(clearRating: true),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterFacetRow extends StatelessWidget {
  const _FilterFacetRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TongtaiDesignTokens.spacing2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final child in children)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: TongtaiDesignTokens.spacing2,
                      ),
                      child: child,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle view (no query): recent-search quick-repeat (WTM-73 AC3)
// ─────────────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.lang,
    required this.recent,
    required this.onRepeat,
    required this.onClearHistory,
  });

  final String lang;
  final List<String> recent;
  final ValueChanged<String> onRepeat;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (recent.isEmpty) {
      return _CenteredMessage(
        messageKey: const Key('search-empty-idle'),
        icon: Icons.search,
        title: l10n.searchEverythingTitle,
        subtitle: l10n.searchEverythingBody,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing2),
              Text(
                l10n.searchRecent,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                key: const Key('search-action-clear-history'),
                onPressed: onClearHistory,
                child: Text(l10n.actionClear),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            runSpacing: TongtaiDesignTokens.spacing2,
            children: [
              for (final query in recent)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(query),
                  onPressed: () => onRepeat(query),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results area: tabs + per-tab lists
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsArea extends StatelessWidget {
  const _ResultsArea({
    required this.lang,
    required this.tabController,
    required this.tabs,
    required this.controller,
  });

  final String lang;
  final TabController tabController;
  final List<TongtaiSearchTab> tabs;
  final TongtaiUnifiedSearchController controller;

  @override
  Widget build(BuildContext context) {
    final results = controller.results;
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelColor: TongtaiDesignTokens.lightTextPrimary,
          unselectedLabelColor: TongtaiDesignTokens.lightTextSecondary,
          indicatorColor: TongtaiDesignTokens.producerGreen,
          tabs: [
            for (final tab in tabs)
              Tab(text: '${tab.label(lang)} (${results.countFor(tab)})'),
          ],
        ),
        if (controller.failure != null)
          Expanded(
            child: TongtaiFailureView(
              prefix: 'search',
              failure: controller.failure!,
              onRetry: () => controller.repeat(controller.query),
            ),
          )
        else if (controller.isSearching && results.isEmpty)
          const Expanded(child: TongtaiLoadingView(prefix: 'search'))
        else
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                for (final tab in tabs)
                  _ResultsTabView(lang: lang, tab: tab, results: results),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResultsTabView extends StatelessWidget {
  const _ResultsTabView({
    required this.lang,
    required this.tab,
    required this.results,
  });

  final String lang;
  final TongtaiSearchTab tab;
  final TongtaiSearchResults results;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (results.countFor(tab) == 0) {
      return _CenteredMessage(
        messageKey: const Key('search-empty-no-results'),
        icon: Icons.search_off,
        title: l10n.searchNoResults,
        subtitle: l10n.searchNoResultsBody,
      );
    }

    const padding = EdgeInsets.fromLTRB(
      TongtaiDesignTokens.spacing4,
      TongtaiDesignTokens.spacing3,
      TongtaiDesignTokens.spacing4,
      TongtaiDesignTokens.spacing4,
    );

    switch (tab) {
      case TongtaiSearchTab.suppliers:
        return ListView(
          padding: padding,
          children: [
            for (final s in results.suppliers)
              _SupplierResultCard(supplier: s, lang: lang),
          ],
        );
      case TongtaiSearchTab.products:
        return ListView(
          padding: padding,
          children: [
            for (final p in results.products)
              _ProductResultCard(product: p, lang: lang),
          ],
        );
      case TongtaiSearchTab.collections:
        return ListView(
          padding: padding,
          children: [
            if (results.suppliers.isNotEmpty) ...[
              _SectionHeader(
                label: '${l10n.sectionSuppliers} (${results.supplierCount})',
                color: TongtaiDesignTokens.producerGreen,
              ),
              for (final s in results.suppliers)
                _SupplierResultCard(supplier: s, lang: lang),
            ],
            if (results.products.isNotEmpty) ...[
              _SectionHeader(
                label: '${l10n.sectionProducts} (${results.productCount})',
                color: TongtaiDesignTokens.inventoryOrange,
              ),
              for (final p in results.products)
                _ProductResultCard(product: p, lang: lang),
            ],
          ],
        );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Text(
            label,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierResultCard extends StatelessWidget {
  const _SupplierResultCard({required this.supplier, required this.lang});

  final TongtaiSupplierResult supplier;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      cardKey: Key('search-item-supplier-${supplier.id}'),
      icon: Icons.factory_outlined,
      iconColor: TongtaiDesignTokens.producerGreen,
      title: supplier.name,
      subtitle: [
        if (supplier.category != null && supplier.category!.isNotEmpty)
          supplier.category!,
        if (supplier.country != null && supplier.country!.isNotEmpty)
          supplier.country!,
      ].join(' • '),
      trailing: supplier.rating == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                Text(
                  supplier.rating!.toStringAsFixed(1),
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({required this.product, required this.lang});

  final TongtaiProductResult product;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      cardKey: Key('search-item-product-${product.id}'),
      icon: Icons.inventory_2_outlined,
      iconColor: TongtaiDesignTokens.inventoryOrange,
      title: product.name,
      subtitle: [
        if (product.category != null && product.category!.isNotEmpty)
          product.category!,
        '${context.l10n.labelStock}: ${product.stock.toStringAsFixed(0)}',
      ].join(' • '),
      trailing: Text(
        TongtaiFormatters.vnd(product.price),
        style: TongtaiDesignTokens.smallStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: TongtaiDesignTokens.lightTextPrimary,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    this.cardKey,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  /// Stable test id applied to the card root (P0 §5).
  final Key? cardKey;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
        boxShadow: TongtaiDesignTokens.elevation1,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.componentBorderRadius,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    this.messageKey,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  /// Stable test id applied to the empty-state root (P0 §5).
  final Key? messageKey;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: messageKey,
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing3),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TongtaiDesignTokens.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TongtaiDesignTokens.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing1),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
