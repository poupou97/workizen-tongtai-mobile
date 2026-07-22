import 'package:flutter/foundation.dart';

import 'supplier.dart';

/// One row of a supplier's product-catalog breakdown: a [category] and how many
/// products the supplier offers in it (WTM-64 AC2).
@immutable
class SupplierCategoryCount {
  const SupplierCategoryCount(this.category, this.count);

  /// Product category, e.g. "Electronics".
  final String category;

  /// Number of distinct products in [category].
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierCategoryCount &&
          other.category == category &&
          other.count == count);

  @override
  int get hashCode => Object.hash(category, count);

  @override
  String toString() => 'SupplierCategoryCount($category, $count)';
}

/// Historical transaction summary for a supplier (WTM-64 AC5).
///
/// Captures the two headline signals from the acceptance criteria — order
/// **frequency** ([totalOrders]) and **volume** ([totalVolumeUnits]) — plus a
/// repeat-buyer signal that reflects sourcing reliability.
@immutable
class SupplierTransactionSummary {
  const SupplierTransactionSummary({
    required this.totalOrders,
    required this.totalVolumeUnits,
    required this.repeatBuyerRate,
  });

  /// Lifetime number of fulfilled orders (frequency).
  final int totalOrders;

  /// Lifetime units shipped across all orders (volume).
  final int totalVolumeUnits;

  /// Share of orders from returning buyers, 0.0–1.0.
  final double repeatBuyerRate;

  /// Average units per order, or 0 when the supplier has no order history.
  double get averageOrderVolume =>
      totalOrders == 0 ? 0 : totalVolumeUnits / totalOrders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierTransactionSummary &&
          other.totalOrders == totalOrders &&
          other.totalVolumeUnits == totalVolumeUnits &&
          other.repeatBuyerRate == repeatBuyerRate);

  @override
  int get hashCode =>
      Object.hash(totalOrders, totalVolumeUnits, repeatBuyerRate);
}

/// Comprehensive supplier profile backing the Supplier Detail View (WTM-64).
///
/// Composes the base [Supplier] (name, location, rating, reviews, categories)
/// with the richer detail the acceptance criteria call for: a business
/// [description], [certifications], a product [catalog] breakdown, historical
/// [transactions], and contact details. Kept as a pure, immutable domain model
/// — no Flutter/UI or persistence concerns — so it is trivially unit-testable.
@immutable
class SupplierProfile {
  const SupplierProfile({
    required this.supplier,
    required this.description,
    required this.certifications,
    required this.catalog,
    required this.transactions,
    this.contactEmail,
    this.contactPhone,
  });

  /// The base supplier this profile expands on.
  final Supplier supplier;

  /// Business description / "about" blurb.
  final String description;

  /// Certification labels earned, e.g. ["ISO 9001", "CE"].
  final List<String> certifications;

  /// Per-category product counts (AC2).
  final List<SupplierCategoryCount> catalog;

  /// Historical transaction summary (AC5).
  final SupplierTransactionSummary transactions;

  /// Contact email, or null when unknown.
  final String? contactEmail;

  /// Contact phone, or null when unknown.
  final String? contactPhone;

  // ── Convenience pass-throughs to the base supplier ──────────────────────

  String get id => supplier.id;
  String get name => supplier.name;
  String get location => supplier.location;
  double get rating => supplier.rating;
  int get reviewCount => supplier.reviewCount;

  /// Total products offered across every catalog category.
  int get productCount => catalog.fold(0, (sum, row) => sum + row.count);

  /// Up-to-two-letter monogram used as a placeholder logo (AC1).
  String get initials => supplierInitials(name);

  /// Whether any contact channel is known.
  bool get hasContact => contactEmail != null || contactPhone != null;
}

