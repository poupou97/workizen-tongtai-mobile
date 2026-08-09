import 'package:flutter/foundation.dart';

import '../../consumer/customer.dart';
import '../../finance/settlement.dart';
import '../../inventory/product.dart';
import '../../orders/order.dart';
import '../commerce_models.dart';

/// Kết quả đọc một nguồn hàng — WTM-326 (C2 · Epic WTM-324).
///
/// ## §25 — abstraction NHỎ, không phải framework
///
/// Founder: *"không xây connector framework lớn. Chỉ abstraction nhỏ nếu Excel
/// + future vendor chứng minh cần."*
///
/// Nên hợp đồng ở đây đúng **ba** bước, và chúng là ba bước đã có thật trong
/// luồng Excel — không phải ba bước tưởng tượng ra cho một vendor chưa tồn tại:
///
/// ```
/// parse()  → đọc thành bảng
/// validate() → phân loại ERROR / WARNING / INFO
/// normalize() → dựng bản ghi canonical
/// ```
abstract interface class CommerceImportSource {
  /// Tên người bán nhìn thấy — hiện trong màn xem trước và trong `import_jobs`.
  String get displayName;

  /// Đọc, kiểm tra, chuẩn hoá. Một lần gọi trả về **đủ để xem trước**, chưa
  /// ghi gì cả.
  ///
  /// Tách `parse`/`validate`/`normalize` thành ba lời gọi công khai sẽ mời gọi
  /// chỗ khác gọi `normalize` mà bỏ qua `validate`. Ở đây chúng là ba giai
  /// đoạn **bên trong** một lời gọi, nên không có đường vòng.
  Future<CommerceImportPreview> read();
}

/// Mức nghiêm trọng của một phát hiện lúc kiểm tra (§13).
enum ImportIssueLevel {
  /// **Chặn** phần liên quan. Không chặn cả file vì một dòng — một danh mục
  /// 100 sản phẩm không đáng bị từ chối vì một đơn hàng hỏng.
  error('error'),

  /// Nhập được, nhưng người bán nên biết. Họ quyết.
  warning('warning'),

  /// Chỉ để nói cho biết.
  info('info');

  const ImportIssueLevel(this.code);

  final String code;
}

/// Một phát hiện, **nói bằng ngôn ngữ nghiệp vụ** (§27).
///
/// ⛔ Không "row 42 column J parse error". Người bán không có row 42; họ có
/// *"Áo thun cotton"* và *"thiếu giá vốn"*.
@immutable
class ImportIssue {
  const ImportIssue({
    required this.level,
    required this.code,
    required this.subject,
    required this.detail,
    this.sheet,
    this.rowNumber,
  });

  final ImportIssueLevel level;

  /// Mã canonical để đếm và gom nhóm — `duplicate_sku` · `missing_cost`…
  final String code;

  /// Người bán nhận ra cái gì đang có vấn đề: tên sản phẩm, mã đơn.
  final String subject;

  /// Một câu tiếng Việt.
  final String detail;

  /// Chỗ sửa — hiện **nhỏ**, dưới câu tiếng Việt, để ai muốn mở Excel ra sửa
  /// thì tìm được. Không phải nội dung chính.
  final String? sheet;
  final int? rowNumber;

  bool get blocks => level == ImportIssueLevel.error;
}

/// Những gì đã đọc được, **trước khi ghi bất cứ thứ gì**.
@immutable
class CommerceImportPreview {
  const CommerceImportPreview({
    required this.sourceName,
    required this.checksum,
    this.products = const [],
    this.variants = const [],
    this.quotes = const [],
    this.customers = const [],
    this.orders = const [],
    this.settlements = const [],
    this.issues = const [],
  });

  /// Xem trước rỗng vì file không đọc được. Không phải "file rỗng" — chỗ gọi
  /// phân biệt bằng chính danh sách `issues`.
  factory CommerceImportPreview.rejected({
    required String sourceName,
    required ImportIssue issue,
  }) => CommerceImportPreview(
    sourceName: sourceName,
    checksum: '',
    issues: [issue],
  );

  final String sourceName;

  /// SHA-256 của nội dung file — nhận ra "đã nhập file này rồi".
  final String checksum;

  final List<Product> products;
  final List<ProductVariant> variants;
  final List<SupplierQuote> quotes;
  final List<Customer> customers;
  final List<CustomerOrder> orders;
  final List<SettlementLine> settlements;

  final List<ImportIssue> issues;

  List<ImportIssue> get errors => [
    for (final i in issues)
      if (i.level == ImportIssueLevel.error) i,
  ];

  List<ImportIssue> get warnings => [
    for (final i in issues)
      if (i.level == ImportIssueLevel.warning) i,
  ];

  /// Còn gì để nhập không.
  ///
  /// Có lỗi **không** đồng nghĩa với không nhập được: lỗi ở một đơn hàng
  /// không ngăn 100 sản phẩm đi vào. Chỉ khi không còn bản ghi nào hợp lệ thì
  /// mới thật sự không có gì để làm.
  bool get hasAnythingToImport =>
      products.isNotEmpty ||
      customers.isNotEmpty ||
      orders.isNotEmpty ||
      variants.isNotEmpty ||
      quotes.isNotEmpty;

  /// Số đếm theo loại — thứ màn xem trước hiện lên.
  Map<String, int> get counts => {
    'products': products.length,
    'variants': variants.length,
    'quotes': quotes.length,
    'customers': customers.length,
    'orders': orders.length,
    'settlements': settlements.length,
  };
}

/// Những gì đã thật sự ghi xuống.
@immutable
class CommerceImportResult {
  const CommerceImportResult({
    required this.job,
    required this.counts,
    this.skipped = const [],
  });

  final ImportJob job;

  /// Đếm **sau khi ghi**, không phải đếm lúc xem trước. Hai con số này có thể
  /// khác nhau, và khi khác thì con số sau mới là sự thật.
  final Map<String, int> counts;

  /// Những gì đã bị bỏ qua và vì sao — để màn hình nói được, thay vì để người
  /// bán tự phát hiện thiếu sau ba tuần.
  final List<ImportIssue> skipped;

  int get total => counts.values.fold(0, (sum, v) => sum + v);
}
