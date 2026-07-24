import 'package:flutter/foundation.dart';

import 'product.dart';
import 'product_inventory_service.dart';
import 'product_repository.dart';

/// Catalog of products backing the Inventory screen (WTM-68) and its Add/Edit
/// form (WTM-69), reads/writes through a [ProductRepository] (WTM-121) — Drift
/// (real, persistent), Sample (demo) or in-memory (tests). Exposes a fresh
/// [ProductInventoryService] view for read-only querying/paging; adds/edits go
/// through [upsert], which persists then notifies. The UI never knows the source.
class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController(this._repository);

  /// Demo/preview catalogue (read-only sample data). Not persisted.
  factory ProductCatalogController.sample() =>
      ProductCatalogController(const SampleProductRepository());

  /// In-memory catalogue for tests, optionally pre-filled.
  factory ProductCatalogController.inMemory([
    Iterable<Product> initial = const [],
  ]) => ProductCatalogController(InMemoryProductRepository(initial));

  final ProductRepository _repository;
  final List<Product> _products = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Current products as an unmodifiable snapshot.
  List<Product> get products => List.unmodifiable(_products);

  /// Number of products in the catalog.
  int get count => _products.length;

  /// A read-only query/paging view over the current products. A new instance is
  /// returned each call so it always reflects the latest mutations.
  ProductInventoryService get service => ProductInventoryService(_products);

  /// Whether [sku] is already used by a product other than [exceptId]
  /// (case-insensitive, trimmed). A blank SKU is never "taken".
  bool isSkuTaken(String sku, {String? exceptId}) {
    final needle = sku.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return _products.any(
      (p) => p.id != exceptId && p.sku.trim().toLowerCase() == needle,
    );
  }

  /// Loads the catalog from the repository (call once when the screen mounts).
  Future<void> hydrate() async {
    final loaded = await _repository.loadAll();
    _products
      ..clear()
      ..addAll(loaded);
    _hydrated = true;
    notifyListeners();
  }

  /// Persist [product] (new id) or replace the existing product with the same
  /// id, then notify. Returns `true` when it replaced an existing product
  /// (edit), `false` when it was appended (add).
  Future<bool> upsert(Product product) async {
    await _repository.upsert(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    final replaced = index >= 0;
    if (replaced) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
    notifyListeners();
    return replaced;
  }
}
