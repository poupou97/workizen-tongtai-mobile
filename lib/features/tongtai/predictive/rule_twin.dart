library;

import 'package:flutter/foundation.dart';

/// Contracts shared by every **Rule Twin** in Tổng Tài (ADR-TON-016, Founder
/// directive "Capability-Driven Predictive Foundation", 2026-07-30).
///
/// A Rule Twin is the **authoritative** deterministic answer for a predictive
/// question (revenue forecast, customer risk, business alerts). It:
///
/// - never depends on AI, a network, or a BYOK key;
/// - never fabricates a conclusion when the data cannot support one —
///   it says [DataSufficiency.insufficient] and explains why;
/// - always reports *why* through [ReasonCode]s, so the UI and the AI
///   explanation layer both quote the SAME reasons;
/// - carries a [version] so a changed formula is visible to consumers.
///
/// AI may explain a twin's output. AI may never replace, override or "improve"
/// the numbers (ADR-TON-013 invariant, extended here to predictions).

/// How much confidence the deterministic rule places in its own output.
///
/// This is NOT a probability — it is a coarse, explainable band derived from
/// how much history the rule had and how stable that history was.
enum ForecastConfidence {
  /// Not enough data to answer at all — the result is null/empty by contract.
  none,

  /// Answer produced, but from thin or very volatile history: show it as a
  /// hint, never as a promise.
  low,

  /// Enough history, moderate volatility.
  medium,

  /// Long, stable history — the strongest claim a deterministic rule makes.
  high;

  String label(String languageCode) => languageCode == 'vi'
      ? switch (this) {
          ForecastConfidence.none => 'Chưa đủ dữ liệu',
          ForecastConfidence.low => 'Thấp',
          ForecastConfidence.medium => 'Trung bình',
          ForecastConfidence.high => 'Cao',
        }
      : switch (this) {
          ForecastConfidence.none => 'Insufficient data',
          ForecastConfidence.low => 'Low',
          ForecastConfidence.medium => 'Medium',
          ForecastConfidence.high => 'High',
        };
}

/// Whether the input data satisfies the rule's stated minimum.
enum DataSufficiency {
  /// The rule refuses to answer. `result` MUST be null/empty.
  insufficient,

  /// The rule answers, but the caller must surface the caveat.
  partial,

  /// The rule's minimum is met.
  sufficient;

  bool get canAnswer => this != DataSufficiency.insufficient;
}

/// A machine-readable reason a twin reached its verdict.
///
/// Reason codes are the contract between the rule, the UI and the AI: the UI
/// renders them as localized text, the AI explains them in prose, and tests
/// assert on them. Adding a code is additive; changing a code's meaning is a
/// breaking change and requires a twin [RuleTwinResult.version] bump.
enum ReasonCode {
  // ── data sufficiency ────────────────────────────────────────────────────
  /// Fewer completed months than the rule's minimum.
  notEnoughHistory,

  /// History exists but every value is zero.
  noRevenueYet,

  /// No customer records at all.
  noCustomers,

  // ── revenue trend ───────────────────────────────────────────────────────
  /// Recent months trend upward beyond the noise band.
  revenueGrowing,

  /// Recent months trend downward beyond the noise band.
  revenueDeclining,

  /// Movement stays inside the noise band.
  revenueFlat,

  /// Month-over-month swings are large — forecast is a wide guess.
  highVolatility,

  /// A repeating yearly shape was detected (needs ≥ 12 months).
  seasonalPatternDetected,

  /// The current month is still running, so it is excluded from the base.
  partialMonthExcluded,

  /// The current **week** is still running, so it is excluded from the base.
  ///
  /// Cố ý là một mã riêng chứ không dùng lại [partialMonthExcluded]: mã này
  /// hiện thành chữ trên màn hình, và một bản tổng kết TUẦN nói *"đã loại tháng
  /// đang chạy"* là nói sai sự thật với người bán.
  partialWeekExcluded,

  // ── customer risk ───────────────────────────────────────────────────────
  /// Bought recently — inside the active window.
  recentPurchase,

  /// Silence longer than this customer's own typical gap.
  purchaseGapExceeded,

  /// Silence beyond the churn threshold.
  inactiveBeyondChurnWindow,

  /// Used to buy often, now slowing down.
  frequencyDropping,

  /// High lifetime value at risk — worth a win-back.
  highValueAtRisk,

  /// Never placed a second order.
  singlePurchaseOnly,

  // ── business alerts ─────────────────────────────────────────────────────
  /// Revenue fell versus the comparable previous window.
  revenueDropVsPrevious,

  /// Order count fell versus the comparable previous window.
  ordersDropVsPrevious,

  /// Stock at or below reorder level for products that actually sell.
  stockBelowReorder,

  /// Expenses exceeded income over the window.
  negativeCashflow;

  String get code => name;

