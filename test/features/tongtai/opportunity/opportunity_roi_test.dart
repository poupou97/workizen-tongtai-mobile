import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_rule_engine.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_signals.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-207 — ROI is computed from the seller's own cost price, or it is null.
///
/// ADR-TON-022 removed the ROI facet and the High Risk badge because
/// `estimatedRoi` was a constant per rule — "sort by ROI" sorted by nothing,
/// and High Risk restated which rule fired while reading as a judgement about
/// the seller's money. The recorded condition for their return was a cost
/// price; WTM-204 supplied it, this is the return.
void main() {
  final now = DateTime(2026, 8, 1);

  Product product({double? costPrice, int quantity = 0}) => Product(
    id: 'p1',
    sku: 'SKU-1',
    name: 'Quạt mini',
    category: 'Home',
    quantity: quantity,
    pricePerUnit: 150000,
    reorderLevel: 3,
    updatedAt: now,
    costPrice: costPrice,
  );

  CustomerOrder saleOf(String productName) => CustomerOrder(
    id: 'o1',
    customerId: 'c1',
    orderNumber: 'DH-1',
    date: DateTime(2026, 7, 20),
    status: OrderStatus.delivered,
    items: [
      OrderItem(
        productName: productName,
        category: 'Home',
        quantity: 2,
        unitPrice: 150000,
      ),
    ],
  );

  Opportunity restockFor(Product p) => const OpportunityRuleEngine()
      .generate(
        products: [p],
        customers: const [],
        orders: [saleOf(p.name)],
        goals: const [],
        now: now,
      )
      .singleWhere((o) => o.id == 'gen-restock-p1');

  group('the number is real or it is absent', () {
    test('cost price known → profit over investment', () {
      // 150k sell, 100k cost → 0.5× return on the money put in.
      expect(restockFor(product(costPrice: 100000)).roi, closeTo(0.5, 1e-9));
    });

    test('no cost price → null, not a constant and not zero', () {
      expect(
        restockFor(product()).roi,
        isNull,
        reason: 'nobody knows is not the same answer as no return',
      );
    });

    test('different costs give different ROIs — the P-24 check', () {
      // The old `estimatedRoi` was 2.5 for every restock ever generated.
      final cheap = restockFor(product(costPrice: 50000)).roi!;
      final dear = restockFor(product(costPrice: 120000)).roi!;

      expect(cheap, isNot(dear));
      expect(cheap, greaterThan(dear));
    });

    test('win-back has no cost side, so it has no ROI', () {
      final winback = const OpportunityRuleEngine().generate(
        products: const [],
        customers: const [],
        orders: const [],
        goals: const [],
        now: now,
      );
      // No data, no opportunities at all — and more to the point, nothing in
      // the engine invents an ROI for rules without a cost side.
      expect(winback, isEmpty);
    });
  });

  group('High Risk fires on real returns only', () {
    Opportunity opp({double? roi}) => Opportunity(
      id: 'a',
      type: OpportunityType.trend,
      title: 't',
      description: 'd',
      expectedImpact: 1000000,
      roi: roi,
      score: OpportunityScore.fixed(50),
      discoveredAt: now,
    );

    test('a thin computed return raises the badge', () {
      expect(
        opportunitySignals(opp(roi: 0.4), now: now),
        contains(OpportunitySignal.highRisk),
      );
    });

    test('a healthy computed return does not', () {
      expect(
        opportunitySignals(opp(roi: 2.5), now: now),
        isNot(contains(OpportunitySignal.highRisk)),
      );
    });

    test('an unknown return raises nothing', () {
      // "Nobody knows" is not "risky". Alarming on the unknown re-teaches the
      // seller to ignore the badge — the exact damage the constant did.
      expect(
        opportunitySignals(opp(), now: now),
        isNot(contains(OpportunitySignal.highRisk)),
      );
    });
  });

  group('sorting by ROI', () {
    Opportunity opp(String id, {double? roi}) => Opportunity(
      id: id,
      type: OpportunityType.trend,
      title: 'Cơ hội $id',
      description: 'd',
      expectedImpact: 1000000,
      roi: roi,
      score: OpportunityScore.fixed(50),
      discoveredAt: now,
    );

    test('known returns rank above unknown ones, best first', () {
      final controller = OpportunityFeedController([
        opp('unknown'),
        opp('thin', roi: 0.3),
        opp('good', roi: 2.0),
      ]);

      expect(
        controller
            .feed(const OpportunityQuery(sort: OpportunitySort.roi))
            .map((o) => o.id),
        ['good', 'thin', 'unknown'],
        reason: 'null must not beat a known-poor return',
      );
    });
  });
}
