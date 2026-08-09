import 'package:flutter/foundation.dart';

import '../core/provenance.dart';

/// Chuyến giao hàng — WTM-323 (C7 · Epic WTM-315).
///
/// ## Cảnh báo đáng giá nhất không phải "đơn bị chậm"
///
/// Founder viết đúng chỗ khó: thứ người bán cần là *"đơn này ba ngày không
/// nhúc nhích **trong khi đơn cùng tuyến đã tới**"*.
///
/// Khác biệt nằm ở vế sau. *"Chậm hơn dự kiến"* xảy ra với cả nghìn đơn mỗi
/// mùa cao điểm và không nói được gì; *"cùng tuyến, cùng hãng, gửi cùng ngày —
/// cái kia tới rồi, cái này chưa"* thì nói được, và nói đúng lúc gọi hãng còn
/// kịp.

/// Hãng vận chuyển — **mã canonical**, không phải nhãn hiển thị.
enum Carrier {
  ghn('ghn', 'Giao Hàng Nhanh'),
  ghtk('ghtk', 'Giao Hàng Tiết Kiệm'),
  viettelPost('viettel_post', 'Viettel Post'),
  jt('jt', 'J&T Express'),
  spx('spx', 'Shopee Express'),
  ninjaVan('ninja_van', 'Ninja Van');

  const Carrier(this.code, this.displayName);

  final String code;
  final String displayName;

  static Carrier? fromCode(String? code) {
    for (final c in Carrier.values) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// Đoán hãng từ **hình dạng mã vận đơn**.
  ///
  /// `null` = **không đoán được**, và giao diện hỏi người bán thay vì chọn
  /// bừa. Đoán sai hãng làm mọi lần tra cứu sau đó trỏ nhầm cửa, và người bán
  /// sẽ kết luận app không tra được — chứ không kết luận app đoán sai.
  ///
  /// Nhận diện dựa trên tiền tố công khai; cố tình **hẹp**, vì một luật rộng
  /// bắt được nhiều mã hơn cũng bắt nhầm nhiều hơn.
  static Carrier? guessFrom(String trackingNumber) {
    final code = trackingNumber.trim().toUpperCase();
    if (code.isEmpty) return null;
    if (RegExp(r'^SPX[A-Z0-9]{8,}$').hasMatch(code)) return Carrier.spx;
    if (RegExp(r'^(GHN|LGH)[0-9]{6,}$').hasMatch(code)) return Carrier.ghn;
    if (RegExp(r'^S[0-9]{8,}$').hasMatch(code)) return Carrier.ghtk;
    if (RegExp(r'^J&?T[0-9]{8,}$').hasMatch(code)) return Carrier.jt;
    if (RegExp(r'^[0-9]{11,13}VT$').hasMatch(code)) return Carrier.viettelPost;
    return null;
  }
}

/// Trạng thái chuyến — **mã canonical**.
enum ShipmentStatus {
  /// Đã tạo vận đơn, hãng chưa lấy hàng.
  created('created'),

  /// Đang trên đường.
  inTransit('in_transit'),

  /// Giao thất bại — khách không nghe máy, sai địa chỉ…
  failed('failed'),

  delivered('delivered'),

  /// Đang hoàn về người bán.
  returning('returning');

  const ShipmentStatus(this.code);

  final String code;

  /// Mã lạ ⇒ `null`, **không** rơi về `inTransit`.
  ///
  /// Rơi về "đang giao" sẽ khiến một kiện đã hoàn về kho trông như đang trên
  /// đường tới khách — và người bán không đi tìm nó.
  static ShipmentStatus? fromCode(String? code) {
    for (final s in ShipmentStatus.values) {
      if (s.code == code) return s;
    }
    return null;
  }

  bool get isFinished =>
      this == ShipmentStatus.delivered || this == ShipmentStatus.returning;
}

@immutable
class Shipment {
  const Shipment({
    required this.id,
    required this.trackingNumber,
    required this.status,
    this.orderId,
    this.carrier,
    this.lastUpdate,
    this.eta,
    this.origin,
    this.destination,
    this.notes,
    this.externalId,
    this.provenance = ProvenanceSource.manual,
    this.importJobId,
  });

  final String id;
  final String? orderId;
  final String trackingNumber;

  /// `null` = chưa biết hãng nào. Không đoán bừa.
  final Carrier? carrier;

  final ShipmentStatus status;

  /// `null` = **chưa có tin nào từ hãng**, không phải "cập nhật lúc 0".
  final DateTime? lastUpdate;

  final DateTime? eta;
  final String? origin;
  final String? destination;
  final String? notes;

  final String? externalId;
  final ProvenanceSource provenance;
  final String? importJobId;

  /// Bao nhiêu ngày không có tin. `null` khi chưa từng có tin nào.
  int? silentDaysAt(DateTime now) {
    final last = lastUpdate;
    if (last == null) return null;
    return now.difference(last).inDays;
  }

  /// Trễ so với hẹn. `null` khi hãng chưa hẹn ngày.
  int? lateDaysAt(DateTime now) {
    final promised = eta;
    if (promised == null || status.isFinished) return null;
    final late = now.difference(promised).inDays;
    return late > 0 ? late : 0;
  }

  /// Tuyến — dùng để so *"đơn cùng tuyến đã tới"*.
  ///
  /// `null` khi thiếu một trong hai đầu: so hai chuyến mà không biết chúng có
  /// cùng tuyến hay không thì so sánh vô nghĩa, và một so sánh vô nghĩa dẫn
  /// tới một cảnh báo vô nghĩa.
  String? get route {
    final from = origin;
    final to = destination;
    if (from == null || to == null || from.isEmpty || to.isEmpty) return null;
    return '$from→$to';
  }

  @override
  bool operator ==(Object other) => other is Shipment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
