/// **Khoảnh khắc AHA đầu tiên** — WTM-354 (S5, Epic WTM-349).
///
/// Người bán vừa đưa dữ liệu vào. Màn này phải làm họ hiểu một điều:
///
/// > *"Tổng Tài không chờ tôi hỏi. Nó đã phân tích doanh nghiệp trước và đang
/// > cho tôi biết điều cần chú ý."*
///
/// ## Không có luật mới nào ở đây
///
/// Năm luật cần cho màn này đã chạy trong `main` từ trước:
///
/// | Phát hiện | Chủ |
/// |---|---|
/// | Sắp hết hàng | `StockAlertService` qua `BusinessBriefService` |
/// | Biên lợi nhuận mỏng | `Product.marginRatio` qua `BusinessBriefService` |
/// | Khách sắp tới nhịp mua lại | `rule:repeat-due` (WTM-180) |
/// | Khách quen đã im lặng | `CustomerRiskRule` |
/// | Mùa vụ lặp lại | `SeasonalRule` (WTM-180) |
///
/// File này **không tính lại** thứ gì trong số đó — nó gom, xếp ưu tiên, và
/// chuyển sang một hình dạng màn hình đọc được. Đó là kỷ luật P-27/P-28: một
/// khái niệm, một chỗ tính. Chỗ đúng để một kết luận sai là *luật*, không phải
/// bản gom của luật.
///
/// ## Ba trạng thái, không phải hai
///
/// * [FirstInsight.insufficient] — *chưa đủ dữ liệu để xét*
/// * [FirstInsight.ready] với danh sách **rỗng** — *đã xét, không có gì đáng
///   chú ý*
/// * [FirstInsight.ready] có phát hiện
///
/// Gộp hai trạng thái đầu là cách một màn hình im lặng biến thành một lời trấn
/// an sai. Đây là cùng khuôn mẫu với `SeasonalVerdict.ready` / `.insufficient`.
///
/// ## ⛔ Xu hướng kênh không có ở đây
///
/// Concept vẽ *"TikTok Shop tăng 27%"*. Có `vendor` trên đơn **không tương
/// đương** có một luật xu hướng kênh hợp lệ, và Epic này không viết luật đó
/// (§4.4, §24 của directive). Không luật ⇒ không dòng.
library;

import 'package:flutter/foundation.dart';

import '../agent/business_brief.dart';
import '../agent/business_brief_service.dart';
import '../core/tongtai_enums.dart';
import '../finance/true_profit.dart';
import '../inventory/product.dart';
import '../opportunity/seasonal_rule.dart';
import 'first_insight_input.dart';

/// Một phát hiện, đã kèm lý do và **tên luật đã sinh ra nó**.
@immutable
class FirstFinding {
  const FirstFinding({
    required this.kind,
    required this.severity,
    required this.headline,
    required this.reason,
    required this.ruleCode,
    required this.subjectKind,
    required this.subjectId,
  });

  /// Loại việc — dùng chung enum với brief, vì đây **là** cùng những việc ấy,
  /// chỉ nhìn ở một thời điểm khác trong đời người dùng.
  final BriefKind kind;

  final BriefSeverity severity;

  /// Một câu, có số của chính doanh nghiệp này.
  final String headline;

  /// Vì sao nghĩ vậy — câu người bán đọc được, lấy từ bằng chứng của luật chứ
  /// không viết lại. Viết lại là dựng danh sách lý do thứ hai, và hai danh sách
  /// lý do sẽ lệch nhau đúng vào ngày ai đó sửa một bên.
  final String reason;

  /// Mã luật, ví dụ `rule:repeat-due`.
  ///
  /// Không phải trang trí: một phát hiện không chỉ ra được luật nào sinh ra nó
  /// là một phát hiện không kiểm chứng được, và đó là định nghĩa của số bịa.
  final String ruleCode;

  final String subjectKind;
  final String subjectId;
}

/// Ảnh chụp nhanh doanh nghiệp. Mọi trường **có thể `null`**, và `null` nghĩa
/// *chưa tính được* — không phải *bằng không* (ADR-TON-023).
@immutable
class BusinessSnapshot {
  const BusinessSnapshot({
    required this.revenue,
    required this.orders,
    required this.profit,
    required this.inventoryValue,
    required this.profitBlockers,
  });

  static const BusinessSnapshot none = BusinessSnapshot(
    revenue: null,
    orders: 0,
    profit: null,
    inventoryValue: null,
    profitBlockers: <ProfitBlocker>[],
  );

  /// Doanh thu trong cửa sổ xét. `null` khi không có đơn nào.
  final double? revenue;

  final int orders;

  /// Lời thật — `null` khi `TrueProfitRule` **từ chối** vì thiếu dữ liệu.
  ///
  /// Từ chối chứ không đoán: một con số lợi nhuận thiếu giá vốn hoặc thiếu phí
  /// sàn luôn đẹp hơn sự thật, và đó là con số nguy hiểm nhất trong cả sản
  /// phẩm.
  final double? profit;

