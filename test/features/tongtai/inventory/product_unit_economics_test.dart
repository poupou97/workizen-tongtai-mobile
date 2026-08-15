// Kinh tế đơn vị của một sản phẩm — WTM-420 (concept-1 `cp6`).
//
// Ba luật, và cả ba đều nói về **chỗ chưa biết**:
//
//   §1 thiếu giá vốn ⇒ KHÔNG có lợi nhuận. Coi giá vốn bằng 0 là nói dối theo
//      hướng dễ chịu: mọi món đều lãi đúng bằng giá bán, biên 100%, và người
//      bán tin mình đang lãi to.
//   §2 bán lỗ là một SỰ THẬT — số âm phải đi ra nguyên vẹn, không kẹp về 0.
//   §3 dự phóng neo vào tồn kho THẬT, và chỉ tồn tại khi có đủ hai vế.
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_unit_economics.dart';

Product _product({double price = 100000, double? cost, int? quantity = 10}) =>
    Product(
      id: 'p',
      sku: 'SKU-1',
      name: 'Sản phẩm',
      category: 'home',
      pricePerUnit: price,
      costPrice: cost,
      quantity: quantity,
      updatedAt: DateTime(2026, 8, 15),
      provenance: ProvenanceSource.manual,
    );

void main() {
  test(
    '§1 chưa khai giá vốn ⇒ không lợi nhuận, không biên, không dự phóng',
    () {
      final e = ProductUnitEconomics.of(_product(cost: null));

      expect(e.hasCost, isFalse);
      expect(
        e.profitPerUnit,
        isNull,
        reason: 'coi giá vốn bằng 0 thì mọi món đều "lãi" đúng bằng giá bán',
      );
      expect(e.marginPercent, isNull);
      expect(e.projectedProfitOnStock, isNull);
    },
  );

  test('§2 bán LỖ ra số âm, không bị kẹp về 0', () {
    final e = ProductUnitEconomics.of(_product(price: 80000, cost: 100000));

    expect(e.profitPerUnit, -20000);
    expect(e.marginPercent, -25);
    expect(
      e.projectedProfitOnStock,
      -200000,
      reason: 'giấu số âm là giấu đúng chỗ người bán đang chảy máu',
    );
  });

  test('§3 dự phóng neo vào tồn kho thật', () {
    final e = ProductUnitEconomics.of(
      _product(price: 100000, cost: 60000, quantity: 34),
    );

    expect(e.profitPerUnit, 40000);
    expect(e.marginPercent, 40);
    expect(e.projectedProfitOnStock, 40000 * 34);
  });

  test('§3b hết hàng / chưa khai tồn ⇒ không dự phóng', () {
    for (final q in [0, null]) {
      final e = ProductUnitEconomics.of(_product(cost: 60000, quantity: q));
      expect(
        e.projectedProfitOnStock,
        isNull,
        reason: 'không còn gì để bán thì "bán hết tồn" không phải một câu',
      );
      expect(e.profitPerUnit, isNotNull, reason: 'lãi mỗi cái vẫn tính được');
    }
  });

  test('§4 giá bán bằng 0 ⇒ KHÔNG có biên (không phải vô cực)', () {
    final e = ProductUnitEconomics.of(_product(price: 0, cost: 60000));

    expect(e.profitPerUnit, -60000);
    expect(
      e.marginPercent,
      isNull,
      reason: '"biên lợi nhuận vô cực" là một câu vô nghĩa in lên màn hình',
    );
  });
}
