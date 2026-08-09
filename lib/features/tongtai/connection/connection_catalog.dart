import 'package:flutter/foundation.dart';

import 'connection_capability.dart';

/// **Nguồn dữ liệu — nói đúng trạng thái** — WTM-331 (C7 · Epic WTM-324).
///
/// ## ⛔ Không gọi Demo XLSX là dữ liệu Shopee
///
/// Founder §24. Một danh sách nguồn mà mọi dòng trông như nhau sẽ khiến người
/// bán tin rằng app đang đồng bộ với sàn — trong khi thứ họ có là một file
/// Excel họ tự tải về.
///
/// ## ⭐ Ba tầng, và trộn chúng là chỗ dễ nói dối nhất
///
/// Task Order trước (§21) chỉnh thẳng một suy luận sai của tôi:
///
/// > *"Không được suy ra: '0 implementation trong 1124 connector' = 'Vendor
/// > không có API'. Đó chỉ là: NO IMPLEMENTATION FOUND IN STUDIED SOURCE SET."*
///
/// Nên mỗi mục ở đây tách rõ ba tầng:
///
/// | Tầng | Là gì | Ở đâu |
/// |---|---|---|
/// | **Bằng chứng nguồn** | ta tìm thấy gì trong bộ mã đã đọc | [evidence] |
/// | **Tài liệu vendor** | vendor nói gì | [vendorClaim] |
/// | **Quyết định sản phẩm** | ta chọn làm gì | [readiness] |
///
/// Ba tầng có thể **mâu thuẫn nhau**, và khi mâu thuẫn thì việc của catalog là
/// hiện cả ba chứ không hoà giải chúng.
enum ConnectionReadiness {
  /// Đã nối thật, chạy được trên máy người bán.
  connected('connected'),

  /// Dữ liệu vào qua **file**, không qua API. Không tự cập nhật.
  fileBridge('file_bridge'),

  /// Chỉ có dữ liệu mẫu — chưa nối gì cả.
  demo('demo'),

  /// Đã đọc mã/tài liệu, biết làm thế nào, **chưa dựng**.
  researched('researched'),

  /// Kỹ thuật làm được, nhưng cần vendor **duyệt tài khoản đối tác** trước.
  /// Đây là rào cản *thương mại*, không phải rào cản kỹ thuật — và phân biệt
  /// hai loại rào cản đó quyết định việc nên làm gì tiếp theo.
  partnerRequired('partner_required'),

  /// Để sau. Không phải "không làm được".
  apiFuture('api_future');

  const ConnectionReadiness(this.code);

  final String code;

  static ConnectionReadiness? fromCode(String? code) {
    for (final r in ConnectionReadiness.values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Nguồn này mang loại dữ liệu gì.
enum SourceKind {
  /// Đơn hàng, sản phẩm, doanh thu — **cái đã bán**.
  commerce('commerce'),

  /// Nhà cung cấp, báo giá, MOQ — **cái sắp nhập**.
  sourcing('sourcing');

  const SourceKind(this.code);

  final String code;
}

/// Một nguồn dữ liệu trong catalog.
@immutable
class ConnectionSource {
  const ConnectionSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.readiness,
    required this.evidence,
    required this.vendorClaim,
    this.connectorId,
    this.entryPattern,
  });

  final String id;

  /// Tên riêng — **không dịch**. "Shopee" là "Shopee" ở mọi ngôn ngữ.
  final String name;

  final SourceKind kind;

  /// **Quyết định sản phẩm** — ta chọn làm gì với nguồn này.
  final ConnectionReadiness readiness;

  /// **Bằng chứng nguồn** — ta tìm thấy gì trong bộ mã đã đọc (WTM-309).
  ///
  /// Câu này phải nói được *"đã đọc gì"*, không phải *"vendor thế nào"*.
  final String evidence;

  /// **Tài liệu vendor** — vendor nói có gì.
  final String vendorClaim;

  /// Mã connector đã dựng trong app, nếu có. `null` ⇒ chưa có gì để nối.
  ///
  /// Đây là thứ khiến [readiness] `connected` **không tự khai được**: muốn
  /// khai đã nối thì phải có một connector thật trong `ConnectorDescriptor`.
  final String? connectorId;

  /// §D-6: *"Connector ≠ chỉ API."* App-to-app · share · deep link · URL
  /// import · file import đều là đường vào hợp lệ.
  final String? entryPattern;
}

/// Catalog là **dữ liệu**, không phải `switch` rải trong UI (kỷ luật WTM-287).
abstract final class ConnectionCatalog {
  /// Nguồn **thương mại** — cái đã bán.
  static const List<ConnectionSource> commerce = [
    ConnectionSource(
      id: 'google_drive_xlsx',
      name: 'Google Drive / Excel',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.fileBridge,
      connectorId: kGoogleConnectorId,
      entryPattern: 'file_import',
      evidence:
          'Đã dựng và chạy: đọc .xlsx ngay trên máy, nhập qua đường '
          'production (WTM-326).',
      vendorClaim:
          'Drive API v3 — scope drive.file đủ cho backup và chọn file.',
    ),
    ConnectionSource(
      id: 'shopee',
      name: 'Shopee',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.partnerRequired,
      entryPattern: 'file_import',
      // ⭐ Câu này cố ý nói "trong bộ mã đã đọc", không nói "không có API".
      evidence:
          'Không tìm thấy implementation nào trong 1124 connector của ba bộ '
          'automation đã đọc (WTM-309). Đó là NO IMPLEMENTATION FOUND IN '
          'STUDIED SOURCE SET — không phải kết luận về vendor.',
      vendorClaim:
          'Shopee Open Platform có API đơn hàng/sản phẩm, cần tài khoản '
          'partner được duyệt và ký request.',
    ),
    ConnectionSource(
      id: 'tiktok_shop',
      name: 'TikTok Shop',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.partnerRequired,
      entryPattern: 'file_import',
      evidence: 'Không tìm thấy implementation trong bộ mã đã đọc (WTM-309).',
      vendorClaim:
          'TikTok Shop Partner API — cần đăng ký developer và duyệt ứng dụng.',
    ),
    ConnectionSource(
      id: 'shopify',
      name: 'Shopify',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.researched,
      evidence:
          'Có connector trong cả ba bộ automation đã đọc; xác thực bằng '
          'Admin API access token.',
      vendorClaim: 'Admin API REST/GraphQL, webhook đầy đủ.',
    ),
    ConnectionSource(
      id: 'woocommerce',
      name: 'WooCommerce',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.researched,
      evidence: 'Có connector trong bộ mã đã đọc; xác thực bằng consumer key.',
      vendorClaim: 'REST API v3 trên chính site WordPress của người bán.',
    ),
    ConnectionSource(
      id: 'ebay',
      name: 'eBay',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.apiFuture,
      evidence: 'Không tìm thấy implementation trong bộ mã đã đọc (WTM-309).',
      vendorClaim: 'Sell API + OAuth; ứng dụng phải qua vòng duyệt.',
    ),
    ConnectionSource(
      id: 'amazon',
      name: 'Amazon',
      kind: SourceKind.commerce,
      readiness: ConnectionReadiness.apiFuture,
      evidence: 'Không tìm thấy implementation trong bộ mã đã đọc (WTM-309).',
      vendorClaim: 'SP-API — cần đăng ký developer, ký request theo AWS SigV4.',
    ),
  ];

