import 'package:flutter/foundation.dart';

import 'settlement.dart';

/// Vì sao chưa tính được lợi nhuận thật.
///
/// Mã cố định, không phải câu tiếng Việt: tầng UI dịch ra chữ người bán đọc
/// (ADR-TON-007), và telemetry chỉ mang mã (ADR-TON-017).
enum ProfitBlocker {
  /// Có món chưa nhập giá vốn. `costPrice` null = **chưa nhập**, không phải 0.
  missingCost('missing_cost'),

  /// Có voucher/discount chưa biết ai trả.
  unknownFunding('unknown_funding'),

  /// Lô đối soát lệch quá ngưỡng chưa giải thích được.
  unexplainedDelta('unexplained_delta'),

  /// ⭐ Có đơn **bán trên sàn** mà chưa có khoản phí nào của sàn (WTM-322).
  ///
  /// Đây là con số nguy hiểm nhất app có thể in ra: nhập file đơn hàng mà chưa
  /// nhập báo cáo thu nhập thì **doanh thu đúng, lợi nhuận sai** — và sai theo
  /// hướng tâng bốc, tức là kiểu sai không ai đi kiểm.
  ///
  /// Không suy ra từ *"không có dòng phí nào"* mà từ **kênh bán**: một đơn bán
  /// tại quầy không có phí sàn là chuyện bình thường, một đơn Shopee thì không.
  missingMarketplaceFees('missing_marketplace_fees');

  const ProfitBlocker(this.code);

  final String code;
}

/// Kết quả tính lợi nhuận thật — **có số, hoặc nói rõ vì sao chưa có**.
///
/// Kiểu sealed chứ không phải `double?`: một `null` ở chỗ gọi rất dễ thành
/// `?? 0`, và `0` thì hiện lên màn hình như một con số thật. Buộc phải phân
/// nhánh là cách duy nhất khiến "chưa biết" không lặng lẽ thành "bằng không".
@immutable
sealed class TrueProfit {
  const TrueProfit();
}

/// Tính được.
@immutable
class ProfitKnown extends TrueProfit {
  const ProfitKnown({
    required this.revenue,
    required this.cogs,
    required this.settlementImpact,
  });

  final double revenue;

  /// Giá vốn hàng bán.
  final double cogs;

  /// Tổng đóng góp có dấu của mọi khoản đối soát — chi âm, thu dương.
  final double settlementImpact;

  double get amount => revenue - cogs + settlementImpact;
}

/// Chưa tính được, và **nói rõ thiếu gì**.
///
/// Không trả doanh thu rồi gọi nó là lợi nhuận — đó là kỷ luật `null` ≠ `0` áp
/// cho con số quan trọng nhất trong app.
@immutable
class ProfitInsufficient extends TrueProfit {
  const ProfitInsufficient(this.blockers)
    : assert(blockers.length > 0, 'insufficient thì phải nói được thiếu gì');

  final List<ProfitBlocker> blockers;
}

/// Rule Twin của lợi nhuận thật (ADR-TON-016 — chạy không cần AI/mạng/khoá).
///
/// ```
/// lợi nhuận thật = doanh thu − giá vốn − Σ chi + Σ thu
/// ```
///
/// **Từ chối trả số** khi thiếu bất kỳ mảnh nào. Đây là điểm khác biệt với
/// công thức trên giấy: công thức luôn ra một số, còn hệ thống thì phải biết
/// khi nào số đó vô nghĩa.
class TrueProfitRule {
  const TrueProfitRule({this.deltaTolerance = 1000});

  /// Lệch dưới ngưỡng này coi như làm tròn của sàn, không chặn.
  ///
  /// 1.000 đ: đủ nhỏ để một khoản phí thật không lọt qua, đủ lớn để không chặn
  /// vì lẻ đồng. Ngưỡng nằm ở đây, không rải trong UI.
  final double deltaTolerance;

  /// [itemCosts] là giá vốn từng món — `null` cho một món nghĩa là **chưa
  /// nhập**, và đó là lý do trả `insufficient` chứ không phải coi bằng 0.
  TrueProfit compute({
    required double revenue,
    required Map<String, double?> itemCosts,
    required List<SettlementLine> lines,
    List<Payout> payouts = const [],
    int marketplaceOrdersWithoutFees = 0,
  }) {
    final blockers = <ProfitBlocker>[];

    if (marketplaceOrdersWithoutFees > 0) {
      blockers.add(ProfitBlocker.missingMarketplaceFees);
    }

    if (itemCosts.isEmpty || itemCosts.values.any((c) => c == null)) {
      blockers.add(ProfitBlocker.missingCost);
    }
    if (lines.any((l) => !l.fundingIsKnown)) {
      blockers.add(ProfitBlocker.unknownFunding);
    }
    if (payouts.any((p) => (p.reconciledDelta?.abs() ?? 0) > deltaTolerance)) {
      blockers.add(ProfitBlocker.unexplainedDelta);
    }

    if (blockers.isNotEmpty) return ProfitInsufficient(blockers);

    return ProfitKnown(
      revenue: revenue,
      cogs: itemCosts.values.fold<double>(0, (a, c) => a + c!),
      settlementImpact: lines.fold<double>(0, (a, l) => a + l.signedImpact),
    );
  }
}
