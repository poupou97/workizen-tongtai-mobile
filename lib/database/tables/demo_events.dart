import 'package:drift/drift.dart';

import 'businesses.dart';

/// Sổ sự kiện của doanh nghiệp demo — WTM-337 (E1 · Epic WTM-336).
///
/// ## ⭐ MỘT bảng, không phải sáu
///
/// Founder §41 cấm over-engineer. Bản mô phỏng cần hội thoại · bình luận ·
/// đánh giá · ca hỗ trợ · chiến dịch · lead — sáu khái niệm, và cách hiển
/// nhiên là sáu bảng.
///
/// Nhưng cả sáu đều là **những chuyện đã xảy ra vào một thời điểm, gắn với một
/// đối tượng**. Đó chính xác là một sự kiện. Nên ở đây có một bảng, và sáu thứ
/// kia là **hình chiếu** đọc ra từ nó.
///
/// Hệ quả tốt ngoài dự tính: **dòng thời gian doanh nghiệp (§37) có sẵn** — sổ
/// này *chính là* dòng thời gian, không phải một thứ dựng thêm để hiển thị.
///
/// ## Sự kiện lái repository THẬT
///
/// Đơn về thì `OrderRepository` nhận, phí sàn thì `SettlementRepository` nhận,
/// kiện hàng thì `ShipmentRepository` nhận. Bảng này **không** giữ bản sao của
/// chúng — nó giữ *"chuyện gì đã xảy ra"*, còn *"doanh nghiệp đang thế nào"*
/// vẫn nằm ở miền thật.
///
/// Nếu làm ngược lại, bản demo sẽ có một miền song song, và mọi màn hình phải
/// biết đang ở chế độ nào — đúng thứ ADR-TON-014 đã cấm.
@TableIndex(name: 'demo_events_business_id', columns: {#businessId})
@TableIndex(name: 'demo_events_occurred_at', columns: {#occurredAt})
@TableIndex(name: 'demo_events_correlation', columns: {#correlationId})
class DemoEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Mã canonical loại sự kiện — mười bảy loại của §34.
  TextColumn get kind => text()();

  /// Ai gây ra: `platform` (sàn/hãng) · `agent` (Tổng Tài) · `seller` (bạn).
  ///
  /// Ba chủ thể này là **nội dung** của dòng thời gian, không phải chi tiết kỹ
  /// thuật: người bán cần thấy việc nào do máy làm và việc nào do mình làm.
  TextColumn get actor => text()();

  /// Nền tảng liên quan — `shopee` · `facebook` · `ghn`… `null` khi nội bộ.
  TextColumn get vendor => text().nullable()();

  TextColumn get subjectKind => text().nullable()();
  TextColumn get subjectId => text().nullable()();

  /// Nối các sự kiện của **cùng một câu chuyện**.
  ///
  /// Đây là thứ thay cho một entity `BusinessConversation` (WTM-296 §10): một
  /// bình luận, câu trả lời, đơn hàng và kiện hàng của cùng một khách đọc liền
  /// mạch mà không cần bảng thứ hai.
  TextColumn get correlationId => text().nullable()();

  /// Câu người bán đọc. Đã là tiếng Việt, không phải mã.
  TextColumn get headline => text()();

  /// Chi tiết theo loại — JSON.
  TextColumn get payload => text().nullable()();

  /// Lúc chuyện xảy ra **trong thế giới mô phỏng**, không phải lúc ghi dòng.
  DateTimeColumn get occurredAt => dateTime()();

  /// Lúc sự kiện được **áp vào miền thật**. `null` = chưa tới lượt.
  ///
  /// Tách hai mốc là điều kiện để đồng hồ chạy được: engine sinh sẵn 30 ngày
  /// sự kiện, rồi mỗi lần bấm "Ngày tiếp" chỉ áp những cái đã tới hạn.
  DateTimeColumn get appliedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
