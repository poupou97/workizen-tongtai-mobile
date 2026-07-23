import 'package:flutter/foundation.dart';

import 'customer_history.dart';

/// Value tier of a customer, derived from lifetime spend (WTM-75 AC: visual
/// indicators for VIP / high-value customers). Mirrors the tiered CRM model in
/// `docs/tongtai/SCREEN-CONSUMER.md`.
///
/// Kept as a domain enum (no colors here) so it stays UI-agnostic and
/// unit-testable; the screen maps it to a color + badge.
enum CustomerTier {
  vip,
  gold,
  silver,
  bronze;

  String get labelEn => switch (this) {
    CustomerTier.vip => 'VIP',
    CustomerTier.gold => 'Gold',
    CustomerTier.silver => 'Silver',
    CustomerTier.bronze => 'Bronze',
  };

  String get labelVi => switch (this) {
    CustomerTier.vip => 'VIP',
    CustomerTier.gold => 'Vàng',
    CustomerTier.silver => 'Bạc',
    CustomerTier.bronze => 'Đồng',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// Whether this tier is treated as high-value and gets a prominent indicator
  /// (WTM-75 AC: visual indicators for VIP / high-value customers).
  bool get isHighValue => this == CustomerTier.vip || this == CustomerTier.gold;
}

/// Lifetime-spend thresholds (in đồng) for the customer value tiers. A customer
/// at or above [kCustomerTierVipMin] is VIP, at or above [kCustomerTierGoldMin]
/// is Gold, at or above [kCustomerTierSilverMin] is Silver, otherwise Bronze.
///
/// Mirrors the USD tiers in `docs/tongtai/SCREEN-CONSUMER.md` (VIP > $1,500,
/// Gold $500–1,500, Silver $100–500, Bronze < $100) expressed in đồng.
const double kCustomerTierVipMin = 30000000; // ≥ 30M ₫
const double kCustomerTierGoldMin = 10000000; // ≥ 10M ₫
const double kCustomerTierSilverMin = 3000000; // ≥ 3M ₫

/// A customer in the CRM directory (WTM-75, extended by WTM-76 Add/Edit).
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so it
/// is trivially unit-testable and reusable by the directory service, screens and
/// (later) any Drift-backed repository.
@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.orderCount,
    required this.totalSpent,
    required this.lastPurchaseDate,
    this.email = '',
    this.addresses = const [],
    this.segments = const [],
    this.tags = const [],
    this.notes = '',
    this.history = const [],
  });

  /// Stable identifier.
  final String id;

  /// Display name, e.g. "Phương Nguyễn".
  final String name;

  /// Contact phone in full form, e.g. "+84912345678". Matched by search but
  /// shown masked in the list (see [maskedPhone]).
  final String phone;

  /// Human-readable city / region, e.g. "Hà Nội". Used as the location facet.
  final String location;

  /// Number of purchases the customer has made — their purchase *frequency*.
  final int orderCount;

  /// Lifetime spend, in Vietnamese đồng — their purchase *volume*, and the basis
  /// for the value [tier].
  final double totalSpent;

  /// When the customer last purchased — their *recency*. `null` for a customer
  /// who has not bought anything yet (e.g. just added via the WTM-76 form).
  final DateTime? lastPurchaseDate;

  /// Contact email; empty when unknown (WTM-76 AC1).
  final String email;

  /// Delivery/contact addresses — a customer can have several (WTM-76 AC2).
  final List<String> addresses;

  /// Audience segments this customer belongs to, e.g. "Loyal Customers"
  /// (WTM-76 AC1; matches the JSON-array `segments` column in the Drift table).
  final List<String> segments;

  /// Seller-defined tags for quick annotation (WTM-76 AC3).
  final List<String> tags;

  /// Free-form seller notes (WTM-76 AC3).
  final String notes;

  /// Edit history, newest first (WTM-76 AC4 — full audit trail).
  final List<CustomerRevision> history;

  /// Copy with individual field overrides. [lastPurchaseDate] cannot be cleared
  /// via copyWith (pass-through when omitted) — no current caller needs that.
  Customer copyWith({
    String? name,
    String? phone,
    String? location,
    int? orderCount,
    double? totalSpent,
    DateTime? lastPurchaseDate,
    String? email,
    List<String>? addresses,
    List<String>? segments,
    List<String>? tags,
    String? notes,
    List<CustomerRevision>? history,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      email: email ?? this.email,
      addresses: addresses ?? this.addresses,
      segments: segments ?? this.segments,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      history: history ?? this.history,
    );
  }

  /// Value tier derived from [totalSpent] against the tier thresholds: VIP is
  /// the highest, Bronze the lowest.
  CustomerTier get tier {
    if (totalSpent >= kCustomerTierVipMin) return CustomerTier.vip;
    if (totalSpent >= kCustomerTierGoldMin) return CustomerTier.gold;
    if (totalSpent >= kCustomerTierSilverMin) return CustomerTier.silver;
    return CustomerTier.bronze;
  }

  /// Privacy-masked phone for list display (WTM-75 business rule: phone numbers
  /// masked except in the detail view). Keeps the first six characters and the
  /// last three, hiding the middle — e.g. "+84912345678" -> "+84912***678".
  /// Numbers too short to mask meaningfully are returned unchanged.
  String get maskedPhone {
    final raw = phone.trim();
    if (raw.length <= 9) return raw;
    return '${raw.substring(0, 6)}***${raw.substring(raw.length - 3)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Customer && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Customer($id, $name, ${tier.labelEn})';
}