  /// Vì sao chưa tính được lời — hiện ra để người bán biết cần bổ sung gì.
  final List<ProfitBlocker> profitBlockers;

  /// Vốn đang nằm trong hàng. `null` khi chưa khai đủ tồn hoặc giá vốn.
  final double? inventoryValue;

  bool get isEmpty => revenue == null && orders == 0 && inventoryValue == null;
}

/// Kết quả — **hoặc** một kết luận, **hoặc** lời từ chối có lý do.
@immutable
class FirstInsight {
  const FirstInsight.ready({required this.findings, required this.snapshot})
    : insufficientReason = null;

  const FirstInsight.insufficient(this.insufficientReason)
    : findings = const [],
      snapshot = BusinessSnapshot.none;

  final List<FirstFinding> findings;
  final BusinessSnapshot snapshot;

  /// `null` = đã kết luận được. Khác `findings == []`: rỗng nghĩa *"đã xét và
  /// không có gì"*, còn đây là *"chưa đủ dữ liệu để xét"*.
  final String? insufficientReason;

  bool get isInsufficient => insufficientReason != null;

  /// Đã xét nhưng doanh nghiệp đang yên ổn — một câu trả lời hợp lệ, không
  /// phải một màn hỏng.
  bool get isQuiet => !isInsufficient && findings.isEmpty;
}

/// Bao nhiêu phát hiện là vừa đủ cho một màn onboarding.
///
/// Bốn, không phải mười: đây là màn **đầu tiên** người bán gặp, và một danh
/// sách dài hơn thế đọc như một bảng cảnh báo chứ không như một trợ lý vừa
/// hiểu ra điều gì đó.
const int kMaxFirstFindings = 4;

/// Engine — **giá trị vào, giá trị ra**, không chạm repository.
///
/// Cố ý nhận dữ liệu đã tải thay vì nhận repository: nó làm engine test được
/// bằng dữ liệu dựng tay, và giữ mọi quyết định "đọc gì từ đâu" ở một chỗ duy
/// nhất là provider. Cùng hình dạng với `BusinessBriefService`.
class FirstInsightEngine {
  const FirstInsightEngine({
    this.brief = const BusinessBriefService(maxItems: kMaxFirstFindings),
    this.seasonal = const SeasonalRule(),
    this.profitRule = const TrueProfitRule(),
    this.maxFindings = kMaxFirstFindings,
  });

  final BusinessBriefService brief;
  final SeasonalRule seasonal;
  final TrueProfitRule profitRule;
  final int maxFindings;

