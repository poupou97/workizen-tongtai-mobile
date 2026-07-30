import 'package:flutter/material.dart';

import '../../navigation/tongtai_design_tokens.dart';
import '../../producer/supplier.dart';
import '../../producer/supplier_favorites_controller.dart';
import '../../producer/supplier_search_service.dart';
import 'tongtai_supplier_detail_screen.dart';
import 'tongtai_supplier_favorites_screen.dart';
import '../../../../core/l10n/app_strings.dart';

/// Number of result columns for a given available [width].
///
/// Pulled out as a pure function so the responsive behaviour (portrait vs.
/// landscape / tablet) is directly unit-testable: a narrow portrait phone gets
/// a single column, a wide landscape phone or tablet gets two, and a large
/// tablet gets three.
int supplierResultColumns(double width) {
  if (width >= 900) return 3;
  if (width >= 600) return 2;
  return 1;
}

/// Supplier Search screen (WTM-63) — Producer/Sourcing Hub.
///
/// Local-first supplier discovery: a responsive search field, category/rating/
/// location filters, real-time typeahead suggestions, and a results grid that
/// reflows between portrait and landscape. All search is in-memory via
/// [SupplierSearchService], so results appear synchronously (well under the
/// 500ms target).
class TongtaiSupplierSearchScreen extends StatefulWidget {
  const TongtaiSupplierSearchScreen({super.key, this.service, this.favorites});

  /// Injectable for tests; defaults to the built-in sample directory.
  final SupplierSearchService? service;

  /// Shared favorites state (WTM-65); injectable for tests. Defaults to an
  /// in-memory-backed controller so the screen runs standalone.
  final SupplierFavoritesController? favorites;

  @override
  State<TongtaiSupplierSearchScreen> createState() =>
      _TongtaiSupplierSearchScreenState();
}

