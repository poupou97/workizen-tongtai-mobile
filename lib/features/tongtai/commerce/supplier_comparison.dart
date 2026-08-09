import 'package:flutter/foundation.dart';

import 'commerce_models.dart';

/// **So sánh nhà cung cấp** — use case P0 của Founder (WTM-329 · §17).
///
/// Mở một sản phẩm ⇒ nhà cung cấp đang nhập · các lựa chọn khác · giá · MOQ ·
/// lead time · rating · ảnh hưởng tới lời.
///
/// ## ⛔ Không fake độ chính xác khi không có input
///
/// Founder §17 nói thẳng. Nên mọi con số ở đây đều có thể là **`null`**, và
/// `null` được nói ra thành *"chưa biết"* chứ không lấp bằng một giá trị trung
/// bình cho đẹp bảng.
///
/// Cụ thể: một nguồn thiếu `leadTimeDays` **không** bị đoán là "chắc bằng
/// nguồn kia". Nó hiện là chưa biết, và câu gợi ý sẽ không nhắc tới thời gian
/// giao — vì nói *"rẻ hơn 12% và giao nhanh hơn"* khi không biết giao bao lâu
/// là bịa ra một nửa lời khuyên.
///
/// ## Rẻ hơn không đồng nghĩa với tốt hơn
///
/// Rẻ hơn 12% mà giao chậm hơn 6 ngày là một **đánh đổi**, không phải một câu
/// trả lời. Lớp này nêu đánh đổi; người bán quyết.
@immutable
class SupplierComparison {
  const SupplierComparison({
    required this.productId,
    required this.current,
    required this.alternatives,
  });

  /// Dựng từ các báo giá của một sản phẩm.
  ///
  /// Mốc so sánh tìm theo thứ tự: [currentSupplierId] → [currentUnitCost] →
  /// báo giá rẻ nhất.
  ///
  /// [currentUnitCost] là **giá vốn đang ghi trên sản phẩm** — thứ người bán
  /// đang thật sự trả. Nó quan trọng vì `Product` không mang `supplierId`
  /// trong miền: không có mốc này thì mốc rơi về "báo giá rẻ nhất", và lúc đó
  /// **không lựa chọn nào rẻ hơn được** — engine im lặng vĩnh viễn dù dữ liệu
  /// có nguồn tốt hơn hẳn.
  factory SupplierComparison.from({
    required String productId,
    required List<SupplierQuote> quotes,
    String? currentSupplierId,
    double? currentUnitCost,
  }) {
    if (quotes.isEmpty) {
      return SupplierComparison(
        productId: productId,
        current: null,
        alternatives: const [],
      );
    }

    final sorted = [...quotes]
      ..sort((a, b) => a.unitCost.compareTo(b.unitCost));
    SupplierQuote? current;
    if (currentSupplierId != null) {
      for (final q in sorted) {
        if (q.supplierId == currentSupplierId) {
          current = q;
          break;
        }
      }
    }
    if (current == null && currentUnitCost != null) {
      // Khớp theo giá đang trả. Dung sai một đồng vì giá đi qua `double`.
      for (final q in sorted) {
        if ((q.unitCost - currentUnitCost).abs() < 1) {
          current = q;
          break;
        }
      }
    }
    current ??= sorted.first;

    return SupplierComparison(
      productId: productId,
      current: current,
      alternatives: [
        for (final q in sorted)
          if (q.id != current.id) SupplierOption(quote: q, against: current),
      ],
    );
  }

  final String productId;

  /// Nguồn đang nhập. `null` = chưa có báo giá nào.
  final SupplierQuote? current;

  /// Các lựa chọn khác, **rẻ nhất trước**.
  final List<SupplierOption> alternatives;

  bool get isComparable => current != null && alternatives.isNotEmpty;

  /// Lựa chọn đáng nói nhất: rẻ hơn nhiều nhất mà **không** chậm hơn.
  ///
  /// Không có cái nào như thế ⇒ `null`, và giao diện nói *"chưa có nguồn nào
  /// tốt hơn rõ ràng"* thay vì đẩy đại một cái tên lên.
  SupplierOption? get clearWin {
    SupplierOption? best;
    for (final option in alternatives) {
      if (!option.isCheaper) continue;
      // Chậm hơn ⇒ không phải "rõ ràng tốt hơn". Chưa biết nhanh chậm cũng
      // không: một đánh đổi không đo được thì không phải một chiến thắng.
      if (option.slowerByDays == null || option.slowerByDays! > 0) continue;
      if (best == null || option.savingRatio! > best.savingRatio!) {
        best = option;
      }
    }
    return best;
  }
}

/// Một lựa chọn thay thế, đã so với nguồn đang dùng.
@immutable
class SupplierOption {
  const SupplierOption({required this.quote, required this.against});

  final SupplierQuote quote;
  final SupplierQuote against;

  /// Rẻ hơn bao nhiêu phần. `null` khi mốc so sánh bằng 0 (không xảy ra với
  /// dữ liệu thật, nhưng chia cho 0 thì không cần dữ liệu thật mới nổ).
  double? get savingRatio {
    if (against.unitCost == 0) return null;
    return (against.unitCost - quote.unitCost) / against.unitCost;
  }

  bool get isCheaper => quote.unitCost < against.unitCost;

  /// Chậm hơn bao nhiêu ngày. **`null` = chưa biết**, không phải "bằng nhau".
  ///
  /// Đây là chỗ dễ nói dối nhất trong cả lớp: coi `null` là 0 sẽ biến một
  /// nguồn chưa ai hỏi giao bao lâu thành một nguồn "giao nhanh ngang".
  int? get slowerByDays {
    final mine = quote.leadTimeDays;
    final theirs = against.leadTimeDays;
    if (mine == null || theirs == null) return null;
    return mine - theirs;
  }

  /// Phải đặt thêm bao nhiêu so với nguồn hiện tại. `null` khi chưa biết MOQ.
  double? get extraMinimumOrder {
    final mine = quote.minimumOrderQuantity;
    final theirs = against.minimumOrderQuantity;
    if (mine == null || theirs == null) return null;
    final delta = mine - theirs;
    return delta <= 0 ? 0 : delta;
  }

  /// Tiết kiệm được bao nhiêu tiền nếu nhập [units] đơn vị.
  double savingFor(int units) => (against.unitCost - quote.unitCost) * units;

  /// Những gì **chưa biết** về lựa chọn này — để giao diện nói ra thay vì im
  /// lặng bỏ qua.
  List<String> get unknowns => [
    if (quote.leadTimeDays == null) 'lead_time',
    if (quote.minimumOrderQuantity == null) 'moq',
    if (quote.rating == null) 'rating',
  ];
}
