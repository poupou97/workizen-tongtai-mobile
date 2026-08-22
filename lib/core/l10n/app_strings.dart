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

  // ── Tổng Tài · brief hằng ngày (WTM-304, Epic WTM-302) ─────────────────
  /// Lời chào theo buổi — thứ đầu tiên người bán đọc khi mở app.
  String get briefGreetingMorning;
  String get briefGreetingAfternoon;
  String get briefGreetingEvening;

  /// "Có N việc đáng chú ý hôm nay".
  String briefHeadline(int count);

  /// Cùng thẻ, **không** con số — dùng trên Trang chủ (WTM-388).
  String get briefHeadlineNoCount;

  String get briefNothingTitle;
  String get briefNothingBody;
  String get briefSeeAll;
  String get briefSectionDecide;
  String get briefSectionKnow;

  String get briefWhyTitle;
  String get briefSuggestTitle;

  String get briefStatusPending;
  String get briefStatusAccepted;
  String get briefStatusDismissed;
  String get briefStatusPostponed;

  String get titleAgent;
  String get agentSubtitle;

  // ── Tổng Tài · quyết định + hoạt động (WTM-305) ─────────────────────────
  /// Ba nút của một việc. Động từ, không phải "OK/Cancel".
  String get briefActionAccept;
  String get briefActionDismiss;
  String get briefActionLater;

  String get briefStoryTitle;
  String get briefStoryHappened;
  String get briefStoryNext;

  /// ⚠️ Nhãn **diễn tập** — hành động chưa ra khỏi máy này.
  String get briefDemoExecution;
  String get briefDemoExecutionBody;

  String get briefAcceptedSnack;
  String get briefDismissedSnack;
  String briefLaterSnack(int days);

  String get titleActivity;
  String get activitySubtitle;
  String get activityToday;
  String get activityEarlier;
  String get activityEmpty;
  String get activityEmptyBody;

  // ── Tổng Tài · mức tự động + orchestration (WTM-306) ───────────────────
  String get titleAutonomy;
  String get autonomySubtitle;

  String get autonomyAreaCustomerCare;
  String get autonomyAreaInventory;
  String get autonomyAreaMarketing;

  String get autonomyModeSuggest;
  String get autonomyModeConfirm;
  String get autonomyModeAuto;
  String get autonomyModeSuggestBody;
  String get autonomyModeConfirmBody;
  String get autonomyModeAutoBody;

  /// Nhãn **Xem trước** — `Tự động` chưa production-ready (Task Order §9).
  String get autonomyPreviewBadge;
  String get autonomyPreviewBody;

  /// ⛔ Việc **luôn hỏi người bán**, bất kể mức nào được chọn.
  String get autonomyAlwaysAsk;
  String get autonomyAlwaysAskBody;
  String get autonomyNoAuto;

  /// Nhãn nghiệp vụ cho từng loại hành động — người bán không đọc mã.
  String get actLabelSendMessage;
  String get actLabelColdMessage;
  String get actLabelContactOutside;
  String get actLabelMergeCustomers;
  String get actLabelPurchaseOrder;
  String get actLabelOrderAboveLimit;
  String get actLabelUpdatePrice;
  String get actLabelCampaignPause;
  String get actLabelCampaignBudget;

  /// Thẻ orchestration — sáu dòng.
  String get automationTitle;

  // ── Tổng Tài · runner + đặt lại demo (WTM-307) ─────────────────────────
  String get agentRunNow;
  String get agentRunNothing;
  String agentRunDone(int count);

  String get moreResetDemo;
  String get moreResetDemoConfirmTitle;
  String get moreResetDemoConfirmBody;
  String moreResetDemoSnack(int decisions);

  // ── navigation / screen titles (P0 §2 WTM-145: one active locale) ──────
  String get titleReports;
  String get titleFinance;
  String get titleGoalDetail;

  // ── More menu ───────────────────────────────────────────────────────────
  // ── đếm, hiện trên nhãn (WTM-344) ───────────────────────────────────────
  /// "42 cơ hội" · "1 cơ hội".
  String countOpportunities(int count);

  /// "112 đơn" · "1 đơn".
  String countOrders(int count);

  /// "40 khách" · "1 khách".
  String countCustomers(int count);

  /// "Thay đổi chưa lưu (2)".
  String unsavedChanges(int count);

  String get moreLoadSample;
  String get moreRemoveSample;

  // ── KPI labels ──────────────────────────────────────────────────────────
  String get kpiRevenue;
  String get kpiOrders;
  String get kpiCustomers;
  String get kpiAov;
  String get kpiIncome;

  /// WTM-197 — nhãn hiển thị cho `FinanceCategory`; mã lưu là canonical code.
  /// Nhóm chi phí đầu vào (WTM-236) — hạ tầng · công cụ · trả theo mức dùng.
  String get finCatInfrastructure;
  String get finCatTooling;
  String get finCatProvider;

  String get finCatProductCost;
  String get finCatPlatformFee;
  String get finCatShipping;
  String get finCatStaff;
  String get finCatMarketing;
  String get finCatRent;
  String get finCatSales;
  String get finCatOther;

  /// WTM-196 — how much of income the app worked out from orders.
  String financeFromSales(String amount);

  /// WTM-211 — money earned but not yet received.
  String get financeReceivablesTitle;
  String financeReceivablesBody(String amount, int debtors);
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

  /// WTM-209 — revenue per recorded sales channel.
  String get sectionRevenueByChannel;
  String reportChannelOrders(int count);
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
  String get homeEmptyBody;
  String get homeSampleLoadedSnack;
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

  /// "Đã nạp 100 sản phẩm và 12 tháng lịch sử." — nói bằng con số thật.
  String moreSampleLoadedSnack(int products, int months);
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

  /// Nhãn cho con số **đã đo được**, không phải khoản thêm vào — WTM-384.
  /// Cố ý KHÔNG có dấu `+`: đây là tiền đã kiếm, không phải tiền sẽ kiếm.
  String get oppObservedPrefix;
  String get oppScoreLabel;
  String oppDismissedSnack(String title);
  String oppInterestedSnack(String title);
  String oppGoalCreatedSnack(String title);
  String oppCreatedFromNote(String description);

  /// WTM-191 — turn an opportunity into work inside the active journey.
  String get oppAddToJourney;
  String oppAddedToJourneySnack(String title);

  /// Business Loop (WTM-223): kết quả thường trực + đường đi tiếp, thay cho
  /// một snackbar biến mất sau vài giây.
  String get oppInJourney;
  String get oppOpenJourney;
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

  /// WTM-210 — start a journey straight from Home's mission block.
  String get homeStartJourney;
  String get homeStartJourneyNeedGoal;
  String get oppFilterAll;
  String get oppFilterSaved;
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

  /// WTM-192 — Opportunity Hub took the fifth bottom-bar slot from More.
  String get navOpportunity;

  // ── common actions/labels (WTM-146 §3 EN-literal sweep) ─────────────────
  String get actionAdd;
  String get actionSave;
  String get actionSend;
  String get actionClearFilters;
  String get actionPrevPage;
  String get actionNextPage;
  String get labelSort;
  String get labelStatus;
  String get labelChannel;
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

  /// Dòng dưới con số trên thẻ phân khúc: "khách".
  // ── cp6 · Tài chính của sản phẩm (WTM-420) ─────────────────────────────

  String get finProductSection;
  String get finSellingPrice;
  String get finCostPrice;
  String get finProfitPerUnit;
  String get finMargin;

  /// Dòng MỜI khai giá vốn — không trách, vì đây là điều app chưa hỏi.
  String get finCostMissing;

  /// Nhãn của con số DỰ KIẾN, ví dụ "nếu bán hết 34 sản phẩm đang tồn".
  String finProjectedOnStock(int quantity);

  /// Tiêu đề nhóm con số ĐO ĐƯỢC từ đơn thật.
  String finMeasuredIn(int days);

  String get finUnitsSold;
  String get finRevenue;
  String get finRealProfit;

  /// Chưa bán được cái nào trong cửa sổ.
  String get finNoSalesYet;

  String get segCardUnit;

  /// Thay đổi so với 30 ngày trước, ví dụ "+3 so với 30 ngày trước".
  String segCardDelta(int delta);

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
  String get homeChatTooltip;
  String get sectionBusinessKpis;
  String get sectionTopOpportunities;
  String get homeCtaCustomer;
  String get homeCtaProduct;
  String get homeCtaOrder;
  String get homeCtaGoal;
  String get homeCtaDemo;

  // ── Concept-1 shell + thẻ chỉ số (WTM-404) ─────────────────────────────
  /// Dòng phụ dưới tên sản phẩm ở đầu Trang chủ. Concept mở bằng **thương
  /// hiệu**, không phải bằng chữ "Bảng điều khiển" — một bảng điều khiển là
  /// thứ người ta *dùng*, một sản phẩm là thứ người ta *nhớ*.
  String get brandTagline;

  /// Nhãn đường dẫn tiếp trên thẻ chỉ số — "Xem kho", "Xem khách"…
  String get actionOpen;

  /// Nút trên mỗi dòng cơ hội ở Trang chủ.
  String get actionHandleNow;

  /// Khối so sánh nhà cung cấp trên màn sản phẩm (WTM-409, cp11).
  ///
  /// ⚠️ `supplierUnknown*` KHÔNG được ghép thành một câu chung. Mỗi thứ chưa
  /// biết là một câu riêng, vì gộp lại sẽ ra *"chưa biết thời gian giao, số
  /// lượng tối thiểu"* — đọc như một danh sách thiếu sót của người bán, trong
  /// khi nó là điều **app** chưa hỏi.
  String get supplierSectionTitle;
  String get supplierCurrent;
  String get supplierAlternatives;
  String get supplierUnknownLeadTime;
  String get supplierUnknownMoq;
  String get supplierUnknownRating;

  /// *"Rẻ hơn 12%"* — chỉ hiện khi thật sự rẻ hơn.
  String supplierCheaperBy(int percent);

  /// *"Giao chậm hơn 6 ngày"* / *"Giao nhanh hơn 3 ngày"*.
  String supplierSlowerByDays(int days);
  String supplierFasterByDays(int days);

  /// *"Phải đặt thêm 50"* — khi MOQ nguồn kia cao hơn.
  String supplierExtraMoq(String quantity);

  /// Câu nhắc rằng đây là **đánh đổi**, không phải câu trả lời.
  String get supplierTradeOffNote;

  /// Khối "vì sao điểm này" trên màn chi tiết cơ hội (WTM-408, cp5b).
  ///
  /// ⚠️ `oppFactorDemand` phải nói **khách của chính người bán**, KHÔNG nói
  /// "thị trường" — trên máy này yếu tố ấy đọc từ lịch sử đơn của họ, và
  /// `OpportunityFactorKind.demandVolume` ghi rõ ràng buộc đó.
  String get oppWhyThisScore;
  String get oppFactorProfit;
  String get oppFactorDemand;
  String get oppFactorSupplier;
  String get oppFactorCompetition;
  String get oppFactorNoData;

  /// *"Chấm được 70% các yếu tố"* — hiện khi điểm chưa đủ độ phủ.
  String oppScoreCoverage(int percent);

  /// Lý do một yếu tố không chấm được. Mỗi mã một câu, không ghép chuỗi.
  String get oppUnavailSupplierSample;
  String get oppUnavailNeedsMarket;
  String get oppUnavailNoBaseline;
  String get oppUnavailNoDemandHistory;

  /// Đơn vị dưới con số trên thẻ năng lực — *"12 sản phẩm"*, *"82 khách"*.
  String get homeUnitInputs;
  String get homeUnitProducts;
  String get homeUnitCustomers;
  String get homeUnitGoals;

  /// Chip mức ưu tiên trên dòng "Việc Tổng Tài đề xuất".
  ///
  /// ⚠️ Đây là **thứ hạng trong danh sách đang hiện**, không phải một ngưỡng
  /// điểm — xem `OpportunityPriority`. Nhãn phải đọc như *"làm trước"*, không
  /// như *"nghiêm trọng"*.
  String get oppPriorityHigh;
  String get oppPriorityMedium;
  String get oppPriorityLow;
  String get oppPriorityUnknown;

  /// Khối đóng cuối Trang chủ (WTM-406, concept-1) — linh vật mời hỏi.
  String get homeCloserTitle;
  String get homeCloserBody;

  /// Mức đổi của một chỉ số so với **tháng liền trước đã kết thúc**.
  ///
  /// ⚠️ "tháng trước" chứ không phải "hôm qua": chuỗi Home đọc là chuỗi
  /// **tháng** (`RevenueSeries`, tháng đang chạy bị loại vì một tháng dở luôn
  /// trông như sụp đổ cạnh các tháng đủ). Nhãn phải nói đúng mốc mình so.
  String homeVsPrevMonth(String percent);

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

  /// Home hero (WTM-221) — Concept mở màn bằng một câu của app, không phải
  /// một hàng số. Ba câu, ba trạng thái phân biệt.
  String get homeGreeting;
  String homeHeadlineOpportunities(int count);

  /// ⭐ WTM-388 — câu **duy nhất** Trang chủ nói về "hôm nay làm gì".
  ///
  /// Thay `homeHeadlineOpportunities`, vốn công bố **tổng** số cơ hội (43) rồi
  /// để hai con số khác trên cùng màn nói ngược lại.
  String homeHeadlineTopActions(int count);
  String get homeHeadlineNoneToday;
  String get homeHeadlineNotEnoughData;
  String get homeAskHint;

  /// Nút mở capability nơi một bước hành trình được làm (WTM-220).
  String get journeyDoStep;

  /// Hành trình đi hết (WTM-226). Cố ý KHÔNG nói "đạt mục tiêu": làm hết việc
  /// chưa chắc chạm số, và nói gộp hai thứ là lời nói dối đầu tiên.
  String get journeyPlanDoneTitle;
  String get journeyPlanDoneBody;
  String get journeySetNextGoal;

  /// Concept-1 screen headers (WTM-216) — one line saying what a screen is for.
  String get subtitleProducer;
  String get subtitleInventory;
  String get subtitleConsumer;
  String get subtitleOpportunity;
  String get subtitleFinance;
  String get subtitleReports;

  /// Concept-1 inventory overview card (WTM-215).
  /// CTA nối nơi thấy vấn đề tới cơ hội engine đã sinh (WTM-225).
  /// Nhãn chi phí cho sản phẩm KHÔNG phải hàng vật lý (WTM-231).
  String get productVariableCostLabel;

  /// Ô chọn loại sản phẩm trên form (WTM-233 / ADR-TON-023).
  String get productKindLabel;

  /// Nhãn của một mã [ProductKind]. Mã lạ đọc ra "Hàng hoá" vì mọi dòng có
  /// trước ADR-TON-023 đều thật sự là hàng vật lý.
  String productKindName(String code);

  /// Câu nói vì sao ô tồn kho biến mất — không có nó thì việc mất ô trông
  /// giống một lỗi hiển thị.
  String get productKindNoStockNote;

  /// Nguồn đầu vào của doanh nghiệp (WTM-234 / ADR-TON-023).
  String get titleBusinessInputs;
  String get inputsCommitmentLabel;
  String get inputsAllCounted;

  /// Bao nhiêu nguồn KHÔNG góp vào tổng. Bắt buộc hiện cạnh tổng: một tổng
  /// không tự khai mình thiếu gì sẽ được đọc như một tổng đầy đủ.
  String inputsUnknownCount(int count);
  String get inputsEmpty;
  String get inputAddTitle;
  String get inputEditTitle;
  String get inputDelete;
  String get inputKindLabel;
  String get inputNameLabel;
  String get inputNameHint;
  String get inputNameRequired;
  String get inputCadenceLabel;
  String get inputAmountLabel;
  String get inputNoteLabel;

  /// Vì sao một số tiền đã nhập vẫn không vào tổng cam kết.
  String get inputNotCommitmentNote;

  /// Ô "không tính vào cam kết" trên một dòng nguồn — KHÔNG được hiện "0 ₫",
  /// vì 0 nói nguồn đó miễn phí.
  String get inputNotCounted;

  /// Nhãn của một mã [BusinessInputKind].
  String inputKindName(String code);

  /// Nhãn của một mã [InputCadence]; `null` = người bán chưa nói.
  String inputCadenceName(String? code);

  /// Mục nguồn đầu vào trên tab Producer.
  String get producerInputsSection;

  /// Nhãn khối "bước tiếp theo trong hành trình" trên màn nguồn đầu vào
  /// (WTM-235) — đọc từ Journey, thường trực, không phải Snackbar.
  String get inputsJourneyStepTitle;

  String get stockSeeOpportunity;
  String get customerSeeOpportunity;

  String get invOverviewTitle;
  String get invOverviewProducts;
  String get invOverviewValue;
  String get invLowStockSection;
  String get invViewAll;
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

  // ── Product detail (WTM-335) — read-only grouped attribute view ──────────
  String get productDetailTitle;
  String get productDetailCoreSection;
  String get productDetailSpecSection;
  String get productDetailEdit;
  String get productDetailSku;
  String get productDetailCategory;
  String get productDetailPrice;
  String get productDetailStock;
  String get productDetailKind;
  String get productDetailBrand;

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
  String get obStart;
  String get obNext;
  String get obBack;
  String get obProgress;
  String obQuestion(String stepId);

  // ── Onboarding V2 (Epic WTM-349) ────────────────────────────────────────
  // Trải nghiệm vào cửa phải chứng minh giá trị TRƯỚC khi người bán tới phần
  // còn lại của sản phẩm. Không chuỗi nào ở đây nói "hoàn tất thiết lập".
  String get obV2WelcomeTitle;
  String get obV2WelcomeBody;
  String get obV2ValueOpportunityTitle;
  String get obV2ValueOpportunityBody;
  String get obV2ValueRiskTitle;
  String get obV2ValueRiskBody;
  String get obV2ValueActionTitle;
  String get obV2ValueActionBody;

  /// Nhãn một đáp án của câu "loại hình kinh doanh" (WTM-351).
  String profileBusinessType(String code);

  String get obV2DataTitle;
  String get obV2DataBody;
  String get obV2DataCsvTitle;
  String get obV2DataCsvBody;
  String get obV2DataSampleTitle;
  String get obV2DataSampleBody;
  String get obV2DataNoneTitle;
  String get obV2DataNoneBody;
  String get obV2DataConnectorsLater;

  String get obV2AnalysisTitle;
  String get obV2AnalysisBody;

  /// Một dòng tiến trình: chặng + số bản ghi **thật** vừa xử lý.
  String obV2AnalysisStage(String stageCode, int count);

  String get obV2InsightTitle;
  String get obV2InsightBody;
  String get obV2InsightQuietTitle;
  String get obV2InsightQuietBody;
  String get obV2InsightInsufficientTitle;
  String get obV2InsightInsufficientBody;
  String get obV2SnapshotRevenue;
  String get obV2SnapshotProfit;
  String get obV2SnapshotOrders;
  String get obV2SnapshotInventory;

  /// Vì sao chưa tính được lời — hiện ra thay cho một con số đoán.
  String get obV2ProfitUnknown;

  String get obV2GoalTitle;
  String get obV2GoalBody;
  String get obV2GoalLimit;
  String obV2Goal(String code);

  String get obV2PlanTitle;
  String get obV2PlanBody;
  String get obV2PlanEvidence;
  String get obV2PlanCta;
  String get obV2Continue;
  String get obV2SkipProfile;

  // ── Màn khởi động (WTM-367 · nhận diện mới WTM-416) ──────────────────────

  /// Chủ sở hữu sản phẩm, đặt trên tên sản phẩm — theo bố cục Founder giao.
  // ── Vốn chôn trong hàng chậm bán (WTM-411 · concept-1 cp3) ──────────────

  String get invShowAll;
  String get invTiedUpTitle;

  /// `count` mặt hàng không bán được cái nào trong `days` ngày.
  String invTiedUpBody(int count, int days);

  /// Phần **chưa tính được** vì thiếu giá vốn. Câu chữ MỜI khai, không trách:
  /// thiếu giá vốn là điều app chưa hỏi, không phải lỗi người bán.
  String invTiedUpUnknownCost(int count);

  String get invTiedUpAction;

  String get startupBrandOwner;

  /// Nhãn nền tảng ở đường kẻ ngang. KHÔNG dịch: đây là một phần của khoá
  /// nhận diện, giống chữ "Ai CRM" trong logo.
  String get startupPlatform;

  String get startupBrand;
  String get startupTagline;
  String get startupWorking;

  /// Một chặng khởi động THẬT. `count` là số bản ghi thật, `null` khi chặng
  /// đó không đếm gì — và khi đó câu chữ không được bịa ra một con số.
  String startupStep(String stepCode, int? count);
  String get startupPrivacy;

  /// Nhãn trợ năng cho linh vật — nói **AI đang làm gì**, không tả con cáo.
  String get obV2MascotGreeting;
  String get obV2MascotWorking;
  String get obV2MascotExplaining;
  String get obV2MascotPlanning;
  String get obV2MascotCalm;
  String get obV2MascotIdle;
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

  /// ⚠️ Nhãn của ô đếm ở màn Nguồn hàng. Con số phía dưới là **số nhà cung cấp
  /// người bán đã lưu** (`favorites.length`) — KHÔNG có bước xác minh nào.
  ///
  /// Tên cũ là *"Nhà cung cấp đã xác minh"*, tuyên bố một việc app không làm
  /// (WTM-422, cùng họ WTM-421).
  String get producerSavedSuppliers;
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
  String get supRatings;
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

  // ── Tổng kết tuần (WTM-377 · Epic WTM-179) ──────────────────────────────
  /// *"114 sản phẩm"* — WTM-382. Trước đó là chuỗi tiếng Anh viết thẳng trong
  /// màn Kho, và nó hiện ra trên máy người bán.
  String invProductCount(int count);

  String get titleWeeklyReview;
  String get weeklyReviewSubtitle;
  String get weeklyReviewRange;
  String get weeklyReviewRevenue;
  String get weeklyReviewOrders;
  String get weeklyReviewCustomers;
  String get weeklyReviewAov;
  String get weeklyReviewVsPrevious;
  String get weeklyReviewNoPrevious;
  String get weeklyReviewTopProduct;
  String get weeklyReviewNothingSold;
  String get weeklyReviewNothingSoldBody;
  String get weeklyReviewHistory;
  String get weeklyReviewInsufficient;
  String get weeklyReviewInsufficientBody;
  String get weeklyReviewWhy;

  /// Câu miễn trừ cho mọi con số mang tính phán đoán (WTM-280).
  ///
  /// Đặt **ngay cạnh con số**, không phải trong một trang điều khoản — người
  /// bán đọc nó đúng lúc đang nhìn con số và sắp quyết định theo nó.
  ///
  /// Câu chữ phải giữ đúng ADR-TON-016: số đến từ **phép tính trên dữ liệu của
  /// chính người bán** (Rule Twin), AI chỉ giải thích. Cấm ngụ ý "AI tính ra
  /// con số này".
  String get estimateDisclaimer;
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

  /// ⛔ Brief **hỏng** — khác hẳn "chưa đủ dữ liệu" (WTM-342).
  String get briefFailedTitle;
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

  // ── kết nối nền tảng ngoài (WTM-317 · Epic WTM-315) ─────────────────────
  String get titleConnections;

  /// Câu mở màn Kết nối — nói app **dùng** nền tảng của người bán, không phải
  /// gửi dữ liệu về đâu đó.
  String get connectionsIntro;

  String get connectorGoogle;
  String get connectorTelegram;
  String get connectorAtlassian;

  /// Nhãn trạng thái. `SETUP_REQUIRED` cố ý **không** đọc là "lỗi".
  String get connectionSetupRequired;
  String get connectionActive;
  String get connectionPaused;
  String get connectionError;

  String get connectionConnect;
  String get connectionDisconnect;
  String get connectionDisconnectConfirm;

  /// Vì sao nút kết nối chưa bấm được — hiện ngay chỗ bấm, không giấu trong log.
  String get connectionNotConfigured;

  String get driveBackupTitle;
  String get driveBackupHint;
  String get driveBackupNow;
  String get driveBackupRunning;

  /// "Đã lưu lên Google Drive lúc 14:30" — nói việc đã xong ở đâu.
  String driveBackupDone(String time);

  String get driveBackupList;
  String get driveBackupEmpty;
  String get driveBackupRestore;

  /// Khả năng đang bật của một kết nối.
  String get capabilityDriveBackup;
  String get capabilityTelegramMessaging;
  String get capabilityJiraWork;
  String get capabilityConfluenceKnowledge;

  /// Nhãn hành động sao lưu trong màn Hoạt động.
  String get actLabelBackupUpload;

  /// Nhãn hành động báo cho chính chủ shop.
  String get actLabelOwnerNotify;

  // ── nhập dữ liệu cửa hàng (WTM-326 · Epic WTM-324) ──────────────────────
  String get titleImport;

  /// Câu mở màn — nói app **đọc** file của người bán, không gửi đi đâu.
  String get importIntro;

  String get importPickFile;

  /// "100 sản phẩm đã sẵn sàng" — ngôn ngữ nghiệp vụ, không phải "parsed 100 rows".
  String importReadyProducts(int count);

  String importReadyVariants(int count);
  String importReadySuppliers(int count);
  String importReadyOrders(int count);
  String importReadyCustomers(int count);

  /// "3 dòng cần xem lại trước khi nhập" — chặn.
  String importBlocked(int count);

  /// "5 dòng có cảnh báo — vẫn nhập được".
  String importWarned(int count);

  String get importConfirm;
  String get importRunning;

  /// "Đã nhập 100 sản phẩm vào cửa hàng của bạn."
  String importDone(int count);

  String get importNothing;
  String get importHistory;
  String get importReset;
  String get importResetConfirm;

  /// "Đã bỏ 100 sản phẩm của lần nhập ngày 9/8."
  String importResetDone(int count);

  /// "PRODUCTS · dòng 42" — chỗ mở Excel ra sửa, hiện nhỏ dưới câu tiếng Việt.
  String importIssueLocation(String sheet, int row);

  /// "… và 12 dòng nữa".
  String importMoreIssues(int count);

  // ── WTM-443 · người bán tự chỉ cột ─────────────────────────────────────

  /// Tiêu đề bước ghép cột.
  String get importMapTitle;

  /// Câu giải thích — vì sao app hỏi, và điều gì xảy ra sau đó.
  String get importMapIntro;

  /// Nhãn ô chọn sàn.
  String get importMapVendor;

  /// Nhãn ô chọn loại file.
  String get importMapKind;

  String get importMapKindOrders;
  String get importMapKindIncome;

  /// Mục "chưa ghép cột nào" trong danh sách chọn cột.
  String get importMapUnset;

  /// Nút lưu bản đồ rồi đọc lại file.
  String get importMapSave;

  /// "Còn thiếu: Mã đơn, Số lượng" — nói rõ thiếu VAI TRÒ gì, không nói
  /// "thiếu cột": người bán có cột, họ chỉ chưa chỉ nó vào đâu.
  String importMapMissing(String roles);

  /// Nhãn một vai trò canonical — `orderId` ⇒ "Mã đơn hàng".
  String importMapField(String field);

  /// "196 bản ghi" — tổng của một lần nhập.
  String importRecordCount(int count);

  // ── catalog nguồn dữ liệu (WTM-331 · §24) ───────────────────────────────
  String get sourcesCommerce;
  String get sourcesSourcing;
  String get sourcesMessaging;
  String get sourcesLogistics;
  String get sourcesFinance;

  /// Nút bật doanh nghiệp mô phỏng ngay từ màn nguồn dữ liệu.
  String get sourcesStartDemo;

  /// "10 nền tảng đang phát dữ liệu demo".
  String sourcesDemoLive(int count);

  /// Câu nhắc rằng danh sách này nói **trạng thái thật**, không phải quảng cáo.
  String get sourcesHonestNote;

  String get readinessConnected;
  String get readinessFileBridge;
  String get readinessDemo;

  /// ⭐ Trạng thái **thứ bảy** — đang phát trong bản mô phỏng, KHÔNG phải đã
  /// nối. Cố ý không mượn nhãn của `connected` (§40).
  String get readinessDemoConnected;
  String get readinessResearched;
  String get readinessPartnerRequired;
  String get readinessApiFuture;

  // ── doanh nghiệp demo (WTM-338 · Epic WTM-336) ──────────────────────────
  String get titleBusinessLife;

  /// Câu nói rõ đây là mô phỏng — §40 cấm fake trạng thái kỹ thuật.

  String get demoStart;
  String get demoNextEvent;
  String get demoNextDay;
  String get demoNextWeek;
  String get demoReset;

  /// "Ngày 12 / 30".
  /// Nhãn nút xoá MỘT DÒNG trong đơn đang tạo — nói rõ **xoá cái gì**.
  ///
  /// Trình đọc màn hình chỉ đọc được thứ ta đặt tên. Một nút mang biểu tượng
  /// `×` không nhãn thì người khiếm thị nghe ra "nút", không biết nó xoá dòng
  /// nào — mà đây là hành động **phá huỷ** (WTM-432).
  String orderRemoveLine(String product);

  /// ── Màn chào lúc mở app (WTM-433) — theo `loading-screen.png` ──
  String get splashOwner;
  String get splashProduct;
  String get splashPlatform;
  String get splashLoading;
  String get splashTagline;

  String demoDayOf(int day, int total);

  String get demoNeedsCatalogue;
  String get demoFinished;
  String get demoNotStarted;

  /// "Đã đi tới 6 việc mới".
  String demoAdvanced(int count);

  /// Nhãn ngắn gắn trên mọi bề mặt mô phỏng.

  /// Ba chủ thể trên dòng thời gian. `actorPlatform` là nhãn dự phòng khi
  /// không biết sàn nào — tên sàn đã biết thì hiện tên riêng của nó.
  String get actorPlatform;
  String get actorAgent;
  String get actorSeller;

  // ── hội thoại khách hàng (WTM-339 · Epic WTM-336) ───────────────────────
  String get titleConversations;

  /// Chưa có hội thoại nào — nói phải làm gì, không để màn trắng.
  String get conversationsEmpty;

  /// Khách đang chờ trả lời.
  String get conversationAwaiting;

  /// Tổng Tài đã soạn sẵn, chưa gửi.
  String get conversationDraftReady;

  /// ⭐ Rủi ro cao ⇒ bắt buộc duyệt.
  String get conversationNeedsApproval;

  /// Nhãn trên khung nháp — nói thẳng là CHƯA gửi.
  String get conversationDraftLabel;

  String get conversationSend;
  String get conversationEdit;
  String get conversationSent;
  String get conversationSendFailed;

  /// Nhãn "Bạn đã gửi" trên một tin của người bán.
  String get conversationYouSent;

  /// Tiêu đề phần câu chuyện khách hàng trong Khách hàng 360.
  String get customer360Story;

  /// "Biết tới shop qua Facebook Page · 12/7".
  String customer360FirstTouch(String channel, String date);

  /// Tiêu đề phần gợi ý mua kèm.
  String get customer360Suggestions;

  /// "3 khách khác mua kèm".
  String customer360BoughtTogether(int count);

  /// Nút mở khung hội thoại từ Khách hàng 360.
  ///
  /// Không có khoá "chưa có việc nào": khách chưa có gì trong sổ thì phần này
  /// **ẩn hẳn**. Một dòng "chưa có việc nào" trên mọi khách của một doanh
  /// nghiệp chưa bật demo là nhiễu thuần.
  String get customer360OpenConversation;

  // ── Telegram (WTM-318) ──────────────────────────────────────────────────
  String get telegramTitle;

  /// ⭐ Sự thật quan trọng nhất về Telegram bot, nói ngay chỗ thiết lập.
  String get telegramHint;

  String get telegramTokenLabel;
  String get telegramTokenHint;
  String get telegramSaveToken;
  String get telegramTokenBad;

  /// "Đã nhận @tongtai_bot" — xác nhận bằng thứ người bán nhìn thấy.
  String telegramBotFound(String username);

  String get telegramStartHint;
  String get telegramFindChats;
  String get telegramNoChats;
  String get telegramSendTest;
  String get telegramTestSent;

  // ── Jira + Confluence (WTM-319) ─────────────────────────────────────────
  String get atlassianTitle;
  String get atlassianHint;
  String get atlassianUrlLabel;

  /// Ví dụ địa chỉ — đi qua key vì nó là chuỗi hiển thị (ADR-TON-007).
  String get atlassianUrlHint;
  String get atlassianEmailLabel;
  String get atlassianTokenLabel;
  String get atlassianTokenHint;
  String get atlassianSave;
  String get atlassianBad;
  String get atlassianPickProject;
  String get atlassianPickSpace;
  String get atlassianNoProjects;

  /// Chưa chọn project ⇒ chưa kết luận được, KHÁC "không có việc nào".
  String get atlassianNoData;

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
  String get titleReports => 'Báo cáo & Phân tích';
  @override
  String get titleFinance => 'Tài chính';
  @override
  String get titleGoalDetail => 'Chi tiết mục tiêu';

  @override
  String countOpportunities(int count) => '$count cơ hội';
  @override
  String countOrders(int count) => '$count đơn';
  @override
  String countCustomers(int count) => '$count khách';
  @override
  String unsavedChanges(int count) => 'Thay đổi chưa lưu ($count)';
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
  String get finCatInfrastructure => 'Hạ tầng';
  @override
  String get finCatTooling => 'Công cụ';
  @override
  String get finCatProvider => 'Dịch vụ trả theo dùng';
  @override
  String get finCatProductCost => 'Nhập hàng';
  @override
  String get finCatPlatformFee => 'Phí sàn';
  @override
  String get finCatShipping => 'Vận chuyển';
  @override
  String get finCatStaff => 'Lương nhân viên';
  @override
  String get finCatMarketing => 'Quảng cáo';
  @override
  String get finCatRent => 'Thuê mặt bằng';
  @override
  String get finCatSales => 'Bán hàng';
  @override
  String get finCatOther => 'Khác';
  @override
  String financeFromSales(String amount) => 'trong đó $amount từ bán hàng';
  @override
  String get financeReceivablesTitle => 'Công nợ';
  @override
  String financeReceivablesBody(String amount, int debtors) =>
      '$amount đang kẹt ở $debtors khách';
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
  String get sectionRevenueByChannel => 'Doanh thu theo kênh';
  @override
  String reportChannelOrders(int count) => '$count đơn';
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
  String get homeEmptyBody => 'Nhập dữ liệu kinh doanh đầu tiên của bạn.';
  @override
  String get homeSampleLoadedSnack =>
      'Đã nạp dữ liệu mẫu — tất cả màn hình đang dùng chung dữ liệu này. '
      'Xóa trong More khi không cần nữa.';
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
      'Nạp một cửa hàng mẫu đầy đủ: 100 sản phẩm với báo giá nhà cung cấp và '
      'đối soát sàn, cộng 12 tháng lịch sử đơn hàng và thu chi (có mùa vụ Tết, '
      'hè, cuối năm) để Dự báo doanh thu và Rủi ro khách hàng có gì để nói. '
      'Nó vào ứng dụng như dữ liệu bình thường — mọi màn hình cùng hiển thị. '
      'Xoá bất cứ lúc nào bằng "Xóa dữ liệu mẫu"; dữ liệu bạn tự nhập không bị '
      'ảnh hưởng.';
  @override
  String get moreLoadSampleAction => 'Nạp mẫu';
  @override
  String moreSampleLoadedSnack(int products, int months) =>
      'Đã nạp $products sản phẩm và $months tháng lịch sử.';
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
  String get oppObservedPrefix => 'Doanh thu 60 ngày';
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
  String get oppInJourney => 'Cơ hội này đã nằm trong hành trình của bạn.';
  @override
  String get oppOpenJourney => 'Mở hành trình';
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
  String get homeStartJourney => 'Bắt đầu hành trình';
  @override
  String get homeStartJourneyNeedGoal =>
      'Tạo một mục tiêu trước — hành trình là kế hoạch cho một mục tiêu.';
  @override
  String get oppFilterAll => 'Tất cả cơ hội';
  @override
  String get oppFilterSaved => 'Đã lưu';
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
  String get agentRunNow => 'Chạy việc đến hạn';
  @override
  String get agentRunNothing => 'Chưa có việc nào đến hạn.';
  @override
  String agentRunDone(int count) => 'Đã xử lý $count việc đến hạn.';
  @override
  String get moreResetDemo => 'Đặt lại dữ liệu mẫu';
  @override
  String get moreResetDemoConfirmTitle => 'Đặt lại dữ liệu mẫu?';
  @override
  String get moreResetDemoConfirmBody =>
      'Dữ liệu mẫu sẽ về đúng trạng thái ban đầu, và mọi quyết định bạn đã ra cho dữ liệu mẫu sẽ bị xoá. Dữ liệu thật của bạn không bị đụng tới.';
  @override
  String moreResetDemoSnack(int decisions) =>
      'Đã đặt lại dữ liệu mẫu và xoá $decisions quyết định cũ.';

  @override
  String get titleAutonomy => 'Tôi được làm tới đâu';
  @override
  String get autonomySubtitle =>
      'Chọn mức cho từng mảng việc. Bạn đổi được bất cứ lúc nào.';
  @override
  String get autonomyAreaCustomerCare => 'Chăm sóc khách';
  @override
  String get autonomyAreaInventory => 'Kho và giá';
  @override
  String get autonomyAreaMarketing => 'Quảng cáo';
  @override
  String get autonomyModeSuggest => 'Gợi ý';
  @override
  String get autonomyModeConfirm => 'Hỏi trước khi làm';
  @override
  String get autonomyModeAuto => 'Tự động';
  @override
  String get autonomyModeSuggestBody => 'Tôi nói cho bạn biết, bạn tự làm.';
  @override
  String get autonomyModeConfirmBody => 'Tôi chuẩn bị sẵn và chờ bạn bấm.';
  @override
  String get autonomyModeAutoBody =>
      'Tôi tự làm trong hạn mức, rồi báo lại cho bạn.';
  @override
  String get autonomyPreviewBadge => 'Xem trước';
  @override
  String get autonomyPreviewBody =>
      'Mức tự động chưa chạy thật trong bản này. Bạn bật được để xem câu chuyện đổi thế nào, nhưng tôi vẫn hỏi bạn trước khi làm.';
  @override
  String get autonomyAlwaysAsk => 'Luôn hỏi bạn';
  @override
  String get autonomyAlwaysAskBody =>
      'Những việc này tôi không bao giờ tự làm, kể cả khi bạn chọn Tự động.';
  @override
  String get autonomyNoAuto =>
      'Mảng này chưa có việc nào tôi được phép tự làm.';
  @override
  String get actLabelSendMessage => 'Nhắn cho khách đã mua';
  @override
  String get actLabelColdMessage => 'Nhắn cho người chưa từng mua';
  @override
  String get actLabelContactOutside => 'Liên hệ người ngoài danh bạ';
  @override
  String get actLabelMergeCustomers => 'Gộp hai bản ghi khách';
  @override
  String get actLabelPurchaseOrder => 'Dựng phiếu nhập hàng';
  @override
  String get actLabelOrderAboveLimit => 'Nhập vượt hạn mức chi';
  @override
  String get actLabelUpdatePrice => 'Đổi giá bán';
  @override
  String get actLabelCampaignPause => 'Tạm dừng chiến dịch';
  @override
  String get actLabelCampaignBudget => 'Đổi ngân sách chiến dịch';
  @override
  String get automationTitle => 'Tôi làm việc này thế nào';

  @override
  String get briefActionAccept => 'Làm ngay';
  @override
  String get briefActionDismiss => 'Bỏ qua';
  @override
  String get briefActionLater => 'Để sau';
  @override
  String get briefStoryTitle => 'Chuyện gì đã xảy ra';
  @override
  String get briefStoryHappened => 'Bạn đã quyết';
  @override
  String get briefStoryNext => 'Tiếp theo';
  @override
  String get briefDemoExecution => 'Diễn tập — chưa gửi đi đâu';
  @override
  String get briefDemoExecutionBody =>
      'Việc đã được ghi lại đầy đủ trên máy bạn, nhưng chưa có kênh nào thật sự nhận nó. Khi bạn nối Telegram hay sàn bán hàng, đúng việc này sẽ chạy thật.';
  @override
  String get briefAcceptedSnack => 'Đã ghi nhận. Tôi sẽ theo dõi kết quả.';
  @override
  String get briefDismissedSnack => 'Đã bỏ qua. Tôi sẽ không nhắc lại.';
  @override
  String briefLaterSnack(int days) => 'Tôi sẽ nhắc lại sau $days ngày.';
  @override
  String get titleActivity => 'Tổng Tài đã làm gì';
  @override
  String get activitySubtitle => 'Những việc tôi đã xem và đã làm';
  @override
  String get activityToday => 'Hôm nay';
  @override
  String get activityEarlier => 'Trước đó';
  @override
  String get activityEmpty => 'Chưa có gì để kể';
  @override
  String get activityEmptyBody =>
      'Khi bạn quyết việc đầu tiên, tôi sẽ ghi lại ở đây: đã làm gì, kết quả ra sao, và bước tiếp theo là gì.';

  @override
  String get briefGreetingMorning => 'Chào buổi sáng';
  @override
  String get briefGreetingAfternoon => 'Chào buổi chiều';
  @override
  String get briefGreetingEvening => 'Chào buổi tối';
  @override
  String briefHeadline(int count) => 'Có $count việc đáng chú ý hôm nay';
  @override
  String get briefHeadlineNoCount => 'Tôi đã xem qua doanh nghiệp sáng nay';
  @override
  String get briefNothingTitle => 'Chưa có việc nào cần bạn quyết';
  @override
  String get briefNothingBody =>
      'Tôi vẫn đang theo dõi khách, kho và dòng tiền. Có gì đáng chú ý tôi báo ngay.';
  @override
  String get briefSeeAll => 'Xem tất cả';
  @override
  String get briefSectionDecide => 'Đang chờ bạn quyết';
  @override
  String get briefSectionKnow => 'Chỉ để bạn biết';
  @override
  String get briefWhyTitle => 'Vì sao tôi nghĩ vậy';
  @override
  String get briefSuggestTitle => 'Nên làm';
  @override
  String get briefStatusPending => 'Đang chờ bạn';
  @override
  String get briefStatusAccepted => 'Bạn đã duyệt';
  @override
  String get briefStatusDismissed => 'Bạn đã bỏ qua';
  @override
  String get briefStatusPostponed => 'Đã hẹn xem lại';
  @override
  String get titleAgent => 'Tổng Tài';
  @override
  String get agentSubtitle => 'Tôi đang trông doanh nghiệp cùng bạn';

  @override
  String get navOpportunity => 'Cơ hội';

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
  String get labelChannel => 'Kênh';
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
  String get finProductSection => 'Tài chính của sản phẩm';
  @override
  String get finSellingPrice => 'Giá bán';
  @override
  String get finCostPrice => 'Giá vốn';
  @override
  String get finProfitPerUnit => 'Lãi mỗi sản phẩm';
  @override
  String get finMargin => 'Biên lợi nhuận';
  @override
  String get finCostMissing =>
      'Chưa khai giá vốn — khai để thấy lãi và biên lợi nhuận';
  @override
  String finProjectedOnStock(int quantity) =>
      'Dự kiến nếu bán hết $quantity sản phẩm đang tồn';
  @override
  String finMeasuredIn(int days) => 'Đã bán trong $days ngày qua';
  @override
  String get finUnitsSold => 'Số lượng';
  @override
  String get finRevenue => 'Doanh thu';
  @override
  String get finRealProfit => 'Lợi nhuận thật';
  @override
  String get finNoSalesYet => 'Chưa bán được cái nào trong cửa sổ này';
  @override
  String get segCardUnit => 'khách';
  @override
  String segCardDelta(int delta) =>
      '${delta > 0 ? '+' : ''}$delta so với 30 ngày trước';
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
  String get homeChatTooltip => 'Trò chuyện Workizen AI';
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
  String get brandTagline => 'AI Business OS';
  @override
  String get actionOpen => 'Xem';
  @override
  String get actionHandleNow => 'Xử lý ngay';
  @override
  String get homeUnitInputs => 'đầu vào';
  @override
  String get homeUnitProducts => 'sản phẩm';
  @override
  String get homeUnitCustomers => 'khách hàng';
  @override
  String get homeUnitGoals => 'mục tiêu';
  @override
  String get oppPriorityHigh => 'Ưu tiên: Cao';
  @override
  String get oppPriorityMedium => 'Ưu tiên: Trung bình';
  @override
  String get oppPriorityLow => 'Ưu tiên: Thấp';
  @override
  String get oppPriorityUnknown => 'Chưa xếp được';
  @override
  String get oppWhyThisScore => 'Vì sao điểm này';
  @override
  String get supplierSectionTitle => 'Nguồn hàng';
  @override
  String get supplierCurrent => 'Đang nhập';
  @override
  String get supplierAlternatives => 'Lựa chọn khác';
  @override
  String get supplierUnknownLeadTime => 'chưa biết thời gian giao';
  @override
  String get supplierUnknownMoq => 'chưa biết số lượng tối thiểu';
  @override
  String get supplierUnknownRating => 'chưa có đánh giá';
  @override
  String supplierCheaperBy(int percent) => 'Rẻ hơn $percent%';
  @override
  String supplierSlowerByDays(int days) => 'Giao chậm hơn $days ngày';
  @override
  String supplierFasterByDays(int days) => 'Giao nhanh hơn $days ngày';
  @override
  String supplierExtraMoq(String quantity) => 'Phải đặt thêm $quantity';
  @override
  String get supplierTradeOffNote =>
      'Rẻ hơn chưa chắc tốt hơn — bạn là người quyết.';
  @override
  String get oppFactorProfit => 'Tiềm năng lợi nhuận';
  @override
  String get oppFactorDemand => 'Nhu cầu từ khách của bạn';
  @override
  String get oppFactorSupplier => 'Chất lượng nhà cung cấp';
  @override
  String get oppFactorCompetition => 'Mức cạnh tranh';
  @override
  String get oppFactorNoData => 'chưa có dữ liệu';
  @override
  String oppScoreCoverage(int percent) => 'Chấm được $percent% các yếu tố';
  @override
  String get oppUnavailSupplierSample =>
      'danh bạ nhà cung cấp hiện là dữ liệu mẫu';
  @override
  String get oppUnavailNeedsMarket => 'cần dữ liệu thị trường';
  @override
  String get oppUnavailNoBaseline => 'chưa có mốc doanh thu để so';
  @override
  String get oppUnavailNoDemandHistory => 'chưa có lịch sử đơn hàng';
  @override
  String get homeCloserTitle => 'Tổng Tài sẵn sàng hỗ trợ bạn!';
  @override
  String get homeCloserBody =>
      'Phân tích lợi nhuận? Tìm cơ hội mới? Hỏi tôi nhé.';
  @override
  String homeVsPrevMonth(String percent) => '$percent so với tháng trước';

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
  String invStockAlerts(String parts) => 'Cảnh báo tồn kho: $parts';
  @override
  String get homeGreeting => 'Chào bạn 👋';
  @override
  String homeHeadlineOpportunities(int count) =>
      'Hôm nay tôi tìm được $count cơ hội cho bạn.';
  @override
  String homeHeadlineTopActions(int count) =>
      'Hôm nay có $count việc đáng làm nhất.';
  @override
  String get homeHeadlineNoneToday =>
      'Hôm nay chưa có cơ hội nào nổi bật. Cứ ghi việc kinh doanh như thường, '
      'tôi vẫn đang theo dõi.';
  @override
  String get homeHeadlineNotEnoughData =>
      'Thêm vài dữ liệu đầu tiên để tôi bắt đầu tìm cơ hội cho bạn.';
  @override
  String get homeAskHint => 'Hỏi Tổng Tài bất cứ điều gì…';
  @override
  String get journeyDoStep => 'Làm ngay';
  @override
  String get journeyPlanDoneTitle => 'Bạn đã đi hết hành trình này 🎉';
  @override
  String get journeyPlanDoneBody =>
      'Mọi bước trong kế hoạch đã xong. Đặt mục tiêu tiếp theo để tôi lập '
      'hành trình mới cho bạn.';
  @override
  String get journeySetNextGoal => 'Đặt mục tiêu tiếp theo';
  @override
  String get subtitleProducer => 'Tìm cơ hội & nguồn hàng';
  @override
  String get subtitleInventory => 'Quản lý danh mục & kho';
  @override
  String get subtitleConsumer => 'Khách hàng & kênh bán';
  @override
  String get subtitleOpportunity => 'Cơ hội kinh doanh hôm nay';
  @override
  String get subtitleFinance => 'Quản lý tài chính doanh nghiệp';
  @override
  String get subtitleReports => 'Báo cáo & phân tích kinh doanh';
  @override
  String get productVariableCostLabel => 'Chi phí mỗi lượt bán';
  @override
  String get productKindLabel => 'Loại sản phẩm';
  @override
  String productKindName(String code) => switch (code) {
    'digital' => 'Sản phẩm số',
    'service' => 'Dịch vụ',
    'physical' => 'Hàng hoá',
    _ => 'Hàng hoá',
  };
  @override
  String get productKindNoStockNote => 'Loại này không có tồn kho để đếm.';
  @override
  String get titleBusinessInputs => 'Nguồn đầu vào';
  @override
  String get inputsCommitmentLabel => 'Cam kết mỗi tháng';
  @override
  String get inputsAllCounted => 'Đã tính đủ mọi nguồn.';
  @override
  String inputsUnknownCount(int count) =>
      'Còn $count nguồn chưa cộng được vào con số này.';
  @override
  String get inputsEmpty =>
      'Chưa có nguồn đầu vào nào. Thêm những thứ bạn trả tiền đều đặn để biết '
      'mỗi tháng mình cam kết bao nhiêu.';
  @override
  String get inputAddTitle => 'Thêm nguồn';
  @override
  String get inputEditTitle => 'Sửa nguồn';
  @override
  String get inputDelete => 'Xoá nguồn';
  @override
  String get inputKindLabel => 'Loại đầu vào';
  @override
  String get inputNameLabel => 'Tên nguồn';
  @override
  String get inputNameHint => 'VD: nhà cung cấp vải, tiền máy chủ';
  @override
  String get inputNameRequired => 'Cần một cái tên để nhận ra nguồn này';
  @override
  String get inputCadenceLabel => 'Nhịp trả tiền';
  @override
  String get inputAmountLabel => 'Số tiền mỗi nhịp';
  @override
  String get inputNoteLabel => 'Ghi chú';
  @override
  String get inputNotCommitmentNote =>
      'Nhịp này không tạo cam kết cố định nên số tiền không cộng vào tổng.';
  @override
  String get inputNotCounted => 'Chưa tính';
  @override
  String inputKindName(String code) => switch (code) {
    'supplier' => 'Nhà cung cấp',
    'provider' => 'Dịch vụ trả theo dùng',
    'infrastructure' => 'Hạ tầng',
    'tooling' => 'Công cụ',
    'people' => 'Người',
    _ => 'Nguồn khác',
  };
  @override
  String inputCadenceName(String? code) => switch (code) {
    'one_off' => 'Một lần',
    'monthly' => 'Hằng tháng',
    'yearly' => 'Hằng năm',
    'usage_based' => 'Theo mức dùng',
    _ => 'Chưa rõ nhịp',
  };
  @override
  String get producerInputsSection => 'Nguồn đầu vào';
  @override
  String get inputsJourneyStepTitle => 'Bước tiếp theo trong hành trình';
  @override
  String get stockSeeOpportunity => 'Xem cơ hội nhập hàng';
  @override
  String get customerSeeOpportunity => 'Xem cơ hội mời khách quay lại';
  @override
  String get invOverviewTitle => 'Tổng quan tồn kho';
  @override
  String get invOverviewProducts => 'Tổng sản phẩm';
  @override
  String get invOverviewValue => 'Giá trị tồn kho';
  @override
  String get invLowStockSection => 'Sản phẩm sắp hết hàng';
  @override
  String get invViewAll => 'Xem tất cả';
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
  String get homeTodaysMissions => 'Hành trình mục tiêu';
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

  // ── Product detail (WTM-335) ──────────────────────────────────────────────
  @override
  String get productDetailTitle => 'Chi tiết sản phẩm';
  @override
  String get productDetailCoreSection => 'Thông tin chính';
  @override
  String get productDetailSpecSection => 'Thông số kỹ thuật';
  @override
  String get productDetailEdit => 'Sửa';
  @override
  String get productDetailSku => 'SKU';
  @override
  String get productDetailCategory => 'Danh mục';
  @override
  String get productDetailPrice => 'Giá bán';
  @override
  String get productDetailStock => 'Tồn kho';
  @override
  String get productDetailKind => 'Loại';
  @override
  String get productDetailBrand => 'Thương hiệu';

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
    'wholesale' => 'Bán sỉ',
    'website' => 'Website của mình',
    'app_store' => 'Chợ ứng dụng',
    'direct' => 'Bán trực tiếp',
    // WTM-442 — bốn sàn thêm cùng hồ sơ File Bridge. Thiếu một mã ở đây thì
    // chip hiện "Kênh khác" cho một kênh app THỰC SỰ biết: trung thực, nhưng
    // vẫn sai.
    'ebay' => 'eBay',
    'amazon' => 'Amazon',
    'shopify' => 'Cửa hàng Shopify',
    'lazada' => 'Lazada',
    'marketplace_other' => 'Sàn khác',
    // WTM-232: trước đây nhánh này là `_ => 'Bán sỉ'`, nên MỌI mã mới thêm
    // vào sẽ âm thầm hiện thành "Bán sỉ" — một nhãn sai mà không gì báo. Nay
    // mọi mã đều được liệt kê, và mã lạ (từ bản dựng mới hơn) nói thật rằng
    // nó lạ thay vì mượn tên của một kênh có thật.
    _ => 'Kênh khác',
  };
  @override
  String get obStart => 'Bắt đầu';
  @override
  String get obNext => 'Tiếp';
  @override
  String get obBack => 'Quay lại';
  @override
  String get obProgress => 'Câu';
  @override
  String obQuestion(String stepId) => switch (stepId) {
    'business_type' => 'Bạn đang kinh doanh gì?',
    'trade' => 'Bạn đang bán gì?',
    'channels' => 'Bạn bán ở những đâu?',
    'size' => 'Hiện tại bạn làm ở quy mô nào?',
    _ => 'Có mùa nào bạn bán chạy hơn hẳn không?',
  };
  @override
  String get obV2WelcomeTitle => 'Tôi là Tổng Tài';
  @override
  String get obV2WelcomeBody =>
      'Tôi giúp bạn hiểu và điều hành doanh nghiệp bằng AI.';
  @override
  String get obV2ValueOpportunityTitle => 'Phát hiện cơ hội';
  @override
  String get obV2ValueOpportunityBody =>
      'Tìm chỗ còn tiền trong chính số liệu bạn đang có.';
  @override
  String get obV2ValueRiskTitle => 'Cảnh báo rủi ro';
  @override
  String get obV2ValueRiskBody =>
      'Báo trước khi hết hàng, khách nguội hay tiền hụt.';
  @override
  String get obV2ValueActionTitle => 'Đề xuất việc cần làm';
  @override
  String get obV2ValueActionBody =>
      'Mỗi phát hiện đi kèm một việc bấm được ngay.';
  @override
  String profileBusinessType(String code) => switch (code) {
    'goods' => 'Bán hàng (nhập, tồn, giao)',
    'digital' => 'Sản phẩm số, khoá học, phần mềm',
    'service' => 'Dịch vụ',
    'mixed' => 'Vừa bán hàng vừa làm dịch vụ',
    'preparing' => 'Đang chuẩn bị kinh doanh',
    _ => 'Khác',
  };
  @override
  String get obV2DataTitle => 'Tổng Tài cần hiểu doanh nghiệp của bạn';
  @override
  String get obV2DataBody => 'Chọn cách bạn muốn bắt đầu.';
  @override
  String get obV2DataCsvTitle => 'Nhập file Excel / CSV';
  @override
  String get obV2DataCsvBody => 'Sản phẩm, đơn hàng, khách hàng từ file có sẵn';
  @override
  String get obV2DataSampleTitle => 'Dùng dữ liệu mẫu';
  @override
  String get obV2DataSampleBody =>
      'Một doanh nghiệp 12 tháng để xem Tổng Tài làm được gì';
  @override
  String get obV2DataNoneTitle => 'Chưa có dữ liệu';
  @override
  String get obV2DataNoneBody => 'Bắt đầu từ ý tưởng kinh doanh';
  @override
  String get obV2DataConnectorsLater =>
      'Kết nối thẳng với sàn bán hàng sẽ có ở bản sau.';
  @override
  String get obV2AnalysisTitle => 'Tổng Tài đang hiểu doanh nghiệp của bạn';
  @override
  String get obV2AnalysisBody => 'Chạy ngay trên máy bạn, không gửi đi đâu cả.';
  @override
  String obV2AnalysisStage(String stageCode, int count) => switch (stageCode) {
    'products' => 'Đã đọc $count sản phẩm',
    'orders' => 'Đã phân tích $count đơn hàng',
    'customers' => 'Đã nhận diện $count khách hàng',
    'stock' => 'Đã kiểm tra tồn kho, $count mặt hàng cần chú ý',
    _ => 'Đã tìm ra $count điều đáng chú ý',
  };
  @override
  String get obV2InsightTitle => 'Tôi đã hiểu doanh nghiệp của bạn';
  @override
  String get obV2InsightBody => 'Đây là những điều đáng chú ý nhất lúc này.';
  @override
  String get obV2InsightQuietTitle => 'Tôi đã xem, chưa có gì gấp';
  @override
  String get obV2InsightQuietBody =>
      'Các luật đã chạy hết trên dữ liệu của bạn và không thấy việc nào cần '
      'làm ngay. Tôi sẽ báo khi có.';
  @override
  String get obV2InsightInsufficientTitle => 'Tôi chưa có gì để xem';
  @override
  String get obV2InsightInsufficientBody =>
      'Chưa đủ dữ liệu để kết luận. Đây không phải "mọi thứ đều ổn" — tôi chưa '
      'nhìn thấy gì cả.';
  @override
  String get obV2SnapshotRevenue => 'Doanh thu';
  @override
  String get obV2SnapshotProfit => 'Lợi nhuận';
  @override
  String get obV2SnapshotOrders => 'Đơn đã chốt';
  @override
  String get obV2SnapshotInventory => 'Vốn tồn kho';
  @override
  String get obV2ProfitUnknown => 'Chưa tính được';
  @override
  String get obV2GoalTitle => 'Bạn muốn Tổng Tài giúp đạt mục tiêu nào trước?';
  @override
  String get obV2GoalBody => 'Chọn 1–2 điều quan trọng nhất với bạn lúc này.';
  @override
  String get obV2GoalLimit => 'Chọn nhiều nhất 2 mục tiêu';
  @override
  String obV2Goal(String code) => switch (code) {
    'grow_revenue' => 'Tăng doanh thu',
    'grow_profit' => 'Tăng lợi nhuận',
    'find_products' => 'Tìm sản phẩm mới',
    'optimize_inventory' => 'Tối ưu tồn kho',
    'better_sourcing' => 'Tìm nguồn hàng tốt hơn',
    'keep_customers' => 'Giữ chân khách hàng',
    'new_market' => 'Bán sang thị trường mới',
    _ => 'Chỉ khám phá trước',
  };
  @override
  String get obV2PlanTitle => 'Kế hoạch đầu tiên của bạn';
  @override
  String get obV2PlanBody =>
      'Làm từ trên xuống. Mỗi việc mở thẳng vào chỗ làm.';
  @override
  String get obV2PlanEvidence => 'Vì sao';
  @override
  String get obV2PlanCta => 'Bắt đầu điều hành cùng Tổng Tài';
  @override
  String get obV2Continue => 'Tiếp tục';
  @override
  String get obV2SkipProfile => 'Bỏ qua, tôi khai sau';
  @override
  String get invShowAll => 'Xem tất cả';
  @override
  String get invTiedUpTitle => 'Vốn đang nằm trong hàng chậm bán';
  @override
  String invTiedUpBody(int count, int days) =>
      '$count mặt hàng còn tồn, không bán được cái nào trong $days ngày qua';
  @override
  String invTiedUpUnknownCost(int count) =>
      'Chưa tính $count mặt hàng — khai giá vốn để thấy con số đủ';
  @override
  String get invTiedUpAction => 'Xem hàng chậm bán';
  @override
  String get startupBrandOwner => 'Workizen';
  @override
  String get startupPlatform => 'AI Platform';
  @override
  String get startupBrand => 'Tổng Tài AI';
  @override
  String get startupTagline => 'Trợ lý điều hành doanh nghiệp bằng AI';
  @override
  String get startupWorking => 'Tổng Tài đang khởi động…';
  @override
  String startupStep(String stepCode, int? count) => switch (stepCode) {
    'database' => 'Đã mở cơ sở dữ liệu',
    'profile' => 'Đã đọc hồ sơ doanh nghiệp',
    'catalog' => 'Đã đọc ${count ?? 0} sản phẩm',
    _ => 'Đã đọc ${count ?? 0} đơn hàng',
  };
  @override
  String get startupPrivacy => 'Dữ liệu của bạn nằm trên máy này';
  @override
  String get obV2MascotGreeting => 'Tổng Tài đang chào bạn';
  @override
  String get obV2MascotWorking => 'Tổng Tài đang đọc dữ liệu của bạn';
  @override
  String get obV2MascotExplaining => 'Tổng Tài đang trình bày điều vừa tìm ra';
  @override
  String get obV2MascotPlanning => 'Tổng Tài đang đưa ra việc cần làm';
  @override
  String get obV2MascotCalm => 'Tổng Tài đã xem xong và không thấy gì gấp';
  @override
  String get obV2MascotIdle => 'Tổng Tài chưa có dữ liệu nào để xem';
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
  String get producerSavedSuppliers => 'Nhà cung cấp đã lưu';
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
  String get supRatings => 'Đánh giá';
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
  String invProductCount(int count) => '$count sản phẩm';

  @override
  String get titleWeeklyReview => 'Tổng kết tuần';
  @override
  String get weeklyReviewSubtitle => 'Tuần rồi thế nào, tuần tới nên làm gì';
  @override
  String get weeklyReviewRange => 'Tuần';
  @override
  String get weeklyReviewRevenue => 'Doanh thu';
  @override
  String get weeklyReviewOrders => 'Đơn hàng';
  @override
  String get weeklyReviewCustomers => 'Khách mua';
  @override
  String get weeklyReviewAov => 'Trung bình mỗi đơn';
  @override
  String get weeklyReviewVsPrevious => 'So với tuần trước';
  @override
  String get weeklyReviewNoPrevious => 'Chưa có tuần trước để so';
  @override
  String get weeklyReviewTopProduct => 'Bán chạy nhất tuần';
  @override
  String get weeklyReviewNothingSold => 'Tuần rồi không bán được gì';
  @override
  String get weeklyReviewNothingSoldBody =>
      'Đây là số thật, không phải lỗi đọc dữ liệu. Xem lại tồn kho và khách '
      'lâu chưa quay lại để chuẩn bị cho tuần tới.';
  @override
  String get weeklyReviewHistory => 'Bốn tuần gần nhất';
  @override
  String get weeklyReviewInsufficient => 'Chưa đủ dữ liệu để tổng kết';
  @override
  String get weeklyReviewInsufficientBody =>
      'Cần ít nhất một tuần đã kết thúc có đơn hàng. Ghi đơn trong tuần này, '
      'sáng thứ Hai sẽ có bản tổng kết đầu tiên.';
  @override
  String get weeklyReviewWhy => 'Vì sao';

  @override
  String get estimateDisclaimer =>
      'Đây là ước tính tính từ dữ liệu bán hàng của chính bạn — không phải '
      'cam kết. Quyết định cuối cùng vẫn là của bạn.';
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
  String get briefFailedTitle => 'Chưa dựng được việc hôm nay';
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
  String get titleConnections => 'Kết nối';
  @override
  String get connectionsIntro =>
      'Tổng Tài dùng chính tài khoản của bạn trên các nền tảng này. Dữ liệu '
      'vẫn nằm trên máy bạn; khoá kết nối được cất riêng, không nằm trong file '
      'sao lưu.';
  @override
  String get connectorGoogle => 'Google';
  @override
  String get connectorTelegram => 'Telegram';
  @override
  String get connectorAtlassian => 'Jira & Confluence';
  @override
  String get connectionSetupRequired => 'Chưa thiết lập';
  @override
  String get connectionActive => 'Đang hoạt động';
  @override
  String get connectionPaused => 'Tạm dừng';
  @override
  String get connectionError => 'Cần kết nối lại';
  @override
  String get connectionConnect => 'Kết nối';
  @override
  String get connectionDisconnect => 'Ngắt kết nối';
  @override
  String get connectionDisconnectConfirm =>
      'Ngắt kết nối sẽ xoá khoá khỏi máy này. Dữ liệu kinh doanh giữ nguyên.';
  @override
  String get connectionNotConfigured =>
      'Bản cài này chưa có khoá ứng dụng Google nên chưa đăng nhập được. '
      'Mọi phần còn lại đã sẵn sàng.';
  @override
  String get driveBackupTitle => 'Sao lưu lên Google Drive';
  @override
  String get driveBackupHint =>
      'Tổng Tài chỉ thấy được những file do chính nó tạo trong Drive của bạn.';
  @override
  String get driveBackupNow => 'Sao lưu ngay';
  @override
  String get driveBackupRunning => 'Đang sao lưu…';
  @override
  String driveBackupDone(String time) => 'Đã lưu lên Google Drive lúc $time';
  @override
  String get driveBackupList => 'Các bản đã lưu trên Drive';
  @override
  String get driveBackupEmpty => 'Chưa có bản sao lưu nào trên Drive.';
  @override
  String get driveBackupRestore => 'Khôi phục từ bản này';
  @override
  String get capabilityDriveBackup => 'Sao lưu lên Drive';
  @override
  String get capabilityTelegramMessaging => 'Nhắn cho khách qua Telegram';
  @override
  String get capabilityJiraWork => 'Đọc công việc trong Jira';
  @override
  String get capabilityConfluenceKnowledge => 'Đọc tài liệu Confluence';
  @override
  String get actLabelBackupUpload => 'Sao lưu dữ liệu';
  @override
  String get actLabelOwnerNotify => 'Báo cho bạn';

  @override
  String get titleImport => 'Nhập dữ liệu cửa hàng';
  @override
  String get importIntro =>
      'Tổng Tài đọc file của bạn ngay trên máy này. Bạn xem trước rồi mới '
      'quyết định có nhập hay không.';
  @override
  String get importPickFile => 'Chọn file Excel của tôi';
  @override
  String importReadyProducts(int count) => '$count sản phẩm đã sẵn sàng';
  @override
  String importReadyVariants(int count) => '$count phiên bản';
  @override
  String importReadySuppliers(int count) => '$count báo giá nhà cung cấp';
  @override
  String importReadyOrders(int count) => '$count đơn hàng';
  @override
  String importReadyCustomers(int count) => '$count khách hàng';
  @override
  String importBlocked(int count) => '$count dòng cần xem lại — sẽ bỏ qua';
  @override
  String importWarned(int count) => '$count dòng có cảnh báo — vẫn nhập được';
  @override
  String get importConfirm => 'Nhập vào cửa hàng';
  @override
  String get importRunning => 'Đang nhập…';
  @override
  String importDone(int count) => 'Đã nhập $count sản phẩm vào cửa hàng.';

  @override
  String get importMapTitle => 'File này của sàn nào?';
  @override
  String get importMapIntro =>
      'Ứng dụng chưa nhận ra file này. Chỉ giúp cột nào là cột nào — lần sau '
      'không phải làm lại.';
  @override
  String get importMapVendor => 'Sàn';
  @override
  String get importMapKind => 'Loại file';
  @override
  String get importMapKindOrders => 'File đơn hàng';
  @override
  String get importMapKindIncome => 'Báo cáo thu nhập';
  @override
  String get importMapUnset => 'Chưa chọn';
  @override
  String get importMapSave => 'Lưu và đọc lại';
  @override
  String importMapMissing(String roles) => 'Còn thiếu: $roles';
  @override
  String importMapField(String field) => switch (field) {
    'orderId' => 'Mã đơn hàng',
    'orderDate' => 'Ngày đặt',
    'status' => 'Trạng thái',
    'sku' => 'Mã hàng (SKU)',
    'productName' => 'Tên sản phẩm',
    'quantity' => 'Số lượng',
    'unitPrice' => 'Đơn giá',
    'buyerName' => 'Tên người mua',
    'buyerId' => 'Mã người mua',
    'commission' => 'Hoa hồng sàn',
    'transactionFee' => 'Phí thanh toán',
    'serviceFee' => 'Phí dịch vụ',
    'shippingFee' => 'Phí vận chuyển',
    'voucher' => 'Voucher người bán trả',
    'platformVoucher' => 'Voucher sàn tài trợ',
    'payout' => 'Tiền thực nhận',
    // Vai trò từ một bản dựng mới hơn: hiện đúng mã thay vì mượn tên một vai
    // trò có thật — cùng kỷ luật `_ => 'Kênh khác'` của `profileChannel`.
    _ => field,
  };
  @override
  String get importNothing => 'Không có gì để nhập từ file này.';
  @override
  String get importHistory => 'Đã nhập trước đây';
  @override
  String get importReset => 'Bỏ lần nhập này';
  @override
  String get importResetConfirm =>
      'Chỉ xoá những gì lần nhập này mang vào. Dữ liệu bạn tự nhập giữ nguyên.';
  @override
  String importResetDone(int count) => 'Đã bỏ $count bản ghi.';
  @override
  String importIssueLocation(String sheet, int row) => '$sheet · dòng $row';
  @override
  String importMoreIssues(int count) => '… và $count dòng nữa';
  @override
  String importRecordCount(int count) => '$count bản ghi';
  @override
  String get sourcesCommerce => 'Nguồn đơn hàng';
  @override
  String get sourcesSourcing => 'Nguồn nhập hàng';
  @override
  String get sourcesMessaging => 'Kênh khách nhắn';
  @override
  String get sourcesLogistics => 'Vận chuyển';
  @override
  String get sourcesFinance => 'Tiền về';
  @override
  String get sourcesStartDemo => 'Bắt đầu doanh nghiệp demo';
  @override
  String sourcesDemoLive(int count) =>
      '$count nền tảng đang phát dữ liệu trong bản mô phỏng. '
      'Không có kết nối thật nào — không byte nào rời máy này.';
  @override
  String get sourcesHonestNote =>
      'Danh sách này nói đúng trạng thái hiện tại. Nguồn chưa nối thì ghi là '
      'chưa nối — dữ liệu mẫu không được trình bày như dữ liệu từ sàn.';
  @override
  String get readinessConnected => 'Đang dùng';
  @override
  String get readinessFileBridge => 'Nhập qua file';
  @override
  String get readinessDemo => 'Dữ liệu mẫu';
  @override
  String get readinessDemoConnected => 'Demo — đang phát';
  @override
  String get readinessResearched => 'Đã nghiên cứu';
  @override
  String get readinessPartnerRequired => 'Chờ sàn duyệt';
  @override
  String get readinessApiFuture => 'Để sau';

  @override
  String get titleBusinessLife => 'Doanh nghiệp của bạn';
  @override
  String get demoStart => 'Bắt đầu doanh nghiệp demo';
  @override
  String get demoNextEvent => 'Việc tiếp';
  @override
  String get demoNextDay => 'Ngày tiếp';
  @override
  String get demoNextWeek => 'Tuần tiếp';
  @override
  String get demoReset => 'Bắt đầu lại';
  @override
  String orderRemoveLine(String product) => 'Xoá $product khỏi đơn';

  @override
  @override
  String get splashOwner => 'Workizen';
  @override
  String get splashProduct => 'Quản lý Quan hệ Khách hàng';
  @override
  String get splashPlatform => 'Nền tảng AI';
  @override
  String get splashLoading => 'Đang khởi động AI…';
  @override
  String get splashTagline => 'Mỗi mối quan hệ một thông minh hơn';

  @override
  String demoDayOf(int day, int total) => 'Ngày $day / $total';
  @override
  String get demoNeedsCatalogue =>
      'Cần có danh mục sản phẩm trước. Vào Nhập dữ liệu cửa hàng và dùng bộ mẫu.';
  @override
  String get demoFinished => 'Đã hết 30 ngày. Bắt đầu lại để chạy vòng mới.';
  @override
  String get demoNotStarted => 'Chưa bắt đầu doanh nghiệp demo.';
  @override
  String demoAdvanced(int count) => 'Đã đi tới $count việc mới';
  @override
  String get actorPlatform => 'Sàn';
  @override
  String get actorAgent => 'Tổng Tài';
  @override
  String get actorSeller => 'Bạn';

  @override
  String get titleConversations => 'Hội thoại khách hàng';
  @override
  String get conversationsEmpty =>
      'Chưa có hội thoại nào. Bắt đầu doanh nghiệp demo ở màn Doanh nghiệp của '
      'bạn để khách bắt đầu nhắn tin.';
  @override
  String get conversationAwaiting => 'Khách đang chờ';
  @override
  String get conversationDraftReady => 'Tổng Tài đã soạn';
  @override
  String get conversationNeedsApproval => 'Cần bạn duyệt';
  @override
  String get conversationDraftLabel => 'Tổng Tài soạn — chưa gửi';
  @override
  String get conversationSend => 'Gửi';
  @override
  String get conversationEdit => 'Sửa lời';
  @override
  String get conversationSent => 'Đã gửi (mô phỏng — không ra khỏi máy này)';
  @override
  String get conversationSendFailed => 'Chưa gửi được. Thử lại.';
  @override
  String get conversationYouSent => 'Bạn đã gửi';
  @override
  String get customer360Story => 'Câu chuyện khách hàng';
  @override
  String customer360FirstTouch(String channel, String date) =>
      'Biết tới shop qua $channel · $date';
  @override
  String get customer360Suggestions => 'Gợi ý cho khách này';
  @override
  String customer360BoughtTogether(int count) => '$count khách khác mua kèm';
  @override
  String get customer360OpenConversation => 'Mở hội thoại';

  @override
  String get telegramTitle => 'Nhận bản tin qua Telegram';
  @override
  String get telegramHint =>
      'Tổng Tài sẽ nhắn bản tin sáng cho bạn. Bot Telegram không nhắn trước '
      'được cho ai, nên bạn phải mở chat với bot một lần — cũng vì vậy bot '
      'không thể nhắn cho khách hàng của bạn.';
  @override
  String get telegramTokenLabel => 'Bot token';
  @override
  String get telegramTokenHint => 'Nhắn @BotFather trên Telegram để tạo bot.';
  @override
  String get telegramSaveToken => 'Lưu token';
  @override
  String get telegramTokenBad =>
      'Telegram không nhận token này. Kiểm tra lại chuỗi BotFather đưa.';
  @override
  String telegramBotFound(String username) => 'Đã nhận $username';
  @override
  String get telegramStartHint =>
      'Mở Telegram, nhắn /start cho bot, rồi bấm Tìm cuộc trò chuyện.';
  @override
  String get telegramFindChats => 'Tìm cuộc trò chuyện';
  @override
  String get telegramNoChats =>
      'Chưa thấy ai nhắn cho bot. Nhắn /start rồi thử lại.';
  @override
  String get telegramSendTest => 'Gửi tin thử';
  @override
  String get telegramTestSent => 'Đã gửi. Mở Telegram xem thử.';

  @override
  String get atlassianTitle => 'Công việc trong Jira & Confluence';
  @override
  String get atlassianHint =>
      'Tổng Tài chỉ đọc, và chỉ đọc đúng dự án bạn chọn. Không phải để thay '
      'Jira — chỉ để trả lời "công việc đang thế nào".';
  @override
  String get atlassianUrlLabel => 'Địa chỉ Atlassian';
  @override
  String get atlassianUrlHint => 'https://ten-cua-ban.atlassian.net';
  @override
  String get atlassianEmailLabel => 'Email tài khoản';
  @override
  String get atlassianTokenLabel => 'API token';
  @override
  String get atlassianTokenHint =>
      'Tạo tại id.atlassian.com → Security → API tokens.';
  @override
  String get atlassianSave => 'Kiểm tra và lưu';
  @override
  String get atlassianBad =>
      'Atlassian không nhận khoá này. Kiểm tra lại địa chỉ, email và token.';
  @override
  String get atlassianPickProject => 'Chọn dự án';
  @override
  String get atlassianPickSpace => 'Chọn không gian tài liệu';
  @override
  String get atlassianNoProjects => 'Chưa thấy dự án nào trong tài khoản này.';
  @override
  String get atlassianNoData =>
      'Chưa đủ dữ liệu để nói công việc đang thế nào.';

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
  String get invShowAll => 'Show all';
  @override
  String get invTiedUpTitle => 'Capital sitting in slow-moving stock';
  @override
  String invTiedUpBody(int count, int days) =>
      '$count items in stock with no sales in the last $days days';
  @override
  String invTiedUpUnknownCost(int count) =>
      '$count items not counted — add cost price to see the full number';
  @override
  String get invTiedUpAction => 'View slow-moving stock';

  @override
  String get actionViewAll => 'View all';
  @override
  String get actionSearch => 'Search';
  @override
  String get actionCancel => 'Cancel';

  @override
  String get titleReports => 'Reports & Analytics';
  @override
  String get titleFinance => 'Finance';
  @override
  String get titleGoalDetail => 'Goal details';

  @override
  String countOpportunities(int count) =>
      count == 1 ? '1 opportunity' : '$count opportunities';
  @override
  String countOrders(int count) => count == 1 ? '1 order' : '$count orders';
  @override
  String countCustomers(int count) =>
      count == 1 ? '1 customer' : '$count customers';
  @override
  String unsavedChanges(int count) => 'Unsaved changes ($count)';
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
  String get finCatInfrastructure => 'Infrastructure';
  @override
  String get finCatTooling => 'Tooling';
  @override
  String get finCatProvider => 'Usage-based service';
  @override
  String get finCatProductCost => 'Product cost';
  @override
  String get finCatPlatformFee => 'Platform fee';
  @override
  String get finCatShipping => 'Shipping';
  @override
  String get finCatStaff => 'Staff';
  @override
  String get finCatMarketing => 'Marketing';
  @override
  String get finCatRent => 'Rent';
  @override
  String get finCatSales => 'Sales';
  @override
  String get finCatOther => 'Other';
  @override
  String financeFromSales(String amount) => 'incl. $amount from sales';
  @override
  String get financeReceivablesTitle => 'Receivables';
  @override
  String financeReceivablesBody(String amount, int debtors) =>
      '$amount stuck across $debtors customers';
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
  String get sectionRevenueByChannel => 'Revenue by channel';
  @override
  String reportChannelOrders(int count) =>
      count == 1 ? '1 order' : '$count orders';
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
  String get homeEmptyBody => 'Enter your first business data.';
  @override
  String get homeSampleLoadedSnack =>
      'Sample data loaded — every screen now shares this data. '
      'Remove it in More when you no longer need it.';
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
      'Loads a complete sample shop: 100 products with supplier quotes and '
      'marketplace settlements, plus 12 months of order and cash history (with '
      'Tết, summer and year-end seasonality) so Revenue forecast and Customer '
      'risk have something to say. It enters the app as ordinary data — every '
      'screen shows it. Remove it any time with "Remove sample data"; data you '
      'entered yourself is never touched.';
  @override
  String get moreLoadSampleAction => 'Load samples';
  @override
  String moreSampleLoadedSnack(int products, int months) =>
      'Loaded $products products and $months months of history.';
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
  String get oppObservedPrefix => 'Revenue, last 60 days';
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
  String get oppInJourney => 'This opportunity is in your journey.';
  @override
  String get oppOpenJourney => 'Open the journey';
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
  String get homeStartJourney => 'Start a journey';
  @override
  String get homeStartJourneyNeedGoal =>
      'Create a goal first — a journey is the plan for a goal.';
  @override
  String get oppFilterAll => 'All opportunities';
  @override
  String get oppFilterSaved => 'Saved';
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
  String get agentRunNow => 'Run what is due';
  @override
  String get agentRunNothing => 'Nothing is due yet.';
  @override
  String agentRunDone(int count) => 'Handled $count due items.';
  @override
  String get moreResetDemo => 'Reset sample data';
  @override
  String get moreResetDemoConfirmTitle => 'Reset sample data?';
  @override
  String get moreResetDemoConfirmBody =>
      'Sample data returns to its starting state, and every decision you made about sample data is removed. Your real data is untouched.';
  @override
  String moreResetDemoSnack(int decisions) =>
      'Sample data reset; $decisions old decisions removed.';

  @override
  String get titleAutonomy => 'How far I may go';
  @override
  String get autonomySubtitle =>
      'Pick a level for each area. You can change it any time.';
  @override
  String get autonomyAreaCustomerCare => 'Customer care';
  @override
  String get autonomyAreaInventory => 'Stock and pricing';
  @override
  String get autonomyAreaMarketing => 'Advertising';
  @override
  String get autonomyModeSuggest => 'Suggest';
  @override
  String get autonomyModeConfirm => 'Ask before acting';
  @override
  String get autonomyModeAuto => 'Automatic';
  @override
  String get autonomyModeSuggestBody => 'I tell you; you do it.';
  @override
  String get autonomyModeConfirmBody => 'I prepare it and wait for your tap.';
  @override
  String get autonomyModeAutoBody =>
      'I act within your limits, then report back.';
  @override
  String get autonomyPreviewBadge => 'Preview';
  @override
  String get autonomyPreviewBody =>
      'Automatic does not run for real in this build. Turn it on to see how the story changes — I will still ask you before acting.';
  @override
  String get autonomyAlwaysAsk => 'Always ask me';
  @override
  String get autonomyAlwaysAskBody =>
      'I never do these on my own, even when you choose Automatic.';
  @override
  String get autonomyNoAuto => 'Nothing in this area may run on its own yet.';
  @override
  String get actLabelSendMessage => 'Message an existing customer';
  @override
  String get actLabelColdMessage => 'Message someone who never bought';
  @override
  String get actLabelContactOutside => 'Contact someone outside the book';
  @override
  String get actLabelMergeCustomers => 'Merge two customer records';
  @override
  String get actLabelPurchaseOrder => 'Draft a purchase order';
  @override
  String get actLabelOrderAboveLimit => 'Order above your spend limit';
  @override
  String get actLabelUpdatePrice => 'Change a selling price';
  @override
  String get actLabelCampaignPause => 'Pause a campaign';
  @override
  String get actLabelCampaignBudget => 'Change a campaign budget';
  @override
  String get automationTitle => 'How I handle this';

  @override
  String get briefActionAccept => 'Do it';
  @override
  String get briefActionDismiss => 'Dismiss';
  @override
  String get briefActionLater => 'Later';
  @override
  String get briefStoryTitle => 'What happened';
  @override
  String get briefStoryHappened => 'You decided';
  @override
  String get briefStoryNext => 'Next';
  @override
  String get briefDemoExecution => 'Rehearsal — nothing was sent';
  @override
  String get briefDemoExecutionBody =>
      'The work is fully recorded on your device, but no channel actually received it. Connect Telegram or a marketplace and this exact action runs for real.';
  @override
  String get briefAcceptedSnack => 'Recorded. I will watch what comes of it.';
  @override
  String get briefDismissedSnack => 'Dismissed. I will not bring it up again.';
  @override
  String briefLaterSnack(int days) => 'I will remind you in $days days.';
  @override
  String get titleActivity => 'What Tổng Tài did';
  @override
  String get activitySubtitle => 'What I looked at and what I did';
  @override
  String get activityToday => 'Today';
  @override
  String get activityEarlier => 'Earlier';
  @override
  String get activityEmpty => 'Nothing to tell yet';
  @override
  String get activityEmptyBody =>
      'The moment you decide your first item, I will record it here: what was done, how it went, and what comes next.';

  @override
  String get briefGreetingMorning => 'Good morning';
  @override
  String get briefGreetingAfternoon => 'Good afternoon';
  @override
  String get briefGreetingEvening => 'Good evening';
  @override
  String briefHeadline(int count) => '$count things worth your attention today';
  @override
  String get briefHeadlineNoCount => 'I looked over your business this morning';
  @override
  String get briefNothingTitle => 'Nothing needs your decision yet';
  @override
  String get briefNothingBody =>
      'I am still watching customers, stock and cash. I will tell you the moment something matters.';
  @override
  String get briefSeeAll => 'See all';
  @override
  String get briefSectionDecide => 'Waiting on you';
  @override
  String get briefSectionKnow => 'Just so you know';
  @override
  String get briefWhyTitle => 'Why I think so';
  @override
  String get briefSuggestTitle => 'Suggested';
  @override
  String get briefStatusPending => 'Waiting on you';
  @override
  String get briefStatusAccepted => 'You approved';
  @override
  String get briefStatusDismissed => 'You dismissed';
  @override
  String get briefStatusPostponed => 'Scheduled to revisit';
  @override
  String get titleAgent => 'Tổng Tài';
  @override
  String get agentSubtitle => 'I am watching the business with you';

  @override
  String get navOpportunity => 'Opportunity';

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
  String get labelChannel => 'Channel';
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
  String get finProductSection => 'Product finance';
  @override
  String get finSellingPrice => 'Selling price';
  @override
  String get finCostPrice => 'Cost price';
  @override
  String get finProfitPerUnit => 'Profit per unit';
  @override
  String get finMargin => 'Margin';
  @override
  String get finCostMissing =>
      'No cost price yet — add it to see profit and margin';
  @override
  String finProjectedOnStock(int quantity) =>
      'Projected if all $quantity units in stock sell';
  @override
  String finMeasuredIn(int days) => 'Sold in the last $days days';
  @override
  String get finUnitsSold => 'Units';
  @override
  String get finRevenue => 'Revenue';
  @override
  String get finRealProfit => 'Real profit';
  @override
  String get finNoSalesYet => 'No sales in this window yet';
  @override
  String get segCardUnit => 'customers';
  @override
  String segCardDelta(int delta) =>
      '${delta > 0 ? '+' : ''}$delta vs 30 days ago';
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
  String get homeChatTooltip => 'Workizen AI chat';
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
  String get brandTagline => 'AI Business OS';
  @override
  String get actionOpen => 'Open';
  @override
  String get actionHandleNow => 'Handle now';
  @override
  String get homeUnitInputs => 'inputs';
  @override
  String get homeUnitProducts => 'products';
  @override
  String get homeUnitCustomers => 'customers';
  @override
  String get homeUnitGoals => 'goals';
  @override
  String get oppPriorityHigh => 'Priority: High';
  @override
  String get oppPriorityMedium => 'Priority: Medium';
  @override
  String get oppPriorityLow => 'Priority: Low';
  @override
  String get oppPriorityUnknown => 'Not ranked';
  @override
  String get oppWhyThisScore => 'Why this score';
  @override
  String get supplierSectionTitle => 'Sourcing';
  @override
  String get supplierCurrent => 'Currently buying from';
  @override
  String get supplierAlternatives => 'Other options';
  @override
  String get supplierUnknownLeadTime => 'lead time unknown';
  @override
  String get supplierUnknownMoq => 'minimum order unknown';
  @override
  String get supplierUnknownRating => 'no rating yet';
  @override
  String supplierCheaperBy(int percent) => '$percent% cheaper';
  @override
  String supplierSlowerByDays(int days) => '$days days slower';
  @override
  String supplierFasterByDays(int days) => '$days days faster';
  @override
  String supplierExtraMoq(String quantity) => 'Order $quantity more';
  @override
  String get supplierTradeOffNote =>
      'Cheaper is not always better — the call is yours.';
  @override
  String get oppFactorProfit => 'Profit potential';
  @override
  String get oppFactorDemand => 'Demand from your customers';
  @override
  String get oppFactorSupplier => 'Supplier quality';
  @override
  String get oppFactorCompetition => 'Competition';
  @override
  String get oppFactorNoData => 'no data yet';
  @override
  String oppScoreCoverage(int percent) => 'Scored on $percent% of factors';
  @override
  String get oppUnavailSupplierSample =>
      'the supplier directory is sample data';
  @override
  String get oppUnavailNeedsMarket => 'needs market data';
  @override
  String get oppUnavailNoBaseline => 'no revenue baseline to compare against';
  @override
  String get oppUnavailNoDemandHistory => 'no order history yet';
  @override
  String get homeCloserTitle => 'Tổng Tài is ready to help!';
  @override
  String get homeCloserBody => 'Profit analysis? New opportunities? Just ask.';
  @override
  String homeVsPrevMonth(String percent) => '$percent vs last month';

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
  String invStockAlerts(String parts) => 'Stock alerts: $parts';
  @override
  String get homeGreeting => 'Hello 👋';
  @override
  String homeHeadlineOpportunities(int count) =>
      'I found $count opportunities for you today.';
  @override
  String homeHeadlineTopActions(int count) =>
      '$count things worth doing today.';
  @override
  String get homeHeadlineNoneToday =>
      'Nothing stands out today. Keep recording your business — I am still '
      'watching.';
  @override
  String get homeHeadlineNotEnoughData =>
      'Add your first few records so I can start finding opportunities.';
  @override
  String get homeAskHint => 'Ask Tổng Tài anything…';
  @override
  String get journeyDoStep => 'Do it now';
  @override
  String get journeyPlanDoneTitle => 'You finished this journey 🎉';
  @override
  String get journeyPlanDoneBody =>
      'Every step in the plan is done. Set your next goal and I will plan the '
      'next journey.';
  @override
  String get journeySetNextGoal => 'Set the next goal';
  @override
  String get subtitleProducer => 'Find opportunities and suppliers';
  @override
  String get subtitleInventory => 'Products and warehouse';
  @override
  String get subtitleConsumer => 'Customers and sales channels';
  @override
  String get subtitleOpportunity => "Today's business opportunities";
  @override
  String get subtitleFinance => 'Business finances';
  @override
  String get subtitleReports => 'Business reports and analytics';
  @override
  String get productVariableCostLabel => 'Cost per sale';
  @override
  String get productKindLabel => 'Product type';
  @override
  String productKindName(String code) => switch (code) {
    'digital' => 'Digital product',
    'service' => 'Service',
    'physical' => 'Goods',
    _ => 'Goods',
  };
  @override
  String get productKindNoStockNote => 'This type has no stock to count.';
  @override
  String get titleBusinessInputs => 'Business inputs';
  @override
  String get inputsCommitmentLabel => 'Committed each month';
  @override
  String get inputsAllCounted => 'Every input is counted.';
  @override
  String inputsUnknownCount(int count) =>
      '$count input(s) are not part of this figure yet.';
  @override
  String get inputsEmpty =>
      'No inputs yet. Add what you pay for regularly to see what you commit to '
      'each month.';
  @override
  String get inputAddTitle => 'Add input';
  @override
  String get inputEditTitle => 'Edit input';
  @override
  String get inputDelete => 'Delete input';
  @override
  String get inputKindLabel => 'Input type';
  @override
  String get inputNameLabel => 'Input name';
  @override
  String get inputNameHint => 'e.g. fabric supplier, server bill';
  @override
  String get inputNameRequired => 'A name is needed to recognise this input';
  @override
  String get inputCadenceLabel => 'Payment rhythm';
  @override
  String get inputAmountLabel => 'Amount per payment';
  @override
  String get inputNoteLabel => 'Note';
  @override
  String get inputNotCommitmentNote =>
      'This rhythm is not a fixed commitment, so the amount stays out of the '
      'total.';
  @override
  String get inputNotCounted => 'Not counted';
  @override
  String inputKindName(String code) => switch (code) {
    'supplier' => 'Supplier',
    'provider' => 'Usage-based service',
    'infrastructure' => 'Infrastructure',
    'tooling' => 'Tooling',
    'people' => 'People',
    _ => 'Other input',
  };
  @override
  String inputCadenceName(String? code) => switch (code) {
    'one_off' => 'One-off',
    'monthly' => 'Monthly',
    'yearly' => 'Yearly',
    'usage_based' => 'Usage-based',
    _ => 'Rhythm unknown',
  };
  @override
  String get producerInputsSection => 'Business inputs';
  @override
  String get inputsJourneyStepTitle => 'Next step in your journey';
  @override
  String get stockSeeOpportunity => 'See the restock opportunity';
  @override
  String get customerSeeOpportunity => 'See the win-back opportunity';
  @override
  String get invOverviewTitle => 'Inventory overview';
  @override
  String get invOverviewProducts => 'Products';
  @override
  String get invOverviewValue => 'Stock value';
  @override
  String get invLowStockSection => 'Products running low';
  @override
  String get invViewAll => 'View all';
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
  String get homeTodaysMissions => 'Goal journey';
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

  // ── Product detail (WTM-335) ──────────────────────────────────────────────
  @override
  String get productDetailTitle => 'Product detail';
  @override
  String get productDetailCoreSection => 'Key information';
  @override
  String get productDetailSpecSection => 'Specifications';
  @override
  String get productDetailEdit => 'Edit';
  @override
  String get productDetailSku => 'SKU';
  @override
  String get productDetailCategory => 'Category';
  @override
  String get productDetailPrice => 'Price';
  @override
  String get productDetailStock => 'Stock';
  @override
  String get productDetailKind => 'Type';
  @override
  String get productDetailBrand => 'Brand';

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
    'wholesale' => 'Wholesale',
    'website' => 'Own website',
    'app_store' => 'App store',
    'direct' => 'Direct / contract',
    // WTM-442 — see the Vietnamese twin.
    'ebay' => 'eBay',
    'amazon' => 'Amazon',
    'shopify' => 'Shopify store',
    'lazada' => 'Lazada',
    'marketplace_other' => 'Other marketplace',
    // See the Vietnamese twin: this used to be `_ => 'Wholesale'`, which
    // silently mislabelled every code added afterwards (WTM-232).
    _ => 'Other channel',
  };
  @override
  String get obStart => 'Start';
  @override
  String get obNext => 'Next';
  @override
  String get obBack => 'Back';
  @override
  String get obProgress => 'Question';
  @override
  String obQuestion(String stepId) => switch (stepId) {
    'business_type' => 'What kind of business do you run?',
    'trade' => 'What do you sell?',
    'channels' => 'Where do you sell?',
    'size' => 'How big is it right now?',
    _ => 'Any season when you sell much more?',
  };
  @override
  String get obV2WelcomeTitle => 'I am Tổng Tài';
  @override
  String get obV2WelcomeBody =>
      'I help you understand and run your business with AI.';
  @override
  String get obV2ValueOpportunityTitle => 'Spot opportunities';
  @override
  String get obV2ValueOpportunityBody =>
      'Find the money still sitting in the numbers you already have.';
  @override
  String get obV2ValueRiskTitle => 'Warn about risk';
  @override
  String get obV2ValueRiskBody =>
      'Tell you before stock runs out, customers go quiet or cash gets tight.';
  @override
  String get obV2ValueActionTitle => 'Suggest what to do';
  @override
  String get obV2ValueActionBody =>
      'Every finding comes with something you can act on right away.';
  @override
  String profileBusinessType(String code) => switch (code) {
    'goods' => 'Selling goods (buy, stock, ship)',
    'digital' => 'Digital products, courses, software',
    'service' => 'Services',
    'mixed' => 'Both goods and services',
    'preparing' => 'Getting ready to start',
    _ => 'Something else',
  };
  @override
  String get obV2DataTitle => 'Tổng Tài needs to understand your business';
  @override
  String get obV2DataBody => 'Pick how you want to start.';
  @override
  String get obV2DataCsvTitle => 'Import an Excel / CSV file';
  @override
  String get obV2DataCsvBody =>
      'Products, orders and customers from a file you already have';
  @override
  String get obV2DataSampleTitle => 'Use sample data';
  @override
  String get obV2DataSampleBody =>
      'A 12-month business so you can see what Tổng Tài does';
  @override
  String get obV2DataNoneTitle => 'No data yet';
  @override
  String get obV2DataNoneBody => 'Start from the business idea';
  @override
  String get obV2DataConnectorsLater =>
      'Connecting directly to marketplaces comes in a later release.';
  @override
  String get obV2AnalysisTitle => 'Tổng Tài is reading your business';
  @override
  String get obV2AnalysisBody =>
      'Running on your device. Nothing is sent anywhere.';
  @override
  String obV2AnalysisStage(String stageCode, int count) => switch (stageCode) {
    'products' => 'Read $count products',
    'orders' => 'Analysed $count orders',
    'customers' => 'Recognised $count customers',
    'stock' => 'Checked stock, $count items need attention',
    _ => 'Found $count things worth knowing',
  };
  @override
  String get obV2InsightTitle => 'I understand your business now';
  @override
  String get obV2InsightBody => 'Here is what matters most right now.';
  @override
  String get obV2InsightQuietTitle => 'I looked — nothing urgent';
  @override
  String get obV2InsightQuietBody =>
      'Every rule ran over your data and found nothing that needs doing today. '
      'I will tell you when that changes.';
  @override
  String get obV2InsightInsufficientTitle => 'I have nothing to look at yet';
  @override
  String get obV2InsightInsufficientBody =>
      'Not enough data to conclude anything. This is not "all clear" — I have '
      'not seen anything at all.';
  @override
  String get obV2SnapshotRevenue => 'Revenue';
  @override
  String get obV2SnapshotProfit => 'Profit';
  @override
  String get obV2SnapshotOrders => 'Confirmed orders';
  @override
  String get obV2SnapshotInventory => 'Stock capital';
  @override
  String get obV2ProfitUnknown => 'Cannot compute yet';
  @override
  String get obV2GoalTitle => 'Which goal should Tổng Tài help with first?';
  @override
  String get obV2GoalBody => 'Pick the 1–2 that matter most right now.';
  @override
  String get obV2GoalLimit => 'Pick at most 2 goals';
  @override
  String obV2Goal(String code) => switch (code) {
    'grow_revenue' => 'Grow revenue',
    'grow_profit' => 'Grow profit',
    'find_products' => 'Find new products',
    'optimize_inventory' => 'Optimise inventory',
    'better_sourcing' => 'Find better suppliers',
    'keep_customers' => 'Keep customers coming back',
    'new_market' => 'Sell into a new market',
    _ => 'Just explore for now',
  };
  @override
  String get obV2PlanTitle => 'Your first plan';
  @override
  String get obV2PlanBody =>
      'Work top down. Each item opens where the work happens.';
  @override
  String get obV2PlanEvidence => 'Why';
  @override
  String get obV2PlanCta => 'Start running the business with Tổng Tài';
  @override
  String get obV2Continue => 'Continue';
  @override
  String get obV2SkipProfile => 'Skip, I will fill this in later';
  @override
  String get startupBrandOwner => 'Workizen';
  @override
  String get startupPlatform => 'AI Platform';
  @override
  String get startupBrand => 'Tổng Tài AI';
  @override
  String get startupTagline => 'The AI assistant that runs your business';
  @override
  String get startupWorking => 'Tổng Tài is starting…';
  @override
  String startupStep(String stepCode, int? count) => switch (stepCode) {
    'database' => 'Opened the database',
    'profile' => 'Read the business profile',
    'catalog' => 'Read ${count ?? 0} products',
    _ => 'Read ${count ?? 0} orders',
  };
  @override
  String get startupPrivacy => 'Your data stays on this device';
  @override
  String get obV2MascotGreeting => 'Tổng Tài is greeting you';
  @override
  String get obV2MascotWorking => 'Tổng Tài is reading your data';
  @override
  String get obV2MascotExplaining => 'Tổng Tài is presenting what it found';
  @override
  String get obV2MascotPlanning => 'Tổng Tài is proposing what to do';
  @override
  String get obV2MascotCalm => 'Tổng Tài looked and found nothing urgent';
  @override
  String get obV2MascotIdle => 'Tổng Tài has no data to look at yet';
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
  String get producerSavedSuppliers => 'Saved suppliers';
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
  String get supRatings => 'Ratings';
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
  String invProductCount(int count) =>
      count == 1 ? '1 product' : '$count products';

  @override
  String get titleWeeklyReview => 'Weekly review';
  @override
  String get weeklyReviewSubtitle => 'How last week went, what to do next';
  @override
  String get weeklyReviewRange => 'Week';
  @override
  String get weeklyReviewRevenue => 'Revenue';
  @override
  String get weeklyReviewOrders => 'Orders';
  @override
  String get weeklyReviewCustomers => 'Customers';
  @override
  String get weeklyReviewAov => 'Average per order';
  @override
  String get weeklyReviewVsPrevious => 'vs last week';
  @override
  String get weeklyReviewNoPrevious => 'No previous week to compare';
  @override
  String get weeklyReviewTopProduct => 'Best seller this week';
  @override
  String get weeklyReviewNothingSold => 'Nothing sold last week';
  @override
  String get weeklyReviewNothingSoldBody =>
      'This is a real number, not a read error. Check stock and customers who '
      'have not come back, to prepare for next week.';
  @override
  String get weeklyReviewHistory => 'Last four weeks';
  @override
  String get weeklyReviewInsufficient => 'Not enough data to review';
  @override
  String get weeklyReviewInsufficientBody =>
      'At least one completed week with orders is needed. Record orders this '
      'week and the first review appears on Monday morning.';
  @override
  String get weeklyReviewWhy => 'Why';

  @override
  String get estimateDisclaimer =>
      'These are estimates calculated from your own sales data — not a '
      'promise. The final call is yours.';
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
  String get briefFailedTitle => "Could not build today's work";
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
  String get titleConnections => 'Connections';
  @override
  String get connectionsIntro =>
      'Tổng Tài uses your own accounts on these platforms. Your data stays on '
      'this device; connection keys are kept separately and never travel in a '
      'backup file.';
  @override
  String get connectorGoogle => 'Google';
  @override
  String get connectorTelegram => 'Telegram';
  @override
  String get connectorAtlassian => 'Jira & Confluence';
  @override
  String get connectionSetupRequired => 'Not set up yet';
  @override
  String get connectionActive => 'Connected';
  @override
  String get connectionPaused => 'Paused';
  @override
  String get connectionError => 'Needs reconnecting';
  @override
  String get connectionConnect => 'Connect';
  @override
  String get connectionDisconnect => 'Disconnect';
  @override
  String get connectionDisconnectConfirm =>
      'Disconnecting removes the key from this device. Your business data is '
      'untouched.';
  @override
  String get connectionNotConfigured =>
      'This build has no Google app key yet, so signing in is not possible. '
      'Everything else is ready.';
  @override
  String get driveBackupTitle => 'Back up to Google Drive';
  @override
  String get driveBackupHint =>
      'Tổng Tài can only see the files it creates itself in your Drive.';
  @override
  String get driveBackupNow => 'Back up now';
  @override
  String get driveBackupRunning => 'Backing up…';
  @override
  String driveBackupDone(String time) => 'Saved to Google Drive at $time';
  @override
  String get driveBackupList => 'Backups on Drive';
  @override
  String get driveBackupEmpty => 'No backups on Drive yet.';
  @override
  String get driveBackupRestore => 'Restore from this one';
  @override
  String get capabilityDriveBackup => 'Back up to Drive';
  @override
  String get capabilityTelegramMessaging => 'Message customers on Telegram';
  @override
  String get capabilityJiraWork => 'Read work items in Jira';
  @override
  String get capabilityConfluenceKnowledge => 'Read Confluence pages';
  @override
  String get actLabelBackupUpload => 'Back up your data';
  @override
  String get actLabelOwnerNotify => 'Notify you';

  @override
  String get titleImport => 'Import shop data';
  @override
  String get importIntro =>
      'Tổng Tài reads your file right on this device. You see what is in it '
      'before deciding to import.';
  @override
  String get importPickFile => 'Choose my Excel file';
  @override
  String importReadyProducts(int count) => '$count products ready';
  @override
  String importReadyVariants(int count) => '$count variants';
  @override
  String importReadySuppliers(int count) => '$count supplier quotes';
  @override
  String importReadyOrders(int count) => '$count orders';
  @override
  String importReadyCustomers(int count) => '$count customers';
  @override
  String importBlocked(int count) =>
      '$count rows need a look — will be skipped';
  @override
  String importWarned(int count) =>
      '$count rows have warnings — still importable';
  @override
  String get importConfirm => 'Import into my shop';
  @override
  String get importRunning => 'Importing…';
  @override
  String importDone(int count) => 'Imported $count products into your shop.';

  @override
  String get importMapTitle => 'Which marketplace is this file from?';
  @override
  String get importMapIntro =>
      'This file was not recognised. Point out which column is which — you '
      'will not have to do it again.';
  @override
  String get importMapVendor => 'Marketplace';
  @override
  String get importMapKind => 'File type';
  @override
  String get importMapKindOrders => 'Order file';
  @override
  String get importMapKindIncome => 'Income report';
  @override
  String get importMapUnset => 'Not set';
  @override
  String get importMapSave => 'Save and read again';
  @override
  String importMapMissing(String roles) => 'Still missing: $roles';
  @override
  String importMapField(String field) => switch (field) {
    'orderId' => 'Order number',
    'orderDate' => 'Order date',
    'status' => 'Status',
    'sku' => 'SKU',
    'productName' => 'Product name',
    'quantity' => 'Quantity',
    'unitPrice' => 'Unit price',
    'buyerName' => 'Buyer name',
    'buyerId' => 'Buyer id',
    'commission' => 'Marketplace commission',
    'transactionFee' => 'Payment fee',
    'serviceFee' => 'Service fee',
    'shippingFee' => 'Shipping fee',
    'voucher' => 'Seller-funded voucher',
    'platformVoucher' => 'Platform-funded voucher',
    'payout' => 'Amount received',
    // See the Vietnamese twin.
    _ => field,
  };
  @override
  String get importNothing => 'Nothing to import from this file.';
  @override
  String get importHistory => 'Imported before';
  @override
  String get importReset => 'Undo this import';
  @override
  String get importResetConfirm =>
      'Removes only what this import brought in. Anything you entered stays.';
  @override
  String importResetDone(int count) => 'Removed $count records.';
  @override
  String importIssueLocation(String sheet, int row) => '$sheet · row $row';
  @override
  String importMoreIssues(int count) => '… and $count more rows';
  @override
  String importRecordCount(int count) => '$count records';
  @override
  String get sourcesCommerce => 'Where orders come from';
  @override
  String get sourcesSourcing => 'Where stock comes from';
  @override
  String get sourcesMessaging => 'Where customers message';
  @override
  String get sourcesLogistics => 'Shipping';
  @override
  String get sourcesFinance => 'Money in';
  @override
  String get sourcesStartDemo => 'Start the demo business';
  @override
  String sourcesDemoLive(int count) =>
      '$count platforms are emitting data in the simulation. '
      'Nothing is really connected — no byte leaves this device.';
  @override
  String get sourcesHonestNote =>
      'This list states the real current status. A source that is not '
      'connected says so — sample data is never presented as marketplace data.';
  @override
  String get readinessConnected => 'In use';
  @override
  String get readinessFileBridge => 'Via file import';
  @override
  String get readinessDemo => 'Sample data only';
  @override
  String get readinessDemoConnected => 'Demo — live';
  @override
  String get readinessResearched => 'Researched';
  @override
  String get readinessPartnerRequired => 'Awaiting marketplace approval';
  @override
  String get readinessApiFuture => 'Later';

  @override
  String get titleBusinessLife => 'Your business';
  @override
  String get demoStart => 'Start the demo business';
  @override
  String get demoNextEvent => 'Next event';
  @override
  String get demoNextDay => 'Next day';
  @override
  String get demoNextWeek => 'Next week';
  @override
  String get demoReset => 'Start over';
  @override
  String orderRemoveLine(String product) => 'Remove $product from the order';

  @override
  @override
  String get splashOwner => 'Workizen';
  @override
  String get splashProduct => 'Customer Relationship Management';
  @override
  String get splashPlatform => 'AI Platform';
  @override
  String get splashLoading => 'Loading AI Power…';
  @override
  String get splashTagline => 'Making every relationship smarter';

  @override
  String demoDayOf(int day, int total) => 'Day $day / $total';
  @override
  String get demoNeedsCatalogue =>
      'You need a product catalogue first. Go to Import shop data and use the '
      'sample dataset.';
  @override
  String get demoFinished => 'The 30 days are done. Start over for a new run.';
  @override
  String get demoNotStarted => 'The demo business has not started.';
  @override
  String demoAdvanced(int count) => 'Advanced through $count new events';
  @override
  String get actorPlatform => 'Marketplace';
  @override
  String get actorAgent => 'Tổng Tài';
  @override
  String get actorSeller => 'You';

  @override
  String get titleConversations => 'Customer conversations';
  @override
  String get conversationsEmpty =>
      'No conversations yet. Start the demo business from Your business so '
      'customers begin messaging.';
  @override
  String get conversationAwaiting => 'Customer waiting';
  @override
  String get conversationDraftReady => 'Draft ready';
  @override
  String get conversationNeedsApproval => 'Needs your approval';
  @override
  String get conversationDraftLabel => 'Drafted by Tổng Tài — not sent';
  @override
  String get conversationSend => 'Send';
  @override
  String get conversationEdit => 'Edit';
  @override
  String get conversationSent => 'Sent (simulated — nothing left this device)';
  @override
  String get conversationSendFailed => 'Could not send. Try again.';
  @override
  String get conversationYouSent => 'You sent';
  @override
  String get customer360Story => 'Customer story';
  @override
  String customer360FirstTouch(String channel, String date) =>
      'Found the shop via $channel · $date';
  @override
  String get customer360Suggestions => 'Suggest to this customer';
  @override
  String customer360BoughtTogether(int count) =>
      '$count other customers bought it together';
  @override
  String get customer360OpenConversation => 'Open conversation';

  @override
  String get telegramTitle => 'Get your brief on Telegram';
  @override
  String get telegramHint =>
      'Tổng Tài will send you the morning brief. A Telegram bot cannot message '
      'anyone first, so you need to open a chat with it once — and for the same '
      'reason it cannot message your customers.';
  @override
  String get telegramTokenLabel => 'Bot token';
  @override
  String get telegramTokenHint =>
      'Message @BotFather on Telegram to create a bot.';
  @override
  String get telegramSaveToken => 'Save token';
  @override
  String get telegramTokenBad =>
      'Telegram rejected this token. Check the string BotFather gave you.';
  @override
  String telegramBotFound(String username) => 'Connected to $username';
  @override
  String get telegramStartHint =>
      'Open Telegram, send /start to the bot, then tap Find chats.';
  @override
  String get telegramFindChats => 'Find chats';
  @override
  String get telegramNoChats =>
      'No one has messaged the bot yet. Send /start and try again.';
  @override
  String get telegramSendTest => 'Send a test message';
  @override
  String get telegramTestSent => 'Sent. Check Telegram.';

  @override
  String get atlassianTitle => 'Work in Jira & Confluence';
  @override
  String get atlassianHint =>
      'Tổng Tài only reads, and only the project you pick. Not a Jira '
      'replacement — just an answer to "how is the work going".';
  @override
  String get atlassianUrlLabel => 'Atlassian address';
  @override
  String get atlassianUrlHint => 'https://your-name.atlassian.net';
  @override
  String get atlassianEmailLabel => 'Account email';
  @override
  String get atlassianTokenLabel => 'API token';
  @override
  String get atlassianTokenHint =>
      'Create one at id.atlassian.com → Security → API tokens.';
  @override
  String get atlassianSave => 'Check and save';
  @override
  String get atlassianBad =>
      'Atlassian rejected these details. Check the address, email and token.';
  @override
  String get atlassianPickProject => 'Pick a project';
  @override
  String get atlassianPickSpace => 'Pick a documentation space';
  @override
  String get atlassianNoProjects => 'No projects found for this account.';
  @override
  String get atlassianNoData => 'Not enough data to say how the work is going.';

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
