import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_insight.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-347 — hai câu hỏi về một khách mà đơn hàng không tự trả lời.
void main() {
  final at = DateTime(2026, 8, 1);

  Product product(String id) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Hàng $id',
    category: 'Thời trang',
    pricePerUnit: 100000,
    updatedAt: at,
  );

  CustomerOrder order(String id, String customerId, List<String> productIds) =>
      CustomerOrder(
        id: id,
        customerId: customerId,
        orderNumber: 'DH-$id',
        date: at,
        status: OrderStatus.delivered,
        items: [
          for (final p in productIds)
            OrderItem(
              productId: p,
              productName: 'Hàng $p',
              sku: 'SKU-$p',
              category: 'Thời trang',
              quantity: 1,
              unitPrice: 100000,
            ),
        ],
      );

  group('Discover — khách này từ đâu tới', () {
    test('⭐ lấy việc SỚM NHẤT có mang tên nền tảng', () {
      final touch = firstTouchOf([
        (vendor: 'shopee', at: DateTime(2026, 7, 20)),
        (vendor: 'facebook_page', at: DateTime(2026, 7, 12)),
        (vendor: 'tiktok_shop', at: DateTime(2026, 8, 1)),
      ]);

      expect(touch?.vendor, 'facebook_page');
      expect(touch?.at, DateTime(2026, 7, 12));
    });

    test('việc nội bộ không tính là kênh — nó không nói khách từ đâu', () {
      final touch = firstTouchOf([
        (vendor: null, at: DateTime(2026, 7, 1)),
        (vendor: '', at: DateTime(2026, 7, 5)),
        (vendor: 'shopee', at: DateTime(2026, 7, 20)),
      ]);

      expect(touch?.vendor, 'shopee');
    });

    test('⛔ khách gõ tay vào danh bạ ⇒ null, KHÔNG đoán một kênh', () {
      // Đoán một kênh cho họ là bịa ra một nguồn khách.
      expect(firstTouchOf([(vendor: null, at: at)]), isNull);
      expect(firstTouchOf(const []), isNull);
    });
  });

  group('Recommendation — nên mời khách mua gì tiếp', () {
    final products = [
      for (final id in ['a', 'b', 'c', 'd']) product(id),
    ];

    test('⭐ gợi ý thứ khách KHÁC mua kèm, xếp theo số lần', () {
      final result = suggestionsFor(
        customerId: 'me',
        orders: [
          order('o1', 'me', ['a']),
          order('o2', 'x', ['a', 'b']),
          order('o3', 'y', ['a', 'b']),
          order('o4', 'z', ['a', 'c']),
        ],
        products: products,
      );

      expect(result.map((s) => s.product.id), ['b', 'c']);
      expect(result.first.boughtTogetherCount, 2);
    });

    test('không gợi ý lại thứ khách đã mua', () {
      final result = suggestionsFor(
        customerId: 'me',
        orders: [
          order('o1', 'me', ['a', 'b']),
          order('o2', 'x', ['a', 'b']),
        ],
        products: products,
      );

      expect(result, isEmpty);
    });

    test('⛔ khách chưa mua gì ⇒ RỖNG, không rơi về hàng bán chạy', () {
      // Một danh sách bán chạy đội lốt gợi ý cá nhân luôn có nội dung, nên
      // không ai nhận ra nó chưa bao giờ biết gì về khách.
      final result = suggestionsFor(
        customerId: 'newbie',
        orders: [
          order('o1', 'x', ['a', 'b']),
          order('o2', 'y', ['a', 'b']),
        ],
        products: products,
      );

      expect(result, isEmpty);
    });

    test('hoà thì xếp theo mã — cùng dữ liệu cho cùng thứ tự', () {
      final result = suggestionsFor(
        customerId: 'me',
        orders: [
          order('o1', 'me', ['a']),
          order('o2', 'x', ['a', 'c', 'b']),
        ],
        products: products,
      );

      expect(result.map((s) => s.product.id), ['b', 'c']);
    });
  });
}
