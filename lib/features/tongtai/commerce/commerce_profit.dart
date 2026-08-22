import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import '../finance/settlement.dart';
import '../finance/true_profit.dart';
import '../inventory/product.dart';
import '../orders/order.dart';
import '../profile/business_profile.dart' show SalesChannel;

/// **Lời thật sau phí** — Capability Context của thương mại (WTM-328 · C4).
///
/// ## ⛔ Không có Finance truth thứ hai
///
/// Founder: *"Không tạo Finance truth thứ hai. Reuse canonical commerce +
/// settlement hiện tại."*
///
/// Nên lớp này **không tự tính** lợi nhuận. Nó chỉ gom đúng ba mảnh mà
/// `TrueProfitRule` (ADR-TON-016) đòi — doanh thu, giá vốn từng món, các dòng
/// đối soát — rồi giao cho quy tắc đó quyết. Công thức nằm ở đúng một chỗ, và
/// đó là chỗ đã có từ WTM-231.
///
/// ## Vì sao câu hỏi này khó hơn nó trông
///
/// *"Tháng này tôi lời bao nhiêu?"* — người bán tính nhẩm `giá bán − giá vốn`.
/// Con số đó **luôn dương** với mọi sản phẩm họ bán. Nhưng:
///
/// ```
/// doanh thu 259.000  −  giá vốn 240.000  =  lãi gộp 19.000   ← ai cũng thấy
///                    −  hoa hồng sàn 14.245
///                    −  phí thanh toán 7.252
///                    =  LỖ 2.497                              ← không ai thấy
/// ```
///
/// Sản phẩm đó vẫn nằm trong danh sách bán chạy. Càng bán càng lỗ, và bảng
/// doanh thu vẫn xanh.
@immutable
class CommerceProfitContext {
  const CommerceProfitContext({
    required this.from,
    required this.to,
    required this.overall,
    required this.byProduct,
    required this.observedAt,
  });

  /// Dựng từ dữ liệu thật. Hàm thuần — không mạng, không DB, test được thẳng.
  factory CommerceProfitContext.derive({
    required List<CustomerOrder> orders,
    required List<Product> products,
    required List<SettlementLine> settlements,
    required DateTime now,
    Duration window = const Duration(days: 30),
    TrueProfitRule rule = const TrueProfitRule(),
  }) {
    final from = now.subtract(window);
    final costOf = {for (final p in products) p.id: p.costPrice};
    final nameOf = {for (final p in products) p.id: p.name};
    final linesByOrder = <String, List<SettlementLine>>{};
    for (final line in settlements) {
      (linesByOrder[line.orderId] ??= []).add(line);
    }

    // Đơn **đã huỷ/hoàn** không phải doanh thu. Tính chúng vào rồi trừ ở phần
    // hoàn tiền sẽ ra đúng tổng nhưng sai từng sản phẩm — và người bán đọc
    // theo sản phẩm.
    final counted = [
      for (final o in orders)
        if (!o.date.isBefore(from) &&
            !o.date.isAfter(now) &&
            o.status != OrderStatus.cancelled)
          o,
    ];

    var revenue = 0.0;
    final itemCosts = <String, double?>{};
    final lines = <SettlementLine>[];
    final perProduct = <String, _ProductAccumulator>{};
    var marketplaceOrdersWithoutFees = 0;

    for (final order in counted) {
      final orderLines = linesByOrder[order.id] ?? const <SettlementLine>[];
      lines.addAll(orderLines);

      // ⭐ Đơn bán trên sàn mà chưa có khoản phí nào ⇒ chưa tính được lời
      // (WTM-322). Suy ra từ **kênh bán**, không từ "không thấy dòng phí": một
      // đơn bán tại quầy không có phí sàn là bình thường, một đơn Shopee thì
      // không — và nhầm hai chuyện đó làm lợi nhuận sai theo hướng tâng bốc.
      if (orderLines.isEmpty && _chargesPlatformFees(order.channel)) {
        marketplaceOrdersWithoutFees++;
      }

      final orderRevenue = order.items.fold<double>(
        0,
        (sum, i) => sum + i.unitPrice * i.quantity,
      );

      for (final item in order.items) {
        final itemRevenue = item.unitPrice * item.quantity;
        revenue += itemRevenue;

        // Khoá gồm mã đơn: hai đơn cùng sản phẩm là **hai** khoản giá vốn, và
        // gộp chúng lại sẽ tính thiếu vốn cho sản phẩm bán nhiều nhất.
        final cost = costOf[item.productId];
        itemCosts['${order.id}:${item.productId}'] = cost == null
            ? null
            : cost * item.quantity;

        final acc = perProduct.putIfAbsent(
          item.productId,
          () => _ProductAccumulator(
            productId: item.productId,
            name: nameOf[item.productId] ?? item.productName,
          ),
        );
        acc.revenue += itemRevenue;
        acc.units += item.quantity;
        acc.costPerUnit = cost;
        // Phí của đơn phân bổ theo **tỷ trọng doanh thu** của món trong đơn.
        // Đơn một món thì trọn vẹn; đơn nhiều món thì đây là cách phân bổ duy
        // nhất không cần thông tin sàn không cung cấp.
        final share = orderRevenue == 0 ? 0.0 : itemRevenue / orderRevenue;
        for (final line in orderLines) {
          acc.settlementImpact += line.signedImpact * share;
        }
        acc.orders.add(order.id);
      }
    }

    final overall = rule.compute(
      revenue: revenue,
      itemCosts: itemCosts,
      lines: lines,
      marketplaceOrdersWithoutFees: marketplaceOrdersWithoutFees,
    );

    final byProduct =
        <ProductProfit>[
          for (final acc in perProduct.values) acc.build(),
        ]..sort((a, b) {
          // Lỗ lên đầu. Người bán mở màn này để tìm chỗ chảy máu, không để ngắm
          // sản phẩm tốt.
          final aValue = a.profit is ProfitKnown
              ? (a.profit as ProfitKnown).amount
              : double.infinity;
          final bValue = b.profit is ProfitKnown
              ? (b.profit as ProfitKnown).amount
              : double.infinity;
          return aValue.compareTo(bValue);
        });

    return CommerceProfitContext(
      from: from,
      to: now,
      overall: overall,
      byProduct: byProduct,
      observedAt: now,
    );
  }

