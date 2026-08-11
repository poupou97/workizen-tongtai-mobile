import '../action/business_action.dart';
import '../analytics/customer_rfm.dart';
import '../consumer/customer.dart';
import '../capability/customer_capability.dart';
import '../consumer/identity_evidence.dart';
import '../core/tongtai_formatters.dart';
import '../inventory/product.dart';
import '../inventory/stock_alert.dart';
import '../inventory/stock_alert_service.dart';
import '../predictive/business_alerts_rule.dart';
import '../predictive/customer_risk_rule.dart';
import '../proposal/proposed_change.dart';
import 'business_brief.dart';

/// Dựng **"có gì đáng chú ý hôm nay"** từ Rule Twin — WTM-303.
///
/// ## Hàm thuần, và điều đó quyết định trải nghiệm
///
/// Service này không chạm cơ sở dữ liệu, không gọi mạng, không cần khoá AI.
/// Nghĩa là brief hiện ra **ngay khi mở app**, kể cả ở chế độ máy bay — đúng
/// cảm giác Founder mô tả: *"Tổng Tài đã nhìn doanh nghiệp trước khi tôi mở
/// app."*
///
/// AI được phép **giải thích thêm** một [BriefItem]; nó không bao giờ sinh ra
/// một item, đổi một con số, hay đổi thứ tự (ADR-TON-016 — Rule Twin
/// authoritative).
///
/// ## Không luật dẫn xuất nào được viết lại ở đây
///
/// Rủi ro khách: [CustomerRiskRule]. Sắp hết hàng: [StockAlertService] (chủ sở
/// hữu duy nhất của khái niệm, WTM-213). Biên lợi nhuận: [Product.marginRatio].
/// Service này chỉ **dịch** kết quả của chúng thành câu và đề nghị.
///
/// Đó là kỷ luật P-27/P-28 mà repo này đã dọn bốn lần: một khái niệm, một chỗ
/// tính. Chỗ đúng để một brief sai là *luật*, không phải bản dịch của luật.
class BusinessBriefService {
  const BusinessBriefService({
    this.maxItems = 5,
    this.thinMarginRatio = kThinMarginRatio,
    this.repeatDueFrom = 0.8,
    this.repeatDueTo = 1.25,
    this.minimumOrdersForCadence = 3,
  });

  /// Cửa sổ "sắp tới nhịp", đo bằng `gapRatio` của chính khách đó.
  ///
  /// Dưới [repeatDueFrom] là còn sớm — nhắc lúc đó chỉ làm phiền. Trên
  /// [repeatDueTo] là đã trễ, và khi đó khách thuộc về mục *khách đã im lặng*
  /// chứ không phải mục này.
  final double repeatDueFrom;
  final double repeatDueTo;

  /// Hai đơn cho ra một khoảng cách, và một khoảng cách không phải một thói
  /// quen. Dưới mức này thì "nhịp mua" chưa đủ căn cứ để nhắc.
  final int minimumOrdersForCadence;

  /// Bao nhiêu việc là vừa đủ cho một buổi sáng.
  ///
  /// Không phải con số tuỳ tiện: một danh sách dài hơn thế thì người bán không
  /// đọc, và một trợ lý nói mười việc cùng lúc thì không giúp ai quyết được gì.
  final int maxItems;

  /// Dưới mức này thì coi như bán gần bằng giá vốn.
  final double thinMarginRatio;

  /// Biên lợi nhuận mỏng — 15%.
  static const double kThinMarginRatio = 0.15;

  /// Nhiều nhất bao nhiêu khách được nhắc trong một brief.
  ///
  /// Một brief nói *"chín khách sắp rời"* là một brief người bán bỏ qua. Rule
  /// Twin vẫn xếp hạng cả danh bạ; brief chỉ mời quyết việc **cấp nhất**.
  static const int kMaxCustomerItems = 2;

  /// Nhiều nhất bao nhiêu mặt hàng sắp hết được nhắc.
  static const int kMaxStockItems = 2;

  /// Dựng danh sách việc, đã sắp xếp, đã cắt còn [maxItems].
  ///
  /// [risk] `null` = Rule Twin từ chối trả lời vì thiếu dữ liệu — và **từ chối
  /// là một câu trả lời** (ADR-TON-017). Khi đó không có việc nào về khách,
  /// chứ không phải "không có khách nào rủi ro".
  List<BriefItem> derive({
    required DateTime now,
    CustomerRiskAssessment? risk,
    List<CustomerRfm> profiles = const [],
    List<Customer> customers = const [],
    List<Product> products = const [],
    List<BusinessAlert> alerts = const [],
  }) {
    final byId = {for (final c in customers) c.id: c};
    final cadence = {for (final p in profiles) p.customerId: p};

    final items = <BriefItem>[
      ..._customerItems(risk, byId, cadence, now),
      ..._repeatDueItems(risk, byId, profiles, now),
      ..._stockItems(products, now),
      ..._marginItems(products, now),
      ..._signalItems(alerts, now),
    ]..sort(compareBriefItems);

    return List.unmodifiable(
      items.length <= maxItems ? items : items.sublist(0, maxItems),
    );
  }

