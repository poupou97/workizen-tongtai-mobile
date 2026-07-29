import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_context.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/metrics/business_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context_service.dart';
import 'package:tongtai/features/tongtai/metrics/business_health.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_signals.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-129/131 — BusinessContext is the Aggregate Root, composed from one
/// Context Provider per capability. AI reads only this; Home consumes it.
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

  BusinessContextService service({
    List<CustomerOrder> orders = const [],
    List<Customer> customers = const [],
    List<Product> products = const [],
    List<Opportunity> opportunities = const [],
    DateTime? now,
  }) {
    final orderRepo = InMemoryOrderRepository(orders);
    final customerRepo = InMemoryCustomerRepository(customers);
    final productRepo = InMemoryProductRepository(products);
    return BusinessContextService(
      BusinessMetricsService(orderRepo, customerRepo),
      CustomerContextProvider(customerRepo),
      OrderContextProvider(orderRepo),
      InventoryContextProvider(productRepo),
      OpportunityContextProvider(
        opportunities: opportunities,
        clock: () => now ?? DateTime(2026, 7, 25),
      ),
    );
  }

  group('capability summaries', () {
    test('CustomerSummary counts total + by tier', () {
      final s = CustomerSummary.from([
        customer('a', spent: 40000000), // VIP
        customer('b', spent: 12000000), // Gold
        customer('c', spent: 500000), // Bronze
      ]);
      expect(s.total, 3);
      expect(s.tier(CustomerTier.vip), 1);
      expect(s.tier(CustomerTier.gold), 1);
      expect(s.tier(CustomerTier.bronze), 1);
    });

    test('OrderSummary counts total, by status, and open orders', () {
      final s = OrderSummary.from([
        order('o1', status: OrderStatus.pending),
        order('o2', status: OrderStatus.delivered),
        order('o3', status: OrderStatus.cancelled),
        order('o4', status: OrderStatus.confirmed),
      ]);
      expect(s.total, 4);
      expect(s.openCount, 2); // pending + confirmed
    });

    test('InventorySummary counts stock health + value', () {
      final s = InventorySummary.from([
        product('p1', qty: 10, reorder: 3, price: 5000),
        product('p2', qty: 2, reorder: 3, price: 1000),
        product('p3', qty: 0, reorder: 3, price: 2000),
      ]);
      expect(s.productCount, 3);
      expect(s.lowStockCount, 1);
      expect(s.outOfStockCount, 1);
      expect(s.stockValue, 52000);
    });

    test(
      'OpportunitySummary counts active opportunities by rule-based signal',
      () {
        final now = DateTime(2026, 7, 25);
        final s = OpportunitySummary.from([
          // seasonal high value → highValue + urgent
          Opportunity(
            id: 'a',
            type: OpportunityType.seasonal,
            title: 't',
            description: 'd',
            expectedImpact: 40000000,
            estimatedRoi: 2.5,
            aiScore: 50,
            discoveredAt: DateTime(2026, 7, 24),
          ),
          // low ROI → highRisk
          Opportunity(
            id: 'b',
            type: OpportunityType.trend,
            title: 't',
            description: 'd',
            expectedImpact: 5000000,
            estimatedRoi: 1.5,
            aiScore: 50,
            discoveredAt: DateTime(2026, 7, 24),
          ),
          // dismissed → excluded from the active total + counts
          Opportunity(
            id: 'c',
            type: OpportunityType.seasonal,
            title: 't',
            description: 'd',
            expectedImpact: 90000000,
            estimatedRoi: 1.0,
            aiScore: 50,
            discoveredAt: DateTime(2026, 7, 24),
            reaction: OpportunityReaction.dismissed,
          ),
        ], now: now);

        expect(s.total, 2); // dismissed excluded
        expect(s.signal(OpportunitySignal.highValue), 1);
        expect(s.signal(OpportunitySignal.urgent), 1);
        expect(s.signal(OpportunitySignal.highRisk), 1);
      },
    );
  });

  group('BusinessContextService.load (composes providers)', () {
    test('assembles the aggregate from every capability provider', () async {
      final ctx = await service(
        orders: [
          order('o1', total: 100000),
          order('o2', total: 300000, status: OrderStatus.cancelled),
        ],
        customers: [customer('c1'), customer('c2')],
        products: [product('p1'), product('p2', qty: 1)],
        opportunities: [
          Opportunity(
            id: 'a',
            type: OpportunityType.seasonal,
            title: 't',
            description: 'd',
            expectedImpact: 40000000,
            estimatedRoi: 2.5,
            aiScore: 50,
            discoveredAt: DateTime(2026, 7, 24),
          ),
        ],
      ).load();

      expect(ctx.metrics.revenue, 100000); // cancelled excluded
      expect(ctx.metrics.customersCount, 2);
      expect(ctx.customers.total, 2);
      expect(ctx.orders.total, 2);
      expect(ctx.inventory.productCount, 2);
      expect(ctx.inventory.lowStockCount, 1);
      expect(ctx.opportunity.total, 1);
      expect(ctx.opportunity.signal(OpportunitySignal.highValue), 1);
      expect(ctx.hasData, isTrue);
    });

    test('a brand-new business loads an empty context', () async {
      final ctx = await service().load();
      expect(ctx.hasData, isFalse);
      expect(ctx.customers.total, 0);
      expect(ctx.orders.total, 0);
      expect(ctx.inventory.productCount, 0);
      expect(ctx.opportunity.total, 0);
    });
  });

  group('BusinessHealth.fromContext', () {
    test('empty context → not enough data', () {
      expect(
        BusinessHealth.fromContext(BusinessContext.empty),
        BusinessHealth.notEnoughData,
      );
    });
  });
}
