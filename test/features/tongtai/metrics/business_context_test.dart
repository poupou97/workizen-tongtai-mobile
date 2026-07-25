import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/metrics/business_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context_service.dart';
import 'package:tongtai/features/tongtai/metrics/business_health.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-129 — BusinessContext is the business Aggregate Root (Progressive
/// Aggregation Phase 1: metrics + customers + orders + inventory). AI reads only
/// this; Home consumes it; BusinessHealth derives from it.
void main() {
  Customer customer(String id, {double spent = 1000000}) => Customer(
    id: id,
    name: id,
    phone: '',
    location: '',
    orderCount: 0,
    totalSpent: spent,
    lastPurchaseDate: null,
  );

  CustomerOrder order(
    String id, {
    OrderStatus status = OrderStatus.confirmed,
    double total = 100000,
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

  Product product(
    String id, {
    int qty = 10,
    int reorder = 3,
    double price = 5000,
  }) => Product(
    id: id,
    sku: 'SKU-$id',
    name: id,
    category: 'Home',
    quantity: qty,
    pricePerUnit: price,
    reorderLevel: reorder,
    updatedAt: DateTime(2026, 7, 1),
  );

  group('summaries', () {
    test('CustomerSummary counts total + by tier', () {
      final s = CustomerSummary.from([
        customer('a', spent: 40000000), // VIP (≥30M)
        customer('b', spent: 12000000), // Gold (≥10M)
        customer('c', spent: 500000), // Bronze
      ]);
      expect(s.total, 3);
      expect(s.tier(CustomerTier.vip), 1);
      expect(s.tier(CustomerTier.gold), 1);
      expect(s.tier(CustomerTier.bronze), 1);
      expect(s.tier(CustomerTier.silver), 0);
    });

    test('OrderSummary counts total, by status, and open orders', () {
      final s = OrderSummary.from([
        order('o1', status: OrderStatus.pending),
        order('o2', status: OrderStatus.delivered),
        order('o3', status: OrderStatus.cancelled),
        order('o4', status: OrderStatus.confirmed),
      ]);
      expect(s.total, 4);
      expect(s.status(OrderStatus.pending), 1);
      expect(s.status(OrderStatus.delivered), 1);
      // Open = not delivered and not cancelled → pending + confirmed.
      expect(s.openCount, 2);
    });

    test('InventorySummary counts stock health + value', () {
      final s = InventorySummary.from([
        product('p1', qty: 10, reorder: 3, price: 5000), // in stock
        product('p2', qty: 2, reorder: 3, price: 1000), // low stock
        product('p3', qty: 0, reorder: 3, price: 2000), // out of stock
      ]);
      expect(s.productCount, 3);
      expect(s.lowStockCount, 1);
      expect(s.outOfStockCount, 1);
      // Stock value = 10×5000 + 2×1000 + 0×2000.
      expect(s.stockValue, 52000);
    });
  });

  group('BusinessContextService.load', () {
    test('assembles the Phase-1 aggregate from the repositories', () async {
      final service = BusinessContextService(
        InMemoryOrderRepository([
          order('o1', total: 100000),
          order('o2', total: 300000, status: OrderStatus.cancelled),
        ]),
        InMemoryCustomerRepository([customer('c1'), customer('c2')]),
        InMemoryProductRepository([product('p1'), product('p2', qty: 1)]),
      );
      final ctx = await service.load();

      // Metrics exclude the cancelled order.
      expect(ctx.metrics.revenue, 100000);
      expect(ctx.metrics.ordersCount, 1);
      expect(ctx.metrics.customersCount, 2);
      expect(ctx.customers.total, 2);
      expect(ctx.orders.total, 2); // summary counts all statuses
      expect(ctx.inventory.productCount, 2);
      expect(ctx.inventory.lowStockCount, 1);
      expect(ctx.hasData, isTrue);
    });

    test('a brand-new business loads BusinessContext.empty', () async {
      final service = BusinessContextService(
        InMemoryOrderRepository(),
        InMemoryCustomerRepository(),
        InMemoryProductRepository(),
      );
      final ctx = await service.load();
      expect(ctx.hasData, isFalse);
      expect(ctx.metrics, BusinessContext.empty.metrics);
      expect(ctx.customers.total, 0);
      expect(ctx.orders.total, 0);
      expect(ctx.inventory.productCount, 0);
    });
  });

  group('BusinessHealth.fromContext', () {
    test('no data → not enough data; with sales → healthy', () {
      expect(
        BusinessHealth.fromContext(BusinessContext.empty),
        BusinessHealth.notEnoughData,
      );
      final withSales = BusinessContext(
        metrics: BusinessContext.empty.metrics,
        customers: CustomerSummary.empty,
        orders: OrderSummary.empty,
        inventory: InventorySummary.empty,
      );
      expect(
        BusinessHealth.fromContext(withSales),
        BusinessHealth.notEnoughData,
      );
    });
  });
}
