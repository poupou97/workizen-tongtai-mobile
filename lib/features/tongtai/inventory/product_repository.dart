import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/domain_snapshot.dart';
import '../core/local_workspace.dart';
import 'product.dart';
import 'product_inventory_service.dart' show kSampleProducts;

/// Decides the source of catalog data (WTM-121) — Drift (real), Sample (demo) or
/// in-memory (tests). The controller depends on this seam, not on Drift.
abstract class ProductRepository {
  Future<List<Product>> loadAll();

  /// Insert a new product or replace the one with the same id.
  Future<void> upsert(Product product);

  /// Deletes every row whose id starts with [prefix] — the sample-data
  /// lifecycle hook (WTM-144/ADR-TON-014): sample records carry the
  /// `sample-` id prefix so they can be removed without touching user data.
  Future<void> deleteByIdPrefix(String prefix);
}

/// Real, persistent catalog for the local business (WTM-121).
///
/// **Structured columns + versioned domain snapshot** (ADR-TON-009, option B):
/// core fields (sku/name/category/description/price/stock) live in structured
/// columns — the source of truth for those (promoted) fields; extended fields not
/// yet promoted (imagePaths) ride in `domain_snapshot` as versioned JSON. Audit
/// history is not persisted (it is regenerable session state).
class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db, {this._workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  /// Current snapshot version — bump + migrate in [_extendedFrom] when the shape
  /// of the JSON changes.
  static const int _snapshotVersion = 1;

  @override
  Future<List<Product>> loadAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.productsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(_toProduct).toList();
  }

  @override
  Future<void> upsert(Product p) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db
        .into(_db.productsTable)
        .insertOnConflictUpdate(
          ProductsTableCompanion.insert(
            id: p.id,
            businessId: businessId,
            sku: p.sku,
            name: p.name,
            listPrice: p.pricePerUnit,
            category: Value(p.category),
            description: Value(p.description),
            totalStock: Value(p.quantity.toDouble()),
            stockAlertLevel: Value(p.reorderLevel.toDouble()),
            domainSnapshot: Value(
              encodeDomainSnapshot({
                'imagePaths': p.imagePaths,
              }, version: _snapshotVersion),
            ),
            updatedAt: Value(p.updatedAt),
          ),
        );
  }

  Product _toProduct(ProductsTableData row) => Product(
    id: row.id,
    sku: row.sku,
    name: row.name,
    category: row.category ?? '',
    quantity: row.totalStock.round(),
    pricePerUnit: row.listPrice,
    reorderLevel: (row.stockAlertLevel ?? 0).round(),
    updatedAt: row.updatedAt,
    description: row.description ?? '',
    imagePaths: snapshotStringList(
      decodeDomainSnapshot(row.domainSnapshot),
      'imagePaths',
    ),
  );
  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(_db.productsTable)..where(
          (t) => t.businessId.equals(businessId) & t.id.like('$prefix%'),
        ))
        .go();
  }
}

/// Demo / Preview source (WTM-121): the built-in sample catalogue, **read-only**
/// — used only in Demo Mode, never written to the user's database.
class SampleProductRepository implements ProductRepository {
  const SampleProductRepository();

  @override
  Future<List<Product>> loadAll() async => List.of(kSampleProducts);

  @override
  Future<void> upsert(Product product) async {
    // Demo data is read-only — do not persist.
  }
  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    // Demo fixtures are read-only — nothing to delete.
  }
}

/// In-memory source for tests (mutable, no database).
class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository([Iterable<Product> initial = const []])
    : _products = [...initial];

  final List<Product> _products;

  @override
  Future<List<Product>> loadAll() async => List.of(_products);

  @override
  Future<void> upsert(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async =>
      _products.removeWhere((x) => x.id.startsWith(prefix));
}
