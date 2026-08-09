import 'package:drift/drift.dart';

import 'businesses.dart';
import 'products.dart';

/// Báo giá của một nhà cung cấp cho một sản phẩm — WTM-327.
///
/// ## Vì sao `producers` chưa đủ
///
/// Bảng `producers` mô tả **nhà cung cấp**: tên, nước, rating, MOQ chung, lead
/// time chung. Nó trả lời *"nhà cung cấp này thế nào"*.
///
/// Câu hỏi P0 của Founder (§17) là câu khác: *"cho **sản phẩm này**, ai bán rẻ
/// hơn và giao nhanh hơn?"* — và câu đó cần giá **theo cặp (sản phẩm, nhà cung
/// cấp)**. Cùng một nhà cung cấp báo hai giá cho hai mặt hàng là chuyện bình
/// thường; nhét nó vào `producers` sẽ ép một giá duy nhất cho cả danh mục.
///
/// ## `products.supplierId` vẫn là "đang nhập của ai"
///
/// Bảng này là **các lựa chọn**, không phải lựa chọn hiện tại. Một sản phẩm có
/// một nhà cung cấp đang dùng và nhiều báo giá để so — trộn hai khái niệm sẽ
/// làm "đổi nhà cung cấp" thành một thao tác không ai truy được.
@TableIndex(name: 'supplier_quotes_business_id', columns: {#businessId})
@TableIndex(name: 'supplier_quotes_product_id', columns: {#productId})
@TableIndex(name: 'supplier_quotes_supplier_id', columns: {#supplierId})
class SupplierQuotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get productId =>
      text().references(ProductsTable, #id, onDelete: KeyAction.cascade)();

  /// **Không** khoá ngoại tới `producers`.
  ///
  /// Một báo giá tìm được trên Alibaba/1688 có thể chưa ứng với nhà cung cấp
  /// nào trong sổ. Ép khoá ngoại sẽ buộc phải tạo một `producer` rỗng cho mỗi
  /// báo giá — và sổ nhà cung cấp đầy những cái tên người bán chưa từng làm
  /// việc cùng.
  TextColumn get supplierId => text().nullable()();

  /// Tên hiển thị, giữ tại chỗ để một báo giá vẫn đọc được khi nhà cung cấp
  /// chưa có trong sổ.
  TextColumn get supplierName => text()();

  /// `alibaba` · `1688` · `aliexpress` · `local_vn` · `wholesale` ·
  /// `manufacturer` — **mã canonical**, không phải nhãn hiển thị.
  TextColumn get platform => text().nullable()();

  TextColumn get country => text().nullable()();

  /// Đường tới trang báo giá. Đây là thứ `BusinessAction` mở ra khi chưa có
  /// vendor API (§18) — nên nó là dữ liệu, không phải chú thích.
  TextColumn get sourceUrl => text().nullable()();

  /// 0–5. `null` = **chưa biết**, không phải 0 sao.
  RealColumn get rating => real().nullable()();

  RealColumn get unitCost => real()();
  TextColumn get currency => text().withDefault(const Constant('VND'))();

  /// Số lượng đặt tối thiểu. `null` = chưa biết, không phải "không giới hạn".
  RealColumn get minimumOrderQuantity => real().nullable()();

  /// `null` = **chưa biết**. So sánh phải nói "chưa biết" chứ không đoán
  /// (§17: không fake độ chính xác nếu không có input).
  IntColumn get leadTimeDays => integer().nullable()();

  TextColumn get paymentTerms => text().nullable()();
  TextColumn get shippingMethod => text().nullable()();
  TextColumn get notes => text().nullable()();

  TextColumn get externalId => text().nullable()();
  TextColumn get provenanceCode => text().nullable()();
  TextColumn get importJobId => text().nullable()();

  /// Báo giá cũ là báo giá sai. Giữ mốc để so sánh nói được *"giá này ghi từ
  /// ba tháng trước"* thay vì trình bày nó như giá hôm nay.
  DateTimeColumn get quotedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
