import 'package:flutter/material.dart';

import '../../inventory/product.dart';
import '../../inventory/product_catalog_controller.dart';
import '../../inventory/product_image_source.dart';
import '../../inventory/stock_alert.dart';
import '../../inventory/stock_alert_service.dart';
import '../../navigation/tongtai_design_tokens.dart';
import 'tongtai_product_form_screen.dart';
import '../../../../core/l10n/app_strings.dart';

/// Color for a [StockAlertLevel] badge (WTM-70): out of stock is the error red,
/// low stock the warning amber. Pure function so the mapping is unit-testable
/// without pumping a widget.
Color tongtaiStockAlertColor(StockAlertLevel level) => switch (level) {
  StockAlertLevel.outOfStock => TongtaiDesignTokens.error,
  StockAlertLevel.lowStock => TongtaiDesignTokens.warning,
};

/// Stock Alerts screen (WTM-70) — "notify the user when qty falls below the
/// threshold".
///
/// Lists every product at or below its low-stock threshold, most-urgent first
/// (out of stock, then low), so a shop owner can see at a glance what needs
/// restocking. Tapping a row opens the Add/Edit form (WTM-69) where the reorder
/// threshold and quantity can be adjusted; because the screen listens to the
/// shared [ProductCatalogController], a restock makes the alert drop off live.
class TongtaiStockAlertsScreen extends StatelessWidget {
  const TongtaiStockAlertsScreen({
    super.key,
    required this.catalog,
    this.imageSource,
    this.minimumThreshold = 0,
  });

  /// The shared catalog whose products are checked against their thresholds. Not
  /// owned here — the caller (Inventory screen) disposes it.
  final ProductCatalogController catalog;

  /// Image source handed to the Add/Edit form; defaults to the real picker.
  final ProductImageSource? imageSource;

  /// Catalog-wide low-stock threshold floor forwarded to [StockAlertService]
  /// (WTM-70). Default 0 = per-product thresholds only.
  final int minimumThreshold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleStockAlerts),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: catalog,
          builder: (context, _) {
            final service = StockAlertService(
              catalog.products,
              minimumThreshold: minimumThreshold,
            );
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
                      TongtaiDesignTokens.spacing4,
                      0,
                      TongtaiDesignTokens.spacing4,
                      TongtaiDesignTokens.spacing4,
                    ),
                    itemCount: alerts.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: TongtaiDesignTokens.spacing3),
                    itemBuilder: (context, index) => _AlertRow(
                      alert: alerts[index],
                      onTap: () => _openForm(context, alerts[index].product),
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
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing3,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing3,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              statKey: const Key('stock-summary-out-of-stock'),
              count: outOfStock,
              label: context.l10n.stockOut,
              color: TongtaiDesignTokens.error,
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Expanded(
            child: _SummaryStat(
              statKey: const Key('stock-summary-low-stock'),
              count: lowStock,
              label: context.l10n.stockLow,
              color: TongtaiDesignTokens.warning,
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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          Text(
            label,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onTap});

  final StockAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiStockAlertColor(alert.level);
    final product = alert.product;
    return Material(
      key: Key('stock-item-${product.id}'),
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
              Container(
                width: 4,
                height: 44,
                margin: const EdgeInsets.only(
                  right: TongtaiDesignTokens.spacing3,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    TongtaiDesignTokens.radiusFull,
                  ),
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
                      _restockHint(alert),
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LevelChip(level: alert.level),
                  const SizedBox(height: TongtaiDesignTokens.spacing2),
                  Text(
                    context.l10n.stockQtyOfThreshold(
                      alert.quantity,
                      alert.threshold,
                    ),
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
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
  static String _restockHint(StockAlert alert) => alert.shortfall > 0
      ? 'Restock ${alert.shortfall}+ to clear'
      : 'Restock needed';
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final StockAlertLevel level;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiStockAlertColor(level);
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
        level.label(context.l10n.languageCode),
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HealthyState extends StatelessWidget {
  const _HealthyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('stock-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: TongtaiDesignTokens.success,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              context.l10n.stockAllHealthy,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              context.l10n.stockAllHealthyBody,
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
