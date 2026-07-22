import 'package:flutter/foundation.dart';

/// A sourcing supplier shown in the Producer directory (WTM-63).
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so it
/// is trivially unit-testable and reusable by the search service, screens and
/// (later) any Drift-backed repository.
@immutable
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    required this.minOrderUnits,
    required this.leadTime,
  });

  /// Stable identifier.
  final String id;

  /// Display name, e.g. "TechPro Wholesale".
  final String name;

  /// Human-readable "City, Country", e.g. "Shenzhen, China".
  final String location;

  /// Aggregate rating, 0.0–5.0.
  final double rating;

  /// Number of reviews behind [rating].
  final int reviewCount;

  /// Product categories this supplier serves, e.g. ["Electronics"].
  final List<String> categories;

  /// Minimum order quantity, in units.
  final int minOrderUnits;

  /// Delivery lead time, e.g. "7-14 days".
  final String leadTime;

  /// Country portion of [location] (text after the last comma), trimmed.
  ///
  /// Falls back to the whole string when there is no comma. Used as the
  /// location facet for filtering.
  String get country {
    final comma = location.lastIndexOf(',');
    return comma == -1 ? location.trim() : location.substring(comma + 1).trim();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Supplier && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Supplier($id, $name, $rating★)';
}
