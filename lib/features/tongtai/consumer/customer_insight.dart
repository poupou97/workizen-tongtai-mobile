import 'package:flutter/foundation.dart';

import '../inventory/product.dart';
import '../orders/order.dart';

/// Hai câu hỏi về một khách mà đơn hàng KHÔNG tự trả lời — WTM-347.
///
/// * **Khách này từ đâu tới?** (Discover)
/// * **Nên mời họ mua gì tiếp?** (Recommendation)
///
/// Cả hai suy ra từ dữ liệu đã có: việc đầu tiên chạm tới khách, và những gì
/// khách khác mua kèm. Không bảng mới, không màn mới, không AI — Rule Twin.

/// Lần đầu tiên khách xuất hiện, và **ở đâu**.
@immutable
class FirstTouch {
  const FirstTouch({required this.vendor, required this.at});

  /// Mã nền tảng — `facebook_page` · `shopee`… Khách tự người bán nhập tay thì
  /// không có kênh nào cả, và đó là lý do [firstTouchOf] trả `null`.
  final String vendor;

  final DateTime at;
}

/// Việc **sớm nhất** có mang tên một nền tảng.
///
/// `null` = không biết khách đến từ đâu. Đó là câu trả lời thật cho khách được
/// gõ tay vào danh bạ; đoán một kênh cho họ là bịa ra một nguồn khách.
FirstTouch? firstTouchOf(Iterable<({String? vendor, DateTime at})> touches) {
  ({String vendor, DateTime at})? best;
  for (final t in touches) {
    final vendor = t.vendor;
    if (vendor == null || vendor.isEmpty) continue;
    if (best == null || t.at.isBefore(best.at)) {
      best = (vendor: vendor, at: t.at);
    }
  }
  return best == null ? null : FirstTouch(vendor: best.vendor, at: best.at);
}

/// Một mặt hàng nên mời khách mua tiếp, kèm **lý do đọc được**.
@immutable
class ProductSuggestion {
  const ProductSuggestion({
    required this.product,
    required this.boughtTogetherCount,
  });

  final Product product;

  /// Bao nhiêu khách khác đã mua nó **cùng** thứ khách này từng mua.
  final int boughtTogetherCount;
}

/// Gợi ý mua kèm, suy từ đơn hàng THẬT.
///
/// ## Luật
///
/// 1. Lấy những mặt hàng khách này đã mua.
/// 2. Tìm các đơn **của người khác** có chứa ít nhất một trong số đó.
/// 3. Đếm những mặt hàng còn lại trong các đơn ấy.
/// 4. Bỏ thứ khách đã mua rồi, xếp theo số lần mua kèm.
///
/// ## Vì sao không đoán khi thiếu dữ liệu
///
/// Khách chưa mua gì ⇒ **rỗng**, không phải "gợi ý hàng bán chạy". Một danh
/// sách bán chạy đội lốt gợi ý cá nhân là kiểu nói dối khó phát hiện nhất: nó
/// luôn có nội dung, nên không ai nhận ra nó chưa bao giờ biết gì về khách.
List<ProductSuggestion> suggestionsFor({
  required String customerId,
  required List<CustomerOrder> orders,
  required List<Product> products,
  int max = 3,
}) {
  final mine = <String>{};
  for (final o in orders) {
    if (o.customerId != customerId) continue;
    for (final item in o.items) {
      mine.add(item.productId);
    }
  }
  if (mine.isEmpty) return const [];

  final together = <String, int>{};
  for (final o in orders) {
    if (o.customerId == customerId) continue;
    final ids = {for (final item in o.items) item.productId};
    if (!ids.any(mine.contains)) continue;
    for (final id in ids) {
      if (mine.contains(id)) continue;
      together[id] = (together[id] ?? 0) + 1;
    }
  }
  if (together.isEmpty) return const [];

  final byId = {for (final p in products) p.id: p};
  final ranked = together.entries.toList()
    // Hoà thì xếp theo mã, để cùng dữ liệu luôn cho cùng thứ tự — ảnh chụp và
    // test mới đối chiếu được với nhau.
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

  return [
    for (final e in ranked.take(max))
      if (byId[e.key] case final product?)
        ProductSuggestion(product: product, boughtTogetherCount: e.value),
  ];
}
