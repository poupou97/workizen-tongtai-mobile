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
            now: now),
        'just now',
      );
      expect(
        TongtaiFormatters.relativeDate(
            now.subtract(const Duration(minutes: 5)),
            now: now),
        '5m ago',
      );
      expect(
        TongtaiFormatters.relativeDate(now.subtract(const Duration(hours: 3)),
            now: now),
        '3h ago',
      );
      expect(
        TongtaiFormatters.relativeDate(now.subtract(const Duration(days: 2)),
            now: now),
        '2d ago',
      );
    });

    test('falls back to absolute date beyond a week', () {
      expect(
        TongtaiFormatters.relativeDate(now.subtract(const Duration(days: 30)),
            now: now),
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

    test('unknown OrderStatus falls back to pending', () {
      expect(OrderStatus.fromStorage('garbage'), OrderStatus.pending);
      expect(OrderStatus.fromStorage(null), OrderStatus.pending);
    });

    test('JourneyStatus round-trips and localizes', () {
      expect(JourneyStatus.fromStorage('inProgress'),
          JourneyStatus.inProgress);
      expect(JourneyStatus.blocked.labelVi, 'Bị chặn');
    });

    test('OpportunityType localizes', () {
      expect(OpportunityType.crossBorder.labelEn, 'Cross-border');
      expect(OpportunityType.crossBorder.labelVi, 'Xuyên biên giới');
      expect(OpportunityType.fromStorage('seasonal'),
          OpportunityType.seasonal);
    });
  });
}
