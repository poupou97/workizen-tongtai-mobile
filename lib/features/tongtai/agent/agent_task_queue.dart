import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import '../core/provenance.dart';
import 'agent_task.dart';

/// Hàng đợi việc bền vững (WTM-301 · D-4).
///
/// ## ⭐ Không có gì ở đây biết mình đang chạy ở đâu
///
/// File này import `drift` (cần, để nói chuyện với SQLite) nhưng **không import
/// `package:flutter`**. Giao thức nhận việc — `dueAt` · `leasedUntil` ·
/// `attempts` — đúng nghĩa với **mọi** runner: một vòng lặp trong app, một
/// worker trên Oracle VM, hay một cron trên Managed Worker.
///
/// "Ai chạy" là thứ nằm ngoài file này. Đó là điều kiện Founder đặt cho D-4.
///
/// ## Vì sao SQLite đủ, không cần `FOR UPDATE SKIP LOCKED`
///
/// COMP AI dùng `FOR UPDATE SKIP LOCKED` vì họ có nhiều worker cùng chạy trên
/// một Postgres. Trên máy người bán chỉ có **một** tiến trình, nên một
/// `UPDATE … WHERE` có điều kiện lease là đủ — và **hợp đồng giữ nguyên**, nên
/// bản Postgres sau này chỉ việc đổi câu SQL, không đổi luật.
class AgentTaskQueue {
  AgentTaskQueue(
    this._db, {
    this._workspace = const LocalWorkspace(),
    required this._now,
    required this._newId,
    this._lease = kAgentTaskLease,
  });

  final AppDatabase _db;
  final LocalWorkspace _workspace;
  final DateTime Function() _now;
  final String Function() _newId;
  final Duration _lease;

  /// Đặt lịch một việc — **chống trùng ngay lúc đặt**.
  ///
  /// Cùng `kind` + cùng subject mà **chưa xong** ⇒ cập nhật `dueAt`/`reason`,
  /// **không** tạo thẻ mới. Gọi trigger năm mươi lần vẫn chỉ có một việc.
  ///
  /// Rẻ hơn nhiều so với chống trùng lúc chạy, và đó là cách COMP AI làm.
  Future<AgentTask> schedule({
    required AgentTaskKind kind,
    required String reason,
    required DateTime dueAt,
    String? subjectKind,
    String? subjectId,
    String? correlationId,
    int priority = 0,
    int budget = 4,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);

    final open =
        await (_db.select(_db.agentTasksTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.kind.equals(kind.code) &
                  t.finishedAt.isNull() &
                  _subjectMatches(t, subjectKind, subjectId),
            ))
            .getSingleOrNull();

    if (open != null) {
      await (_db.update(_db.agentTasksTable)..where(
            (t) => t.businessId.equals(businessId) & t.id.equals(open.id),
          ))
          .write(
            AgentTasksTableCompanion(
              dueAt: Value(dueAt),
              reason: Value(reason),
            ),
          );
      final refreshed = await _byId(businessId, open.id);
      return refreshed!;
    }

    final task = AgentTask(
      id: _newId(),
      correlationId: correlationId,
      kind: kind,
      reason: reason,
      subjectKind: subjectKind,
      subjectId: subjectId,
      dueAt: dueAt,
      priority: priority,
      budget: budget,
      createdAt: _now(),
    );
    await _db.into(_db.agentTasksTable).insert(_companion(task, businessId));
    return task;
  }

  /// Đặt lịch xem lại sau [days] ngày, **kèm lý do người bán đọc được**.
  ///
  /// Lý do là phần quan trọng hơn con số: *"khách này sắp hết hàng dùng"*, chứ
  /// không phải *"scheduled recheck"*.
  Future<AgentTask> scheduleRecheck({
    required String reason,
    required int days,
    String? subjectKind,
    String? subjectId,
    String? correlationId,
    int budget = 4,
  }) {
    assert(days >= 1 && days <= 730, 'khoảng xem lại phải trong 1..730 ngày');
    return schedule(
      kind: AgentTaskKind.recheck,
      reason: reason,
      dueAt: _now().add(Duration(days: days)),
      subjectKind: subjectKind,
      subjectId: subjectId,
      correlationId: correlationId,
      budget: budget,
    );
  }

  /// Nhận tối đa [limit] việc đến hạn.
  ///
  /// Nhận và tăng `attempts` trong **cùng một câu lệnh** cho mỗi việc: không
  /// đọc-rồi-ghi, nên không có cửa sổ đua.
  Future<List<AgentTask>> claimDue({int limit = 5}) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final now = _now();
    final until = now.add(_lease);

