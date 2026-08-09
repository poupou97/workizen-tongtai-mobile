import 'package:flutter/foundation.dart';

import 'commerce_models.dart';

/// Nhận một đường dẫn sản phẩm từ Alibaba/1688/AliExpress — WTM-323 (§D-6).
///
/// ## ⭐ Connector KHÔNG chỉ là API
///
/// Founder D-6 nói rõ: app-to-app · share · deep link · URL import · file
/// import đều là **đường vào hợp lệ**. Đây là đường rẻ nhất trong số đó — không
/// OAuth, không đăng ký, không ai duyệt.
///
/// ```
/// Người bán đang ở app Alibaba/1688
///    ↓ Share / Copy URL
/// Tổng Tài nhận
///    ↓ nhận ra: nền tảng + mã sản phẩm ở nguồn
/// Người bán điền: giá · MOQ · lead time
///    ↓
/// SupplierQuote → So sánh nhà cung cấp → Opportunity → Journey
///    ↓
/// "Xem tại Alibaba" → deep link về app gốc
/// ```
///
/// ## ⛔ Không scraping — và điều đó quyết định app biết được gì
///
/// Từ một URL, app **chỉ** suy ra được **nền tảng** và **mã sản phẩm**. Giá,
/// MOQ, thời gian giao đều nằm sau một trang web mà lấy về là vi phạm điều
/// khoản.
///
/// Nên lớp này trả về một **khung báo giá còn trống**, không phải một báo giá.
/// Người bán nhìn số trên màn hình Alibaba và gõ vào — mất mười giây, và con số
/// đó **đúng**, khác hẳn một con số app đoán.
///
/// Cách sai là để trống rồi hiện `0`: một báo giá 0 đồng sẽ thắng mọi so sánh
/// nhà cung cấp, và app sẽ khuyên người bán đổi sang một nguồn không có giá.
@immutable
class SourcingUrl {
  const SourcingUrl({
    required this.platform,
    required this.externalId,
    required this.canonicalUrl,
  });

  final SupplierPlatform platform;

  /// Mã sản phẩm ở nguồn — dùng để nhận ra *"link này đã dán rồi"*.
  final String externalId;

  /// Đường dẫn đã gọn lại, bỏ tham số theo dõi.
  ///
  /// Link chia sẻ từ app di động mang hàng chục tham số quảng cáo; giữ nguyên
  /// thì hai lần dán cùng một sản phẩm ra hai chuỗi khác nhau và chống trùng
  /// không chạy.
  final String canonicalUrl;

  /// Đọc một đường dẫn. `null` = không phải nguồn nào ta nhận ra.
  ///
  /// Không cố đoán: một link lạ trả `null` để giao diện nói *"chưa nhận ra
  /// trang này"* thay vì tạo một báo giá trỏ đi đâu không rõ.
  static SourcingUrl? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Người bán hay dán cả một đoạn chữ kèm link (app Alibaba chia sẻ như vậy).
    final found = RegExp(r'https?://[^\s]+').firstMatch(trimmed);
    final text = found?.group(0) ?? trimmed;

    final Uri uri;
    try {
      uri = Uri.parse(text);
    } on FormatException {
      return null;
    }
    if (!uri.hasScheme || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();
    final path = uri.path;

    for (final rule in _rules) {
      if (!rule.matchesHost(host)) continue;
      final id = rule.idFrom(path, uri);
      if (id == null) continue;
      return SourcingUrl(
        platform: rule.platform,
        externalId: id,
        canonicalUrl: rule.canonical(id),
      );
    }
    return null;
  }

  /// Khung báo giá còn trống, chờ người bán điền số.
  ///
  /// `unitCost` bắt buộc dương ở [SupplierQuote] nên khung này **không** phải
  /// một báo giá — nó là dữ liệu để dựng biểu mẫu. Tách rõ hai thứ để không có
  /// đường nào ghi một báo giá 0 đồng xuống sổ.
  SourcingDraft toDraft({required String productId}) => SourcingDraft(
    productId: productId,
    platform: platform,
    externalId: externalId,
    sourceUrl: canonicalUrl,
  );

  static const List<_UrlRule> _rules = [
    _UrlRule(
      platform: SupplierPlatform.alibaba,
      hosts: ['alibaba.com', 'm.alibaba.com', 'offer.alibaba.com'],
      pattern: r'/product-detail/[^/]*?_?(\d{6,})\.html',
      canonicalTemplate: 'https://www.alibaba.com/product-detail/{id}.html',
    ),
    _UrlRule(
      platform: SupplierPlatform.taobao1688,
      hosts: ['1688.com', 'detail.1688.com', 'm.1688.com'],
      pattern: r'/offer/(\d{6,})\.html',
      canonicalTemplate: 'https://detail.1688.com/offer/{id}.html',
    ),
    _UrlRule(
      platform: SupplierPlatform.aliexpress,
      hosts: ['aliexpress.com', 'www.aliexpress.com', 'm.aliexpress.com'],
      pattern: r'/item/(\d{6,})\.html',
      canonicalTemplate: 'https://www.aliexpress.com/item/{id}.html',
    ),
  ];
}

class _UrlRule {
  const _UrlRule({
    required this.platform,
    required this.hosts,
    required this.pattern,
    required this.canonicalTemplate,
  });

  final SupplierPlatform platform;
  final List<String> hosts;
  final String pattern;
  final String canonicalTemplate;

  bool matchesHost(String host) {
    for (final h in hosts) {
      if (host == h || host.endsWith('.$h')) return true;
    }
    return false;
  }

  String? idFrom(String path, Uri uri) {
    final match = RegExp(pattern).firstMatch(path);
    if (match != null) return match.group(1);
    // Một số link chia sẻ để mã trong tham số thay vì trong đường dẫn.
    for (final key in const ['offerId', 'productId', 'itemId', 'id']) {
      final value = uri.queryParameters[key];
      if (value != null && RegExp(r'^\d{6,}$').hasMatch(value)) return value;
    }
    return null;
  }

  String canonical(String id) => canonicalTemplate.replaceAll('{id}', id);
}

/// Khung báo giá chờ người bán điền — **chưa** phải một `SupplierQuote`.
@immutable
class SourcingDraft {
  const SourcingDraft({
    required this.productId,
    required this.platform,
    required this.externalId,
    required this.sourceUrl,
  });

  final String productId;
  final SupplierPlatform platform;
  final String externalId;
  final String sourceUrl;

  /// Những gì app **không biết** và người bán phải điền.
  ///
  /// Danh sách này hiện lên màn hình. Nói ra *"tôi chưa biết ba thứ này"* trung
  /// thực hơn nhiều so với hiện ba ô trống không giải thích.
  static const List<String> unknownFields = [
    'unit_cost',
    'minimum_order_quantity',
    'lead_time_days',
  ];
}
