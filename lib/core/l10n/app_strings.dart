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
  String get moreLoadHistory;
  String get moreLoadHistoryConfirmTitle;
  String get moreLoadHistoryConfirmBody;
  String get moreHistoryLoadedSnack;
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
  String get actionNext;
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

  /// WTM-191 — turn an opportunity into work inside the active journey.
  String get oppAddToJourney;
  String oppAddedToJourneySnack(String title);
  String get oppAlreadyInJourney;
  String get oppNoActiveJourney;
  // ── WTM-194: chuỗi từng bị hard-code bằng tiếng Anh ────────────────────
  String get actionSaveChanges;
  String get sortAscending;
  String get sortDescending;
  String get customerAddTitle;
  String get customerEditTitle;
  String get customerSave;
  String get customerPossibleDuplicate;
  String get customerNoPurchases;
  String customerLastPurchase(String date);
  String get goalFormNewTitle;
  String get goalFormEditTitle;
  String get goalFormCreate;
  String get goalReviewRevenueTarget;
  String get goalReviewMetricTarget;
  String get goalStartDate;
  String get goalEndDate;
  String get goalReviewType;
  String get goalReviewTimeline;
  String get goalReviewNotes;
  String get homeNoOpportunities;
  String get homeNoMissions;
  String get oppFilterAll;
  String get oppEmptyFeed;
  String get productSkuExists;
  String get productNameHint;
  String get productCategoryHint;
  String get stockRestockNeeded;
  String stockRestockBy(int quantity);
  String get supplierNoFavoritesMatch;
  String get supplierNoSearchMatch;
  String get supplierFavoritesHint;
  String get supplierSearchHint;

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

  // ── bottom navigation (WTM-55, keyed in WTM-146 §3) ─────────────────────
  String get navHome;
  String get navProducer;
  String get navInventory;
  String get navConsumer;
  String get navMore;

  // ── common actions/labels (WTM-146 §3 EN-literal sweep) ─────────────────
  String get actionAdd;
  String get actionSave;
  String get actionSend;
  String get actionClearFilters;
  String get actionPrevPage;
  String get actionNextPage;
  String get labelSort;
  String get labelStatus;
  String get labelTotal;
  String get labelType;
  String get labelLocation;
  String get labelPeriod;
  String get labelQuantity;
  String get labelDescription;
  String get formFixHighlighted;
  String get changeHistory;

  // ── chat extras ─────────────────────────────────────────────────────────
  String get chatRemoveAttachment;
  String get chatAttachFile;

  // ── Consumer overview (WTM-26) ──────────────────────────────────────────
  String get titleConsumerIntelligence;
  String get titleCustomers;
  String get segActive;
  String get segVip;
  String get segNew;
  String get sectionCustomerSegments;
  String get emptyCustomerSegments;
  String get sectionRecentInteractions;
  String get emptyRecentInteractions;
  String get sectionCustomerLifecycle;

  // ── orders (WTM-126) ────────────────────────────────────────────────────
  String get titleCreateOrder;
  String get orderSoldPrice;
  String get orderNeedProduct;
  String get orderAddItem;
  String get orderEmptyItems;

  // ── customer form/list (WTM-75/76) ──────────────────────────────────────
  String get custRemoveAddress;
  String get custAddAddress;
  String get custSegments;
  String get custCustomSegmentHint;
  String get custAdd;
  String get custSearchHint;
  String get custPurchaseHistory;
  String get custEmptySearch;
  String get custEmptySearchHint;

  // ── purchase history extras (WTM-77) ────────────────────────────────────
  String get historyRepurchase;
  String get historyEmptyOrders;
  String get historyEmptyHint;

  // ── goals extras (WTM-87) ───────────────────────────────────────────────
  String get titleBusinessGoals;
  String get goalNew;

  // ── Home extras (WTM-128) ───────────────────────────────────────────────
  String get titleHomeDashboard;
  String get homeChatTooltip;
  String get homeAiSubtitle;
  String get sectionBusinessKpis;
  String get sectionTopOpportunities;
  String get homeCtaCustomer;
  String get homeCtaProduct;
  String get homeCtaOrder;
  String get homeCtaGoal;
  String get homeCtaDemo;
  String get tileJourney;

  // ── inventory (WTM-68/70) ───────────────────────────────────────────────
  String get pickerTitle;
  String get pickerSearchHint;
  String get pickerNoMatch;
  String get invAdd;
  String get invView;
  String get invSearchHint;

  /// Tappable stock banner. Was hardcoded English until WTM-169 — the
  /// Vietnamese build showed "Stock alerts: 4 out of stock • 2 low".
  String invStockAlerts(String parts);
  String supplierReviewCount(int count);
  String supplierProductCount(int count);
  String supplierCatalogSummary(int products, int categories);
  String supplierMessageTitle(String name);
  String supplierMessageSent(String name);
  String supplierMinOrder(int units, String leadTime);
  String get homeTodaysMissions;

  /// "ROI ×2.4" — the multiplier badge on a Home opportunity card.
  String homeRoiMultiple(String multiple);
  String orderForCustomer(String name);
  String customerAddressCount(int count);
  String productImageCount(int count);
  String stockQtyOfThreshold(int quantity, int threshold);
  String supplierFromReviews(int count);
  String invUpdatedOn(String date);
  String invShowingRange(int first, int last, int total);
  String invPageOf(int page, int pageCount);
  String invQuantity(int quantity);
  String invOutOfStockCount(int count);
  String invLowStockCount(int count);
  String get invEmptySearch;
  String get invEmptySearchHint;
  String get titleStockAlerts;
  String get stockOut;
  String get stockLow;
  String get stockAllHealthy;
  String get stockAllHealthyBody;

  // ── More sections/entries (WTM-33) ──────────────────────────────────────
  String get moreSettings;
  String get moreNotifications;
  String get moreTheme;
  String get moreGrokKey;
  String get moreBusinessSection;
  String get moreBusinessInfo;
  String get moreSupportSection;
  String get moreReplayTutorial;
  String get moreHelp;
  String get moreSendFeedback;

  // Feedback (WTM-175) — kênh phản hồi local-first: không backend, không tài
  // khoản; báo cáo đi qua share sheet của người dùng.
  String get feedbackIntro;
  String get feedbackHint;
  String get feedbackSend;
  String get feedbackEmpty;
  String get feedbackWhatIsSent;
  String get feedbackNoBusinessData;
  String get feedbackMessageHeading;
  String get feedbackDiagnosticsHeading;
  String get feedbackAppVersionLabel;
  String get feedbackPlatformLabel;
  String get feedbackLocaleLabel;
  String get feedbackSubject;

  // AI Business Profile (WTM-177) — bốn câu hỏi phân loại về ngành nghề.
  // KHÔNG có trường tự do: xem tongtai_business_profile_privacy_test.dart.
  String get profileTitle;
  String get profileIntro;
  String get profilePrivacyNote;
  String get profileTradeLabel;
  String get profileSizeLabel;
  String get profileChannelsLabel;
  String get profileSeasonalityLabel;
  String get profileSave;
  String get profileSaved;
  String get profileSkipHint;
  String profileTrade(String code);
  String profileSize(String code);
  String profileChannel(String code);
  String profileSeasonality(String code);

  // Business Journey (WTM-187) — hành trình có bậc.
  String get journeyTitle;
  String get journeyEmptyTitle;
  String get journeyEmptyBody;
  String get journeyInsufficientTitle;
  String get journeyInsufficientBody;
  String get journeyProgress;
  String get journeyFromRule;

  /// WTM-191 — this piece of work came from an opportunity the seller chose.
  String get journeyFromOpportunity;
  String get journeyMeasured;

  // AI-first Onboarding (WTM-178) — hội thoại chạy được KHÔNG cần AI.
  String get obGreeting;
  String get obGreetingBody;
  String get obStart;
  String get obSkip;
  String get obNext;
  String get obBack;
  String get obDone;
  String get obClosing;
  String get obClosingEmpty;
  String get obProgress;
  String obQuestion(String stepId);
  String get moreLegalSection;
  String get moreTerms;
  String get morePrivacy;

  // ── Privacy policy (WTM-37) ─────────────────────────────────────────────
  // Source of truth: docs/05-OPERATIONS/PRIVACY-POLICY.md. Adding a telemetry
  // event means editing both, in the same PR.
  // ── About (WTM-170) ─────────────────────────────────────────────────────
  String aboutVersion(String version);
  String get aboutWhatTitle;
  String get aboutWhatBody;
  String get aboutDataTitle;
  String get aboutDataBody;
  String get aboutAiTitle;
  String get aboutAiBody;

  /// Trailing note on a settings row that is on the roadmap but not built.
  String get settingsComingSoon;

  String get privacyTitle;
  String get privacyUpdated;
  String get privacyLocalTitle;
  String get privacyLocalBody;
  String get privacyAiTitle;
  String get privacyAiBody;
  String get privacyTelemetryTitle;
  String get privacyTelemetryBody;
  String get privacyCrashTitle;
  String get privacyCrashBody;
  String get privacyNoAdsTitle;
  String get privacyNoAdsBody;
  String get privacyBackupTitle;
  String get privacyBackupBody;
  String get privacySampleTitle;
  String get privacySampleBody;
  String get privacyRightsTitle;
  String get privacyRightsBody;

  // ── opportunity feed extras (WTM-91) ────────────────────────────────────
  String get titleOpportunities;

  // ── Producer hub (WTM-24) ───────────────────────────────────────────────
  String get titleProducerHub;
  String get producerAiSummary;
  String get producerAiCapabilities;
  String get producerCapScoring;
  String get producerCapRanking;
  String get producerCapTrends;
  String get producerCapPrice;
  String get producerCapQuality;
  String get producerCapDelivery;
  String get producerRecentOpps;
  String get producerEmptyOpps;
  String get producerVerifiedSuppliers;
  String get producerEmptySuppliers;

  // ── product form extras (WTM-69) ────────────────────────────────────────
  String get formWrite;
  String get formPreview;
  String get formNothingToPreview;
  String get formMarkdownHint;
  String get formUpload;
  String get formCamera;
  String get formRemoveImage;

  String get titleEditProduct;
  String get titleAddProduct;
  String get formSaveChanges;
  String get formSaveProduct;
  String get favAdd;
  String get lifecycleAwareness;
  String get lifecycleConsideration;
  String get lifecyclePurchase;
  String get lifecycleRetention;

  // ── supplier screens (WTM-63/64/65 — chrome only, catalog stays data) ───
  String get labelSupplier;
  String get supAbout;
  String get supRatingsCerts;
  String get supProductCatalog;
  String get supTransactionHistory;
  String get supTotalVolume;
  String get supTotalOrders;
  String get supRepeatBuyers;
  String get supContact;
  String get supMessage;
  String get supAskHint;
  String get titleSupplierSearch;
  String get titleFavoriteSuppliers;
  String get supSearchHint;
  String get supShow;
  String get supFavorites;
  String get favRemove;
  String get favEmpty;
  String get favEmptyHint;

  // ── finance / transaction type toggles (WTM-113) ────────────────────────
  String get txnIncome;
  String get txnExpense;

  /// Deterministic Producer-hub summary line (rule-based, zero AI spend).
  String producerSummaryLine(int opportunities, int favorites);

  // ── Predictive Foundation (WTM-149 · ADR-TON-016) ───────────────────────
  String get titleForecast;
  String get titleCustomerRisk;
  String get forecastNextMonth;
  String get forecastRange;
  String get forecastConfidence;
  String get forecastBasis;
  String get forecastInsufficient;
  String get forecastInsufficientBody;
  String get forecastHistory;
  String get forecastVsPrevious;
  String get forecastWhy;
  String get forecastRuleBased;
  String get riskStageActive;
  String get riskStageCooling;
  String get riskStageAtRisk;
  String get riskStageChurned;
  String get riskStageNeverPurchased;
  String get riskWinBack;
  String get riskEmpty;
  String get riskEmptyBody;
  String get riskRecommendedActions;
  String get riskActionContact;
  String get riskActionOffer;
  String get riskNoData;
  String get aiExplain;
  String get aiExplainRunning;
  String daysSincePurchase(int days);
  String riskScoreLabel(int score);
  String customersAtRisk(int count);

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

  // ── shared screen states (WTM-148 / ADR-TON-017) ────────────────────────
  // One wording for every screen: a data-path failure must read the same in
  // Inventory as in Reports, or the user learns nothing from seeing it twice.
  String get stateLoading;
  String get stateEmpty;
  String get stateRetry;
  String get stateInsufficientTitle;
  String get stateInsufficientBody;
  String get stateStaleTitle;
  String get stateTechnicalDetail;
  String get errorStorageTitle;
  String get errorStorageBody;
  String get errorNetworkTitle;
  String get errorNetworkBody;
  String get errorPermissionTitle;
  String get errorPermissionBody;
  String get errorConfigurationTitle;
  String get errorConfigurationBody;
  String get errorUnexpectedTitle;
  String get errorUnexpectedBody;

  /// "Showing data from 09:41" — the stale banner always names the moment, so
  /// "old" is never left to the imagination.
  String stateStaleBody(String time);

  // ── backup & restore (WTM-164 / ADR-TON-018) ────────────────────────────
  String get titleBackup;
  String get backupCreate;
  String get backupCreateHint;
  String get backupRestore;
  String get backupRestoreHint;
  String get backupPickFile;
  String get backupPassphraseLabel;
  String get backupPassphraseNeeded;
  String get backupPreviewTitle;
  String get backupCreatedAt;
  String get backupAppVersion;
  String get backupEncrypted;
  String get backupNotEncrypted;
  String get backupCompatible;
  String get backupContents;
  String get backupReplaceWarning;
  String get backupReplaceAction;
  String get backupConfirmTitle;
  String get backupConfirmBody;
  String get backupRestoring;
  String get backupRestoreDone;
  String get backupSafetyCopy;

  /// Action on the success card: load the pre-restore safety copy back into
  /// the preview, so a restore that turned out to be the wrong file can be
  /// walked back from inside the app.
  String get backupUndoAction;
  String get backupUndoHint;
  String get backupRejected;
  String get backupIntegrityNote;
  String get datasetCustomers;
  String get datasetProducts;
  String get datasetOrders;
  String get datasetGoals;
  String get datasetTransactions;
  String get datasetFavourites;

  /// Why a backup file was refused — one sentence per [BackupProblem].
  String backupProblem(String code);
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
  String get moreLoadHistory => 'Nạp dữ liệu mẫu 12 tháng';
  @override
  String get moreLoadHistoryConfirmTitle => 'Nạp lịch sử 12 tháng?';
  @override
  String get moreLoadHistoryConfirmBody =>
      'Sinh 12 tháng đơn hàng, thu chi và khách hàng liên tiếp (có mùa vụ Tết, '
      'hè, cuối năm) để thử Dự báo doanh thu và Rủi ro khách hàng. Dữ liệu này '
      'là bản ghi mẫu bình thường — xoá bất cứ lúc nào bằng "Xóa dữ liệu mẫu"; '
      'dữ liệu bạn tự nhập không bị ảnh hưởng.';
  @override
  String get moreHistoryLoadedSnack =>
      'Đã nạp 12 tháng dữ liệu mẫu — mở Dự báo doanh thu để xem.';
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
  String get actionNext => 'Tiếp tục';
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
  String get oppAddToJourney => 'Đưa vào hành trình';
  @override
  String oppAddedToJourneySnack(String title) =>
      'Đã đưa "$title" vào hành trình';
  @override
  String get oppAlreadyInJourney => 'Đã có trong hành trình';
  @override
  String get oppNoActiveJourney =>
      'Chưa có hành trình nào đang chạy. Hãy mở một mục tiêu và bắt đầu hành '
      'trình trước.';
  @override
  String get actionSaveChanges => 'Lưu thay đổi';
  @override
  String get sortAscending => 'Sắp xếp tăng dần';
  @override
  String get sortDescending => 'Sắp xếp giảm dần';
  @override
  String get customerAddTitle => 'Thêm khách hàng';
  @override
  String get customerEditTitle => 'Sửa khách hàng';
  @override
  String get customerSave => 'Lưu khách hàng';
  @override
  String get customerPossibleDuplicate => 'Có thể trùng với khách đã có';
  @override
  String get customerNoPurchases => 'Chưa mua lần nào';
  @override
  String customerLastPurchase(String date) => 'Mua gần nhất $date';
  @override
  String get goalFormNewTitle => 'Mục tiêu kinh doanh mới';
  @override
  String get goalFormEditTitle => 'Sửa mục tiêu';
  @override
  String get goalFormCreate => 'Tạo mục tiêu';
  @override
  String get goalReviewRevenueTarget => 'Mục tiêu doanh thu';
  @override
  String get goalReviewMetricTarget => 'Mục tiêu chỉ số';
  @override
  String get goalStartDate => 'Ngày bắt đầu';
  @override
  String get goalEndDate => 'Ngày kết thúc';
  @override
  String get goalReviewType => 'Loại';
  @override
  String get goalReviewTimeline => 'Thời gian';
  @override
  String get goalReviewNotes => 'Ghi chú';
  @override
  String get homeNoOpportunities => 'Chưa có cơ hội nào';
  @override
  String get homeNoMissions => 'Chưa có nhiệm vụ nào';
  @override
  String get oppFilterAll => 'Tất cả cơ hội';
  @override
  String get oppEmptyFeed => 'Chưa có cơ hội nào ở đây.';
  @override
  String get productSkuExists => 'SKU đã tồn tại';
  @override
  String get productNameHint => 'ví dụ: Quạt mini cầm tay';
  @override
  String get productCategoryHint => 'ví dụ: Điện tử';
  @override
  String get stockRestockNeeded => 'Cần nhập thêm';
  @override
  String stockRestockBy(int quantity) => 'Nhập thêm ít nhất $quantity';
  @override
  String get supplierNoFavoritesMatch =>
      'Không có nhà cung cấp yêu thích nào khớp';
  @override
  String get supplierNoSearchMatch =>
      'Không tìm thấy nhà cung cấp nào khớp với tìm kiếm của bạn';
  @override
  String get supplierFavoritesHint =>
      'Chạm hình trái tim trên một nhà cung cấp để thêm vào yêu thích.';
  @override
  String get supplierSearchHint => 'Thử từ khoá khác hoặc chỉnh lại bộ lọc.';

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
  String get navHome => 'Trang chủ';
  @override
  String get navProducer => 'Nguồn hàng';
  @override
  String get navInventory => 'Kho';
  @override
  String get navConsumer => 'Khách hàng';
  @override
  String get navMore => 'Thêm';

  @override
  String get actionAdd => 'Thêm';
  @override
  String get actionSave => 'Lưu';
  @override
  String get actionSend => 'Gửi';
  @override
  String get actionClearFilters => 'Xoá bộ lọc';
  @override
  String get actionPrevPage => 'Trang trước';
  @override
  String get actionNextPage => 'Trang sau';
  @override
  String get labelSort => 'Sắp xếp';
  @override
  String get labelStatus => 'Trạng thái';
  @override
  String get labelTotal => 'Tổng';
  @override
  String get labelType => 'Loại';
  @override
  String get labelLocation => 'Khu vực';
  @override
  String get labelPeriod => 'Kỳ';
  @override
  String get labelQuantity => 'Số lượng';
  @override
  String get labelDescription => 'Mô tả';
  @override
  String get formFixHighlighted => 'Vui lòng sửa các trường được đánh dấu.';
  @override
  String get changeHistory => 'Lịch sử thay đổi';

  @override
  String get chatRemoveAttachment => 'Gỡ tệp đính kèm';
  @override
  String get chatAttachFile => 'Đính kèm tệp';

  @override
  String get titleConsumerIntelligence => 'Chân dung khách hàng';
  @override
  String get titleCustomers => 'Khách hàng';
  @override
  String get segActive => 'Đang hoạt động';
  @override
  String get segVip => 'VIP';
  @override
  String get segNew => 'Mới';
  @override
  String get sectionCustomerSegments => 'Phân khúc khách hàng';
  @override
  String get emptyCustomerSegments => 'Chưa định nghĩa phân khúc khách hàng';
  @override
  String get sectionRecentInteractions => 'Tương tác gần đây';
  @override
  String get emptyRecentInteractions => 'Chưa có tương tác gần đây';
  @override
  String get sectionCustomerLifecycle => 'Vòng đời khách hàng';

  @override
  String get titleCreateOrder => 'Tạo đơn hàng';
  @override
  String get orderSoldPrice => 'Giá bán (mỗi đơn vị)';
  @override
  String get orderNeedProduct => 'Thêm ít nhất một sản phẩm';
  @override
  String get orderAddItem => 'Thêm sản phẩm';
  @override
  String get orderEmptyItems => 'Chưa có sản phẩm — bấm "Thêm sản phẩm"';

  @override
  String get custRemoveAddress => 'Xoá địa chỉ';
  @override
  String get custAddAddress => 'Thêm địa chỉ';
  @override
  String get custSegments => 'Phân khúc';
  @override
  String get custCustomSegmentHint => 'Phân khúc tuỳ chỉnh…';
  @override
  String get custAdd => 'Thêm khách hàng';
  @override
  String get custSearchHint => 'Tìm theo tên, SĐT hoặc khu vực';
  @override
  String get custPurchaseHistory => 'Lịch sử mua hàng';
  @override
  String get custEmptySearch => 'Không có khách hàng khớp tìm kiếm';
  @override
  String get custEmptySearchHint => 'Thử từ khoá khác hoặc xoá lọc khu vực.';

  @override
  String get historyRepurchase => 'Mua lại';
  @override
  String get historyEmptyOrders => 'Không có đơn hàng trong khoảng này';
  @override
  String get historyEmptyHint =>
      'Thử khoảng thời gian rộng hơn hoặc xoá lọc danh mục.';

  @override
  String get titleBusinessGoals => 'Mục tiêu kinh doanh';
  @override
  String get goalNew => 'Mục tiêu mới';

  @override
  String get titleHomeDashboard => 'Bảng điều khiển';
  @override
  String get homeChatTooltip => 'Trò chuyện Workizen AI';
  @override
  String get homeAiSubtitle =>
      'Trợ lý kinh doanh AI của bạn — nguồn hàng, kho, khách hàng và hơn nữa.';
  @override
  String get sectionBusinessKpis => 'Chỉ số kinh doanh';
  @override
  String get sectionTopOpportunities => 'Cơ hội nổi bật';
  @override
  String get homeCtaCustomer => 'Tạo khách hàng đầu tiên';
  @override
  String get homeCtaProduct => 'Thêm sản phẩm đầu tiên';
  @override
  String get homeCtaOrder => 'Tạo đơn hàng đầu tiên';
  @override
  String get homeCtaGoal => 'Đặt mục tiêu kinh doanh đầu tiên';
  @override
  String get homeCtaDemo => 'Khám phá dữ liệu mẫu';
  @override
  String get tileJourney => 'Hành trình';

  @override
  String get pickerTitle => 'Chọn sản phẩm';
  @override
  String get pickerSearchHint => 'Tìm theo tên, SKU hoặc danh mục';
  @override
  String get pickerNoMatch => 'Không có sản phẩm khớp';
  @override
  String get invAdd => 'Thêm sản phẩm';
  @override
  String get invView => 'Xem';
  @override
  String get invSearchHint => 'Tìm sản phẩm hoặc danh mục';
  @override
  @override
  String invStockAlerts(String parts) => 'Cảnh báo tồn kho: $parts';
  @override
  String supplierReviewCount(int count) => '($count đánh giá)';
  @override
  String supplierProductCount(int count) => '$count sản phẩm';
  @override
  String supplierCatalogSummary(int products, int categories) =>
      '$products sản phẩm thuộc $categories danh mục';
  @override
  String supplierMessageTitle(String name) => 'Nhắn cho $name';
  @override
  String supplierMessageSent(String name) => 'Đã gửi tin nhắn cho $name';
  @override
  String supplierMinOrder(int units, String leadTime) =>
      'Tối thiểu $units • $leadTime';
  @override
  String get homeTodaysMissions => 'Việc hôm nay';
  @override
  String homeRoiMultiple(String multiple) => 'ROI ×$multiple';
  @override
  String orderForCustomer(String name) => 'Khách hàng: $name';
  @override
  String customerAddressCount(int count) => 'Địa chỉ ($count)';
  @override
  String productImageCount(int count) => 'Hình ảnh ($count)';
  @override
  String stockQtyOfThreshold(int quantity, int threshold) =>
      'SL $quantity / $threshold';

  @override
  String supplierFromReviews(int count) => 'từ $count đánh giá';
  @override
  String invUpdatedOn(String date) => 'Cập nhật $date';
  @override
  String invShowingRange(int first, int last, int total) =>
      '$first–$last / $total';
  @override
  String invPageOf(int page, int pageCount) => 'Trang $page/$pageCount';
  @override
  String invQuantity(int quantity) => 'SL $quantity';
  @override
  String invOutOfStockCount(int count) => '$count hết hàng';
  @override
  String invLowStockCount(int count) => '$count sắp hết';

  @override
  String get invEmptySearch => 'Không có sản phẩm khớp tìm kiếm';
  @override
  String get invEmptySearchHint => 'Thử từ khoá khác hoặc xoá lọc danh mục.';
  @override
  String get titleStockAlerts => 'Cảnh báo tồn kho';
  @override
  String get stockOut => 'Hết hàng';
  @override
  String get stockLow => 'Sắp hết hàng';
  @override
  String get stockAllHealthy => 'Tồn kho đều ổn';
  @override
  String get stockAllHealthyBody =>
      'Không có sản phẩm nào chạm ngưỡng đặt lại.';

  @override
  String get moreSettings => 'Cài đặt';
  @override
  String get moreNotifications => 'Thông báo';
  @override
  String get moreTheme => 'Giao diện';
  @override
  String get moreGrokKey => 'Khóa API Grok (xAI)';
  @override
  String get moreBusinessSection => 'Kinh doanh';
  @override
  String get moreBusinessInfo => 'Thông tin doanh nghiệp';
  @override
  String get moreSupportSection => 'Hỗ trợ';
  @override
  String get moreReplayTutorial => 'Xem lại hướng dẫn';
  @override
  String get moreHelp => 'Trợ giúp & hỗ trợ';
  @override
  String get moreSendFeedback => 'Gửi phản hồi';
  @override
  String get feedbackIntro =>
      'Có gì sai, thiếu, hay khó dùng? Viết vào đây. Bạn chọn ứng dụng để gửi '
      '— Zalo, email, hay bất cứ thứ gì bạn đang dùng.';
  @override
  String get feedbackHint => 'Viết phản hồi của bạn...';
  @override
  String get feedbackSend => 'Gửi phản hồi';
  @override
  String get feedbackEmpty => 'Hãy viết vài dòng trước khi gửi.';
  @override
  String get feedbackWhatIsSent => 'Những gì được gửi kèm';
  @override
  String get feedbackNoBusinessData =>
      'Không có dữ liệu kinh doanh nào được gửi. Không đơn hàng, không khách '
      'hàng, không số tiền, không khoá AI.';
  @override
  String get feedbackMessageHeading => 'PHẢN HỒI';
  @override
  String get feedbackDiagnosticsHeading => 'THÔNG TIN KỸ THUẬT';
  @override
  String get feedbackAppVersionLabel => 'Phiên bản';
  @override
  String get feedbackPlatformLabel => 'Thiết bị';
  @override
  String get feedbackLocaleLabel => 'Ngôn ngữ';
  @override
  String get feedbackSubject => 'Phản hồi Tổng Tài';
  @override
  String get profileTitle => 'Thông tin doanh nghiệp';
  @override
  String get profileIntro =>
      'Cho Workizen AI biết bạn kinh doanh gì, để lời khuyên bớt chung chung. '
      'Bỏ qua câu nào cũng được.';
  @override
  String get profilePrivacyNote =>
      'Chỉ bốn thông tin phân loại này được gửi kèm khi bạn hỏi AI. Không có '
      'tên, số điện thoại, địa chỉ, hay con số kinh doanh nào.';
  @override
  String get profileTradeLabel => 'Bạn bán gì?';
  @override
  String get profileSizeLabel => 'Quy mô hiện tại';
  @override
  String get profileChannelsLabel => 'Bán qua kênh nào?';
  @override
  String get profileSeasonalityLabel => 'Mùa cao điểm';
  @override
  String get profileSave => 'Lưu';
  @override
  String get profileSaved => 'Đã lưu thông tin doanh nghiệp';
  @override
  String get profileSkipHint => 'Có thể sửa lại bất cứ lúc nào.';
  @override
  String profileTrade(String code) => switch (code) {
    'fashion' => 'Thời trang',
    'food' => 'Thực phẩm, đồ ăn',
    'cosmetics' => 'Mỹ phẩm',
    'electronics' => 'Điện tử',
    'home_goods' => 'Đồ gia dụng',
    'services' => 'Dịch vụ',
    _ => 'Ngành khác',
  };
  @override
  String profileSize(String code) => switch (code) {
    'solo' => 'Tự làm một mình',
    'small' => 'Nhỏ, vài người',
    'growing' => 'Đang mở rộng',
    _ => 'Đã ổn định',
  };
  @override
  String profileChannel(String code) => switch (code) {
    'shop' => 'Cửa hàng',
    'market' => 'Chợ, sạp',
    'shopee' => 'Shopee',
    'tiktok' => 'TikTok Shop',
    'facebook' => 'Facebook',
    'zalo' => 'Zalo',
    _ => 'Bán sỉ',
  };
  @override
  @override
  String get obGreeting => 'Chào bạn 👋';
  @override
  String get obGreetingBody =>
      'Tôi là Workizen AI. Cho tôi hỏi bốn câu ngắn về việc kinh doanh của bạn, '
      'để những gợi ý sau này nói đúng chuyện của bạn thay vì nói chung chung. '
      'Câu nào không muốn trả lời thì bỏ qua.';
  @override
  String get obStart => 'Bắt đầu';
  @override
  String get obSkip => 'Bỏ qua';
  @override
  String get obNext => 'Tiếp';
  @override
  String get obBack => 'Quay lại';
  @override
  String get obDone => 'Xong, vào ứng dụng';
  @override
  String get obClosing =>
      'Cảm ơn bạn. Từ giờ khi bạn hỏi, tôi đã biết bạn kinh doanh gì — gợi ý sẽ '
      'sát hơn. Bạn sửa lại bất cứ lúc nào trong Thêm › Thông tin doanh nghiệp.';
  @override
  String get obClosingEmpty =>
      'Không sao, vào dùng thử trước cũng được. Khi nào muốn kể tôi nghe về việc '
      'kinh doanh của bạn thì vào Thêm › Thông tin doanh nghiệp.';
  @override
  String get obProgress => 'Câu';
  @override
  String obQuestion(String stepId) => switch (stepId) {
    'trade' => 'Bạn đang bán gì?',
    'channels' => 'Bạn bán ở những đâu?',
    'size' => 'Hiện tại bạn làm ở quy mô nào?',
    _ => 'Có mùa nào bạn bán chạy hơn hẳn không?',
  };
  @override
  String get journeyTitle => 'Hành trình';
  @override
  String get journeyEmptyTitle => 'Chưa có hành trình nào';
  @override
  String get journeyEmptyBody =>
      'Đặt một mục tiêu rồi bắt đầu hành trình, tôi sẽ chia nó thành các bước '
      'cụ thể dựa trên việc kinh doanh của bạn.';
  @override
  String get journeyInsufficientTitle => 'Chưa đủ dữ liệu để lập kế hoạch';
  @override
  String get journeyInsufficientBody =>
      'Thêm vài sản phẩm hoặc khách hàng trước đã. Tôi không muốn đưa cho bạn '
      'một kế hoạch chung chung không dính gì tới việc bạn đang làm.';
  @override
  String get journeyProgress => 'Tiến độ';
  @override
  String get journeyFromRule => 'Hệ thống đề xuất';
  @override
  String get journeyFromOpportunity => 'Từ cơ hội bạn đã chọn';
  @override
  String get journeyMeasured => 'Tự tính từ dữ liệu';
  @override
  String profileSeasonality(String code) => switch (code) {
    'none' => 'Bán đều quanh năm',
    'tet' => 'Cao điểm dịp Tết',
    'school_year' => 'Cao điểm mùa tựu trường',
    'summer' => 'Cao điểm mùa hè',
    _ => 'Cao điểm cuối năm',
  };
  @override
  String get moreLegalSection => 'Pháp lý';
  @override
  String get moreTerms => 'Điều khoản dịch vụ';
  @override
  String get morePrivacy => 'Chính sách quyền riêng tư';

  @override
  @override
  String aboutVersion(String version) => 'Phiên bản $version';
  @override
  String get aboutWhatTitle => 'Tổng Tài là gì';
  @override
  String get aboutWhatBody =>
      'Một hệ điều hành kinh doanh cho người bán hàng: nguồn hàng, tồn kho, '
      'khách hàng, đơn hàng, tài chính, báo cáo, mục tiêu và cơ hội — trong '
      'một ứng dụng chạy được cả khi mất mạng.';
  @override
  String get aboutDataTitle => 'Dữ liệu của bạn ở đâu';
  @override
  String get aboutDataBody =>
      'Trên chính máy này. Không tài khoản, không máy chủ, không đồng bộ. Bạn '
      'mang dữ liệu đi bằng file CSV hoặc bản sao lưu, và gỡ app là xoá sạch.';
  @override
  String get aboutAiTitle => 'Workizen AI';
  @override
  String get aboutAiBody =>
      'AI là phần giải thích, không phải phần tính. Các con số do quy tắc xác '
      'định tính ra và chạy được khi không có mạng, không có khoá; AI chỉ diễn '
      'giải chúng bằng khoá của chính bạn.';
  @override
  String get settingsComingSoon => 'Sắp có';

  @override
  String get privacyTitle => 'Chính sách quyền riêng tư';
  @override
  String get privacyUpdated => 'Cập nhật 31/07/2026';
  @override
  String get privacyLocalTitle => 'Dữ liệu kinh doanh nằm trên máy bạn';
  @override
  String get privacyLocalBody =>
      'Khách hàng, sản phẩm, đơn hàng, mục tiêu, giao dịch — tất cả lưu trên '
      'thiết bị này. Không tài khoản, không máy chủ Tổng Tài, không đồng bộ. '
      'Chúng tôi không nhận được dữ liệu kinh doanh của bạn.';
  @override
  String get privacyAiTitle => 'Workizen AI dùng khoá của chính bạn';
  @override
  String get privacyAiBody =>
      'Khi bạn hỏi Workizen AI, nội dung câu hỏi đi thẳng từ máy bạn tới nhà '
      'cung cấp bạn đã chọn, kèm khoá API của bạn. Chúng tôi không trung '
      'chuyển và không thấy nội dung đó — chính sách của nhà cung cấp áp dụng '
      'cho phần họ nhận. Dùng chế độ Local (Ollama) thì không có gì rời máy. '
      'Khoá lưu trong kho bảo mật của hệ điều hành, không nằm trong bản sao lưu.';
  @override
  String get privacyTelemetryTitle => 'Số liệu vận hành chúng tôi nhận';
  @override
  String get privacyTelemetryBody =>
      'Chỉ hai thứ: app được mở (không kèm tham số nào), và một màn không đọc '
      'được dữ liệu (kèm tên màn, loại lỗi, mã lỗi cố định). Không có tên khách '
      'hàng, số tiền, số bản ghi, tên file hay đường dẫn. Mô tả lỗi chi tiết '
      'chỉ hiện trên máy bạn.';
  @override
  String get privacyCrashTitle => 'Báo cáo sự cố';
  @override
  String get privacyCrashBody =>
      'Khi app dừng đột ngột, chúng tôi nhận stack trace, model máy và phiên '
      'bản hệ điều hành để sửa lỗi. Báo cáo gọi tên loại lỗi nhưng cố ý không '
      'mang theo giá trị dữ liệu, tên khách hàng hay con số doanh thu.';
  @override
  String get privacyNoAdsTitle => 'Không quảng cáo, không hồ sơ người dùng';
  @override
  String get privacyNoAdsBody =>
      'Không SDK quảng cáo, không theo dõi tiếp thị, không lập hồ sơ, không '
      'quảng cáo cá nhân hoá. Quyền Advertising ID bị gỡ khỏi ứng dụng. Quyền '
      'duy nhất app xin là truy cập Internet, để gọi nhà cung cấp AI bạn chọn.';
  @override
  String get privacyBackupTitle => 'Sao lưu';
  @override
  String get privacyBackupBody =>
      'Bản sao lưu tạo trên máy bạn và chỉ rời khỏi máy nếu bạn chủ động chia '
      'sẻ. Bạn có thể đặt mật khẩu. Mã kiểm tra SHA-256 dùng để phát hiện file '
      'hỏng — đó là chống hỏng, không phải chống giả mạo. Bản sao lưu chứa dữ '
      'liệu kinh doanh, không chứa khoá API.';
  @override
  String get privacySampleTitle => 'Dữ liệu mẫu';
  @override
  String get privacySampleBody =>
      'Dữ liệu mẫu được ghi vào chính kho dữ liệu thật với tiền tố riêng, và '
      'chỉ đúng những bản ghi đó bị gỡ khi bạn xoá dữ liệu mẫu. Dữ liệu bạn tự '
      'nhập không bao giờ bị xoá bởi thao tác này.';
  @override
  String get privacyRightsTitle => 'Quyền của bạn';
  @override
  String get privacyRightsBody =>
      'Gỡ app hoặc xoá dữ liệu ứng dụng là xoá sạch — dữ liệu chỉ nằm trên máy '
      'nên không có bản sao ở nơi khác. Bạn có thể mang dữ liệu đi bằng file '
      'CSV hoặc bản sao lưu. Xoá khoá API là tắt AI; app vẫn chạy đủ chức năng.';

  @override
  String get titleOpportunities => 'Cơ hội';

  @override
  String get titleProducerHub => 'Trung tâm nguồn hàng';
  @override
  String get producerAiSummary => 'Tóm tắt AI';
  @override
  String get producerAiCapabilities => 'Năng lực AI';
  @override
  String get producerCapScoring => 'Chấm điểm cơ hội';
  @override
  String get producerCapRanking => 'Xếp hạng nhà cung cấp';
  @override
  String get producerCapTrends => 'Xu hướng thị trường';
  @override
  String get producerCapPrice => 'Phân tích giá';
  @override
  String get producerCapQuality => 'Đánh giá chất lượng';
  @override
  String get producerCapDelivery => 'Thời gian giao hàng';
  @override
  String get producerRecentOpps => 'Cơ hội gần đây';
  @override
  String get producerEmptyOpps => 'Chưa phát hiện cơ hội nào';
  @override
  String get producerVerifiedSuppliers => 'Nhà cung cấp đã xác minh';
  @override
  String get producerEmptySuppliers => 'Chưa kết nối nhà cung cấp nào';

  @override
  String get formWrite => 'Soạn';
  @override
  String get formPreview => 'Xem trước';
  @override
  String get formNothingToPreview => 'Chưa có gì để xem trước.';
  @override
  String get formMarkdownHint =>
      'Hỗ trợ **markdown** — tiêu đề, **đậm**, danh sách…';
  @override
  String get formUpload => 'Tải lên';
  @override
  String get formCamera => 'Máy ảnh';
  @override
  String get formRemoveImage => 'Xoá ảnh';
  @override
  String get titleEditProduct => 'Sửa sản phẩm';
  @override
  String get titleAddProduct => 'Thêm sản phẩm';
  @override
  String get formSaveChanges => 'Lưu thay đổi';
  @override
  String get formSaveProduct => 'Lưu sản phẩm';
  @override
  String get favAdd => 'Thêm vào yêu thích';
  @override
  String get lifecycleAwareness => 'Nhận biết';
  @override
  String get lifecycleConsideration => 'Cân nhắc';
  @override
  String get lifecyclePurchase => 'Mua hàng';
  @override
  String get lifecycleRetention => 'Giữ chân';

  @override
  String get labelSupplier => 'Nhà cung cấp';
  @override
  String get supAbout => 'Giới thiệu';
  @override
  String get supRatingsCerts => 'Đánh giá & chứng nhận';
  @override
  String get supProductCatalog => 'Danh mục sản phẩm';
  @override
  String get supTransactionHistory => 'Lịch sử giao dịch';
  @override
  String get supTotalVolume => 'Tổng khối lượng';
  @override
  String get supTotalOrders => 'Tổng đơn hàng';
  @override
  String get supRepeatBuyers => 'Khách mua lại';
  @override
  String get supContact => 'Liên hệ';
  @override
  String get supMessage => 'Nhắn nhà cung cấp';
  @override
  String get supAskHint => 'Hỏi về giá, MOQ, thời gian giao…';
  @override
  String get titleSupplierSearch => 'Tìm nhà cung cấp';
  @override
  String get titleFavoriteSuppliers => 'Nhà cung cấp yêu thích';
  @override
  String get supSearchHint => 'Tìm nhà cung cấp, danh mục, khu vực';
  @override
  String get supShow => 'Hiển thị';
  @override
  String get supFavorites => 'Yêu thích';
  @override
  String get favRemove => 'Bỏ khỏi yêu thích';
  @override
  String get favEmpty => 'Chưa có nhà cung cấp yêu thích';
  @override
  String get favEmptyHint =>
      'Bấm biểu tượng tim trên nhà cung cấp để thêm vào đây.';

  @override
  String get txnIncome => 'Thu';
  @override
  String get txnExpense => 'Chi';

  @override
  String producerSummaryLine(int opportunities, int favorites) =>
      '$opportunities cơ hội từ dữ liệu của bạn · '
      '$favorites nhà cung cấp yêu thích.';

  @override
  String get titleForecast => 'Dự báo doanh thu';
  @override
  String get titleCustomerRisk => 'Rủi ro khách hàng';
  @override
  String get forecastNextMonth => 'Dự báo tháng tới';
  @override
  String get forecastRange => 'Khoảng dự báo';
  @override
  String get forecastConfidence => 'Độ tin cậy';
  @override
  String get forecastBasis => 'Tính từ các tháng';
  @override
  String get forecastInsufficient => 'Chưa đủ dữ liệu để dự báo';
  @override
  String get forecastInsufficientBody =>
      'Cần ít nhất 3 tháng có doanh thu. Ghi thêm đơn hàng hoặc nạp dữ liệu '
      'mẫu 12 tháng trong More để xem thử.';
  @override
  String get forecastHistory => 'Doanh thu theo tháng';
  @override
  String get forecastVsPrevious => 'So với kỳ trước';
  @override
  String get forecastWhy => 'Vì sao';
  @override
  String get forecastRuleBased => 'Quy tắc (không cần AI)';
  @override
  String get riskStageActive => 'Đang mua';
  @override
  String get riskStageCooling => 'Đang nguội';
  @override
  String get riskStageAtRisk => 'Nguy cơ rời';
  @override
  String get riskStageChurned => 'Đã rời bỏ';
  @override
  String get riskStageNeverPurchased => 'Chưa mua lần nào';
  @override
  String get riskWinBack => 'Nên kéo lại';
  @override
  String get riskEmpty => 'Chưa có khách hàng để đánh giá';
  @override
  String get riskEmptyBody =>
      'Thêm khách hàng và ghi đơn hàng để hệ thống theo dõi nhịp mua.';
  @override
  String get riskRecommendedActions => 'Nên làm gì';
  @override
  String get riskActionContact => 'Liên hệ hỏi thăm';
  @override
  String get riskActionOffer => 'Gửi ưu đãi kéo lại';
  @override
  String get riskNoData => 'Chưa đủ dữ liệu để đánh giá rủi ro';
  @override
  String get aiExplain => 'Nhờ AI giải thích';
  @override
  String get aiExplainRunning => 'Workizen AI đang giải thích…';
  @override
  String daysSincePurchase(int days) => '$days ngày chưa mua';
  @override
  String riskScoreLabel(int score) => 'Điểm rủi ro $score';
  @override
  String customersAtRisk(int count) => '$count khách có nguy cơ rời';

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

  @override
  String get stateLoading => 'Đang tải…';
  @override
  String get stateEmpty => 'Chưa có dữ liệu';
  @override
  String get stateRetry => 'Thử lại';
  @override
  String get stateInsufficientTitle => 'Chưa đủ dữ liệu để kết luận';
  @override
  String get stateInsufficientBody =>
      'Ghi thêm dữ liệu thật rồi quay lại — hệ thống sẽ không đoán bừa.';
  @override
  String get stateStaleTitle => 'Dữ liệu chưa được làm mới';
  @override
  String get stateTechnicalDetail => 'Chi tiết kỹ thuật';
  @override
  String get errorStorageTitle => 'Không đọc được dữ liệu trên máy';
  @override
  String get errorStorageBody =>
      'Dữ liệu vẫn nằm trên máy bạn, nhưng lần đọc này thất bại. '
      'Thử lại; nếu vẫn lỗi, khởi động lại ứng dụng.';
  @override
  String get errorNetworkTitle => 'Không kết nối được';
  @override
  String get errorNetworkBody =>
      'Kiểm tra kết nối mạng rồi thử lại. Dữ liệu kinh doanh của bạn vẫn ở '
      'trên máy và không cần mạng.';
  @override
  String get errorPermissionTitle => 'Thiếu quyền truy cập';
  @override
  String get errorPermissionBody =>
      'Hệ điều hành đã từ chối. Cấp quyền trong Cài đặt rồi mở lại màn này.';
  @override
  String get errorConfigurationTitle => 'Cần thiết lập trước';
  @override
  String get errorConfigurationBody =>
      'Thiếu cấu hình để chạy được thao tác này. Hoàn tất thiết lập rồi thử '
      'lại.';
  @override
  String get errorUnexpectedTitle => 'Lỗi không mong đợi';
  @override
  String get errorUnexpectedBody =>
      'Đây là lỗi chưa được phân loại. Chi tiết kỹ thuật bên dưới giữ nguyên '
      'để bạn (hoặc chúng tôi) truy được nguyên nhân.';
  @override
  String stateStaleBody(String time) =>
      'Đang xem dữ liệu lúc $time. Lần làm mới gần nhất thất bại.';

  @override
  String get titleBackup => 'Sao lưu & khôi phục';
  @override
  String get backupCreate => 'Tạo file sao lưu (.ttbk)';
  @override
  String get backupCreateHint =>
      'Toàn bộ dữ liệu kinh doanh trong một file: khách hàng, sản phẩm, đơn '
      'hàng, mục tiêu, thu chi, nhà cung cấp yêu thích.';
  @override
  String get backupRestore => 'Khôi phục từ file sao lưu';
  @override
  String get backupRestoreHint =>
      'Thay thế toàn bộ dữ liệu hiện tại bằng nội dung file sao lưu.';
  @override
  String get backupPickFile => 'Chọn file .ttbk';
  @override
  String get backupPassphraseLabel => 'Mật khẩu của file sao lưu';
  @override
  String get backupPassphraseNeeded =>
      'File này được mã hoá. Nhập mật khẩu để xem nội dung.';
  @override
  String get backupPreviewTitle => 'Nội dung file sao lưu';
  @override
  String get backupCreatedAt => 'Tạo lúc';
  @override
  String get backupAppVersion => 'Phiên bản app / CSDL';
  @override
  String get backupEncrypted => 'Có mã hoá';
  @override
  String get backupNotEncrypted => 'Không mã hoá';
  @override
  String get backupCompatible => 'Tương thích với bản app này';
  @override
  String get backupContents => 'Số bản ghi sẽ được khôi phục';
  @override
  String get backupReplaceWarning =>
      'Toàn bộ dữ liệu kinh doanh hiện tại trên máy sẽ bị THAY THẾ bằng dữ '
      'liệu trong file này. App sẽ tự tạo một bản sao lưu an toàn trước khi '
      'thay.';
  @override
  String get backupReplaceAction => 'Thay thế dữ liệu hiện tại';
  @override
  String get backupConfirmTitle => 'Thay thế dữ liệu hiện tại?';
  @override
  String get backupConfirmBody =>
      'Không thể hoàn tác bằng một nút bấm. Bản sao lưu an toàn sẽ được tạo '
      'trước, và đường dẫn hiện ngay sau khi xong.';
  @override
  String get backupRestoring => 'Đang khôi phục…';
  @override
  String get backupRestoreDone => 'Đã khôi phục xong';
  @override
  String get backupSafetyCopy => 'Bản sao lưu an toàn trước khi khôi phục';
  @override
  String get backupUndoAction => 'Quay lại dữ liệu trước khi khôi phục';
  @override
  String get backupUndoHint =>
      'Mở bản sao lưu an toàn ở trên để xem trước. Bạn vẫn phải xác nhận lần '
      'nữa trước khi nó thay thế dữ liệu hiện tại.';
  @override
  String get backupRejected => 'Không dùng được file này';
  @override
  String get backupIntegrityNote =>
      'Checksum SHA-256 phát hiện file hỏng hoặc thiếu, KHÔNG chứng minh file '
      'là thật. Chỉ file có mã hoá mới chống sửa đổi.';
  @override
  String get datasetCustomers => 'Khách hàng';
  @override
  String get datasetProducts => 'Sản phẩm';
  @override
  String get datasetOrders => 'Đơn hàng';
  @override
  String get datasetGoals => 'Mục tiêu';
  @override
  String get datasetTransactions => 'Thu chi';
  @override
  String get datasetFavourites => 'NCC yêu thích';
  @override
  String backupProblem(String code) => switch (code) {
    'notABackup' => 'Đây không phải file sao lưu Tổng Tài (.ttbk v2).',
    'tooNew' =>
      'File được tạo bởi bản app mới hơn. Hãy cập nhật app rồi thử lại.',
    'unsupportedVersion' => 'Bản app này không đọc được phiên bản file đó.',
    'truncated' => 'File bị thiếu dữ liệu (có thể sao chép chưa xong).',
    'checksumMismatch' => 'File bị hỏng — checksum không khớp.',
    'passphraseRequired' => 'File có mã hoá. Cần nhập mật khẩu.',
    'wrongPassphrase' => 'Mật khẩu không đúng, hoặc file đã bị sửa đổi.',
    'malformedPayload' => 'Nội dung file không đọc được.',
    'missingDataset' =>
      'File thiếu một phần dữ liệu nên không phải bản đầy đủ.',
    'invalidRecord' => 'Có bản ghi trong file bị sai định dạng.',
    'duplicateId' => 'File có bản ghi trùng mã.',
    'brokenForeignKey' => 'File có đơn hàng trỏ tới khách hàng không tồn tại.',
    'countMismatch' => 'Số bản ghi khai báo không khớp nội dung thật.',
    'notRestorableKind' =>
      'File này là gói dữ liệu loại khác (không phải bản sao lưu để khôi phục).',
    'redactedPackage' =>
      'File này đã bị lược bỏ thông tin cá nhân nên không dùng để khôi phục được.',
    _ => 'Không khôi phục được từ file này.',
  };
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
  String get moreLoadHistory => 'Load 12 months of sample data';
  @override
  String get moreLoadHistoryConfirmTitle => 'Load 12 months of history?';
  @override
  String get moreLoadHistoryConfirmBody =>
      'Generates 12 consecutive months of orders, cash flow and customers '
      '(with Tết, summer and year-end seasonality) so you can try Revenue '
      'forecast and Customer risk. These are ordinary sample rows — remove '
      'them any time with "Remove sample data"; your own data is untouched.';
  @override
  String get moreHistoryLoadedSnack =>
      'Loaded 12 months of sample data — open Revenue forecast to see it.';
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
  String get actionNext => 'Next';
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
  String get oppAddToJourney => 'Add to journey';
  @override
  String oppAddedToJourneySnack(String title) =>
      'Added "$title" to the journey';
  @override
  String get oppAlreadyInJourney => 'Already in the journey';
  @override
  String get oppNoActiveJourney =>
      'No journey is running yet. Open a goal and start a journey first.';
  @override
  String get actionSaveChanges => 'Save changes';
  @override
  String get sortAscending => 'Sort ascending';
  @override
  String get sortDescending => 'Sort descending';
  @override
  String get customerAddTitle => 'Add customer';
  @override
  String get customerEditTitle => 'Edit customer';
  @override
  String get customerSave => 'Save customer';
  @override
  String get customerPossibleDuplicate => 'Possible duplicate customer';
  @override
  String get customerNoPurchases => 'No purchases yet';
  @override
  String customerLastPurchase(String date) => 'Last purchase $date';
  @override
  String get goalFormNewTitle => 'New business goal';
  @override
  String get goalFormEditTitle => 'Edit goal';
  @override
  String get goalFormCreate => 'Create goal';
  @override
  String get goalReviewRevenueTarget => 'Revenue target';
  @override
  String get goalReviewMetricTarget => 'Metric target';
  @override
  String get goalStartDate => 'Start date';
  @override
  String get goalEndDate => 'End date';
  @override
  String get goalReviewType => 'Type';
  @override
  String get goalReviewTimeline => 'Timeline';
  @override
  String get goalReviewNotes => 'Notes';
  @override
  String get homeNoOpportunities => 'No opportunities yet';
  @override
  String get homeNoMissions => 'No missions yet';
  @override
  String get oppFilterAll => 'All opportunities';
  @override
  String get oppEmptyFeed => 'No opportunities here yet.';
  @override
  String get productSkuExists => 'SKU already exists';
  @override
  String get productNameHint => 'e.g. Handheld mini fan';
  @override
  String get productCategoryHint => 'e.g. Electronics';
  @override
  String get stockRestockNeeded => 'Restock needed';
  @override
  String stockRestockBy(int quantity) => 'Restock $quantity+ to clear';
  @override
  String get supplierNoFavoritesMatch => 'No favourite suppliers match';
  @override
  String get supplierNoSearchMatch => 'No suppliers match your search';
  @override
  String get supplierFavoritesHint =>
      'Tap the heart on a supplier to add it to your favourites.';
  @override
  String get supplierSearchHint =>
      'Try a different keyword or adjust your filters.';

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
  String get navHome => 'Home';
  @override
  String get navProducer => 'Producer';
  @override
  String get navInventory => 'Inventory';
  @override
  String get navConsumer => 'Consumer';
  @override
  String get navMore => 'More';

  @override
  String get actionAdd => 'Add';
  @override
  String get actionSave => 'Save';
  @override
  String get actionSend => 'Send';
  @override
  String get actionClearFilters => 'Clear filters';
  @override
  String get actionPrevPage => 'Previous page';
  @override
  String get actionNextPage => 'Next page';
  @override
  String get labelSort => 'Sort';
  @override
  String get labelStatus => 'Status';
  @override
  String get labelTotal => 'Total';
  @override
  String get labelType => 'Type';
  @override
  String get labelLocation => 'Location';
  @override
  String get labelPeriod => 'Period';
  @override
  String get labelQuantity => 'Quantity';
  @override
  String get labelDescription => 'Description';
  @override
  String get formFixHighlighted => 'Please fix the highlighted fields.';
  @override
  String get changeHistory => 'Change history';

  @override
  String get chatRemoveAttachment => 'Remove attachment';
  @override
  String get chatAttachFile => 'Attach file';

  @override
  String get titleConsumerIntelligence => 'Customer Intelligence';
  @override
  String get titleCustomers => 'Customers';
  @override
  String get segActive => 'Active';
  @override
  String get segVip => 'VIP';
  @override
  String get segNew => 'New';
  @override
  String get sectionCustomerSegments => 'Customer Segments';
  @override
  String get emptyCustomerSegments => 'No customer segments defined yet';
  @override
  String get sectionRecentInteractions => 'Recent Interactions';
  @override
  String get emptyRecentInteractions => 'No recent interactions';
  @override
  String get sectionCustomerLifecycle => 'Customer Lifecycle';

  @override
  String get titleCreateOrder => 'Create Order';
  @override
  String get orderSoldPrice => 'Sold price (per unit)';
  @override
  String get orderNeedProduct => 'Add at least one product';
  @override
  String get orderAddItem => 'Add item';
  @override
  String get orderEmptyItems => 'No products yet — tap "Add item"';

  @override
  String get custRemoveAddress => 'Remove address';
  @override
  String get custAddAddress => 'Add address';
  @override
  String get custSegments => 'Segments';
  @override
  String get custCustomSegmentHint => 'Custom segment…';
  @override
  String get custAdd => 'Add customer';
  @override
  String get custSearchHint => 'Search name, phone or location';
  @override
  String get custPurchaseHistory => 'Purchase history';
  @override
  String get custEmptySearch => 'No customers match your search';
  @override
  String get custEmptySearchHint =>
      'Try a different keyword or clear the location filter.';

  @override
  String get historyRepurchase => 'Repurchase';
  @override
  String get historyEmptyOrders => 'No orders in this period';
  @override
  String get historyEmptyHint =>
      'Try a wider period or clear the category filter.';

  @override
  String get titleBusinessGoals => 'Business Goals';
  @override
  String get goalNew => 'New goal';

  @override
  String get titleHomeDashboard => 'Home Dashboard';
  @override
  String get homeChatTooltip => 'Workizen AI chat';
  @override
  String get homeAiSubtitle =>
      'Your AI-powered business assistant for sourcing, '
      'inventory, customers, and more.';
  @override
  String get sectionBusinessKpis => 'Business KPIs';
  @override
  String get sectionTopOpportunities => 'Top Opportunities';
  @override
  String get homeCtaCustomer => 'Create your first customer';
  @override
  String get homeCtaProduct => 'Add your first product';
  @override
  String get homeCtaOrder => 'Create your first order';
  @override
  String get homeCtaGoal => 'Set your first business goal';
  @override
  String get homeCtaDemo => 'Explore Demo Mode';
  @override
  String get tileJourney => 'Journey';

  @override
  String get pickerTitle => 'Pick a product';
  @override
  String get pickerSearchHint => 'Search name, SKU or category';
  @override
  String get pickerNoMatch => 'No products match';
  @override
  String get invAdd => 'Add product';
  @override
  String get invView => 'View';
  @override
  String get invSearchHint => 'Search products or categories';
  @override
  @override
  String invStockAlerts(String parts) => 'Stock alerts: $parts';
  @override
  String supplierReviewCount(int count) => '($count reviews)';
  @override
  String supplierProductCount(int count) => '$count products';
  @override
  String supplierCatalogSummary(int products, int categories) =>
      '$products products across $categories '
      '${categories == 1 ? 'category' : 'categories'}';
  @override
  String supplierMessageTitle(String name) => 'Message $name';
  @override
  String supplierMessageSent(String name) => 'Message sent to $name';
  @override
  String supplierMinOrder(int units, String leadTime) =>
      'Min $units • $leadTime';
  @override
  String get homeTodaysMissions => "Today's Missions";
  @override
  String homeRoiMultiple(String multiple) => 'ROI ×$multiple';
  @override
  String orderForCustomer(String name) => 'Customer: $name';
  @override
  String customerAddressCount(int count) => 'Addresses ($count)';
  @override
  String productImageCount(int count) => 'Images ($count)';
  @override
  String stockQtyOfThreshold(int quantity, int threshold) =>
      'Qty $quantity / $threshold';

  @override
  String supplierFromReviews(int count) => 'from $count reviews';
  @override
  String invUpdatedOn(String date) => 'Updated $date';
  @override
  String invShowingRange(int first, int last, int total) =>
      '$first–$last of $total';
  @override
  String invPageOf(int page, int pageCount) => 'Page $page/$pageCount';
  @override
  String invQuantity(int quantity) => 'Qty $quantity';
  @override
  String invOutOfStockCount(int count) => '$count out of stock';
  @override
  String invLowStockCount(int count) => '$count low';

  @override
  String get invEmptySearch => 'No products match your search';
  @override
  String get invEmptySearchHint =>
      'Try a different keyword or clear the category filter.';
  @override
  String get titleStockAlerts => 'Stock alerts';
  @override
  String get stockOut => 'Out of stock';
  @override
  String get stockLow => 'Low stock';
  @override
  String get stockAllHealthy => 'All stock levels healthy';
  @override
  String get stockAllHealthyBody =>
      'No products are at or below their reorder threshold.';

  @override
  String get moreSettings => 'Settings';
  @override
  String get moreNotifications => 'Notifications';
  @override
  String get moreTheme => 'Theme';
  @override
  String get moreGrokKey => 'Grok (xAI) API key';
  @override
  String get moreBusinessSection => 'Business';
  @override
  String get moreBusinessInfo => 'Business Info';
  @override
  String get moreSupportSection => 'Support';
  @override
  String get moreReplayTutorial => 'Replay Tutorial';
  @override
  String get moreHelp => 'Help & Support';
  @override
  String get moreSendFeedback => 'Send Feedback';
  @override
  String get feedbackIntro =>
      'Something wrong, missing, or hard to use? Write it here. You pick the '
      'app to send it with — Zalo, email, whatever you already use.';
  @override
  String get feedbackHint => 'Write your feedback...';
  @override
  String get feedbackSend => 'Send feedback';
  @override
  String get feedbackEmpty => 'Write a few lines before sending.';
  @override
  String get feedbackWhatIsSent => 'What gets attached';
  @override
  String get feedbackNoBusinessData =>
      'No business data is sent. No orders, no customers, no amounts, no AI '
      'keys.';
  @override
  String get feedbackMessageHeading => 'FEEDBACK';
  @override
  String get feedbackDiagnosticsHeading => 'TECHNICAL INFO';
  @override
  String get feedbackAppVersionLabel => 'Version';
  @override
  String get feedbackPlatformLabel => 'Device';
  @override
  String get feedbackLocaleLabel => 'Language';
  @override
  String get feedbackSubject => 'Tổng Tài feedback';
  @override
  String get profileTitle => 'Business info';
  @override
  String get profileIntro =>
      'Tell Workizen AI what you sell, so its advice stops being generic. '
      'Skip anything you would rather not answer.';
  @override
  String get profilePrivacyNote =>
      'Only these four categorical facts are sent along when you ask the AI. '
      'No names, phone numbers, addresses or business figures.';
  @override
  String get profileTradeLabel => 'What do you sell?';
  @override
  String get profileSizeLabel => 'Current size';
  @override
  String get profileChannelsLabel => 'Where do you sell?';
  @override
  String get profileSeasonalityLabel => 'Busiest season';
  @override
  String get profileSave => 'Save';
  @override
  String get profileSaved => 'Business info saved';
  @override
  String get profileSkipHint => 'You can change this any time.';
  @override
  String profileTrade(String code) => switch (code) {
    'fashion' => 'Fashion',
    'food' => 'Food and drink',
    'cosmetics' => 'Cosmetics',
    'electronics' => 'Electronics',
    'home_goods' => 'Home goods',
    'services' => 'Services',
    _ => 'Something else',
  };
  @override
  String profileSize(String code) => switch (code) {
    'solo' => 'Just me',
    'small' => 'Small, a few people',
    'growing' => 'Growing',
    _ => 'Established',
  };
  @override
  String profileChannel(String code) => switch (code) {
    'shop' => 'Shop',
    'market' => 'Market stall',
    'shopee' => 'Shopee',
    'tiktok' => 'TikTok Shop',
    'facebook' => 'Facebook',
    'zalo' => 'Zalo',
    _ => 'Wholesale',
  };
  @override
  @override
  String get obGreeting => 'Hello 👋';
  @override
  String get obGreetingBody =>
      'I am Workizen AI. Let me ask four short questions about your business, so '
      'my advice talks about your shop instead of shops in general. Skip any '
      'question you would rather not answer.';
  @override
  String get obStart => 'Start';
  @override
  String get obSkip => 'Skip';
  @override
  String get obNext => 'Next';
  @override
  String get obBack => 'Back';
  @override
  String get obDone => 'Done, open the app';
  @override
  String get obClosing =>
      'Thank you. From now on I know what you sell, so my suggestions will fit '
      'better. Change any of it under More › Business info.';
  @override
  String get obClosingEmpty =>
      'That is fine — have a look around first. When you want to tell me about '
      'your business, it is under More › Business info.';
  @override
  String get obProgress => 'Question';
  @override
  String obQuestion(String stepId) => switch (stepId) {
    'trade' => 'What do you sell?',
    'channels' => 'Where do you sell?',
    'size' => 'How big is it right now?',
    _ => 'Any season when you sell much more?',
  };
  @override
  String get journeyTitle => 'Journey';
  @override
  String get journeyEmptyTitle => 'No journey yet';
  @override
  String get journeyEmptyBody =>
      'Set a goal and start a journey — I will break it into concrete steps '
      'based on how your business actually works.';
  @override
  String get journeyInsufficientTitle => 'Not enough data to plan yet';
  @override
  String get journeyInsufficientBody =>
      'Add a few products or customers first. I would rather not hand you a '
      'generic plan that has nothing to do with what you are doing.';
  @override
  String get journeyProgress => 'Progress';
  @override
  String get journeyFromRule => 'Suggested by the system';
  @override
  String get journeyFromOpportunity => 'From an opportunity you chose';
  @override
  String get journeyMeasured => 'Counted from your data';
  @override
  String profileSeasonality(String code) => switch (code) {
    'none' => 'Steady all year',
    'tet' => 'Peaks at Tet',
    'school_year' => 'Peaks at back-to-school',
    'summer' => 'Peaks in summer',
    _ => 'Peaks at year end',
  };
  @override
  String get moreLegalSection => 'Legal';
  @override
  String get moreTerms => 'Terms of Service';
  @override
  String get morePrivacy => 'Privacy Policy';

  @override
  @override
  String aboutVersion(String version) => 'Version $version';
  @override
  String get aboutWhatTitle => 'What Tổng Tài is';
  @override
  String get aboutWhatBody =>
      'A business operating system for sellers: sourcing, inventory, customers, '
      'orders, finance, reports, goals and opportunities — in one app that '
      'works offline.';
  @override
  String get aboutDataTitle => 'Where your data lives';
  @override
  String get aboutDataBody =>
      'On this device. No account, no server, no sync. You can take it with you '
      'as CSV or a backup file, and uninstalling deletes all of it.';
  @override
  String get aboutAiTitle => 'Workizen AI';
  @override
  String get aboutAiBody =>
      'AI explains; it does not compute. The numbers come from deterministic '
      'rules that run with no network and no key; AI only puts them into words, '
      'using your own key.';
  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get privacyTitle => 'Privacy Policy';
  @override
  String get privacyUpdated => 'Updated 31 July 2026';
  @override
  String get privacyLocalTitle => 'Your business data stays on your device';
  @override
  String get privacyLocalBody =>
      'Customers, products, orders, goals and transactions are all stored on '
      'this device. No account, no Tổng Tài server, no sync. We never receive '
      'your business data.';
  @override
  String get privacyAiTitle => 'Workizen AI uses your own key';
  @override
  String get privacyAiBody =>
      'When you ask Workizen AI, your message goes directly from this device to '
      'the provider you chose, authenticated with your own API key. We do not '
      'proxy it and never see it — the provider\'s own policy governs what they '
      'receive. In Local (Ollama) mode nothing leaves the device. Keys live in '
      'the operating system secure store and are never included in a backup.';
  @override
  String get privacyTelemetryTitle => 'The operational data we do receive';
  @override
  String get privacyTelemetryBody =>
      'Two things only: that the app was opened (with no parameters at all), '
      'and that a screen failed to load data (with the screen name, the failure '
      'kind and a fixed error code). No customer names, amounts, record counts, '
      'file names or paths. Detailed error text stays on your device.';
  @override
  String get privacyCrashTitle => 'Crash reports';
  @override
  String get privacyCrashBody =>
      'If the app stops unexpectedly we receive a stack trace, your device '
      'model and OS version so we can fix it. A report names the kind of '
      'failure but deliberately carries no data value, customer name or revenue '
      'figure.';
  @override
  String get privacyNoAdsTitle => 'No ads, no profiling';
  @override
  String get privacyNoAdsBody =>
      'No ad SDKs, no marketing tracking, no profiling, no personalised ads. '
      'The Advertising ID permission is stripped from the app. The only '
      'permission requested is internet access, to reach the AI provider you '
      'chose.';
  @override
  String get privacyBackupTitle => 'Backups';
  @override
  String get privacyBackupBody =>
      'A backup is created on your device and leaves it only if you share it. '
      'You can set a passphrase. The SHA-256 checksum detects a corrupted file '
      '— it is corruption protection, not tamper protection. Backups contain '
      'your business data; they never contain API keys.';
  @override
  String get privacySampleTitle => 'Sample data';
  @override
  String get privacySampleBody =>
      'Sample data is written into the real repositories under its own prefix, '
      'and only those records are removed when you delete it. Data you entered '
      'yourself is never deleted by that action.';
  @override
  String get privacyRightsTitle => 'Your choices';
  @override
  String get privacyRightsBody =>
      'Uninstalling the app or clearing its data deletes everything — the data '
      'is only on this device, so that is all of it. You can take your data '
      'with you as CSV or as a backup file. Removing your API key turns AI off; '
      'the app works fully without it.';

  @override
  String get titleOpportunities => 'Opportunities';

  @override
  String get titleProducerHub => 'Producer Hub';
  @override
  String get producerAiSummary => 'AI Summary';
  @override
  String get producerAiCapabilities => 'AI Capabilities';
  @override
  String get producerCapScoring => 'Opportunity Scoring';
  @override
  String get producerCapRanking => 'Supplier Ranking';
  @override
  String get producerCapTrends => 'Market Trends';
  @override
  String get producerCapPrice => 'Price Analysis';
  @override
  String get producerCapQuality => 'Quality Rating';
  @override
  String get producerCapDelivery => 'Delivery Time';
  @override
  String get producerRecentOpps => 'Recent Opportunities';
  @override
  String get producerEmptyOpps => 'No opportunities discovered yet';
  @override
  String get producerVerifiedSuppliers => 'Verified Suppliers';
  @override
  String get producerEmptySuppliers => 'No suppliers connected yet';

  @override
  String get formWrite => 'Write';
  @override
  String get formPreview => 'Preview';
  @override
  String get formNothingToPreview => 'Nothing to preview yet.';
  @override
  String get formMarkdownHint =>
      'Supports **markdown** — headings, **bold**, lists…';
  @override
  String get formUpload => 'Upload';
  @override
  String get formCamera => 'Camera';
  @override
  String get formRemoveImage => 'Remove image';
  @override
  String get titleEditProduct => 'Edit Product';
  @override
  String get titleAddProduct => 'Add Product';
  @override
  String get formSaveChanges => 'Save Changes';
  @override
  String get formSaveProduct => 'Save Product';
  @override
  String get favAdd => 'Add to favorites';
  @override
  String get lifecycleAwareness => 'Awareness';
  @override
  String get lifecycleConsideration => 'Consideration';
  @override
  String get lifecyclePurchase => 'Purchase';
  @override
  String get lifecycleRetention => 'Retention';

  @override
  String get labelSupplier => 'Supplier';
  @override
  String get supAbout => 'About';
  @override
  String get supRatingsCerts => 'Ratings & Certifications';
  @override
  String get supProductCatalog => 'Product Catalog';
  @override
  String get supTransactionHistory => 'Transaction History';
  @override
  String get supTotalVolume => 'Total volume';
  @override
  String get supTotalOrders => 'Total orders';
  @override
  String get supRepeatBuyers => 'Repeat buyers';
  @override
  String get supContact => 'Contact';
  @override
  String get supMessage => 'Message supplier';
  @override
  String get supAskHint => 'Ask about pricing, MOQ, lead time…';
  @override
  String get titleSupplierSearch => 'Supplier Search';
  @override
  String get titleFavoriteSuppliers => 'Favorite Suppliers';
  @override
  String get supSearchHint => 'Search suppliers, categories, locations';
  @override
  String get supShow => 'Show';
  @override
  String get supFavorites => 'Favorites';
  @override
  String get favRemove => 'Remove from favorites';
  @override
  String get favEmpty => 'No favorite suppliers yet';
  @override
  String get favEmptyHint =>
      'Tap the heart on a supplier to add it here for quick access.';

  @override
  String get txnIncome => 'Income';
  @override
  String get txnExpense => 'Expense';

  @override
  String producerSummaryLine(int opportunities, int favorites) =>
      '$opportunities opportunities from your data · '
      '$favorites favorite suppliers.';

  @override
  String get titleForecast => 'Revenue forecast';
  @override
  String get titleCustomerRisk => 'Customer risk';
  @override
  String get forecastNextMonth => 'Next month forecast';
  @override
  String get forecastRange => 'Forecast range';
  @override
  String get forecastConfidence => 'Confidence';
  @override
  String get forecastBasis => 'Based on months';
  @override
  String get forecastInsufficient => 'Not enough data to forecast';
  @override
  String get forecastInsufficientBody =>
      'At least 3 months with revenue are needed. Record more orders, or load '
      'the 12-month sample data from More to try it out.';
  @override
  String get forecastHistory => 'Monthly revenue';
  @override
  String get forecastVsPrevious => 'vs previous window';
  @override
  String get forecastWhy => 'Why';
  @override
  String get forecastRuleBased => 'Rule-based (no AI needed)';
  @override
  String get riskStageActive => 'Active';
  @override
  String get riskStageCooling => 'Cooling';
  @override
  String get riskStageAtRisk => 'At risk';
  @override
  String get riskStageChurned => 'Churned';
  @override
  String get riskStageNeverPurchased => 'Never purchased';
  @override
  String get riskWinBack => 'Win back';
  @override
  String get riskEmpty => 'No customers to assess yet';
  @override
  String get riskEmptyBody =>
      'Add customers and record orders so the app can learn their buying rhythm.';
  @override
  String get riskRecommendedActions => 'Recommended actions';
  @override
  String get riskActionContact => 'Reach out and check in';
  @override
  String get riskActionOffer => 'Send a win-back offer';
  @override
  String get riskNoData => 'Not enough data to assess risk';
  @override
  String get aiExplain => 'Ask AI to explain';
  @override
  String get aiExplainRunning => 'Workizen AI is explaining…';
  @override
  String daysSincePurchase(int days) => '$days days since last purchase';
  @override
  String riskScoreLabel(int score) => 'Risk score $score';
  @override
  String customersAtRisk(int count) => '$count customers at risk';

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

  @override
  String get stateLoading => 'Loading…';
  @override
  String get stateEmpty => 'No data yet';
  @override
  String get stateRetry => 'Try again';
  @override
  String get stateInsufficientTitle => 'Not enough data to conclude';
  @override
  String get stateInsufficientBody =>
      'Record more real data and come back — this will not guess.';
  @override
  String get stateStaleTitle => 'Data is not up to date';
  @override
  String get stateTechnicalDetail => 'Technical detail';
  @override
  String get errorStorageTitle => 'Could not read your data';
  @override
  String get errorStorageBody =>
      'Your data is still on this device, but this read failed. Try again; '
      'if it keeps failing, restart the app.';
  @override
  String get errorNetworkTitle => 'Could not connect';
  @override
  String get errorNetworkBody =>
      'Check your connection and try again. Your business data lives on this '
      'device and does not need the network.';
  @override
  String get errorPermissionTitle => 'Permission needed';
  @override
  String get errorPermissionBody =>
      'The system denied access. Grant it in Settings, then reopen this '
      'screen.';
  @override
  String get errorConfigurationTitle => 'Setup needed first';
  @override
  String get errorConfigurationBody =>
      'Something has to be set up before this can run. Finish the setup and '
      'try again.';
  @override
  String get errorUnexpectedTitle => 'Unexpected error';
  @override
  String get errorUnexpectedBody =>
      'This one is unclassified. The technical detail below is kept verbatim '
      'so the cause stays traceable.';
  @override
  String stateStaleBody(String time) =>
      'Showing data from $time. The last refresh failed.';

  @override
  String get titleBackup => 'Backup & restore';
  @override
  String get backupCreate => 'Create a backup file (.ttbk)';
  @override
  String get backupCreateHint =>
      'Your whole business in one file: customers, products, orders, goals, '
      'transactions and favourite suppliers.';
  @override
  String get backupRestore => 'Restore from a backup file';
  @override
  String get backupRestoreHint =>
      'Replaces all current data with the contents of a backup file.';
  @override
  String get backupPickFile => 'Choose a .ttbk file';
  @override
  String get backupPassphraseLabel => 'Passphrase for this backup';
  @override
  String get backupPassphraseNeeded =>
      'This file is encrypted. Enter the passphrase to see what is inside.';
  @override
  String get backupPreviewTitle => 'What this backup contains';
  @override
  String get backupCreatedAt => 'Created';
  @override
  String get backupAppVersion => 'App / database version';
  @override
  String get backupEncrypted => 'Encrypted';
  @override
  String get backupNotEncrypted => 'Not encrypted';
  @override
  String get backupCompatible => 'Compatible with this app version';
  @override
  String get backupContents => 'Records that will be restored';
  @override
  String get backupReplaceWarning =>
      'ALL current business data on this device will be REPLACED with the data '
      'in this file. A safety backup is created automatically first.';
  @override
  String get backupReplaceAction => 'Replace current data';
  @override
  String get backupConfirmTitle => 'Replace current data?';
  @override
  String get backupConfirmBody =>
      'This cannot be undone with one tap. A safety backup is written first, '
      'and its location is shown as soon as the restore finishes.';
  @override
  String get backupRestoring => 'Restoring…';
  @override
  String get backupRestoreDone => 'Restore complete';
  @override
  String get backupSafetyCopy => 'Safety backup taken before restoring';
  @override
  String get backupUndoAction => 'Go back to the data from before';
  @override
  String get backupUndoHint =>
      'Opens the safety copy above as a preview. You still have to confirm '
      'again before it replaces the current data.';
  @override
  String get backupRejected => 'This file cannot be used';
  @override
  String get backupIntegrityNote =>
      'The SHA-256 checksum detects a damaged or incomplete file. It does not '
      'prove the file is genuine — only an encrypted backup resists tampering.';
  @override
  String get datasetCustomers => 'Customers';
  @override
  String get datasetProducts => 'Products';
  @override
  String get datasetOrders => 'Orders';
  @override
  String get datasetGoals => 'Goals';
  @override
  String get datasetTransactions => 'Transactions';
  @override
  String get datasetFavourites => 'Favourite suppliers';
  @override
  String backupProblem(String code) => switch (code) {
    'notABackup' => 'This is not a Tổng Tài backup file (.ttbk v2).',
    'tooNew' => 'Written by a newer app. Update the app and try again.',
    'unsupportedVersion' => 'This app cannot read that file version.',
    'truncated' => 'The file is incomplete — the copy may not have finished.',
    'checksumMismatch' => 'The file is damaged — its checksum does not match.',
    'passphraseRequired' => 'The file is encrypted. A passphrase is needed.',
    'wrongPassphrase' => 'Wrong passphrase, or the file has been altered.',
    'malformedPayload' => 'The contents of the file could not be read.',
    'missingDataset' =>
      'The file is missing part of the data, so it is not a full snapshot.',
    'invalidRecord' => 'A record inside the file is malformed.',
    'duplicateId' => 'The file contains records with the same id.',
    'brokenForeignKey' =>
      'The file has an order pointing at a customer it does not contain.',
    'countMismatch' =>
      'The declared record counts do not match the actual contents.',
    'notRestorableKind' =>
      'This package is a different kind — not a backup meant to be restored.',
    'redactedPackage' =>
      'Personal data was removed from this package, so it cannot be restored.',
    _ => 'This file cannot be restored.',
  };
}

/// `context.l10n.<key>` — the ergonomic accessor used throughout the UI.
extension AppStringsX on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
