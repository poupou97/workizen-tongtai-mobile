import 'package:drift/drift.dart';

import 'businesses.dart';

/// Việc bền vững của Agent (WTM-301 · D-4).
///
/// ## Không cột nào mang nghĩa "mobile"
///
/// Không `app_session_id`, không `is_foreground`, không `work_manager_id`.
/// Điều kiện của Founder: **cùng một task phải chạy được trên Workizen Managed
/// Worker / Oracle VM 24/7 mà không đổi business model**. Một cột mang nghĩa
/// mobile sẽ biến việc đổi runner thành việc đổi schema.
///
/// ## `leased_until` là thứ làm "app bị kill" và "worker chết" thành một
///
/// Cả hai đều là *giữ việc rồi biến mất*. Một cơ chế xử lý cả hai, nên runner
/// nào cũng dùng đúng giao thức đó.
@TableIndex(name: 'agent_tasks_business_id', columns: {#businessId})
@TableIndex(name: 'agent_tasks_due', columns: {#dueAt})
@TableIndex(name: 'agent_tasks_correlation', columns: {#correlationId})
@TableIndex(
  name: 'agent_tasks_open_subject',
  columns: {#businessId, #kind, #subjectKind, #subjectId},
)
class AgentTasksTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get correlationId => text().nullable()();

  /// Mã canonical `AgentTaskKind`.
  TextColumn get kind => text()();

  /// **Viết cho người đọc** — đi vào lời nhắn cho agent và màn hình người bán.
  TextColumn get reason => text()();

  TextColumn get subjectKind => text().nullable()();
  TextColumn get subjectId => text().nullable()();

  DateTimeColumn get dueAt => dateTime()();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Số lượt gọi vendor lần chạy này được tiêu.
  IntColumn get budget => integer().withDefault(const Constant(4))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// `null` = **không ai đang giữ việc**.
  DateTimeColumn get leasedUntil => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// `null` = **chưa xong**, không phải "xong lúc 0".
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Mã canonical `AgentTaskOutcome`.
  TextColumn get outcome => text().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
