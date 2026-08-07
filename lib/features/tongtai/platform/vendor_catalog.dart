import 'package:flutter/foundation.dart';

/// Chức năng một nền tảng có thể phục vụ — **từ vựng đóng**, dùng chung giữa
/// Vendor Catalog và Capability Matrix (WTM-293 · N1/N2 · ADR-TON-024 luật 3).
enum PlatformCapability {
  orders('orders'),
  products('products'),
  inventory('inventory'),
  customers('customers'),
  chat('chat'),
  ads('ads'),
  live('live'),
  warehouse('warehouse'),
  payments('payments'),
  settlement('settlement'),
  shipping('shipping'),
  analytics('analytics'),
  delivery('delivery');

  const PlatformCapability(this.code);

  final String code;

  static PlatformCapability? fromCode(String? code) {
    for (final c in PlatformCapability.values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Mức tin cậy của một dòng catalog — **tập thứ tự**.
///
/// ## Vì sao trường này tồn tại (bài học đã trả giá)
///
/// Bảng vendor cũ (WTM-252/271) ghi GitHub là *"OAuth device flow · n8n có node
/// sẵn"*. **Sai cả hai**, và chỉ lộ ra khi dựng connector thật (WTM-268):
///
/// | Ghi trong catalog | Thực tế |
/// |---|---|
/// | OAuth device flow | **PAT chỉ-đọc** — hẹp hơn *và* đơn giản hơn |
/// | n8n có node sẵn ✅ | **không dùng được** — không phân trang theo cách cần |
///
/// Hai ô sai **đều lệch cùng một hướng**: lạc quan hơn thực tế. Không ngẫu
/// nhiên — tài liệu nhà cung cấp viết để bán, nó nói cái gì *có thể* làm được,
/// không nói cái gì *nên* làm.
enum VendorVerification {
  /// Đọc từ tài liệu nhà cung cấp. **Chưa ai thử.**
  documented('documented', 1),

  /// Đã dựng thử, thấy nó chạy.
  tried('tried', 2),

  /// Đã chạy thật trên dữ liệu Workizen.
  production('production', 3);

  const VendorVerification(this.code, this.rank);

  final String code;
  final int rank;

  static VendorVerification? fromCode(String? code) {
    for (final v in VendorVerification.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Mô hình giá.
enum VendorPricing {
  free('free'),
  usageBased('usage_based'),
  subscription('subscription'),
  enterprise('enterprise');

  const VendorPricing(this.code);

  final String code;

  static VendorPricing? fromCode(String? code) {
    for (final p in VendorPricing.values) {
      if (p.code == code) return p;
    }
    return null;
  }
}

/// Mức phổ biến **ở thị trường Việt Nam**, không phải toàn cầu.
enum VendorPopularity {
  high('high'),
  medium('medium'),
  low('low');

  const VendorPopularity(this.code);

  final String code;
}

/// Một nhà cung cấp trong danh mục.
///
/// ## ⭐ `recommended` là hàm thuần, KHÔNG phải trường
///
/// Một cờ `recommended: true` gán bằng tay là **một ý kiến đội lốt dữ liệu**:
/// nó làm AI nói *"nên dùng X"* mà không ai truy được vì sao. Và nó là đúng họ
/// lỗi P-27/P-28 đã lặp bốn lần trong repo này — một trường được **lưu** trong
/// khi lẽ ra nó phải được **tính**.
///
/// Ai không đồng ý với gợi ý thì sửa **công thức**, không sửa từng dòng — và
/// sửa công thức là một thay đổi nhìn thấy được trong PR.
///
/// `vendor_catalog_is_data_governance_test` canh rằng không đường ghi nào lưu
/// giá trị này.
@immutable
class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.verification,
    required this.pricing,
    required this.popularity,
    this.regions = const [],
    this.officialApi = false,
    this.oauth = false,
    this.apiKey = false,
    this.mcp = false,
    this.webhook = false,
    this.polling = false,
    this.sdk = false,
    this.n8nNode = false,
    this.communityNode = false,
    this.freeTier = false,
    this.vietnamSupport = false,
    this.productionReady = false,
    this.requiresAnnualAudit = false,
    this.note,
  });

  final String id;
  final String name;
  final PlatformCapability category;

  /// Mã ISO quốc gia có hỗ trợ chính thức.
  final List<String> regions;

  // Cách kết nối.
  final bool officialApi;
  final bool oauth;
  final bool apiKey;
  final bool mcp;
  final bool webhook;
  final bool polling;
  final bool sdk;

  /// Có node n8n **chính thức**.
  final bool n8nNode;

  /// Chỉ có community node — rủi ro bảo trì, không tương đương chính thức.
  final bool communityNode;

  final VendorPricing pricing;
  final bool freeTier;
  final VendorPopularity popularity;

  /// Có hỗ trợ / tài liệu / thanh toán cho Việt Nam.
  final bool vietnamSupport;

  /// API ổn định, có versioning.
  final bool productionReady;

  /// ⚠️ Thẩm định lại **hằng năm** — Gmail CASA ($500–4.500/năm).
  final bool requiresAnnualAudit;

  final VendorVerification verification;
  final String? note;

  /// **Hàm thuần.** Công thức viết ra ở đây, không lưu ở đâu cả.
  ///
  /// Mỗi vế đều có một lý do cụ thể:
  /// - `verification ≥ tried`: một dòng `documented` chỉ là tài liệu nhà cung
  ///   cấp, và tài liệu nhà cung cấp viết để bán.
  /// - `¬requiresAnnualAudit`: Gmail CASA là lý do vế này tồn tại — một khoản
  ///   phí lặp lại hằng năm không phải chi tiết kỹ thuật.
  /// - `officialApi ∨ n8nNode`: community node **không** tính (xem
  ///   [communityNode]).
  bool get recommended =>
      productionReady &&
      verification.rank >= VendorVerification.tried.rank &&
      (freeTier || pricing == VendorPricing.usageBased) &&
      (officialApi || n8nNode) &&
      (regions.contains('VN') || vietnamSupport) &&
      !requiresAnnualAudit;

  /// Vì sao **chưa** được khuyến nghị — để người đọc sửa đúng chỗ.
  ///
  /// Trả rỗng khi [recommended]. Đây là thứ một cờ gán tay không bao giờ cho
  /// được: một cờ nói *"không"*, còn cái này nói *"không, vì ba lý do sau"*.
  List<String> get notRecommendedBecause => [
    if (!productionReady) 'api_not_production_ready',
    if (verification.rank < VendorVerification.tried.rank) 'never_tried',
    if (!(freeTier || pricing == VendorPricing.usageBased)) 'no_free_entry',
    if (!(officialApi || n8nNode)) 'no_official_integration_path',
    if (!(regions.contains('VN') || vietnamSupport)) 'no_vietnam_support',
    if (requiresAnnualAudit) 'requires_annual_audit',
  ];

  @override
  bool operator ==(Object other) => other is Vendor && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Vendor($id, ${verification.code})';
}

/// Danh mục nhà cung cấp — **dữ liệu tĩnh trong code, không phải bảng**.
///
/// Không vào SQLite và không vào `.ttbk`: đây là **kiến thức của app**, không
/// phải dữ liệu của người bán. Lưu nó vào cơ sở dữ liệu nghiệp vụ sẽ sinh ra
/// một bản sao cũ trên máy mỗi người bán, và mỗi lần sửa catalog lại thành một
/// migration.
///
/// Cũng **không** nằm trong prompt AI (ADR-TON-016 — Rule Twin có thẩm quyền,
/// AI chỉ giải thích): trong prompt thì không truy vấn được, không test được,
/// và AI sẽ "nhớ" phiên bản cũ khi nội dung đổi.
abstract final class VendorCatalog {
  static const List<Vendor> all = [
    Vendor(
      id: 'github',
      name: 'GitHub',
      category: PlatformCapability.delivery,
      officialApi: true,
      apiKey: true,
      polling: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.medium,
      productionReady: true,
      verification: VendorVerification.production,
      note:
          'connector đầu tiên chạy thật (WTM-268/274); PAT chỉ-đọc, '
          'KHÔNG phải OAuth device flow như catalog cũ ghi',
    ),
    Vendor(
      id: 'telegram',
      name: 'Telegram',
      category: PlatformCapability.chat,
      regions: ['VN'],
      officialApi: true,
      apiKey: true,
      polling: true,
      webhook: true,
      n8nNode: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.high,
      vietnamSupport: true,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'rẻ nhất để thử: tự tạo bot, không ai duyệt',
    ),
    Vendor(
      id: 'shopee',
      name: 'Shopee',
      category: PlatformCapability.orders,
      regions: ['VN'],
      officialApi: true,
      oauth: true,
      webhook: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.high,
      vietnamSupport: true,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'cần hồ sơ doanh nghiệp — xem 19-INTEGRATION-SANDBOX',
    ),
    Vendor(
      id: 'tiktok_shop',
      name: 'TikTok Shop',
      category: PlatformCapability.orders,
      regions: ['VN'],
      officialApi: true,
      oauth: true,
      webhook: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.high,
      vietnamSupport: true,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'như Shopee — Partner API cần duyệt',
    ),
    Vendor(
      id: 'shopify',
      name: 'Shopify',
      category: PlatformCapability.orders,
      officialApi: true,
      apiKey: true,
      webhook: true,
      n8nNode: true,
      pricing: VendorPricing.subscription,
      popularity: VendorPopularity.low,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'dev store tự tạo được',
    ),
    Vendor(
      id: 'stripe',
      name: 'Stripe',
      category: PlatformCapability.payments,
      officialApi: true,
      apiKey: true,
      webhook: true,
      sdk: true,
      n8nNode: true,
      pricing: VendorPricing.usageBased,
      popularity: VendorPopularity.low,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'cần backend cho webhook',
    ),
    Vendor(
      id: 'revenuecat',
      name: 'RevenueCat',
      category: PlatformCapability.payments,
      officialApi: true,
      apiKey: true,
      webhook: true,
      pricing: VendorPricing.usageBased,
      freeTier: true,
      popularity: VendorPopularity.low,
      productionReady: true,
      verification: VendorVerification.tried,
      note: 'workflow đã dựng rồi GỠ — app chưa lên store',
    ),
    Vendor(
      id: 'gmail',
      name: 'Gmail',
      category: PlatformCapability.chat,
      regions: ['VN'],
      officialApi: true,
      oauth: true,
      n8nNode: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.high,
      vietnamSupport: true,
      productionReady: true,
      requiresAnnualAudit: true,
      verification: VendorVerification.documented,
      note:
          '⚠️ CASA \$500–4.500/năm, thẩm định lại mỗi 12 tháng '
          '⇒ khuyến nghị Share Sheet thay API',
    ),
    Vendor(
      id: 'ga4',
      name: 'Google Analytics 4',
      category: PlatformCapability.analytics,
      officialApi: true,
      oauth: true,
      n8nNode: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.medium,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'tự đăng ký được',
    ),
    Vendor(
      id: 'facebook',
      name: 'Facebook / Messenger',
      category: PlatformCapability.chat,
      regions: ['VN'],
      officialApi: true,
      oauth: true,
      webhook: true,
      n8nNode: true,
      pricing: VendorPricing.free,
      freeTier: true,
      popularity: VendorPopularity.high,
      vietnamSupport: true,
      productionReady: true,
      verification: VendorVerification.documented,
      note: 'cần App Review',
    ),
  ];

  static Vendor? byId(String id) {
    for (final v in all) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Nhà cung cấp **nên dùng**, tính lại mỗi lần gọi.
  static List<Vendor> get recommended =>
      all.where((v) => v.recommended).toList();

  static List<Vendor> forCategory(PlatformCapability category) =>
      all.where((v) => v.category == category).toList();
}
