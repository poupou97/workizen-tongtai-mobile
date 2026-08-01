import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_context.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_context.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context_service.dart';
import 'package:tongtai/features/tongtai/metrics/business_health.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_signals.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/timeline/business_event.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_context.dart';

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

  BusinessGoal goal(
    String id, {
    double target = 100000000,
    double achieved = 20000000,
    DateTime? start,
    DateTime? end,
  }) => BusinessGoal(
    id: id,
    name: id,
    type: GoalType.revenue,
    targetAmount: target,
    achievedAmount: achieved,
    growthTarget: 0,
    growthAchieved: 0,
    startDate: start ?? DateTime(2026, 7, 1),
    endDate: end ?? DateTime(2026, 9, 30),
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );

  FinanceTransaction txn(
    String id, {
    TransactionType type = TransactionType.income,
    double amount = 1000000,
    DateTime? date,
  }) => FinanceTransaction(
    id: id,
    type: type,
    category: FinanceCategory.other,
    amount: amount,
    date: date ?? DateTime(2026, 7, 10),
  );

  BusinessContextService service({
    List<CustomerOrder> orders = const [],
    List<Customer> customers = const [],
    List<Product> products = const [],
    List<Opportunity> opportunities = const [],
    List<BusinessGoal> goals = const [],
    List<FinanceTransaction> transactions = const [],
    DateTime? now,
  }) {
    final orderRepo = InMemoryOrderRepository(orders);
    final customerRepo = InMemoryCustomerRepository(customers);
    final productRepo = InMemoryProductRepository(products);
    final goalRepo = InMemoryBusinessGoalRepository(goals);
    final financeRepo = InMemoryFinanceRepository(transactions);
    DateTime clock() => now ?? DateTime(2026, 7, 25);
    return BusinessContextService(
      BusinessMetricsService(orderRepo, customerRepo),
      CustomerContextProvider(customerRepo),
      OrderContextProvider(orderRepo),
      InventoryContextProvider(productRepo),
      OpportunityContextProvider(opportunities: opportunities, clock: clock),
      JourneyContextProvider(goalRepo, clock: clock),
      FinanceContextProvider(financeRepo, clock: clock),
      TimelineContextProvider(
        financeRepo,
        orderRepo,
        goalRepo,
        opportunities: opportunities,
        clock: clock,
      ),
      clock: clock,
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
            score: OpportunityScore.fixed(50),
            discoveredAt: DateTime(2026, 7, 24),
          ),
          Opportunity(
            id: 'b',
            type: OpportunityType.trend,
            title: 't',
            description: 'd',
            expectedImpact: 5000000,
            score: OpportunityScore.fixed(50),
            discoveredAt: DateTime(2026, 7, 24),
          ),
          // dismissed → excluded from the active total + counts
          Opportunity(
            id: 'c',
            type: OpportunityType.seasonal,
            title: 't',
            description: 'd',
            expectedImpact: 90000000,
            score: OpportunityScore.fixed(50),
            discoveredAt: DateTime(2026, 7, 24),
            reaction: OpportunityReaction.dismissed,
          ),
        ], now: now);

        expect(s.total, 2); // dismissed excluded
        expect(s.signal(OpportunitySignal.highValue), 1);
        expect(s.signal(OpportunitySignal.urgent), 1);
        // WTM-193: High Risk is no longer emitted — it came from a constant
        // ROI, so it only restated which rule fired.
        expect(s.signal(OpportunitySignal.highRisk), 0);
      },
    );

    test('JourneySummary counts goals by pace + active/completed/at-risk', () {
      final now = DateTime(2026, 7, 25); // ~26% through a Jul 1–Sep 30 timeline
      final s = JourneySummary.from([
        goal('done', achieved: 100000000), // progress 1.0 -> completed
        goal('ahead', achieved: 40000000), // 0.40 vs ~0.26 elapsed -> ahead
        goal('behind', achieved: 2000000), // 0.02 -> behind
        goal('soon', start: DateTime(2026, 8, 1)), // future -> not started
      ], now: now);

      expect(s.total, 4);
      expect(s.completedCount, 1);
      expect(s.activeCount, 3); // everything not completed
      expect(s.atRiskCount, 1); // the behind one
      expect(s.pace(GoalPace.ahead), 1);
      expect(s.pace(GoalPace.notStarted), 1);
    });

    test('TimelineSummary counts events by type + recent window + latest', () {
      final now = DateTime(2026, 7, 25); // recent window cutoff = Jul 18
      BusinessEvent event(String id, BusinessEventType type, DateTime at) =>
          BusinessEvent(id: id, type: type, title: id, timestamp: at);
      final s = TimelineSummary.from([
        event('e1', BusinessEventType.order, DateTime(2026, 7, 24)), // recent
        event('e2', BusinessEventType.order, DateTime(2026, 7, 20)), // recent
        event('e3', BusinessEventType.finance, DateTime(2026, 7, 10)), // old
      ], now: now);

      expect(s.totalEvents, 3);
      expect(s.type(BusinessEventType.order), 2);
      expect(s.type(BusinessEventType.finance), 1);
      expect(s.recentCount, 2); // Jul 24 + Jul 20
      expect(s.latestAt, DateTime(2026, 7, 24));
      expect(s.hasActivity, isTrue);
    });

    test('TimelineSummary.empty has no activity', () {
      expect(TimelineSummary.empty.hasActivity, isFalse);
      expect(TimelineSummary.empty.latestAt, isNull);
    });
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
            score: OpportunityScore.fixed(50),
            discoveredAt: DateTime(2026, 7, 24),
          ),
        ],
        goals: [goal('g1')],
        transactions: [txn('t1', amount: 500000)],
      ).load();

      expect(ctx.metrics.revenue, 100000); // cancelled excluded
      expect(ctx.metrics.customersCount, 2);
      expect(ctx.customers.total, 2);
      expect(ctx.orders.total, 2);
      expect(ctx.inventory.productCount, 2);
      expect(ctx.inventory.lowStockCount, 1);
      expect(ctx.opportunity.total, 1);
      expect(ctx.opportunity.signal(OpportunitySignal.highValue), 1);
      expect(ctx.journey.total, 1);
      expect(ctx.finance.incomeYtd, 500000);
      expect(ctx.finance.hasActivity, isTrue);
      // Timeline projects the same records into an activity stream:
      // 2 orders + 1 goal + 1 transaction + 1 opportunity = 5 events.
      expect(ctx.timeline.totalEvents, 5);
      expect(ctx.timeline.type(BusinessEventType.order), 2);
      expect(ctx.timeline.type(BusinessEventType.opportunity), 1);
      expect(ctx.timeline.hasActivity, isTrue);
      expect(ctx.hasData, isTrue);
    });

    test('a brand-new business loads an empty context', () async {
      final ctx = await service().load();
      expect(ctx.hasData, isFalse);
      expect(ctx.customers.total, 0);
      expect(ctx.orders.total, 0);
      expect(ctx.inventory.productCount, 0);
      expect(ctx.opportunity.total, 0);
      expect(ctx.journey.total, 0);
      expect(ctx.finance.hasActivity, isFalse);
      expect(ctx.timeline.hasActivity, isFalse);
      expect(ctx.timeline.totalEvents, 0);
    });

    test(
      'journey/finance data alone marks the business as having data',
      () async {
        final journeyOnly = await service(goals: [goal('g1')]).load();
        expect(journeyOnly.hasData, isTrue);
        expect(journeyOnly.journey.activeCount, 1);

        final financeOnly = await service(transactions: [txn('t1')]).load();
        expect(financeOnly.hasData, isTrue);
        expect(financeOnly.finance.hasActivity, isTrue);
      },
    );
  });

  group('Business Snapshot (WTM-132)', () {
    test('carries version + generatedAt and embeds health', () async {
      final ctx = await service(
        customers: [customer('c1')],
        now: DateTime(2026, 7, 25, 9),
      ).load();
      expect(ctx.version, kBusinessContextVersion);
      expect(ctx.generatedAt, DateTime(2026, 7, 25, 9));
      // No sales yet → not enough data, confidence 1.0 (rule-based v1).
      expect(ctx.health.status, BusinessHealthStatus.notEnoughData);
      expect(ctx.health.confidence, 1.0);
      expect(ctx.health.reason, isNotEmpty);
    });

    test('a business with sales reports healthy in the snapshot', () async {
      final ctx = await service(
        orders: [order('o1', total: 100000)],
        customers: [customer('c1')],
      ).load();
      expect(ctx.health.status, BusinessHealthStatus.healthy);
      expect(ctx.health.isHealthy, isTrue);
    });

    test('hasData ignores the timeline projection (no double-count)', () {
      // Timeline re-derives from the other slices, so a snapshot whose only
      // "activity" is timeline events (and every real slice empty) still has no
      // data — timeline must not leak into hasData.
      final ctx = BusinessContext(
        generatedAt: DateTime(2026, 7, 25),
        metrics: BusinessMetrics.empty,
        customers: CustomerSummary.empty,
        orders: OrderSummary.empty,
        inventory: InventorySummary.empty,
        opportunity: OpportunitySummary.empty,
        journey: JourneySummary.empty,
        finance: FinanceSummary.empty,
        timeline: TimelineSummary.from([
          BusinessEvent(
            id: 'e',
            type: BusinessEventType.order,
            title: 'o',
            timestamp: DateTime(2026, 7, 24),
          ),
        ], now: DateTime(2026, 7, 25)),
        health: BusinessHealth.notEnoughData,
      );
      expect(ctx.timeline.hasActivity, isTrue);
      expect(ctx.hasData, isFalse);
    });
  });
}