  FirstInsight analyse(FirstInsightInput input) {
    // ⭐ Không có gì để xét thì nói thế. Đây KHÔNG phải "doanh nghiệp của bạn
    // ổn" — chúng ta chưa nhìn thấy gì cả.
    if (input.products.isEmpty &&
        input.orders.isEmpty &&
        input.customers.isEmpty) {
      return const FirstInsight.insufficient('chưa có dữ liệu nào để xét');
    }

    final findings = <FirstFinding>[
      ..._fromBrief(input),
      ..._fromSeasonal(input),
    ];

    // Xếp: khẩn trước, rồi theo mã đối tượng. Tổng và lặp lại được, nên chạy
    // hai lần trên cùng dữ liệu cho cùng thứ tự — điều kiện để ảnh chụp demo
    // đối chiếu được với test.
    findings.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      if (bySeverity != 0) return bySeverity;
      final byRule = a.ruleCode.compareTo(b.ruleCode);
      return byRule != 0 ? byRule : a.subjectId.compareTo(b.subjectId);
    });

    return FirstInsight.ready(
      findings: List.unmodifiable(
        findings.length <= maxFindings
            ? findings
            : findings.sublist(0, maxFindings),
      ),
      snapshot: _snapshot(input),
    );
  }

  Iterable<FirstFinding> _fromBrief(FirstInsightInput input) sync* {
    final items = brief.derive(
      now: input.now,
      risk: input.risk,
      profiles: input.profiles,
      customers: input.customers,
      products: input.products,
      alerts: input.alerts,
    );

    for (final item in items) {
      yield FirstFinding(
        kind: item.kind,
        severity: item.severity,
        headline: item.headline,
        // Bằng chứng đầu tiên là lý do mạnh nhất — luật đã xếp nó lên đầu.
        // `detail` là câu người bán đọc; bằng chứng không có câu thì nói tên
        // luật còn hơn nói một chuỗi rỗng trông như màn hỏng.
        reason: item.evidence.first.detail ?? item.evidence.first.source,
        ruleCode: item.evidence.first.source,
        subjectKind: item.subjectKind,
        subjectId: item.subjectId,
      );
    }
  }

  Iterable<FirstFinding> _fromSeasonal(FirstInsightInput input) sync* {
    final verdict = seasonal.evaluate(
      orders: input.orders,
      products: input.products,
      now: input.now,
    );
    // Thiếu một năm lịch sử ⇒ luật **từ chối**, và từ chối không sinh ra dòng
    // nào. Nó cũng không làm cả màn thành `insufficient`: các luật khác vẫn
    // kết luận được.
    if (verdict.isInsufficient) return;

    for (final o in verdict.opportunities) {
      yield FirstFinding(
        kind: BriefKind.stockRunningOut,
        severity: BriefSeverity.warning,
        headline:
            '${o.product.name} — cùng kỳ năm ngoái bán ${o.unitsLastYear}, '
            'năm nay mới ${o.unitsThisYear}',
        reason: 'Còn thiếu ${o.shortfall} so với cùng kỳ',
        ruleCode: kSeasonalRuleCode,
        subjectKind: 'product',
        subjectId: o.product.id,
      );
    }
  }

  BusinessSnapshot _snapshot(FirstInsightInput input) {
    final billed = [
      for (final o in input.orders)
        if (o.status != OrderStatus.cancelled) o,
    ];
    final revenue = billed.fold<double>(0, (a, o) => a + o.totalAmount);

    final costByProduct = {for (final p in input.products) p.id: p.costPrice};
    // Khoá theo `đơn:mặt hàng` chứ không theo mã hàng: cùng một mặt hàng bán
    // trong hai đơn là hai dòng giá vốn, gộp lại là đếm thiếu.
    final itemCosts = <String, double?>{
      for (final o in billed)
        for (final item in o.items)
          '${o.id}:${item.productId}': switch (costByProduct[item.productId]) {
            final double c => c * item.quantity,
            _ => null,
          },
    };

    final profit = billed.isEmpty
        ? ProfitInsufficient(const [ProfitBlocker.missingCost])
        : profitRule.compute(
            revenue: revenue,
            itemCosts: itemCosts,
            lines: input.settlementLines,
            payouts: input.payouts,
            marketplaceOrdersWithoutFees: input.marketplaceOrdersWithoutFees,
          );

    return BusinessSnapshot(
      revenue: billed.isEmpty ? null : revenue,
      orders: billed.length,
      profit: switch (profit) {
        ProfitKnown(:final amount) => amount,
        ProfitInsufficient() => null,
      },
      profitBlockers: switch (profit) {
        ProfitInsufficient(:final blockers) => blockers,
        ProfitKnown() => const [],
      },
      inventoryValue: _inventoryValue(input.products),
    );
  }

  /// Vốn nằm trong hàng — `null` nếu **bất kỳ** mặt hàng còn tồn nào chưa khai
  /// giá vốn. Cộng phần biết được rồi gọi nó là "vốn tồn kho" sẽ ra một con số
  /// luôn nhỏ hơn sự thật, và không ai nhận ra vì nó vẫn có nội dung.
  double? _inventoryValue(List<Product> products) {
    var total = 0.0;
    var counted = 0;
    for (final p in products) {
      final qty = p.quantity;
      if (qty == null || qty <= 0) continue;
      final cost = p.costPrice;
      if (cost == null) return null;
      total += cost * qty;
      counted++;
    }
    return counted == 0 ? null : total;
  }
}

/// Lý do "chưa hề chạy phân tích" — dùng cho đường B, nơi engine **không được
/// gọi** chứ không phải chạy rồi không thấy gì.
///
/// Là một **mã**, không phải một câu: nó không bao giờ hiện lên màn hình (màn
/// đọc `isInsufficient` rồi tự chọn câu qua `AppStrings`), và một chuỗi tiếng
/// Việt nằm trong `ui/` là thứ governance l10n cấm — đúng như nó vừa bắt được.
const String kInsightNotAnalysed = 'not_analysed';

/// Mã luật mùa vụ. Hằng số để test và UI không chép tay chuỗi.
const String kSeasonalRuleCode = 'rule:seasonal';

/// Những luật được phép kết luận trong First Insight.
///
/// Mục kết thúc bằng `/` là một **họ** mã (`rule:business-alerts/revenue_drop`,
/// `…/orders_drop`, …) — cảnh báo vĩ mô sinh một mã cho mỗi loại, nên khai
/// từng cái sẽ hỏng ngay lần thêm loại thứ sáu.
///
/// Danh sách này **được test đối chiếu ngược với mã nguồn của luật**, không
/// phải chỉ với dữ liệu của một test. Một danh sách khai bằng tay chỉ chứng
/// minh được điều gì đó khi có thứ bắt nó lệch.
const Set<String> kFirstInsightRuleSources = {
  'rule:customer-value',
  'rule:repeat-due',
  'rule:stock-alert',
  'rule:margin',
  'rule:business-alerts/',
  kSeasonalRuleCode,
};

/// Mã luật này có được khai không.
bool isDeclaredRuleSource(String code) => kFirstInsightRuleSources.any(
  (declared) =>
      declared.endsWith('/') ? code.startsWith(declared) : code == declared,
);
