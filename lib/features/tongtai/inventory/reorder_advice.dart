import 'package:flutter/foundation.dart';

import '../commerce/commerce_models.dart';

/// The best supplier quote to reorder from, among [quotes] — an **explicit
/// rule** (WTM-456), written here as a pure function rather than buried in a
/// widget so it can be read, argued with, and tested on its own.
///
/// A quote only qualifies when it carries BOTH a [SupplierQuote.leadTimeDays]
/// and a [SupplierQuote.minimumOrderQuantity]: this feature promises the whole
/// answer (đặt bao nhiêu · chờ bao lâu), and a quote missing either half can
/// only give half of it. Among the qualifiers the lowest
/// [SupplierQuote.unitCost] wins; a tie breaks to the most recently quoted
/// ([SupplierQuote.quotedAt]) — a fresher price is the better guess.
///
/// Returns `null` when nothing qualifies. `null ≠ 0`: the caller then leaves the
/// alert exactly as it was, with no lead time borrowed from another product or
/// averaged across suppliers.
SupplierQuote? bestReorderQuote(Iterable<SupplierQuote> quotes) {
  SupplierQuote? best;
  for (final quote in quotes) {
    // Half a quote is not a candidate: without either number the advice would
    // have to invent the missing half, which is exactly what this rule forbids.
    if (quote.leadTimeDays == null || quote.minimumOrderQuantity == null) {
      continue;
    }
    if (best == null) {
      best = quote;
      continue;
    }
    if (quote.unitCost < best.unitCost) {
      best = quote;
    } else if (quote.unitCost == best.unitCost &&
        quote.quotedAt.isAfter(best.quotedAt)) {
      // Same price ⇒ prefer the fresher quote (tie-break, WTM-456).
      best = quote;
    }
  }
  return best;
}

/// What a shop owner needs in order to act on a stock alert, derived from the
/// single best supplier quote for that product (WTM-456).
///
/// Pure — this is the Rule Twin (ADR-TON-016): it runs with no AI, network or
/// key, and never fabricates a number. AI may later *explain* these figures, but
/// it does not produce them.
@immutable
class ReorderAdvice {
  const ReorderAdvice({
    required this.quote,
    required this.orderQuantity,
    required this.leadTimeDays,
    required this.quoteAgeDays,
  });

  /// Advice for a product [shortfall] units below its reorder threshold, chosen
  /// from [quotes]; `null` when no quote qualifies (see [bestReorderQuote]).
  ///
  /// [now] is injected, never read from the clock in here, so the quote age is
  /// deterministic and testable.
  static ReorderAdvice? forShortfall(
    int shortfall,
    Iterable<SupplierQuote> quotes, {
    required DateTime now,
  }) {
    final quote = bestReorderQuote(quotes);
    if (quote == null) return null;
    // Both are non-null by bestReorderQuote's own qualification rule — the `!`
    // is a total function here, not a guess.
    final moq = quote.minimumOrderQuantity!;
    final leadTime = quote.leadTimeDays!;
    // "Đặt bao nhiêu" = đủ để vượt lại ngưỡng, nhưng không dưới đơn tối thiểu
    // của nguồn: đặt ít hơn MOQ thì nguồn không nhận.
    final needed = shortfall.toDouble();
    return ReorderAdvice(
      quote: quote,
      orderQuantity: needed > moq ? needed : moq,
      leadTimeDays: leadTime,
      quoteAgeDays: quote.daysOldAt(now),
    );
  }

  /// The quote these numbers were read off — its name, cost and currency are the
  /// audit trail behind the advice, so the seller can trace where it came from.
  final SupplierQuote quote;

  /// How many units to order: `max(shortfall, minimumOrderQuantity)`. A [double]
  /// because MOQ is one; the UI formats it for display.
  final double orderQuantity;

  /// Days to wait for delivery — the best quote's own lead time, never an
  /// average across suppliers.
  final int leadTimeDays;

  /// How old the quote is at [now]. Carried alongside the numbers on purpose: an
  /// old quote is a wrong quote, so the app says its age instead of presenting a
  /// three-month-old price as today's (the rule the `supplier_quotes` docstring
  /// already states).
  final int quoteAgeDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReorderAdvice &&
          other.quote == quote &&
          other.orderQuantity == orderQuantity &&
          other.leadTimeDays == leadTimeDays &&
          other.quoteAgeDays == quoteAgeDays);

  @override
  int get hashCode =>
      Object.hash(quote, orderQuantity, leadTimeDays, quoteAgeDays);

  @override
  String toString() =>
      'ReorderAdvice(order=$orderQuantity, lead=$leadTimeDays, '
      'age=$quoteAgeDays, ${quote.supplierName})';
}
