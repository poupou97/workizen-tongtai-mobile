import 'package:drift/drift.dart';

import 'businesses.dart';

/// Chuyến giao hàng — WTM-323 (C7 · Epic WTM-315).
///
/// ## Vì sao là bảng riêng chứ không phải cột trên `orders`
///
/// Một đơn có thể tách thành nhiều kiện (sàn tách theo kho), và một kiện có thể
/// gộp nhiều đơn. Nhét mã vận đơn thành một cột trên `orders` sẽ hỏng ở cả hai
/// chiều — và hỏng im lặng, vì cột vẫn nhận được một giá trị.
///
/// ## Không lưu số ngày đứng im
///
/// *"Ba ngày không nhúc nhích"* là **dữ liệu dẫn xuất** từ `lastUpdate` và
/// đồng hồ. Lưu nó xuống thì hôm sau con số sai mà không ai chạm vào bản ghi —
/// đúng kỷ luật `settlement_no_derived_write` đã có.
@TableIndex(name: 'shipments_business_id', columns: {#businessId})
@TableIndex(name: 'shipments_order_id', columns: {#orderId})
@TableIndex(name: 'shipments_tracking', columns: {#trackingNumber})
class ShipmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// **Không** khoá ngoại tới `orders`: một kiện có thể tới trước khi đơn được
  /// nhập, và "đã giao cho khách này" vẫn là sự thật sau khi đơn bị xoá.
  TextColumn get orderId => text().nullable()();

  TextColumn get trackingNumber => text()();

  /// Mã canonical hãng vận chuyển — `ghn` · `ghtk` · `viettel_post` · `jt`.
  TextColumn get carrier => text().nullable()();

  /// Mã canonical trạng thái. Mã lạ ⇒ bỏ dòng, không rơi về "đang giao".
  TextColumn get status => text()();

  /// Lần hãng cập nhật gần nhất. **`null` = chưa có tin nào**, không phải
  /// "cập nhật lúc 0" — và đó là khác biệt quyết định việc có cảnh báo hay không.
  DateTimeColumn get lastUpdate => dateTime().nullable()();

  /// Dự kiến giao. `null` = hãng chưa nói.
  DateTimeColumn get eta => dateTime().nullable()();

  TextColumn get origin => text().nullable()();
  TextColumn get destination => text().nullable()();
  TextColumn get notes => text().nullable()();

  TextColumn get externalId => text().nullable()();
  TextColumn get provenanceCode => text().nullable()();
  TextColumn get importJobId => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
