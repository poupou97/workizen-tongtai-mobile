import 'package:drift/drift.dart';

import 'businesses.dart';
import 'products.dart';

/// Phiên bản của một sản phẩm — WTM-327 (C3 · Epic WTM-324).
///
/// ## Vì sao là bảng riêng, không phải nhiều Product
///
/// Founder §4: *"Không duplicate Product thành nhiều Product nếu canonical
/// model hỗ trợ Variant."*
///
/// Một áo thun Đen/S và Đen/M là **một** sản phẩm với hai phiên bản, không
/// phải hai sản phẩm. Nhân chúng thành hai Product sẽ làm hỏng đúng những con
/// số người bán hỏi nhiều nhất: *"tôi có bao nhiêu mặt hàng"* nhảy gấp ba,
/// *"sản phẩm nào bán chạy"* xé một mặt hàng thành nhiều dòng nhỏ mà không
/// dòng nào nổi lên, và so sánh nhà cung cấp thì so cho từng size.
///
/// ## Hai option, không phải N
///
/// Shopify dừng ở ba; Shopee/TikTok thực tế dùng một hoặc hai (màu · size).
/// Hai cột tường minh đọc và truy vấn được; một mảng JSON thì không — và cái
/// giá của việc thêm option thứ ba sau này là một migration, không phải một
/// cuộc viết lại.
@TableIndex(name: 'product_variants_business_id', columns: {#businessId})
@TableIndex(name: 'product_variants_product_id', columns: {#productId})
@TableIndex(name: 'product_variants_sku', columns: {#sku})
class ProductVariantsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Xoá sản phẩm là xoá phiên bản của nó — một phiên bản không có sản phẩm mẹ
  /// là một dòng không ai đọc được nữa.
  TextColumn get productId =>
      text().references(ProductsTable, #id, onDelete: KeyAction.cascade)();

  /// Nhãn người bán đọc: "Đen / S".
  TextColumn get name => text()();

  TextColumn get sku => text()();

  /// Tên và giá trị của tối đa hai lựa chọn: ("Màu", "Đen") · ("Size", "S").
  TextColumn get option1Name => text().nullable()();
  TextColumn get option1Value => text().nullable()();
  TextColumn get option2Name => text().nullable()();
  TextColumn get option2Value => text().nullable()();

  /// `null` = **kế thừa giá của sản phẩm mẹ**, không phải "miễn phí".
  RealColumn get costPrice => real().nullable()();
  RealColumn get sellingPrice => real().nullable()();

  /// `null` = phiên bản này không theo dõi tồn, **không phải** hết hàng
  /// (cùng kỷ luật `products.totalStock` từ ADR-TON-023).
  RealColumn get quantity => real().nullable()();

  /// Mã ở nguồn ngoài (dòng Excel, id Shopify…). Cho phép nhập lại cùng file
  /// mà không sinh bản ghi thứ hai.
  TextColumn get externalId => text().nullable()();

  /// Bản ghi này từ đâu tới — mã canonical `ProvenanceSource`.
  TextColumn get provenanceCode => text().nullable()();

  /// Lần nhập nào tạo ra nó. Đây là thứ cho phép **xoá đúng một lần nhập**.
  TextColumn get importJobId => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
