import 'package:flutter/foundation.dart';

import 'product.dart';

/// Severity of a stock-level alert (WTM-70). Ordered most-urgent first so the
/// enum index doubles as the sort key: an out-of-stock product is more urgent
/// than one that is merely low.
///
/// Kept UI-agnostic (no colors) so it stays unit-testable; the alerts screen
/// maps it to a color + label.
enum StockAlertLevel {
  outOfStock,
  lowStock;

  String get labelEn => switch (this) {
    StockAlertLevel.outOfStock => 'Out of stock',
    StockAlertLevel.lowStock => 'Low stock',
  };

  String get labelVi => switch (this) {
    StockAlertLevel.outOfStock => 'Hết hàng',
    StockAlertLevel.lowStock => 'Sắp hết hàng',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A raised stock-level alert for a single product (WTM-70): the product is at
/// or below its effective low-stock threshold, so the user should be notified to
/// restock.
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so the
/// alert engine, screens and (later) a notification scheduler can all reuse it.
@immutable
class StockAlert {
  const StockAlert({
    required this.product,
    required this.level,
    required this.threshold,
  });

  /// The product that triggered the alert.
  final Product product;

  /// How urgent the alert is (out of stock vs. merely low).
  final StockAlertLevel level;

  /// The effective low-stock threshold this alert was raised against, i.e. the
  /// larger of the product's own [Product.reorderLevel] and any catalog-wide
  /// minimum threshold (WTM-70: "set low-stock threshold").
  final int threshold;

  /// On-hand quantity, forwarded from [product] for convenience.
  int get quantity => product.quantity;

  /// Units that must be added to lift the product back above its threshold
  /// (never negative). Zero when the threshold itself is zero.
  int get shortfall {
    final gap = threshold - quantity;
    return gap > 0 ? gap : 0;
  }

  /// Builds an alert for [product] when its on-hand quantity is at or below the
  /// effective threshold — the larger of the product's own [Product.reorderLevel]
  /// and [minimumThreshold] — otherwise returns `null` (healthy stock).
  ///
  /// [minimumThreshold] is a catalog-wide floor (default 0, i.e. per-product
  /// thresholds only): raising it makes every product alert earlier, which is how
  /// WTM-70 lets the user set a single low-stock threshold across the catalog.
  static StockAlert? forProduct(Product product, {int minimumThreshold = 0}) {
    assert(minimumThreshold >= 0, 'minimumThreshold cannot be negative');
    final threshold = product.reorderLevel > minimumThreshold
        ? product.reorderLevel
        : minimumThreshold;
    if (product.quantity <= 0) {
      return StockAlert(
        product: product,
        level: StockAlertLevel.outOfStock,
        threshold: threshold,
      );
    }
    if (product.quantity <= threshold) {
      return StockAlert(
        product: product,
        level: StockAlertLevel.lowStock,
        threshold: threshold,
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockAlert &&
          other.product.id == product.id &&
          other.level == level &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(product.id, level, threshold);

  @override
  String toString() =>
      'StockAlert(${product.id}, ${level.name}, qty=$quantity/$threshold)';
}
