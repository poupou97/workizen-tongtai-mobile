import 'package:drift/drift.dart';

import 'businesses.dart';

/// Kết nối tới nền tảng ngoài (WTM-283 · N0.2) — **metadata, không bí mật**.
///
/// Thay `integrations_table`, bảng có từ bootstrap v1 mà chưa từng có dòng
/// nào, và mang bốn cột `*Encrypted` — tức là nó mã hoá sẵn một quyết định:
/// *token nằm trong SQLite nghiệp vụ*. Quyết định đó trái luật credential của
/// Founder, và nguy hiểm thật chứ không chỉ trên lý thuyết: `.ttbk` mặc định
/// **không mã hoá**, nên token trong bảng nghiệp vụ sẽ đi thẳng vào file
/// backup — cộng sự cố 31/07 (hai file `.ttbk` bị gửi nhầm lên Zalo) thì
/// đường rò rỉ là có thật.
///
/// Bảng này **không có cột nào cho token**, và cũng không có cột cho *khoá tra*
/// credential: khoá tra suy ra được từ `id` (xem `CredentialReference`), nên
/// nó không cần lưu và do đó không thể lọt vào backup.
///
/// Tiền lệ xoá bảng chết: `opportunities_table` (WTM-190) và `channels_table`
/// (WTM-209) — một bảng rỗng nói dối về thiết kế thì bỏ đi có giá trị hơn giữ.
@TableIndex(name: 'connections_business_id', columns: {#businessId})
@TableIndex(name: 'connections_connector', columns: {#connectorId})
class ConnectionsTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Nền tảng nào — `github` · `revenuecat` · … Mã canonical, **không** phải
  /// khoá ngoại: cùng lý do `orders_table.channelId` bỏ FK ở v12 (một mã từ
  /// từ vựng đóng, không phải tham chiếu tới một dòng).
  TextColumn get connectorId => text()();

  /// Tên người bán tự đặt. Một người có thể nối nhiều tài khoản trên cùng một
  /// nền tảng, nên `connectorId` không đủ làm định danh.
  TextColumn get label => text()();

  /// Mã canonical `ConnectionStatus`. Mã lạ ⇒ đọc ra `null`, không rơi về
  /// `active` — một kết nối hỏng trông như đang chạy là kiểu nói dối tệ nhất
  /// ở đây.
  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// `null` = **chưa đồng bộ lần nào**, không phải "đồng bộ lúc 0".
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
