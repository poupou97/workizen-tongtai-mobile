import 'package:flutter/foundation.dart';

/// The editable fields of a [Product] (WTM-69). Used both to key form-validation
/// errors and to label entries in a product's change history, so the two stay in
/// sync (one enum, one set of labels).
enum ProductField {
  name,
  sku,
  category,
  description,
  unitPrice,
  quantity,
  reorderLevel,
  images;

  /// Whether the Add/Edit form requires this field (WTM-69 AC5 — validation for
  /// required fields: name, SKU, category, unit price, quantity).
  bool get isRequired => switch (this) {
    ProductField.name ||
    ProductField.sku ||
    ProductField.category ||
    ProductField.unitPrice ||
    ProductField.quantity => true,
    _ => false,
  };

  String get labelEn => switch (this) {
    ProductField.name => 'Name',
    ProductField.sku => 'SKU',
    ProductField.category => 'Category',
    ProductField.description => 'Description',
    ProductField.unitPrice => 'Unit price',
    ProductField.quantity => 'Quantity',
    ProductField.reorderLevel => 'Reorder level',
    ProductField.images => 'Images',
  };

  String get labelVi => switch (this) {
    ProductField.name => 'Tên',
    ProductField.sku => 'SKU',
    ProductField.category => 'Danh mục',
    ProductField.description => 'Mô tả',
    ProductField.unitPrice => 'Đơn giá',
    ProductField.quantity => 'Số lượng',
    ProductField.reorderLevel => 'Mức đặt lại',
    ProductField.images => 'Hình ảnh',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A single field-level change captured when a product is edited (WTM-69 AC4).
///
/// Values are kept as display strings ("89000" -> "95000") so a revision is a
/// self-describing, storage-agnostic record that any UI can render without
/// re-deriving the old value.
@immutable
class ProductFieldChange {
  const ProductFieldChange({
    required this.field,
    required this.before,
    required this.after,
  });

  /// Which field changed.
  final ProductField field;

  /// The value before the edit.
  final String before;

  /// The value after the edit.
  final String after;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductFieldChange &&
          other.field == field &&
          other.before == before &&
          other.after == after);

  @override
  int get hashCode => Object.hash(field, before, after);

  @override
  String toString() =>
      'ProductFieldChange(${field.name}: "$before" -> "$after")';
}

/// One edit event in a product's change history: the set of field [changes] made
/// at a given [timestamp] (WTM-69 AC4). A revision is only recorded when at least
/// one field actually changed, so the history never contains empty entries.
@immutable
class ProductRevision {
  const ProductRevision({required this.timestamp, required this.changes});

  /// When the edit was saved.
  final DateTime timestamp;

  /// The field changes made in this edit.
  final List<ProductFieldChange> changes;

  bool get isEmpty => changes.isEmpty;
  bool get isNotEmpty => changes.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRevision &&
          other.timestamp == timestamp &&
          listEquals(other.changes, changes));

  @override
  int get hashCode => Object.hash(timestamp, Object.hashAll(changes));

  @override
  String toString() =>
      'ProductRevision($timestamp, ${changes.length} change(s))';
}
