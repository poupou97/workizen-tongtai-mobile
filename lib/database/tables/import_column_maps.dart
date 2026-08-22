import 'package:drift/drift.dart';

import 'businesses.dart';

/// Bản đồ cột người bán tự chỉ — WTM-443 (Epic WTM-440).
///
/// ## Vì sao lưu, thay vì hỏi lại mỗi lần
///
/// Người bán xuất file **hằng tháng**. Bắt họ ghép lại chín cột mỗi lần là
/// biến một tính năng cứu nguy thành một hình phạt, và họ sẽ thôi nhập.
///
/// ## Khoá tự nhiên, không có cột `id`
///
/// Khoá là `(businessId, vendor, fileKind)` — đúng một bản đồ cho mỗi sàn mỗi
/// loại file. Đặt như vậy thì **cấu trúc** ngăn hai bản đồ cùng khớp, thay vì
/// trông cậy vào mã ứng dụng nhớ dọn bản cũ. (Đường đọc vẫn xử lý được tình
/// huống hai bản đồ cùng khớp — dữ liệu cũ hoặc khôi phục từ `.ttbk` của bản
/// dựng khác — nhưng nó không nên xảy ra ngay từ đầu.)
///
/// ## `columns` là JSON, cố ý
///
/// Theo ADR-TON-009 / WTM-122: giữ trong JSON tới khi có **cớ nghiệp vụ thật**
/// để tách cột — truy vấn thường xuyên, chỉ mục, khoá ngoại, thống kê. Không
/// cái nào đúng ở đây: bản đồ luôn được đọc **cả cụm**, cho đúng một sàn, ngay
/// trước khi đọc file. Tách thành bảng con chỉ thêm một phép nối mà không ai
/// cần.
///
/// Nội dung JSON là `{"<mã vai trò canonical>": "<tên cột trong file>"}`. Vai
/// trò là **mã canonical** (`MarketplaceField.name`), không phải nhãn hiển thị
/// — ADR-TON-018. Tên cột thì ngược lại: nó là **chuỗi thật của người bán**,
/// nguyên văn, kể cả dấu tiếng Việt và khoảng trắng.
@TableIndex(name: 'import_column_maps_business_id', columns: {#businessId})
class ImportColumnMapsTable extends Table {
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Mã sàn canonical, hoặc `marketplace_other` khi người bán nói *"sàn
  /// khác"*. Cùng quy ước `orders_table.channelId`: một mã từ từ vựng đóng,
  /// **không** phải khoá ngoại.
  TextColumn get vendor => text()();

  /// `MarketplaceFileKind` — `orders` · `income`.
  ///
  /// Một sàn cần **hai** bản đồ, không phải một: file đơn và báo cáo thu nhập
  /// là hai file khác nhau với hai bộ cột khác nhau. Gộp chúng lại là cách
  /// chắc chắn để nhập được doanh thu mà không nhập được phí — tức là in ra
  /// lợi nhuận đẹp hơn sự thật.
  TextColumn get fileKind => text()();

  /// JSON — xem chú thích của lớp.
  TextColumn get columns => text()();

  /// Lần cuối người bán xác nhận bản đồ này.
  ///
  /// Không phải trang trí: sàn đổi định dạng thì bản đồ cũ thành sai, và ngày
  /// tháng là thứ duy nhất nói cho người bán biết bản đồ này đã bao lâu rồi.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {businessId, vendor, fileKind};
}