  // ── Khách quen đã im lặng ────────────────────────────────────────────────

  Iterable<BriefItem> _customerItems(
    CustomerRiskAssessment? risk,
    Map<String, Customer> byId,
    Map<String, CustomerRfm> cadence,
    DateTime now,
  ) sync* {
    if (risk == null) return;

    // `winBackCandidate` là chính sách đã có chủ (`isWinBackCandidate`) — brief
    // không tự đặt ngưỡng thứ hai cho câu hỏi "có đáng đuổi theo không".
    final worth = risk.entries
        .where((e) => e.winBackCandidate)
        .take(kMaxCustomerItems);

    for (final entry in worth) {
      final customer = byId[entry.customerId];
      final days = entry.recencyDays;
      if (days == null) continue; // chưa từng mua ⇒ không phải "đã im lặng"

      final name = customer?.name;
      final gap = cadence[entry.customerId]?.medianGapDays;

      // Một nguồn quan sát: sổ đơn hàng của chính người bán. Ba dòng dưới là
      // BA CÂU về CÙNG MỘT lần nhìn, nên luật gộp theo `source` cho chúng
      // thành một tín hiệu — đúng như phải thế (WTM-298 luật 1).
      const source = 'rule:customer-risk';
      final evidence = <IdentityEvidence>[
        IdentityEvidence(
          kind: IdentityEvidenceKind.orderHistoryMatch,
          source: source,
          detail: 'Đã mua ${entry.lifetimeOrders} lần',
        ),
        if (gap != null)
          IdentityEvidence(
            kind: IdentityEvidenceKind.orderHistoryMatch,
            source: source,
            detail: 'Thường quay lại sau khoảng $gap ngày',
          ),
        IdentityEvidence(
          kind: IdentityEvidenceKind.orderHistoryMatch,
          source: source,
          detail: 'Lần mua gần nhất cách đây $days ngày',
        ),
        IdentityEvidence(
          kind: IdentityEvidenceKind.businessRecordObservation,
          source: 'rule:customer-value',
          detail:
              'Đã chi tổng cộng ${TongtaiFormatters.vnd(entry.lifetimeValue)}',
        ),
      ];

      yield BriefItem(
        kind: BriefKind.customerAtRisk,
        severity: entry.stage == CustomerLifecycleStage.churned
            ? BriefSeverity.critical
            : BriefSeverity.warning,
        subjectKind: 'customer',
        subjectId: entry.customerId,
        subjectLabel: name,
        headline: name == null
            ? 'Một khách quen đã $days ngày chưa quay lại'
            : '$name đã $days ngày chưa quay lại',
        suggestion: 'Nhắn hỏi thăm và gợi ý mặt hàng họ hay mua',
        evidence: evidence,
        move: const DoSomething(
          actionType: BusinessActionType.customerSendMessage,
          // Chưa connector nào chạy thật. `vendor` phải nói đúng điều đó —
          // xem `ActionVendor.demo` (WTM-305).
          vendor: ActionVendor.demo,
        ),
        observedAt: now,
      );
    }
  }

  // ── Khách sắp tới nhịp mua lại (WTM-180 story 2, mặt kia) ────────────────

