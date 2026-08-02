import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import 'business_input.dart';

/// Đọc/ghi [BusinessInput] (WTM-229).
///
/// Interface tách khỏi bản Drift theo đúng seam ADR-TON-008: màn hình và test
/// nói chuyện với interface, nguồn dữ liệu do repository quyết.
abstract class BusinessInputRepository {
  Future<List<BusinessInput>> loadAll();
  Future<void> upsert(BusinessInput input);
  Future<void> upsertAll(Iterable<BusinessInput> inputs);
  Future<void> delete(String id);

  /// Xoá sạch — dùng bởi Restore = Replace (ADR-TON-018).
  Future<void> deleteAll();
}

class DriftBusinessInputRepository implements BusinessInputRepository {
  DriftBusinessInputRepository(this._db, {LocalWorkspace? workspace})
    : _workspace = workspace ?? const LocalWorkspace();

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  @override
  Future<List<BusinessInput>> loadAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows = await (_db.select(
      _db.businessInputsTable,
    )..where((t) => t.businessId.equals(businessId))).get();
    return [for (final row in rows) _toInput(row)];
  }

  @override
  Future<void> upsert(BusinessInput input) => upsertAll([input]);

  @override
  Future<void> upsertAll(Iterable<BusinessInput> inputs) async {
    if (inputs.isEmpty) return;
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.batch((batch) {
      for (final input in inputs) {
        batch.insert(
          _db.businessInputsTable,
          BusinessInputsTableCompanion.insert(
            id: input.id,
            businessId: businessId,
            name: input.name,
            kind: input.kind.code,
            // `null` đi thẳng xuống cột: "chưa khai" phải sống sót qua lần đóng
            // app, quy về 0 là bịa một con số người bán chưa nói.
            cadence: Value(input.cadence?.code),
            expectedAmount: Value(input.expectedAmount),
            note: Value(input.note),
            updatedAt: Value(input.updatedAt),
          ),
          onConflict: DoUpdate((_) => _companionOf(input, businessId)),
        );
      }
    });
  }

  BusinessInputsTableCompanion _companionOf(
    BusinessInput input,
    String businessId,
  ) => BusinessInputsTableCompanion(
    id: Value(input.id),
    businessId: Value(businessId),
    name: Value(input.name),
    kind: Value(input.kind.code),
    cadence: Value(input.cadence?.code),
    expectedAmount: Value(input.expectedAmount),
    note: Value(input.note),
    updatedAt: Value(input.updatedAt),
  );

  @override
  Future<void> delete(String id) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.businessInputsTable,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).go();
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.businessInputsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  BusinessInput _toInput(BusinessInputsTableData row) => BusinessInput(
    id: row.id,
    name: row.name,
    // Mã lạ ⇒ `supplier`: một dòng đã lưu là một nguồn CÓ THẬT, nên nó phải
    // đọc ra được. Chọn loại phổ biến nhất và để người bán sửa, thay vì làm
    // biến mất một nguồn họ đã khai.
    kind: BusinessInputKind.fromCode(row.kind) ?? BusinessInputKind.supplier,
    cadence: InputCadence.fromCode(row.cadence),
    expectedAmount: row.expectedAmount,
    note: row.note ?? '',
    updatedAt: row.updatedAt,
  );
}

/// Bản trong bộ nhớ cho test và preview.
class InMemoryBusinessInputRepository implements BusinessInputRepository {
  InMemoryBusinessInputRepository([List<BusinessInput> seed = const []])
    : _inputs = [...seed];

  final List<BusinessInput> _inputs;

  @override
  Future<List<BusinessInput>> loadAll() async => List.unmodifiable(_inputs);

  @override
  Future<void> upsert(BusinessInput input) => upsertAll([input]);

  @override
  Future<void> upsertAll(Iterable<BusinessInput> inputs) async {
    for (final input in inputs) {
      _inputs
        ..removeWhere((i) => i.id == input.id)
        ..add(input);
    }
  }

  @override
  Future<void> delete(String id) async =>
      _inputs.removeWhere((i) => i.id == id);

  @override
  Future<void> deleteAll() async => _inputs.clear();
}
