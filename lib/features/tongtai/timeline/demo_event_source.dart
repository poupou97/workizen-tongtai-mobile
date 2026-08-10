import '../simulation/demo_event.dart';
import 'business_event.dart';

/// Sổ sự kiện mô phỏng, nhìn như **một nguồn nữa** của dòng thời gian —
/// WTM-346.
///
/// ## Vì sao là nguồn, không phải màn
///
/// Trước đây chuyện demo có màn riêng còn đơn thật có màn riêng, nên **không
/// màn nào kể được trọn một ngày kinh doanh**: màn demo không thấy đơn thật,
/// màn thật không thấy chuyện demo. Người bán thì chỉ có một ngày.
///
/// Đưa nó về đúng chỗ — một `BusinessEventSource` — thì dòng thời gian hợp
/// nhất tự có, và ngày connector thật thay chỗ mô phỏng, thứ phải đổi là
/// **một nguồn**, không phải một màn.
class DemoBusinessEventSource implements BusinessEventSource {
  const DemoBusinessEventSource(this.applied);

  /// Chỉ những việc **đã áp**. Việc chưa tới lượt mà nằm trên dòng thời gian
  /// là nói trước tương lai (WTM-344).
  final List<DemoEvent> applied;

  @override
  List<BusinessEvent> events() => [
    for (final e in applied)
      BusinessEvent(
        id: e.id,
        type: _typeOf(e.kind),
        title: e.headline,
        timestamp: e.occurredAt,
        actorCode: e.actor.code,
        vendor: e.vendor,
        correlationId: e.correlationId,
        refId: e.subjectId,
      ),
  ];

  /// Xếp việc demo vào **cùng bộ loại** với bản ghi thật, để bộ lọc theo loại
  /// áp cho cả hai. Một loại "demo" riêng sẽ chia đôi bộ lọc và trả lại đúng
  /// cái vách ngăn vừa gỡ.
  static BusinessEventType _typeOf(DemoEventKind kind) => switch (kind) {
    DemoEventKind.orderCreated => BusinessEventType.order,
    DemoEventKind.paymentFailed ||
    DemoEventKind.paymentSucceeded ||
    DemoEventKind.settlementReceived ||
    DemoEventKind.refundRequested ||
    DemoEventKind.refundCompleted => BusinessEventType.finance,
    DemoEventKind.inventoryLow ||
    DemoEventKind.supplierQuoteChanged => BusinessEventType.inventory,
    DemoEventKind.messageReceived ||
    DemoEventKind.commentReceived ||
    DemoEventKind.reviewCreated ||
    DemoEventKind.customerChurnRisk ||
    DemoEventKind.repeatPurchaseDue => BusinessEventType.customer,
    DemoEventKind.shipmentUpdated ||
    DemoEventKind.shipmentDelayed ||
    DemoEventKind.deliveryFailed => BusinessEventType.order,
    DemoEventKind.campaignPerformanceChanged => BusinessEventType.opportunity,
  };
}