  final DateTime from;
  final DateTime to;

  /// Lợi nhuận thật của cả kỳ — hoặc lời khai *chưa tính được vì thiếu gì*.
  final TrueProfit overall;

  /// Từng sản phẩm, **lỗ lên đầu**.
  final List<ProductProfit> byProduct;

  final DateTime observedAt;

  /// Kênh này có thu phí sàn không — **hỏi lại `SalesChannel`, không tự trả lời**.
  ///
  /// ## Vì sao bản chép ở đây bị gỡ (WTM-442)
  ///
  /// Trước đây chỗ này giữ một bản sao của cùng luật ấy, kèm đúng câu cảnh báo
  /// này: *"thêm một sàn mới là thêm một dòng ở đây, và quên thêm nghĩa là lợi
  /// nhuận của sàn đó bị tính thừa mà không ai báo."*
  ///
  /// Lời cảnh báo đúng — và nó thành sự thật ngay lần đầu có người thêm sàn.
  /// Lúc thêm `ebay`/`amazon`/`shopify`/`lazada`, chỉ cần sửa **một** trong hai
  /// bản là hai bên lệch nhau lặng lẽ: `SalesChannel` nói có phí, chỗ này nói
  /// không, và lợi nhuận sai theo hướng dễ chịu.
  ///
  /// Một khái niệm một chủ (P-27/P-28). `SalesChannel.chargesPlatformFee` là
  /// chủ, và switch bên đó **không có nhánh `_`** nên quên phân loại là lỗi
  /// biên dịch, không phải một con số sai âm thầm.
  ///
  /// `null` = kênh **chưa ghi**, không phải "không có phí": không biết thì
  /// không đòi được dòng đối soát nào.
  static bool _chargesPlatformFees(SalesChannel? channel) =>
      channel?.chargesPlatformFee ?? false;

  /// Sản phẩm **doanh thu dương nhưng lời thật âm** — thứ không ai nhìn thấy
  /// nếu chỉ đọc bảng doanh thu.
  List<ProductProfit> get losingAfterFees => [
    for (final p in byProduct)
      if (p.isLosingAfterFees) p,
  ];

  /// Có đủ dữ liệu để nói gì chưa. `false` ⇒ màn hình nói *chưa đủ dữ liệu*,
  /// **không** hiện "0 đ" (ADR-TON-017: `insufficient` ≠ `empty`).
  bool get hasData => byProduct.isNotEmpty;
}

/// Lợi nhuận thật của một sản phẩm trong kỳ.
@immutable
class ProductProfit {
  const ProductProfit({
    required this.productId,
    required this.name,
    required this.revenue,
    required this.units,
    required this.profit,
    required this.orderCount,
  });

  final String productId;
  final String name;
  final double revenue;
  final int units;

  /// Có số, hoặc nói rõ thiếu gì. Không bao giờ là `0` thay cho "chưa biết".
  final TrueProfit profit;

  final int orderCount;

  double? get amount =>
      profit is ProfitKnown ? (profit as ProfitKnown).amount : null;

  /// Biên lợi nhuận thật trên doanh thu. `null` khi chưa tính được.
  double? get marginRatio {
    final value = amount;
    if (value == null || revenue == 0) return null;
    return value / revenue;
  }

  /// Bán được tiền nhưng **mất tiền**.
  bool get isLosingAfterFees {
    final value = amount;
    return value != null && revenue > 0 && value < 0;
  }

  /// Lãi gộp vẫn dương mà lời thật âm — trường hợp gây hiểu nhầm nhất, vì phép
  /// tính nhẩm của người bán cho ra một con số dương.
  bool grossLooksFineButLoses(double? costPerUnit) {
    if (costPerUnit == null || !isLosingAfterFees) return false;
    return revenue - costPerUnit * units > 0;
  }
}

class _ProductAccumulator {
  _ProductAccumulator({required this.productId, required this.name});

  final String productId;
  final String name;
  final Set<String> orders = {};

  double revenue = 0;
  int units = 0;
  double settlementImpact = 0;
  double? costPerUnit;

  ProductProfit build() {
    final cost = costPerUnit;
    return ProductProfit(
      productId: productId,
      name: name,
      revenue: revenue,
      units: units,
      orderCount: orders.length,
      // Chưa có giá vốn ⇒ **từ chối trả số**, đúng kỷ luật `TrueProfitRule`.
      // Coi bằng 0 sẽ biến mọi sản phẩm chưa nhập vốn thành sản phẩm siêu lời.
      profit: cost == null
          ? ProfitInsufficient(const [ProfitBlocker.missingCost])
          : ProfitKnown(
              revenue: revenue,
              cogs: cost * units,
              settlementImpact: settlementImpact,
            ),
    );
  }
}
