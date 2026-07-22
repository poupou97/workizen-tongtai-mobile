import 'package:flutter/foundation.dart';

import 'product.dart';
import 'product_history.dart';

/// Immutable snapshot of the Add/Edit Product form (WTM-69).
///
/// Numeric fields are held as raw text so the form can validate user input
/// (blank / non-numeric / negative) before parsing. Pure Dart — no Flutter
/// widgets — so all validation and conversion is unit-testable without pumping a
/// screen.
@immutable
class ProductFormData {
  const ProductFormData({
    this.name = '',
    this.sku = '',
    this.category = '',
    this.description = '',
    this.priceText = '',
    this.quantityText = '',
    this.reorderLevelText = '',
    this.imagePaths = const [],
  });

  /// Seed a form from an existing product (edit mode).
  factory ProductFormData.fromProduct(Product product) => ProductFormData(
    name: product.name,
    sku: product.sku,
    category: product.category,
    description: product.description,
    priceText: _numberText(product.pricePerUnit),
    quantityText: product.quantity.toString(),
    reorderLevelText: product.reorderLevel.toString(),
    imagePaths: List.of(product.imagePaths),
  );

  final String name;
  final String sku;
  final String category;
  final String description;
  final String priceText;
  final String quantityText;
  final String reorderLevelText;
  final List<String> imagePaths;

  ProductFormData copyWith({
    String? name,
    String? sku,
    String? category,
    String? description,
    String? priceText,
    String? quantityText,
    String? reorderLevelText,
    List<String>? imagePaths,
  }) {
    return ProductFormData(
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      description: description ?? this.description,
      priceText: priceText ?? this.priceText,
      quantityText: quantityText ?? this.quantityText,
      reorderLevelText: reorderLevelText ?? this.reorderLevelText,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  /// Parsed unit price, or `null` when the text is blank/non-numeric.
  double? get parsedPrice => _tryParseNumber(priceText);

  /// Parsed quantity, or `null` when the text is blank/non-integer.
  int? get parsedQuantity => _tryParseInt(quantityText);

  /// Parsed reorder level; blank is treated as 0 (the field is optional).
  int get parsedReorderLevel => reorderLevelText.trim().isEmpty
      ? 0
      : (_tryParseInt(reorderLevelText) ?? 0);

  /// Field-keyed validation errors (WTM-69 AC5). An empty map means the form is
  /// valid. Only required fields plus numeric-format checks are enforced here;
  /// SKU uniqueness (which needs the catalog) is layered on by the screen.
  Map<ProductField, String> validate() {
    final errors = <ProductField, String>{};

    if (name.trim().isEmpty) {
      errors[ProductField.name] = 'Name is required';
    }
    if (sku.trim().isEmpty) {
      errors[ProductField.sku] = 'SKU is required';
    }
    if (category.trim().isEmpty) {
      errors[ProductField.category] = 'Category is required';
    }

    final price = priceText.trim();
    if (price.isEmpty) {
      errors[ProductField.unitPrice] = 'Unit price is required';
    } else {
      final value = _tryParseNumber(price);
      if (value == null) {
        errors[ProductField.unitPrice] = 'Unit price must be a number';
      } else if (value < 0) {
        errors[ProductField.unitPrice] = 'Unit price cannot be negative';
      }
    }

    final quantity = quantityText.trim();
    if (quantity.isEmpty) {
      errors[ProductField.quantity] = 'Quantity is required';
    } else {
      final value = _tryParseInt(quantity);
      if (value == null) {
        errors[ProductField.quantity] = 'Quantity must be a whole number';
      } else if (value < 0) {
        errors[ProductField.quantity] = 'Quantity cannot be negative';
      }
    }

    final reorder = reorderLevelText.trim();
    if (reorder.isNotEmpty) {
      final value = _tryParseInt(reorder);
      if (value == null) {
        errors[ProductField.reorderLevel] =
            'Reorder level must be a whole number';
      } else if (value < 0) {
        errors[ProductField.reorderLevel] = 'Reorder level cannot be negative';
      }
    }

    return errors;
  }

  /// Whether every required field is present and valid.
  bool get isValid => validate().isEmpty;

  /// Build a [Product] from this form. Callers should check [isValid] first;
  /// unparseable numbers fall back to 0 so this never throws (a best-effort
  /// product is also handy for computing a live change preview).
  Product toProduct({required String id, required DateTime updatedAt}) {
    return Product(
      id: id,
      sku: sku.trim(),
      name: name.trim(),
      category: category.trim(),
      quantity: _tryParseInt(quantityText) ?? 0,
      pricePerUnit: _tryParseNumber(priceText) ?? 0,
      reorderLevel: parsedReorderLevel,
      description: description.trim(),
      imagePaths: List.unmodifiable(imagePaths),
      updatedAt: updatedAt,
    );
  }
}

/// Creates and edits [Product]s from form data, recording a change history on
/// edit (WTM-69 AC4). Stateless — all methods are pure given their inputs.
abstract final class ProductEditor {
  /// Build a brand-new product (add mode). [id] is the caller-assigned id and
  /// [now] both stamps `updatedAt` and starts the (empty) history.
  static Product create(
    ProductFormData data, {
    required String id,
    required DateTime now,
  }) {
    return data.toProduct(id: id, updatedAt: now);
  }

  /// Apply [data] to [original] (edit mode). When any field changed, prepends a
  /// [ProductRevision] to the product's history and stamps [now] as the new
  /// `updatedAt`. When nothing changed, returns [original] untouched — no
  /// phantom revision and no timestamp bump.
  static Product applyEdit(
    Product original,
    ProductFormData data, {
    required DateTime now,
  }) {
    final edited = data.toProduct(id: original.id, updatedAt: now);
    final changes = diff(original, edited);
    if (changes.isEmpty) return original;
    return edited.copyWith(
      history: [
        ProductRevision(timestamp: now, changes: changes),
        ...original.history,
      ],
    );
  }

  /// Field-level differences between [before] and [after], in field-declaration
  /// order. Images are compared by count (a photo set change is recorded as
  /// "2" -> "3") since paths are not meaningful history to a human.
  static List<ProductFieldChange> diff(Product before, Product after) {
    final changes = <ProductFieldChange>[];
    void compare(ProductField field, String a, String b) {
      if (a != b) {
        changes.add(ProductFieldChange(field: field, before: a, after: b));
      }
    }

    compare(ProductField.name, before.name, after.name);
    compare(ProductField.sku, before.sku, after.sku);
    compare(ProductField.category, before.category, after.category);
    compare(ProductField.description, before.description, after.description);
    compare(
      ProductField.unitPrice,
      _numberText(before.pricePerUnit),
      _numberText(after.pricePerUnit),
    );
    compare(
      ProductField.quantity,
      before.quantity.toString(),
      after.quantity.toString(),
    );
    compare(
      ProductField.reorderLevel,
      before.reorderLevel.toString(),
      after.reorderLevel.toString(),
    );
    compare(
      ProductField.images,
      before.imagePaths.length.toString(),
      after.imagePaths.length.toString(),
    );
    return changes;
  }
}

/// Formats a numeric value without a trailing ".0" (e.g. 89000.0 -> "89000").
String _numberText(num value) {
  if (value is int) return value.toString();
  final d = value.toDouble();
  return d == d.roundToDouble() ? d.round().toString() : d.toString();
}

double? _tryParseNumber(String text) => double.tryParse(text.trim());

int? _tryParseInt(String text) => int.tryParse(text.trim());
