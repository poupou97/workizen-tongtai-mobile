import 'package:flutter/foundation.dart';

import 'customer.dart';
import 'customer_history.dart';

/// Suggested audience segments offered as quick-pick chips in the Add/Edit form
/// (WTM-76 AC1). Mirrors the segment vocabulary in
/// `docs/01-PRODUCT/screens/SCREEN-CONSUMER.md`; the seller can also type any
/// custom segment.
const List<String> kTongtaiSegmentSuggestions = [
  'New Customer',
  'Loyal Customers',
  'High Value',
  'Occasional Buyers',
  'Social Commerce',
];

/// Immutable snapshot of the Add/Edit Customer form (WTM-76).
///
/// Pure Dart — no Flutter widgets — so all validation and conversion is
/// unit-testable without pumping a screen (same pattern as `ProductFormData`,
/// WTM-69). Multi-value fields ([addresses], [segments], [tags]) are held as
/// lists; blank address entries are dropped on save rather than rejected.
@immutable
class CustomerFormData {
  const CustomerFormData({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.location = '',
    this.addresses = const [],
    this.segments = const [],
    this.tags = const [],
    this.notes = '',
  });

  /// Seed a form from an existing customer (edit mode).
  factory CustomerFormData.fromCustomer(Customer customer) => CustomerFormData(
    name: customer.name,
    phone: customer.phone,
    email: customer.email,
    location: customer.location,
    addresses: List.of(customer.addresses),
    segments: List.of(customer.segments),
    tags: List.of(customer.tags),
    notes: customer.notes,
  );

  final String name;
  final String phone;
  final String email;
  final String location;
  final List<String> addresses;
  final List<String> segments;
  final List<String> tags;
  final String notes;

  CustomerFormData copyWith({
    String? name,
    String? phone,
    String? email,
    String? location,
    List<String>? addresses,
    List<String>? segments,
    List<String>? tags,
    String? notes,
  }) {
    return CustomerFormData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      addresses: addresses ?? this.addresses,
      segments: segments ?? this.segments,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  /// Address entries with blanks removed and whitespace trimmed — what actually
  /// gets saved (WTM-76 AC2: multiple address entries).
  List<String> get cleanedAddresses => [
    for (final address in addresses)
      if (address.trim().isNotEmpty) address.trim(),
  ];

  /// Field-keyed validation errors (WTM-76 AC1). An empty map means the form is
  /// valid. Name and phone are required; email is optional but must look like
  /// an email when present. Duplicate detection (which needs the directory) is
  /// layered on by the screen — see [findCustomerDuplicates].
  Map<CustomerField, String> validate() {
    final errors = <CustomerField, String>{};

    if (name.trim().isEmpty) {
      errors[CustomerField.name] = 'Name is required';
    }

    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) {
      errors[CustomerField.phone] = 'Phone is required';
    } else if (normalizeCustomerPhone(trimmedPhone).length < 7 ||
        !RegExp(r'^[+0-9][0-9 .\-()]*$').hasMatch(trimmedPhone)) {
      errors[CustomerField.phone] = 'Enter a valid phone number';
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      errors[CustomerField.email] = 'Enter a valid email address';
    }

    return errors;
  }

  /// Whether every required field is present and valid.
  bool get isValid => validate().isEmpty;

  /// Build a [Customer] from this form. Purchase stats ([orderCount],
  /// [totalSpent], [lastPurchaseDate]) and [history] are not form-editable —
  /// they carry over from the original in edit mode and start at zero/empty for
  /// a new customer.
  Customer toCustomer({
    required String id,
    int orderCount = 0,
    double totalSpent = 0,
    DateTime? lastPurchaseDate,
    List<CustomerRevision> history = const [],
  }) {
    return Customer(
      id: id,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      location: location.trim(),
      addresses: List.unmodifiable(cleanedAddresses),
      segments: List.unmodifiable(segments),
      tags: List.unmodifiable(tags),
      notes: notes.trim(),
      orderCount: orderCount,
      totalSpent: totalSpent,
      lastPurchaseDate: lastPurchaseDate,
      history: history,
    );
  }
}

/// Creates and edits [Customer]s from form data, recording a change history on
/// edit (WTM-76 AC4). Stateless — all methods are pure given their inputs.
abstract final class CustomerEditor {
  /// Build a brand-new customer (add mode) with zeroed purchase stats.
  static Customer create(CustomerFormData data, {required String id}) {
    return data.toCustomer(id: id);
  }

  /// Apply [data] to [original] (edit mode). When any field changed, prepends a
  /// [CustomerRevision] to the customer's history (audit trail, newest first)
  /// and carries the purchase stats over untouched. When nothing changed,
  /// returns [original] as-is — no phantom revision.
  static Customer applyEdit(
    Customer original,
    CustomerFormData data, {
    required DateTime now,
  }) {
    final edited = data.toCustomer(
      id: original.id,
      orderCount: original.orderCount,
      totalSpent: original.totalSpent,
      lastPurchaseDate: original.lastPurchaseDate,
      history: original.history,
    );
    final changes = diff(original, edited);
    if (changes.isEmpty) return original;
    return edited.copyWith(
      history: [
        CustomerRevision(timestamp: now, changes: changes),
        ...original.history,
      ],
    );
  }

  /// Field-level differences between [before] and [after], in field-declaration
  /// order. Multi-value fields are compared (and recorded) as joined display
  /// strings so a revision reads naturally, e.g.
  /// `Addresses: "12 Hàng Bài" -> "12 Hàng Bài | 5 Lê Lợi"`.
  static List<CustomerFieldChange> diff(Customer before, Customer after) {
    final changes = <CustomerFieldChange>[];
    void compare(CustomerField field, String a, String b) {
      if (a != b) {
        changes.add(CustomerFieldChange(field: field, before: a, after: b));
      }
    }

    compare(CustomerField.name, before.name, after.name);
    compare(CustomerField.phone, before.phone, after.phone);
    compare(CustomerField.email, before.email, after.email);
    compare(CustomerField.location, before.location, after.location);
    compare(
      CustomerField.addresses,
      before.addresses.join(' | '),
      after.addresses.join(' | '),
    );
    compare(
      CustomerField.segments,
      before.segments.join(', '),
      after.segments.join(', '),
    );
    compare(CustomerField.tags, before.tags.join(', '), after.tags.join(', '));
    compare(CustomerField.notes, before.notes, after.notes);
    return changes;
  }
}

/// Normalizes a phone number for duplicate matching (WTM-76 AC5): keeps digits
/// only, then strips the Vietnamese country prefix ("84") and/or the domestic
/// leading zero — so "+84 912 345 678", "84912345678" and "0912345678" all
/// normalize to "912345678".
String normalizeCustomerPhone(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('84') && digits.length >= 10) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Customers in [all] that look like duplicates of the entry being typed
/// (WTM-76 AC5): same normalized phone (when both have one) or same
/// case-insensitive trimmed name. [exceptId] excludes the customer being edited
/// so a record never collides with itself.
List<Customer> findCustomerDuplicates(
  Iterable<Customer> all, {
  required String name,
  required String phone,
  String? exceptId,
}) {
  final needleName = name.trim().toLowerCase();
  final needlePhone = normalizeCustomerPhone(phone);
  if (needleName.isEmpty && needlePhone.isEmpty) return const [];
  return [
    for (final customer in all)
      if (customer.id != exceptId &&
          ((needlePhone.isNotEmpty &&
                  normalizeCustomerPhone(customer.phone) == needlePhone) ||
              (needleName.isNotEmpty &&
                  customer.name.trim().toLowerCase() == needleName)))
        customer,
  ];
}
