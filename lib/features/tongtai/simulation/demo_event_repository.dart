import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import 'demo_event.dart';

/// Sổ sự kiện — WTM-337.
class DemoEventRepository {
  DemoEventRepository(this._db, {this.workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace workspace;

  Future<void> saveAll(Iterable<DemoEvent> events) async {
    final rows = events.toList(growable: false);
    if (rows.isEmpty) return;
    final businessId = await workspace.ensureBusinessId(_db);
    await _db.batch((batch) {
      for (final e in rows) {
        batch.insert(
          _db.demoEventsTable,
          DemoEventsTableCompanion.insert(
            id: e.id,
            businessId: businessId,
            kind: e.kind.code,
            actor: e.actor.code,
            vendor: Value(e.vendor),
            subjectKind: Value(e.subjectKind),
            subjectId: Value(e.subjectId),
            correlationId: Value(e.correlationId),
            headline: e.headline,
            payload: Value(e.encodePayload()),
            occurredAt: e.occurredAt,
            appliedAt: Value(e.appliedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Mọi sự kiện **đã áp**, mới nhất trước — nguồn của dòng thời gian (§37).
  ///
  /// Chưa áp thì không hiện: một chuyện chưa xảy ra trong thế giới mô phỏng mà
  /// đã nằm trên dòng thời gian là nói trước tương lai.
  Future<List<DemoEvent>> loadTimeline({int limit = 200}) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.demoEventsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) & t.appliedAt.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
              ..limit(limit))
            .get();
    return rows.map(_toEvent).nonNulls.toList();
  }

  /// Sự kiện tới hạn mà chưa áp, cũ nhất trước.
  Future<List<DemoEvent>> loadDue(DateTime until) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.demoEventsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.appliedAt.isNull() &
                    t.occurredAt.isSmallerOrEqualValue(until),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
            .get();
    return rows.map(_toEvent).nonNulls.toList();
  }

  /// Sự kiện kế tiếp chưa áp — cho nút "Sự kiện tiếp".
  Future<DemoEvent?> nextPending() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final row =
        await (_db.select(_db.demoEventsTable)
              ..where(
                (t) => t.businessId.equals(businessId) & t.appliedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toEvent(row);
  }

  /// Một câu chuyện — mọi sự kiện cùng `correlationId`, cũ nhất trước.
  Future<List<DemoEvent>> loadStory(String correlationId) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.demoEventsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.correlationId.equals(correlationId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
            .get();
    return rows.map(_toEvent).nonNulls.toList();
  }

  Future<void> markApplied(Iterable<String> ids, DateTime at) async {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return;
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.update(_db.demoEventsTable)
          ..where((t) => t.businessId.equals(businessId) & t.id.isIn(list)))
        .write(DemoEventsTableCompanion(appliedAt: Value(at)));
  }

  Future<int> count() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows = await (_db.select(
      _db.demoEventsTable,
    )..where((t) => t.businessId.equals(businessId))).get();
    return rows.length;
  }

  /// **Phạm vi: toàn bộ sổ sự kiện demo.** Không đụng miền thật — chỗ gọi phải
  /// dọn miền riêng, và việc tách ra là cố ý (kỷ luật WTM-307).
  Future<void> deleteAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.demoEventsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  /// Mã lạ ⇒ **bỏ dòng**, không đoán (ADR-TON-018).
  DemoEvent? _toEvent(DemoEventsTableData row) {
    final kind = DemoEventKind.fromCode(row.kind);
    final actor = DemoActor.fromCode(row.actor);
    if (kind == null || actor == null) return null;
    return DemoEvent(
      id: row.id,
      kind: kind,
      actor: actor,
      vendor: row.vendor,
      subjectKind: row.subjectKind,
      subjectId: row.subjectId,
      correlationId: row.correlationId,
      headline: row.headline,
      payload: DemoEvent.decodePayload(row.payload),
      occurredAt: row.occurredAt,
      appliedAt: row.appliedAt,
    );
  }
}
