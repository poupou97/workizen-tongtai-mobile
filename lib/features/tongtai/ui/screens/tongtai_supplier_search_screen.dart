import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

import '../../core/screen_data_controller.dart';
import '../widgets/tongtai_screen_data.dart';
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
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(context.l10n.titleSupplierSearch),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
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
        // Search field + suggestions + filter bar are fixed-height chrome; at a
        // 2.0x system font they ran 196 px past a short viewport. Same shape,
        // same fix as Inventory: let the chrome scroll away.
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TtSpace.x4,
                      TtSpace.x3,
                      TtSpace.x4,
                      TtSpace.x2,
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
                ],
              ),
            ),
            // Results (+ heart state + favorites-only) rebuild whenever the
            // shared favorites change.
            SliverFillRemaining(
              hasScrollBody: true,
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
        fillColor: TtColors.surfaceTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TtRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: TtSpace.x4),
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
      margin: const EdgeInsets.symmetric(horizontal: TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.sm),
        border: Border.all(color: TtColors.border),
        boxShadow: TtElevation.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TtRadius.sm),
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
                      ? TtColors.danger
                      : TtColors.textSecondary,
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
                  padding: const EdgeInsets.only(right: TtSpace.x2),
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
                  padding: const EdgeInsets.only(right: TtSpace.x2),
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
                  padding: const EdgeInsets.only(right: TtSpace.x2),
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
        horizontal: TtSpace.x4,
        vertical: TtSpace.x1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TtType.body.copyWith(
                color: TtColors.textSecondary,
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
        TtSpace.x4,
        TtSpace.x3,
        TtSpace.x4,
        TtSpace.x2,
      ),
      child: Row(
        children: [
          Text(
            count == 1 ? '1 supplier' : '$count suppliers',
            style: TtType.body.copyWith(color: TtColors.textSecondary),
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
            TtSpace.x4,
            0,
            TtSpace.x4,
            TtSpace.x4,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            // 176 fitted a 20 px heart; a 48 dp tap target needs the extra
            // 28 (WTM-168). Growing the tile is the honest trade — shrinking
            // the target back is how it got to 20x20 in the first place.
            mainAxisExtent: 204,
            crossAxisSpacing: TtSpace.x3,
            mainAxisSpacing: TtSpace.x3,
          ),
          itemCount: suppliers.length,
          itemBuilder: (context, index) => _SupplierCard(
            supplier: suppliers[index],
            isFavorite: favorites.isFavorite(suppliers[index].id),
            // A favourite is persisted (WTM-65) — a write that fails must not
            // leave the heart looking saved (WTM-148).
            onToggleFavorite: () =>
                _toggleFavorite(context, favorites, suppliers[index].id),
          ),
        );
      },
    );
  }
}

/// Persists a favourite toggle, surfacing a failure instead of dropping it.
Future<void> _toggleFavorite(
  BuildContext context,
  SupplierFavoritesController favorites,
  String supplierId,
) async {
  final failure = await runTongtaiAction(
    () => favorites.toggle(supplierId),
    screen: 'supplier-search',
  );
  if (failure != null && context.mounted) showTongtaiFailure(context, failure);
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
        borderRadius: BorderRadius.circular(TtRadius.md),
        child: Container(
          padding: const EdgeInsets.all(TtSpace.x3),
          decoration: BoxDecoration(
            color: TtColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(TtRadius.md),
            border: Border.all(color: TtColors.border),
            boxShadow: TtElevation.soft,
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
                      style: TtType.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TtColors.textPrimary,
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
              const SizedBox(height: TtSpace.x1),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: TtColors.textSecondary,
                  ),
                  const SizedBox(width: TtSpace.x1),
                  Expanded(
                    child: Text(
                      supplier.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TtSpace.x2),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: TtColors.warning),
                  const SizedBox(width: TtSpace.x1),
                  Text(
                    supplier.rating.toStringAsFixed(1),
                    style: TtType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TtColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: TtSpace.x1),
                  Text(
                    '(${supplier.reviewCount})',
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: TtSpace.x1,
                runSpacing: TtSpace.x1,
                children: [
                  for (final category in supplier.categories.take(2))
                    _CategoryTag(label: category),
                ],
              ),
              const SizedBox(height: TtSpace.x1),
              Text(
                context.l10n.supplierMinOrder(
                  supplier.minOrderUnits,
                  supplier.leadTime,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TtType.caption.copyWith(color: TtColors.textSecondary),
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
    // The heart stays visually 20 px so it does not dominate the card, but the
    // thing a thumb has to hit is 48 (WTM-168). An earlier version used a bare
    // InkResponse to avoid IconButton's padding; that left a 20x20 target,
    // which is a heart you have to aim at.
    return Tooltip(
      key: heartKey,
      message: isFavorite ? context.l10n.favRemove : context.l10n.favAdd,
      child: SizedBox(
        width: TtButtonMetrics.height,
        height: TtButtonMetrics.height,
        child: InkResponse(
          onTap: onPressed,
          radius: 24,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: isFavorite ? TtColors.dangerOnLight : TtColors.textSecondary,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x2, vertical: 2),
      decoration: BoxDecoration(
        color: TtColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TtRadius.full),
      ),
      child: Text(
        label,
        style: TtType.caption.copyWith(
          color: TtColors.success,
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
              padding: const EdgeInsets.all(TtSpace.x8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    favoritesOnly ? Icons.favorite_border : Icons.search_off,
                    size: 48,
                    color: TtColors.textSecondary,
                  ),
                  const SizedBox(height: TtSpace.x3),
                  Text(
                    // Key carries which empty state this is — behaviour tests
                    // must not assert on copy (WTM-194).
                    key: Key(
                      favoritesOnly
                          ? 'supplier-empty-favorites'
                          : 'supplier-empty-search',
                    ),
                    favoritesOnly
                        ? context.l10n.supplierNoFavoritesMatch
                        : context.l10n.supplierNoSearchMatch,
                    textAlign: TextAlign.center,
                    style: TtType.bodyLarge.copyWith(
                      color: TtColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TtSpace.x1),
                  Text(
                    favoritesOnly
                        ? context.l10n.supplierFavoritesHint
                        : context.l10n.supplierSearchHint,
                    textAlign: TextAlign.center,
                    style: TtType.body.copyWith(color: TtColors.textSecondary),
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
