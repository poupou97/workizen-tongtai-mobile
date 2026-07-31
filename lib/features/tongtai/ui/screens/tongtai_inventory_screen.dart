import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../inventory/product_catalog_controller.dart';
import '../../inventory/product_image_source.dart';
import '../../inventory/product_inventory_service.dart';
import '../../inventory/stock_alert_service.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_inventory_provider.dart';
import 'tongtai_product_form_screen.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_stock_alerts_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';

/// Color for a [StockStatus] badge (WTM-68 AC: color-coded in stock / low /
/// out). Pulled out as a pure function so the mapping is directly unit-testable
/// without pumping a widget.
Color tongtaiStockStatusColor(StockStatus status) => switch (status) {
  StockStatus.inStock => TongtaiDesignTokens.success,
  StockStatus.lowStock => TongtaiDesignTokens.warning,
  StockStatus.outOfStock => TongtaiDesignTokens.error,
};

/// Inventory / product list screen (WTM-68) — Product & Warehouse hub.
///
/// Local-first product catalog: a searchable, category-filterable, sortable
/// product list with color-coded stock status and 20-per-page pagination. A "+"
/// button opens the Add Product form and tapping a row opens it in Edit mode
/// (WTM-69); saved products are upserted into the [ProductCatalogController] so
/// the list updates live. Filtering, sorting and paging happen synchronously.
class TongtaiInventoryScreen extends ConsumerStatefulWidget {
  const TongtaiInventoryScreen({
    super.key,
    this.service,
    this.catalog,
    this.imageSource,
    this.minimumThreshold = 0,
  });

  /// Seed catalog for tests; when [catalog] is omitted a mutable controller is
  /// created from this (or the built-in sample catalog when both are null).
  final ProductInventoryService? service;

  /// Injectable mutable catalog. When provided it takes precedence over
  /// [service] and is *not* disposed here (its owner disposes it).
  final ProductCatalogController? catalog;

  /// Image source handed to the Add/Edit form; defaults to the real picker.
  final ProductImageSource? imageSource;

  /// Catalog-wide low-stock threshold floor for the alert banner (WTM-70),
  /// forwarded to [StockAlertService]. Default 0 = per-product thresholds only.
  final int minimumThreshold;

  @override
  ConsumerState<TongtaiInventoryScreen> createState() =>
      _TongtaiInventoryScreenState();
}