  /// Khách **sắp** quay lại — nhắn trước khi họ quên.
  ///
  /// ## Cùng một tín hiệu, hai đầu khác nhau
  ///
  /// `_customerItems` ở trên dùng `gapRatio` để báo khách **đã** im lặng quá
  /// lâu. Đó là tin đến **sau** khi mất khách. Cùng con số đó, đọc ở đoạn
  /// `≈ 1.0`, lại là thứ đến **trước**: khách đang tới đúng nhịp mua của chính
  /// họ, và một tin nhắn lúc này rẻ hơn nhiều so với một chiến dịch kéo khách
  /// đã đi.
  ///
  /// ## Ba điều kiện, và vì sao
  ///
  /// 1. **Phải có nhịp thật** — `medianGapDays` null nghĩa là chưa đủ đơn để
  ///    biết khách này mua theo chu kỳ nào. Chưa biết thì không nhắc.
  /// 2. **Đủ số lần mua** ([minimumOrdersForCadence]) — hai đơn cho ra một
  ///    khoảng cách, và một khoảng cách không phải một thói quen.
  /// 3. **Chưa bị đánh dấu rủi ro** — khách đã quá hạn thuộc về mục ở trên.
  ///    Báo cả hai chỗ là một khách hiện hai lần với hai lời khuyên khác nhau,
  ///    và người bán không biết tin cái nào (P-27: một chuyện, một mục).
  Iterable<BriefItem> _repeatDueItems(
    CustomerRiskAssessment? risk,
    Map<String, Customer> byId,
    List<CustomerRfm> profiles,
    DateTime now,
  ) sync* {
    final alreadyFlagged = {
      for (final e in risk?.entries ?? const []) e.customerId,
    };

    for (final p in profiles) {
      if (alreadyFlagged.contains(p.customerId)) continue;
      if (p.frequency < minimumOrdersForCadence) continue;

      final gap = p.medianGapDays;
      final ratio = p.gapRatio;
      final days = p.recencyDays;
      if (gap == null || ratio == null || days == null) continue;
      if (ratio < repeatDueFrom || ratio > repeatDueTo) continue;

      final name = byId[p.customerId]?.name;
      yield BriefItem(
        kind: BriefKind.customerAtRisk,
        // Đây là **cơ hội**, không phải báo động: khách chưa mất, chỉ là sắp
        // tới lúc. Đánh severity cao hơn sẽ đẩy nó lên trên những việc đang
        // thật sự cháy.
        severity: BriefSeverity.info,
        subjectKind: 'customer',
        subjectId: p.customerId,
        subjectLabel: name,
        headline: name == null
            ? 'Một khách quen thường mua lại sau ${gap.round()} ngày '
                  '— hôm nay là ngày thứ $days'
            : '$name thường mua lại sau ${gap.round()} ngày '
                  '— hôm nay là ngày thứ $days',
        suggestion: 'Nhắn trước khi họ quên, kèm mặt hàng họ hay mua',
        evidence: [
          IdentityEvidence(
            kind: IdentityEvidenceKind.orderHistoryMatch,
            source: 'rule:repeat-due',
            detail: 'Đã mua ${p.frequency} lần',
          ),
          IdentityEvidence(
            kind: IdentityEvidenceKind.orderHistoryMatch,
            source: 'rule:repeat-due',
            detail: 'Nhịp mua của riêng khách này: ${gap.round()} ngày',
          ),
          IdentityEvidence(
            kind: IdentityEvidenceKind.orderHistoryMatch,
            source: 'rule:repeat-due',
            detail: 'Lần mua gần nhất cách đây $days ngày',
          ),
        ],
        move: const DoSomething(
          actionType: BusinessActionType.customerSendMessage,
          vendor: ActionVendor.demo,
        ),
        observedAt: now,
      );
    }
  }

  // ── Sắp hết hàng ─────────────────────────────────────────────────────────

  Iterable<BriefItem> _stockItems(List<Product> products, DateTime now) sync* {
    final service = StockAlertService(products);
    for (final alert in service.alerts.take(kMaxStockItems)) {
      final p = alert.product;
      final out = alert.level == StockAlertLevel.outOfStock;

      yield BriefItem(
        kind: BriefKind.stockRunningOut,
        severity: out ? BriefSeverity.critical : BriefSeverity.warning,
        subjectKind: 'product',
        subjectId: p.id,
        subjectLabel: p.name,
        headline: out
            ? '${p.name} đã hết hàng'
            : '${p.name} sắp hết — còn ${alert.quantity}',
        suggestion: out
            ? 'Nhập thêm ngay, mỗi ngày hết hàng là một ngày mất đơn'
            : 'Nhập thêm ${alert.shortfall} để về lại mức an toàn',
        evidence: [
          IdentityEvidence(
            kind: IdentityEvidenceKind.businessRecordObservation,
            source: 'rule:stock-alert',
            detail: 'Còn ${alert.quantity} trong kho',
          ),
          IdentityEvidence(
            kind: IdentityEvidenceKind.businessRecordObservation,
            source: 'rule:stock-alert',
            detail: 'Mức đặt lại của mặt hàng này là ${alert.threshold}',
          ),
        ],
        move: DoSomething(
          actionType: BusinessActionType.inventoryCreatePurchaseOrder,
          vendor: ActionVendor.demo,
          parameters: {'productId': p.id, 'quantity': alert.shortfall},
        ),
        observedAt: now,
      );
    }
  }

  // ── Bán gần bằng giá vốn ─────────────────────────────────────────────────

