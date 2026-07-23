import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order_history_service.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';

/// Unit tests for the WTM-77 purchase-history domain:
///  - AC1: newest-first ordering
///  - AC2/AC3: order totals + quantities derived from item lines
///  - AC4: date-range (inclusive) and category filters
///  - AC5: average order value + repurchase rate (cancelled excluded)
void main() {
  CustomerOrder order(
    String id,
    String customerId,
    DateTime date, {
    OrderStatus status = OrderStatus.delivered,
    List<OrderItem>? items,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: 'DH-$id',
    date: date,
    status: status,
    items:
        items ??
        const [
          OrderItem(
            productName: 'Widget',
            category: 'Electronics',
            quantity: 1,
            unitPrice: 100000,
          ),
        ],
  );

  group('CustomerOrder derived values (AC2/AC3)', () {
    test('totalQuantity and totalAmount sum the item lines', () {
      final o = order(
        'x',
        'c1',
        DateTime(2026, 7, 1),
        items: const [
          OrderItem(
            productName: 'Fan',
            category: 'Electronics',
            quantity: 2,
            unitPrice: 89000,
          ),
          OrderItem(
            productName: 'Shirt',
            category: 'Fashion',
            quantity: 3,
            unitPrice: 120000,
          ),
        ],
      );
      expect(o.totalQuantity, 5);
      expect(o.totalAmount, 2 * 89000 + 3 * 120000);
      expect(o.categories, {'Electronics', 'Fashion'});
    });

    test('sample orders are well-formed (unique ids, non-empty items)', () {
      final ids = kSampleCustomerOrders.map((o) => o.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final o in kSampleCustomerOrders) {
        expect(o.items, isNotEmpty, reason: o.id);
        expect(o.totalAmount, greaterThan(0), reason: o.id);
      }
    });
  });

  group('ordersFor (AC1 + AC4)', () {
    final service = CustomerOrderHistoryService([
      order('a', 'c1', DateTime(2026, 3, 1)),
      order('b', 'c1', DateTime(2026, 7, 1)),
      order('c', 'c1', DateTime(2026, 5, 1)),
      order('z', 'c2', DateTime(2026, 6, 1)), // another customer
    ]);

    test('returns only the customer\'s orders, newest first', () {
      final orders = service.ordersFor('c1');
      expect(orders.map((o) => o.id), ['b', 'c', 'a']);
    });

    test('date range is inclusive on both bounds', () {
      final orders = service.ordersFor(
        'c1',
        OrderHistoryQuery(from: DateTime(2026, 3, 1), to: DateTime(2026, 5, 1)),
      );
      expect(orders.map((o) => o.id), ['c', 'a']);
    });

    test('from-only bound drops older orders', () {
      final orders = service.ordersFor(
        'c1',
        OrderHistoryQuery(from: DateTime(2026, 4, 1)),
      );
      expect(orders.map((o) => o.id), ['b', 'c']);
    });

    test('category filter matches any item line in the order', () {
      final mixed = CustomerOrderHistoryService([
        order(
          'm1',
          'c1',
          DateTime(2026, 7, 1),
          items: const [
            OrderItem(
              productName: 'Fan',
              category: 'Electronics',
              quantity: 1,
              unitPrice: 89000,
            ),
            OrderItem(
              productName: 'Shirt',
              category: 'Fashion',
              quantity: 1,
              unitPrice: 120000,
            ),
          ],
        ),
        order(
          'm2',
          'c1',
          DateTime(2026, 6, 1),
          items: const [
            OrderItem(
              productName: 'Lamp',
              category: 'Home',
              quantity: 1,
              unitPrice: 145000,
            ),
          ],
        ),
      ]);
      expect(
        mixed
            .ordersFor('c1', const OrderHistoryQuery(category: 'Fashion'))
            .map((o) => o.id),
        ['m1'],
      );
      expect(
        mixed
            .ordersFor('c1', const OrderHistoryQuery(category: 'Home'))
            .map((o) => o.id),
        ['m2'],
      );
    });

    test('categoriesFor lists distinct categories, sorted', () {
      expect(CustomerOrderHistoryService.sample().categoriesFor('c01'), [
        'Electronics',
        'Fashion',
        'Home',
      ]);
    });
  });

  group('metricsFor (AC5)', () {
    test('average order value = total / count over non-cancelled orders', () {
      final service = CustomerOrderHistoryService([
        order(
          'a',
          'c1',
          DateTime(2026, 7, 1),
          items: const [
            OrderItem(
              productName: 'A',
              category: 'Electronics',
              quantity: 1,
              unitPrice: 300000,
            ),
          ],
        ),
        order(
          'b',
          'c1',
          DateTime(2026, 6, 1),
          items: const [
            OrderItem(
              productName: 'B',
              category: 'Electronics',
              quantity: 1,
              unitPrice: 100000,
            ),
          ],
        ),
      ]);
      final metrics = service.metricsFor('c1');
      expect(metrics.orderCount, 2);
      expect(metrics.totalSpent, 400000);
      expect(metrics.averageOrderValue, 200000);
      expect(metrics.repurchaseRate, 0.5); // 1 repeat of 2 orders
    });

    test('cancelled orders are excluded from the metrics', () {
      final service = CustomerOrderHistoryService([
        order('a', 'c1', DateTime(2026, 7, 1)),
        order('b', 'c1', DateTime(2026, 6, 1), status: OrderStatus.cancelled),
      ]);
      final metrics = service.metricsFor('c1');
      expect(metrics.orderCount, 1);
      expect(metrics.repurchaseRate, 0); // single realized order — no repeat
    });

    test('a customer with no orders gets the empty metrics', () {
      final metrics = CustomerOrderHistoryService.sample().metricsFor('nobody');
      expect(metrics, OrderHistoryMetrics.empty);
      expect(metrics.averageOrderValue, 0);
      expect(metrics.repurchaseRate, 0);
    });
  });
}
