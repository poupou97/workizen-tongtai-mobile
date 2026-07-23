import 'package:flutter/foundation.dart';

/// The editable fields of a [Customer] (WTM-76). Used both to key form-validation
/// errors and to label entries in a customer's change history, so the two stay in
/// sync (one enum, one set of labels) — same pattern as `ProductField` (WTM-69).
enum CustomerField {
  name,
  phone,
  email,
  location,
  addresses,
  segments,
  tags,
  notes;

  /// Whether the Add/Edit form requires this field (WTM-76 AC1 — name and phone
  /// are the minimum a seller needs to reach a customer).
  bool get isRequired => switch (this) {
    CustomerField.name || CustomerField.phone => true,
    _ => false,
  };

  String get labelEn => switch (this) {
    CustomerField.name => 'Name',
    CustomerField.phone => 'Phone',
    CustomerField.email => 'Email',
    CustomerField.location => 'City',
    CustomerField.addresses => 'Addresses',
    CustomerField.segments => 'Segments',
    CustomerField.tags => 'Tags',
    CustomerField.notes => 'Notes',
  };

  String get labelVi => switch (this) {
    CustomerField.name => 'Tên',
    CustomerField.phone => 'Điện thoại',
    CustomerField.email => 'Email',
    CustomerField.location => 'Thành phố',
    CustomerField.addresses => 'Địa chỉ',
    CustomerField.segments => 'Phân khúc',
    CustomerField.tags => 'Thẻ',
    CustomerField.notes => 'Ghi chú',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A single field-level change captured when a customer is edited (WTM-76 AC4).
///
/// Values are kept as display strings so a revision is a self-describing,
/// storage-agnostic record that any UI can render without re-deriving the old
/// value.
@immutable
class CustomerFieldChange {
  const CustomerFieldChange({
    required this.field,
    required this.before,
    required this.after,
  });

  /// Which field changed.
  final CustomerField field;

  /// The value before the edit.
  final String before;

  /// The value after the edit.
  final String after;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerFieldChange &&
          other.field == field &&
          other.before == before &&
          other.after == after);

  @override
  int get hashCode => Object.hash(field, before, after);

  @override
  String toString() =>
      'CustomerFieldChange(${field.name}: "$before" -> "$after")';
}

/// One edit event in a customer's change history: the set of field [changes]
/// made at a given [timestamp] (WTM-76 AC4 — full audit trail). A revision is
/// only recorded when at least one field actually changed, so the history never
/// contains empty entries.
@immutable
class CustomerRevision {
  const CustomerRevision({required this.timestamp, required this.changes});

  /// When the edit was saved.
  final DateTime timestamp;

  /// The field changes made in this edit.
  final List<CustomerFieldChange> changes;

  bool get isEmpty => changes.isEmpty;
  bool get isNotEmpty => changes.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRevision &&
          other.timestamp == timestamp &&
          listEquals(other.changes, changes));

  @override
  int get hashCode => Object.hash(timestamp, Object.hashAll(changes));

  @override
  String toString() =>
      'CustomerRevision($timestamp, ${changes.length} change(s))';
}