class _TongtaiSupplierSearchScreenState
    extends State<TongtaiSupplierSearchScreen> {
  late final SupplierSearchService _service;
  late final SupplierFavoritesController _favorites;
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  SupplierSearchFilter _filter = const SupplierSearchFilter();

  /// When true, results are narrowed to favorited suppliers (WTM-65 AC4).
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SupplierSearchService.sample();
    _favorites = widget.favorites ?? SupplierFavoritesController.inMemory();
    if (!_favorites.isLoaded) {
      _favorites.load();
    }
    _queryFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _filter = _filter.copyWith(query: value));
  }

  void _applySuggestion(String suggestion) {
    _queryController.text = suggestion;
    _queryController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    _queryFocus.unfocus();
    setState(() => _filter = _filter.copyWith(query: suggestion));
  }

  void _clearQuery() {
    _queryController.clear();
    setState(() => _filter = _filter.copyWith(query: ''));
  }

  void _selectCategory(String? category) {
    setState(() {
      _filter = category == null
          ? _filter.copyWith(clearCategory: true)
          : _filter.copyWith(category: category);
    });
  }

  void _selectRating(double? minRating) {
    setState(() {
      _filter = minRating == null
          ? _filter.copyWith(clearRating: true)
          : _filter.copyWith(minRating: minRating);
    });
  }

  void _selectLocation(String? location) {
    setState(() {
      _filter = location == null
          ? _filter.copyWith(clearLocation: true)
          : _filter.copyWith(location: location);
    });
  }

  void _resetFilters() {
    setState(() {
      _filter = SupplierSearchFilter(query: _filter.query);
      _favoritesOnly = false;
    });
  }

  void _setFavoritesOnly(bool value) {
    setState(() => _favoritesOnly = value);
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TongtaiSupplierFavoritesScreen(
          favorites: _favorites,
          service: _service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _service.suggestions(_filter.query);
    final showSuggestions =
        _queryFocus.hasFocus &&
        suggestions.isNotEmpty &&
        _filter.query.isNotEmpty;

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleSupplierSearch),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        actions: [
          ListenableBuilder(
            listenable: _favorites,
            builder: (context, _) => IconButton(
              key: const Key('supplier-search-open-favorites'),
              onPressed: _openFavorites,
              tooltip: context.l10n.titleFavoriteSuppliers,
              icon: Badge(
                isLabelVisible: _favorites.count > 0,
                label: Text('${_favorites.count}'),
                child: const Icon(Icons.favorite_outline),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
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
                onChanged: _onQueryChanged,
                onClear: _filter.query.isEmpty ? null : _clearQuery,
              ),
            ),
            if (showSuggestions)
              _SuggestionsList(
                suggestions: suggestions,
                onSelected: _applySuggestion,
              ),
            _FilterBar(
              service: _service,
              filter: _filter,
              onCategory: _selectCategory,
              onRating: _selectRating,
              onLocation: _selectLocation,
              favoritesOnly: _favoritesOnly,
              onFavoritesOnly: _setFavoritesOnly,
            ),
            // Results (+ heart state + favorites-only) rebuild whenever the
            // shared favorites change.
            Expanded(
              child: ListenableBuilder(
                listenable: _favorites,
                builder: (context, _) {
                  final base = _service.search(_filter);
                  final results = _favoritesOnly
                      ? _favorites.onlyFavorites(base)
                      : base;
                  return Column(
                    children: [
                      _ResultsHeader(
                        count: results.length,
                        hasActiveFilters:
                            _filter.hasActiveFilters || _favoritesOnly,
                        onReset: _resetFilters,
                      ),
                      Expanded(
                        child: results.isEmpty
                            ? _EmptyState(favoritesOnly: _favoritesOnly)
                            : _ResultsGrid(
                                suppliers: results,
                                favorites: _favorites,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('supplier-search-field'),
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.supSearchHint,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.service,
    required this.filter,
    required this.onCategory,
    required this.onRating,
    required this.onLocation,
    required this.favoritesOnly,
    required this.onFavoritesOnly,
  });

  final SupplierSearchService service;
  final SupplierSearchFilter filter;
  final ValueChanged<String?> onCategory;
  final ValueChanged<double?> onRating;
  final ValueChanged<String?> onLocation;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterRow(
          label: context.l10n.supShow,
          child: Row(
            children: [
              // Favorites-only filter (WTM-65 AC4).
              FilterChip(
                key: const Key('supplier-search-filter-favorites'),
                label: Text(context.l10n.supFavorites),
                selected: favoritesOnly,
                avatar: Icon(
                  favoritesOnly ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: favoritesOnly
                      ? TongtaiDesignTokens.error
                      : TongtaiDesignTokens.lightTextSecondary,
                ),
                onSelected: onFavoritesOnly,
              ),
            ],
          ),
        ),
        _FilterRow(
          label: context.l10n.searchCategory,
          child: Row(
            children: [
              for (final category in service.categories)
                Padding(
                  padding: const EdgeInsets.only(
                    right: TongtaiDesignTokens.spacing2,
                  ),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: filter.category == category,
                    onSelected: (selected) =>
                        onCategory(selected ? category : null),
                  ),
                ),
            ],
          ),
        ),
        _FilterRow(
          label: context.l10n.searchRating,
          child: Row(
            children: [
              for (final rating in kSupplierRatingPresets)
                Padding(
                  padding: const EdgeInsets.only(
                    right: TongtaiDesignTokens.spacing2,
                  ),
                  child: ChoiceChip(
                    label: Text('${rating.toStringAsFixed(1)}★+'),
                    selected: filter.minRating == rating,
                    onSelected: (selected) =>
                        onRating(selected ? rating : null),
                  ),
                ),
            ],
          ),
        ),
        _FilterRow(
          label: context.l10n.labelLocation,
          child: Row(
            children: [
              for (final country in service.countries)
                Padding(
                  padding: const EdgeInsets.only(
                    right: TongtaiDesignTokens.spacing2,
                  ),
                  child: ChoiceChip(
                    label: Text(country),
                    selected: filter.location == country,
                    onSelected: (selected) =>
                        onLocation(selected ? country : null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.hasActiveFilters,
    required this.onReset,
  });

  final int count;
  final bool hasActiveFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing3,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing2,
      ),
      child: Row(
        children: [
          Text(
            count == 1 ? '1 supplier' : '$count suppliers',
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const Spacer(),
          if (hasActiveFilters)
            TextButton.icon(
              key: const Key('supplier-search-action-clear-filters'),
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: Text(context.l10n.actionClearFilters),
            ),
        ],
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.suppliers, required this.favorites});

  final List<Supplier> suppliers;
  final SupplierFavoritesController favorites;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = supplierResultColumns(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            TongtaiDesignTokens.spacing4,
            0,
            TongtaiDesignTokens.spacing4,
            TongtaiDesignTokens.spacing4,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 176,
            crossAxisSpacing: TongtaiDesignTokens.spacing3,
            mainAxisSpacing: TongtaiDesignTokens.spacing3,
          ),
          itemCount: suppliers.length,
          itemBuilder: (context, index) => _SupplierCard(
            supplier: suppliers[index],
            isFavorite: favorites.isFavorite(suppliers[index].id),
            onToggleFavorite: () => favorites.toggle(suppliers[index].id),
          ),
        );
      },
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Supplier supplier;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TongtaiSupplierDetailScreen.forSupplier(supplier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('supplier-search-item-${supplier.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        child: Container(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
          decoration: BoxDecoration(
            color: TongtaiDesignTokens.lightBackground,
            borderRadius: BorderRadius.circular(
              TongtaiDesignTokens.cardBorderRadius,
            ),
            border: Border.all(color: TongtaiDesignTokens.lightBorder),
            boxShadow: TongtaiDesignTokens.elevation1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      supplier.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TongtaiDesignTokens.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                  _FavoriteHeart(
                    heartKey: Key('supplier-search-fav-${supplier.id}'),
                    isFavorite: isFavorite,
                    onPressed: onToggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing1),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing1),
                  Expanded(
                    child: Text(
                      supplier.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing2),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: TongtaiDesignTokens.spacing1),
                  Text(
                    supplier.rating.toStringAsFixed(1),
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TongtaiDesignTokens.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing1),
                  Text(
                    '(${supplier.reviewCount})',
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: TongtaiDesignTokens.spacing1,
                runSpacing: TongtaiDesignTokens.spacing1,
                children: [
                  for (final category in supplier.categories.take(2))
                    _CategoryTag(label: category),
                ],
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing1),
              Text(
                'Min ${supplier.minOrderUnits} • ${supplier.leadTime}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact heart toggle (WTM-65 AC1/AC2): filled red when favorited, outline
/// otherwise. Sits inside the card's [InkWell]; because it is itself a button it
/// wins the tap so favoriting never also opens the detail view.
class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({
    required this.isFavorite,
    required this.onPressed,
    this.heartKey,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  /// Stable per-supplier test id (`supplier-search-fav-<id>`) supplied by the
  /// owning card, which is the only place the supplier id is known.
  final Key? heartKey;

  @override
  Widget build(BuildContext context) {
    // A plain InkResponse (not IconButton) keeps the control at the name's 24px
    // line box — an IconButton would add ~48px tap-target padding and overflow
    // the card's fixed-height row.
    return Tooltip(
      key: heartKey,
      message: isFavorite ? context.l10n.favRemove : context.l10n.favAdd,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: isFavorite
              ? TongtaiDesignTokens.error
              : TongtaiDesignTokens.lightTextSecondary,
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.producerGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
      ),
      child: Text(
        label,
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: TongtaiDesignTokens.producerGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.favoritesOnly = false});

  /// Whether the empty result is because the favorites-only filter is on but no
  /// favorites match — a different, more helpful message than a plain no-match.
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    // Scroll-safe: centered when there is room, scrollable when the results area
    // is short (e.g. a small screen with the filter bar expanded) so it never
    // overflows.
    return LayoutBuilder(
      key: const Key('supplier-search-empty'),
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
                    favoritesOnly ? Icons.favorite_border : Icons.search_off,
                    size: 48,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing3),
                  Text(
                    favoritesOnly
                        ? 'No favorite suppliers match'
                        : 'No suppliers match your search',
                    textAlign: TextAlign.center,
                    style: TongtaiDesignTokens.bodyStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing1),
                  Text(
                    favoritesOnly
                        ? 'Tap the heart on a supplier to add it to your favorites.'
                        : 'Try a different keyword or adjust your filters.',
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