  /// Localized, user-facing wording. Reason codes are shown to the seller in
  /// the Forecast/Risk screens and quoted verbatim by the AI explanation, so
  /// the wording lives with the code (domain-enum convention, ADR-TON-007).
  String get labelVi => switch (this) {
    ReasonCode.notEnoughHistory => 'Chưa đủ lịch sử để dự báo',
    ReasonCode.noRevenueYet => 'Chưa có doanh thu nào',
    ReasonCode.noCustomers => 'Chưa có khách hàng nào',
    ReasonCode.revenueGrowing => 'Doanh thu đang tăng',
    ReasonCode.revenueDeclining => 'Doanh thu đang giảm',
    ReasonCode.revenueFlat => 'Doanh thu đi ngang',
    ReasonCode.highVolatility => 'Doanh thu biến động mạnh',
    ReasonCode.seasonalPatternDetected => 'Có quy luật mùa vụ',
    ReasonCode.partialMonthExcluded => 'Đã loại tháng đang chạy',
    ReasonCode.partialWeekExcluded => 'Đã loại tuần đang chạy',
    ReasonCode.recentPurchase => 'Vừa mua gần đây',
    ReasonCode.purchaseGapExceeded => 'Lâu hơn nhịp mua thường lệ',
    ReasonCode.inactiveBeyondChurnWindow => 'Im lặng quá ngưỡng rời bỏ',
    ReasonCode.frequencyDropping => 'Tần suất mua đang giảm',
    ReasonCode.highValueAtRisk => 'Khách giá trị cao đang rời',
    ReasonCode.singlePurchaseOnly => 'Mới mua đúng một lần',
    ReasonCode.revenueDropVsPrevious => 'Doanh thu giảm so với kỳ trước',
    ReasonCode.ordersDropVsPrevious => 'Số đơn giảm so với kỳ trước',
    ReasonCode.stockBelowReorder => 'Tồn kho dưới ngưỡng đặt lại',
    ReasonCode.negativeCashflow => 'Dòng tiền âm',
  };

  String get labelEn => switch (this) {
    ReasonCode.notEnoughHistory => 'Not enough history to forecast',
    ReasonCode.noRevenueYet => 'No revenue recorded yet',
    ReasonCode.noCustomers => 'No customers yet',
    ReasonCode.revenueGrowing => 'Revenue is growing',
    ReasonCode.revenueDeclining => 'Revenue is declining',
    ReasonCode.revenueFlat => 'Revenue is flat',
    ReasonCode.highVolatility => 'Revenue swings widely',
    ReasonCode.seasonalPatternDetected => 'Seasonal pattern detected',
    ReasonCode.partialMonthExcluded => 'Running month excluded',
    ReasonCode.partialWeekExcluded => 'Running week excluded',
    ReasonCode.recentPurchase => 'Bought recently',
    ReasonCode.purchaseGapExceeded => 'Longer than their usual gap',
    ReasonCode.inactiveBeyondChurnWindow => 'Silent beyond the churn window',
    ReasonCode.frequencyDropping => 'Buying less often',
    ReasonCode.highValueAtRisk => 'High-value customer at risk',
    ReasonCode.singlePurchaseOnly => 'Only ever bought once',
    ReasonCode.revenueDropVsPrevious => 'Revenue down vs previous window',
    ReasonCode.ordersDropVsPrevious => 'Orders down vs previous window',
    ReasonCode.stockBelowReorder => 'Stock at or below reorder level',
    ReasonCode.negativeCashflow => 'Negative cash flow',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// The uniform envelope every Rule Twin returns.
///
/// [result] is null exactly when [sufficiency] is [DataSufficiency.insufficient]
/// — enforced by the assert below, so "no data" can never masquerade as a real
/// prediction (Testing Bible P-03: the user must be able to tell *no data* from
/// *could not compute*).
@immutable
class RuleTwinResult<T> {
  const RuleTwinResult({
    required this.result,
    required this.confidence,
    required this.sufficiency,
    required this.reasonCodes,
    required this.version,
    required this.generatedAt,
  }) : assert(
         (sufficiency == DataSufficiency.insufficient) == (result == null),
         'insufficient data MUST carry a null result, and vice versa',
       ),
       assert(
         sufficiency != DataSufficiency.insufficient ||
             confidence == ForecastConfidence.none,
         'insufficient data MUST report ForecastConfidence.none',
       );

  /// Insufficient-data constructor — the only way to return "I cannot answer".
  factory RuleTwinResult.insufficient({
    required List<ReasonCode> reasonCodes,
    required String version,
    required DateTime generatedAt,
  }) => RuleTwinResult<T>(
    result: null,
    confidence: ForecastConfidence.none,
    sufficiency: DataSufficiency.insufficient,
    reasonCodes: reasonCodes,
    version: version,
    generatedAt: generatedAt,
  );

  /// The computed answer, or null when [sufficiency] is insufficient.
  final T? result;

  final ForecastConfidence confidence;
  final DataSufficiency sufficiency;

  /// Why — ordered most-significant first. Never empty.
  final List<ReasonCode> reasonCodes;

  /// Formula version, e.g. `revenue-forecast/1`. Bump when the maths changes.
  final String version;

  final DateTime generatedAt;

  bool get hasAnswer => result != null;

  /// Stable, PII-free line for the AI prompt and for telemetry.
  ///
  /// Deliberately contains only codes and bands — never customer names, phone
  /// numbers, or raw money — so the same string is safe in both places
  /// (privacy red-line, D-7/ADR-TON-005).
  String get provenance =>
      '[$version] sufficiency=${sufficiency.name} '
      'confidence=${confidence.name} '
      'reasons=${reasonCodes.map((r) => r.code).join(',')}';
}
