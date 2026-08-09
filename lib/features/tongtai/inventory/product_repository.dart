import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/domain_snapshot.dart';
import '../core/local_workspace.dart';
import '../core/provenance.dart';
import 'product.dart';
import 'product_inventory_service.dart' show kSampleProducts;

/// Decides the source of catalog data (WTM-121) — Drift (real), Sample (demo) or
/// in-memory (tests). The controller depends on this seam, not on Drift.
abstract class ProductRepository {
  Future<List<Product>> loadAll();

  /// Insert a new product or replace the one with the same id.
  Future<void> upsert(Product product);

  /// [upsert] for a whole collection, as ONE write (WTM-149 device defect 2) —
  /// see `CustomerRepository.upsertAll` for why the seam exists.
  Future<void> upsertAll(Iterable<Product> products);

  /// Deletes every row whose id starts with [prefix] — the sample-data
  /// lifecycle hook (WTM-144/ADR-TON-014): sample records carry the
  /// `sample-` id prefix so they can be removed without touching user data.
  Future<void> deleteByIdPrefix(String prefix);

  /// Removes **every** record of this business (WTM-164 restore Replace).
  ///
  /// Separate from `deleteByIdPrefix('')` on purpose: "wipe the business" is a
  /// destructive operation that should be spelled out at the call site, not
  /// achieved by an empty-prefix trick nobody reading the code would notice.
  Future<void> deleteAll();
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
        .insertOnConflictUpdate(_companion(p, businessId));
  }

  @override
  Future<void> upsertAll(Iterable<Product> products) async {
    final rows = products.toList(growable: false);
    if (rows.isEmpty) return;
    final businessId = await _workspace.ensureBusinessId(_db);
    // One batch = one transaction = one fsync, instead of one per row.
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.productsTable, [
        for (final p in rows) _companion(p, businessId),
      ]),
    );
  }

  /// The single row mapping, shared by [upsert] and [upsertAll] so the bulk
  /// path can never drift from the single-row path.
  ProductsTableCompanion _companion(Product p, String businessId) =>
      ProductsTableCompanion.insert(
        id: p.id,
        businessId: businessId,
        sku: p.sku,
        name: p.name,
        listPrice: p.pricePerUnit,
        // WTM-204: the column has existed since v1; the domain finally
        // carries it. Null-aware — absent means "not entered", never 0.
        costPerUnit: Value(p.costPrice),
        category: Value(p.category),
        description: Value(p.description),
        // `null` đi thẳng xuống cột: "không áp dụng" phải sống sót qua lần
        // đóng app, nếu quy về 0 thì mở lại app sản phẩm số sẽ "hết hàng".
        totalStock: Value(p.quantity?.toDouble()),
        kind: Value(p.kind.code),
        stockAlertLevel: Value(p.reorderLevel?.toDouble()),
        domainSnapshot: Value(
          encodeDomainSnapshot({
            'imagePaths': p.imagePaths,
          }, version: _snapshotVersion),
        ),
        updatedAt: Value(p.updatedAt),
        // v24 (WTM-327) — nguồn ngoài. Phải đi qua ĐÂY chứ không phải một
        // đường ghi riêng của importer: cùng một hàng đi vào bằng hai cửa thì
        // sớm muộn hai cửa nói hai chuyện khác nhau.
        externalId: Value(p.externalId),
        brand: Value(p.brand),
        imageUrl: Value(p.imageUrl),
        provenanceCode: Value(p.provenance.code),
        importJobId: Value(p.importJobId),
      );

  Product _toProduct(ProductsTableData row) => Product(
    id: row.id,
    sku: row.sku,
    name: row.name,
    category: row.category ?? '',
    quantity: row.totalStock?.round(),
    pricePerUnit: row.listPrice,
    costPrice: row.costPerUnit,
    reorderLevel: row.stockAlertLevel?.round(),
    kind: ProductKind.fromCode(row.kind),
    updatedAt: row.updatedAt,
    description: row.description ?? '',
    imagePaths: snapshotStringList(
      decodeDomainSnapshot(row.domainSnapshot),
      'imagePaths',
    ),
    externalId: row.externalId,
    brand: row.brand,
    imageUrl: row.imageUrl,
    // Mã lạ ⇒ `manual`. Đây là chỗ DUY NHẤT trong repo rơi về mặc định thay vì
    // bỏ dòng, và có lý do: dòng có trước v24 **không có** cột này, và chúng
    // đúng là do người bán tự nhập. Bỏ dòng ở đây sẽ xoá sạch danh mục của
    // những người đã dùng app từ trước.
    provenance:
        ProvenanceSource.fromCode(row.provenanceCode) ??
        ProvenanceSource.manual,
    importJobId: row.importJobId,
  );
  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(_db.productsTable)..where(
          (t) => t.businessId.equals(businessId) & t.id.like('$prefix%'),
        ))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.productsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
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
  Future<void> upsertAll(Iterable<Product> products) async {
    // Demo data is read-only — do not persist.
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    // Demo fixtures are read-only — nothing to delete.
  }

  @override
  Future<void> deleteAll() async {
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
  Future<void> upsertAll(Iterable<Product> products) async {
    for (final p in products) {
      await upsert(p);
    }
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async =>
      _products.removeWhere((x) => x.id.startsWith(prefix));

  @override
  Future<void> deleteAll() async => _products.clear();
}
