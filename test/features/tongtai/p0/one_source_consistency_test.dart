import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_context.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_context.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context_service.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_rule_engine.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_context.dart';

/// P0 §1 (WTM-144) — ONE SOURCE end-to-end: after seeding, the
/// BusinessContext (what Home + AI read), the domain repositories (what each
/// capability screen reads) and the Opportunity Rule Engine all agree.
/// Includes the mandated acceptance scenario:
/// fresh → seed → create → update → delete-samples → restart → verify.
void main() {
  final now = DateTime(2026, 7, 24);
  DateTime clock() => now;

  late InMemoryCustomerRepository customers;
  late InMemoryProductRepository products;
  late InMemoryOrderRepository orders;
  late InMemoryBusinessGoalRepository goals;
  late InMemoryFinanceRepository finance;
  late SampleDataSeeder seeder;

  setUp(() {
    customers = InMemoryCustomerRepository();
    products = InMemoryProductRepository([]);
    orders = InMemoryOrderRepository();
    goals = InMemoryBusinessGoalRepository();
    finance = InMemoryFinanceRepository();
    seeder = SampleDataSeeder(
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      finance: finance,
    );
  });

  /// The PRODUCTION BusinessContext composition — identical wiring to
  /// tongtai_context_provider.dart, over these repositories. Building it
  /// fresh simulates an app restart (the repos persist, like the DB file).
  BusinessContextService buildContextService() {
    Future<List<dynamic>> generated() async =>
        const OpportunityRuleEngine().generate(
          products: await products.loadAll(),
          customers: await customers.loadAll(),
          orders: await orders.loadAll(),
          goals: await goals.loadAll(),
          now: now,
        );
    return BusinessContextService(
      BusinessMetricsService(orders, customers),
      CustomerContextProvider(customers),
      OrderContextProvider(orders),
      InventoryContextProvider(products),
      OpportunityContextProvider(
        source: () async => (await generated()).cast(),
        clock: clock,
      ),
      JourneyContextProvider(goals, orders: orders.loadAll, clock: clock),
      FinanceContextProvider(finance, clock: clock),
      TimelineContextProvider(finance, orders, goals, clock: clock),
      clock: clock,
    );
  }

  test('cross-screen consistency: context counts == repository counts after '
      'seeding (Home ⇔ domain screens can never disagree)', () async {
    await seeder.seed();
    final ctx = await buildContextService().load();

    expect(ctx.customers.total, (await customers.loadAll()).length);
    expect(ctx.inventory.productCount, (await products.loadAll()).length);
    expect(ctx.orders.total, (await orders.loadAll()).length);
    expect(ctx.journey.total, (await goals.loadAll()).length);
    expect(ctx.hasData, isTrue);

    // And the fixture sizes, for absolute clarity.
    expect(ctx.customers.total, kSampleCustomers.length);
    expect(ctx.inventory.productCount, kSampleProducts.length);
  });

  test('Opportunity e2e: persisted rows → Rule Engine → context slice — no '
      'screen-local list anywhere', () async {
    await seeder.seed();
    final engine = const OpportunityRuleEngine().generate(
      products: await products.loadAll(),
      customers: await customers.loadAll(),
      orders: await orders.loadAll(),
      goals: await goals.loadAll(),
      now: now,
    );
    // The July sample orders guarantee at least category momentum.
    expect(engine, isNotEmpty);
    for (final o in engine) {
      expect(o.id, startsWith('gen-'));
    }

    final ctx = await buildContextService().load();
    expect(ctx.opportunity.total, engine.length);
  });

  test('ACCEPTANCE: fresh → seed → create → update → delete samples → restart '
      '→ every slice verified', () async {
    // 1. Fresh install: nothing anywhere.
    var ctx = await buildContextService().load();
    expect(ctx.hasData, isFalse);

    // 2. Seed samples.
    await seeder.seed();
    ctx = await buildContextService().load();
    expect(ctx.customers.total, kSampleCustomers.length);

    // 3. User creates their own records (UUID-style ids).
    await customers.upsert(
      const Customer(
        id: 'uuid-user-c1',
        name: 'Khách Ruột',
        phone: '0901',
        location: 'HCM',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
      ),
    );
    await orders.upsert(
      CustomerOrder(
        id: 'uuid-user-o1',
        customerId: 'uuid-user-c1',
        orderNumber: 'DH-RUOT-1',
        date: DateTime(2026, 7, 22),
        status: OrderStatus.delivered,
        items: const [
          OrderItem(
            productName: 'Hàng thật',
            category: 'Home',
            quantity: 2,
            unitPrice: 250000,
          ),
        ],
      ),
    );
    ctx = await buildContextService().load();
    expect(ctx.customers.total, kSampleCustomers.length + 1);
    expect(ctx.orders.total, kSampleCustomerOrders.length + 1);

    // 4. User edits a sample product (allowed — ordinary rows).
    final sampleProduct = (await products.loadAll()).first;
    await products.upsert(sampleProduct.copyWith(quantity: 999));
    final edited = (await products.loadAll()).firstWhere(
      (p) => p.id == sampleProduct.id,
    );
    expect(edited.quantity, 999);

    // 5. Delete ALL samples — user data must survive untouched.
    await seeder.removeAll();
    ctx = await buildContextService().load();
    expect(ctx.customers.total, 1);
    expect(ctx.orders.total, 1);
    expect(ctx.inventory.productCount, 0);
    expect(ctx.journey.total, 0);
    // The user's revenue is still counted (billable order of 500k).
    expect(ctx.metrics.revenue, 500000);

    // 6. "Restart": a brand-new service graph over the same repositories
    //    (repos persist like the DB file) — identical reads.
    final afterRestart = await buildContextService().load();
    expect(afterRestart.customers.total, 1);
    expect(afterRestart.orders.total, 1);
    expect(afterRestart.metrics.revenue, 500000);
    expect(afterRestart.hasData, isTrue);
    expect(await seeder.hasSamples(), isFalse);
  });
}