  /// Nguồn **nhập hàng** — cái sắp nhập.
  static const List<ConnectionSource> sourcing = [
    ConnectionSource(
      id: 'manual_supplier',
      name: 'Tự nhập nhà cung cấp',
      kind: SourceKind.sourcing,
      readiness: ConnectionReadiness.connected,
      connectorId: null,
      entryPattern: 'manual',
      evidence: 'Đã có trong app từ WTM-63; báo giá theo sản phẩm từ WTM-327.',
      vendorClaim: 'Không có vendor — người bán tự nhập.',
    ),
    ConnectionSource(
      id: 'alibaba',
      name: 'Alibaba',
      kind: SourceKind.sourcing,
      readiness: ConnectionReadiness.demo,
      entryPattern: 'url_import',
      evidence:
          'Báo giá Alibaba trong app hiện là **dữ liệu demo** từ file mẫu, '
          'không phải dữ liệu về từ Alibaba.',
      vendorClaim:
          'Có API cho nhà cung cấp đã xác minh; người mua lẻ không dùng được.',
    ),
    ConnectionSource(
      id: '1688',
      name: '1688',
      kind: SourceKind.sourcing,
      readiness: ConnectionReadiness.demo,
      entryPattern: 'url_import',
      evidence: 'Như Alibaba — báo giá trong app là dữ liệu demo.',
      vendorClaim: 'API nội địa Trung Quốc, thực tế đi qua đại lý trung gian.',
    ),
    ConnectionSource(
      id: 'aliexpress',
      name: 'AliExpress',
      kind: SourceKind.sourcing,
      readiness: ConnectionReadiness.demo,
      entryPattern: 'url_import',
      evidence: 'Như Alibaba — báo giá trong app là dữ liệu demo.',
      vendorClaim: 'Affiliate/dropship API, cần tài khoản đối tác.',
    ),
    ConnectionSource(
      id: 'url_import',
      name: 'Dán đường dẫn sản phẩm',
      kind: SourceKind.sourcing,
      readiness: ConnectionReadiness.apiFuture,
      entryPattern: 'url_import',
      evidence:
          'Chưa dựng. §D-6: connector không chỉ là API — dán link cũng là '
          'một đường vào hợp lệ.',
      vendorClaim: 'Không phụ thuộc vendor nào.',
    ),
  ];

  static List<ConnectionSource> get all => [...commerce, ...sourcing];

  static ConnectionSource? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<ConnectionSource> withReadiness(ConnectionReadiness readiness) =>
      [
        for (final s in all)
          if (s.readiness == readiness) s,
      ];
}
