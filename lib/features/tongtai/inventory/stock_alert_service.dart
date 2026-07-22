import 'product.dart';
import 'stock_alert.dart';

/// Stock-level alert engine (WTM-70): given the current product catalog it
/// derives the set of low-stock / out-of-stock alerts, ready for the Inventory
/// alert banner and the Stock Alerts screen to notify the user.
///
/// Pure Dart over an in-memory list — local-first, no backend (ADR-002) — so the
/// counts and ordering compute synchronously and are trivially unit-testable. A
/// Drift/remote-backed data source can later feed the same engine unchanged.
class StockAlertService {
  StockAlertService(Iterable<Product> products, {this.minimumThreshold = 0})
    : assert(minimumThreshold >= 0, 'minimumThreshold cannot be negative'),
      _products = List.unmodifiable(products);

  final List<Product> _products;

  /// Catalog-wide low-stock threshold floor (WTM-70: "set low-stock threshold").
  /// A product alerts when its quantity is at or below the larger of its own
  /// [Product.reorderLevel] and this value. Default 0 = per-product thresholds
  /// only, matching [Product.stockStatus].
  final int minimumThreshold;

  List<StockAlert>? _cache;

  /// Every raised alert, most-urgent first: out-of-stock before low-stock, then
  /// by [StockAlert.shortfall] descending (furthest below threshold first), with
  /// a stable tiebreak by product name then id. Computed once and memoized.
  List<StockAlert> get alerts {
    return _cache ??= _compute();
  }

  List<StockAlert> _compute() {
    final list = <StockAlert>[
      for (final p in _products)
        ?StockAlert.forProduct(p, minimumThreshold: minimumThreshold),
    ];
    list.sort(_compare);
    return List.unmodifiable(list);
  }

  int _compare(StockAlert a, StockAlert b) {
    // Enum index is ordered most-urgent first (outOfStock = 0).
    final byLevel = a.level.index.compareTo(b.level.index);
    if (byLevel != 0) return byLevel;
    final byShortfall = b.shortfall.compareTo(a.shortfall); // descending
    if (byShortfall != 0) return byShortfall;
    final byName = a.product.name.toLowerCase().compareTo(
      b.product.name.toLowerCase(),
    );
    if (byName != 0) return byName;
    return a.product.id.compareTo(b.product.id);
  }

  /// Alerts for products that are completely out of stock.
  List<StockAlert> get outOfStockAlerts => [
    for (final a in alerts)
      if (a.level == StockAlertLevel.outOfStock) a,
  ];

  /// Alerts for products that are low (but not yet out of) stock.
  List<StockAlert> get lowStockAlerts => [
    for (final a in alerts)
      if (a.level == StockAlertLevel.lowStock) a,
  ];

  /// Number of products completely out of stock.
  int get outOfStockCount => outOfStockAlerts.length;

  /// Number of products at or below their threshold but not yet out of stock.
  int get lowStockCount => lowStockAlerts.length;

  /// Total number of raised alerts.
  int get totalCount => alerts.length;

  /// Whether any alert is currently raised.
  bool get hasAlerts => alerts.isNotEmpty;
}
