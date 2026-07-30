import 'package:flutter/widgets.dart';

/// Locale-aware app strings for Tổng Tài (WTM-119) — the same custom-l10n
/// architecture as the Workizen AI Personal Hub: an abstract [AppStrings] with
/// per-locale implementations resolved from `Localizations.localeOf`, no ARB /
/// flutter gen-l10n and no external i18n package.
///
/// Migration is incremental (Boy-Scout): add a getter here + both
/// implementations, then replace the inline literal with `context.l10n.<key>`.
/// New features should use `context.l10n` from the start when the cost is low.
abstract class AppStrings {
  const AppStrings();

  /// Resolves the active locale's strings; falls back to English.
  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'vi' ? const AppStringsVi() : const AppStringsEn();
  }

  // ── common actions (shared across screens) ─────────────────────────────
  String get actionViewAll;
  String get actionSearch;
  String get actionCancel;

  // ── settings / language ────────────────────────────────────────────────
  String get settingsLanguage;
  String get languagePickerTitle;

  // ── navigation / screen titles (P0 §2 WTM-145: one active locale) ──────
  String get titleReports;
  String get titleFinance;
  String get titleTimeline;
  String get titleGoalDetail;

  // ── More menu ───────────────────────────────────────────────────────────
  String get moreLoadSample;
  String get moreRemoveSample;

  // ── KPI labels ──────────────────────────────────────────────────────────
  String get kpiRevenue;
  String get kpiOrders;
  String get kpiCustomers;
  String get kpiAov;
  String get kpiIncome;
  String get kpiExpense;
  String get kpiProfit;
  String get kpiMargin;

  // ── section titles ──────────────────────────────────────────────────────
  String get sectionGetStarted;
  String get sectionRevenueTrend;
  String get sectionTopCategories;
  String get sectionTopProducts;
  String get sectionTopCustomers;
  String get sectionBreakdownByPeriod;
  String get sectionPipeline;
  String get sectionCashflow;
  String get sectionExpensesByCategory;
  String get sectionRecent;

  // ── Workizen AI actions / results ───────────────────────────────────────
  String get aiSummarize;
  String get aiRecommend;
  String get aiPlan;
  String get aiHealth;
  String get aiInsight;
  String get aiResultSummary;
  String get aiResultRecommendations;
  String get aiResultWeeklyPlan;

  // ── journey / opportunity ───────────────────────────────────────────────
  String get journeyRealizedTitle;
  String get journeyRealizedSource;
  String get opportunityCreateGoal;

  // ── reports misc ────────────────────────────────────────────────────────
  String get reportsPeakPrefix;
}

class AppStringsVi extends AppStrings {
  const AppStringsVi();

  @override
  String get actionViewAll => 'Xem tất cả';
  @override
  String get actionSearch => 'Tìm kiếm';
  @override
  String get actionCancel => 'Hủy';

  @override
  String get settingsLanguage => 'Ngôn ngữ';
  @override
  String get languagePickerTitle => 'Chọn ngôn ngữ';

  @override
  String get titleReports => 'Báo cáo & Phân tích';
  @override
  String get titleFinance => 'Tài chính';
  @override
  String get titleTimeline => 'Dòng thời gian';
  @override
  String get titleGoalDetail => 'Chi tiết mục tiêu';

  @override
  String get moreLoadSample => 'Nạp dữ liệu mẫu';
  @override
  String get moreRemoveSample => 'Xóa dữ liệu mẫu';

  @override
  String get kpiRevenue => 'Doanh thu';
  @override
  String get kpiOrders => 'Đơn hàng';
  @override
  String get kpiCustomers => 'Khách hàng';
  @override
  String get kpiAov => 'Giá trị đơn TB';
  @override
  String get kpiIncome => 'Doanh thu';
  @override
  String get kpiExpense => 'Chi phí';
  @override
  String get kpiProfit => 'Lợi nhuận';
  @override
  String get kpiMargin => 'Biên lợi nhuận';