class _TongtaiInventoryScreenState
    extends ConsumerState<TongtaiInventoryScreen> {
  late final ProductCatalogController _catalog;
  late final bool _ownsCatalog;
  final TextEditingController _searchController = TextEditingController();

  /// Catalogue hydration as a visible state (WTM-148): an unreadable product
  /// table must not render as "you sell nothing".
  late final ScreenDataController<ProductCatalogController> _data;

  ProductQuery _query = const ProductQuery();

  @override
  void initState() {
    super.initState();
    if (widget.catalog != null) {
      _catalog = widget.catalog!;
      _ownsCatalog = false;
    } else if (widget.service != null) {
      // Test seed: an in-memory catalogue over the supplied products.
      _catalog = ProductCatalogController.inMemory(widget.service!.all);
      _ownsCatalog = true;
    } else {
      // Real app: persistent Drift catalogue (WTM-121), empty for new users.
      _catalog = ProductCatalogController(ref.read(productRepositoryProvider));
      _ownsCatalog = true;
    }
    _data = ScreenDataController<ProductCatalogController>(
      _read,
      // Injected catalogue/service ⇒ the rows are already in memory; hydrating
      // them is a refresh, not a cold start.
      initialValue: _ownsCatalog && widget.service == null ? null : _catalog,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'inventory',
    )..start();
  }

  Future<ProductCatalogController> _read() async {
    await _catalog.hydrate();
    return _catalog;
  }

  @override
  void dispose() {
    _data.dispose();
    _searchController.dispose();
    if (_ownsCatalog) _catalog.dispose();
    super.dispose();
  }

  // Any change to the search text, category or sort resets to the first page so
  // the user is never stranded on a now-out-of-range page.
  void _onSearchChanged(String value) {
    setState(() => _query = _query.copyWith(text: value, pageIndex: 0));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = _query.copyWith(text: '', pageIndex: 0));
  }

  void _selectCategory(String? category) {
    setState(() {
      _query = category == null
          ? _query.copyWith(clearCategory: true, pageIndex: 0)
          : _query.copyWith(category: category, pageIndex: 0);
    });
  }

  void _selectSort(ProductSort sort) {
    setState(() => _query = _query.copyWith(sort: sort, pageIndex: 0));
  }

  void _toggleDirection() {
    setState(
      () =>
          _query = _query.copyWith(ascending: !_query.ascending, pageIndex: 0),
    );
  }

  void _goToPage(int index) {
    setState(() => _query = _query.copyWith(pageIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_catalog, _data]),
      builder: (context, _) {
        final service = _catalog.service;
        final page = service.page(_query);
        final alerts = StockAlertService(
          _catalog.products,
          minimumThreshold: widget.minimumThreshold,
        );
        return Scaffold(
          backgroundColor: TongtaiDesignTokens.lightBackground,
          appBar: AppBar(
            title: Text(context.l10n.navInventory),
            elevation: 0,
            backgroundColor: TongtaiDesignTokens.lightBackground,
            foregroundColor: TongtaiDesignTokens.lightTextPrimary,
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('inventory-action-add'),
            onPressed: () => _openForm(context),
            // White label on amber-500 reads at 2.15:1 — the worst pairing
            // in the palette. Same hue, deep enough to read (WTM-169).
            backgroundColor: TongtaiDesignTokens.inventoryOrangeText,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.invAdd),
          ),
          // The pagination controls sit in the bottom bar so the (endFloat) FAB
          // is lifted clear above them, instead of a bottom-right FAB obscuring
          // the Next-page button.
          bottomNavigationBar: page.totalCount > 0
              ? SafeArea(
                  top: false,
                  child: _PaginationBar(
                    page: page,
                    onPrevious: page.hasPrevious
                        ? () => _goToPage(page.pageIndex - 1)
                        : null,
                    onNext: page.hasNext
                        ? () => _goToPage(page.pageIndex + 1)
                        : null,
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            // The chrome above the list (alert banner · search · category
            // filter · sort bar · result count) is fixed-height content, and at
            // a 2.0x system font it grew past a short viewport and clipped by
            // 103 px — measured, not guessed (WTM-169). `Expanded` cannot save
            // it: the non-flex children alone were taller than the screen.
            //
            // Letting the chrome scroll away is both the fix and the ordinary
            // mobile behaviour; the list keeps the rest of the space.
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alerts.hasAlerts)
                        _AlertBanner(
                          outOfStock: alerts.outOfStockCount,
                          lowStock: alerts.lowStockCount,
                          onTap: () => _openAlerts(context),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TongtaiDesignTokens.spacing4,
                          TongtaiDesignTokens.spacing3,
                          TongtaiDesignTokens.spacing4,
                          TongtaiDesignTokens.spacing2,
                        ),
                        child: _SearchField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onClear: _query.text.isEmpty ? null : _clearSearch,
                        ),
                      ),
                      _CategoryFilter(
                        categories: service.categories,
                        selected: _query.category,
                        onSelected: _selectCategory,
                      ),
                      _SortBar(
                        sort: _query.sort,
                        ascending: _query.ascending,
                        onSort: _selectSort,
                        onToggleDirection: _toggleDirection,
                      ),
                      _ResultsHeader(count: page.totalCount),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: TongtaiScreenData<ProductCatalogController>(
                    prefix: 'inventory',
                    state: _data.state,
                    onRetry: _data.retry,
                    isEmpty: (_) => page.isEmpty,
                    emptyBuilder: (_) => const _EmptyState(),
                    builder: (context, _) => _ProductList(
                      products: page.items,
                      onEdit: (product) => _openForm(context, product: product),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Open the Add/Edit form. [product] null = add; non-null = edit. On save the
  /// returned product is upserted into the catalog and the list snaps to page 1.
  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => TongtaiProductFormScreen(
          product: product,
          categories: _catalog.service.categories,
          isSkuTaken: (sku) => _catalog.isSkuTaken(sku, exceptId: product?.id),
          imageSource: widget.imageSource,
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    final failure = await runTongtaiAction(
      () => _catalog.upsert(result),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'inventory',
    );
    if (!context.mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    setState(() => _query = _query.copyWith(pageIndex: 0));
  }

  /// Open the Stock Alerts screen (WTM-70), sharing the same live catalog so a
  /// restock made there is reflected back on this list.
  void _openAlerts(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiStockAlertsScreen(
          catalog: _catalog,
          imageSource: widget.imageSource,
          minimumThreshold: widget.minimumThreshold,
        ),
      ),
    );
  }
}

/// Tappable low-stock summary banner (WTM-70) shown above the search field when
/// any product is at or below its threshold; opens the Stock Alerts screen.
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.outOfStock,
    required this.lowStock,
    required this.onTap,
  });

  final int outOfStock;
  final int lowStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Out-of-stock is the more urgent state, so the banner leans on its red when
    // anything is fully out; otherwise the low-stock amber.
    final color = outOfStock > 0
        ? TongtaiDesignTokens.error
        : TongtaiDesignTokens.warning;
    final l10n = context.l10n;
    final parts = <String>[
      if (outOfStock > 0) l10n.invOutOfStockCount(outOfStock),
      if (lowStock > 0) l10n.invLowStockCount(lowStock),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing3,
        TongtaiDesignTokens.spacing4,
        0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('inventory-open-stock-alerts'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.cardBorderRadius,
          ),
          child: Container(
            // A tappable banner is a tap target: 12 dp padding around a 22 dp
            // row came to 46, and Android asks for 48 (WTM-169).
            constraints: const BoxConstraints(
              minHeight: TongtaiDesignTokens.buttonHeight,
            ),
            padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.cardBorderRadius,
              ),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 20),
                const SizedBox(width: TongtaiDesignTokens.spacing2),
                Expanded(
                  child: Text(
                    l10n.invStockAlerts(parts.join(' • ')),
                    key: const Key('inventory-summary-alerts'),
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  context.l10n.invView,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.chevron_right, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('inventory-search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.invSearchHint,
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

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return _ChipsRow(
      label: context.l10n.searchCategory,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
          child: ChoiceChip(
            label: Text(context.l10n.filterAll),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
            child: ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (isSelected) =>
                  onSelected(isSelected ? category : null),
            ),
          ),
      ],
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onToggleDirection,
  });

  final ProductSort sort;
  final bool ascending;
  final ValueChanged<ProductSort> onSort;
  final VoidCallback onToggleDirection;

  @override
  Widget build(BuildContext context) {
    return _ChipsRow(
      label: context.l10n.labelSort,
      trailing: IconButton(
        icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
        tooltip: ascending ? 'Sort ascending' : 'Sort descending',
        onPressed: onToggleDirection,
      ),
      children: [
        for (final option in ProductSort.values)
          Padding(
            padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
            child: ChoiceChip(
              label: Text(option.label(context.l10n.languageCode)),
              selected: sort == option,
              onSelected: (_) => onSort(option),
            ),
          ),
      ],
    );
  }
}

