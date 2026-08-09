import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import '../core/provenance.dart';
import 'commerce_models.dart';

/// Kho của miền thương mại chuẩn hoá — WTM-327.
///
/// ## Xoá theo LẦN NHẬP, không theo "demo"
///
/// Founder §22: đặt lại dữ liệu demo thương mại phải **xoá riêng dataset
/// demo** và **không xoá dữ liệu thật**.
///
/// Cách làm rẻ tiền là gắn cờ `isDemo` lên từng dòng rồi xoá theo cờ. Nó hỏng
/// ngay lần đầu người bán sửa một sản phẩm demo thành sản phẩm thật của họ —
/// cờ vẫn là `true`, và lần reset sau xoá mất việc của họ.
///
/// Ở đây xoá theo `importJobId`: *"bỏ lần nhập ngày 9/8 đi"* là một câu nói
/// đúng nghĩa, và nó không đụng gì tới dòng người bán tự tạo.
///
/// Cùng kỷ luật WTM-307: **mỗi đường xoá phải khai phạm vi của nó.**
class CommerceRepository {
  CommerceRepository(this._db, {this.workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace workspace;

  // ── import job ───────────────────────────────────────────────────────────

  Future<void> saveImportJob(ImportJob job) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db
        .into(_db.importJobsTable)
        .insertOnConflictUpdate(
          ImportJobsTableCompanion.insert(
            id: job.id,
            businessId: businessId,
            sourceCode: job.source.code,
            sourceVendor: Value(job.sourceVendor),
            sourceFile: Value(job.sourceFile),
            sourceAccount: Value(job.sourceAccount),
            sourceChecksum: Value(job.sourceChecksum),
            recordCounts: Value(jsonEncode(job.recordCounts)),
            warnings: Value(jsonEncode(job.warnings)),
            isDemo: Value(job.isDemo),
            importedAt: Value(job.importedAt),
          ),
        );
  }

  Future<List<ImportJob>> loadImportJobs() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.importJobsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]))
            .get();
    return rows.map(_toImportJob).nonNulls.toList();
  }

  /// Lần nhập gần nhất của cùng một nội dung file. `null` = chưa nhập bao giờ.
  ///
  /// So bằng **checksum**, không bằng tên: người bán đổi tên file rồi nhập lại
  /// vẫn là cùng một dữ liệu, và một tên khác không biến nó thành dữ liệu mới.
  Future<ImportJob?> findByChecksum(String checksum) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final row =
        await (_db.select(_db.importJobsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.sourceChecksum.equals(checksum),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.importedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toImportJob(row);
  }

  // ── variant ──────────────────────────────────────────────────────────────

  Future<void> upsertVariants(Iterable<ProductVariant> variants) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows = variants.toList(growable: false);
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      for (final v in rows) {
        batch.insert(
          _db.productVariantsTable,
          ProductVariantsTableCompanion.insert(
            id: v.id,
            businessId: businessId,
            productId: v.productId,
            name: v.name,
            sku: v.sku,
            option1Name: Value(v.option1Name),
            option1Value: Value(v.option1Value),
            option2Name: Value(v.option2Name),
            option2Value: Value(v.option2Value),
            costPrice: Value(v.costPrice),
            sellingPrice: Value(v.sellingPrice),
            quantity: Value(v.quantity),
            externalId: Value(v.externalId),
            provenanceCode: Value(v.provenance.code),
            importJobId: Value(v.importJobId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ProductVariant>> loadVariants({String? productId}) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final query = _db.select(_db.productVariantsTable)
      ..where((t) => t.businessId.equals(businessId));
    if (productId != null) {
      query.where((t) => t.productId.equals(productId));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return (await query.get()).map(_toVariant).nonNulls.toList();
  }

  // ── báo giá ──────────────────────────────────────────────────────────────

  Future<void> upsertQuotes(Iterable<SupplierQuote> quotes) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows = quotes.toList(growable: false);
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      for (final q in rows) {
        batch.insert(
          _db.supplierQuotesTable,
          SupplierQuotesTableCompanion.insert(
            id: q.id,
            businessId: businessId,
            productId: q.productId,
            supplierId: Value(q.supplierId),
            supplierName: q.supplierName,
            platform: Value(q.platform?.code),
            country: Value(q.country),
            sourceUrl: Value(q.sourceUrl),
            rating: Value(q.rating),
            unitCost: q.unitCost,
            currency: Value(q.currency),
            minimumOrderQuantity: Value(q.minimumOrderQuantity),
            leadTimeDays: Value(q.leadTimeDays),
            paymentTerms: Value(q.paymentTerms),
            shippingMethod: Value(q.shippingMethod),
            notes: Value(q.notes),
            externalId: Value(q.externalId),
            provenanceCode: Value(q.provenance.code),
            importJobId: Value(q.importJobId),
            quotedAt: Value(q.quotedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<SupplierQuote>> loadQuotes({String? productId}) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final query = _db.select(_db.supplierQuotesTable)
      ..where((t) => t.businessId.equals(businessId));
    if (productId != null) {
      query.where((t) => t.productId.equals(productId));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.unitCost)]);
    return (await query.get()).map(_toQuote).nonNulls.toList();
  }

  // ── xoá theo phạm vi ─────────────────────────────────────────────────────

  /// **Phạm vi: đúng một lần nhập.** Không đụng dòng người bán tự tạo, không
  /// đụng lần nhập khác.
  ///
  /// Trả về số bản ghi đã xoá theo loại — để màn hình nói được *"đã bỏ 100 sản
  /// phẩm và 96 đơn của lần nhập ngày 9/8"* thay vì một câu chung chung.
  Future<Map<String, int>> deleteImport(String importJobId) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final counts = <String, int>{};

    await _db.transaction(() async {
      counts['variants'] =
          await (_db.delete(_db.productVariantsTable)..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.importJobId.equals(importJobId),
              ))
              .go();
      counts['quotes'] =
          await (_db.delete(_db.supplierQuotesTable)..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.importJobId.equals(importJobId),
              ))
              .go();
      counts['products'] =
          await (_db.delete(_db.productsTable)..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.importJobId.equals(importJobId),
              ))
              .go();
      await (_db.delete(_db.importJobsTable)..where(
            (t) => t.businessId.equals(businessId) & t.id.equals(importJobId),
          ))
          .go();
    });

    return counts;
  }

  /// **Phạm vi: mọi bảng của miền thương mại, mọi lần nhập.** Chỉ dùng cho
  /// restore Replace (ADR-TON-018).
  Future<void> deleteAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      await (_db.delete(
        _db.productVariantsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.supplierQuotesTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.importJobsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
    });
  }

  // ── ánh xạ ───────────────────────────────────────────────────────────────

  /// Mã canonical lạ ⇒ **bỏ dòng**, không rơi về mặc định (ADR-TON-018).
  ImportJob? _toImportJob(ImportJobsTableData row) {
    final source = ProvenanceSource.fromCode(row.sourceCode);
    if (source == null) return null;
    return ImportJob(
      id: row.id,
      source: source,
      sourceVendor: row.sourceVendor,
      sourceFile: row.sourceFile,
      sourceAccount: row.sourceAccount,
      sourceChecksum: row.sourceChecksum,
      recordCounts: _decodeCounts(row.recordCounts),
      warnings: _decodeList(row.warnings),
      isDemo: row.isDemo,
      importedAt: row.importedAt,
    );
  }

  ProductVariant? _toVariant(ProductVariantsTableData row) => ProductVariant(
    id: row.id,
    productId: row.productId,
    name: row.name,
    sku: row.sku,
    option1Name: row.option1Name,
    option1Value: row.option1Value,
    option2Name: row.option2Name,
    option2Value: row.option2Value,
    costPrice: row.costPrice,
    sellingPrice: row.sellingPrice,
    quantity: row.quantity,
    externalId: row.externalId,
    provenance:
        ProvenanceSource.fromCode(row.provenanceCode) ??
        ProvenanceSource.manual,
    importJobId: row.importJobId,
  );

  SupplierQuote? _toQuote(SupplierQuotesTableData row) => SupplierQuote(
    id: row.id,
    productId: row.productId,
    supplierId: row.supplierId,
    supplierName: row.supplierName,
    platform: SupplierPlatform.fromCode(row.platform),
    country: row.country,
    sourceUrl: row.sourceUrl,
    rating: row.rating,
    unitCost: row.unitCost,
    currency: row.currency,
    minimumOrderQuantity: row.minimumOrderQuantity,
    leadTimeDays: row.leadTimeDays,
    paymentTerms: row.paymentTerms,
    shippingMethod: row.shippingMethod,
    notes: row.notes,
    externalId: row.externalId,
    provenance:
        ProvenanceSource.fromCode(row.provenanceCode) ??
        ProvenanceSource.manual,
    importJobId: row.importJobId,
    quotedAt: row.quotedAt,
  );

  static Map<String, int> _decodeCounts(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final e in decoded.entries)
          if (e.key is String && e.value is int)
            e.key as String: e.value as int,
      };
    } on FormatException {
      return const {};
    }
  }

  static List<String> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }
}
