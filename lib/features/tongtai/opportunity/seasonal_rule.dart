import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import '../inventory/product.dart';
import '../orders/order.dart';

/// **Mùa vụ lặp lại** — WTM-180 story 4.
///
/// Câu hỏi nó trả lời: *"cùng kỳ năm ngoái tôi bán chạy gì, mà năm nay chưa
/// chuẩn bị?"*
///
/// ## Vì sao đây là giá trị giao được NGAY
///
/// Không cần khoá API, không cần mạng, không cần sàn. Toàn bộ tín hiệu nằm
/// trong đơn hàng của chính người bán — thứ họ đã có. Rule Twin tính, AI chỉ
/// giải thích nếu người bán hỏi thêm.
///
/// ## Ba cái chốt chống bịa
///
/// Một luật mùa vụ rất dễ nói bừa, vì mắt người nhìn đâu cũng ra chu kỳ. Ba
/// điều kiện dưới đây là thứ ngăn nó:
///
/// 1. **Đủ một năm mới được kết luận.** Thiếu là [SeasonalVerdict.insufficient]
///    — *từ chối trả lời* chứ không đoán. Đây là kỷ luật Rule Twin của
///    ADR-TON-016: cấm bịa số khi thiếu dữ liệu.
/// 2. **Phải bán đủ nhiều năm ngoái** ([minimumUnits]). Một đơn lẻ không phải
///    mùa vụ, nó là một đơn lẻ.
/// 3. **Năm nay phải đang hụt thật.** Bán tốt năm ngoái mà năm nay vẫn đang
///    bán tốt thì không có việc gì để làm — nói ra chỉ là tiếng ồn.
@immutable
class SeasonalOpportunity {
  const SeasonalOpportunity({
    required this.product,
    required this.unitsLastYear,
    required this.unitsThisYear,
    required this.windowStart,
    required this.windowEnd,
  });

  final Product product;

  /// Số lượng đã bán trong **cùng cửa sổ này năm ngoái**.
  final int unitsLastYear;

  /// Số lượng đã bán trong cửa sổ năm nay, tính tới hôm nay.
  final int unitsThisYear;

  final DateTime windowStart;
  final DateTime windowEnd;

  /// Còn thiếu bao nhiêu so với cùng kỳ — con số để người bán quyết nhập bao
  /// nhiêu, chứ không phải một lời khuyên chung chung.
  int get shortfall => (unitsLastYear - unitsThisYear).clamp(0, 1 << 30);
}

/// Kết quả của luật — **hoặc** một kết luận, **hoặc** lời từ chối có lý do.
@immutable
class SeasonalVerdict {
  const SeasonalVerdict.ready(this.opportunities) : insufficientReason = null;

  const SeasonalVerdict.insufficient(this.insufficientReason)
    : opportunities = const [];

  final List<SeasonalOpportunity> opportunities;

  /// `null` = đã kết luận được. Khác `[]`: rỗng nghĩa là *"đã xét và không có
  /// gì"*, còn đây là *"chưa đủ dữ liệu để xét"*. Hai câu đó khác nhau, và gộp
  /// chúng lại là cách một màn hình im lặng biến thành một lời trấn an sai.
  final String? insufficientReason;

  bool get isInsufficient => insufficientReason != null;
}

class SeasonalRule {
  const SeasonalRule({
    this.lookAheadDays = 30,
    this.toleranceDays = 10,
    this.minimumUnits = 3,
    this.maxResults = 3,
  });

  /// Nhìn trước bao nhiêu ngày — mùa vụ chỉ đáng nói khi còn kịp nhập hàng.
  final int lookAheadDays;

  /// Nới cửa sổ năm ngoái ra hai phía, vì mùa vụ không rơi đúng ngày.
  final int toleranceDays;

  /// Bán dưới mức này năm ngoái thì không gọi là mùa vụ.
  final int minimumUnits;

  final int maxResults;

  SeasonalVerdict evaluate({
    required List<CustomerOrder> orders,
    required List<Product> products,
    required DateTime now,
  }) {
    if (orders.isEmpty) {
      return const SeasonalVerdict.insufficient('chưa có đơn hàng nào');
    }

    // ⭐ Đủ một năm mới được kết luận. Thiếu thì **từ chối**, không đoán:
    // "cùng kỳ năm ngoái" mà không có năm ngoái thì không có gì để so.
    var earliest = orders.first.date;
    for (final o in orders) {
      if (o.date.isBefore(earliest)) earliest = o.date;
    }
    final windowStart = now;
    final windowEnd = now.add(Duration(days: lookAheadDays));
    final lastYearStart = _shiftYear(
      windowStart,
    ).subtract(Duration(days: toleranceDays));
    final lastYearEnd = _shiftYear(
      windowEnd,
    ).add(Duration(days: toleranceDays));

    if (earliest.isAfter(lastYearStart)) {
      return const SeasonalVerdict.insufficient(
        'chưa có đủ một năm lịch sử để so cùng kỳ',
      );
    }

    final soldLastYear = _unitsSold(orders, lastYearStart, lastYearEnd);
    final soldThisYear = _unitsSold(
      orders,
      windowStart.subtract(Duration(days: toleranceDays)),
      now,
    );
    final byId = {for (final p in products) p.id: p};

    final out = <SeasonalOpportunity>[];
    for (final entry in soldLastYear.entries) {
      if (entry.value < minimumUnits) continue;
      final product = byId[entry.key];
      if (product == null) continue;

      final thisYear = soldThisYear[entry.key] ?? 0;
      // Năm nay vẫn đang bán tốt ⇒ không có việc gì để làm.
      if (thisYear >= entry.value) continue;

      // …và chỉ đáng nói khi **hàng không đủ để bắt kịp**. `quantity == null`
      // là "chưa khai tồn", không phải "hết hàng" (ADR-TON-023) — chưa biết
      // thì không kết luận thiếu.
      final stock = product.quantity;
      if (stock != null && stock >= entry.value - thisYear) continue;

      out.add(
        SeasonalOpportunity(
          product: product,
          unitsLastYear: entry.value,
          unitsThisYear: thisYear,
          windowStart: windowStart,
          windowEnd: windowEnd,
        ),
      );
    }

    out.sort((a, b) {
      final byGap = b.shortfall.compareTo(a.shortfall);
      // Hoà thì xếp theo mã: cùng dữ liệu luôn cho cùng thứ tự.
      return byGap != 0 ? byGap : a.product.id.compareTo(b.product.id);
    });
    return SeasonalVerdict.ready(out.take(maxResults).toList(growable: false));
  }

  static Map<String, int> _unitsSold(
    List<CustomerOrder> orders,
    DateTime from,
    DateTime to,
  ) {
    final units = <String, int>{};
    for (final o in orders) {
      // Đơn huỷ không phải nhu cầu — cộng nó vào là đếm một lần mua không xảy
      // ra thành tín hiệu mùa vụ.
      if (o.status == OrderStatus.cancelled) continue;
      if (o.date.isBefore(from) || o.date.isAfter(to)) continue;
      for (final item in o.items) {
        units[item.productId] = (units[item.productId] ?? 0) + item.quantity;
      }
    }
    return units;
  }

  /// Lùi đúng một năm, giữ nguyên ngày/tháng. Ngày 29/2 lùi về năm thường sẽ
  /// tự tràn sang 1/3 — chấp nhận được, vì cửa sổ còn nới ±[toleranceDays].
  static DateTime _shiftYear(DateTime d) =>
      DateTime(d.year - 1, d.month, d.day, d.hour, d.minute);
}
