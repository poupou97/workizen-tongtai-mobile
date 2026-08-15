import 'package:flutter/foundation.dart';

import 'product.dart';

/// **Vốn đang chôn trong hàng chậm bán** — WTM-411 (concept-1 `cp3`).
///
/// `ANALYSIS.md` gọi đúng giá trị của nó: *"đúng chỗ người bán Việt Nam **chôn
/// tiền mà không nhìn thấy**"*. Kho đầy trông như tài sản; phần không bán được
/// là tiền đã nằm xuống.
///
/// ## ⛔ `costPrice == null` KHÔNG được cộng thành 0
///
/// Đây là chỗ duy nhất luật này có thể nói dối, và nó nói dối **theo hướng dễ
/// chịu**: một mặt hàng chưa khai giá vốn mà tính thành 0 sẽ cho ra tổng **thấp
/// hơn sự thật**, và người bán yên tâm nhầm — tệ hơn hẳn một tổng lớn gây lo.
///
/// Nên mặt hàng thiếu giá vốn **không vào tổng** và được **đếm riêng**
/// ([unknownCostCount]), để giao diện nói ra: *"còn N mặt hàng chưa khai giá
/// vốn"*. Cùng kỷ luật `null ≠ 0` mà `Product.costPrice` (WTM-204),
/// `SupplierOption` (WTM-409) và `OpportunityFactor` (WTM-408) đều theo.
///
/// ## Một chủ cho ngưỡng "chậm bán"
///
/// Lớp này **không tự đặt ngưỡng**. Nó nhận [soldProductIds] — tập mặt hàng đã
/// bán trong cửa sổ — từ phía gọi, và cửa sổ ấy có đúng một chủ:
/// `CommerceProfitContext.from`/`to`.
///
/// ⚠️ Trước WTM-411, ngưỡng này được khai ở **bốn** chỗ và chỉ **một** chỗ có
/// thật: một trường `deadStockDays = 90` không dòng mã nào đọc · cửa sổ 30 ngày
/// của bối cảnh lời · một điều kiện `.abs() >= 0` trông như lọc ngày nhưng luôn
/// đúng · và số `30` viết cứng trong câu thông báo. Đừng thêm chủ thứ hai.
@immutable
class SlowMovingCapital {
  const SlowMovingCapital({
    required this.tiedUpAmount,
    required this.slowMovingCount,
    required this.unknownCostCount,
    required this.windowDays,
    this.productIds = const {},
  });

  static const SlowMovingCapital none = SlowMovingCapital(
    tiedUpAmount: 0,
    slowMovingCount: 0,
    unknownCostCount: 0,
    windowDays: 0,
  );

  /// Tính từ danh mục thật.
  ///
  /// [soldProductIds] = mặt hàng **đã bán** trong cửa sổ [windowDays]. Mặt hàng
  /// còn tồn mà không nằm trong tập ấy là hàng chậm bán.
  factory SlowMovingCapital.from({
    required Iterable<Product> products,
    required Set<String> soldProductIds,
    required int windowDays,
  }) {
    var amount = 0.0;
    var unknownCost = 0;
    final ids = <String>{};

    for (final p in products) {
      final quantity = p.quantity;
      // Không còn tồn thì không có vốn nào đang nằm — kể cả khi lâu rồi không
      // bán. "Hết hàng" và "hàng nằm" là hai chuyện khác nhau.
      if (quantity == null || quantity <= 0) continue;
      if (soldProductIds.contains(p.id)) continue;

      ids.add(p.id);
      final cost = p.costPrice;
      if (cost == null) {
        unknownCost++;
        continue;
      }
      amount += quantity * cost;
    }

    return SlowMovingCapital(
      tiedUpAmount: amount,
      slowMovingCount: ids.length,
      unknownCostCount: unknownCost,
      windowDays: windowDays,
      productIds: Set.unmodifiable(ids),
    );
  }

  /// Tổng tiền **đo được** đang nằm trong hàng chậm bán.
  ///
  /// ⚠️ Chỉ cộng những mặt hàng **có** giá vốn. Xem [unknownCostCount] để biết
  /// con số này còn thiếu bao nhiêu mặt hàng.
  final double tiedUpAmount;

  /// Số mặt hàng còn tồn mà không bán được cái nào trong cửa sổ.
  final int slowMovingCount;

  /// Trong số đó, bao nhiêu mặt hàng **chưa khai giá vốn** ⇒ không tính được
  /// vào [tiedUpAmount].
  final int unknownCostCount;

  /// Độ dài cửa sổ, để câu thông báo nói đúng con số nó dựa vào — thay vì viết
  /// cứng một số rồi lệch khi ai đó đổi cửa sổ.
  final int windowDays;

  /// Đúng những mặt hàng đã đếm ở [slowMovingCount].
  ///
  /// Có mặt ở đây để thẻ **làm được việc gì đó**, không chỉ để đọc: bấm vào là
  /// danh sách Kho lọc về đúng tập này. Một con số tiền đang nằm mà không dẫn
  /// tới danh sách thì chỉ là một nỗi lo mới (ANALYSIS.md điều 2).
  final Set<String> productIds;

  bool get hasSlowMoving => slowMovingCount > 0;

  /// Tổng đang **thiếu** một phần vì có mặt hàng chưa khai giá vốn.
  bool get isPartial => unknownCostCount > 0;
}
