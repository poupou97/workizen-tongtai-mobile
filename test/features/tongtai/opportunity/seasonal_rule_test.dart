import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/opportunity/seasonal_rule.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-180 story 4 — **mùa vụ lặp lại**, và ba cái chốt chống bịa.
void main() {
  final now = DateTime(2026, 8, 11);

  Product product(String id, {int? quantity}) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Hàng $id',
    category: 'Thời trang',
    pricePerUnit: 100000,
    quantity: quantity,
    updatedAt: now,
  );

  CustomerOrder order(
    String id,
    DateTime date,
    String productId,
    int qty, {
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: date,
    status: status,
    items: [
      OrderItem(
        productId: productId,
        productName: 'Hàng $productId',
        sku: 'SKU-$productId',
        category: 'Thời trang',
        quantity: qty,
        unitPrice: 100000,
      ),
    ],
  );

  /// Đủ một năm lịch sử — điều kiện cần để luật chịu kết luận.
  List<CustomerOrder> withHistory(List<CustomerOrder> extra) => [
    order('anchor', DateTime(2025, 1, 5), 'x', 1),
    ...extra,
  ];

  test('⛔ chưa đủ một năm ⇒ TỪ CHỐI kết luận, không đoán', () {
    final verdict = const SeasonalRule().evaluate(
      orders: [order('o1', DateTime(2026, 6, 1), 'a', 50)],
      products: [product('a', quantity: 0)],
      now: now,
    );

    // "Cùng kỳ năm ngoái" mà không có năm ngoái thì không có gì để so.
    expect(verdict.isInsufficient, isTrue);
    expect(verdict.opportunities, isEmpty);
  });

  test('⛔ rỗng vì CHƯA XÉT ĐƯỢC khác rỗng vì ĐÃ XÉT', () {
    // Gộp hai câu này lại là cách một màn hình im lặng biến thành lời trấn an
    // sai: "không có gì đáng lo" trong khi sự thật là "chưa biết".
    final notEnough = const SeasonalRule().evaluate(
      orders: const [],
      products: const [],
      now: now,
    );
    final looked = const SeasonalRule().evaluate(
      orders: withHistory(const []),
      products: [product('a', quantity: 100)],
      now: now,
    );

    expect(notEnough.isInsufficient, isTrue);
    expect(looked.isInsufficient, isFalse);
    expect(looked.opportunities, isEmpty);
  });

  test('⭐ bán chạy cùng kỳ năm ngoái, năm nay hụt và thiếu hàng ⇒ có việc', () {
    final verdict = const SeasonalRule().evaluate(
      orders: withHistory([
        order('ly1', DateTime(2025, 8, 20), 'a', 12),
        order('ty1', DateTime(2026, 8, 5), 'a', 2),
      ]),
      products: [product('a', quantity: 1)],
      now: now,
    );

    expect(verdict.opportunities, hasLength(1));
    final s = verdict.opportunities.single;
    expect(s.unitsLastYear, 12);
    expect(s.unitsThisYear, 2);
    // Con số để người bán quyết nhập bao nhiêu, không phải lời khuyên chung.
    expect(s.shortfall, 10);
  });

  test('⛔ một đơn lẻ KHÔNG phải mùa vụ', () {
    final verdict = const SeasonalRule().evaluate(
      orders: withHistory([order('ly1', DateTime(2025, 8, 20), 'a', 2)]),
      products: [product('a', quantity: 0)],
      now: now,
    );

    expect(verdict.opportunities, isEmpty);
  });

  test('⛔ năm nay vẫn đang bán tốt ⇒ im lặng, không tạo tiếng ồn', () {
    final verdict = const SeasonalRule().evaluate(
      orders: withHistory([
        order('ly1', DateTime(2025, 8, 20), 'a', 10),
        order('ty1', DateTime(2026, 8, 5), 'a', 12),
      ]),
      products: [product('a', quantity: 0)],
      now: now,
    );

    expect(verdict.opportunities, isEmpty);
  });

  test('⛔ còn đủ hàng để bắt kịp ⇒ không có việc gì để làm', () {
    final verdict = const SeasonalRule().evaluate(
      orders: withHistory([order('ly1', DateTime(2025, 8, 20), 'a', 10)]),
      products: [product('a', quantity: 50)],
      now: now,
    );

    expect(verdict.opportunities, isEmpty);
  });

  test('tồn null = CHƯA KHAI, không phải hết hàng — vẫn nhắc', () {
    // ADR-TON-023: `null` ≠ 0. Chưa biết tồn thì không được kết luận là đủ.
    final verdict = const SeasonalRule().evaluate(
      orders: withHistory([order('ly1', DateTime(2025, 8, 20), 'a', 10)]),
      products: [product('a')],
      now: now,
    );

    expect(verdict.opportunities, hasLength(1));
  });

  test('đơn HUỶ không được tính là nhu cầu', () {
    final verdict = const SeasonalRule().evaluate(
      orders: withHistory([
        order(
          'ly1',
          DateTime(2025, 8, 20),
          'a',
          20,
          status: OrderStatus.cancelled,
        ),
      ]),
      products: [product('a', quantity: 0)],
      now: now,
    );

    expect(verdict.opportunities, isEmpty);
  });
}
