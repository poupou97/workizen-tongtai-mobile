import '../consumer/customer_order.dart';
import '../core/tongtai_enums.dart';
import '../finance/finance_transaction.dart';
import '../journey/business_goal.dart';
import '../opportunity/opportunity.dart';
import 'business_event.dart';

/// Emits a [BusinessEvent] per finance transaction (WTM-114). Income is a
/// positive amount, expense negative.
class FinanceEventSource implements BusinessEventSource {
  const FinanceEventSource(this._transactions);

  final List<FinanceTransaction> _transactions;

  @override
  List<BusinessEvent> events() => [
    for (final t in _transactions)
      BusinessEvent(
        id: 'evt-fin-${t.id}',
        type: BusinessEventType.finance,
        title: '${t.type.labelVi}: ${t.category}',
        subtitle: t.description,
        timestamp: t.date,
        amount: t.isIncome ? t.amount : -t.amount,
        refId: t.id,
      ),
  ];
}

/// Emits a [BusinessEvent] per customer order (WTM-114).
class OrderEventSource implements BusinessEventSource {
  const OrderEventSource(this._orders);

  final List<CustomerOrder> _orders;

  @override
  List<BusinessEvent> events() => [
    for (final o in _orders)
      BusinessEvent(
        id: 'evt-order-${o.id}',
        type: BusinessEventType.order,
        title: 'Đơn hàng ${o.orderNumber}',
        subtitle: '${o.totalQuantity} món · ${o.status.labelVi}',
        timestamp: o.date,
        // Cancelled orders carry no money.
        amount: o.status == OrderStatus.cancelled ? null : o.totalAmount,
        refId: o.id,
      ),
  ];
}

/// Emits a [BusinessEvent] per surfaced opportunity (WTM-114).
class OpportunityEventSource implements BusinessEventSource {
  const OpportunityEventSource(this._opportunities);

  final List<Opportunity> _opportunities;

  @override
  List<BusinessEvent> events() => [
    for (final o in _opportunities)
      BusinessEvent(
        id: 'evt-opp-${o.id}',
        type: BusinessEventType.opportunity,
        title: 'Cơ hội: ${o.title}',
        subtitle: 'Điểm AI ${o.aiScore.round()} · ${o.type.labelVi}',
        timestamp: o.discoveredAt,
        refId: o.id,
      ),
  ];
}

/// Emits a [BusinessEvent] per business goal created (WTM-114).
class JourneyEventSource implements BusinessEventSource {
  const JourneyEventSource(this._goals);

  final List<BusinessGoal> _goals;

  @override
  List<BusinessEvent> events() => [
    for (final g in _goals)
      BusinessEvent(
        id: 'evt-goal-${g.id}',
        type: BusinessEventType.journey,
        title: 'Mục tiêu: ${g.name}',
        subtitle: g.type.labelVi,
        timestamp: g.createdAt,
        refId: g.id,
      ),
  ];
}
