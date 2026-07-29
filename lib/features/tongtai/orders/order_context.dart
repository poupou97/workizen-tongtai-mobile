import 'package:flutter/foundation.dart';

import '../core/capability_context_provider.dart';
import '../core/tongtai_enums.dart';
import 'order.dart';
import 'order_repository.dart';

/// Orders-capability slice of the business snapshot (WTM-129/131).
@immutable
class OrderSummary {
  const OrderSummary({required this.total, required this.byStatus});

  static const OrderSummary empty = OrderSummary(total: 0, byStatus: {});

  final int total;

  /// Count of orders in each lifecycle status.
  final Map<OrderStatus, int> byStatus;

  int status(OrderStatus s) => byStatus[s] ?? 0;

  /// Orders still open (not delivered or cancelled) — a useful attention signal.
  int get openCount =>
      total - status(OrderStatus.delivered) - status(OrderStatus.cancelled);

  factory OrderSummary.from(List<CustomerOrder> orders) {
    final byStatus = <OrderStatus, int>{};
    for (final o in orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
    }
    return OrderSummary(total: orders.length, byStatus: byStatus);
  }
}

/// The Orders capability's Context Provider (WTM-131) — loads orders from the
/// repository and produces the [OrderSummary] slice for BusinessContext.
class OrderContextProvider implements CapabilityContextProvider<OrderSummary> {
  const OrderContextProvider(this._repository);

  final OrderRepository _repository;

  @override
  Future<OrderSummary> load() async =>
      OrderSummary.from(await _repository.loadAll());
}
