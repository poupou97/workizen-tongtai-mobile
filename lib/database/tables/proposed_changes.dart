import 'package:drift/drift.dart';

import 'businesses.dart';

/// Đề nghị đổi một sự thật nghiệp vụ — **chưa phải sự thật** (WTM-299 · D-2).
///
/// ## Vì sao cần một bảng, không phải một giá trị trả về
///
/// Trước WTM-299, `SuggestLink` là giá trị trong bộ nhớ: không sống qua một
/// lần đóng app. Nghĩa là Tổng Tài **không thể** lên mức **L2 · Prepare** —
/// AI chuẩn bị sẵn, người bán bấm xác nhận — vì không có chỗ nào giữ cái "đã
/// chuẩn bị sẵn".
///
/// ## Không có cột `confidence` thô
///
/// Mức tin cậy **tính** từ `evidence` lúc đọc (WTM-298). Lưu một con số khai
/// sẵn ở đây là mở lại đúng cửa sau vừa đóng.
@TableIndex(name: 'proposed_changes_business_id', columns: {#businessId})
@TableIndex(name: 'proposed_changes_status', columns: {#status})
@TableIndex(
  name: 'proposed_changes_subject',
  columns: {#subjectKind, #subjectId},
)
@TableIndex(name: 'proposed_changes_correlation', columns: {#correlationId})
class ProposedChangesTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Nối các bản ghi cùng một chuỗi việc. `null` = việc đứng một mình.
  ///
  /// Đây là thứ thay cho entity `BusinessConversation`: câu chuyện là một
  /// **truy vấn** theo cột này (WTM-296 §10).
  TextColumn get correlationId => text().nullable()();

  /// Mã canonical `ProposalDomain` — quyết định luật xét lại.
  TextColumn get domain => text()();

  TextColumn get subjectKind => text()();
  TextColumn get subjectId => text()();
  TextColumn get subjectLabel => text().nullable()();

  TextColumn get field => text()();

  /// `null` = ô đang **trống**, không phải "bằng không".
  TextColumn get currentValue => text().nullable()();

  TextColumn get proposedValue => text()();

  /// Bằng chứng, JSON. Mức tin cậy tính từ đây lúc đọc — **không** lưu điểm.
  TextColumn get evidence => text()();

  /// `seller` · `agent` · `rule:<tên>`. Dùng để gỡ hàng loạt khi một luật sai.
  TextColumn get proposedBy => text()();

  /// Câu tiếng Việt người bán đọc. Lưu cùng bản ghi để lời giải thích không
  /// lệch khỏi dữ liệu.
  TextColumn get summary => text()();

  /// Mã canonical `ProposalStatus`.
  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// `null` = **chưa ai quyết**, không phải "quyết lúc 0".
  DateTimeColumn get decidedAt => dateTime().nullable()();

  TextColumn get provenanceCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
