import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import '../core/provenance.dart';
import 'settlement.dart';

/// Đường ghi/đọc khoản đối soát và lô tiền về (WTM-292 · N0.4 · ADR-TON-024).
///
/// ## ⭐ Luật 3 nằm ở đây, và nó là hình dạng của API
///
/// ADR-TON-024 cấm **tự động phân bổ** một khoản cấp-đơn xuống từng món. Lý do
/// không phải sạch sẽ mà là đúng sai: phân bổ là một luật dẫn xuất, và nếu nó
/// chạy ngầm lúc ghi thì cùng một con số vừa được lưu vừa được tính lại — lỗi
/// P-27/P-28 đã lặp **bốn lần** trong repo này.
///
/// Nên seam này được thiết kế sao cho việc đó **không viết ra được**: không
/// hàm nào ở đây nhận một [SettlementLine] và ghi ra **nhiều** dòng. `upsert`
/// ghi đúng thứ được đưa vào; `upsertAll` ghi đúng những thứ được đưa vào.
/// Phân bổ sống ở `settlement_allocation.dart` — hàm thuần, trả về một khung
/// nhìn không có `id` nên không có gì để lưu.
/// `settlement_no_derived_write_governance_test` canh đúng tính chất đó.
abstract class SettlementRepository {
  /// Mọi khoản của một đơn.
  Future<List<SettlementLine>> loadForOrder(String orderId);

  /// Mọi khoản đã trả trong một lô.
  Future<List<SettlementLine>> loadForPayout(String payoutId);

  /// Ghi **đúng một** dòng.
  Future<void> upsert(SettlementLine line);

  /// Ghi **đúng những dòng được đưa vào**, trong một giao dịch.
  ///
  /// Không sinh thêm dòng nào — xem doc của lớp về vì sao đó là luật, không
  /// phải chi tiết cài đặt.
  Future<void> upsertAll(Iterable<SettlementLine> lines);

  Future<List<Payout>> loadPayouts();

  Future<void> upsertPayout(Payout payout);

  /// Ghi chênh lệch đã đối soát cho một lô.
  ///
  /// Tách khỏi [upsertPayout] vì đối soát là một **việc**, không phải một lần
  /// sửa trường: nó xảy ra sau, do người bán hoặc một luật khác kích hoạt.
  Future<void> recordReconciliation(String payoutId, double delta);

  Future<void> deleteByIdPrefix(String prefix);

  /// Xoá mọi bản ghi của doanh nghiệp này (WTM-164 restore Replace).
  Future<void> deleteAll();
}

/// Bản Drift, bền vững trên máy.
class DriftSettlementRepository implements SettlementRepository {
  DriftSettlementRepository(
    this._db, {
    this._workspace = const LocalWorkspace(),
  });

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  @override
  Future<List<SettlementLine>> loadForOrder(String orderId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.settlementLinesTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) & t.orderId.equals(orderId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
            .get();
    return rows.map(_toLine).nonNulls.toList();
  }

  @override
  Future<List<SettlementLine>> loadForPayout(String payoutId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.settlementLinesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) & t.payoutId.equals(payoutId),
            ))
            .get();
    return rows.map(_toLine).nonNulls.toList();
  }

  @override
  Future<void> upsert(SettlementLine line) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db
        .into(_db.settlementLinesTable)
        .insertOnConflictUpdate(_companion(line, businessId));
  }

  @override
  Future<void> upsertAll(Iterable<SettlementLine> lines) async {
    final rows = lines.toList(growable: false);
    if (rows.isEmpty) return;
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.settlementLinesTable, [
        for (final l in rows) _companion(l, businessId),
      ]),
    );
  }

  @override
  Future<List<Payout>> loadPayouts() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.payoutsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.settledAt)]))
            .get();
    return rows.map(_toPayout).toList();
  }

  @override
  Future<void> upsertPayout(Payout payout) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db
        .into(_db.payoutsTable)
        .insertOnConflictUpdate(
          PayoutsTableCompanion.insert(
            id: payout.id,
            businessId: businessId,
            connectionId: payout.connectionId,
            amount: payout.amount,
            currency: payout.currency,
            settledAt: payout.settledAt,
            reconciledDelta: Value(payout.reconciledDelta),
            provenanceCode: Value(payout.provenance.storedCode),
          ),
        );
  }

  @override
  Future<void> recordReconciliation(String payoutId, double delta) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.update(_db.payoutsTable)..where(
          (t) => t.businessId.equals(businessId) & t.id.equals(payoutId),
        ))
        .write(PayoutsTableCompanion(reconciledDelta: Value(delta)));
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      await (_db.delete(_db.settlementLinesTable)..where(
            (t) => t.businessId.equals(businessId) & t.id.like('$prefix%'),
          ))
          .go();
      await (_db.delete(_db.payoutsTable)..where(
            (t) => t.businessId.equals(businessId) & t.id.like('$prefix%'),
          ))
          .go();
    });
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      await (_db.delete(
        _db.settlementLinesTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.payoutsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
    });
  }

  SettlementLinesTableCompanion _companion(
    SettlementLine l,
    String businessId,
  ) => SettlementLinesTableCompanion.insert(
    id: l.id,
    businessId: businessId,
    orderId: l.orderId,
    orderItemId: Value(l.orderItemId),
    kind: l.kind.code,
    direction: l.direction.code,
    amount: l.amount,
    currency: l.currency,
    occurredAt: l.occurredAt,
    fundedBy: l.fundedBy.code,
    sellerShare: Value(l.sellerShare),
    payoutId: Value(l.payoutId),
    provenanceCode: Value(l.provenance.storedCode),
  );

  /// Mã lạ ⇒ `null` ⇒ dòng bị **bỏ qua**, không rơi về mặc định.
  ///
  /// Hậu quả cụ thể nếu rơi về mặc định: một `funded_by` lạ đọc thành
  /// `platform` sẽ khiến app khai rằng sàn tài trợ khoản này, và lợi nhuận
  /// hiện lên cao hơn thực tế — sai theo hướng người bán không nghi ngờ.
  SettlementLine? _toLine(SettlementLinesTableData row) {
    final kind = SettlementKind.fromCode(row.kind);
    final direction = SettlementDirection.fromCode(row.direction);
    final funded = FundingSource.fromCode(row.fundedBy);
    if (kind == null || direction == null || funded == null) return null;
    // `amount` âm trên đĩa là bản ghi hỏng, không phải "chiều ngược lại":
    // chiều nằm ở cột `direction`. Dựng object sẽ vấp assert, nên chặn ở đây
    // và bỏ qua dòng — cùng cách xử lý mã canonical không đọc được.
    if (row.amount < 0) return null;
    return SettlementLine(
      id: row.id,
      orderId: row.orderId,
      orderItemId: row.orderItemId,
      kind: kind,
      direction: direction,
      amount: row.amount,
      currency: row.currency,
      occurredAt: row.occurredAt,
      fundedBy: funded,
      sellerShare: row.sellerShare,
      payoutId: row.payoutId,
      provenance: Provenance.fromStored(code: row.provenanceCode, id: row.id),
    );
  }

  Payout _toPayout(PayoutsTableData row) => Payout(
    id: row.id,
    connectionId: row.connectionId,
    amount: row.amount,
    currency: row.currency,
    settledAt: row.settledAt,
    reconciledDelta: row.reconciledDelta,
    provenance: Provenance.fromStored(code: row.provenanceCode, id: row.id),
  );
}
