import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_rule_engine.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-139 — the Opportunity Rule Engine generates real opportunities from
/// business data. Deterministic; empty business → nothing; AI never replaces it.
void main() {
  const engine = OpportunityRuleEngine();
  final now = DateTime(2026, 7, 29);

  CustomerOrder order(
    String id, {
    required DateTime date,
    String customerId = 'c1',
    String product = 'Quạt mini',
    String category = 'Home',
    double amount = 500000,
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: 'DH-$id',
    date: date,
    status: status,
    items: [
      OrderItem(
        productName: product,
        category: category,
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  Product product(String id, String name, {int qty = 0, int reorder = 3}) =>
      Product(
        id: id,
        sku: 'SKU-$id',
        name: name,
        category: 'Home',
        quantity: qty,
        pricePerUnit: 100000,
        reorderLevel: reorder,
        updatedAt: DateTime(2026, 7, 1),
      );

  Customer customer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '',
    location: '',
    orderCount: 2,
    totalSpent: 1000000,
    lastPurchaseDate: null,
  );

  test('an empty business generates nothing (User Data First)', () {
    final result = engine.generate(
      products: [],
      customers: [],
      orders: [],
      goals: [],
      now: now,
    );
    expect(result, isEmpty);
  });

  test('restock: out-of-stock product WITH sales → strong opportunity', () {
    final result = engine.generate(
      products: [product('p1', 'Quạt mini', qty: 0)],
      customers: [],
      orders: [order('o1', date: DateTime(2026, 7, 10), amount: 800000)],
      goals: [],
      now: now,
    );
    final restock = result.singleWhere((o) => o.id == 'gen-restock-p1');
    expect(restock.title, contains('đã hết hàng'));
    expect(restock.expectedImpact, 800000); // recent revenue of that product
    expect(restock.aiScore, 85);
    // A stocked product or one with no sales generates nothing.
    expect(
      engine
          .generate(
            products: [product('p2', 'Khác', qty: 50)],
            customers: [],
            orders: [order('o1', date: DateTime(2026, 7, 10))],
            goals: [],
            now: now,
          )
          .where((o) => o.id.startsWith('gen-restock')),
      isEmpty,
    );
  });

  test('win-back: lapsed repeat customer → AOV-sized opportunity', () {
    final result = engine.generate(
      products: [],
      customers: [customer('c1', 'Thu Hà')],
      orders: [
        order('a', date: DateTime(2026, 5, 1), amount: 400000),
        order('b', date: DateTime(2026, 6, 10), amount: 600000),
      ],
      goals: [],
      now: now, // last order Jun 10 → >30 days quiet
    );
    final winback = result.singleWhere((o) => o.id == 'gen-winback-c1');
    expect(winback.title, contains('Thu Hà'));
    expect(winback.expectedImpact, 500000); // AOV of 2 orders

    // A recently-active customer generates nothing.
    final active = engine.generate(
      products: [],
      customers: [customer('c1', 'Thu Hà')],
      orders: [
        order('a', date: DateTime(2026, 7, 20), amount: 400000),
        order('b', date: DateTime(2026, 6, 10), amount: 600000),
      ],
      goals: [],
      now: now,
    );
    expect(active.where((o) => o.id.startsWith('gen-winback')), isEmpty);
  });

  test('goal catch-up: behind revenue goal → gap-sized opportunity', () {
    final goal = BusinessGoal(
      id: 'g1',
      name: 'Đạt 100 triệu quý 3',
      type: GoalType.revenue,
      targetAmount: 100000000,
      achievedAmount: 0, // ignored — derived from orders
      growthTarget: 0,
      growthAchieved: 0,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 9, 30),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );
    // Only 1M booked at ~31% elapsed → far behind pace.
    final result = engine.generate(
      products: [],
      customers: [],
      orders: [order('o1', date: DateTime(2026, 7, 5), amount: 1000000)],
      goals: [goal],
      now: now,
    );
    final catchUp = result.singleWhere((o) => o.id == 'gen-goal-g1');
    expect(catchUp.expectedImpact, greaterThan(0));
    expect(catchUp.aiScore, 75);
    expect(catchUp.description, contains('chậm'));
  });

  test('category momentum: top recent category with ≥2 orders', () {
    final result = engine.generate(
      products: [],
      customers: [],
      orders: [
        order(
          'a',
          date: DateTime(2026, 7, 5),
          category: 'Home',
          amount: 900000,
        ),
        order(
          'b',
          date: DateTime(2026, 7, 10),
          category: 'Fashion',
          amount: 300000,
        ),
      ],
      goals: [],
      now: now,
    );
    final momentum = result.singleWhere((o) => o.id.startsWith('gen-momentum'));
    expect(momentum.id, 'gen-momentum-Home');
    expect(momentum.expectedImpact, 900000);
  });

  test('deterministic + sorted strongest first + cancelled excluded', () {
    List<dynamic> run() => engine.generate(
      products: [product('p1', 'Quạt mini', qty: 0)],
      customers: [],
      orders: [
        order('o1', date: DateTime(2026, 7, 10), amount: 800000),
        order(
          'void',
          date: DateTime(2026, 7, 11),
          amount: 9999999,
          status: OrderStatus.cancelled,
        ),
      ],
      goals: [],
      now: now,
    );
    final a = run();
    final b = run();
    expect(a.map((o) => o.id), b.map((o) => o.id)); // deterministic
    // Restock (85) outranks momentum (60) — strongest first.
    expect(a.first.id, 'gen-restock-p1');
    // Cancelled order's 9.99M never appears in any impact.
    expect(a.every((o) => o.expectedImpact != 9999999), isTrue);
  });
}
