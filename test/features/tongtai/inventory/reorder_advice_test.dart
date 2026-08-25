import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/inventory/reorder_advice.dart';

/// WTM-456 — the reorder rule the stock alert learns from stored supplier
/// quotes. Two pure pieces, tested on their own so the numbers can never hide in
/// a widget:
///
///  * [bestReorderQuote] — the explicit "best quote" rule, including tie-break;
///  * [ReorderAdvice.forShortfall] — turns a shortfall + that quote into "order
///    this much · wait this long · quote is this old".
void main() {
  SupplierQuote quote({
    required String id,
    required double unitCost,
    int? leadTimeDays = 7,
    double? minimumOrderQuantity = 10,
    DateTime? quotedAt,
    String name = 'Nguồn',
  }) {
    return SupplierQuote(
      id: id,
      productId: 'p1',
      supplierName: name,
      unitCost: unitCost,
      leadTimeDays: leadTimeDays,
      minimumOrderQuantity: minimumOrderQuantity,
      quotedAt: quotedAt ?? DateTime(2026, 8, 1),
    );
  }

  group('bestReorderQuote — the explicit selection rule', () {
    test('no quotes at all ⇒ null (null ≠ 0)', () {
      expect(bestReorderQuote(const []), isNull);
    });

    test('a quote missing lead time does not qualify', () {
      expect(
        bestReorderQuote([quote(id: 'a', unitCost: 100, leadTimeDays: null)]),
        isNull,
      );
    });

    test('a quote missing MOQ does not qualify', () {
      expect(
        bestReorderQuote([
          quote(id: 'a', unitCost: 100, minimumOrderQuantity: null),
        ]),
        isNull,
      );
    });

    test('picks the lowest unit cost among the qualifying quotes', () {
      final best = bestReorderQuote([
        quote(id: 'pricey', unitCost: 120),
        quote(id: 'cheap', unitCost: 80),
        quote(id: 'mid', unitCost: 100),
      ]);
      expect(best?.id, 'cheap');
    });

    test('a cheaper but incomplete quote loses to a complete pricier one', () {
      // The whole point of the rule: half a quote can only give half the
      // answer, so it is not a candidate even when it is the cheapest.
      final best = bestReorderQuote([
        quote(id: 'cheap-no-lead', unitCost: 50, leadTimeDays: null),
        quote(id: 'cheap-no-moq', unitCost: 55, minimumOrderQuantity: null),
        quote(id: 'complete', unitCost: 90),
      ]);
      expect(best?.id, 'complete');
    });

    test('ties on unit cost break to the most recently quoted', () {
      final best = bestReorderQuote([
        quote(id: 'older', unitCost: 100, quotedAt: DateTime(2026, 6, 1)),
        quote(id: 'newer', unitCost: 100, quotedAt: DateTime(2026, 8, 20)),
        quote(id: 'oldest', unitCost: 100, quotedAt: DateTime(2026, 1, 1)),
      ]);
      expect(best?.id, 'newer');
    });

    test(
      'lower cost still wins over a newer-but-pricier quote (cost first)',
      () {
        final best = bestReorderQuote([
          quote(id: 'newer-pricey', unitCost: 100, quotedAt: DateTime(2026, 9)),
          quote(id: 'older-cheap', unitCost: 80, quotedAt: DateTime(2026, 1)),
        ]);
        expect(best?.id, 'older-cheap');
      },
    );
  });

  group('ReorderAdvice.forShortfall', () {
    final now = DateTime(2026, 8, 25);

    test('no qualifying quote ⇒ null (alert stays as it was)', () {
      expect(
        ReorderAdvice.forShortfall(5, [
          quote(id: 'a', unitCost: 100, leadTimeDays: null),
        ], now: now),
        isNull,
      );
      expect(ReorderAdvice.forShortfall(5, const [], now: now), isNull);
    });

    test('order quantity is the shortfall when it exceeds the MOQ', () {
      final advice = ReorderAdvice.forShortfall(50, [
        quote(id: 'a', unitCost: 100, minimumOrderQuantity: 10),
      ], now: now);
      expect(advice, isNotNull);
      expect(advice!.orderQuantity, 50);
    });

    test(
      'order quantity is lifted to the MOQ when the shortfall is smaller',
      () {
        // Ordering fewer than the supplier's minimum is not an order they take —
        // so the advice is max(shortfall, MOQ), not the bare shortfall.
        final advice = ReorderAdvice.forShortfall(3, [
          quote(id: 'a', unitCost: 100, minimumOrderQuantity: 100),
        ], now: now);
        expect(advice!.orderQuantity, 100);
      },
    );

    test('lead time is the chosen quote\'s own, never averaged', () {
      final advice = ReorderAdvice.forShortfall(10, [
        quote(id: 'slow-cheap', unitCost: 80, leadTimeDays: 30),
        quote(id: 'fast-pricey', unitCost: 200, leadTimeDays: 2),
      ], now: now);
      // The cheapest qualifying quote is chosen, so its 30-day lead time is
      // reported verbatim — not blended with the 2-day one.
      expect(advice!.leadTimeDays, 30);
      expect(advice.quote.id, 'slow-cheap');
    });

    test('quote age is measured from quotedAt to now', () {
      final advice = ReorderAdvice.forShortfall(10, [
        quote(id: 'a', unitCost: 100, quotedAt: DateTime(2026, 8, 5)),
      ], now: now);
      expect(advice!.quoteAgeDays, 20);
    });

    test('a fresh quote reports age zero, not a negative number', () {
      final advice = ReorderAdvice.forShortfall(10, [
        quote(id: 'a', unitCost: 100, quotedAt: now),
      ], now: now);
      expect(advice!.quoteAgeDays, 0);
    });
  });
}
