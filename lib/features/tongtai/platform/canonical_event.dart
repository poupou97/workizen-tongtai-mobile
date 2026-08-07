import 'package:flutter/foundation.dart';

import '../core/provenance.dart';

/// Miền nghiệp vụ của một sự kiện — nửa trước của `<miền>.<việc đã xảy ra>`.
enum EventDomain {
  order('order'),
  inventory('inventory'),
  customer('customer'),
  payment('payment'),
  refund('refund'),
  shipment('shipment'),
  settlement('settlement'),
  subscription('subscription'),
  delivery('delivery');

  const EventDomain(this.code);

  final String code;

  static EventDomain? fromCode(String? code) {
    for (final d in EventDomain.values) {
      if (d.code == code) return d;
    }
    return null;
  }

  /// Mã thoát của miền này — dùng khi nền tảng trả một việc app chưa biết.
  String get unknownCode => '$code.unknown';
}

/// Việc đã xảy ra — **từ vựng đóng** (WTM-294 · N3 · ADR-TON-024 luật 4).
///
/// ## ⭐ Cùng một sự việc ở hai nền tảng phải ra CÙNG một mã
///
/// Shopee *"đơn đã xác nhận"* và TikTok *"order confirmed"* **không được**
/// thành hai mã khác nhau. Nếu chúng khác nhau thì Rule Twin phải biết từng nền
/// tảng — đúng thứ canonical sinh ra để tránh — và mỗi sàn mới lại thêm một
/// nhánh `if` vào lõi nghiệp vụ.
///
/// Phép thử để biết một mã mới có chính đáng không:
///
/// > *Nếu ngày mai có sàn thứ tư làm cùng việc này, nó có dùng được mã này
/// > không?*
///
/// Không ⇒ mã đang mô tả **cách nền tảng nói**, không phải **việc đã xảy ra**.
///
/// ## Mỗi miền có một mã `unknown`, và đó là câu trả lời trung thực
///
/// Cám dỗ cụ thể: Shopee có `TO_CONFIRM_RECEIVE`. Nó *gần giống*
/// [orderFulfilled]. Ánh xạ bừa vào đó sẽ làm doanh thu ghi nhận **sớm một
/// khâu**, và không ai phát hiện cho tới khi có đơn bị trả.
enum CanonicalEventType {
  orderCreated(EventDomain.order, 'created'),
  orderUpdated(EventDomain.order, 'updated'),
  orderPaid(EventDomain.order, 'paid'),
  orderCancelled(EventDomain.order, 'cancelled'),
  orderFulfilled(EventDomain.order, 'fulfilled'),
  orderUnknown(EventDomain.order, 'unknown'),

  inventoryChanged(EventDomain.inventory, 'changed'),
  inventoryUnknown(EventDomain.inventory, 'unknown'),

  customerCreated(EventDomain.customer, 'created'),
  customerUpdated(EventDomain.customer, 'updated'),
  customerUnknown(EventDomain.customer, 'unknown'),

  paymentReceived(EventDomain.payment, 'received'),
  paymentFailed(EventDomain.payment, 'failed'),
  paymentUnknown(EventDomain.payment, 'unknown'),

  refundCompleted(EventDomain.refund, 'completed'),
  refundUnknown(EventDomain.refund, 'unknown'),

  shipmentCreated(EventDomain.shipment, 'created'),
  shipmentDelivered(EventDomain.shipment, 'delivered'),
  shipmentFailed(EventDomain.shipment, 'failed'),
  shipmentUnknown(EventDomain.shipment, 'unknown'),

  settlementLineRecorded(EventDomain.settlement, 'line_recorded'),
  settlementPayoutSettled(EventDomain.settlement, 'payout_settled'),
  settlementUnknown(EventDomain.settlement, 'unknown'),

  subscriptionStarted(EventDomain.subscription, 'started'),
  subscriptionRenewed(EventDomain.subscription, 'renewed'),
  subscriptionCancelled(EventDomain.subscription, 'cancelled'),
  subscriptionExpired(EventDomain.subscription, 'expired'),
  subscriptionChanged(EventDomain.subscription, 'changed'),
  subscriptionBillingIssue(EventDomain.subscription, 'billing_issue'),
  subscriptionUnknown(EventDomain.subscription, 'unknown'),

  /// Đã chạy thật — connector GitHub (WTM-268/274).
  deliveryCommit(EventDomain.delivery, 'commit'),
  deliveryChangeMerged(EventDomain.delivery, 'change_merged'),
  deliveryReleased(EventDomain.delivery, 'released'),
  deliveryUnknown(EventDomain.delivery, 'unknown');

  const CanonicalEventType(this.domain, this.action);

  final EventDomain domain;
  final String action;

  String get code => '${domain.code}.$action';

