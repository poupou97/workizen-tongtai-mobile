import 'package:drift/drift.dart';

import 'businesses.dart';

/// Mọi side effect của Agent — **cửa ghi duy nhất** (WTM-300 · D-3).
///
/// ## Vì sao khoá duy nhất là `(business, idempotency_key)`
///
/// Chạy lại một hành động không được sinh ra việc thứ hai: gửi tin hai lần,
/// đặt đơn hai lần, chuyển tiền hai lần. Khoá này là thứ chặn điều đó, và
/// `request_hash` là thứ chặn một lỗi tinh vi hơn — **hai việc khác nhau lỡ
/// trùng khoá sẽ lặng lẽ nuốt nhau** nếu chỉ có khoá mà không có vân tay.
///
/// ## Không khoá ngoại tới subject
///
/// Hành động có thể trỏ tới khách, sản phẩm, đơn — nhiều loại. Và lịch sử
/// hành động phải sống sót kể cả khi đối tượng bị xoá: *"đã gửi tin cho khách
/// này"* vẫn là sự thật sau khi khách bị xoá.
@TableIndex(name: 'business_actions_business_id', columns: {#businessId})
@TableIndex(name: 'business_actions_status', columns: {#status})
@TableIndex(name: 'business_actions_correlation', columns: {#correlationId})
@TableIndex(
  name: 'business_actions_idempotency',
  unique: true,
  columns: {#businessId, #idempotencyKey},
)
class BusinessActionsTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get correlationId => text().nullable()();

  /// Mã canonical `BusinessActionType`.
  TextColumn get type => text()();

  /// Mã canonical `ActionVendor` — kể cả `internal`.
  TextColumn get vendor => text()();

  TextColumn get subjectKind => text()();
  TextColumn get subjectId => text()();
  TextColumn get subjectLabel => text().nullable()();

  /// Câu tiếng Việt người bán đọc được.
  TextColumn get summary => text()();

  /// Tham số, JSON.
  TextColumn get parameters => text()();

  TextColumn get proposedBy => text()();

  /// `null` = **chưa ai duyệt**.
  TextColumn get requestedBy => text().nullable()();

  TextColumn get idempotencyKey => text()();

  /// Vân tay payload — cùng khoá mà khác vân tay ⇒ từ chối.
  TextColumn get requestHash => text()();

  /// Mã canonical `ActionStatus`.
  TextColumn get status => text()();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Hết hạn ⇒ ai đó nhận lại được, kể cả khi tiến trình trước đã chết.
  DateTimeColumn get leasedUntil => dateTime().nullable()();

  DateTimeColumn get plannedAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Mã kết quả ở hệ ngoài. `null` = **chưa có kết quả**.
  TextColumn get externalId => text().nullable()();

  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
