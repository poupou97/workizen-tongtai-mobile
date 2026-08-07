import 'package:drift/drift.dart';

import 'businesses.dart';

/// Khoản tiền sàn giữ lại hoặc trả thêm, gắn với một đơn (WTM-292 · N0.4).
///
/// ## Vì sao `amount` không lưu dấu
///
/// `amount` **luôn dương**, chiều nằm ở cột `direction` riêng. Nếu chiều nằm ở
/// dấu của số thì một connector viết `-50000` và một connector khác viết
/// `50000` cho cùng một sự việc — và không ai phát hiện tới khi báo cáo lệch.
///
/// ## Vì sao `funded_by` không có DEFAULT
///
/// Cột không nullable và **không có giá trị mặc định**: một `DEFAULT 'platform'`
/// ở đây là app tự khai thay cho sàn rằng *"sàn tài trợ"*, và nó rơi đúng vào
/// hướng làm lợi nhuận đẹp lên. Connector không biết thì ghi `unknown`, và
/// Rule Twin từ chối trả số lợi nhuận.
///
/// Không khoá ngoại tới `orders_table`: khoản đối soát có thể về **trước** khi
/// đơn được đồng bộ xong, và một FK ở đây biến thứ tự đồng bộ thành lỗi ghi
/// (bài học 787 ở v12).
@TableIndex(name: 'settlement_lines_business_id', columns: {#businessId})
@TableIndex(name: 'settlement_lines_order_id', columns: {#orderId})
@TableIndex(name: 'settlement_lines_payout_id', columns: {#payoutId})
class SettlementLinesTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Luôn có — một khoản không gắn đơn là giao dịch Finance bình thường.
  TextColumn get orderId => text()();

  /// `null` = khoản **cấp đơn**, không phải "chưa biết món nào".
  TextColumn get orderItemId => text().nullable()();

  /// Mã canonical `SettlementKind`. Mã lạ ⇒ đọc ra `null` ⇒ bản ghi hỏng.
  TextColumn get kind => text()();

  /// Mã canonical `SettlementDirection`.
  TextColumn get direction => text()();

  /// **Luôn dương.**
  RealColumn get amount => real()();

  TextColumn get currency => text()();

  DateTimeColumn get occurredAt => dateTime()();

  /// Mã canonical `FundingSource`. **Không DEFAULT** — xem doc của lớp.
  TextColumn get fundedBy => text()();

  /// Tỷ lệ người bán chịu khi `funded_by = 'shared'`, 0..1.
  /// `null` với `shared` ⇒ thực chất là chưa biết.
  RealColumn get sellerShare => real().nullable()();

  /// `null` = **chưa về tài khoản**, không phải "về lúc 0".
  TextColumn get payoutId => text().nullable()();

  /// Mã canonical `Provenance` (WTM-282). `null` ⇒ suy từ tiền tố id lúc đọc
  /// và đánh dấu `inferred` — không ghi suy đoán xuống đĩa.
  TextColumn get provenanceCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
