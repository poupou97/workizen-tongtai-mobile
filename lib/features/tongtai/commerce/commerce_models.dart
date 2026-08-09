import 'package:flutter/foundation.dart';

import '../core/provenance.dart';

/// Miền thương mại chuẩn hoá — WTM-327 (C3 · Epic WTM-324).
///
/// ## ⭐ Nguồn thay được, miền thì không
///
/// Founder §2: *"File Bridge là một NGUỒN, không phải một MIỀN."*
///
/// Excel là Source Adapter **đầu tiên**. Shopify/Shopee/TikTok/eBay/Amazon sau
/// này đưa vào **cùng** những lớp dưới đây; Alibaba/1688/AliExpress làm giàu
/// [SupplierQuote]. Không lớp nào ở đây biết Excel tồn tại — đó là điều kiện
/// để thêm vendor không phải viết lại miền.

/// Một phiên bản của sản phẩm: "Đen / S", "Size 40".
@immutable
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    this.option1Name,
    this.option1Value,
    this.option2Name,
    this.option2Value,
    this.costPrice,
    this.sellingPrice,
    this.quantity,
    this.externalId,
    this.provenance = ProvenanceSource.manual,
    this.importJobId,
  });

  final String id;
  final String productId;
  final String name;
  final String sku;

  final String? option1Name;
  final String? option1Value;
  final String? option2Name;
  final String? option2Value;

  /// `null` = **kế thừa giá sản phẩm mẹ**, không phải miễn phí.
  final double? costPrice;
  final double? sellingPrice;

  /// `null` = phiên bản này không theo dõi tồn, **không phải** hết hàng.
  final double? quantity;

  final String? externalId;
  final ProvenanceSource provenance;
  final String? importJobId;

  /// Giá bán thật, có xét kế thừa. `null` khi cả hai đều chưa biết —
  /// **không** rơi về 0, vì 0 đồng là một câu trả lời sai chứ không phải im
  /// lặng.
  double? effectiveSellingPrice(double? parentPrice) =>
      sellingPrice ?? parentPrice;

  double? effectiveCostPrice(double? parentCost) => costPrice ?? parentCost;

  @override
  bool operator ==(Object other) => other is ProductVariant && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Nền tảng của một nhà cung cấp — **mã canonical**, không phải nhãn.
enum SupplierPlatform {
  alibaba('alibaba'),
  taobao1688('1688'),
  aliexpress('aliexpress'),
  localVn('local_vn'),
  wholesale('wholesale'),
  manufacturer('manufacturer');

  const SupplierPlatform(this.code);

  final String code;

  /// Mã lạ ⇒ `null`. Không rơi về `localVn`: một nguồn Trung Quốc hiện thành
  /// nguồn trong nước sẽ làm người bán tính sai cả lead time lẫn thuế.
  static SupplierPlatform? fromCode(String? code) {
    for (final p in SupplierPlatform.values) {
      if (p.code == code) return p;
    }
    return null;
  }
}

/// Báo giá của một nhà cung cấp **cho một sản phẩm cụ thể**.
///
/// Đây là thứ trả lời câu hỏi P0 của Founder (§17): *"cho sản phẩm này, ai bán
/// rẻ hơn và giao nhanh hơn?"* — khác hẳn câu `producers` trả lời (*"nhà cung
/// cấp này thế nào"*).
@immutable
class SupplierQuote {
  const SupplierQuote({
    required this.id,
    required this.productId,
    required this.supplierName,
    required this.unitCost,
    required this.quotedAt,
    this.supplierId,
    this.platform,
    this.country,
    this.sourceUrl,
    this.rating,
    this.currency = 'VND',
    this.minimumOrderQuantity,
    this.leadTimeDays,
    this.paymentTerms,
    this.shippingMethod,
    this.notes,
    this.externalId,
    this.provenance = ProvenanceSource.manual,
    this.importJobId,
  });

  final String id;
  final String productId;

  /// `null` = nhà cung cấp chưa có trong sổ. Báo giá vẫn đọc được — ép mọi báo
  /// giá phải có một `producer` sẽ làm sổ đầy những cái tên chưa từng làm việc
  /// cùng.
  final String? supplierId;

  final String supplierName;
  final SupplierPlatform? platform;
  final String? country;
  final String? sourceUrl;

  /// 0–5. `null` = **chưa biết**, không phải 0 sao.
  final double? rating;

  final double unitCost;
  final String currency;

  final double? minimumOrderQuantity;

  /// `null` = chưa biết. So sánh phải **nói ra** là chưa biết (§17: không fake
  /// độ chính xác nếu không có input).
  final int? leadTimeDays;

  final String? paymentTerms;
  final String? shippingMethod;
  final String? notes;

  final String? externalId;
  final ProvenanceSource provenance;
  final String? importJobId;

  /// Báo giá cũ là báo giá sai. Giữ mốc để nói được *"giá ghi từ ba tháng
  /// trước"* thay vì trình bày nó như giá hôm nay.
  final DateTime quotedAt;

  int daysOldAt(DateTime now) => now.difference(quotedAt).inDays;

  @override
  bool operator ==(Object other) => other is SupplierQuote && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Một lần nhập dữ liệu từ nguồn ngoài.
@immutable
class ImportJob {
  const ImportJob({
    required this.id,
    required this.source,
    required this.importedAt,
    this.sourceVendor,
    this.sourceFile,
    this.sourceAccount,
    this.sourceChecksum,
    this.recordCounts = const {},
    this.warnings = const [],
    this.isDemo = false,
  });

  final String id;

  /// `fileBridge` hôm nay; `connector` khi có vendor API.
  final ProvenanceSource source;

  /// `google_drive` · `local_file` · sau này `shopify`…
  final String? sourceVendor;

  /// Tên file người bán nhìn thấy — câu trả lời cho *"số này ở đâu ra"*.
  final String? sourceFile;

  final String? sourceAccount;

  /// SHA-256 nội dung. Chống nhập trùng bằng **nội dung**, không bằng tên file
  /// (tên đổi được).
  final String? sourceChecksum;

  /// `{"products": 100, "orders": 96}` — chụp lúc nhập, **không** tính lại lúc
  /// đọc: đếm lại sau khi người bán sửa vài dòng sẽ ra con số khác, và con số
  /// đó không còn mô tả lần nhập nữa.
  final Map<String, int> recordCounts;

  final List<String> warnings;

  /// §14 — dữ liệu demo hay dữ liệu thật. Cờ nằm ở **lần nhập**, không ở từng
  /// dòng: một file demo không thể có vài dòng thật.
  final bool isDemo;

  final DateTime importedAt;

  int get totalRecords =>
      recordCounts.values.fold(0, (sum, value) => sum + value);

  @override
  bool operator ==(Object other) => other is ImportJob && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Nguồn của một lần nhập — mã canonical cho `import_jobs.source_vendor`.
abstract final class ImportVendor {
  /// File chọn từ Google Drive.
  static const String googleDrive = 'google_drive';

  /// File chọn từ máy.
  static const String localFile = 'local_file';

  /// Bộ dữ liệu demo đóng gói sẵn trong app.
  static const String bundledDemo = 'bundled_demo';
}
