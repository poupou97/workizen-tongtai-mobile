// WTM-411 — vốn chôn trong hàng chậm bán, và **cái chưa khai giá vốn**.
//
// Luật canh:
//
//   §1 thiếu giá vốn ⇒ KHÔNG cộng thành 0, phải đếm riêng
//   §2 hết hàng ≠ hàng nằm — tồn 0 thì không có vốn nào đang nằm
//   §3 bán được trong cửa sổ ⇒ không phải hàng chậm
//   §4 cửa sổ đi vào từ phía gọi, lớp này KHÔNG tự đặt ngưỡng
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/slow_moving_capital.dart';

Product p({required String id, int? quantity, double? costPrice}) => Product(
  id: id,
  sku: 'SKU-$id',
  name: 'Sản phẩm $id',
  category: 'Gia dụng',
  pricePerUnit: 200000,
  quantity: quantity,
  costPrice: costPrice,
  updatedAt: DateTime(2026, 8, 14),
);

void main() {
  test('⭐ §1 thiếu giá vốn ⇒ KHÔNG cộng thành 0, đếm riêng', () {
    final r = SlowMovingCapital.from(
      products: [
        p(id: 'a', quantity: 10, costPrice: 50000), // 500k đo được
        p(id: 'b', quantity: 4), // chưa khai giá vốn
      ],
      soldProductIds: const {},
      windowDays: 30,
    );

    expect(r.slowMovingCount, 2, reason: 'cả hai đều là hàng chậm');
    expect(r.tiedUpAmount, 500000, reason: 'chỉ cộng mặt hàng ĐO ĐƯỢC');
    expect(
      r.unknownCostCount,
      1,
      reason:
          'mặt hàng chưa khai giá vốn phải đếm riêng, '
          'nếu không tổng thấp hơn sự thật mà trông như đã đủ',
    );
    expect(r.isPartial, isTrue);
  });

  test('§2 hết hàng ≠ hàng nằm', () {
    // Lâu rồi không bán, nhưng tồn 0 ⇒ không có đồng vốn nào đang nằm.
    final r = SlowMovingCapital.from(
      products: [
        p(id: 'a', quantity: 0, costPrice: 50000),
        p(id: 'b', costPrice: 50000), // tồn chưa khai
      ],
      soldProductIds: const {},
      windowDays: 30,
    );
    expect(r.slowMovingCount, 0);
    expect(r.tiedUpAmount, 0);
    expect(r.hasSlowMoving, isFalse);
  });

  test('§3 bán được trong cửa sổ ⇒ không phải hàng chậm', () {
    final r = SlowMovingCapital.from(
      products: [
        p(id: 'a', quantity: 10, costPrice: 50000),
        p(id: 'b', quantity: 10, costPrice: 50000),
      ],
      soldProductIds: const {'a'},
      windowDays: 30,
    );
    expect(r.slowMovingCount, 1);
    expect(r.tiedUpAmount, 500000);
  });

  test('§4 cửa sổ được giữ nguyên để câu chữ nói đúng con số nó dựa vào', () {
    // Lớp này không tự đặt ngưỡng — nó chỉ mang theo con số phía gọi đưa, để
    // giao diện khỏi viết cứng một số thứ hai.
    final r = SlowMovingCapital.from(
      products: [p(id: 'a', quantity: 1, costPrice: 1000)],
      soldProductIds: const {},
      windowDays: 45,
    );
    expect(r.windowDays, 45);
  });

  test('kho rỗng ⇒ không có gì, không nổ', () {
    final r = SlowMovingCapital.from(
      products: const [],
      soldProductIds: const {},
      windowDays: 30,
    );
    expect(r.hasSlowMoving, isFalse);
    expect(r.isPartial, isFalse);
    expect(r.tiedUpAmount, 0);
  });
}
