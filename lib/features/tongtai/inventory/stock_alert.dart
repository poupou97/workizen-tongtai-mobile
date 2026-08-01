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
/// or below its low-stock threshold, so the user should be notified to restock.
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so the
/// alert engine, screens and (later) a notification scheduler can all reuse it.
@immutable
class StockAlert {
  const StockAlert({required this.product, required this.level});

  /// The product that triggered the alert.
  final Product product;

  /// How urgent the alert is (out of stock vs. merely low).
  final StockAlertLevel level;

  /// The threshold this alert was raised against — the product's own
  /// [Product.reorderLevel], forwarded. There is no other threshold: "sắp hết
  /// hàng" has exactly one owner, [Product.stockStatus] (WTM-213).
  int get threshold => product.reorderLevel;

  /// On-hand quantity, forwarded from [product] for convenience.
  int get quantity => product.quantity;

  /// Units that must be added to lift the product back above its threshold
  /// (never negative). Zero when the threshold itself is zero.
  int get shortfall {
    final gap = threshold - quantity;
    return gap > 0 ? gap : 0;
  }

  /// Builds an alert for [product], or `null` for healthy stock.
  ///
  /// Reads [Product.stockStatus] — the ONE rule for "low stock" — rather than
  /// re-implementing the comparison. WTM-213 removed the `minimumThreshold`
  /// catalog floor that used to live here: it was a second, internally
  /// consistent rule for a concept that already had an owner (the P-27 shape,
  /// same family as `lapsedCustomerDays`), so with any floor > 0 the list
  /// badge and the alerts screen would have told two different truths. No
  /// production caller ever passed it and no setting ever wrote it; WTM-70's
  /// "set low-stock threshold" is the per-product reorder level on the form.
  static StockAlert? forProduct(Product product) =>
      switch (product.stockStatus) {
        StockStatus.outOfStock => StockAlert(
          product: product,
          level: StockAlertLevel.outOfStock,
        ),
        StockStatus.lowStock => StockAlert(
          product: product,
          level: StockAlertLevel.lowStock,
        ),
        StockStatus.inStock => null,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockAlert &&
          other.product.id == product.id &&
          other.level == level);

  @override
  int get hashCode => Object.hash(product.id, level);

  @override
  String toString() =>
      'StockAlert(${product.id}, ${level.name}, qty=$quantity/$threshold)';
}
