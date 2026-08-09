import 'package:shared_preferences/shared_preferences.dart';

import '../consumer/customer_repository.dart';
import '../core/provenance.dart';
import '../core/tongtai_enums.dart';
import '../finance/settlement.dart';
import '../finance/settlement_repository.dart';
import '../inventory/product_repository.dart';
import '../logistics/shipment.dart';
import '../logistics/shipment_repository.dart';
import '../orders/order.dart';
import '../orders/order_repository.dart';
import '../profile/business_profile.dart' show SalesChannel;
import 'demo_event.dart';
import 'demo_event_repository.dart';
import 'demo_scenario.dart';

/// Đồng hồ mô phỏng — WTM-337 (§33).
///
/// ## 30 ngày kinh doanh trong 15 phút
///
/// Founder bấm `Ngày tiếp`, thế giới đi tới, và **miền thật thay đổi**: đơn vào
/// `OrderRepository`, phí sàn vào `SettlementRepository`, kiện hàng vào
/// `ShipmentRepository`, tồn kho giảm ở `ProductRepository`.
///
/// ## ⭐ Vì sao ghi vào miền THẬT thay vì dựng miền demo song song
///
/// ADR-TON-014 đã trả lời câu này một lần cho dữ liệu mẫu: *"sample seed vào
/// production repos, KHÔNG parallel demo state"*. Lý do vẫn đúng ở đây, và
/// mạnh hơn:
///
/// - mọi màn hình, mọi Rule Twin, mọi Capability Context **không cần biết** có
///   chế độ demo;
/// - thứ Founder nhìn thấy là **đường chạy thật** — nếu nó hỏng thì hỏng ngay
///   trong buổi demo, chứ không chờ tới người dùng thật;
/// - tắt mô phỏng đi thì không còn code nào phải gỡ.
///
/// Cái giá: dữ liệu mô phỏng nằm chung sổ với dữ liệu thật. Trả bằng
/// `provenance` và một đường xoá khai rõ phạm vi — cùng kỷ luật lần nhập
/// (WTM-327).
class SimulationEngine {
  SimulationEngine({
    required this.events,
    required this.orders,
    required this.products,
    required this.customers,
    required this.settlements,
    required this.shipments,
    required this.prefs,
    this.scenario = const DemoScenario(),
  });

  final DemoEventRepository events;
  final OrderRepository orders;
  final ProductRepository products;
  final CustomerRepository customers;
  final SettlementRepository settlements;
  final ShipmentRepository shipments;
  final SharedPreferences prefs;
  final DemoScenario scenario;

  /// Ngày bắt đầu thế giới mô phỏng, lưu để đóng app mở lại vẫn đúng chỗ.
  static const String _startedAtKey = 'tongtai.simulation.startedAt';

  /// Đang ở ngày thứ mấy.
  static const String _dayKey = 'tongtai.simulation.day';

