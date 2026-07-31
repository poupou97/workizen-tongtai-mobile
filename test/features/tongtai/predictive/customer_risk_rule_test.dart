import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';

/// WTM-156 — the Customer Risk Rule Twin.
///
/// The directory is hand-built so every score is checkable on a calendar and by
/// hand against the documented weights
/// (`0.60 × lateness + 0.25 × loyaltyRisk + 0.15 × valueWeight`).
///
/// Every fixture customer carries the SAME real-looking name/phone/email — if a
/// single one of those strings ever appears anywhere in the assessment, the
/// privacy test fails loudly (D-7 / ADR-TON-005 red-line).
void main() {
  final now = DateTime(2026, 7, 15);

  const fixtureName = 'Nguyễn Thị Mai';
  const fixturePhone = '+84912345678';
  const fixtureEmail = 'mai@example.com';
  const fixtureLocation = 'Hà Nội';

  Customer customer(String id) => Customer(
    id: id,
    name: fixtureName,
    phone: fixturePhone,
    location: fixtureLocation,
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
    email: fixtureEmail,
  );

  var nextId = 0;
  CustomerOrder order(String customerId, DateTime date, double total) {
    nextId += 1;
    return CustomerOrder(
      id: 'o$nextId',
      customerId: customerId,
      orderNumber: 'DH-$nextId',
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
  }

  // ── The directory ────────────────────────────────────────────────────────
  //
  //  id                 orders                        recency cadence ratio LTV
  //  c-loyal            15/4, 15/5, 15/6, 5/7 2026      10 d   30 d   0.33  2.0M
  //  c-late-1x5         1/4, 1/5, 31/5 2026             45 d   30 d   1.50  0.9M
  //  c-late-3x          15/2, 17/3, 16/4 2026           90 d   30 d   3.00  0.9M
  //  c-whale-churned    1/1, 1/2 2026                  164 d   31 d   5.29 16.0M
  //  c-one-order        20/6/2026 (single)              25 d    —     0.83  0.25M
  //  c-never            none                             —      —      —      0
  //
  // c-late-1x5 and c-late-3x are deliberately identical in spend and order
  // count, so ONLY lateness separates them.
  const ids = [
    'c-loyal',
    'c-late-1x5',
    'c-late-3x',
    'c-whale-churned',
    'c-one-order',
    'c-never',
  ];

  List<CustomerOrder> fixtureOrders() {
    nextId = 0;
    return [
      order('c-loyal', DateTime(2026, 4, 15), 500000),
      order('c-loyal', DateTime(2026, 5, 15), 500000),
      order('c-loyal', DateTime(2026, 6, 15), 500000),
      order('c-loyal', DateTime(2026, 7, 5), 500000),
      order('c-late-1x5', DateTime(2026, 4), 300000),
      order('c-late-1x5', DateTime(2026, 5), 300000),
      order('c-late-1x5', DateTime(2026, 5, 31), 300000),
      order('c-late-3x', DateTime(2026, 2, 15), 300000),
      order('c-late-3x', DateTime(2026, 3, 17), 300000),
      order('c-late-3x', DateTime(2026, 4, 16), 300000),
      order('c-whale-churned', DateTime(2026), 8000000),
      order('c-whale-churned', DateTime(2026, 2), 8000000),
      order('c-one-order', DateTime(2026, 6, 20), 250000),
    ];
  }

  CustomerCapabilityContext contextOf({
    Iterable<String> customerIds = ids,
    List<CustomerOrder>? orders,
  }) => CustomerCapabilityContext.from(
    customers: [for (final id in customerIds) customer(id)],
    orders: orders ?? fixtureOrders(),
    now: now,
  );

  RuleTwinResult<CustomerRiskAssessment> assess([
    CustomerCapabilityContext? ctx,
  ]) => const CustomerRiskRule().assess(ctx ?? contextOf());

  CustomerRiskEntry entry(String id) {
    final found = assess().result!.entryFor(id);
    expect(found, isNotNull, reason: 'missing entry for $id');
    return found!;
  }

  group('sufficiency', () {
    test('no customers at all → insufficient + noCustomers, no result', () {
      final result = assess(contextOf(customerIds: const [], orders: const []));

      expect(result.sufficiency, DataSufficiency.insufficient);
      expect(result.confidence, ForecastConfidence.none);
      expect(result.result, isNull);
      expect(result.hasAnswer, isFalse);
      expect(result.reasonCodes, [ReasonCode.noCustomers]);
      expect(result.version, 'customer-risk/1');
      expect(result.generatedAt, now);
    });

    test(
      'customers exist but none ever bought → partial + low, still lists them',
      () {
        final result = assess(contextOf(orders: const []));

        expect(result.sufficiency, DataSufficiency.partial);
        expect(result.confidence, ForecastConfidence.low);
        expect(result.reasonCodes, contains(ReasonCode.noRevenueYet));
        expect(result.result!.entries, hasLength(ids.length));
        expect(result.result!.entries.map((e) => e.stage).toSet(), {
          CustomerLifecycleStage.neverPurchased,
        });
      },
    );

    test('a returning majority earns high confidence; otherwise medium', () {
      // 4 of 6 fixture customers have ≥ 2 orders.
      expect(assess().confidence, ForecastConfidence.high);
      expect(assess().sufficiency, DataSufficiency.sufficient);

      // Drop two repeat buyers → 2 of 4 returning, no strict majority.
      final thin = contextOf(
        customerIds: const [
          'c-late-1x5',
          'c-late-3x',
          'c-one-order',
          'c-never',
        ],
      );
      expect(assess(thin).confidence, ForecastConfidence.medium);
    });
  });

  group('scoring', () {
    test('a loyal recent buyer scores low and carries recentPurchase', () {
      final loyal = entry('c-loyal');

      expect(loyal.stage, CustomerLifecycleStage.active);
      expect(loyal.recencyDays, 10);
      expect(loyal.lifetimeOrders, 4);
      expect(loyal.reasonCodes, [ReasonCode.recentPurchase]);
      expect(loyal.winBackCandidate, isFalse);
      // 0.60×0.0667 + 0.25×0 + 0.15×1.0 (top spend band) = 19.0 / 100.
      expect(loyal.riskScore, closeTo(19, 0.1));
      expect(loyal.riskScore, lessThan(25));
      // The lowest score in the whole directory.
      expect(
        loyal.riskScore,
        assess().result!.entries
            .map((e) => e.riskScore)
            .reduce((a, b) => a < b ? a : b),
      );
    });

    test('silence past 3× the own cadence outranks silence past 1.5×', () {
      final late3x = entry('c-late-3x');
      final late15x = entry('c-late-1x5');

      // Same spend, same order count — only lateness differs.
      expect(late3x.lifetimeValue, late15x.lifetimeValue);
      expect(late3x.lifetimeOrders, late15x.lifetimeOrders);
      expect(late3x.recencyDays, 90);
      expect(late15x.recencyDays, 45);

      expect(late3x.stage, CustomerLifecycleStage.atRisk);
      expect(late15x.stage, CustomerLifecycleStage.cooling);
      expect(late3x.riskScore, greaterThan(late15x.riskScore));
      expect(late3x.reasonCodes, contains(ReasonCode.purchaseGapExceeded));
      expect(late15x.reasonCodes, contains(ReasonCode.purchaseGapExceeded));
      // Slowed to 3 orders where their own 30-day rhythm predicted 5.
      expect(late3x.reasonCodes, contains(ReasonCode.frequencyDropping));
      expect(
        late15x.reasonCodes,
        isNot(contains(ReasonCode.frequencyDropping)),
      );
    });

    test(
      'a high-lifetime-value churned customer is highValueAtRisk + win-back',
      () {
        final whale = entry('c-whale-churned');

        expect(whale.stage, CustomerLifecycleStage.churned);
        expect(whale.lifetimeValue, 16000000);
        expect(whale.winBackCandidate, isTrue);
        expect(whale.reasonCodes, [
          ReasonCode.inactiveBeyondChurnWindow,
          ReasonCode.highValueAtRisk,
          ReasonCode.frequencyDropping,
        ]);
        expect(whale.isLapsed, isTrue);
      },
    );

    test('a one-order customer carries singlePurchaseOnly', () {
      final once = entry('c-one-order');

      expect(once.lifetimeOrders, 1);
      expect(once.reasonCodes, contains(ReasonCode.singlePurchaseOnly));
      // Still inside the fixed 30-day active window.
      expect(once.stage, CustomerLifecycleStage.active);
      expect(once.reasonCodes.first, ReasonCode.recentPurchase);
      // Never proved they come back → outscores the loyal repeat buyer.
      expect(once.riskScore, greaterThan(entry('c-loyal').riskScore));
    });

    test('a never-purchased contact is not churned and claims no reason', () {
      final never = entry('c-never');

      expect(never.stage, CustomerLifecycleStage.neverPurchased);
      expect(never.recencyDays, isNull);
      expect(never.lifetimeOrders, 0);
      expect(never.lifetimeValue, 0);
      expect(never.winBackCandidate, isFalse);
      // No ReasonCode describes "in the directory, never bought" — the stage
      // carries that fact instead of a fabricated code.
      expect(never.reasonCodes, isEmpty);
    });

    test('every score stays inside 0..100', () {
      for (final e in assess().result!.entries) {
        expect(e.riskScore, inInclusiveRange(0, 100));
      }
    });
  });

  group('assessment', () {
    test('entries are ordered highest risk first', () {
      final entries = assess().result!.entries;

      expect(entries, hasLength(ids.length));
      expect(entries.first.customerId, 'c-whale-churned');
      expect(entries.last.customerId, 'c-loyal');
      for (var i = 1; i < entries.length; i++) {
        expect(
          entries[i - 1].riskScore,
          greaterThanOrEqualTo(entries[i].riskScore),
          reason: 'entry $i broke the descending risk order',
        );
      }
      // The full ranking, hand-computed from the documented weights.
      expect(entries.map((e) => e.customerId).take(3), [
        'c-whale-churned',
        'c-late-3x',
        'c-late-1x5',
      ]);
    });

    test('stage counts and lapsed/win-back counts agree with the entries', () {
      final assessment = assess().result!;

      expect(assessment.totalCustomers, ids.length);
      expect(assessment.stageCounts.values.reduce((a, b) => a + b), ids.length);
      expect(assessment.stage(CustomerLifecycleStage.active), 2);
      expect(assessment.stage(CustomerLifecycleStage.cooling), 1);
      expect(assessment.atRiskCount, 1);
      expect(assessment.churnedCount, 1);
      expect(assessment.stage(CustomerLifecycleStage.neverPurchased), 1);
      expect(assessment.lapsedCount, 2);
      // c-late-3x (3 lifetime orders) + c-whale-churned (top spend band).
      expect(assessment.winBackCount, 2);
      expect(
        assessment.entries.where((e) => e.winBackCandidate).length,
        assessment.winBackCount,
      );
      expect(assessment.top(2).map((e) => e.customerId), [
        'c-whale-churned',
        'c-late-3x',
      ]);
    });

    test('twin-level reason codes are the distinct entry reasons, ranked', () {
      final result = assess();

      expect(result.reasonCodes, [
        ReasonCode.inactiveBeyondChurnWindow,
        ReasonCode.highValueAtRisk,
        ReasonCode.purchaseGapExceeded,
        ReasonCode.frequencyDropping,
        ReasonCode.singlePurchaseOnly,
        ReasonCode.recentPurchase,
      ]);
      expect(result.reasonCodes, isNot(contains(ReasonCode.noCustomers)));
    });
  });

  group('privacy — the twin carries ids only', () {
    test('no customer name, phone, email or address appears anywhere', () {
      final result = assess();
      final assessment = result.result!;

      final dump = <String>[
        result.provenance,
        result.toString(),
        assessment.toString(),
        for (final e in assessment.entries) e.toString(),
        for (final e in assessment.entries) ...[
          e.customerId,
          e.stage.name,
          '${e.riskScore}',
          '${e.lifetimeValue}',
          e.reasonCodes.map((r) => r.code).join(','),
        ],
      ].join('\n');

      expect(dump, isNot(contains(fixtureName)));
      expect(dump, isNot(contains(fixturePhone)));
      expect(dump, isNot(contains(fixtureEmail)));
      expect(dump, isNot(contains(fixtureLocation)));
      // Sanity: the ids ARE there, so the assertion above is not vacuous.
      for (final id in ids) {
        expect(dump, contains(id));
      }
    });

    test('the identifying field is the customer id, verbatim', () {
      expect(
        assess().result!.entries.map((e) => e.customerId).toSet(),
        ids.toSet(),
      );
    });
  });

  group('determinism', () {
    test('two runs over the same data produce identical assessments', () {
      final first = assess(contextOf());
      final second = assess(contextOf());

      expect(first.result!.entries, second.result!.entries);
      expect(first.reasonCodes, second.reasonCodes);
      expect(first.confidence, second.confidence);
      expect(first.provenance, second.provenance);
    });

    test('directory row order does not change the ranking or the reasons', () {
      final forward = assess(contextOf());
      final reversed = assess(
        contextOf(customerIds: ids.reversed.toList(growable: false)),
      );

      expect(
        reversed.result!.entries.map((e) => e.customerId),
        forward.result!.entries.map((e) => e.customerId),
      );
      expect(reversed.reasonCodes, forward.reasonCodes);
    });
  });
}