  /// Đây có phải mã thoát không.
  ///
  /// Rule Twin đọc cờ này để biết mình **chưa đủ dữ liệu**, thay vì tính một sự
  /// việc lạ như thể đã hiểu nó.
  bool get isUnknown => action == 'unknown';

  /// Mã lạ ⇒ `null`. Chỗ gọi phải quyết định rơi về `<miền>.unknown` nào —
  /// xem [CanonicalEventType.unknownFor].
  static CanonicalEventType? fromCode(String? code) {
    for (final t in CanonicalEventType.values) {
      if (t.code == code) return t;
    }
    return null;
  }

  /// Mã thoát của một miền.
  static CanonicalEventType unknownFor(EventDomain domain) {
    for (final t in CanonicalEventType.values) {
      if (t.domain == domain && t.isUnknown) return t;
    }
    throw StateError('miền ${domain.code} thiếu mã unknown');
  }
}

/// Dữ liệu này còn tươi tới đâu.
enum FreshnessConfidence {
  /// Vừa đọc trực tiếp từ nền tảng.
  live('live'),

  /// Đọc từ bộ nhớ đệm, còn trong hạn.
  cached('cached'),

  /// Quá hạn — **vẫn hiện, nhưng nói rõ là cũ** (ADR-TON-017: refresh lỗi giữ
  /// dữ liệu cũ, không xoá màn hình).
  stale('stale');

  const FreshnessConfidence(this.code);

  final String code;

  static FreshnessConfidence? fromCode(String? code) {
    for (final f in FreshnessConfidence.values) {
      if (f.code == code) return f;
    }
    return null;
  }
}

/// Bao bì chuẩn của mọi sự kiện từ nền tảng ngoài (WTM-270 · WTM-294).
///
/// ## ⭐ Vì sao `type` là enum chứ không phải String
///
/// ADR-TON-024 luật 4: *"connector chỉ được emit Canonical Event, không emit
/// event riêng của nền tảng"*. Nếu trường này là `String` thì một connector
/// viết `'shopee.order_status_push'` vẫn dựng được envelope, và lõi nghiệp vụ
/// sẽ thấy mã của nền tảng — đúng thứ luật này cấm.
///
/// Là enum thì **không viết ra được**. Bảng ánh xạ `mã nền tảng → mã canonical`
/// nằm trong từng connector; lõi nghiệp vụ không bao giờ thấy mã thô.
///
/// ## `occurredAt` ≠ `receivedAt`
///
/// Sàn trả sự việc cũ là chuyện thường. `occurredAt` quyết định **thứ tự nghiệp
/// vụ**; `receivedAt` chỉ để chẩn đoán. Trộn hai mốc làm mọi báo cáo theo thời
/// gian sai một cách âm thầm.
@immutable
class CanonicalEvent {
  /// Không `const`: assert phải duyệt [payload], và một hằng số biên dịch
  /// không duyệt được map. Giữ assert quan trọng hơn giữ `const` — nếu không
  /// thì luật "backend không đặt kết luận kinh doanh vào event" chỉ là một lời
  /// khuyên, và lời khuyên thì bị bỏ qua đúng vào ngày ai đó vội.
  CanonicalEvent({
    required this.eventId,
    required this.type,
    required this.occurredAt,
    required this.receivedAt,
    required this.connectionId,
    this.envelopeVersion = currentEnvelopeVersion,
    this.freshness = FreshnessConfidence.live,
    this.provenance = const Provenance.declared(ProvenanceSource.connector),
    this.payload = const {},
  }) : assert(
         // `any` chứ không phải `where().isEmpty` — assert phải rẻ.
         !_hasBusinessConclusion(payload),
         'payload mang kết luận kinh doanh. Đó là việc của Rule Twin trên máy '
         '(ADR-TON-016): backend biết dữ liệu ĐẾN TỪ ĐÂU, chỉ Mobile biết nó '
         'NGHĨA LÀ GÌ. Một con số tính sẵn ở backend là nguồn sự thật thứ hai '
         'đi kèm mọi sự kiện.',
       );

  static bool _hasBusinessConclusion(Map<String, Object?> payload) =>
      payload.keys.any(forbiddenPayloadKeys.contains);

  /// Phiên bản bao bì. Đổi hình dạng envelope ⇒ tăng số này.
  static const int currentEnvelopeVersion = 1;

  /// Trường mang **kết luận kinh doanh** — backend không được đặt vào payload.
  ///
  /// Đó là việc của Rule Twin trên máy (ADR-TON-016): backend biết dữ liệu
  /// **đến từ đâu**, chỉ Mobile biết nó **nghĩa là gì** (WTM-249). Một con số
  /// `revenue` tính sẵn ở backend là nguồn sự thật thứ hai đi kèm mọi sự kiện.
  static const Set<String> forbiddenPayloadKeys = {
    'revenue',
    'mrr',
    'profit',
    'is_important',
    'priority',
    'score',
    'should_notify',
  };

  final int envelopeVersion;