  /// Đã gieo kịch bản chưa. `null` = chưa bắt đầu mô phỏng lần nào.
  Future<DateTime?> startedAt() async {
    final raw = prefs.getString(_startedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<int> currentDay() async => prefs.getInt(_dayKey) ?? 0;

  /// **Giờ trong thế giới mô phỏng.**
  ///
  /// Không phải `DateTime.now()`: Founder bấm ba lần trong một phút thì thế
  /// giới đi ba ngày, và mọi thứ đọc theo mốc này phải đi theo.
  Future<DateTime?> simulatedNow() async {
    final start = await startedAt();
    if (start == null) return null;
    final day = await currentDay();
    return start.add(Duration(days: day, hours: 23, minutes: 59));
  }

  /// Bắt đầu doanh nghiệp demo: sinh kịch bản, áp ngày 1.
  ///
  /// Cần danh mục và danh bạ **đã có**. Không tự bịa sản phẩm — câu hỏi *"còn
  /// màu đen không"* chỉ có nghĩa nếu áo đó có thật, với đúng con số tồn.
  Future<SimulationTick> start({required DateTime anchor}) async {
    final catalogue = await products.loadAll();
    final book = await customers.loadAll();
    if (catalogue.isEmpty) {
      return const SimulationTick.needsCatalogue();
    }

    // Bắt đầu lùi về quá khứ để ngày 1 đã có lịch sử — một doanh nghiệp mở ra
    // đã trống trơn thì không có gì để Rule Twin nói.
    final start = anchor.subtract(Duration(days: scenario.days));
    await events.deleteAll();
    await events.saveAll(
      scenario.generate(startedAt: start, products: catalogue, customers: book),
    );
    await prefs.setString(_startedAtKey, start.toIso8601String());
    await prefs.setInt(_dayKey, 0);

    return advanceDay();
  }

  /// Đi tới một sự kiện kế tiếp — cho người muốn xem từng bước.
  Future<SimulationTick> advanceOneEvent() async {
    final next = await events.nextPending();
    if (next == null) return const SimulationTick.finished();

    final start = await startedAt();
    if (start != null) {
      // Kéo ngày lên cho khớp sự kiện, nếu không thì đồng hồ tụt lại sau.
      final day = next.occurredAt.difference(start).inDays;
      if (day > await currentDay()) await prefs.setInt(_dayKey, day);
    }
    return _apply([next]);
  }

  /// Đi tới hết ngày kế tiếp.
  Future<SimulationTick> advanceDay({int days = 1}) async {
    final start = await startedAt();
    if (start == null) return const SimulationTick.notStarted();

    final day = await currentDay() + days;
    await prefs.setInt(_dayKey, day);
    final until = start.add(Duration(days: day, hours: 23, minutes: 59));
    return _apply(await events.loadDue(until));
  }

  /// Xoá thế giới mô phỏng. **Phạm vi: sổ sự kiện + đồng hồ.**
  ///
  /// ⚠️ Không xoá đơn/kiện/phí đã sinh ra: chúng nằm trong miền thật và mang
  /// `provenance = sample`. Dọn chúng là việc của "Đặt lại dữ liệu mẫu" đã có
  /// — hai đường xoá, mỗi đường khai rõ phạm vi của nó (WTM-307).
  Future<void> reset() async {
    await events.deleteAll();
    await prefs.remove(_startedAtKey);
    await prefs.remove(_dayKey);
  }

  // ── áp sự kiện vào miền thật ─────────────────────────────────────────────

  Future<SimulationTick> _apply(List<DemoEvent> due) async {
    if (due.isEmpty) return const SimulationTick.finished();

    final catalogue = {for (final p in await products.loadAll()) p.id: p};
    final newOrders = <CustomerOrder>[];
    final newShipments = <Shipment>[];
    final newSettlements = <SettlementLine>[];
    final stockChanges = <String, int>{};

    for (final event in due) {
      switch (event.kind) {
        case DemoEventKind.orderCreated:
          final productId = event.payload['productId'] as String?;
          final item = catalogue[productId];
          if (item == null) break;
          final quantity = (event.payload['quantity'] as num?)?.toInt() ?? 1;
          final orderId = 'sample-${event.id}';

          newOrders.add(
            CustomerOrder(
              id: orderId,
              customerId: (event.payload['customerId'] as String?) ?? '',
              orderNumber: 'DH-${event.id.split('-').last}',
              date: event.occurredAt,
              status: OrderStatus.delivered,
              channel: _channel(event.payload['channel'] as String?),
              items: [
                OrderItem(
                  productId: item.id,
                  productName: item.name,
                  sku: item.sku,
                  category: item.category,
                  quantity: quantity,
                  unitPrice:
                      (event.payload['unitPrice'] as num?)?.toDouble() ??
                      item.pricePerUnit,
                ),
              ],
              provenance: const Provenance.declared(ProvenanceSource.sample),
            ),
          );

          // Bán được thì tồn phải giảm. Không giảm thì "hàng sắp hết" không bao
          // giờ xảy ra, và cả hành trình nhập hàng không có lý do tồn tại.
          stockChanges[item.id] = (stockChanges[item.id] ?? 0) + quantity;

          // Phí sàn đi kèm ngay: doanh thu mà chưa có phí là con số tâng bốc,
          // và WTM-322 đã dựng hẳn một blocker để chặn đúng chuyện đó.
          final channel = event.payload['channel'] as String?;
          if (channel == 'shopee' || channel == 'tiktok') {
            final gross =
                ((event.payload['unitPrice'] as num?)?.toDouble() ??
                    item.pricePerUnit) *
                quantity;
            newSettlements
              ..add(
                _fee(
                  orderId: orderId,
                  kind: SettlementKind.commission,
                  amount: gross * 0.055,
                  at: event.occurredAt,
                ),
              )
              ..add(
                _fee(
                  orderId: orderId,
                  kind: SettlementKind.platformFee,
                  amount: gross * 0.028,
                  at: event.occurredAt,
                ),
              );
          }

        case DemoEventKind.shipmentDelayed:
          newShipments.add(
            Shipment(
              id: 'sample-${event.id}',
              trackingNumber: 'GHN${event.id.hashCode.abs() % 100000000}',
              status: ShipmentStatus.inTransit,
              carrier: Carrier.ghn,
              // Lùi mốc cập nhật để Rule Twin thấy nó đứng im thật — không đặt
              // sẵn một cờ "chậm": việc nó chậm là **kết luận**, không phải một
              // ô trong dữ liệu (WTM-323).
              lastUpdate: event.occurredAt.subtract(const Duration(days: 4)),
              eta: event.occurredAt.add(const Duration(days: 2)),
              origin: 'TP.HCM',
              destination: 'Hà Nội',
              provenance: ProvenanceSource.sample,
            ),
          );

        case DemoEventKind.deliveryFailed:
          newShipments.add(
            Shipment(
              id: 'sample-${event.id}',
              trackingNumber: 'GHN${event.id.hashCode.abs() % 100000000}',
              status: ShipmentStatus.failed,
              carrier: Carrier.ghn,
              lastUpdate: event.occurredAt,
              origin: 'TP.HCM',
              destination: 'Hà Nội',
              notes: 'Giao không thành công — khách không nghe máy',
              provenance: ProvenanceSource.sample,
            ),
          );

        // Những loại còn lại **chỉ sống trên dòng thời gian và trong hội
        // thoại**. Ép chúng thành bản ghi miền sẽ đẻ ra sáu bảng cho một bản
        // demo — đúng thứ §41 cấm.
        case DemoEventKind.commentReceived:
        case DemoEventKind.messageReceived:
        case DemoEventKind.reviewCreated:
        case DemoEventKind.refundRequested:
        case DemoEventKind.refundCompleted:
        case DemoEventKind.paymentFailed:
        case DemoEventKind.paymentSucceeded:
        case DemoEventKind.shipmentUpdated:
        case DemoEventKind.inventoryLow:
        case DemoEventKind.supplierQuoteChanged:
        case DemoEventKind.campaignPerformanceChanged:
        case DemoEventKind.customerChurnRisk:
        case DemoEventKind.repeatPurchaseDue:
        case DemoEventKind.settlementReceived:
          break;
      }
    }

    if (newOrders.isNotEmpty) await orders.upsertAll(newOrders);
    if (newShipments.isNotEmpty) await shipments.upsertAll(newShipments);
    if (newSettlements.isNotEmpty) await settlements.upsertAll(newSettlements);

    if (stockChanges.isNotEmpty) {
      await products.upsertAll([
        for (final entry in stockChanges.entries)
          if (catalogue[entry.key] case final item?)
            item.copyWith(
              // Không xuống dưới 0: một kho âm là một con số không giải thích
              // được cho ai.
              quantity: ((item.quantity ?? 0) - entry.value).clamp(0, 1 << 30),
            ),
      ]);
    }

    await events.markApplied(due.map((e) => e.id), DateTime.now());

    return SimulationTick(
      applied: due,
      ordersCreated: newOrders.length,
      day: await currentDay(),
    );
  }

  SettlementLine _fee({
    required String orderId,
    required SettlementKind kind,
    required double amount,
    required DateTime at,
  }) => SettlementLine(
    id: '$orderId-${kind.code}',
    orderId: orderId,
    kind: kind,
    direction: SettlementDirection.outbound,
    amount: amount.roundToDouble(),
    currency: 'VND',
    occurredAt: at,
    fundedBy: FundingSource.seller,
    provenance: const Provenance.declared(ProvenanceSource.sample),
  );

  static SalesChannel? _channel(String? code) => switch (code) {
    'shopee' => SalesChannel.shopee,
    'tiktok' => SalesChannel.tiktok,
    'facebook' => SalesChannel.facebook,
    _ => null,
  };
}

/// Kết quả một lần đẩy đồng hồ.
class SimulationTick {
  const SimulationTick({
    required this.applied,
    required this.ordersCreated,
    required this.day,
  }) : reason = null;

  /// Chưa nhập danh mục ⇒ không mô phỏng được.
  ///
  /// Nói ra chứ không gieo một danh mục bịa: câu hỏi *"còn màu đen không"* chỉ
  /// có nghĩa nếu áo đó có thật.
  const SimulationTick.needsCatalogue()
    : applied = const [],
      ordersCreated = 0,
      day = 0,
      reason = SimulationBlocked.needsCatalogue;

  const SimulationTick.notStarted()
    : applied = const [],
      ordersCreated = 0,
      day = 0,
      reason = SimulationBlocked.notStarted;

  const SimulationTick.finished()
    : applied = const [],
      ordersCreated = 0,
      day = 0,
      reason = SimulationBlocked.finished;

  final List<DemoEvent> applied;
  final int ordersCreated;
  final int day;

  /// `null` khi đã đẩy được. Chỗ gọi nói một câu tiếng Việt theo mã này.
  final SimulationBlocked? reason;

  bool get didSomething => applied.isNotEmpty;
}

enum SimulationBlocked {
  needsCatalogue('needs_catalogue'),
  notStarted('not_started'),
  finished('finished');

  const SimulationBlocked(this.code);

  final String code;
}
