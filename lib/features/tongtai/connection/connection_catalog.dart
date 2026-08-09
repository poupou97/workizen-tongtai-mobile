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

  /// Chỉ có dữ liệu mẫu **tĩnh** — chưa nối gì, và không có gì đang chạy.
  demo('demo'),

  /// ⭐ Nguồn này **đang phát dữ liệu vào bản mô phỏng** (WTM-340 · §40).
  ///
  /// Khác [demo] ở chỗ có thứ đang chạy: đồng hồ mô phỏng đẩy tới đâu thì
  /// nguồn này sinh việc tới đó. Khác [connected] ở chỗ **không có kết nối
  /// nào cả** — không token, không request, không byte nào rời máy.
  ///
  /// Đây là trạng thái **thứ bảy**, cố ý không mượn [connected]. Founder §40:
  /// *"fake dữ liệu được, fake trạng thái engineering thì không."* Cách rẻ
  /// hơn — cho nguồn demo mượn nhãn `connected` rồi ghi chú ở đâu đó — chính
  /// là cách một bản demo biến thành một lời nói dối, vì ghi chú thì rơi
  /// rụng còn nhãn thì ở lại.
  demoConnected('demo_connected'),

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
  sourcing('sourcing'),

  /// Khách nhắn gì, quảng cáo chạy ra sao — **cái đang nói chuyện**.
  messaging('messaging'),

  /// Kiện hàng đi tới đâu — **cái đang trên đường**.
  logistics('logistics'),

  /// Tiền về hay chưa — **cái đã vào tài khoản**.
  finance('finance');

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

  /// Kênh khách nhắn + kênh quảng cáo.
  static const List<ConnectionSource> messaging = [
    ConnectionSource(
      id: 'facebook_page',
      name: 'Facebook Page',
      kind: SourceKind.messaging,
      readiness: ConnectionReadiness.partnerRequired,
      evidence:
          'Có connector Messenger trong bộ mã đã đọc (WTM-309); mọi bản đều '
          'cần Page access token của một app đã duyệt.',
      vendorClaim:
          'Messenger Platform API — quyền nhắn tin phải được Meta **duyệt** '
          'qua App Review; ngoài ra còn cửa sổ trả lời 24 giờ.',
    ),
    ConnectionSource(
      id: 'instagram',
      name: 'Instagram',
      kind: SourceKind.messaging,
      readiness: ConnectionReadiness.partnerRequired,
      evidence: 'Đi cùng Facebook trong bộ mã đã đọc — chung tầng xác thực.',
      vendorClaim:
          'Instagram Graph API — phải đăng ký tài khoản Business, nối với '
          'một Page, và qua cùng vòng duyệt của Meta.',
    ),
    ConnectionSource(
      id: 'facebook_ads',
      name: 'Facebook Ads',
      kind: SourceKind.messaging,
      readiness: ConnectionReadiness.researched,
      evidence: 'Có connector Insights trong bộ mã đã đọc (WTM-309).',
      vendorClaim: 'Marketing API — đọc chỉ số chiến dịch bằng access token.',
    ),
    ConnectionSource(
      id: 'telegram',
      name: 'Telegram',
      kind: SourceKind.messaging,
      readiness: ConnectionReadiness.connected,
      connectorId: kTelegramConnectorId,
      entryPattern: 'bot_token',
      evidence:
          'Đã dựng và chạy thật: getMe / sendMessage / dò nơi nhận '
          '(WTM-318).',
      vendorClaim: 'Bot API — không cần duyệt, chỉ cần một bot token.',
    ),
  ];

  /// Hãng vận chuyển.
  static const List<ConnectionSource> logistics = [
    ConnectionSource(
      id: 'ghn',
      name: 'GHN',
      kind: SourceKind.logistics,
      readiness: ConnectionReadiness.researched,
      evidence: 'Không tìm thấy implementation trong bộ mã đã đọc (WTM-309).',
      vendorClaim: 'API công khai cho shop, xác thực bằng token tài khoản.',
    ),
    ConnectionSource(
      id: 'ghtk',
      name: 'GHTK',
      kind: SourceKind.logistics,
      readiness: ConnectionReadiness.researched,
      evidence: 'Không tìm thấy implementation trong bộ mã đã đọc (WTM-309).',
      vendorClaim: 'API tạo đơn + tra vận đơn, cần token đối tác.',
    ),
    ConnectionSource(
      id: 'viettel_post',
      name: 'Viettel Post',
      kind: SourceKind.logistics,
      readiness: ConnectionReadiness.apiFuture,
      evidence: 'Không tìm thấy implementation trong bộ mã đã đọc (WTM-309).',
      vendorClaim: 'API cho khách doanh nghiệp, đăng ký qua bưu cục.',
    ),
  ];

  /// Tiền về.
  static const List<ConnectionSource> finance = [
    ConnectionSource(
      id: 'bank',
      name: 'Ngân hàng',
      kind: SourceKind.finance,
      readiness: ConnectionReadiness.apiFuture,
      // ⭐ Đây là vùng nhạy cảm nhất, và câu này phải nói thẳng lý do dừng.
      evidence:
          'Chưa dựng, và **chưa nên dựng**: đọc tài khoản ngân hàng là quyết '
          'định pháp lý/bảo mật của Founder (G-3), không phải một task.',
      vendorClaim:
          'Open Banking Việt Nam chưa có chuẩn chung cho cá nhân; hầu hết '
          'đi qua trung gian.',
    ),
  ];

  static List<ConnectionSource> get all => [
    ...commerce,
    ...sourcing,
    ...messaging,
    ...logistics,
    ...finance,
  ];

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

/// Trạng thái **hiển thị** của một nguồn, sau khi tính tới bản mô phỏng —
/// WTM-340 (E4 · Epic WTM-336).
///
/// ## ⛔ Mô phỏng không được che sự thật đã có
///
/// Nguồn đã nối thật ([ConnectionReadiness.connected]) hoặc đã có đường nhập
/// file thật ([ConnectionReadiness.fileBridge]) thì **giữ nguyên nhãn**, kể cả
/// khi đồng hồ demo đang phát dữ liệu mang tên nó.
///
/// Chiều ngược lại mới là chiều nguy hiểm: nếu demo được phép đè lên, thì bật
/// mô phỏng lên là mọi nguồn đều "đang chạy", và người bán mất luôn cách phân
/// biệt thứ mình đã nối với thứ mình chỉ đang xem.
ConnectionReadiness readinessWithDemo(
  ConnectionSource source,
  Set<String> liveDemoVendors,
) {
  if (!liveDemoVendors.contains(source.id)) return source.readiness;
  return switch (source.readiness) {
    ConnectionReadiness.connected ||
    ConnectionReadiness.fileBridge => source.readiness,
    _ => ConnectionReadiness.demoConnected,
  };
}
