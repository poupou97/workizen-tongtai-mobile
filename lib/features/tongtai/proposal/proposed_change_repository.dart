import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../consumer/identity_evidence.dart';
import '../core/local_workspace.dart';
import '../core/provenance.dart';
import 'proposal_gate.dart';
import 'proposed_change.dart';

/// Đường ghi/đọc đề xuất (WTM-299 · D-2).
///
/// ## ⭐ Repository KHÔNG quyết định gì
///
/// Bốn cổng nằm trong [ProposalGate] — hàm thuần, không chạm DB. Repository
/// chỉ **đọc trạng thái hiện có, gọi cổng, rồi ghi theo kết quả**.
///
/// Tách như vậy vì hai lý do, và lý do thứ hai quan trọng hơn:
/// 1. cổng test được không cần DB;
/// 2. **chỉ có một chỗ** quyết định, nên không có đường vòng nào bỏ qua cổng.
///
/// Bằng chứng vì sao lý do 2 đáng lo: COMP AI có fact ledger nghiêm ngặt, rồi
/// **5 ngày sau** thêm `set_field_value` ghi thẳng, bỏ qua toàn bộ. Họ không có
/// gì bắt hai đường hợp nhất.
abstract class ProposedChangeRepository {
  /// Mọi đề xuất **đang chờ người quyết**, mới nhất trước.
  Future<List<ProposedChange>> loadOpen();

  /// Đề xuất nên **hiện** cho người bán — đã lọc qua ngưỡng hiển thị.
  Future<List<ProposedChange>> loadVisible();

  /// Mọi đề xuất của một chuỗi việc — đây là "câu chuyện" thay cho một entity
  /// `BusinessConversation` (WTM-296 §10).
  Future<List<ProposedChange>> loadByCorrelation(String correlationId);

  /// Mọi đề xuất **kể cả đã quyết**, mới nhất trước — nguồn của màn Hoạt động.
  ///
  /// Khác [loadVisible] ở chỗ nó cố ý giữ lại thứ đã bỏ qua: câu chuyện *"bạn
  /// đã bỏ qua việc này"* cũng là một phần của việc agent đã làm.
  Future<List<ProposedChange>> loadRecent({int limit = 50});

  /// Đề nghị một thay đổi. **Đi qua bốn cổng.**
  ///
  /// [humanOwnsField] do chỗ gọi trả lời — nó biết miền, cổng thì không.
  Future<ProposalOutcome> propose(
    ProposedChange proposal, {
    required bool humanOwnsField,
  });

  /// Người bán duyệt. Trả `false` nếu đề xuất không còn mở.
  ///
  /// **Không** ghi giá trị vào bản ghi nghiệp vụ — đó là việc của
  /// `BusinessAction` (WTM-300). Đây chỉ đổi trạng thái đề xuất.
  Future<bool> apply(String id);

  /// Người bán bỏ qua.
  Future<bool> dismiss(String id);

  /// Đề xuất mới hơn thay thế cái cũ cho cùng subject + field.
  ///
  /// Cái cũ chuyển `superseded`, **không xoá** — để phát hiện thay đổi là hệ
  /// quả miễn phí, như `lastEmployerChange()` của COMP AI.
  Future<int> supersedeOlder({
    required String subjectKind,
    required String subjectId,
    required String field,
    required String keepId,
  });

  Future<void> deleteAll();
}

/// Bản Drift.
class DriftProposedChangeRepository implements ProposedChangeRepository {
  DriftProposedChangeRepository(
    this._db, {
    this._workspace = const LocalWorkspace(),
    this._gate = const ProposalGate(),
    required this._now,
  });

  final AppDatabase _db;
  final LocalWorkspace _workspace;
  final ProposalGate _gate;
  final DateTime Function() _now;

  @override
  Future<List<ProposedChange>> loadOpen() async {
    final rows = await _rows(
      (t) => t.status.equals(ProposalStatus.proposed.code),
    );
    return rows.map(_toProposal).nonNulls.toList();
  }

  @override
  Future<List<ProposedChange>> loadVisible() async {
    final open = await loadOpen();
    return open.where(_gate.shouldShow).toList();
  }

  @override
  Future<List<ProposedChange>> loadByCorrelation(String correlationId) async {
    final rows = await _rows((t) => t.correlationId.equals(correlationId));
    return rows.map(_toProposal).nonNulls.toList();
  }

  @override
  Future<List<ProposedChange>> loadRecent({int limit = 50}) async {
    final rows = await _rows(null, limit: limit);
    return rows.map(_toProposal).nonNulls.toList();
  }

  @override
  Future<ProposalOutcome> propose(
    ProposedChange proposal, {
    required bool humanOwnsField,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);

    final existing = (await _rows(
      (t) =>
          t.subjectKind.equals(proposal.subjectKind) &
          t.subjectId.equals(proposal.subjectId) &
          t.field.equals(proposal.field),
    )).map(_toProposal).nonNulls.toList();

    final outcome = _gate.evaluate(
      proposal: proposal,
      existingForField: existing,
      humanOwns: humanOwnsField,
      now: _now(),
    );

    if (outcome is ProposalRejected) return outcome;

    await _db
        .into(_db.proposedChangesTable)
        .insertOnConflictUpdate(_companion(proposal, businessId));

    return outcome;
  }

