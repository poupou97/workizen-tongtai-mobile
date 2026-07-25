import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-127 — [BusinessMetricsService] is the single source of truth for the
/// canonical KPIs (revenue, orders count, customers count, AOV). Reports/Home
/// reuse it; nothing recomputes these elsewhere.
void main() {
  CustomerOrder order(
    String id, {
    OrderStatus status = OrderStatus.confirmed,
    required double total,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: DateTime(2026, 7, 1),
    status: status,
    items: [
      OrderItem(
        productName: 'X',
        category: 'Home',
        quantity: 1,
        unitPrice: total,
      ),
    ],
  );

  Customer customer(String id) => Customer(
    id: id,
    name: id,
    phone: '',
    location: '',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  group('BusinessMetrics.from', () {
    test('empty data → zeros', () {
      final m = BusinessMetrics.from(orders: const [], customersCount: 0);
      expect(m, BusinessMetrics.empty);
      expect(m.hasSales, isFalse);
    });

    test('sums billable revenue, counts orders + customers, derives AOV', () {
      final m = BusinessMetrics.from(
        orders: [order('o1', total: 100000), order('o2', total: 300000)],
        customersCount: 5,
      );
      expect(m.revenue, 400000);
      expect(m.ordersCount, 2);
      expect(m.customersCount, 5);
      expect(m.averageOrderValue, 200000);
      expect(m.hasSales, isTrue);
    });

    test('cancelled orders are excluded from revenue + count + AOV', () {
      final m = BusinessMetrics.from(
        orders: [
          order('o1', total: 100000),
          order('o2', total: 999999, status: OrderStatus.cancelled),
        ],
        customersCount: 2,
      );
      expect(m.revenue, 100000);
      expect(m.ordersCount, 1);
      expect(m.averageOrderValue, 100000);
    });

    test('AOV is 0 when there are no billable orders', () {
      final m = BusinessMetrics.from(
        orders: [order('o1', total: 5000, status: OrderStatus.cancelled)],
        customersCount: 3,
      );
      expect(m.ordersCount, 0);
      expect(m.averageOrderValue, 0);
      expect(m.customersCount, 3); // customers still counted
    });
  });

  group('BusinessMetricsService.load', () {
    test('reads persisted orders + customers into the aggregate', () async {
      final service = BusinessMetricsService(
        InMemoryOrderRepository([
          order('o1', total: 250000),
          order('o2', total: 150000),
        ]),
        InMemoryCustomerRepository([customer('c1'), customer('c2')]),
      );
      final m = await service.load();
      expect(m.revenue, 400000);
      expect(m.ordersCount, 2);
      expect(m.customersCount, 2);
      expect(m.averageOrderValue, 200000);
    });

    test('a brand-new business loads BusinessMetrics.empty', () async {
      final service = BusinessMetricsService(
        InMemoryOrderRepository(),
        InMemoryCustomerRepository(),
      );
      expect(await service.load(), BusinessMetrics.empty);
    });
  });
}
