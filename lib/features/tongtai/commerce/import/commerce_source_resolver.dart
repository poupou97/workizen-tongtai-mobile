import 'dart:typed_data';

import '../../inventory/product.dart';
import 'commerce_import.dart';
import 'marketplace_export_source.dart';
import 'marketplace_profile.dart';
import 'xlsx_commerce_source.dart';
import 'xlsx_reader.dart';

/// Chọn đúng bộ đọc cho một file — WTM-322.
///
/// ## Một nút, không phải ba
///
/// Người bán có một file và một câu hỏi: *"nhập cái này vào được không?"*. Bắt
/// họ tự khai *"đây là file danh mục hay file đơn Shopee hay báo cáo thu
/// nhập"* là đẩy việc phân loại sang cho người ít có khả năng phân loại nhất.
///
/// Nên app **tự nhận**, và khi không nhận ra thì kể lại nó thấy gì
/// (`MarketplaceExportSource`) chứ không im lặng từ chối.
///
/// ## Thứ tự thử có lý do
///
/// File sàn nhận dạng được bằng **điểm số trên tên cột**, còn file danh mục
/// nhận dạng bằng **tên sheet `PRODUCTS`**. Thử sàn trước vì phép thử của nó
/// chặt hơn: một file danh mục không bao giờ vô tình đạt bốn cột trùng tên với
/// Shopee, còn chiều ngược lại thì có thể.
abstract final class CommerceSourceResolver {
  static CommerceImportSource resolve({
    required Uint8List bytes,
    required String fileName,
    required DateTime now,
    required List<Product> knownProducts,
    Set<String> existingOrderIds = const {},
    XlsxReader reader = const XlsxReader(),
  }) {
    if (_looksLikeMarketplaceExport(bytes, reader)) {
      return MarketplaceExportSource(
        bytes: bytes,
        fileName: fileName,
        now: now,
        knownProducts: knownProducts,
        existingOrderIds: existingOrderIds,
        reader: reader,
      );
    }
    return XlsxCommerceSource(bytes: bytes, fileName: fileName, now: now);
  }

  /// Đọc tiêu đề một lần để đoán. Hỏng thì trả `false` — bộ đọc danh mục sẽ
  /// gặp lại đúng lỗi đó và nói bằng câu của nó, thay vì hai chỗ cùng nói.
  static bool _looksLikeMarketplaceExport(Uint8List bytes, XlsxReader reader) {
    try {
      final sheets = reader.read(bytes);
      // File danh mục có sheet tên PRODUCTS — dấu hiệu chắc chắn hơn mọi điểm số.
      for (final name in sheets.keys) {
        if (name.trim().toUpperCase() == 'PRODUCTS') return false;
      }
      for (final rows in sheets.values) {
        if (rows.isEmpty) continue;
        if (MarketplaceMatch.detect(rows.first) != null) return true;
      }
      return false;
    } on Object {
      return false;
    }
  }
}