  Iterable<BriefItem> _marginItems(List<Product> products, DateTime now) sync* {
    for (final p in products) {
      final ratio = p.marginRatio;
      // `null` = chưa nhập chi phí. Đó **không** phải biên bằng 0 — coi nó là 0
      // sẽ khẳng định người bán đang lỗ, con số khó chịu nhất và sai nhất có
      // thể in ra.
      if (ratio == null || ratio >= thinMarginRatio) continue;

      final suggested = _priceForTargetMargin(p.costPrice!, thinMarginRatio);

      yield BriefItem(
        kind: BriefKind.marginTooThin,
        severity: ratio <= 0 ? BriefSeverity.critical : BriefSeverity.warning,
        subjectKind: 'product',
        subjectId: p.id,
        subjectLabel: p.name,
        headline: ratio <= 0
            ? '${p.name} đang bán dưới giá vốn'
            : '${p.name} chỉ còn ${(ratio * 100).round()}% lãi',
        suggestion:
            'Cân nhắc nâng giá bán lên ${TongtaiFormatters.vnd(suggested)}',
        evidence: [
          IdentityEvidence(
            kind: IdentityEvidenceKind.businessRecordObservation,
            source: 'rule:margin',
            detail: 'Giá bán ${TongtaiFormatters.vnd(p.pricePerUnit)}',
          ),
          IdentityEvidence(
            kind: IdentityEvidenceKind.businessRecordObservation,
            source: 'rule:margin',
            detail: 'Chi phí mỗi đơn vị ${TongtaiFormatters.vnd(p.costPrice!)}',
          ),
        ],
        move: ChangeAFact(
          domain: ProposalDomain.pricing,
          field: 'pricePerUnit',
          currentValue: p.pricePerUnit.round().toString(),
          proposedValue: suggested.round().toString(),
        ),
        observedAt: now,
      );
    }
  }

  /// Giá bán để đạt đúng biên [target]: `giá = chi phí / (1 − biên)`.
  ///
  /// Làm tròn lên nghìn — người bán không niêm yết giá lẻ tới đồng.
  static double _priceForTargetMargin(double cost, double target) {
    final raw = cost / (1 - target);
    return (raw / 1000).ceilToDouble() * 1000;
  }

  // ── Cảnh báo toàn doanh nghiệp ───────────────────────────────────────────

  Iterable<BriefItem> _signalItems(
    List<BusinessAlert> alerts,
    DateTime now,
  ) sync* {
    for (final alert in alerts) {
      // Hai loại này đã có việc riêng, cụ thể hơn và bấm được. Nhắc lại ở dạng
      // tổng quát chỉ làm brief dài ra mà không thêm một quyết định nào.
      if (alert.kind == BusinessAlertKind.stockBelowReorder) continue;
      if (alert.kind == BusinessAlertKind.customerRisk) continue;

      yield BriefItem(
        kind: BriefKind.businessSignal,
        severity: switch (alert.severity) {
          BusinessAlertSeverity.critical => BriefSeverity.critical,
          BusinessAlertSeverity.warning => BriefSeverity.warning,
          BusinessAlertSeverity.info => BriefSeverity.info,
        },
        subjectKind: 'business',
        subjectId: alert.kind.name,
        headline: _signalHeadline(alert),
        suggestion: 'Mở Báo cáo để xem điều gì đã đổi',
        evidence: [
          IdentityEvidence(
            kind: IdentityEvidenceKind.businessRecordObservation,
            source: 'rule:business-alerts/${alert.kind.name}',
            detail: _signalDetail(alert),
          ),
        ],
        // Cố ý KHÔNG kèm nút làm gì: không có một việc đúng duy nhất cho
        // "doanh thu giảm". Nó dẫn người bán tới chỗ xem số, rồi họ quyết.
        observedAt: now,
      );
    }
  }

  static String _signalHeadline(BusinessAlert alert) => switch (alert.kind) {
    BusinessAlertKind.revenueDrop => 'Doanh thu kỳ này thấp hơn kỳ trước',
    BusinessAlertKind.ordersDrop => 'Số đơn kỳ này ít hơn kỳ trước',
    BusinessAlertKind.negativeCashflow =>
      'Có ${alert.affectedCount} tháng chi nhiều hơn thu',
    BusinessAlertKind.stockBelowReorder => 'Có mặt hàng dưới mức đặt lại',
    BusinessAlertKind.customerRisk => 'Có khách đã lâu không quay lại',
  };

  static String _signalDetail(BusinessAlert alert) => switch (alert.kind) {
    BusinessAlertKind.revenueDrop =>
      '${TongtaiFormatters.vnd(alert.metricValue)} so với '
          '${TongtaiFormatters.vnd(alert.comparisonValue)} kỳ trước',
    BusinessAlertKind.ordersDrop =>
      '${alert.metricValue.round()} đơn so với '
          '${alert.comparisonValue.round()} đơn kỳ trước',
    BusinessAlertKind.negativeCashflow =>
      '${alert.metricValue.round()}/${alert.comparisonValue.round()} tháng '
          'trong kỳ bị âm',
    BusinessAlertKind.stockBelowReorder =>
      '${alert.affectedCount} mặt hàng dưới mức đặt lại',
    BusinessAlertKind.customerRisk =>
      '${alert.affectedCount} khách đã quá hạn quay lại',
  };
}
