import 'package:flutter/foundation.dart';

import 'shipment.dart';

/// Rule Twin của vận chuyển — WTM-323.
///
/// Chạy **không cần mạng, không cần khoá, không cần AI** (ADR-TON-016). Nó chỉ
/// so những chuyến đã có trong sổ với nhau.
///
/// ## ⭐ Vì sao so với "đơn cùng tuyến" chứ không so với ngày hẹn
///
/// *"Trễ hơn dự kiến"* xảy ra với cả nghìn đơn mỗi mùa cao điểm — cảnh báo theo
/// nó là cảnh báo bị tắt trong tuần đầu.
///
/// *"Cùng hãng, cùng tuyến, gửi cùng khoảng thời gian — những cái kia tới rồi,
/// cái này chưa"* là một câu khác hẳn: nó loại được nguyên nhân chung (bão,
/// quá tải, nghỉ lễ) và chỉ còn lại nguyên nhân riêng của **kiện đó**. Đó mới
/// là lúc gọi hãng còn kịp.
class ShipmentRule {
  const ShipmentRule({
    this.silentDaysThreshold = 3,
    this.minimumPeers = 2,
    this.peerWindow = const Duration(days: 3),
  });

  /// Bao nhiêu ngày không có tin thì đáng nhắc.
  final int silentDaysThreshold;

  /// Cần ít nhất bao nhiêu chuyến cùng tuyến để so.
  ///
  /// Một chuyến đối chiếu là một trùng hợp; hai chuyến trở lên mới là một mẫu.
  /// Cảnh báo dựa trên một mẫu đơn lẻ sẽ sai đủ nhiều để bị bỏ qua.
  final int minimumPeers;

  /// Gửi cách nhau trong khoảng này mới coi là **cùng đợt**.
  final Duration peerWindow;

  /// Những chuyến đáng nhắc, nặng trước.
  List<ShipmentConcern> assess(
    List<Shipment> shipments, {
    required DateTime now,
  }) {
    final out = <ShipmentConcern>[];

    for (final shipment in shipments) {
      if (shipment.status.isFinished) continue;

      if (shipment.status == ShipmentStatus.failed) {
        out.add(
          ShipmentConcern(
            shipment: shipment,
            kind: ShipmentConcernKind.deliveryFailed,
            // Giao thất bại là việc **phải làm hôm nay**: hãng chỉ giữ hàng
            // vài ngày rồi hoàn về, và lúc đó người bán mất cả phí hai chiều.
            peersDelivered: 0,
          ),
        );
        continue;
      }

      final silent = shipment.silentDaysAt(now);
      if (silent == null || silent < silentDaysThreshold) continue;

      final peers = _peersOf(shipment, shipments);
      final delivered = peers
          .where((p) => p.status == ShipmentStatus.delivered)
          .length;

      out.add(
        ShipmentConcern(
          shipment: shipment,
          // Đủ bạn đồng hành đã tới ⇒ vấn đề nằm ở **kiện này**, không phải ở
          // tuyến. Chưa đủ ⇒ chỉ nói nó im lặng, không kết luận thay.
          kind: peers.length >= minimumPeers && delivered >= minimumPeers
              ? ShipmentConcernKind.stuckWhilePeersArrived
              : ShipmentConcernKind.silent,
          peersDelivered: delivered,
        ),
      );
    }

    out.sort((a, b) => b.kind.index.compareTo(a.kind.index));
    return out;
  }

  /// Chuyến **cùng hãng, cùng tuyến, gửi cùng đợt**.
  List<Shipment> _peersOf(Shipment target, List<Shipment> all) {
    final route = target.route;
    final since = target.lastUpdate;
    if (route == null || since == null) return const [];

    return [
      for (final other in all)
        if (other.id != target.id)
          if (other.route == route && other.carrier == target.carrier)
            if (other.lastUpdate != null &&
                other.lastUpdate!.difference(since).abs() <= peerWindow)
              other,
    ];
  }
}

/// Vì sao một chuyến đáng nhắc. Thứ tự tăng dần theo mức khẩn.
enum ShipmentConcernKind {
  /// Lâu không có tin, nhưng chưa có gì để so.
  silent('silent'),

  /// ⭐ Đứng im **trong khi** những chuyến cùng tuyến đã tới.
  stuckWhilePeersArrived('stuck_while_peers_arrived'),

  /// Giao thất bại — hãng sẽ hoàn về nếu không xử lý.
  deliveryFailed('delivery_failed');

  const ShipmentConcernKind(this.code);

  final String code;
}

@immutable
class ShipmentConcern {
  const ShipmentConcern({
    required this.shipment,
    required this.kind,
    required this.peersDelivered,
  });

  final Shipment shipment;
  final ShipmentConcernKind kind;

  /// Bao nhiêu chuyến cùng tuyến đã tới. Đây là **bằng chứng**, không phải
  /// điểm số — nó đi thẳng vào câu người bán đọc.
  final int peersDelivered;
}