    final due =
        await (_db.select(_db.agentTasksTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.finishedAt.isNull() &
                    t.dueAt.isSmallerOrEqualValue(now) &
                    t.attempts.isSmallerThanValue(kMaxAgentTaskAttempts) &
                    (t.leasedUntil.isNull() |
                        t.leasedUntil.isSmallerThanValue(now)),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.priority),
                (t) => OrderingTerm.asc(t.dueAt),
              ])
              ..limit(limit))
            .get();

    final claimed = <AgentTask>[];
    for (final row in due) {
      final count =
          await (_db.update(_db.agentTasksTable)..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.id.equals(row.id) &
                    t.finishedAt.isNull() &
                    (t.leasedUntil.isNull() |
                        t.leasedUntil.isSmallerThanValue(now)),
              ))
              .write(
                AgentTasksTableCompanion(
                  leasedUntil: Value(until),
                  startedAt: Value(row.startedAt ?? now),
                  attempts: Value(row.attempts + 1),
                ),
              );
      if (count == 0) continue; // ai đó vừa nhận trước
      final task = await _byId(businessId, row.id);
      if (task != null) claimed.add(task);
    }

    claimed.sort(compareAgentTaskPriority);
    return claimed;
  }

  /// Đóng một việc.
  Future<bool> finish(String id, AgentTaskOutcome outcome) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final count =
        await (_db.update(_db.agentTasksTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.id.equals(id) &
                  t.finishedAt.isNull(),
            ))
            .write(
              AgentTasksTableCompanion(
                finishedAt: Value(_now()),
                outcome: Value(outcome.code),
                leasedUntil: const Value(null),
              ),
            );
    return count > 0;
  }

  /// Cho nghỉ hưu những việc đã hết lượt thử.
  ///
  /// Tách khỏi [claimDue] vì đây là **một quyết định**, không phải một hiệu ứng
  /// phụ: *"đã thử bốn lần và không xong"* là kết cục cần nhìn thấy được, không
  /// phải một dòng biến mất khỏi hàng đợi.
  Future<int> retireExhausted() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final now = _now();
    return (_db.update(_db.agentTasksTable)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.finishedAt.isNull() &
              t.attempts.isBiggerOrEqualValue(kMaxAgentTaskAttempts) &
              (t.leasedUntil.isNull() | t.leasedUntil.isSmallerThanValue(now)),
        ))
        .write(
          AgentTasksTableCompanion(
            finishedAt: Value(now),
            outcome: Value(AgentTaskOutcome.retired.code),
            leasedUntil: const Value(null),
          ),
        );
  }

  Future<List<AgentTask>> loadOpen() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.agentTasksTable)
              ..where(
                (t) => t.businessId.equals(businessId) & t.finishedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
            .get();
    return rows.map(_toTask).nonNulls.toList();
  }

  Future<List<AgentTask>> loadByCorrelation(String correlationId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.agentTasksTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.correlationId.equals(correlationId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_toTask).nonNulls.toList();
  }

  /// Xoá việc thuộc **đối tượng mẫu** — WTM-307.
  ///
  /// `subjectId` có thể `null` (việc toàn doanh nghiệp) — những việc đó KHÔNG
  /// bị xoá: chúng không thuộc về dữ liệu mẫu nào cả.
  Future<int> deleteForSampleSubjects() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    return (_db.delete(_db.agentTasksTable)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.subjectId.like('$kSampleIdPrefix%'),
        ))
        .go();
  }

  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.agentTasksTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  /// Mọi việc **kể cả đã đóng**, mới đặt trước — nguồn của màn Hoạt động.
  Future<List<AgentTask>> loadRecent({int limit = 50}) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.agentTasksTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(limit))
            .get();
    return rows.map(_toTask).nonNulls.toList();
  }

  Future<AgentTask?> byId(String id) async =>
      _byId(await _workspace.ensureBusinessId(_db), id);

  Future<AgentTask?> _byId(String businessId, String id) async {
    final row =
        await (_db.select(_db.agentTasksTable)
              ..where((t) => t.businessId.equals(businessId) & t.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _toTask(row);
  }

  Expression<bool> _subjectMatches(
    $AgentTasksTableTable t,
    String? kind,
    String? id,
  ) {
    if (kind == null || id == null) {
      return t.subjectKind.isNull() & t.subjectId.isNull();
    }
    return t.subjectKind.equals(kind) & t.subjectId.equals(id);
  }

  AgentTasksTableCompanion _companion(AgentTask t, String businessId) =>
      AgentTasksTableCompanion.insert(
        id: t.id,
        businessId: businessId,
        correlationId: Value(t.correlationId),
        kind: t.kind.code,
        reason: t.reason,
        subjectKind: Value(t.subjectKind),
        subjectId: Value(t.subjectId),
        dueAt: t.dueAt,
        priority: Value(t.priority),
        budget: Value(t.budget),
        attempts: Value(t.attempts),
        leasedUntil: Value(t.leasedUntil),
        createdAt: t.createdAt,
        startedAt: Value(t.startedAt),
        finishedAt: Value(t.finishedAt),
        outcome: Value(t.outcome?.code),
      );

  /// Mã canonical lạ ⇒ **bỏ qua dòng**, không rơi về mặc định (ADR-TON-018).
  AgentTask? _toTask(AgentTasksTableData row) {
    final kind = AgentTaskKind.fromCode(row.kind);
    if (kind == null) return null;
    final outcome = row.outcome == null
        ? null
        : AgentTaskOutcome.fromCode(row.outcome);
    if (row.outcome != null && outcome == null) return null;

    return AgentTask(
      id: row.id,
      correlationId: row.correlationId,
      kind: kind,
      reason: row.reason,
      subjectKind: row.subjectKind,
      subjectId: row.subjectId,
      dueAt: row.dueAt,
      priority: row.priority,
      budget: row.budget,
      attempts: row.attempts,
      leasedUntil: row.leasedUntil,
      createdAt: row.createdAt,
      startedAt: row.startedAt,
      finishedAt: row.finishedAt,
      outcome: outcome,
    );
  }
}
