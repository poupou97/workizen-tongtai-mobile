import 'package:flutter/foundation.dart';

import 'finance_category.dart';
import 'finance_transaction.dart';
import 'settlement.dart';

/// The settlement kinds that are the **marketplace's own cut** — the same cost
/// the seller books under [FinanceCategory.platformFee] ("commission and
/// payment fees").
///
/// A closed, explicit set on purpose: not "anything outbound". Shipping, tax,
/// refunds and chargebacks each have their own home, and reading one of them as
/// a platform fee would raise the double-count alarm over two things that were
/// never the same cost.
const Set<SettlementKind> kPlatformFeeSettlementKinds = {
  SettlementKind.platformFee,
  SettlementKind.commission,
};

/// How many platform fees each of the two books carries in one period.
///
/// ## Why two books can hold the same fee — on purpose
///
/// ADR-TON-024 §2 keeps a seller's hand-entered `platform_fee`
/// [FinanceTransaction] in Finance and never moves it into Settlement, because
/// *moving it would be guessing the seller's intent*. The honest cost of that
/// rule is that when a reconciliation feed later brings the **same** fee in as a
/// [SettlementLine], both books hold it — and a seller reading a combined total
/// can be double-counting with no clue why.
///
/// WTM-460 makes the coexistence **visible without guessing**. This value
/// *counts* fees on each side; it deliberately does **not** try to match a
/// settlement line to a transaction (date+amount+kind). Declaring a pair "the
/// duplicate" would be fabricating Business Truth — two fees that happen to
/// share a day and a number are not necessarily the same fee.
@immutable
class FeeCoexistence {
  const FeeCoexistence({
    required this.reconciledFeeCount,
    required this.recordedFeeCount,
  }) : assert(reconciledFeeCount >= 0),
       assert(recordedFeeCount >= 0);

  /// Outbound platform-fee [SettlementLine]s in the period — from reconciliation.
  final int reconciledFeeCount;

  /// `platform_fee` [FinanceTransaction]s in the period — the seller's own rows.
  final int recordedFeeCount;

  /// Both books carry at least one platform fee this period. Only then is a
  /// double-count even *possible*, so only then does the screen say anything —
  /// a note that appeared with fees on one side would be a false alarm.
  bool get isCoexisting => reconciledFeeCount > 0 && recordedFeeCount > 0;

  static const FeeCoexistence none = FeeCoexistence(
    reconciledFeeCount: 0,
    recordedFeeCount: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeeCoexistence &&
          other.reconciledFeeCount == reconciledFeeCount &&
          other.recordedFeeCount == recordedFeeCount);

  @override
  int get hashCode => Object.hash(reconciledFeeCount, recordedFeeCount);

  @override
  String toString() =>
      'FeeCoexistence(reconciled: $reconciledFeeCount, recorded: $recordedFeeCount)';
}

/// Counts platform fees on each book for the half-open period
/// `[periodStart, periodEndExclusive)` — a pure Rule-Twin read (ADR-TON-016):
/// no AI, no network, no clock of its own.
///
/// It **only counts**. It never dedupes, never moves a record, and never claims
/// a settlement line and a transaction are the same fee (ADR-TON-024 §2, and
/// the ⛔ scope of WTM-460).
FeeCoexistence detectFeeCoexistence({
  required Iterable<SettlementLine> settlementLines,
  required Iterable<FinanceTransaction> transactions,
  required DateTime periodStart,
  required DateTime periodEndExclusive,
}) {
  bool inPeriod(DateTime at) =>
      !at.isBefore(periodStart) && at.isBefore(periodEndExclusive);

  final reconciled = settlementLines
      .where(
        (l) =>
            l.direction == SettlementDirection.outbound &&
            kPlatformFeeSettlementKinds.contains(l.kind) &&
            inPeriod(l.occurredAt),
      )
      .length;

  final recorded = transactions
      .where(
        (t) => t.category == FinanceCategory.platformFee && inPeriod(t.date),
      )
      .length;

  return FeeCoexistence(
    reconciledFeeCount: reconciled,
    recordedFeeCount: recorded,
  );
}
