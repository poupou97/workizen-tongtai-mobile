import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../inventory/product_catalog_controller.dart';
import '../../inventory/product_image_source.dart';
import '../../inventory/product_inventory_service.dart';
import '../../inventory/stock_alert_service.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_inventory_provider.dart';
import 'tongtai_product_form_screen.dart';
import 'tongtai_stock_alerts_screen.dart';

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
    _catalog.hydrate();
  }

  @override
  void dispose() {
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
      listenable: _catalog,
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
            title: const Text('Inventory'),
            elevation: 0,
            backgroundColor: TongtaiDesignTokens.lightBackground,
            foregroundColor: TongtaiDesignTokens.lightTextPrimary,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            backgroundColor: TongtaiDesignTokens.inventoryOrange,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add product'),
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
                Expanded(
                  child: page.isEmpty
                      ? const _EmptyState()
                      : _ProductList(
                          products: page.items,
                          onEdit: (product) =>
                              _openForm(context, product: product),
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
    await _catalog.upsert(result);
    if (!context.mounted) return;
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
    final parts = <String>[
      if (outOfStock > 0) '$outOfStock out of stock',
      if (lowStock > 0) '$lowStock low',
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.cardBorderRadius,
          ),
          child: Container(
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
                    'Stock alerts: ${parts.join(' • ')}',
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'View',
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
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search products or categories',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
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
      label: 'Category',
      children: [
        Padding(
          padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
          child: ChoiceChip(
            label: const Text('All'),
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
      label: 'Sort',
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
              label: Text(option.labelEn),
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
                      'Updated ${TongtaiFormatters.isoDate(product.updatedAt)}',
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Column(
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
                    'Qty ${product.quantity}',
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing2),
                  _StatusChip(status: product.stockStatus),
                ],
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
        status.labelEn,
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
              'Showing ${page.firstItemNumber}–${page.lastItemNumber} '
              'of ${page.totalCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                onPressed: onPrevious,
              ),
              Text(
                'Page ${page.pageIndex + 1} of ${page.pageCount}',
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                onPressed: onNext,
              ),
            ],
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
    return Center(
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
              'No products match your search',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              'Try a different keyword or clear the category filter.',
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
