import 'package:flutter/foundation.dart';

import 'product_history.dart';

/// Stock-level health of a product, derived from on-hand quantity against its
/// reorder threshold (WTM-68 AC: color-coded in stock / low / out).
///
/// Kept as a domain enum (no colors here) so it stays UI-agnostic and
/// unit-testable; the screen maps it to a color + label.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get labelEn => switch (this) {
    StockStatus.inStock => 'In stock',
    StockStatus.lowStock => 'Low stock',
    StockStatus.outOfStock => 'Out of stock',
  };

  String get labelVi => switch (this) {
    StockStatus.inStock => 'Còn hàng',
    StockStatus.lowStock => 'Sắp hết hàng',
    StockStatus.outOfStock => 'Hết hàng',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A product in the sourcing inventory (WTM-68).
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so it
/// is trivially unit-testable and reusable by the inventory service, screens and
/// (later) any Drift-backed repository.
@immutable
class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.quantity,
    required this.pricePerUnit,
    required this.reorderLevel,
    required this.updatedAt,
    this.description = '',
    this.imagePaths = const [],
    this.history = const [],
  });

  /// Stable identifier.
  final String id;

  /// Stock-keeping unit code, e.g. "SKU-EL-001".
  final String sku;

  /// Display name, e.g. "Quạt mini cầm tay".
  final String name;

  /// Product category, e.g. "Electronics".
  final String category;

  /// On-hand quantity, in units.
  final int quantity;

  /// Price per unit, in Vietnamese đồng.
  final double pricePerUnit;

  /// Low-stock threshold, in units: at or below this (but above zero) the
  /// product is flagged [StockStatus.lowStock].
  final int reorderLevel;

  /// When the product's stock/price was last updated.
  final DateTime updatedAt;

  /// Long-form product description. Supports markdown formatting (WTM-69 AC3).
  /// Defaults to empty so existing catalog data stays valid.
  final String description;

  /// Local file paths of product photos, uploaded or camera-captured
  /// (WTM-69 AC2). Empty by default.
  final List<String> imagePaths;

  /// Chronological edit history, most-recent revision first (WTM-69 AC4). Empty
  /// for a product that has never been edited.
  final List<ProductRevision> history;

  /// Copy with individual field overrides. Used by the Add/Edit form to produce
  /// an updated product (WTM-69) without mutating the original.
  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    int? quantity,
    double? pricePerUnit,
    int? reorderLevel,
    DateTime? updatedAt,
    String? description,
    List<String>? imagePaths,
    List<ProductRevision>? history,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      history: history ?? this.history,
    );
  }

  /// Stock health derived from [quantity] vs. [reorderLevel]: zero on hand is
  /// out of stock; at or below the reorder level is low; otherwise in stock.
  StockStatus get stockStatus {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= reorderLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  /// Total on-hand value = unit price × quantity (in đồng).
  double get stockValue => pricePerUnit * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product($id, $sku, $name, qty=$quantity)';

  /// The same record under a different id — the sample-seeding remap hook
  /// (WTM-144/ADR-TON-014).
  Product withId(String newId) => Product(
    id: newId,
    sku: sku,
    name: name,
    category: category,
    quantity: quantity,
    pricePerUnit: pricePerUnit,
    reorderLevel: reorderLevel,
    updatedAt: updatedAt,
    description: description,
    imagePaths: imagePaths,
    history: history,
  );
}
