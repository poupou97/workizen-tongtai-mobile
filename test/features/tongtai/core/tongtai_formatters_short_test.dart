import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart';

/// VN-compact đồng formatter (WTM-14 KPI chips): nghìn → K, triệu → tr,
/// tỷ → tỷ, decimal comma.
void main() {
  group('TongtaiFormatters.vndShort', () {
    test('thousands use K, rounded', () {
      expect(TongtaiFormatters.vndShort(579714), '580K ₫');
      expect(TongtaiFormatters.vndShort(1000), '1K ₫');
    });

    test('millions use tr with a comma decimal, trailing zeros trimmed', () {
      expect(TongtaiFormatters.vndShort(4058000), '4,06tr ₫');
      expect(TongtaiFormatters.vndShort(1250000), '1,25tr ₫');
      expect(TongtaiFormatters.vndShort(12000000), '12tr ₫');
      expect(TongtaiFormatters.vndShort(1000000), '1tr ₫');
    });

    test('billions use tỷ', () {
      expect(TongtaiFormatters.vndShort(1250000000), '1,25tỷ ₫');
    });

    test('below a thousand stays whole đồng', () {
      expect(TongtaiFormatters.vndShort(500), '500 ₫');
      expect(TongtaiFormatters.vndShort(0), '0 ₫');
    });

    test('negatives keep the sign', () {
      expect(TongtaiFormatters.vndShort(-4058000), '-4,06tr ₫');
    });
  });
}
