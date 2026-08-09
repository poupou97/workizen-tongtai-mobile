import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/connection.dart';
import '../core/local_workspace.dart';
import 'connection_service.dart';

/// Nơi **metadata** kết nối được lưu — WTM-317.
///
/// ⛔ Không bí mật nào đi qua đây. Bí mật ở `ConnectionCredentialStore`
/// (Keychain/Keystore); bảng này chỉ giữ *có kết nối nào, tới đâu, tên gì,
/// trạng thái ra sao*.
///
/// Đó là lý do `.ttbk` chép được bảng này mà không rò rỉ gì: khoá tra
/// credential **suy ra** từ `id` chứ không nằm trong một cột.
abstract class ConnectionRepository implements ConnectionRepositoryLike {
  Future<List<Connection>> loadAll();

  @override
  Future<Connection?> byId(String id);

  /// Kết nối tới một nền tảng — `null` khi chưa nối.
  ///
  /// Một người có thể nối nhiều tài khoản cùng nền tảng; hàm này trả về cái
  /// **đầu tiên** và đủ cho giai đoạn hiện tại. Khi nào có người bán nối hai
  /// shop Shopify thì đổi thành `loadByConnector`.
  @override
  Future<Connection?> byConnector(String connectorId);

  @override
  Future<void> upsert(Connection connection);

  /// Xoá metadata. ⚠️ **Không** xoá credential — chỗ gọi phải xoá cả hai, và
  /// việc tách ra là cố ý: xoá bí mật là một hành động riêng, đáng nhìn thấy.
  @override
  Future<void> delete(String id);

  /// Xoá sạch — chỉ dùng cho restore Replace (ADR-TON-018).
  Future<void> deleteAll();
}

class DriftConnectionRepository implements ConnectionRepository {
  DriftConnectionRepository(
    this._db, {
    this.workspace = const LocalWorkspace(),
  });

  final AppDatabase _db;
  final LocalWorkspace workspace;

  @override
  Future<List<Connection>> loadAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.connectionsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_toConnection).nonNulls.toList();
  }

  @override
  Future<Connection?> byId(String id) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final row =
        await (_db.select(_db.connectionsTable)
              ..where((t) => t.businessId.equals(businessId) & t.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _toConnection(row);
  }

  @override
  Future<Connection?> byConnector(String connectorId) async {
    final all = await loadAll();
    for (final c in all) {
      if (c.connectorId == connectorId) return c;
    }
    return null;
  }

  @override
  Future<void> upsert(Connection connection) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db
        .into(_db.connectionsTable)
        .insertOnConflictUpdate(
          ConnectionsTableCompanion.insert(
            id: connection.id,
            businessId: businessId,
            connectorId: connection.connectorId,
            label: connection.label,
            status: connection.status.code,
            createdAt: connection.createdAt,
            lastSyncAt: Value(connection.lastSyncAt),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.connectionsTable,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).go();
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.connectionsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  /// Mã trạng thái lạ ⇒ **bỏ dòng**, không rơi về `active`.
  ///
  /// Một kết nối hỏng trông như đang chạy là kiểu nói dối tệ nhất ở đây: người
  /// bán tưởng dữ liệu đang về trong khi nó đã dừng từ lâu (ADR-TON-018).
  Connection? _toConnection(ConnectionsTableData row) {
    final status = ConnectionStatus.fromCode(row.status);
    if (status == null) return null;
    return Connection(
      id: row.id,
      connectorId: row.connectorId,
      label: row.label,
      status: status,
      createdAt: row.createdAt,
      lastSyncAt: row.lastSyncAt,
    );
  }
}
