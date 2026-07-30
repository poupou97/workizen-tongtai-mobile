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

  /// The locale code behind this strings set ('vi' / 'en') — for domain enums
  /// exposing `label(String languageCode)` (WTM-145 P0 §2).
  String get languageCode;

  // ── common actions (P0 §2 full migration) ───────────────────────────────
  String get actionClear;
  String get actionSkip;
  String get actionNext;
  String get actionGetStarted;
  String get actionUndo;
  String get filterAll;
  String get dateToday;
  String get dateYesterday;
  String get chatYou;

  // ── screen titles ───────────────────────────────────────────────────────
  String get titleExport;
  String get titleOpportunityDetail;
  String get titleTransactionForm;
  String get titleAiAssistant;
  String get titleKeyScan;

  // ── Home ────────────────────────────────────────────────────────────────
  String get homeWelcome;
  String get homeEmptyBody;
  String get homeSampleLoadedSnack;
  String get homeSampleBanner;
  String get homeAddCustomer;
  String get homeAddProduct;
  String get homeAddOrder;
  String get homeAddGoal;
  String get homeViewReports;
  String get kpiAovShort;

  // ── More ────────────────────────────────────────────────────────────────
  String get moreAbout;
  String get moreLoadSampleConfirmTitle;
  String get moreLoadSampleConfirmBody;
  String get moreLoadSampleAction;
  String get moreSampleLoadedSnack;
  String get moreRemoveSampleConfirmTitle;
  String get moreRemoveSampleConfirmBody;
  String get moreRemoveSampleAction;
  String get moreSampleRemovedSnack;

  // ── Export (WTM-99/100) ─────────────────────────────────────────────────
  String get exportPickDataSet;
  String get exportDateRange;
  String get exportRangeAll;
  String get exportRangeLast30;
  String get exportRangeLast90;
  String get exportEncryptTitle;
  String get exportEncryptHint;
  String get exportPassphraseLabel;
  String get exportPassphraseTooShort;
  String get exportRun;
  String get exportRunning;
  String get exportCsvHint;
  String get exportHistory;
  String get exportHistoryEmpty;
  String exportShareSubject(String typeLabel, String stamp);
  String exportDoneSnack(int rows, String fileName);
  String exportHistoryLine(
    String fileName,
    String typeLabel,
    int rows,
    String date,
  );

  // ── Unified search (WTM-73) ─────────────────────────────────────────────
  String get searchAdvancedFilters;
  String get searchHint;
  String get searchClearFilters;
  String get searchCategory;
  String get searchCountry;
  String get searchRating;
  String get searchEverythingTitle;
  String get searchEverythingBody;
  String get searchRecent;
  String get searchNoResults;
  String get searchNoResultsBody;
  String get sectionSuppliers;
  String get sectionProducts;
  String get labelStock;
  String searchResultCount(int count);

  // ── Opportunity (WTM-91/92/94) ──────────────────────────────────────────
  String get oppInterested;
  String get oppDismiss;
  String get oppSaveTooltip;
  String get oppUnsaveTooltip;
  String get oppEmptySaved;
  String get oppEmptyTab;
  String get oppRoi;
  String get oppImpact;
  String get oppDetected;
  String get oppWhyWorth;
  String get sectionActionPlan;
  String get sectionSuggestions;
  String get aiScoreLabel;
  String get oppEstimatePrefix;
  String get oppScoreLabel;
  String oppDismissedSnack(String title);
  String oppInterestedSnack(String title);
  String oppGoalCreatedSnack(String title);
  String oppCreatedFromNote(String description);

  // ── Journey / goals (WTM-87/89) ─────────────────────────────────────────
  String get goalEdit;
  String get goalDaysLeftLabel;
  String get goalTimeElapsed;
  String get goalsEmptyPrompt;
  String get goalWhatToAchieve;
  String get goalCustom;
  String get goalTitleHint;
  String get goalRealizedHelp;
  String get goalNotesHint;
  String daysCount(int days);
  String daysLeft(int days);
  String percentOfGoal(int percent);
  String goalTemplateDays(String typeLabel, int days);

  // ── Timeline (WTM-114) ──────────────────────────────────────────────────
  String get timelineEmptyTitle;
  String get timelineEmptyBody;

  // ── Chat (WTM-80/84) ────────────────────────────────────────────────────
  String get chatTyping;
  String get chatInputHint;
  String get chatEmptyPrompt;
  String get chatSearchHint;
  String get chatSearchPrompt;
  String get chatSearchNoResults;
  String get chatSearchRange7d;

  // ── Finance / transaction form (WTM-113) ────────────────────────────────
  String get txnAmountLabel;
  String get txnAmountHint;
  String get txnCategoryLabel;
  String get txnDateLabel;
  String get txnNoteLabel;
  String get txnNoteHint;
  String get txnSave;
  String get financeEmptyTitle;
  String get financeEmptyBody;

  // ── Reports (WTM-95..98/127) ────────────────────────────────────────────
  String get reportsAnalyzing;
  String get reportsNoPipeline;
  String get reportsOpenLabel;
  String get reportsPipelineValue;
  String get reportsSoldPrefix;
  String get reportsEmptyTitle;
  String get reportsEmptyBody;
  String reportsOrdersCount(int count);

  // ── forms (shared) ──────────────────────────────────────────────────────
  String get labelOptionalSuffix;

  // ── purchase history (WTM-77) ───────────────────────────────────────────
  String get historyRangeAll;
  String get historyRangeLast30;
  String get historyRangeLast90;

  // ── Customer form (WTM-76) ──────────────────────────────────────────────
  String get custNameHint;
  String get custLocationHint;
  String get custTagsHint;
  String get custAddressHint;

  // ── AI key / BYOK (WTM-61/83) ───────────────────────────────────────────
  String get aiKeySavedSnack;
  String get aiKeyRemovedSnack;
  String get aiKeyScannedSnack;
  String get aiKeyScanQr;
  String get aiKeySave;
  String get aiKeyTest;
  String get aiKeyRotate;
  String get aiKeyRemove;
  String get aiKeyByokHint;
  String get aiKeyStoredHint;
  String get aiKeyPasteReplace;
  String get aiKeyPaste;
  String get aiKeyShow;
  String get aiKeyHide;
  String get aiKeyRolledBack;
  String get aiKeyNoneStored;
  String get keyScanHint;
  String aiKeyRotatedSnack(String model);
  String aiKeyRotateFailedPrefix(String message);
  String aiKeyTestOkSnack(String model);
  String aiKeyConsoleHint(String url, String provider);
  String aiKeyCardTitle(String provider);
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

  @override
  String get languageCode => 'vi';

  @override
  String get actionClear => 'Xoá';
  @override
  String get actionSkip => 'Bỏ qua';
  @override
  String get actionNext => 'Tiếp tục';
  @override
  String get actionGetStarted => 'Bắt đầu';
  @override
  String get actionUndo => 'Hoàn tác';
  @override
  String get filterAll => 'Tất cả';
  @override
  String get dateToday => 'Hôm nay';
  @override
  String get dateYesterday => 'Hôm qua';
  @override
  String get chatYou => 'Bạn';

  @override
  String get titleExport => 'Xuất dữ liệu (CSV)';
  @override
  String get titleOpportunityDetail => 'Chi tiết cơ hội';
  @override
  String get titleTransactionForm => 'Ghi giao dịch';
  @override
  String get titleAiAssistant => 'Trợ lý AI';
  @override
  String get titleKeyScan => 'Quét QR chứa API key';

  @override
  String get homeWelcome => 'Chào mừng đến Tổng Tài';
  @override
  String get homeEmptyBody => 'Nhập dữ liệu kinh doanh đầu tiên của bạn.';
  @override
  String get homeSampleLoadedSnack =>
      'Đã nạp dữ liệu mẫu — tất cả màn hình đang dùng chung dữ liệu này. '
      'Xóa trong More khi không cần nữa.';
  @override
  String get homeSampleBanner =>
      'Đang hiển thị kèm DỮ LIỆU MẪU (mọi màn hình dùng chung dữ liệu này). '
      'Bạn có thể sửa/xóa từng dòng, hoặc xóa toàn bộ mẫu trong More.';
  @override
  String get homeAddCustomer => '+ Khách hàng';
  @override
  String get homeAddProduct => '+ Sản phẩm';
  @override
  String get homeAddOrder => '+ Đơn hàng';
  @override
  String get homeAddGoal => '+ Mục tiêu';
  @override
  String get homeViewReports => 'Xem báo cáo';
  @override
  String get kpiAovShort => 'Đơn TB';

  @override
  String get moreAbout => 'Về Tổng Tài';
  @override
  String get moreLoadSampleConfirmTitle => 'Nạp dữ liệu mẫu?';
  @override
  String get moreLoadSampleConfirmBody =>
      'Dữ liệu mẫu sẽ được thêm vào ứng dụng như dữ liệu bình thường — '
      'mọi màn hình (Home, Kho, Khách hàng, Báo cáo, Cơ hội…) cùng hiển '
      'thị. Bạn có thể sửa từng dòng hoặc xóa toàn bộ mẫu bất cứ lúc nào; '
      'dữ liệu bạn tự nhập không bị ảnh hưởng.';
  @override
  String get moreLoadSampleAction => 'Nạp mẫu';
  @override
  String get moreSampleLoadedSnack =>
      'Đã nạp dữ liệu mẫu — xem ở mọi màn hình.';
  @override
  String get moreRemoveSampleConfirmTitle => 'Xóa toàn bộ dữ liệu mẫu?';
  @override
  String get moreRemoveSampleConfirmBody =>
      'Chỉ các bản ghi mẫu bị xóa. Dữ liệu bạn tự nhập được giữ nguyên.';
  @override
  String get moreRemoveSampleAction => 'Xóa mẫu';
  @override
  String get moreSampleRemovedSnack => 'Đã xóa toàn bộ dữ liệu mẫu.';

  @override
  String get exportPickDataSet => 'Chọn dữ liệu cần xuất';
  @override
  String get exportDateRange => 'Khoảng thời gian';
  @override
  String get exportRangeAll => 'Toàn bộ';
  @override
  String get exportRangeLast30 => '30 ngày';
  @override
  String get exportRangeLast90 => '90 ngày';
  @override
  String get exportEncryptTitle => 'Mã hoá bằng mật khẩu';
  @override
  String get exportEncryptHint =>
      'File .ttbk chỉ mở được bằng mật khẩu này. Mật khẩu không '
      'được lưu — quên là mất dữ liệu backup.';
  @override
  String get exportPassphraseLabel => 'Mật khẩu (≥ 6 ký tự)';
  @override
  String get exportPassphraseTooShort =>
      'Mật khẩu mã hoá cần tối thiểu 6 ký tự.';
  @override
  String get exportRun => 'Xuất & chia sẻ (email…)';
  @override
  String get exportRunning => 'Đang xuất…';
  @override
  String get exportCsvHint =>
      'File CSV mở đúng tiếng Việt trong Excel (UTF-8 BOM). Chia sẻ '
      'qua share sheet — chọn Mail/Gmail để gửi email; dữ liệu chỉ '
      'rời máy qua ứng dụng bạn chọn.';
  @override
  String get exportHistory => 'Lịch sử xuất';
  @override
  String get exportHistoryEmpty => 'Chưa có lần xuất nào.';
  @override
  String exportShareSubject(String typeLabel, String stamp) =>
      'Tổng Tài — xuất $typeLabel ($stamp)';
  @override
  String exportDoneSnack(int rows, String fileName) =>
      'Đã xuất $rows dòng — $fileName';
  @override
  String exportHistoryLine(
    String fileName,
    String typeLabel,
    int rows,
    String date,
  ) => '$fileName — $typeLabel, $rows dòng, $date';

  @override
  String get searchAdvancedFilters => 'Bộ lọc nâng cao';
  @override
  String get searchHint => 'Tìm nhà cung cấp, sản phẩm…';
  @override
  String get searchClearFilters => 'Xoá lọc';
  @override
  String get searchCategory => 'Danh mục';
  @override
  String get searchCountry => 'Quốc gia';
  @override
  String get searchRating => 'Đánh giá';
  @override
  String get searchEverythingTitle => 'Tìm kiếm toàn bộ';
  @override
  String get searchEverythingBody =>
      'Tìm nhà cung cấp, sản phẩm và hơn thế nữa.';
  @override
  String get searchRecent => 'Tìm kiếm gần đây';
  @override
  String get searchNoResults => 'Không có kết quả';
  @override
  String get searchNoResultsBody => 'Thử từ khoá khác hoặc điều chỉnh bộ lọc.';
  @override
  String get sectionSuppliers => 'Nhà cung cấp';
  @override
  String get sectionProducts => 'Sản phẩm';
  @override
  String get labelStock => 'Tồn';
  @override
  String searchResultCount(int count) =>
      count == 1 ? '1 kết quả' : '$count kết quả';

  @override
  String get oppInterested => 'Quan tâm';
  @override
  String get oppDismiss => 'Bỏ qua';
  @override
  String get oppSaveTooltip => 'Lưu lại';
  @override
  String get oppUnsaveTooltip => 'Bỏ lưu';
  @override
  String get oppEmptySaved => 'Chưa có cơ hội nào được lưu';
  @override
  String get oppEmptyTab => 'Chưa có cơ hội nào trong mục này';
  @override
  String get oppRoi => 'ROI ước tính';
  @override
  String get oppImpact => 'Tác động';
  @override
  String get oppDetected => 'Phát hiện';
  @override
  String get oppWhyWorth => 'Vì sao đáng làm';
  @override
  String get sectionActionPlan => 'Kế hoạch hành động';
  @override
  String get sectionSuggestions => 'Gợi ý';
  @override
  String get aiScoreLabel => 'điểm AI';
  @override
  String get oppEstimatePrefix => 'Ước tính';
  @override
  String get oppScoreLabel => 'Điểm';
  @override
  String oppDismissedSnack(String title) => 'Đã bỏ qua "$title"';
  @override
  String oppInterestedSnack(String title) => 'Đã đánh dấu quan tâm "$title"';
  @override
  String oppGoalCreatedSnack(String title) =>
      'Đã tạo mục tiêu "$title" trong Journey';
  @override
  String oppCreatedFromNote(String description) =>
      'Tạo từ cơ hội: $description';

  @override
  String get goalEdit => 'Sửa mục tiêu';
  @override
  String get goalDaysLeftLabel => 'Còn lại';
  @override
  String get goalTimeElapsed => 'Thời gian đã trôi';
  @override
  String get goalsEmptyPrompt => 'Đặt mục tiêu kinh doanh đầu tiên của bạn';
  @override
  String get goalWhatToAchieve => 'Bạn muốn đạt điều gì?';
  @override
  String get goalCustom => 'Tự đặt mục tiêu';
  @override
  String get goalTitleHint => 'VD: Đạt 100 triệu ₫ trong quý';
  @override
  String get goalRealizedHelp =>
      'Doanh thu đã đạt: tự tính từ đơn hàng đã ghi nhận.';
  @override
  String get goalNotesHint => 'Bối cảnh, kênh bán, nguồn hàng…';
  @override
  String daysCount(int days) => '$days ngày';
  @override
  String daysLeft(int days) => 'còn $days ngày';
  @override
  String percentOfGoal(int percent) => '$percent% mục tiêu';
  @override
  String goalTemplateDays(String typeLabel, int days) =>
      '$typeLabel • $days ngày';

  @override
  String get timelineEmptyTitle => 'Chưa có hoạt động nào';
  @override
  String get timelineEmptyBody =>
      'Đơn hàng, thu chi, cơ hội và mục tiêu sẽ xuất hiện ở đây theo '
      'thời gian.';

  @override
  String get chatTyping => 'Workizen AI đang nhập…';
  @override
  String get chatInputHint => 'Nhắn cho Workizen AI…';
  @override
  String get chatEmptyPrompt => 'Hỏi Workizen AI về việc kinh doanh của bạn';
  @override
  String get chatSearchHint => 'Tìm trong trò chuyện…';
  @override
  String get chatSearchPrompt => 'Nhập từ khóa để tìm trong lịch sử trò chuyện';
  @override
  String get chatSearchNoResults => 'Không tìm thấy tin nhắn nào';
  @override
  String get chatSearchRange7d => '7 ngày';

  @override
  String get txnAmountLabel => 'Số tiền (₫)';
  @override
  String get txnAmountHint => 'Ví dụ: 1500000';
  @override
  String get txnCategoryLabel => 'Nhóm';
  @override
  String get txnDateLabel => 'Ngày';
  @override
  String get txnNoteLabel => 'Ghi chú (không bắt buộc)';
  @override
  String get txnNoteHint => 'Ví dụ: Bán lô quạt cho khách sỉ';
  @override
  String get txnSave => 'Lưu giao dịch';
  @override
  String get financeEmptyTitle => 'Chưa có giao dịch tài chính';
  @override
  String get financeEmptyBody =>
      'Ghi khoản thu/chi đầu tiên và bảng tài chính sẽ hiện ở đây.';

  @override
  String get reportsAnalyzing => 'Workizen AI đang phân tích…';
  @override
  String get reportsNoPipeline => 'Không có cơ hội đang mở';
  @override
  String get reportsOpenLabel => 'Đang mở';
  @override
  String get reportsPipelineValue => 'Giá trị pipeline';
  @override
  String get reportsSoldPrefix => 'Đã bán';
  @override
  String get reportsEmptyTitle => 'Chưa có doanh thu để báo cáo';
  @override
  String get reportsEmptyBody =>
      'Bán đơn hàng đầu tiên và các chỉ số sẽ hiện ở đây.';
  @override
  String reportsOrdersCount(int count) => '$count đơn';

  @override
  String get labelOptionalSuffix => '(không bắt buộc)';

  @override
  String get historyRangeAll => 'Toàn bộ';
  @override
  String get historyRangeLast30 => '30 ngày qua';
  @override
  String get historyRangeLast90 => '90 ngày qua';

  @override
  String get custNameHint => 'VD: Phương Nguyễn';
  @override
  String get custLocationHint => 'VD: Hà Nội';
  @override
  String get custTagsHint => 'Phân tách bằng dấu phẩy, VD: tiktok, bán sỉ';
  @override
  String get custAddressHint => 'VD: 12 Hàng Bài, Hoàn Kiếm';

  @override
  String get aiKeySavedSnack => 'Đã lưu khóa API an toàn.';
  @override
  String get aiKeyRemovedSnack => 'Đã xóa khóa API.';
  @override
  String get aiKeyScannedSnack =>
      'Đã quét khóa từ QR — bấm Lưu (hoặc Đổi khóa) để xác nhận.';
  @override
  String get aiKeyScanQr => 'Quét QR';
  @override
  String get aiKeySave => 'Lưu khóa';
  @override
  String get aiKeyTest => 'Kiểm tra kết nối';
  @override
  String get aiKeyRotate => 'Đổi khóa (kiểm tra rồi mới thay)';
  @override
  String get aiKeyRemove => 'Xóa khóa';
  @override
  String get aiKeyByokHint =>
      'Dùng khóa của riêng bạn (BYOK) để bật trợ lý AI. Khóa được lưu an '
      'toàn trên thiết bị.';
  @override
  String get aiKeyStoredHint =>
      'Đã lưu khóa API. Bạn có thể kiểm tra, thay thế hoặc xóa khóa.';
  @override
  String get aiKeyPasteReplace => 'Dán khóa mới để thay thế';
  @override
  String get aiKeyPaste => 'Dán khóa API của bạn';
  @override
  String get aiKeyShow => 'Hiện khóa';
  @override
  String get aiKeyHide => 'Ẩn khóa';
  @override
  String get aiKeyRolledBack => 'Đã khôi phục khóa cũ.';
  @override
  String get aiKeyNoneStored => 'Chưa có khóa nào được lưu.';
  @override
  String get keyScanHint =>
      'Đưa mã QR vào khung hình — khóa sẽ tự điền vào ô nhập.';
  @override
  String aiKeyRotatedSnack(String model) =>
      'Đã đổi khóa — $model phản hồi với khóa mới.';
  @override
  String aiKeyRotateFailedPrefix(String message) =>
      'Khóa mới không hoạt động ($message). ';
  @override
  String aiKeyTestOkSnack(String model) =>
      'Kết nối thành công — $model đã phản hồi.';
  @override
  String aiKeyConsoleHint(String url, String provider) =>
      'Lấy khóa tại $url. Khóa chỉ lưu trên máy bạn và chỉ gửi trực tiếp '
      'tới $provider.';
  @override
  String aiKeyCardTitle(String provider) => 'Khóa API $provider';
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

  @override
  String get languageCode => 'en';

  @override
  String get actionClear => 'Clear';
  @override
  String get actionSkip => 'Skip';
  @override
  String get actionNext => 'Next';
  @override
  String get actionGetStarted => 'Get Started';
  @override
  String get actionUndo => 'Undo';
  @override
  String get filterAll => 'All';
  @override
  String get dateToday => 'Today';
  @override
  String get dateYesterday => 'Yesterday';
  @override
  String get chatYou => 'You';

  @override
  String get titleExport => 'Export Data (CSV)';
  @override
  String get titleOpportunityDetail => 'Opportunity details';
  @override
  String get titleTransactionForm => 'Record transaction';
  @override
  String get titleAiAssistant => 'AI Assistant';
  @override
  String get titleKeyScan => 'Scan API-key QR';

  @override
  String get homeWelcome => 'Welcome to Tổng Tài';
  @override
  String get homeEmptyBody => 'Enter your first business data.';
  @override
  String get homeSampleLoadedSnack =>
      'Sample data loaded — every screen now shares this data. '
      'Remove it in More when you no longer need it.';
  @override
  String get homeSampleBanner =>
      'Showing SAMPLE DATA alongside your data (every screen shares it). '
      'You can edit/delete individual rows, or remove all samples in More.';
  @override
  String get homeAddCustomer => '+ Customer';
  @override
  String get homeAddProduct => '+ Product';
  @override
  String get homeAddOrder => '+ Order';
  @override
  String get homeAddGoal => '+ Goal';
  @override
  String get homeViewReports => 'View reports';
  @override
  String get kpiAovShort => 'Avg order';

  @override
  String get moreAbout => 'About Tổng Tài';
  @override
  String get moreLoadSampleConfirmTitle => 'Load sample data?';
  @override
  String get moreLoadSampleConfirmBody =>
      'Sample data is added to the app as ordinary data — every screen '
      '(Home, Inventory, Customers, Reports, Opportunities…) shows it. '
      'You can edit individual rows or remove all samples at any time; '
      'data you entered yourself is never touched.';
  @override
  String get moreLoadSampleAction => 'Load samples';
  @override
  String get moreSampleLoadedSnack =>
      'Sample data loaded — visible on every screen.';
  @override
  String get moreRemoveSampleConfirmTitle => 'Remove all sample data?';
  @override
  String get moreRemoveSampleConfirmBody =>
      'Only sample records are removed. Data you entered yourself is kept.';
  @override
  String get moreRemoveSampleAction => 'Remove samples';
  @override
  String get moreSampleRemovedSnack => 'All sample data removed.';

  @override
  String get exportPickDataSet => 'Pick a data set';
  @override
  String get exportDateRange => 'Date range';
  @override
  String get exportRangeAll => 'All data';
  @override
  String get exportRangeLast30 => '30 days';
  @override
  String get exportRangeLast90 => '90 days';
  @override
  String get exportEncryptTitle => 'Encrypt with passphrase';
  @override
  String get exportEncryptHint =>
      'The .ttbk file opens only with this passphrase. It is never '
      'stored — if you forget it, the backup is unrecoverable.';
  @override
  String get exportPassphraseLabel => 'Passphrase (≥ 6 characters)';
  @override
  String get exportPassphraseTooShort =>
      'The encryption passphrase needs at least 6 characters.';
  @override
  String get exportRun => 'Export & share (email…)';
  @override
  String get exportRunning => 'Exporting…';
  @override
  String get exportCsvHint =>
      'The CSV opens correctly in Excel (UTF-8 BOM). Share through the '
      'share sheet — pick Mail/Gmail to send it by email; data leaves the '
      'device only through the app you choose.';
  @override
  String get exportHistory => 'Export history';
  @override
  String get exportHistoryEmpty => 'No exports yet.';
  @override
  String exportShareSubject(String typeLabel, String stamp) =>
      'Tổng Tài — $typeLabel export ($stamp)';
  @override
  String exportDoneSnack(int rows, String fileName) =>
      'Exported $rows rows — $fileName';
  @override
  String exportHistoryLine(
    String fileName,
    String typeLabel,
    int rows,
    String date,
  ) => '$fileName — $typeLabel, $rows rows, $date';

  @override
  String get searchAdvancedFilters => 'Advanced filters';
  @override
  String get searchHint => 'Search suppliers, products…';
  @override
  String get searchClearFilters => 'Clear';
  @override
  String get searchCategory => 'Category';
  @override
  String get searchCountry => 'Country';
  @override
  String get searchRating => 'Rating';
  @override
  String get searchEverythingTitle => 'Search everything';
  @override
  String get searchEverythingBody => 'Find suppliers, products and more.';
  @override
  String get searchRecent => 'Recent searches';
  @override
  String get searchNoResults => 'No results';
  @override
  String get searchNoResultsBody => 'Try another keyword or adjust filters.';
  @override
  String get sectionSuppliers => 'Suppliers';
  @override
  String get sectionProducts => 'Products';
  @override
  String get labelStock => 'Stock';
  @override
  String searchResultCount(int count) =>
      count == 1 ? '1 result' : '$count results';

  @override
  String get oppInterested => 'Interested';
  @override
  String get oppDismiss => 'Dismiss';
  @override
  String get oppSaveTooltip => 'Save';
  @override
  String get oppUnsaveTooltip => 'Unsave';
  @override
  String get oppEmptySaved => 'No saved opportunities yet';
  @override
  String get oppEmptyTab => 'No opportunities in this tab yet';
  @override
  String get oppRoi => 'Est. ROI';
  @override
  String get oppImpact => 'Impact';
  @override
  String get oppDetected => 'Detected';
  @override
  String get oppWhyWorth => 'Why it matters';
  @override
  String get sectionActionPlan => 'Action plan';
  @override
  String get sectionSuggestions => 'Suggestions';
  @override
  String get aiScoreLabel => 'AI score';
  @override
  String get oppEstimatePrefix => 'Est.';
  @override
  String get oppScoreLabel => 'Score';
  @override
  String oppDismissedSnack(String title) => 'Dismissed "$title"';
  @override
  String oppInterestedSnack(String title) => 'Marked "$title" as interested';
  @override
  String oppGoalCreatedSnack(String title) =>
      'Created goal "$title" in Journey';
  @override
  String oppCreatedFromNote(String description) =>
      'Created from opportunity: $description';

  @override
  String get goalEdit => 'Edit goal';
  @override
  String get goalDaysLeftLabel => 'Remaining';
  @override
  String get goalTimeElapsed => 'Time elapsed';
  @override
  String get goalsEmptyPrompt => 'Set your first business goal';
  @override
  String get goalWhatToAchieve => 'What do you want to achieve?';
  @override
  String get goalCustom => 'Custom goal';
  @override
  String get goalTitleHint => 'e.g. Reach 100M ₫ this quarter';
  @override
  String get goalRealizedHelp =>
      'Realized revenue: auto-derived from recorded orders.';
  @override
  String get goalNotesHint => 'Context, sales channels, sourcing…';
  @override
  String daysCount(int days) => '$days days';
  @override
  String daysLeft(int days) => '$days days left';
  @override
  String percentOfGoal(int percent) => '$percent% of goal';
  @override
  String goalTemplateDays(String typeLabel, int days) =>
      '$typeLabel • $days days';

  @override
  String get timelineEmptyTitle => 'No activity yet';
  @override
  String get timelineEmptyBody =>
      'Orders, income & expenses, opportunities and goals will appear '
      'here over time.';

  @override
  String get chatTyping => 'Workizen AI is typing…';
  @override
  String get chatInputHint => 'Message Workizen AI…';
  @override
  String get chatEmptyPrompt => 'Ask Workizen AI about your business';
  @override
  String get chatSearchHint => 'Search chats…';
  @override
  String get chatSearchPrompt => 'Type a keyword to search your chat history';
  @override
  String get chatSearchNoResults => 'No messages found';
  @override
  String get chatSearchRange7d => '7 days';

  @override
  String get txnAmountLabel => 'Amount (₫)';
  @override
  String get txnAmountHint => 'e.g. 1500000';
  @override
  String get txnCategoryLabel => 'Category';
  @override
  String get txnDateLabel => 'Date';
  @override
  String get txnNoteLabel => 'Note (optional)';
  @override
  String get txnNoteHint => 'e.g. Sold a batch of fans wholesale';
  @override
  String get txnSave => 'Save transaction';
  @override
  String get financeEmptyTitle => 'No financial transactions yet';
  @override
  String get financeEmptyBody =>
      'Record your first income or expense and the finance board appears '
      'here.';

  @override
  String get reportsAnalyzing => 'Workizen AI is analyzing…';
  @override
  String get reportsNoPipeline => 'No open opportunities';
  @override
  String get reportsOpenLabel => 'Open';
  @override
  String get reportsPipelineValue => 'Pipeline value';
  @override
  String get reportsSoldPrefix => 'Sold';
  @override
  String get reportsEmptyTitle => 'No revenue to report yet';
  @override
  String get reportsEmptyBody => 'Your KPIs appear here after the first sale.';
  @override
  String reportsOrdersCount(int count) => '$count orders';

  @override
  String get labelOptionalSuffix => '(optional)';

  @override
  String get historyRangeAll => 'All time';
  @override
  String get historyRangeLast30 => 'Last 30 days';
  @override
  String get historyRangeLast90 => 'Last 90 days';

  @override
  String get custNameHint => 'e.g. Phương Nguyễn';
  @override
  String get custLocationHint => 'e.g. Hà Nội';
  @override
  String get custTagsHint => 'Comma-separated, e.g. tiktok, wholesale';
  @override
  String get custAddressHint => 'e.g. 12 Hàng Bài, Hoàn Kiếm';

  @override
  String get aiKeySavedSnack => 'API key saved securely.';
  @override
  String get aiKeyRemovedSnack => 'API key removed.';
  @override
  String get aiKeyScannedSnack =>
      'Key scanned from QR — press Save (or Rotate) to confirm.';
  @override
  String get aiKeyScanQr => 'Scan QR';
  @override
  String get aiKeySave => 'Save key';
  @override
  String get aiKeyTest => 'Test connection';
  @override
  String get aiKeyRotate => 'Rotate key (verify, then replace)';
  @override
  String get aiKeyRemove => 'Remove key';
  @override
  String get aiKeyByokHint =>
      'Use your own key (BYOK) to enable the AI assistant. The key is '
      'stored securely on this device.';
  @override
  String get aiKeyStoredHint =>
      'An API key is stored. You can test, replace or remove it.';
  @override
  String get aiKeyPasteReplace => 'Paste a new key to replace';
  @override
  String get aiKeyPaste => 'Paste your API key';
  @override
  String get aiKeyShow => 'Show key';
  @override
  String get aiKeyHide => 'Hide key';
  @override
  String get aiKeyRolledBack => 'The old key was restored.';
  @override
  String get aiKeyNoneStored => 'No key is stored.';
  @override
  String get keyScanHint =>
      'Point the camera at the QR code — the key fills the input '
      'automatically.';
  @override
  String aiKeyRotatedSnack(String model) =>
      'Key rotated — $model responded with the new key.';
  @override
  String aiKeyRotateFailedPrefix(String message) =>
      'The new key did not work ($message). ';
  @override
  String aiKeyTestOkSnack(String model) => 'Connection OK — $model responded.';
  @override
  String aiKeyConsoleHint(String url, String provider) =>
      'Get a key at $url. It is stored only on your device and sent '
      'directly to $provider only.';
  @override
  String aiKeyCardTitle(String provider) => '$provider API key';
}

/// `context.l10n.<key>` — the ergonomic accessor used throughout the UI.
extension AppStringsX on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
