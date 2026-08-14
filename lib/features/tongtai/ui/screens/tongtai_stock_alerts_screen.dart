import 'package:flutter/material.dart';

import '../../inventory/product.dart';
import '../../inventory/inventory_tone.dart';
import '../../inventory/product_category.dart';
import '../../inventory/product_catalog_controller.dart';
import '../../inventory/product_image_source.dart';
import '../../inventory/stock_alert.dart';
import '../../inventory/stock_alert_service.dart';
import 'tongtai_product_form_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_for.dart';
import '../../providers/tongtai_context_provider.dart';
import 'tongtai_opportunity_detail_screen.dart';

/// Color for a [StockAlertLevel] badge (WTM-70): out of stock is the error red,
/// low stock the warning amber. Pure function so the mapping is unit-testable
/// without pumping a widget.
// ⛔ WTM-414 (DS-2) — ánh xạ chuyển sang `inventory/inventory_tone.dart`
// (`tongtaiStockAlertTone`), trả `TtStatus` thay vì `Color`. Xem chú thích ở
// tệp ấy: trả `Color` là nhảy qua tầng semantic.

/// Stock Alerts screen (WTM-70) — "notify the user when qty falls below the
/// threshold".
///
/// Lists every product at or below its low-stock threshold, most-urgent first
/// (out of stock, then low), so a shop owner can see at a glance what needs
/// restocking. Tapping a row opens the Add/Edit form (WTM-69) where the reorder
/// threshold and quantity can be adjusted; because the screen listens to the
/// shared [ProductCatalogController], a restock makes the alert drop off live.
class TongtaiStockAlertsScreen extends ConsumerWidget {
  const TongtaiStockAlertsScreen({
    super.key,
    required this.catalog,
    this.imageSource,
  });

  /// The shared catalog whose products are checked against their thresholds. Not
  /// owned here — the caller (Inventory screen) disposes it.
  final ProductCatalogController catalog;

  /// Image source handed to the Add/Edit form; defaults to the real picker.
  final ProductImageSource? imageSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WTM-225: the opportunities the Rule Engine already generated. Read, never
    // recomputed here — Inventory does not get its own idea of what is worth
    // restocking.
    final generated =
        ref.watch(generatedOpportunitiesProvider).value ??
        const <Opportunity>[];
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(context.l10n.titleStockAlerts),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: catalog,
          builder: (context, _) {
            final service = StockAlertService(catalog.products);
            if (!service.hasAlerts) return const _HealthyState();
            final alerts = service.alerts;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertSummary(
                  outOfStock: service.outOfStockCount,
                  lowStock: service.lowStockCount,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      TtSpace.x4,
                      0,
                      TtSpace.x4,
                      TtSpace.x4,
                    ),
                    itemCount: alerts.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: TtSpace.x3),
                    itemBuilder: (context, index) => _AlertRow(
                      alert: alerts[index],
                      onTap: () => _openForm(context, alerts[index].product),
                      // The fifth beat: the seller sees the problem here, and
                      // the product has already worked out what to do about it.
                      opportunity: generated.restockFor(
                        alerts[index].product.id,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Open the product in the Add/Edit form so its threshold/quantity can be
  /// adjusted; the saved product is upserted back into the shared catalog, which
  /// re-runs the alert engine and updates this list.
  Future<void> _openForm(BuildContext context, Product product) async {
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => TongtaiProductFormScreen(
          product: product,
          categories: catalog.service.categories,
          isSkuTaken: (sku) => catalog.isSkuTaken(sku, exceptId: product.id),
          imageSource: imageSource,
        ),
      ),
    );
    if (result == null) return;
    catalog.upsert(result);
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.outOfStock, required this.lowStock});

  final int outOfStock;
  final int lowStock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TtSpace.x4,
        TtSpace.x3,
        TtSpace.x4,
        TtSpace.x3,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              statKey: const Key('stock-summary-out-of-stock'),
              count: outOfStock,
              label: context.l10n.stockOut,
              color: TtColors.danger,
            ),
          ),
          const SizedBox(width: TtSpace.x3),
          Expanded(
            child: _SummaryStat(
              statKey: const Key('stock-summary-low-stock'),
              count: lowStock,
              label: context.l10n.stockLow,
              color: TtColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    this.statKey,
    required this.count,
    required this.label,
    required this.color,
  });

  /// Stable test id applied to the tile root (P0 §5).
  final Key? statKey;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: statKey,
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TtType.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: TtSpace.x1),
          Text(
            label,
            style: TtType.caption.copyWith(
              color: TtColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onTap, this.opportunity});

  final StockAlert alert;
  final VoidCallback onTap;

  /// The restock opportunity the engine generated for this product, if any.
  /// `null` for a product that is low but never sells — there is no case to
  /// make, and a button to a non-existent opportunity is the WTM-169 defect.
  final Opportunity? opportunity;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiStockAlertTone(alert.level).color;
    final product = alert.product;
    return Material(
      key: Key('stock-item-${product.id}'),
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
              Container(
                width: 4,
                height: 44,
                margin: const EdgeInsets.only(right: TtSpace.x3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(TtRadius.full),
                ),
              ),
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
                      _restockHint(alert, context.l10n),
                      style: TtType.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TtSpace.x3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TtStatusBadge(
                    status: tongtaiStockAlertTone(alert.level),
                    label: alert.level.label(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  const SizedBox(height: TtSpace.x2),
                  Text(
                    context.l10n.stockQtyOfThreshold(
                      alert.quantity,
                      alert.threshold,
                    ),
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
                    ),
                  ),
                  if (opportunity case final o?) ...[
                    const SizedBox(height: TtSpace.x1),
                    TextButton(
                      key: Key('stock-opportunity-${alert.product.id}'),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              TongtaiOpportunityDetailScreen(opportunity: o),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(context.l10n.stockSeeOpportunity),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Human hint for how much to restock. Falls back to a generic prompt when the
  /// threshold is zero (nothing meaningful to count toward).
  ///
  /// Takes [l10n] rather than reading `context`: both branches were hard-coded
  /// English (WTM-194), and the interpolated one was invisible to the literal
  /// scan — a string built from a number is still a string a seller reads.
  static String _restockHint(StockAlert alert, AppStrings l10n) =>
      alert.shortfall > 0
      ? l10n.stockRestockBy(alert.shortfall)
      : l10n.stockRestockNeeded;
}

class _HealthyState extends StatelessWidget {
  const _HealthyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('stock-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TtSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: TtColors.success,
            ),
            const SizedBox(height: TtSpace.x3),
            Text(
              context.l10n.stockAllHealthy,
              textAlign: TextAlign.center,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              context.l10n.stockAllHealthyBody,
              textAlign: TextAlign.center,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
