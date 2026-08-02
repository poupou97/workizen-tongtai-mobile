import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_for.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';

/// WTM-225 — the fifth beat of the Business Loop: *"biết bước tiếp theo"*.
///
/// The striking part of this gap was that the answer already existed. The Rule
/// Engine generates `gen-restock-<productId>` and `gen-winback-<customerId>`;
/// what was missing was the link from the place the seller sees the problem
/// (Inventory alerts, the customer list) to the place the product already
/// answered it.
void main() {
  Opportunity opp(String id) => Opportunity(
    id: id,
    type: OpportunityType.trend,
    title: id,
    description: 'd',
    expectedImpact: 1000000,
    score: OpportunityScore.fixed(50),
    discoveredAt: DateTime(2026, 8, 2),
  );

  final generated = [
    opp('gen-restock-p1'),
    opp('gen-winback-c1'),
    opp('gen-momentum-Home'),
  ];

  test('finds the opportunity the engine made for this product / customer', () {
    expect(generated.restockFor('p1')?.id, 'gen-restock-p1');
    expect(generated.winBackFor('c1')?.id, 'gen-winback-c1');
  });

  test('nothing generated ⇒ null, so no button is offered', () {
    // A product that is low but never sells has no restock case to make, and a
    // button to an opportunity that does not exist is the WTM-169 defect.
    expect(generated.restockFor('p-unsold'), isNull);
    expect(generated.winBackFor('c-active'), isNull);
    expect(const <Opportunity>[].restockFor('p1'), isNull);
  });

  test('the two lookups do not cross over', () {
    // `gen-winback-c1` must never answer a restock question just because the
    // suffix matches — the prefix IS the kind of work being proposed.
    expect(generated.restockFor('c1'), isNull);
    expect(generated.winBackFor('p1'), isNull);
  });
}
