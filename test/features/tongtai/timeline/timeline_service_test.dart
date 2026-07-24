import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_controller.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/timeline/business_event.dart';
import 'package:tongtai/features/tongtai/timeline/business_event_sources.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_service.dart';

/// WTM-114 — event sources map domain records to events; the service merges
/// and orders them.
void main() {
  group('event sources', () {
    test('finance income is positive, expense negative', () {
      final events = FinanceEventSource([
        FinanceTransaction(
          id: 'i',
          type: TransactionType.income,
          category: 'Bán hàng',
          amount: 3000000,
          date: DateTime(2026, 7, 10),
        ),
        FinanceTransaction(
          id: 'e',
          type: TransactionType.expense,
          category: 'Nhập hàng',
          amount: 1800000,
          date: DateTime(2026, 7, 9),
        ),
      ]).events();

      expect(events.firstWhere((e) => e.refId == 'i').amount, 3000000);
      expect(events.firstWhere((e) => e.refId == 'e').amount, -1800000);
      expect(events.every((e) => e.type == BusinessEventType.finance), isTrue);
    });

    test('a cancelled order carries no amount', () {
      CustomerOrder order(String id, OrderStatus status) => CustomerOrder(
        id: id,
        customerId: 'c',
        orderNumber: id,
        date: DateTime(2026, 7, 1),
        status: status,
        items: const [
          OrderItem(
            productName: 'x',
            category: 'Home',
            quantity: 1,
            unitPrice: 500000,
          ),
        ],
      );

      final events = OrderEventSource([
        order('ok', OrderStatus.delivered),
        order('void', OrderStatus.cancelled),
      ]).events();

      expect(events.firstWhere((e) => e.refId == 'ok').amount, 500000);
      expect(events.firstWhere((e) => e.refId == 'void').amount, isNull);
    });

    test('opportunity source uses the discovered date and title', () {
      final events = OpportunityEventSource([
        Opportunity(
          id: 'o1',
          type: OpportunityType.trend,
          title: 'Đồ gia dụng mini',
          description: 'd',
          expectedImpact: 1000000,
          estimatedRoi: 2,
          aiScore: 81,
          discoveredAt: DateTime(2026, 6, 20),
        ),
      ]).events();

      expect(events.single.type, BusinessEventType.opportunity);
      expect(events.single.timestamp, DateTime(2026, 6, 20));
      expect(events.single.title, contains('Đồ gia dụng mini'));
    });
  });

  group('TimelineService', () {
    test('merges every source and sorts newest first', () {
      final service = TimelineService.sample();
      final events = service.timeline();

      // Count reconciles with the four wired sources.
      final expected =
          FinanceEventSource(kSampleTransactions).events().length +
          OrderEventSource(kSampleCustomerOrders).events().length +
          OpportunityEventSource(kSampleOpportunities).events().length +
          JourneyEventSource(kSampleBusinessGoals).events().length;
      expect(events.length, expected);

      // Strictly non-increasing timestamps.
      for (var i = 0; i + 1 < events.length; i++) {
        expect(
          events[i].timestamp.isBefore(events[i + 1].timestamp),
          isFalse,
          reason: 'event $i is older than ${i + 1}',
        );
      }
    });

    test('limit caps the number of events', () {
      final events = TimelineService.sample().timeline(limit: 5);
      expect(events, hasLength(5));
    });

    test('groups by day, newest day first', () {
      final source = _StaticSource([
        _evt('a', DateTime(2026, 7, 10, 9)),
        _evt('b', DateTime(2026, 7, 10, 14)),
        _evt('c', DateTime(2026, 7, 8, 8)),
      ]);
      final days = TimelineService([source]).groupedByDay();

      expect(days.map((d) => d.date), [
        DateTime(2026, 7, 10),
        DateTime(2026, 7, 8),
      ]);
      // Within the newest day, newest event first (b before a).
      expect(days.first.events.map((e) => e.id), ['b', 'a']);
    });

    test('an empty set of sources is empty', () {
      final service = TimelineService([_StaticSource(const [])]);
      expect(service.isEmpty, isTrue);
      expect(service.timeline(), isEmpty);
    });
  });
}

BusinessEvent _evt(String id, DateTime ts) => BusinessEvent(
  id: id,
  type: BusinessEventType.finance,
  title: id,
  timestamp: ts,
);

class _StaticSource implements BusinessEventSource {
  const _StaticSource(this._events);
  final List<BusinessEvent> _events;
  @override
  List<BusinessEvent> events() => _events;
}
