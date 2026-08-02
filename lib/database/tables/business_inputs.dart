import 'package:drift/drift.dart';

/// Nguồn đầu vào của doanh nghiệp (WTM-229, ADR-TON-023) — schema v16.
///
/// Producer **không phải** danh bạ nhà cung cấp: nó quản lý **toàn bộ đầu
/// vào**, và nhà cung cấp chỉ là một loại. Dogfood Workizen cho thấy đầu vào
/// của một doanh nghiệp AI-first là provider · hạ tầng · công cụ · thời gian,
/// và cả bốn hôm nay rơi hết vào `FinanceCategory.other`.
///
/// ## Vì sao mọi trường tuỳ chọn đều nullable
/// Người bán khai dần: hôm nay chỉ biết tên, tuần sau mới biết trả bao nhiêu.
/// `NULL` = **chưa khai**, không bao giờ là 0 — cùng kỷ luật `cost_per_unit`
/// (WTM-204), `payment_status` (WTM-211), `total_stock` (WTM-227).
///
/// ## Tiền nằm ở đâu
/// Bảng này **không** giữ số tiền đã chi. Sổ thu chi vẫn là chủ sở hữu của
/// tiền; ở đây chỉ có *kỳ vọng* để trả lời "tháng này tôi cam kết trả bao
/// nhiêu". Chép số tiền đã chi sang đây sẽ là sự thật thứ hai về cùng một
/// đồng bạc.
class BusinessInputsTable extends Table {
  TextColumn get id => text()();

  /// Khoá theo doanh nghiệp, như mọi bảng nghiệp vụ khác (ADR-TON-008).
  TextColumn get businessId => text()();

  TextColumn get name => text()();

  /// `BusinessInputKind` bằng **mã canonical**, không bao giờ là nhãn.
  TextColumn get kind => text()();

  /// `InputCadence` bằng mã canonical. `NULL` = chưa khai nhịp trả tiền.
  TextColumn get cadence => text().nullable()();

  /// Số tiền mỗi nhịp. `NULL` = **chưa nhập**, không phải miễn phí.
  RealColumn get expectedAmount => real().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
