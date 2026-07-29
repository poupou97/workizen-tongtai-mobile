import 'package:flutter/foundation.dart';

import '../core/capability_context_provider.dart';
import 'product.dart';
import 'product_repository.dart';

/// Inventory-capability slice of the business snapshot (WTM-129/131).
@immutable
class InventorySummary {
  const InventorySummary({
    required this.productCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.stockValue,
  });

  static const InventorySummary empty = InventorySummary(
    productCount: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    stockValue: 0,
  );

  final int productCount;
  final int lowStockCount;
  final int outOfStockCount;

  /// On-hand stock value in đồng (Σ price × quantity).
  final double stockValue;

  factory InventorySummary.from(List<Product> products) {
    var low = 0;
    var out = 0;
    var value = 0.0;
    for (final p in products) {
      value += p.stockValue;
      switch (p.stockStatus) {
        case StockStatus.lowStock:
          low += 1;
        case StockStatus.outOfStock:
          out += 1;
        case StockStatus.inStock:
          break;
      }
    }
    return InventorySummary(
      productCount: products.length,
      lowStockCount: low,
      outOfStockCount: out,
      stockValue: value,
    );
  }
}

/// The Inventory capability's Context Provider (WTM-131) — loads products from
/// the repository and produces the [InventorySummary] slice for BusinessContext.
class InventoryContextProvider
    implements CapabilityContextProvider<InventorySummary> {
  const InventoryContextProvider(this._repository);

  final ProductRepository _repository;

  @override
  Future<InventorySummary> load() async =>
      InventorySummary.from(await _repository.loadAll());
}
