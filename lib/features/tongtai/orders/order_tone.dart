import '../../../core/design/tt.dart';
import '../core/tongtai_enums.dart';

/// **Trạng thái đơn → sắc thái ngữ nghĩa** — WTM-414 (DS-2).
///
/// Trả `TtStatus`, không trả `Color`: xem chú thích ở `inventory_tone.dart` —
/// một hàm trả `Color` cho phép màn đặt token ấy vào bất cứ đâu, kể cả lên một
/// con số không mang phán quyết.
///
/// Trước DS-2 hàm này sống trong `tongtai_customer_history_screen.dart`. Trạng
/// thái một đơn hàng không phải khái niệm của màn lịch sử khách.
TtStatus tongtaiOrderStatusTone(OrderStatus status) => switch (status) {
  OrderStatus.pending => TtStatus.warning,
  OrderStatus.confirmed || OrderStatus.shipped => TtStatus.info,
  OrderStatus.delivered => TtStatus.success,
  OrderStatus.cancelled => TtStatus.danger,
};
