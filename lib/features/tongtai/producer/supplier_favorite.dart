import 'package:flutter/foundation.dart';

/// A supplier the user has starred, plus when they starred it (WTM-65).
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so it
/// is trivially unit-testable and reusable by the store, controller and screens.
/// [addedAt] is the sort key for the Favorites list ("most recently added
/// first").
@immutable
class SupplierFavorite {
  const SupplierFavorite({required this.supplierId, required this.addedAt});

  /// Id of the favorited supplier (matches `Supplier.id`).
  final String supplierId;

  /// When the supplier was added to favorites.
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierFavorite &&
          other.supplierId == supplierId &&
          other.addedAt == addedAt);

  @override
  int get hashCode => Object.hash(supplierId, addedAt);

  @override
  String toString() => 'SupplierFavorite($supplierId @ $addedAt)';
}

/// Orders favorites by most-recently-added first (WTM-65 AC3).
///
/// Primary key is [SupplierFavorite.addedAt] descending; ties break by
/// [SupplierFavorite.supplierId] ascending so equal timestamps still produce a
/// stable, deterministic order. Sorts a copy — the input list is not mutated.
List<SupplierFavorite> sortByMostRecentlyAdded(
  Iterable<SupplierFavorite> favorites,
) {
  final sorted = favorites.toList()
    ..sort((a, b) {
      final byRecency = b.addedAt.compareTo(a.addedAt);
      if (byRecency != 0) return byRecency;
      return a.supplierId.compareTo(b.supplierId);
    });
  return sorted;
}