  @override
  Future<bool> apply(String id) => _decide(id, ProposalStatus.applied);

  @override
  Future<bool> dismiss(String id) => _decide(id, ProposalStatus.dismissed);

  /// **Chỗ DUY NHẤT** chuyển một đề xuất khỏi `proposed`.
  ///
  /// `where status = proposed` là điều kiện chống đua: hai lần bấm chỉ một lần
  /// đổi được, và lần thứ hai trả `false` thay vì ghi đè quyết định đầu.
  Future<bool> _decide(String id, ProposalStatus status) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final count =
        await (_db.update(_db.proposedChangesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.id.equals(id) &
                  t.status.equals(ProposalStatus.proposed.code),
            ))
            .write(
              ProposedChangesTableCompanion(
                status: Value(status.code),
                decidedAt: Value(_now()),
              ),
            );
    return count > 0;
  }

  @override
  Future<int> supersedeOlder({
    required String subjectKind,
    required String subjectId,
    required String field,
    required String keepId,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    return (_db.update(_db.proposedChangesTable)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.subjectKind.equals(subjectKind) &
              t.subjectId.equals(subjectId) &
              t.field.equals(field) &
              t.status.equals(ProposalStatus.proposed.code) &
              t.id.equals(keepId).not(),
        ))
        .write(
          ProposedChangesTableCompanion(
            status: Value(ProposalStatus.superseded.code),
            decidedAt: Value(_now()),
          ),
        );
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.proposedChangesTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  Future<List<ProposedChangesTableData>> _rows(
    Expression<bool> Function($ProposedChangesTableTable t)? filter, {
    int? limit,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final query = _db.select(_db.proposedChangesTable)
      ..where(
        (t) =>
            t.businessId.equals(businessId) &
            (filter == null ? const Constant(true) : filter(t)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  ProposedChangesTableCompanion _companion(
    ProposedChange p,
    String businessId,
  ) => ProposedChangesTableCompanion.insert(
    id: p.id,
    businessId: businessId,
    correlationId: Value(p.correlationId),
    domain: p.domain.code,
    subjectKind: p.subjectKind,
    subjectId: p.subjectId,
    subjectLabel: Value(p.subjectLabel),
    field: p.field,
    currentValue: Value(p.currentValue),
    proposedValue: p.proposedValue,
    evidence: _encodeEvidence(p.evidence),
    proposedBy: p.proposedBy.code,
    summary: p.summary,
    status: p.status.code,
    createdAt: p.createdAt,
    decidedAt: Value(p.decidedAt),
    provenanceCode: Value(p.provenance.storedCode),
  );

  static String _encodeEvidence(List<IdentityEvidence> evidence) => jsonEncode([
    for (final e in evidence)
      {
        'kind': e.kind.code,
        'source': e.source,
        if (e.detail != null) 'detail': e.detail,
      },
  ]);

  /// Mã canonical lạ ⇒ dòng bị **bỏ qua**, không rơi về mặc định (ADR-TON-018).
  ///
  /// Hậu quả cụ thể nếu rơi về mặc định: một `status` lạ đọc thành `proposed`
  /// sẽ làm một đề xuất người bán **đã bỏ qua** hiện lại.
  ProposedChange? _toProposal(ProposedChangesTableData row) {
    final domain = ProposalDomain.fromCode(row.domain);
    final status = ProposalStatus.fromCode(row.status);
    final author = ProposalAuthor.fromCode(row.proposedBy);
    if (domain == null || status == null || author == null) return null;

    final evidence = _decodeEvidence(row.evidence);
    if (evidence.isEmpty) return null;

    return ProposedChange(
      id: row.id,
      correlationId: row.correlationId,
      domain: domain,
      subjectKind: row.subjectKind,
      subjectId: row.subjectId,
      subjectLabel: row.subjectLabel,
      field: row.field,
      currentValue: row.currentValue,
      proposedValue: row.proposedValue,
      evidence: evidence,
      proposedBy: author,
      summary: row.summary,
      status: status,
      createdAt: row.createdAt,
      decidedAt: row.decidedAt,
      provenance: Provenance.fromStored(code: row.provenanceCode, id: row.id),
    );
  }

  static List<IdentityEvidence> _decodeEvidence(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <IdentityEvidence>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final kind = IdentityEvidenceKind.fromCode(item['kind'] as String?);
        final source = item['source'] as String?;
        if (kind == null || source == null) continue;
        out.add(
          IdentityEvidence(
            kind: kind,
            source: source,
            detail: item['detail'] as String?,
          ),
        );
      }
      return out;
    } on FormatException {
      // JSON hỏng ⇒ bản ghi hỏng, không phải bản ghi rỗng. Chỗ gọi bỏ qua dòng.
      return const [];
    }
  }
}
