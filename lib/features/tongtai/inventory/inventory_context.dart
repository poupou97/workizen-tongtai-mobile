import 'package:flutter/foundation.dart';

import '../core/capability_context_provider.dart';
import 'product.dart';
import 'product_repository.dart';

/// Inventory-capability slice of the business snapshot (WTM-129/131).
@immutable
class InventorySummary {
  const InventorySummary({
    required this.productCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.stockValue,
    required this.unknownCostCount,
  });

  static const InventorySummary empty = InventorySummary(
    productCount: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    stockValue: 0,
    unknownCostCount: 0,
  );

  final int productCount;
  final int lowStockCount;
  final int outOfStockCount;

  /// **Giá vốn** đang nằm trong kho, tính bằng đồng — Σ `costPrice × quantity`
  /// của những mặt hàng **đã khai giá vốn** (WTM-455). KHÔNG dùng giá bán: giá
  /// bán là doanh thu kỳ vọng, không phải tiền đang đọng.
  ///
  /// Con số này có thể **thấp hơn sự thật** khi còn mặt hàng chưa khai giá vốn
  /// — xem [unknownCostCount] để biết còn thiếu bao nhiêu. Cấm cộng chúng thành
  /// 0 (ADR-TON-022: `null ≠ 0`).
  final double stockValue;

  /// Số mặt hàng **còn tồn mà chưa khai giá vốn** ⇒ không tính được vào
  /// [stockValue]. Đếm ra thay vì nuốt vào tổng, để giao diện nói thẳng phần
  /// chưa tính (WTM-455) — cùng kỷ luật `SlowMovingCapital`. `0` ⇒ tổng đã đủ.
  final int unknownCostCount;

  /// Tổng [stockValue] đang **thiếu** một phần vì còn mặt hàng chưa khai giá vốn.
  bool get isPartial => unknownCostCount > 0;

  factory InventorySummary.from(List<Product> products) {
    var low = 0;
    var out = 0;
    var unknownCost = 0;
    var value = 0.0;
    for (final p in products) {
      // `null` = còn tồn nhưng chưa khai giá vốn ⇒ chưa tính được, đếm riêng
      // (WTM-455). Không cộng thành 0: một tổng thiếu trông như tổng đủ sẽ làm
      // người bán yên tâm nhầm. `0` (hết tồn / loại không giữ kho) vẫn vào tổng.
      final v = p.stockValue;
      if (v == null) {
        unknownCost += 1;
      } else {
        value += v;
      }
      switch (p.stockStatus) {
        case StockStatus.lowStock:
          low += 1;
        case StockStatus.outOfStock:
          out += 1;
        // `inStock` và `null` đều không phải cảnh báo. `null` = sản phẩm không
        // có tồn kho (ADR-TON-023): nó không nằm trong chỉ số kho, và cũng
        // không bị đếm là "còn hàng" — nó đơn giản không thuộc câu hỏi này.
        case StockStatus.inStock:
        case null:
          break;
      }
    }
    return InventorySummary(
      productCount: products.length,
      lowStockCount: low,
      outOfStockCount: out,
      stockValue: value,
      unknownCostCount: unknownCost,
    );
  }
}

/// The Inventory capability's Context Provider (WTM-131) — loads products from
/// the repository and produces the [InventorySummary] slice for BusinessContext.
class InventoryContextProvider
    implements CapabilityContextProvider<InventorySummary> {
  const InventoryContextProvider(this._repository);

  final ProductRepository _repository;

  @override
  Future<InventorySummary> load() async =>
      InventorySummary.from(await _repository.loadAll());
}
