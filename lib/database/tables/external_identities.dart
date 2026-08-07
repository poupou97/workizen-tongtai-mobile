import 'package:drift/drift.dart';

import 'businesses.dart';
import 'customers.dart';

/// Danh tính của một người mua trên nền tảng ngoài, trỏ về `customers_table`
/// (WTM-291 · N0.3 · ADR-TON-024).
///
/// ## Vì sao không nhét thẳng vào `customers_table`
///
/// Bảng khách **đã có** `external_id` + `external_source` từ bootstrap v1 —
/// hai cột đơn, tức mỗi khách chỉ mang **một** danh tính ngoài. Đó chính là
/// giả định sai mà Wave 2 tồn tại để gỡ: một người mua có thể vừa là Shopee
/// buyer, vừa là Messenger PSID, vừa là số điện thoại — cùng lúc.
///
/// Hai cột cũ **để nguyên**, không migrate, không backfill: chưa có đường ghi
/// nào từ connector nên chúng đang rỗng, và ghi đè một suy đoán lên chúng sẽ
/// biến phỏng đoán thành lời khai (bài học v17 · `Provenance`).
///
/// ## Khoá duy nhất là (business, connection, platform, externalId)
///
/// **Không** phải `(platform, externalId)`. Cùng một `buyer_id` ở hai tài khoản
/// Shopee khác nhau là **hai người khác nhau** — nền tảng chỉ bảo đảm duy nhất
/// *trong phạm vi một shop*. Bỏ `connectionId` khỏi khoá là tự tay gộp hai
/// khách của hai shop thành một, và đó đúng là loại nhầm ADR-TON-024 cấm.
@TableIndex(name: 'external_identities_business_id', columns: {#businessId})
@TableIndex(name: 'external_identities_customer_id', columns: {#customerId})
@TableIndex(
  name: 'external_identities_lookup',
  unique: true,
  columns: {#businessId, #connectionId, #platform, #externalId},
)
class ExternalIdentitiesTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Mã canonical của nền tảng — `shopee` · `tiktok` · `messenger` · …
  ///
  /// Mã từ từ vựng đóng, **không** khoá ngoại (cùng lý do `orders_table
  /// .channelId` bỏ FK ở v12: một mã không phải tham chiếu tới một dòng).
  TextColumn get platform => text()();

  /// Mã do **nền tảng** cấp. Không bao giờ là nhãn hiển thị (ADR-TON-018).
  TextColumn get externalId => text()();

  /// Kết nối nào mang danh tính này về. **Không** khoá ngoại tới
  /// `connections_table`: gỡ một kết nối không được phép xoá lịch sử khách —
  /// đơn hàng đã ghi rồi thì người mua vẫn là người mua đó.
  TextColumn get connectionId => text()();

  /// Khách hàng mà danh tính này trỏ về. **Cascade**: xoá khách thì danh tính
  /// mồ côi không còn nghĩa gì.
  TextColumn get customerId =>
      text().references(CustomersTable, #id, onDelete: KeyAction.cascade)();

  /// Mã canonical `IdentityConfidence`. Mã lạ ⇒ đọc ra `null` ⇒ bản ghi hỏng,
  /// **không** rơi về `exact` (ADR-TON-018).
  TextColumn get confidence => text()();

  /// Mã canonical `IdentityLinkKind` — ai đã quyết định liên kết này.
  TextColumn get linkKind => text()();

  DateTimeColumn get linkedAt => dateTime()();

  /// Tên hiển thị lúc thấy — **chỉ để người bán nhận ra mặt**, không dùng để
  /// khớp. Khớp theo tên là nguồn của `weak`, và `weak` không tự động hoá gì.
  TextColumn get displayName => text().nullable()();

  /// `null` = **chưa xác nhận**, không phải "xác nhận lúc 0".
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
