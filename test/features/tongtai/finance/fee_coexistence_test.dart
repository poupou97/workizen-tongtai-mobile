import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/fee_coexistence.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/finance/settlement.dart';

/// WTM-460 — platform fees can live in **two books** at once (ADR-TON-024 §2).
///
/// The seller's own `platform_fee` [FinanceTransaction] stays in Finance and is
/// never moved into Settlement; a reconciliation feed can bring the same kind
/// of fee in as a [SettlementLine]. This pure function *counts* fees on each
/// book so the dashboard can say the two coexist. It must **never** dedupe or
/// guess that a given settlement line and transaction are the same fee.
void main() {
  // One reporting period: the calendar year 2026, as the YTD dashboard reads it.
  final periodStart = DateTime(2026);
  final periodEnd = DateTime(2027);

  var seq = 0;
  SettlementLine settlement({
    required SettlementKind kind,
    SettlementDirection direction = SettlementDirection.outbound,
    DateTime? occurredAt,
  }) => SettlementLine(
    id: 'sl-${seq++}',
    orderId: 'o1',
    kind: kind,
    direction: direction,
    amount: 50000,
    currency: 'VND',
    occurredAt: occurredAt ?? DateTime(2026, 6, 15),
    fundedBy: FundingSource.seller,
  );

  FinanceTransaction fee({
    FinanceCategory category = FinanceCategory.platformFee,
    DateTime? date,
  }) => FinanceTransaction(
    id: 'tx-${seq++}',
    type: TransactionType.expense,
    category: category,
    amount: 40000,
    date: date ?? DateTime(2026, 6, 20),
  );

  group('the state turns on only when both books hold a platform fee', () {
    test('both sides > 0 ⇒ coexisting (the DoD "on" case)', () {
      final result = detectFeeCoexistence(
        settlementLines: [settlement(kind: SettlementKind.platformFee)],
        transactions: [fee()],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.isCoexisting, isTrue);
      expect(result.reconciledFeeCount, 1);
      expect(result.recordedFeeCount, 1);
    });

    test('reconciliation fees only, no self-recorded ⇒ off', () {
      final result = detectFeeCoexistence(
        settlementLines: [settlement(kind: SettlementKind.platformFee)],
        transactions: const [],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.isCoexisting, isFalse);
      expect(result.reconciledFeeCount, 1);
      expect(result.recordedFeeCount, 0);
    });

    test('self-recorded fees only, no reconciliation ⇒ off', () {
      final result = detectFeeCoexistence(
        settlementLines: const [],
        transactions: [fee()],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.isCoexisting, isFalse);
      expect(result.reconciledFeeCount, 0);
      expect(result.recordedFeeCount, 1);
    });

    test('empty period ⇒ off (the DoD "empty" case)', () {
      final result = detectFeeCoexistence(
        settlementLines: const [],
        transactions: const [],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result, FeeCoexistence.none);
      expect(result.isCoexisting, isFalse);
    });
  });

  group('it counts, it does not judge which pair overlaps', () {
    test('reports the true counts on each side, unmatched', () {
      // Three reconciliation fees, two self-recorded — deliberately unequal so a
      // dedupe attempt would have to *pick* survivors. The function reports both
      // raw counts; the seller decides.
      final result = detectFeeCoexistence(
        settlementLines: [
          settlement(kind: SettlementKind.platformFee),
          settlement(kind: SettlementKind.commission),
          settlement(kind: SettlementKind.platformFee),
        ],
        transactions: [fee(), fee()],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.reconciledFeeCount, 3);
      expect(result.recordedFeeCount, 2);
      expect(result.isCoexisting, isTrue);
    });
  });

  group('only the marketplace-cut kinds count, and only outbound', () {
    test('commission counts as a platform fee alongside platform_fee', () {
      final result = detectFeeCoexistence(
        settlementLines: [settlement(kind: SettlementKind.commission)],
        transactions: [fee()],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.reconciledFeeCount, 1);
      expect(result.isCoexisting, isTrue);
    });

    test('shipping, tax, refund, chargeback are NOT platform fees', () {
      for (final kind in const [
        SettlementKind.shippingFee,
        SettlementKind.tax,
        SettlementKind.refund,
        SettlementKind.chargeback,
        SettlementKind.voucher,
        SettlementKind.discount,
        SettlementKind.adjustment,
        SettlementKind.unknown,
      ]) {
        final result = detectFeeCoexistence(
          settlementLines: [settlement(kind: kind)],
          transactions: [fee()],
          periodStart: periodStart,
          periodEndExclusive: periodEnd,
        );
        expect(
          result.reconciledFeeCount,
          0,
          reason: '${kind.code} is not the marketplace cut — must not count',
        );
        expect(result.isCoexisting, isFalse);
      }
    });

    test('an inbound platform fee is a refund of a fee, not a fee charged', () {
      // Same kind, opposite direction (ADR-TON-024 §2): a fee being *returned*
      // must not raise the double-count alarm.
      final result = detectFeeCoexistence(
        settlementLines: [
          settlement(
            kind: SettlementKind.platformFee,
            direction: SettlementDirection.inbound,
          ),
        ],
        transactions: [fee()],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.reconciledFeeCount, 0);
      expect(result.isCoexisting, isFalse);
    });

    test('a non-platform_fee transaction is not a self-recorded fee', () {
      final result = detectFeeCoexistence(
        settlementLines: [settlement(kind: SettlementKind.platformFee)],
        transactions: [fee(category: FinanceCategory.shipping)],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.recordedFeeCount, 0);
      expect(result.isCoexisting, isFalse);
    });
  });

  group('the period is half-open [start, end) and both books respect it', () {
    test('fees outside the period are ignored on both sides', () {
      final result = detectFeeCoexistence(
        settlementLines: [
          settlement(
            kind: SettlementKind.platformFee,
            occurredAt: DateTime(2025, 12, 31),
          ),
        ],
        transactions: [fee(date: DateTime(2027, 1, 1))],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );

      expect(result.reconciledFeeCount, 0);
      expect(result.recordedFeeCount, 0);
      expect(result.isCoexisting, isFalse);
    });

    test('start is inclusive, end is exclusive', () {
      final onStart = detectFeeCoexistence(
        settlementLines: [
          settlement(kind: SettlementKind.platformFee, occurredAt: periodStart),
        ],
        transactions: [fee(date: periodStart)],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );
      expect(onStart.isCoexisting, isTrue);

      final onEnd = detectFeeCoexistence(
        settlementLines: [
          settlement(kind: SettlementKind.platformFee, occurredAt: periodEnd),
        ],
        transactions: [fee(date: periodEnd)],
        periodStart: periodStart,
        periodEndExclusive: periodEnd,
      );
      expect(
        onEnd.isCoexisting,
        isFalse,
        reason: 'a fee dated exactly at periodEnd belongs to the next period',
      );
    });
  });
}
