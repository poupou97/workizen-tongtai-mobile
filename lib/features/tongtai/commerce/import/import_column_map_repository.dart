import 'package:drift/drift.dart';

import '../../../../database/database.dart';
import '../../core/local_workspace.dart';
import 'import_column_map.dart';
import 'marketplace_profile.dart';

/// Nơi bản đồ cột người bán tự chỉ được lưu — WTM-443.
///
/// ⛔ Không dữ liệu kinh doanh nào đi qua đây, và **không một ô nào của file**.
/// Bảng này chỉ giữ *tên cột nào ứng với vai trò nào* — tức là lời khai về
/// **cấu trúc** file, không phải nội dung. File của người bán không bao giờ
/// rời máy họ, kể cả vào `.ttbk`.
abstract class ImportColumnMapRepository {
  Future<List<ImportColumnMap>> loadAll();

  /// Ghi đè bản đồ cho đúng cặp `(vendor, fileKind)`.
  ///
  /// Khoá tự nhiên của bảng lo phần "một bản đồ cho mỗi cặp" — chỗ gọi không
  /// phải nhớ dọn bản cũ.
  Future<void> upsert(ImportColumnMap map);

  /// Xoá sạch — chỉ dùng cho restore Replace (ADR-TON-018).
  Future<void> deleteAll();
}

class DriftImportColumnMapRepository implements ImportColumnMapRepository {
  DriftImportColumnMapRepository(
    this._db, {
    this.workspace = const LocalWorkspace(),
  });

  final AppDatabase _db;
  final LocalWorkspace workspace;

  @override
  Future<List<ImportColumnMap>> loadAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.importColumnMapsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.asc(t.vendor)]))
            .get();
    return rows.map(_toMap).nonNulls.toList();
  }

  @override
  Future<void> upsert(ImportColumnMap map) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db
        .into(_db.importColumnMapsTable)
        .insertOnConflictUpdate(
          ImportColumnMapsTableCompanion.insert(
            businessId: businessId,
            vendor: map.vendor,
            fileKind: map.kind.code,
            columns: map.encodeColumns(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.importColumnMapsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  /// Mã `fileKind` lạ ⇒ **bỏ cả dòng**, không rơi về `orders`.
  ///
  /// Một bản đồ `income` bị đọc nhầm thành `orders` sẽ ghép cột phí vào vai
  /// trò đơn hàng — nhập ra doanh thu bịa. Bỏ dòng thì người bán được hỏi
  /// lại; đoán thì không ai được hỏi gì.
  ImportColumnMap? _toMap(ImportColumnMapsTableData row) {
    final kind = switch (row.fileKind) {
      'orders' => MarketplaceFileKind.orders,
      'income' => MarketplaceFileKind.income,
      _ => null,
    };
    if (kind == null) return null;
    return ImportColumnMap(
      vendor: row.vendor,
      kind: kind,
      columns: ImportColumnMap.decodeColumns(row.columns),
    );
  }
}