/// Up to two uppercase initials from a business [name], for a monogram logo.
///
/// Uses the first letters of the first two words; falls back to the first two
/// characters of a single word, or "?" when there is nothing usable.
String supplierInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// Certifications implied by each product category (extra to the baseline
/// "ISO 9001" every supplier carries). Local-first sample mapping.
const Map<String, List<String>> _categoryCertifications = {
  'Electronics': ['CE', 'RoHS'],
  'Smart Home': ['CE', 'RoHS'],
  'Accessories': ['CE'],
  'Apparel': ['OEKO-TEX'],
  'Textiles': ['OEKO-TEX'],
  'Home Goods': ['FSC'],
  'Furniture': ['FSC'],
  'Agriculture': ['HACCP', 'USDA Organic'],
  'Coconut Products': ['HACCP', 'USDA Organic'],
  'Cosmetics': ['GMP', 'FDA'],
};

/// International dialling code for a supplier [country] (sample mapping).
String _dialCode(String country) {
  switch (country) {
    case 'Vietnam':
      return '+84';
    case 'China':
      return '+86';
    case 'Thailand':
      return '+66';
    case 'India':
      return '+91';
    case 'Indonesia':
      return '+62';
    case 'Malaysia':
      return '+60';
    default:
      return '+1';
  }
}

/// Certification labels for a set of product [categories], de-duplicated and
/// alphabetically sorted, always including the baseline "ISO 9001".
List<String> supplierCertifications(List<String> categories) {
  final set = <String>{'ISO 9001'};
  for (final c in categories) {
    set.addAll(_categoryCertifications[c] ?? const <String>[]);
  }
  final list = set.toList()..sort();
  return list;
}

/// Deterministic per-category product-count breakdown for [supplier].
List<SupplierCategoryCount> supplierCatalog(Supplier supplier) {
  return [
    for (var i = 0; i < supplier.categories.length; i++)
      SupplierCategoryCount(
        supplier.categories[i],
        4 +
            ((supplier.reviewCount + supplier.categories[i].length + i * 7) %
                24),
      ),
  ];
}

/// Deterministic historical transaction summary for [supplier].
///
/// Order volume/frequency scale with the supplier's review count and minimum
/// order size; repeat-buyer rate scales with rating. Chosen so that
/// [SupplierTransactionSummary.averageOrderVolume] equals the minimum order.
SupplierTransactionSummary supplierTransactions(Supplier supplier) {
  final totalOrders = supplier.reviewCount + 20;
  return SupplierTransactionSummary(
    totalOrders: totalOrders,
    totalVolumeUnits: totalOrders * supplier.minOrderUnits,
    repeatBuyerRate: (0.5 + (supplier.rating - 4.0) * 0.3).clamp(0.0, 1.0),
  );
}

/// A stable contact email derived from a supplier [name].
String supplierContactEmail(String name) {
  final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return 'sales@${slug.isEmpty ? 'supplier' : slug}.example';
}

/// A stable, plausible contact phone number derived from [supplier].
String supplierContactPhone(Supplier supplier) {
  final dial = _dialCode(supplier.country);
  final local =
      1000000 + (supplier.reviewCount * 137 + supplier.minOrderUnits) % 9000000;
  return '$dial $local';
}

/// Business description / "about" blurb for [supplier].
String _describe(Supplier supplier) {
  final primary = supplier.categories.isEmpty
      ? 'general goods'
      : supplier.categories.first.toLowerCase();
  return '${supplier.name} is a trusted $primary supplier based in '
      '${supplier.location}. They fulfil orders from a minimum of '
      '${supplier.minOrderUnits} units with a typical lead time of '
      '${supplier.leadTime}.';
}

/// Builds a deterministic [SupplierProfile] from a base [Supplier].
///
/// Local-first sample data (ADR-002, no backend): every detail field is derived
/// deterministically from the supplier's own stable fields, so the same
/// supplier always yields the same profile and the whole pipeline is fully
/// unit-testable. A Drift/remote-backed source can later replace this without
/// touching the detail screen.
SupplierProfile buildSupplierProfile(Supplier supplier) {
  return SupplierProfile(
    supplier: supplier,
    description: _describe(supplier),
    certifications: supplierCertifications(supplier.categories),
    catalog: supplierCatalog(supplier),
    transactions: supplierTransactions(supplier),
    contactEmail: supplierContactEmail(supplier.name),
    contactPhone: supplierContactPhone(supplier),
  );
}
