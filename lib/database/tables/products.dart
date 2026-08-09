import 'package:drift/drift.dart';

import 'businesses.dart';
import 'producers.dart';

/// Product entity: Product catalog and inventory management.
@TableIndex(name: 'products_business_id', columns: {#businessId})
@TableIndex(name: 'products_sku', columns: {#sku})
@TableIndex(name: 'products_category', columns: {#category})
@TableIndex(name: 'products_supplier_id', columns: {#supplierId})
class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get sku => text()();
  TextColumn get name => text()();
  // WTM-72: free-text product description, indexed by the products FTS5 table
  // (name + description + category). Nullable/additive so it is backward
  // compatible; added to existing installs via the schema-v3 upgrade step.
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  RealColumn get costPerUnit => real().nullable()();
  RealColumn get listPrice => real()();

  /// Số lượng tồn — **nullable từ v14** (ADR-TON-023): `NULL` nghĩa là loại
  /// sản phẩm này không có tồn kho, KHÔNG phải "hết hàng". Trước v14 cột này
  /// mặc định 0, và chính con số 0 đó là thứ làm Inventory kêu "Hết hàng" cho
  /// một phần mềm.
  RealColumn get totalStock => real().nullable()();

  /// Loại sản phẩm bằng **mã canonical** `ProductKind` (v14). Dòng cũ đọc ra
  /// `physical` — đó là sự thật về chúng, không phải phỏng đoán.
  TextColumn get kind => text().nullable()();
  RealColumn get stockAlertLevel => real().nullable()();
  // WTM-53: ON DELETE CASCADE so deleting a Producer removes the Products it
  // supplies (no orphaned supplier_id references). Nullable rows (no supplier)
  // are unaffected. See DOMAIN-DATA-MODEL.md §Producer↔Product.
  TextColumn get supplierId => text().nullable().references(
    ProducersTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get salesChannels => text().nullable()(); // JSON
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Versioned full-domain snapshot (JSON) — WTM-121, ADR-TON-009 (option B).
  /// Structured columns above stay the source of truth for promoted fields; this
  /// carries the extended domain (e.g. imagePaths) not yet promoted to columns.
  /// Fields graduate out of here to structured columns/child tables on demand.
  TextColumn get domainSnapshot => text().nullable()();

  // ── nguồn ngoài (v24 · WTM-327) ────────────────────────────────────────

  /// Mã ở nguồn: `sku` trong file Excel, id Shopify, item_id Shopee…
  ///
  /// Nhập lại **cùng** một file phải nhận ra bản ghi cũ chứ không sinh bản thứ
  /// hai. Không có cột này thì cách duy nhất là so tên — và tên thì đổi.
  TextColumn get externalId => text().nullable()();

  /// Bản ghi này từ đâu tới — mã canonical `ProvenanceSource`. `null` = dòng
  /// có trước v24, tức là người bán tự nhập; suy ra chứ không đoán.
  TextColumn get provenanceCode => text().nullable()();

  /// Lần nhập nào tạo ra nó (`import_jobs.id`). Đây là thứ cho phép xoá đúng
  /// một lần nhập mà không đụng dữ liệu tự nhập.
  TextColumn get importJobId => text().nullable()();

  TextColumn get brand => text().nullable()();

  /// Ảnh **theo URL**, không nhét binary (§10). `domainSnapshot.imagePaths`
  /// vẫn giữ ảnh cục bộ người bán tự chụp — hai nguồn ảnh khác nhau, và trộn
  /// chúng sẽ làm một lần nhập lại xoá mất ảnh người bán tự thêm.
  TextColumn get imageUrl => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
