import 'package:meta/meta.dart';

import 'product.dart';

/// **Kinh tế đơn vị của một sản phẩm** — WTM-420 (concept-1 `cp6`, tab Tài chính).
///
/// Trả lời đúng ba câu, và **từ chối** câu nào chưa đủ dữ liệu:
///
///   * bán một cái lãi bao nhiêu,
///   * biên lợi nhuận bao nhiêu phần trăm,
///   * bán hết chỗ đang tồn thì lãi bao nhiêu (**dự kiến**, không phải đo).
///
/// ## ⛔ Thiếu giá vốn ⇒ KHÔNG có lợi nhuận, không phải lợi nhuận bằng 0
///
/// Đây là chỗ luật này có thể nói dối, và nó nói dối **theo hướng dễ chịu**:
/// coi giá vốn bằng 0 thì mọi sản phẩm đều lãi đúng bằng giá bán, biên 100%, và
/// người bán tin rằng mình đang lãi to. Cùng kỷ luật `SlowMovingCapital`
/// (WTM-411), `SupplierOption` (WTM-409), `OpportunityFactor` (WTM-408).
///
/// ## Bán lỗ là một sự thật, không phải một lỗi
///
/// `costPrice > sellingPrice` cho ra số âm, và số âm ấy **được trả về**. Người
/// bán cần thấy đúng chỗ mình đang chảy máu; kẹp về 0 là giấu.
@immutable
class ProductUnitEconomics {
  const ProductUnitEconomics({
    required this.sellingPrice,
    required this.costPrice,
    required this.stockOnHand,
  });

  factory ProductUnitEconomics.of(Product product) => ProductUnitEconomics(
    sellingPrice: product.pricePerUnit,
    costPrice: product.costPrice,
    stockOnHand: product.quantity,
  );

  final double sellingPrice;

  /// `null` = **chưa khai**, không phải 0.
  final double? costPrice;

  /// `null` = chưa khai tồn kho.
  final int? stockOnHand;

  bool get hasCost => costPrice != null;

  /// Lãi trên mỗi sản phẩm. `null` khi chưa khai giá vốn.
  double? get profitPerUnit {
    final cost = costPrice;
    return cost == null ? null : sellingPrice - cost;
  }

  /// Biên lợi nhuận, theo **giá bán**. `null` khi chưa khai giá vốn.
  ///
  /// ⚠️ Giá bán bằng 0 cũng trả `null`: chia cho 0 ra vô cực, mà "biên lợi
  /// nhuận vô cực" là một câu vô nghĩa in lên màn hình.
  double? get marginPercent {
    final profit = profitPerUnit;
    if (profit == null || sellingPrice <= 0) return null;
    return profit / sellingPrice * 100;
  }

  /// Bán hết chỗ **đang tồn** thì lãi bao nhiêu — con số **DỰ KIẾN**.
  ///
  /// Neo vào tồn kho thật thay vì để người bán gõ một số bất kỳ: một dự phóng
  /// dựa trên con số có thật vẫn là dự phóng, nhưng nó không mời người ta mơ.
  /// `null` khi thiếu giá vốn hoặc chưa khai tồn.
  double? get projectedProfitOnStock {
    final unit = profitPerUnit;
    final stock = stockOnHand;
    if (unit == null || stock == null || stock <= 0) return null;
    return unit * stock;
  }
}
