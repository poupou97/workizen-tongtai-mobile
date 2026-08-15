import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/inventory_context.dart';
import '../../inventory/product.dart';
import '../../inventory/inventory_tone.dart';
import '../../inventory/product_category.dart';
import '../../inventory/product_catalog_controller.dart';
import '../../inventory/product_image_source.dart';
import '../../inventory/product_inventory_service.dart';
import '../../inventory/stock_alert.dart';
import '../../inventory/stock_alert_service.dart';
import '../../providers/tongtai_inventory_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import 'tongtai_product_detail_screen.dart';
import 'tongtai_product_form_screen.dart';
import '../../inventory/slow_moving_capital.dart';
import '../../inventory/slow_moving_capital_loader.dart';
import '../../providers/tongtai_commerce_provider.dart';
import '../widgets/tongtai_product_thumbnail.dart';
import '../widgets/tongtai_tied_up_capital_card.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_screen_header.dart';
import 'tongtai_stock_alerts_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';

/// Color for a [StockStatus] badge (WTM-68 AC: color-coded in stock / low /
/// out). Pulled out as a pure function so the mapping is directly unit-testable
/// without pumping a widget.
// ⛔ WTM-414 (DS-2) — `tongtaiStockStatusColor` đã bị XOÁ khỏi đây.
//
// Nó là một ánh xạ **miền → token**, tức khái niệm của tầng semantic, mà lại
// sống trong tệp màn. Hai màn cùng hỏi *"hết hàng nghĩa là gì"* thì phải nhận
// cùng một câu trả lời, và câu ấy không thể thuộc về một trong hai.
//
// Nay: `tongtaiStockStatusTone()` trong `inventory/inventory_tone.dart`, trả
// **`TtStatus`** chứ không trả `Color` — màn không còn cầm token thô để đặt vào
// bất cứ đâu. Chỗ nào thật sự cần `Color` (biểu đồ) thì gọi `tone.color`, nên
// vẫn chỉ có **một** bảng ánh xạ.

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
  });

  /// Seed catalog for tests; when [catalog] is omitted a mutable controller is
  /// created from this (or the built-in sample catalog when both are null).
  final ProductInventoryService? service;

  /// Injectable mutable catalog. When provided it takes precedence over
  /// [service] and is *not* disposed here (its owner disposes it).
  final ProductCatalogController? catalog;

  /// Image source handed to the Add/Edit form; defaults to the real picker.
  final ProductImageSource? imageSource;

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

  /// Vốn chôn trong hàng chậm bán (WTM-411 · cp3).
  ///
  /// Tính SAU khi danh mục đã nạp, và **không bao giờ làm hỏng** trạng thái
  /// màn: nguồn dữ liệu của nó là đơn hàng, còn danh sách sản phẩm thì không
  /// cần đơn hàng. Xem `slow_moving_capital_loader.dart`.
  SlowMovingCapital _capital = SlowMovingCapital.none;

  Future<ProductCatalogController> _read() async {
    await _catalog.hydrate();
    _capital = await loadSlowMovingCapital(
      profit: ref.read(commerceProfitProvider.future),
      products: _catalog.service.all,
    );
    return _catalog;
  }

  /// Lọc danh sách về đúng tập hàng chậm bán — hành động của thẻ cp3.
  ///
  /// Đây là lát cắt do **dữ liệu** quyết định, nên nó không đi qua ô tìm kiếm
  /// hay chip danh mục: không chuỗi nào diễn đạt được "không bán được cái nào
  /// trong 30 ngày".
  void _showSlowMoving() {
    setState(() {
      _query = _query.copyWith(pageIndex: 0, onlyIds: _capital.productIds);
    });
  }

  /// Bỏ lát cắt, quay lại toàn danh mục.
  void _clearSlowMoving() {
    setState(() {
      _query = _query.copyWith(pageIndex: 0, clearOnlyIds: true);
    });
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
    // The business data can change from another screen (restore a backup, seed
    // or remove sample data). This screen is kept alive by the shell's
    // IndexedStack, so its `initState` load never runs again — without this it
    // would keep rendering a business that no longer exists (WTM-174).
    ref.listen(businessDataRevisionProvider, (_, _) => _data.refresh());
    return ListenableBuilder(
      listenable: Listenable.merge([_catalog, _data]),
      builder: (context, _) {
        final service = _catalog.service;
        final page = service.page(_query);
        final alerts = StockAlertService(_catalog.products);
        return Scaffold(
          backgroundColor: TtColors.surfaceSecondary,
          appBar: tongtaiScreenHeader(
            context,
            screen: 'inventory',
            title: context.l10n.navInventory,
            subtitle: tongtaiScreenSubtitle(context.l10n, 'inventory'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('inventory-action-add'),
            onPressed: () => _openForm(context),
            // White label on amber-500 reads at 2.15:1 — the worst pairing
            // in the palette. Same hue, deep enough to read (WTM-169).
            backgroundColor: TtFab.background,
            foregroundColor: TtFab.foreground,
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
                      // Concept-1 (WTM-215): overview donut + low-stock strip
                      // replace the WTM-70 text banner. Both read the SAME
                      // owners the rest of the app uses — InventorySummary
                      // for the counts, StockAlertService for the alert set —
                      // so this chrome cannot tell a different story than the
                      // list rows below it.
                      if (_catalog.products.isNotEmpty)
                        _OverviewCard(
                          summary: InventorySummary.from(_catalog.products),
                        ),
                      if (alerts.hasAlerts)
                        _LowStockStrip(
                          alerts: alerts.alerts,
                          onViewAll: () => _openAlerts(context),
                          onOpen: (product) =>
                              _openForm(context, product: product),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TtSpace.x4,
                          TtSpace.x3,
                          TtSpace.x4,
                          TtSpace.x2,
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
                      TongtaiTiedUpCapitalCard(
                        capital: _capital,
                        onViewList: _showSlowMoving,
                      ),
                      _ResultsHeader(
                        count: page.totalCount,
                        // Lối vào lát cắt phải có lối ra ngay cạnh con số nó
                        // vừa đổi — người bán bấm thẻ rồi thấy 12/114 mà không
                        // có cách quay lại sẽ tưởng mất hàng.
                        onClearSlice: _query.hasIdFilter
                            ? _clearSlowMoving
                            : null,
                      ),
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
                      onOpen: (product) => _openDetail(context, product),
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
    // WTM-224: one signal for "the business data changed". Every reader
    // hangs off it — Home's KPIs, the capability contexts, the Rule
    // Twins, and the journey's own re-measurement. Without it the write
    // was visible only on the screen that made it.
    invalidateBusinessDataProviders(ref);
    setState(() => _query = _query.copyWith(pageIndex: 0));
  }

  /// Open the read-only Product Detail (WTM-335). Tapping a row now opens the
  /// detail — the grouped attribute view — rather than the edit form directly;
  /// editing is one tap further, from the detail's "Sửa" action. The detail
  /// screen loads a product's attributes on demand, so the list load never
  /// touches the value store (ADR-TON-019).
  Future<void> _openDetail(BuildContext context, Product product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (detailContext) => TongtaiProductDetailScreen(
          product: product,
          onEdit: () {
            // Pop the detail first so a saved edit returns straight to the
            // list, then open the form on the list's context.
            Navigator.of(detailContext).pop();
            _openForm(context, product: product);
          },
        ),
      ),
    );
  }

  /// Open the Stock Alerts screen (WTM-70), sharing the same live catalog so a
  /// restock made there is reflected back on this list.
  void _openAlerts(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiStockAlertsScreen(
          catalog: _catalog,
          imageSource: widget.imageSource,
        ),
      ),
    );
  }
}

/// Concept-1 overview card (WTM-215): donut of stock health + two KPIs.
///
/// Every number comes from [InventorySummary.from] — the same producer that
/// fills the BusinessContext slice (WTM-131) — and the segment colors are the
/// list rows' own [tongtaiStockStatusColor]. The card computes nothing of its
/// own, so it cannot disagree with the rows below it or with Home.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.summary});

  final InventorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inStock =
        summary.productCount - summary.lowStockCount - summary.outOfStockCount;
    final segments = <(StockStatus, int)>[
      (StockStatus.inStock, inStock),
      (StockStatus.lowStock, summary.lowStockCount),
      (StockStatus.outOfStock, summary.outOfStockCount),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(TtSpace.x4, TtSpace.x3, TtSpace.x4, 0),
      child: Container(
        key: const Key('inventory-overview'),
        padding: const EdgeInsets.all(TtSpace.x4),
        decoration: BoxDecoration(
          color: TtColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(TtRadius.md),
          border: Border.all(color: TtColors.border),
          boxShadow: TtElevation.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.invOverviewTitle,
              style: TtType.body.copyWith(
                color: TtColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TtSpace.x3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OverviewKpi(
                        keyId: 'inventory-overview-count',
                        value: '${summary.productCount}',
                        label: l10n.invOverviewProducts,
                      ),
                      const SizedBox(height: TtSpace.x3),
                      _OverviewKpi(
                        keyId: 'inventory-overview-value',
                        value: TongtaiFormatters.vndShort(summary.stockValue),
                        label: l10n.invOverviewValue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TtSpace.x3),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    key: const Key('inventory-overview-donut'),
                    painter: _DonutPainter(
                      segments: [
                        for (final (status, count) in segments)
                          if (count > 0)
                            (tongtaiStockStatusTone(status).color, count),
                      ],
                      trackColor: TtColors.border,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TtSpace.x3),
            // Wrap, not Row: at a 2.0× system font three legend entries do not
            // fit one line on a small phone (the WTM-169 overflow class).
            Wrap(
              spacing: TtSpace.x3,
              runSpacing: TtSpace.x1,
              children: [
                for (final (status, count) in segments)
                  _LegendEntry(
                    color: tongtaiStockStatusTone(status).color,
                    label: status.label(l10n.languageCode),
                    percent: summary.productCount == 0
                        ? 0
                        : (count * 100 / summary.productCount).round(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewKpi extends StatelessWidget {
  const _OverviewKpi({
    required this.keyId,
    required this.value,
    required this.label,
  });

  final String keyId;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key(keyId),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TtType.h2.copyWith(
            color: TtColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: TtSpace.x1),
        // Flexible, or the min-size Row overflows its Wrap slot by the width
        // of whatever the label grew to — measured 12px at vi/1.3× on 320px.
        Flexible(
          child: Text(
            '$label $percent%',
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Stroke-style donut; segment sweep is proportional to its count. Pure
/// painting — the counts arrive already computed by [InventorySummary].
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, required this.trackColor});

  final List<(Color, int)> segments;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final total = segments.fold<int>(0, (sum, s) => sum + s.$2);
    if (total == 0) {
      canvas.drawArc(arcRect, 0, 6.283185, false, paint..color = trackColor);
      return;
    }
    var start = -1.570796; // 12 o'clock
    for (final (color, count) in segments) {
      final sweep = count * 6.283185 / total;
      canvas.drawArc(arcRect, start, sweep, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) {
    if (old.trackColor != trackColor ||
        old.segments.length != segments.length) {
      return true;
    }
    for (var i = 0; i < segments.length; i++) {
      if (old.segments[i] != segments[i]) return true;
    }
    return false;
  }
}

/// Concept-1 low-stock strip (WTM-215): the WTM-70 text banner, grown into the
/// concept's horizontally scrolling cards. The card set IS
/// [StockAlertService.alerts] — the one owner of "sắp hết hàng" since WTM-213
/// — already sorted most-urgent first.
class _LowStockStrip extends StatelessWidget {
  const _LowStockStrip({
    required this.alerts,
    required this.onViewAll,
    required this.onOpen,
  });

  final List<StockAlert> alerts;
  final VoidCallback onViewAll;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TtSpace.x4,
            TtSpace.x3,
            TtSpace.x4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.invLowStockSection,
                  style: TtType.body.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Same stable ID the old banner carried — the affordance that
              // opens the Stock Alerts screen keeps its identity.
              TextButton(
                key: const Key('inventory-open-stock-alerts'),
                onPressed: onViewAll,
                child: Text(l10n.invViewAll),
              ),
            ],
          ),
        ),
        SizedBox(
          // The cards are text; a height that ignores the system font scale
          // overflows 30px per card at 2.0× (the WTM-169 class).
          height: MediaQuery.textScalerOf(context).scale(96),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: TtSpace.x4),
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(width: TtSpace.x2),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _LowStockCard(alert: alert, onOpen: onOpen);
            },
          ),
        ),
      ],
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.alert, required this.onOpen});

  final StockAlert alert;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Thẻ này vẽ **nền + viền** theo mức cảnh báo, tức dùng token cho một
    // bề mặt — không phải một huy hiệu. Nên nó lấy `Color` từ tone, và tone vẫn
    // là chủ duy nhất của ánh xạ.
    final color = tongtaiStockAlertTone(alert.level).color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('inventory-lowstock-${alert.product.id}'),
        onTap: () => onOpen(alert.product),
        borderRadius: BorderRadius.circular(TtRadius.md),
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(TtSpace.x3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(TtRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alert.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.body.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: TtSpace.x1),
              Text(
                context.l10n.stockQtyOfThreshold(
                  alert.quantity,
                  alert.threshold,
                ),
                style: TtType.caption.copyWith(
                  color: TtColors.readableOn(color),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
          padding: const EdgeInsets.only(right: TtSpace.x2),
          child: ChoiceChip(
            label: Text(context.l10n.filterAll),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: TtSpace.x2),
            child: ChoiceChip(
              label: Text(
                ProductCategory.display(category, context.l10n.languageCode),
              ),
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
        tooltip: ascending
            ? context.l10n.sortAscending
            : context.l10n.sortDescending,
        onPressed: onToggleDirection,
      ),
      children: [
        for (final option in ProductSort.values)
          Padding(
            padding: const EdgeInsets.only(right: TtSpace.x2),
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
        horizontal: TtSpace.x4,
        vertical: TtSpace.x1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
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
  const _ResultsHeader({required this.count, this.onClearSlice});

  final int count;

  /// `null` = đang xem toàn danh mục, không có gì để bỏ.
  final VoidCallback? onClearSlice;

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
          Expanded(
            child: Text(
              context.l10n.invProductCount(count),
              key: const Key('inventory-count-badge'),
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ),
          if (onClearSlice != null)
            TextButton.icon(
              key: const Key('inventory-clear-slice'),
              onPressed: onClearSlice,
              icon: const Icon(Icons.close, size: 16),
              label: Text(context.l10n.invShowAll),
            ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, required this.onOpen});

  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // ⚠️ WTM-382: chừa chiều cao FAB dưới đáy. Trên Nokia 6.1 (731 dp) vùng
      // danh sách chỉ còn một hai dòng sau ô tìm kiếm + hai hàng bộ lọc, và
      // FAB nổi che đúng vào đó. Trên máy cao thì không ai thấy vấn đề.
      padding: const EdgeInsets.fromLTRB(
        TtSpace.x4,
        0,
        TtSpace.x4,
        TtFab.scrollPadding,
      ),
      itemCount: products.length,
      separatorBuilder: (context, _) => const SizedBox(height: TtSpace.x3),
      itemBuilder: (context, index) => _ProductRow(
        product: products[index],
        onTap: () => onOpen(products[index]),
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
        borderRadius: BorderRadius.circular(TtRadius.md),
        child: Container(
          padding: const EdgeInsets.all(TtSpace.x3),
          decoration: BoxDecoration(
            color: TtColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(TtRadius.md),
            border: Border.all(color: TtColors.border),
            boxShadow: TtElevation.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WTM-414 — ô ảnh lấp khoảng trắng của danh sách 100 dòng.
              // Ảnh người bán tự thêm thắng placeholder; placeholder trung tính,
              // phân biệt bằng biểu tượng danh mục chứ không bằng màu.
              TongtaiProductThumbnail(product: product),
              const SizedBox(width: TtSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TtType.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TtColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: TtSpace.x1),
                    Text(
                      '${product.sku} • '
                      '${ProductCategory.display(product.category, context.l10n.languageCode)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: TtSpace.x1),
                    Text(
                      context.l10n.invUpdatedOn(
                        TongtaiFormatters.isoDate(product.updatedAt),
                      ),
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TtSpace.x3),
              // Bounded, or a long price on a 320 px phone pushes the row 11 px
              // past the screen edge (WTM-169) — the Expanded on the left can
              // only give way if the right-hand side is allowed to shrink.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      TongtaiFormatters.vnd(product.pricePerUnit),
                      style: TtType.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TtColors.textPrimary,
                      ),
                    ),
                    // ADR-TON-023: sản phẩm số không có tồn kho — không dòng
                    // số lượng, không chip trạng thái. Hiện "SL 0 · Hết hàng"
                    // cho một phần mềm là app nói một điều không có thật.
                    if (product.quantity case final q?) ...[
                      const SizedBox(height: TtSpace.x1),
                      Text(
                        context.l10n.invQuantity(q),
                        style: TtType.caption.copyWith(
                          color: TtColors.textSecondary,
                        ),
                      ),
                    ],
                    if (product.stockStatus case final status?) ...[
                      const SizedBox(height: TtSpace.x2),
                      TtStatusBadge(
                        status: tongtaiStockStatusTone(status),
                        label: status.label(
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                    ],
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
        horizontal: TtSpace.x4,
        vertical: TtSpace.x2,
      ),
      decoration: const BoxDecoration(
        color: TtColors.surfaceSecondary,
        border: Border(top: BorderSide(color: TtColors.border)),
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
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
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
                    style: TtType.body.copyWith(
                      color: TtColors.textPrimary,
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
        padding: const EdgeInsets.all(TtSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: TtColors.textSecondary,
            ),
            const SizedBox(height: TtSpace.x3),
            Text(
              context.l10n.invEmptySearch,
              textAlign: TextAlign.center,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              context.l10n.invEmptySearchHint,
              textAlign: TextAlign.center,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