  @override
  String get sectionGetStarted => 'Bắt đầu';
  @override
  String get sectionRevenueTrend => 'Doanh thu theo tháng';
  @override
  String get sectionTopCategories => 'Nhóm bán chạy';
  @override
  String get sectionTopProducts => 'Sản phẩm bán chạy';
  @override
  String get sectionTopCustomers => 'Khách hàng hàng đầu';
  @override
  String get sectionBreakdownByPeriod => 'Chi tiết theo kỳ';
  @override
  String get sectionPipeline => 'Cơ hội đang mở';
  @override
  String get sectionCashflow => 'Dòng tiền';
  @override
  String get sectionExpensesByCategory => 'Chi phí theo nhóm';
  @override
  String get sectionRecent => 'Gần đây';

  @override
  String get aiSummarize => 'Tóm tắt';
  @override
  String get aiRecommend => 'Gợi ý hành động';
  @override
  String get aiPlan => 'Kế hoạch tuần';
  @override
  String get aiHealth => 'Sức khỏe';
  @override
  String get aiInsight => 'Đánh giá AI';
  @override
  String get aiResultSummary => 'Tóm tắt';
  @override
  String get aiResultRecommendations => 'Gợi ý hành động';
  @override
  String get aiResultWeeklyPlan => 'Kế hoạch tuần';

  @override
  String get journeyRealizedTitle => 'Doanh thu thực tế trong kỳ';
  @override
  String get journeyRealizedSource => 'Từ đơn hàng đã ghi nhận';
  @override
  String get opportunityCreateGoal => 'Tạo mục tiêu từ cơ hội';

  @override
  String get reportsPeakPrefix => 'Cao nhất';
}

class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get actionViewAll => 'View all';
  @override
  String get actionSearch => 'Search';
  @override
  String get actionCancel => 'Cancel';

  @override
  String get settingsLanguage => 'Language';
  @override
  String get languagePickerTitle => 'Choose language';

  @override
  String get titleReports => 'Reports & Analytics';
  @override
  String get titleFinance => 'Finance';
  @override
  String get titleTimeline => 'Timeline';
  @override
  String get titleGoalDetail => 'Goal details';

  @override
  String get moreLoadSample => 'Load sample data';
  @override
  String get moreRemoveSample => 'Remove sample data';

  @override
  String get kpiRevenue => 'Revenue';
  @override
  String get kpiOrders => 'Orders';
  @override
  String get kpiCustomers => 'Customers';
  @override
  String get kpiAov => 'Avg. order value';
  @override
  String get kpiIncome => 'Income';
  @override
  String get kpiExpense => 'Expense';
  @override
  String get kpiProfit => 'Profit';
  @override
  String get kpiMargin => 'Margin';

  @override
  String get sectionGetStarted => 'Get started';
  @override
  String get sectionRevenueTrend => 'Revenue trend';
  @override
  String get sectionTopCategories => 'Top categories';
  @override
  String get sectionTopProducts => 'Top products';
  @override
  String get sectionTopCustomers => 'Top customers';
  @override
  String get sectionBreakdownByPeriod => 'Breakdown by period';
  @override
  String get sectionPipeline => 'Open pipeline';
  @override
  String get sectionCashflow => 'Cashflow';
  @override
  String get sectionExpensesByCategory => 'Expenses by category';
  @override
  String get sectionRecent => 'Recent';

  @override
  String get aiSummarize => 'Summarize';
  @override
  String get aiRecommend => 'Recommendations';
  @override
  String get aiPlan => 'Weekly plan';
  @override
  String get aiHealth => 'Health';
  @override
  String get aiInsight => 'AI insight';
  @override
  String get aiResultSummary => 'Summary';
  @override
  String get aiResultRecommendations => 'Recommendations';
  @override
  String get aiResultWeeklyPlan => 'Weekly plan';

  @override
  String get journeyRealizedTitle => 'Booked sales this period';
  @override
  String get journeyRealizedSource => 'from recorded orders';
  @override
  String get opportunityCreateGoal => 'Create goal from opportunity';

  @override
  String get reportsPeakPrefix => 'Peak';
}

/// `context.l10n.<key>` — the ergonomic accessor used throughout the UI.
extension AppStringsX on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
