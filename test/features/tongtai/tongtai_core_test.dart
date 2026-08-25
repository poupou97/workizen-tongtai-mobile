import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart';

/// Real tests for the Tổng Tài core utilities (WTM-60).
void main() {
  group('TongtaiFormatters.vnd', () {
    test('groups thousands with a dot and appends ₫', () {
      expect(TongtaiFormatters.vnd(1234567), '1.234.567 ₫');
      expect(TongtaiFormatters.vnd(0), '0 ₫');
      expect(TongtaiFormatters.vnd(999), '999 ₫');
      expect(TongtaiFormatters.vnd(1000), '1.000 ₫');
    });

    test('handles negatives', () {
      expect(TongtaiFormatters.vnd(-5000), '-5.000 ₫');
    });
  });

  group('TongtaiFormatters.compact', () {
    test('abbreviates thousands/millions/billions', () {
      expect(TongtaiFormatters.compact(999), '999');
      expect(TongtaiFormatters.compact(1500), '1.5K');
      expect(TongtaiFormatters.compact(2300000), '2.3M');
      expect(TongtaiFormatters.compact(4000000000), '4B');
    });
  });

  group('TongtaiFormatters.relativeDate', () {
    final now = DateTime(2026, 7, 14, 12, 0, 0);

    test('buckets recent times', () {
      expect(
        TongtaiFormatters.relativeDate(
          now.subtract(const Duration(seconds: 30)),
          now: now,
        ),
        'just now',
      );
      expect(
        TongtaiFormatters.relativeDate(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5m ago',
      );
      expect(
        TongtaiFormatters.relativeDate(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3h ago',
      );
      expect(
        TongtaiFormatters.relativeDate(
          now.subtract(const Duration(days: 2)),
          now: now,
        ),
        '2d ago',
      );
    });

    test('falls back to absolute date beyond a week', () {
      expect(
        TongtaiFormatters.relativeDate(
          now.subtract(const Duration(days: 30)),
          now: now,
        ),
        '2026-06-14',
      );
    });
  });

  group('domain enums', () {
    test('OrderStatus parses storage strings and localizes', () {
      expect(OrderStatus.fromStorage('shipped'), OrderStatus.shipped);
      expect(OrderStatus.shipped.label('en'), 'Shipped');
      expect(OrderStatus.shipped.label('vi'), 'Đang giao');
    });

    // WTM-457 (ADR-TON-018): an unrecognised code is a corrupt record, not a
    // business default. It used to decode to `pending` — a delivered order
    // silently reading as "waiting to be handled".
    test('unknown OrderStatus surfaces as unknown, never a real status', () {
      expect(OrderStatus.fromStorage('garbage'), OrderStatus.unknown);
      expect(OrderStatus.fromStorage(null), OrderStatus.unknown);
      expect(OrderStatus.fromStorage('garbage'), isNot(OrderStatus.pending));
    });

    test('the unknown marker is labelled, never a blank chip', () {
      expect(OrderStatus.unknown.label('en'), 'Unrecognized');
      expect(OrderStatus.unknown.label('vi'), 'Không nhận ra');
    });

    test('unknown is a decode marker, not a status a seller can pick', () {
      expect(OrderStatus.selectable, isNot(contains(OrderStatus.unknown)));
      // Every real lifecycle state is still offered.
      expect(OrderStatus.selectable, hasLength(OrderStatus.values.length - 1));
    });

    test('valid stored codes keep their meaning (no drift)', () {
      // The point of WTM-457: only garbage changes destination.
      for (final s in OrderStatus.values) {
        expect(OrderStatus.fromStorage(s.name), s);
      }
    });

    test('JourneyStatus round-trips and localizes', () {
      expect(JourneyStatus.fromStorage('inProgress'), JourneyStatus.inProgress);
      expect(JourneyStatus.blocked.labelVi, 'Bị chặn');
    });

    // WTM-457: nullable, so a corrupt journey code cannot inherit `notStarted`.
    test('unknown JourneyStatus is null, never a real status', () {
      expect(JourneyStatus.fromStorage('garbage'), isNull);
      expect(JourneyStatus.fromStorage(null), isNull);
    });

    test('OpportunityType localizes', () {
      expect(OpportunityType.crossBorder.labelEn, 'Cross-border');
      expect(OpportunityType.crossBorder.labelVi, 'Xuyên biên giới');
      expect(OpportunityType.fromStorage('seasonal'), OpportunityType.seasonal);
    });

    // WTM-457: nullable, so a corrupt opportunity code cannot inherit `trend`.
    test('unknown OpportunityType is null, never a real type', () {
      expect(OpportunityType.fromStorage('garbage'), isNull);
      expect(OpportunityType.fromStorage(null), isNull);
    });

    test('TransactionType parses storage strings and localizes', () {
      expect(TransactionType.fromStorage('income'), TransactionType.income);
      expect(TransactionType.income.label('en'), 'Income');
      expect(TransactionType.expense.label('vi'), 'Chi');
    });

    // WTM-457: was `expense`, silently turning a corrupt income row into a cost.
    test('unknown TransactionType surfaces as unknown, never a real type', () {
      expect(TransactionType.fromStorage('garbage'), TransactionType.unknown);
      expect(TransactionType.fromStorage(null), TransactionType.unknown);
      expect(
        TransactionType.fromStorage('garbage'),
        isNot(TransactionType.expense),
      );
    });
  });
}
