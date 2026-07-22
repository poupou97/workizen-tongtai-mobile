import 'package:flutter/foundation.dart';

import 'supplier.dart';
import 'supplier_favorite.dart';
import 'supplier_favorites_store.dart';

/// Reactive, in-memory view of the user's favorite suppliers (WTM-65).
///
/// Holds the current favorites so the UI can render heart state and filter
/// results synchronously, while delegating durable persistence + cloud-sync to
/// a [SupplierFavoritesStore]. A single controller is shared across the search
/// screen and the Favorites list so a toggle in one place is reflected
/// everywhere. Extends [ChangeNotifier] so widgets can rebuild on change.
class SupplierFavoritesController extends ChangeNotifier {
  SupplierFavoritesController(this._store);

  /// Convenience: a controller backed by an in-memory store, for standalone
  /// screen previews and tests that do not need SQLite.
  factory SupplierFavoritesController.inMemory([
    Iterable<SupplierFavorite>? seed,
  ]) => SupplierFavoritesController(InMemorySupplierFavoritesStore(seed));

  final SupplierFavoritesStore _store;

  /// supplierId -> when it was favorited.
  final Map<String, DateTime> _addedAt = {};

  bool _isLoaded = false;

  /// Whether [load] has completed at least once.
  bool get isLoaded => _isLoaded;

  /// Number of favorited suppliers.
  int get count => _addedAt.length;

  /// The set of currently favorited supplier ids.
  Set<String> get favoriteIds => _addedAt.keys.toSet();

  /// Whether [supplierId] is currently a favorite.
  bool isFavorite(String supplierId) => _addedAt.containsKey(supplierId);

  /// Hydrate the in-memory state from the backing store. Safe to call more than
  /// once (e.g. on screen re-entry); it replaces the current snapshot.
  Future<void> load() async {
    final all = await _store.loadAll();
    _addedAt
      ..clear()
      ..addEntries(all.map((f) => MapEntry(f.supplierId, f.addedAt)));
    _isLoaded = true;
    notifyListeners();
  }

  /// Add or remove [supplierId] with one tap (WTM-65 AC1). Persists through the
  /// store and notifies listeners. Returns `true` if the supplier is a favorite
  /// afterwards, `false` if it was removed. [now] is injectable for tests.
  Future<bool> toggle(String supplierId, {DateTime? now}) async {
    if (isFavorite(supplierId)) {
      _addedAt.remove(supplierId);
      notifyListeners();
      await _store.remove(supplierId);
      return false;
    }
    final timestamp = now ?? DateTime.now();
    _addedAt[supplierId] = timestamp;
    notifyListeners();
    await _store.add(supplierId, addedAt: timestamp);
    return true;
  }

  /// The favorited suppliers drawn from [directory], ordered most-recently-added
  /// first (WTM-65 AC3). Ids with no matching supplier in [directory] are
  /// dropped (e.g. a supplier that has since left the directory).
  List<Supplier> favoriteSuppliers(Iterable<Supplier> directory) {
    final byId = {for (final s in directory) s.id: s};
    final favorites = <SupplierFavorite>[
      for (final entry in _addedAt.entries)
        if (byId.containsKey(entry.key))
          SupplierFavorite(supplierId: entry.key, addedAt: entry.value),
    ];
    return [
      for (final f in sortByMostRecentlyAdded(favorites)) byId[f.supplierId]!,
    ];
  }

  /// Keep only favorited suppliers from [suppliers], preserving the input order
  /// (WTM-65 AC4: "filter search results to show only favorites"). Unlike
  /// [favoriteSuppliers] this does not re-sort — the caller's ranking is kept.
  List<Supplier> onlyFavorites(Iterable<Supplier> suppliers) => [
    for (final s in suppliers)
      if (isFavorite(s.id)) s,
  ];
}
