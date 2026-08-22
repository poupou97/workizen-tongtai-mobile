import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../profile/business_profile.dart' show SalesChannel;
import 'marketplace_profile.dart';

/// Người bán tự chỉ cột nào là cột nào — WTM-443 (Epic WTM-440).
///
/// ## Vì sao lớp này tồn tại
///
/// `MarketplaceProfile` đoán tên cột từ tài liệu sàn. Sáu hồ sơ hiện có đều
/// **chưa đối chiếu một file thật nào** — và kế hoạch đối chiếu ("xin một file
/// xuất thật") hỏng ở ba chỗ:
///
/// 1. **không kiếm được** — file xuất chỉ có ở Seller Centre của shop đang bán;
/// 2. **xin được thì vướng quyền riêng tư** — file đơn Shopee mang tên · số
///    điện thoại · địa chỉ của **khách hàng người ta**;
/// 3. **kiểm xong vẫn hỏng lần sau** — sàn đổi tên cột là hồ sơ vỡ.
///
/// Nên câu hỏi đúng không phải *"kiếm file ở đâu"* mà **"sao app phải đoán
/// đúng ngay từ đầu?"**. Lớp này là câu trả lời: app đoán trước, người bán sửa
/// lại nếu sai, và **app nhớ**. File không bao giờ rời máy họ.
///
/// ## Nó KHÔNG làm nhẹ đi trách nhiệm của hồ sơ đoán sẵn
///
/// Hồ sơ vẫn có ích — chúng là **phát đoán đầu tiên** để người bán không phải
/// chỉ tay từ số không. Chúng chỉ thôi làm **chốt chặn**.
@immutable
class ImportColumnMap {
  const ImportColumnMap({
    required this.vendor,
    required this.kind,
    required this.columns,
  });

  /// Mã sàn canonical — khớp [MarketplaceProfile.vendor], hoặc
  /// [kOtherMarketplaceVendor] khi người bán nói *"sàn khác"*.
  final String vendor;

  final MarketplaceFileKind kind;

  /// Vai trò canonical ⇒ **tên cột thật trong file của người bán**.
  ///
  /// Chiều này, không phải chiều ngược: một vai trò chỉ có một cột, còn một
  /// cột về lý thuyết có thể phục vụ hai vai trò.
  final Map<MarketplaceField, String> columns;

  /// Mã cho sàn app chưa có hồ sơ — Temu, Sendo, một sàn nội địa nào đó.
  ///
  /// ⚠️ Đây **không phải** nhánh mặc định trá hình. Nó là một lời khai tường
  /// minh: *"có một sàn ở giữa, tôi không biết sàn nào."* Phân biệt với việc
  /// im lặng coi như không có sàn — thứ làm lợi nhuận sai theo hướng tâng bốc
  /// (P-47).
  static const String kOtherMarketplaceVendor = 'marketplace_other';

  /// Vai trò **bắt buộc** phải có thì mới đọc được file.
  ///
  /// Thiếu một trong số này ⇒ chặn, nói rõ thiếu vai trò gì. Nhập nửa vời tệ
  /// hơn không nhập: một đơn không có mã thì lần nhập sau đếm nó lần nữa.
  static Set<MarketplaceField> requiredFor(MarketplaceFileKind kind) =>
      switch (kind) {
        MarketplaceFileKind.orders => const {
          MarketplaceField.orderId,
          MarketplaceField.sku,
          MarketplaceField.quantity,
          MarketplaceField.unitPrice,
        },
        // Báo cáo thu nhập chỉ bắt buộc **mã đơn** — nó là thứ nối khoản phí
        // vào đơn hàng. Từng loại phí thì tuỳ sàn có hay không, và thiếu một
        // loại phí là chuyện bình thường, không phải file hỏng.
        MarketplaceFileKind.income => const {MarketplaceField.orderId},
      };

  /// Vai trò bắt buộc mà bản đồ này **chưa** chỉ được cột nào.
  Set<MarketplaceField> get missingRequired => {
    for (final f in requiredFor(kind))
      if ((columns[f] ?? '').trim().isEmpty) f,
  };

  bool get isUsable => missingRequired.isEmpty;

  /// Biến lời khai của người bán thành một [MarketplaceProfile] dùng được.
  ///
  /// Bản đồ tay **thắng** hồ sơ đoán sẵn: mỗi vai trò chỉ mang đúng một bí
  /// danh — cái người bán chỉ. Không trộn thêm bí danh đoán vào, vì trộn xong
  /// thì lúc đọc sai sẽ không ai biết cột nào đã thắng.
  MarketplaceProfile toProfile(MarketplaceProfile? base) {
    final mapped = {
      for (final e in columns.entries)
        if (e.value.trim().isNotEmpty) e.key: [e.value],
    };
    final isOrders = kind == MarketplaceFileKind.orders;
    return MarketplaceProfile(
      vendor: vendor,
      displayName: base?.displayName ?? vendor,
      channel: base?.channel ?? SalesChannel.marketplaceOther,
      orderColumns: isOrders ? mapped : (base?.orderColumns ?? const {}),
      incomeColumns: isOrders ? (base?.incomeColumns ?? const {}) : mapped,
    );
  }

  // ── lưu trữ ──────────────────────────────────────────────────────────────

  /// JSON lưu xuống DB: **mã canonical**, không phải nhãn hiển thị
  /// (ADR-TON-018).
  String encodeColumns() =>
      jsonEncode({for (final e in columns.entries) e.key.name: e.value});

  /// Mã vai trò lạ ⇒ **bỏ qua dòng đó**, không rơi về một vai trò nào khác.
  ///
  /// Một bản đồ đọc từ bản dựng mới hơn có thể mang vai trò bản này chưa biết.
  /// Bỏ qua thì bản đồ thiếu vai trò ⇒ `missingRequired` bắt được ⇒ người bán
  /// được hỏi lại. Đoán một vai trò thay thế thì con số sai mà không ai biết.
  /// JSON hỏng ⇒ bản đồ **rỗng**, không ném lỗi.
  ///
  /// `jsonDecode` ném `FormatException` với chuỗi hỏng. Ném ở đây thì một dòng
  /// hỏng trong DB làm **cả màn nhập** chết, chứ không phải chỉ mất một bản
  /// đồ. Trả rỗng thì `missingRequired` bắt được và người bán được hỏi lại —
  /// đúng đường đã có. (Bắt lỗi ở tầng domain, không phải trong `ui/`, nên
  /// không đụng ADR-TON-017.)
  static Map<MarketplaceField, String> decodeColumns(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const {};
    }
    if (decoded is! Map) return const {};
    final byName = {for (final f in MarketplaceField.values) f.name: f};
    return {
      for (final e in decoded.entries)
        if (byName[e.key] != null && e.value is String)
          byName[e.key]!: e.value as String,
    };
  }
}
