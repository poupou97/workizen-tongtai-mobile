import 'package:flutter/foundation.dart';

import 'business_metrics.dart';

/// The coarse health status a business reads at (WTM-128). Kept as the stable
/// enum Home renders; the surrounding [BusinessHealth] model carries the reason
/// and confidence.
enum BusinessHealthStatus {
  healthy,
  notEnoughData;

  String get labelEn => switch (this) {
    BusinessHealthStatus.healthy => 'Healthy',
    BusinessHealthStatus.notEnoughData => 'Not enough data',
  };

  String get labelVi => switch (this) {
    BusinessHealthStatus.healthy => 'Khỏe mạnh',
    BusinessHealthStatus.notEnoughData => 'Chưa đủ dữ liệu',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// The reason, in the reader's language.
  ///
  /// The model used to carry `reason` as a Vietnamese string, so the English
  /// build showed a Vietnamese tooltip and nothing could translate it after the
  /// fact. Same principle as ADR-TON-018: **store the code, render the label.**
  String reasonFor(String languageCode) => switch ((this, languageCode)) {
    (BusinessHealthStatus.healthy, 'vi') =>
      'Doanh nghiệp đang ghi nhận doanh thu.',
    (BusinessHealthStatus.healthy, _) => 'The business is recording revenue.',
    (BusinessHealthStatus.notEnoughData, 'vi') =>
      'Chưa đủ dữ liệu để đánh giá sức khỏe.',
    (BusinessHealthStatus.notEnoughData, _) =>
      'Not enough data to assess health yet.',
  };
}

/// A read on how the business is doing (WTM-128/132, Founder) — a **model**, not
/// just an enum, so it can grow without changing Home's UI or the API:
///
/// * [status]     — Healthy | NotEnoughData (what Home renders).
/// * [reason]     — a short human explanation.
/// * [confidence] — 0..1; always 1.0 for the rule-based v1.
///
/// The v1 derivation is a pure rule over the KPIs. A later AI assessor replaces
/// [from] (richer status/reason/confidence) **without touching Home**, which only
/// reads this model.
@immutable
class BusinessHealth {
  const BusinessHealth({
    required this.status,
    required this.reason,
    this.confidence = 1.0,
  });

  static const BusinessHealth healthy = BusinessHealth(
    status: BusinessHealthStatus.healthy,
    reason: 'Doanh nghiệp đang ghi nhận doanh thu.',
  );

  static const BusinessHealth notEnoughData = BusinessHealth(
    status: BusinessHealthStatus.notEnoughData,
    reason: 'Chưa đủ dữ liệu để đánh giá sức khỏe.',
  );

  final BusinessHealthStatus status;
  final String reason;
  final double confidence;

  bool get isHealthy => status == BusinessHealthStatus.healthy;

  /// Localized status label ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => status.label(languageCode);

  /// Localized explanation. Prefer this over [reason], which is kept as the
  /// Vietnamese default for the AI prompt blocks that already assume it.
  String reasonFor(String languageCode) => status.reasonFor(languageCode);

  /// The current (v1) rule over the KPIs: sales ⇒ healthy, otherwise not enough
  /// data. Pure so a later AI assessor can replace it without touching Home.
  factory BusinessHealth.from(BusinessMetrics metrics) =>
      metrics.hasSales ? BusinessHealth.healthy : BusinessHealth.notEnoughData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessHealth &&
          other.status == status &&
          other.reason == reason &&
          other.confidence == confidence);

  @override
  int get hashCode => Object.hash(status, reason, confidence);
}
