import 'business_metrics.dart';

/// A coarse read on how the business is doing (WTM-128, Founder). Home consumes
/// this as a value — **the Home UI never changes** when the assessment later
/// becomes AI-powered; only the producer of this value changes.
///
/// Initially simple: a business with no billable sales yet has *not enough data*
/// to assess; otherwise it reads as *healthy*. Future revisions (trend, margins,
/// risk, AI) return richer states but keep the same enum contract Home renders.
enum BusinessHealth {
  healthy,
  notEnoughData;

  String get labelEn => switch (this) {
    BusinessHealth.healthy => 'Healthy',
    BusinessHealth.notEnoughData => 'Not enough data',
  };

  String get labelVi => switch (this) {
    BusinessHealth.healthy => 'Khỏe mạnh',
    BusinessHealth.notEnoughData => 'Chưa đủ dữ liệu',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// The current (v1) rule: derive health from [BusinessMetrics]. Kept as a pure
  /// function so it is trivially testable and so a later AI assessor can replace
  /// the derivation without touching Home.
  static BusinessHealth from(BusinessMetrics metrics) =>
      metrics.hasSales ? BusinessHealth.healthy : BusinessHealth.notEnoughData;
}