/// A labelled, horizontally-scrolling row of chips with an optional trailing
/// action — shared chrome for the category and sort rows.
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.label, required this.children, this.trailing});

  final String label;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
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
              child: Row(children: children),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing3,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing2,
      ),
      child: Text(
        count == 1 ? '1 product' : '$count products',
        key: const Key('inventory-count-badge'),
        style: TongtaiDesignTokens.smallStyle.copyWith(
          color: TongtaiDesignTokens.lightTextSecondary,
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, required this.onEdit});

  final List<Product> products;
  final ValueChanged<Product> onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        0,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing4,
      ),
      itemCount: products.length,
      separatorBuilder: (context, _) =>
          const SizedBox(height: TongtaiDesignTokens.spacing3),
      itemBuilder: (context, index) => _ProductRow(
        product: products[index],
        onTap: () => onEdit(products[index]),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('inventory-item-${product.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TongtaiDesignTokens.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: TongtaiDesignTokens.spacing1),
                    Text(
                      '${product.sku} • ${product.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: TongtaiDesignTokens.spacing1),
                    Text(
                      context.l10n.invUpdatedOn(
                        TongtaiFormatters.isoDate(product.updatedAt),
                      ),
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              // Bounded, or a long price on a 320 px phone pushes the row 11 px
              // past the screen edge (WTM-169) — the Expanded on the left can
              // only give way if the right-hand side is allowed to shrink.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      TongtaiFormatters.vnd(product.pricePerUnit),
                      style: TongtaiDesignTokens.smallStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: TongtaiDesignTokens.spacing1),
                    Text(
                      context.l10n.invQuantity(product.quantity),
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: TongtaiDesignTokens.spacing2),
                    _StatusChip(status: product.stockStatus),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiStockStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label(context.l10n.languageCode),
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final ProductPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing2,
      ),
      decoration: const BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        border: Border(top: BorderSide(color: TongtaiDesignTokens.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              context.l10n.invShowingRange(
                page.firstItemNumber,
                page.lastItemNumber,
                page.totalCount,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
          // Flexible, because two 48 dp tap targets plus a page label is wider
          // than a 320 px phone at a 1.3x font — the bar clipped by 11 px and
          // took the "next page" button with it (WTM-169).
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('inventory-action-prev-page'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: context.l10n.actionPrevPage,
                  onPressed: onPrevious,
                ),
                Flexible(
                  child: Text(
                    context.l10n.invPageOf(page.pageIndex + 1, page.pageCount),
                    key: const Key('inventory-page-indicator'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('inventory-action-next-page'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: context.l10n.actionNextPage,
                  onPressed: onNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // Scrollable, because "empty" is not the same as "small": at 320 px with a
    // 1.3x font this icon + two lines of Vietnamese ran 55 px past the bottom
    // (WTM-169). A centred Column cannot shrink, so it has to be able to move.
    return SingleChildScrollView(
      key: const Key('inventory-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              context.l10n.invEmptySearch,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              context.l10n.invEmptySearchHint,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
