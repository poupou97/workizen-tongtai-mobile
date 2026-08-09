import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Một chuyện đã xảy ra trong doanh nghiệp demo — WTM-337 (E1 · Epic WTM-336).

/// Mười bảy loại của §34.
///
/// Cố ý **không** dùng `CanonicalEvent` của production: abstraction đó vẫn là
/// giả thuyết (ADR-TON-024 để ngỏ), và Founder §34 nói thẳng *"demo event layer
/// không được ép architecture production phải theo nó"*.
///
/// Một enum riêng ở đây rẻ hơn nhiều so với việc khoá kiến trúc thật vào một
/// danh sách nghĩ ra cho bản demo.
enum DemoEventKind {
  orderCreated('order_created'),
  paymentFailed('payment_failed'),
  paymentSucceeded('payment_succeeded'),
  messageReceived('message_received'),
  commentReceived('comment_received'),
  shipmentUpdated('shipment_updated'),
  shipmentDelayed('shipment_delayed'),
  deliveryFailed('delivery_failed'),
  refundRequested('refund_requested'),
  refundCompleted('refund_completed'),
  reviewCreated('review_created'),
  inventoryLow('inventory_low'),
  supplierQuoteChanged('supplier_quote_changed'),
  campaignPerformanceChanged('campaign_performance_changed'),
  customerChurnRisk('customer_churn_risk'),
  repeatPurchaseDue('repeat_purchase_due'),
  settlementReceived('settlement_received');

  const DemoEventKind(this.code);

  final String code;

  static DemoEventKind? fromCode(String? code) {
    for (final k in DemoEventKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// Ai gây ra chuyện đó.
///
/// Ba chủ thể này là **nội dung** của dòng thời gian (§37), không phải chi tiết
/// kỹ thuật: người bán cần phân biệt việc nào sàn báo về, việc nào Tổng Tài tự
/// làm, và việc nào chính mình đã bấm.
///
/// Gộp cả ba thành "system" là xoá mất đúng thông tin khiến dòng thời gian
/// đáng đọc.
enum DemoActor {
  /// Sàn, hãng vận chuyển, ngân hàng — thế giới bên ngoài.
  platform('platform'),

  /// Tổng Tài.
  agent('agent'),

  /// Người bán.
  seller('seller');

  const DemoActor(this.code);

  final String code;

  static DemoActor? fromCode(String? code) {
    for (final a in DemoActor.values) {
      if (a.code == code) return a;
    }
    return null;
  }
}

@immutable
class DemoEvent {
  const DemoEvent({
    required this.id,
    required this.kind,
    required this.actor,
    required this.headline,
    required this.occurredAt,
    this.vendor,
    this.subjectKind,
    this.subjectId,
    this.correlationId,
    this.payload = const {},
    this.appliedAt,
  });

  final String id;
  final DemoEventKind kind;
  final DemoActor actor;

  /// `shopee` · `facebook` · `ghn`… `null` khi chuyện xảy ra trong nội bộ.
  final String? vendor;

  final String? subjectKind;
  final String? subjectId;

  /// Nối các sự kiện của **cùng một câu chuyện** — thay cho một entity hội
  /// thoại (WTM-296 §10).
  final String? correlationId;

  /// Câu người bán đọc, đã là tiếng Việt.
  final String headline;

  final Map<String, Object?> payload;

  final DateTime occurredAt;

  /// `null` = **chưa tới lượt áp vào miền thật**.
  ///
  /// Tách khỏi [occurredAt] là điều kiện để đồng hồ chạy: engine sinh sẵn cả
  /// tháng sự kiện, mỗi lần bấm "Ngày tiếp" chỉ áp những cái đã tới hạn.
  final DateTime? appliedAt;

  bool get isApplied => appliedAt != null;

  String encodePayload() => jsonEncode(payload);

  static Map<String, Object?> decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, Object?>.from(decoded) : const {};
    } on FormatException {
      return const {};
    }
  }

  DemoEvent markApplied(DateTime at) => DemoEvent(
    id: id,
    kind: kind,
    actor: actor,
    vendor: vendor,
    subjectKind: subjectKind,
    subjectId: subjectId,
    correlationId: correlationId,
    headline: headline,
    payload: payload,
    occurredAt: occurredAt,
    appliedAt: at,
  );

  @override
  bool operator ==(Object other) => other is DemoEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Nền tảng trong bản demo — mã canonical, dùng chung với `ConnectionCatalog`.
abstract final class DemoVendor {
  static const String shopee = 'shopee';
  static const String tiktok = 'tiktok_shop';
  static const String shopify = 'shopify';
  static const String facebook = 'facebook_page';
  static const String facebookAds = 'facebook_ads';
  static const String instagram = 'instagram';
  static const String alibaba = 'alibaba';
  static const String taobao1688 = '1688';
  static const String amazon = 'amazon';
  static const String ebay = 'ebay';
  static const String googleDrive = 'google_drive_xlsx';
  static const String telegram = 'telegram';
  static const String bank = 'bank';
  static const String ghn = 'ghn';
  static const String ghtk = 'ghtk';
  static const String viettelPost = 'viettel_post';
  static const String jt = 'jt';

  /// Nhãn người bán đọc. Tên riêng — không dịch.
  static String displayName(String? code) => switch (code) {
    shopee => 'Shopee',
    tiktok => 'TikTok Shop',
    shopify => 'Shopify',
    facebook => 'Facebook Page',
    facebookAds => 'Facebook Ads',
    instagram => 'Instagram',
    alibaba => 'Alibaba',
    taobao1688 => '1688',
    amazon => 'Amazon',
    ebay => 'eBay',
    googleDrive => 'Google Drive',
    telegram => 'Telegram',
    bank => 'Ngân hàng',
    ghn => 'GHN',
    ghtk => 'GHTK',
    viettelPost => 'Viettel Post',
    jt => 'J&T Express',
    _ => 'Tổng Tài',
  };
}
