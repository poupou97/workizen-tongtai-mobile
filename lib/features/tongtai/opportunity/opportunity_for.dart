import 'opportunity.dart';

/// Finds the opportunity the Rule Engine already generated for a product or a
/// customer (WTM-225).
///
/// The Business Loop's fifth beat — *"biết bước tiếp theo"* — was missing from
/// Inventory and Consumer, and the striking part is that the answer already
/// existed: the engine produces `gen-restock-<productId>` for a product that is
/// running low while selling, and `gen-winback-<customerId>` for a regular who
/// has gone quiet. What was missing was the **link** between the place the
/// seller sees the problem and the place the product already answered it.
///
/// Lookup by the engine's own id convention, deliberately: an opportunity
/// carrying a `productId` field would be a second copy of a fact the id already
/// states, and the two would drift the first time one of them was written by
/// hand (the defect family WTM-196/200/201/205 removed).
///
/// Returns `null` when the engine produced nothing — a product that is low but
/// never sells has no restock case to make, and offering a button to an
/// opportunity that does not exist is the WTM-169 defect.
extension TongtaiOpportunityLookup on Iterable<Opportunity> {
  Opportunity? restockFor(String productId) => _byId('gen-restock-$productId');

  Opportunity? winBackFor(String customerId) =>
      _byId('gen-winback-$customerId');

  Opportunity? _byId(String id) {
    for (final o in this) {
      if (o.id == id) return o;
    }
    return null;
  }
}