  /// **Khoá chống trùng.** Ổn định qua nhiều lần gọi — connector chạy lại không
  /// được sinh đơn ma.
  ///
  /// Khoá thật là `(connectionId, eventId)`, **không** phải
  /// `(connectionId, occurredAt)`: hai sự việc khác nhau có thể trùng mốc.
  final String eventId;

  final CanonicalEventType type;

  /// Khi việc **xảy ra** ở nền tảng.
  final DateTime occurredAt;

  /// Khi app **nhận được**. Chỉ để chẩn đoán.
  final DateTime receivedAt;

  /// Kết nối nào mang sự kiện này về (WTM-283).
  final String connectionId;

  final FreshnessConfidence freshness;
  final Provenance provenance;

  /// Dữ liệu thô đã chuẩn hoá. **Không** chứa kết luận kinh doanh — xem
  /// [forbiddenPayloadKeys] và [businessConclusionsInPayload].
  final Map<String, Object?> payload;

  /// Khoá chống trùng đầy đủ.
  String get dedupeKey => '$connectionId/$eventId';

  /// Sự kiện tới **muộn** so với lúc xảy ra bao lâu.
  ///
  /// Âm là bất thường (đồng hồ lệch), không phải "tới trước khi xảy ra" — nên
  /// nó được trả nguyên để chẩn đoán, không bị kẹp về 0.
  Duration get lag => receivedAt.difference(occurredAt);

  /// Khoá kết luận kinh doanh lọt vào payload — rỗng là đúng.
  ///
  /// Trả danh sách thay vì `bool` để chỗ gọi nói được **cái nào** sai.
  List<String> get businessConclusionsInPayload =>
      payload.keys.where(forbiddenPayloadKeys.contains).toList();

  /// Sự kiện này có thay được [older] không.
  ///
  /// **Không ghi đè bằng dữ liệu cũ hơn.** Đây là chỗ hay hỏng nhất khi có
  /// retry: một lần gọi lại mang về sự việc cũ, và nếu nó ghi đè thì trạng thái
  /// đơn hàng lùi lại một bước mà không ai biết vì sao.
  bool supersedes(CanonicalEvent older) =>
      dedupeKey == older.dedupeKey && occurredAt.isAfter(older.occurredAt);

  @override
  bool operator ==(Object other) =>
      other is CanonicalEvent && other.dedupeKey == dedupeKey;

  @override
  int get hashCode => dedupeKey.hashCode;

  @override
  String toString() => 'CanonicalEvent(${type.code} $eventId @$occurredAt)';
}

/// Bảng ánh xạ `mã nền tảng → mã canonical` của **một** connector.
///
/// ## Vì sao bảng nằm ở connector, không nằm ở lõi
///
/// Lõi nghiệp vụ **không bao giờ** được thấy mã nền tảng. Đặt bảng ở lõi thì
/// mỗi sàn mới lại thêm một nhánh vào chỗ chung, và đó chính là "phải đổi kiến
/// trúc lần thứ hai".
///
/// ## Hai điều bảng này cố ý cho phép
///
/// 1. **Không ánh xạ được ⇒ `<miền>.unknown`**, không đoán mã gần giống nhất.
/// 2. **Bỏ qua hẳn** một mã nền tảng — trả `null` từ [ignored]. Không phải mọi
///    thứ nền tảng có đều đáng thành một sự kiện: GitHub *tag* và *PR đóng
///    không merge* đều bị bỏ qua ở connector đầu tiên, và ánh xạ tag → release
///    đúng là kiểu đoán mà luật 1 cấm.
@immutable
class ConnectorEventMapping {
  const ConnectorEventMapping({
    required this.connectorId,
    required this.domain,
    required this.mappings,
    this.ignored = const {},
  });

  final String connectorId;

  /// Miền mặc định — quyết định mã thoát khi không ánh xạ được.
  final EventDomain domain;

  final Map<String, CanonicalEventType> mappings;

  /// Mã nền tảng **cố ý bỏ qua**, không sinh sự kiện.
  ///
  /// Tách khỏi "không ánh xạ được": bỏ qua là một quyết định đã cân nhắc, còn
  /// không ánh xạ được là một khoảng trống cần người xem. Gộp chúng thì một mã
  /// mới của sàn sẽ im lặng biến mất.
  final Set<String> ignored;

  /// Ánh xạ một mã thô. `null` = **cố ý bỏ qua**.
  ///
  /// Mã lạ ⇒ `<miền>.unknown`, **không** trả `null` — một sự việc chưa hiểu vẫn
  /// là một sự việc đã xảy ra, và im lặng nuốt nó là cách mất dữ liệu không ai
  /// phát hiện.
  CanonicalEventType? resolve(String platformCode) {
    if (ignored.contains(platformCode)) return null;
    return mappings[platformCode] ?? CanonicalEventType.unknownFor(domain);
  }
}
