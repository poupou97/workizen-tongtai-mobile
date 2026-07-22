import 'package:flutter/foundation.dart';

import 'product.dart';
import 'product_inventory_service.dart';

/// Mutable, in-memory catalog of products backing the Inventory screen (WTM-68)
/// and its Add/Edit form (WTM-69).
///
/// Holds the working set of products and exposes a fresh [ProductInventoryService]
/// view for read-only querying/paging. Adds and edits go through [upsert], which
/// notifies listeners so the list rebuilds. Local-first, no backend (ADR-002);
/// a Drift/remote-backed store can replace the in-memory list later without
/// touching callers.
class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController(Iterable<Product> initial)
    : _products = [...initial];

  /// Convenience: a catalog seeded with the built-in sample products.
  factory ProductCatalogController.sample() =>
      ProductCatalogController(kSampleProducts);

  final List<Product> _products;

  /// Current products as an unmodifiable snapshot.
  List<Product> get products => List.unmodifiable(_products);

  /// Number of products in the catalog.
  int get count => _products.length;

  /// A read-only query/paging view over the current products. A new instance is
  /// returned each call so it always reflects the latest mutations.
  ProductInventoryService get service => ProductInventoryService(_products);

  /// Whether [sku] is already used by a product other than [exceptId]
  /// (case-insensitive, trimmed). Drives the form's SKU-uniqueness validation;
  /// pass the edited product's id as [exceptId] so a product never collides with
  /// itself. A blank SKU is never "taken".
  bool isSkuTaken(String sku, {String? exceptId}) {
    final needle = sku.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return _products.any(
      (p) => p.id != exceptId && p.sku.trim().toLowerCase() == needle,
    );
  }

  /// Insert [product] (new id) or replace the existing product with the same id,
  /// then notify listeners. Returns `true` when it replaced an existing product
  /// (edit), `false` when it was appended (add).
  bool upsert(Product product) {
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
