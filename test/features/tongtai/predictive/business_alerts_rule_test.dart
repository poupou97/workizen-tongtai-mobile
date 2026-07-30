import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/cashflow_series.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/predictive/business_alerts_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';

/// WTM-157 — the Business Alerts Rule Twin.
///
/// Each capability input is built independently and defaults to a **healthy**
/// business, so a test that raises one alert proves that alert and nothing else.
///
/// Calendar: `now = 15/7/2026`, so the revenue window is the 12 **completed**
/// months Jul 2025…Jun 2026 and the default 3-month comparison is
/// Apr+May+Jun 2026 against Jan+Feb+Mar 2026.
void main() {
  final now = DateTime(2026, 7, 15);
  final recentMonths = [
    DateTime(2026, 4, 10),
    DateTime(2026, 5, 10),
    DateTime(2026, 6, 10),
  ];
  final previousMonths = [
    DateTime(2026, 1, 10),
    DateTime(2026, 2, 10),
    DateTime(2026, 3, 10),
  ];

  var nextOrderId = 0;
  List<CustomerOrder> monthOrders(
    DateTime day, {
    required int count,
    required double each,
    String customerId = 'c-1',
  }) => [
    for (var i = 0; i < count; i++)
      CustomerOrder(
        id: 'o${nextOrderId += 1}',
        customerId: customerId,
        orderNumber: 'DH-$nextOrderId',
        date: day,
        status: OrderStatus.delivered,
        items: [
          OrderItem(
            productName: 'Khăn lụa',
            category: 'Fashion',
            quantity: 1,
            unitPrice: each,
          ),
        ],
      ),
  ];

  /// Revenue context with [recentEach]/[previousEach] đồng per order and
  /// [recentCount]/[previousCount] orders in each month of the two windows.
  RevenueCapabilityContext revenueContext({
    double recentEach = 10000000,
    double previousEach = 10000000,
    int recentCount = 4,
    int previousCount = 4,
  }) {
    nextOrderId = 0;
    return RevenueCapabilityContext.from(
      orders: [
        for (final month in previousMonths)
          ...monthOrders(month, count: previousCount, each: previousEach),
        for (final month in recentMonths)
          ...monthOrders(month, count: recentCount, each: recentEach),
      ],
      now: now,
    );
  }

  Customer customer(String id) => Customer(
    id: id,
    name: 'Nguyễn Thị Mai',
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
    email: 'mai@example.com',
  );

  CustomerOrder customerOrder(String id, DateTime date, double total) =>
      CustomerOrder(
        id: 'co-$id-${date.millisecondsSinceEpoch}',
        customerId: id,
        orderNumber: 'DH-$id',
        date: date,
        status: OrderStatus.delivered,
        items: [
          OrderItem(
            productName: 'Khăn lụa',
            category: 'Fashion',
            quantity: 1,
            unitPrice: total,
          ),
        ],
      );

  /// A directory of [active] recently-buying customers plus [churned] customers
  /// who last bought 300 days ago (well past every churn window).
  CustomerCapabilityContext customerContext({int active = 5, int churned = 0}) {
    final ids = [
      for (var i = 0; i < active; i++) 'c-active-$i',
      for (var i = 0; i < churned; i++) 'c-churned-$i',
    ];
    return CustomerCapabilityContext.from(
      customers: [for (final id in ids) customer(id)],
      orders: [
        for (var i = 0; i < active; i++)
          customerOrder(
            'c-active-$i',
            now.subtract(const Duration(days: 5)),
            1000000,
          ),
        for (var i = 0; i < churned; i++)
          customerOrder(
            'c-churned-$i',
            now.subtract(const Duration(days: 300)),
            100000,
          ),
      ],
      now: now,
    );
  }

  Product product(String id, {int quantity = 50, int reorderLevel = 10}) =>
      Product(
        id: id,
        sku: 'SKU-$id',
        name: 'Quạt mini $id',
        category: 'Electronics',
        quantity: quantity,
        pricePerUnit: 250000,
        reorderLevel: reorderLevel,
        updatedAt: now,
      );

  FinanceTransaction txn(
    String id,
    DateTime date,
    double amount, {
    required TransactionType type,
  }) => FinanceTransaction(
    id: id,
    type: type,
    category: type == TransactionType.income ? 'Bán hàng' : 'Nhập hàng',
    amount: amount,
    date: date,
  );

  /// Six completed months (Jan…Jun 2026); the first [deficitMonths] of them run
  /// [deficitAmount] in the red, the rest earn a 5M profit.
  CashflowSeries cashflow({int deficitMonths = 0, double deficit = 2000000}) {
    final transactions = <FinanceTransaction>[];
    for (var month = 1; month <= 6; month++) {
      final date = DateTime(2026, month, 10);
      final isDeficit = month <= deficitMonths;
      transactions
        ..add(txn('in-$month', date, 10000000, type: TransactionType.income))
        ..add(
          txn(
            'out-$month',
            date,
            isDeficit ? 10000000 + deficit : 5000000,
            type: TransactionType.expense,
          ),
        );
    }
    return CashflowSeries.fromTransactions(transactions, now: now, months: 6);
  }

  RuleTwinResult<List<BusinessAlert>> evaluate({
    RevenueCapabilityContext? revenue,
    CustomerCapabilityContext? customers,
    CashflowSeries? cashflowSeries,
    List<Product>? products,
  }) => const BusinessAlertsRule().evaluate(
    revenue: revenue ?? revenueContext(),
    customers: customers ?? customerContext(),
    cashflow: cashflowSeries ?? cashflow(),
    products: products ?? [product('p1'), product('p2')],
  );

  BusinessAlert alertOf(
    RuleTwinResult<List<BusinessAlert>> result,
    BusinessAlertKind kind,
  ) {
    final match = result.result!.where((a) => a.kind == kind);
    expect(match, hasLength(1), reason: 'expected exactly one ${kind.name}');
    return match.first;
  }

  group('healthy business', () {
    test(
      'sufficient with an EMPTY alert list — "nothing wrong" is an answer',
      () {
        final result = evaluate();

        expect(result.sufficiency, DataSufficiency.sufficient);
        expect(result.sufficiency.canAnswer, isTrue);
        expect(result.hasAnswer, isTrue);
        expect(result.result, isEmpty);
        expect(result.confidence, ForecastConfidence.high);
        expect(result.version, 'business-alerts/1');
        expect(result.generatedAt, now);
      },
    );

    test('still explains itself: flat revenue, partial month excluded', () {
      final result = evaluate();

      expect(result.reasonCodes, isNotEmpty);
      expect(result.reasonCodes, contains(ReasonCode.revenueFlat));
      expect(result.reasonCodes, contains(ReasonCode.partialMonthExcluded));
      expect(result.reasonCodes, isNot(contains(ReasonCode.notEnoughHistory)));
    });

    test('growth is reported as growth, not silence', () {
      final result = evaluate(revenue: revenueContext(recentEach: 15000000));

      expect(result.result, isEmpty);
      expect(result.reasonCodes, contains(ReasonCode.revenueGrowing));
    });
  });

  group('revenue and orders', () {
    test(
      'a 40% revenue drop raises revenueDrop with revenueDropVsPrevious',
      () {
        final result = evaluate(revenue: revenueContext(recentEach: 6000000));

        final alert = alertOf(result, BusinessAlertKind.revenueDrop);
        expect(alert.reasonCodes, contains(ReasonCode.revenueDropVsPrevious));
        expect(alert.severity, BusinessAlertSeverity.critical);
        expect(alert.change, closeTo(-0.4, 1e-9));
        expect(alert.metricValue, 72000000); // 3 × 4 orders × 6M
        expect(alert.comparisonValue, 120000000); // 3 × 4 orders × 10M
        expect(alert.affectedCount, 3); // months per comparison window
        // Order count did not move, so the orders alert must stay silent.
        expect(
          result.result!.map((a) => a.kind),
          isNot(contains(BusinessAlertKind.ordersDrop)),
        );
        expect(result.reasonCodes, contains(ReasonCode.revenueDropVsPrevious));
      },
    );

    test('a 15% drop is a warning; a 5% wobble is not an alert at all', () {
      final warning = evaluate(revenue: revenueContext(recentEach: 8500000));
      expect(
        alertOf(warning, BusinessAlertKind.revenueDrop).severity,
        BusinessAlertSeverity.warning,
      );

      final noise = evaluate(revenue: revenueContext(recentEach: 9500000));
      expect(noise.result, isEmpty);
      expect(noise.reasonCodes, contains(ReasonCode.revenueFlat));
    });

    test('fewer orders raise ordersDrop with ordersDropVsPrevious', () {
      // 4 → 2 orders per month: −50% orders and −50% revenue.
      final result = evaluate(revenue: revenueContext(recentCount: 2));

      final alert = alertOf(result, BusinessAlertKind.ordersDrop);
      expect(alert.reasonCodes, [ReasonCode.ordersDropVsPrevious]);
      expect(alert.severity, BusinessAlertSeverity.critical);
      expect(alert.metricValue, 6);
      expect(alert.comparisonValue, 12);
      expect(
        result.result!.map((a) => a.kind),
        contains(BusinessAlertKind.revenueDrop),
      );
    });
  });

  group('inventory', () {
    test('stock below reorder raises the inventory alert', () {
      final result = evaluate(
        products: [
          product('p1'),
          product('p-low', quantity: 5, reorderLevel: 10),
        ],
      );

      final alert = alertOf(result, BusinessAlertKind.stockBelowReorder);
      expect(alert.reasonCodes, [ReasonCode.stockBelowReorder]);
      expect(alert.severity, BusinessAlertSeverity.warning);
      expect(alert.affectedCount, 1);
      expect(alert.metricValue, 1);
      expect(alert.comparisonValue, 2);
    });

    test('an out-of-stock product makes it critical', () {
      final result = evaluate(
        products: [
          product('p-low', quantity: 5, reorderLevel: 10),
          product('p-out', quantity: 0, reorderLevel: 10),
        ],
      );

      final alert = alertOf(result, BusinessAlertKind.stockBelowReorder);
      expect(alert.severity, BusinessAlertSeverity.critical);
      expect(alert.affectedCount, 2);
    });

    test('a healthy catalog raises nothing', () {
      expect(
        evaluate(products: [product('p1'), product('p2')]).result,
        isEmpty,
      );
    });
  });

  group('cashflow', () {
    test('deficit months raise negativeCashflow', () {
      final result = evaluate(cashflowSeries: cashflow(deficitMonths: 4));

      final alert = alertOf(result, BusinessAlertKind.negativeCashflow);
      expect(alert.reasonCodes, [ReasonCode.negativeCashflow]);
      expect(alert.affectedCount, 4);
      expect(alert.metricValue, 4);
      expect(alert.comparisonValue, 6);
    });

    test('a window that burned cash overall is critical', () {
      // 6 deficit months of −8M each: the whole window is under water.
      final result = evaluate(
        cashflowSeries: cashflow(deficitMonths: 6, deficit: 8000000),
      );

      expect(
        alertOf(result, BusinessAlertKind.negativeCashflow).severity,
        BusinessAlertSeverity.critical,
      );
    });

    test('one bad month inside a profitable window is only info', () {
      final result = evaluate(cashflowSeries: cashflow(deficitMonths: 1));

      expect(
        alertOf(result, BusinessAlertKind.negativeCashflow).severity,
        BusinessAlertSeverity.info,
      );
    });

    test('a profitable window raises nothing', () {
      expect(evaluate(cashflowSeries: cashflow()).result, isEmpty);
    });
  });

  group('customer risk', () {
    test('a lapsed share past the threshold raises customerRisk', () {
      // 1 churned of 4 = 25% → warning band.
      final result = evaluate(
        customers: customerContext(active: 3, churned: 1),
      );

      final alert = alertOf(result, BusinessAlertKind.customerRisk);
      expect(alert.severity, BusinessAlertSeverity.warning);
      expect(alert.reasonCodes, contains(ReasonCode.inactiveBeyondChurnWindow));
      expect(alert.affectedCount, 1);
      expect(alert.share, closeTo(0.25, 1e-9));
    });

    test('half the book lapsed is critical', () {
      final result = evaluate(
        customers: customerContext(active: 2, churned: 2),
      );

      expect(
        alertOf(result, BusinessAlertKind.customerRisk).severity,
        BusinessAlertSeverity.critical,
      );
    });

    test('a lapsed share below the threshold stays silent', () {
      // 1 churned of 10 = 10%.
      expect(
        evaluate(customers: customerContext(active: 9, churned: 1)).result,
        isEmpty,
      );
    });
  });

  group('ordering', () {
    test('alerts are ordered most severe first, then by kind', () {
      final result = evaluate(
        revenue: revenueContext(recentEach: 6000000), // critical
        customers: customerContext(active: 3, churned: 1), // warning
        cashflowSeries: cashflow(deficitMonths: 1), // info
        products: [product('p-out', quantity: 0, reorderLevel: 10)], // critical
      );

      expect(result.result!.map((a) => a.kind), [
        BusinessAlertKind.revenueDrop, // critical, kind index 0
        BusinessAlertKind.stockBelowReorder, // critical, kind index 2
        BusinessAlertKind.customerRisk, // warning
        BusinessAlertKind.negativeCashflow, // info
      ]);
      for (var i = 1; i < result.result!.length; i++) {
        expect(
          result.result![i - 1].severity.index,
          greaterThanOrEqualTo(result.result![i].severity.index),
        );
      }
    });
  });

  group('sufficiency', () {
    test(
      'nothing readable at all → insufficient, never a false "all clear"',
      () {
        final result = const BusinessAlertsRule().evaluate(
          revenue: RevenueCapabilityContext.from(
            orders: const <CustomerOrder>[],
            now: now,
          ),
          customers: CustomerCapabilityContext.from(
            customers: const <Customer>[],
            orders: const <CustomerOrder>[],
            now: now,
          ),
        );

        expect(result.sufficiency, DataSufficiency.insufficient);
        expect(result.confidence, ForecastConfidence.none);
        expect(result.result, isNull);
        expect(result.reasonCodes, contains(ReasonCode.notEnoughHistory));
        expect(result.reasonCodes, contains(ReasonCode.noCustomers));
        expect(result.reasonCodes, contains(ReasonCode.noRevenueYet));
      },
    );

    test('no revenue comparison but other signals → partial + low', () {
      final result = const BusinessAlertsRule().evaluate(
        revenue: RevenueCapabilityContext.from(
          orders: const <CustomerOrder>[],
          now: now,
        ),
        customers: customerContext(active: 3, churned: 1),
        products: [product('p-out', quantity: 0, reorderLevel: 10)],
      );

      expect(result.sufficiency, DataSufficiency.partial);
      expect(result.confidence, ForecastConfidence.low);
      expect(result.reasonCodes, contains(ReasonCode.notEnoughHistory));
      // The alerts it CAN judge are still raised.
      expect(
        result.result!.map((a) => a.kind),
        containsAll(const [
          BusinessAlertKind.stockBelowReorder,
          BusinessAlertKind.customerRisk,
        ]),
      );
    });

    test('fewer readable signals lower the confidence to medium', () {
      final result = const BusinessAlertsRule().evaluate(
        revenue: revenueContext(),
        customers: CustomerCapabilityContext.from(
          customers: const <Customer>[],
          orders: const <CustomerOrder>[],
          now: now,
        ),
      );

      expect(result.sufficiency, DataSufficiency.sufficient);
      expect(result.confidence, ForecastConfidence.medium);
      expect(result.result, isEmpty);
    });
  });

  group('determinism', () {
    test('two runs over the same inputs produce identical alerts', () {
      final first = evaluate(
        revenue: revenueContext(recentEach: 6000000),
        customers: customerContext(active: 3, churned: 1),
        cashflowSeries: cashflow(deficitMonths: 2),
        products: [product('p-out', quantity: 0, reorderLevel: 10)],
      );
      final second = evaluate(
        revenue: revenueContext(recentEach: 6000000),
        customers: customerContext(active: 3, churned: 1),
        cashflowSeries: cashflow(deficitMonths: 2),
        products: [product('p-out', quantity: 0, reorderLevel: 10)],
      );

      expect(first.result, second.result);
      expect(first.reasonCodes, second.reasonCodes);
      expect(first.confidence, second.confidence);
      expect(first.provenance, second.provenance);
    });

    test('twin-level reason codes carry no duplicates', () {
      final result = evaluate(
        revenue: revenueContext(recentEach: 6000000, recentCount: 2),
        customers: customerContext(active: 3, churned: 1),
        cashflowSeries: cashflow(deficitMonths: 2),
      );

      expect(result.reasonCodes.toSet(), hasLength(result.reasonCodes.length));
      expect(result.provenance, startsWith('[business-alerts/1]'));
    });
  });
}
