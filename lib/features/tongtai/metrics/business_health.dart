import 'business_context.dart';
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

  /// The current (v1) rule over the KPIs: sales ⇒ healthy, otherwise not enough
  /// data. Kept pure so a later AI assessor can replace it without touching Home.
  static BusinessHealth from(BusinessMetrics metrics) =>
      metrics.hasSales ? BusinessHealth.healthy : BusinessHealth.notEnoughData;

  /// Derive health from the [BusinessContext] Aggregate Root (WTM-129) — the
  /// step in the chain `BusinessContext → BusinessHealth`. Phase 1 keys off
  /// sales; richer signals (open orders, low stock, trend, AI) fold in here
  /// later without changing Home's UI contract.
  static BusinessHealth fromContext(BusinessContext context) =>
      from(context.metrics);
}
