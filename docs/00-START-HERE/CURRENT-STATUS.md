# Current Status — 2026-07-25

## Where we are

- **Phase 1 (Product Design Bible):** ✅ DONE + Founder-approved. 60 docs.
- **Phase 2 (build):** 🔄 IN PROGRESS — developed autonomously by the
  Evidence-Driven Runtime. `flutter analyze` clean; **~966 tests passing (P0 §1 suites added)**.
- **This repo:** split from the Hub on 2026-07-22 (`split-baseline` tag);
  app runs standalone.
- **Data Foundation — persistence arc COMPLETE for user-authored capabilities**
  (Founder Post-P0 "Data Foundation before AI"): Finance (WTM-120), Inventory
  (WTM-121), Consumer (WTM-123) and Journey (WTM-124) all persist to Drift via
  the approved **Repository + structured-columns + versioned domain-snapshot**
  pattern (ADR-TON-008/009), **User Data First** (real DB starts empty; sample =
  Demo only). Readiness dashboard: `docs/02-ARCHITECTURE/PERSISTENCE-INVENTORY.md`
  (Capability Persistence Matrix). The shared corrupt-tolerant codec
  `lib/features/tongtai/core/domain_snapshot.dart` backs all four.
- **Business Data Foundation — metrics → context → dashboard chain COMPLETE**
  (Founder G-1/2/3 → ADR-TON-010/011/012): Orders as an independent capability
  (WTM-125/126), `BusinessMetricsService` = KPI single source of truth
  (WTM-127), Home = User Data First (WTM-128), and the `BusinessContext`
  **Aggregate Root** via **Progressive Aggregation** — Phase 1 metrics/Customers/
  Orders/Inventory/Opportunity (WTM-129/130/131), versioned Business Snapshot +
  `BusinessHealth` model (WTM-132), **Phase 2 Journey + Finance slices
  (WTM-133)**, **Phase 3 Timeline projection (WTM-134)** — the **non-AI Business
  Snapshot is now complete**. AI reads **only** BusinessContext, never a repository.
- **⭐ P0 Regression Audit (Founder 2026-07-30, ĐANG CHẠY):** §1 XONG — **ADR-TON-014 sample-seeding**: demo song song bị loại; "Xem thử Demo" seed `sample-` vào repos THẬT; Export/Chat-AI/Timeline hết đọc fixture (bug thật đã fix + regression-lock); `test/features/tongtai/p0/` (lifecycle · consistency · e2e · acceptance). §2 XONG (WTM-145, 2 PR) — **một locale active, mọi UI string qua key**: quét sạch label song ngữ " · " và " | " + migrate TOÀN BỘ chuỗi user-facing trong `lib/features/tongtai/ui/` (19 màn, ~150 key VI/EN + method có tham số); UI cấm đọc `labelVi/labelEn` trực tiếp — luôn `label(context.l10n.languageCode)`; đổi ngôn ngữ runtime update toàn app + persist; 7 lock test trong `test/features/tongtai/p0/localization_test.dart` (scan " · "/" | "/chuỗi-VN-trong-ui/labelVi-labelEn + unused-key + vi≠en + switch-persist). Ranh giới: domain-generated content (rule summary, timeline event title, sample fixtures) là DATA — giữ tiếng Việt theo thiết kế. §3-6 đang tiếp.
- **Founder-gate blocking the next tier**: Workizen AI activation (BYOK/router,
  privacy red-line — **G-3, deferred**; Founder sequenced the full Business Data
  Foundation first). AI Phase-2 (Opportunity Win Probability / Recommendation /
  Summary, `BusinessHealth` AI assessor) all read the same BusinessContext.

## Shipped stories (all at Jira "Code Review", code on this repo's main)

| Area | Stories |
|---|---|
| Data | WTM-51 schema (17 tables) · 52 migrations · 53 relationships · 54 sync-queue outbox |
| Shell/Nav | WTM-55 bottom nav · 56 tab persistence · 57 deep links · 59 onboarding (6 màn) |
| Identity/Core | WTM-58 UUID identity · 60 core utils (formatters/enums) · 62 design tokens+showcase |
| Producer | WTM-63 supplier search · 64 supplier detail · 65 favorites |
| Inventory | WTM-68 product list · 69 add/edit product · 70 stock alerts · WTM-121 **Drift persistence (ADR-TON-009)**: `ProductCatalogController → ProductRepository → Drift` (schema v5 + `products.domain_snapshot`); app thật bắt đầu RỖNG, sản phẩm user persist (imagePaths trong versioned snapshot); sample = Demo Mode |
| Search | WTM-72 FTS5 (đ-aware) · 73 unified search · 74 ranking + A/B |
| Consumer | WTM-75 customer list · 76 add/edit customer (form, multi-address, audit trail, duplicate check) · 77 purchase history (orders, filters, AOV/repurchase) · WTM-123 **Drift persistence (ADR-TON-009)**: `CustomerDirectoryController → CustomerRepository → Drift` (schema v6 + `customers.domain_snapshot`); structured cols for name/phone/city/email/orders/spend + `segments` JSON col; addresses/tags/notes in snapshot; app thật RỖNG, sample = Demo |
| AI | WTM-61 xAI Grok BYOK client + key screen · **WTM-83 (Founder-approved 2026-07-29)**: **key rotation an toàn** — `TongtaiAiService.rotateKey` validate→ghi→live-test→**rollback về khóa cũ nếu key mới chết** (không bao giờ brick setup đang chạy; nút "Đổi khóa" trên key screen) + **quét QR** nhập key (`mobile_scanner`, dep đã duyệt; `TongtaiKeyScanScreen` on-device, key quét CHỈ điền vào ô — vẫn qua đúng validate/save path; seam `scanLauncher` cho test; iOS NSCameraUsageDescription) · **WTM-116 G-3A AI Business Summary (ADR-TON-013)**: `BusinessSummaryService` — AI **chỉ thấy** `businessContextPromptText(BusinessContext)` (test chứng minh boundary), BYOK/Local theo preference chain, twin rule-based khi AI off/offline, business rỗng KHÔNG tốn provider call; card on-demand trên Reports + provenance chip (provider vs Rule-based). Read-only: không mutate/workflow/action · **WTM-135 G-3B AI Recommendation**: `BusinessAiEngine` (runner chung ADR-TON-013: load context → guard → serialize → provider chain → rule fallback; Summary delegate) + `BusinessRecommendationService` — gợi ý hành động CHỈ để chủ shop tự quyết (không mutate/execute/side-effect), twin `ruleBasedBusinessRecommendations` từ tín hiệu snapshot; nút "Gợi ý hành động" cùng card AI trên Reports · **WTM-136 G-3C AI Planner**: `BusinessPlanService` — kế hoạch tuần đánh số ưu tiên (chặn lỗ trước: hết hàng → đơn mở → goal chậm → cơ hội → khách cũ) + KPI theo dõi, twin `ruleBasedBusinessPlan`; **không bước nào tự chạy**; nút "Kế hoạch tuần" cùng card · **WTM-137 G-3D BusinessHealth AI**: `BusinessHealthAiService` — **assessment only**, `ruleHealth` luôn = health rule-based từ snapshot (test chứng minh AI "nói xấu" cũng KHÔNG đổi được status); nút "Sức khỏe" cùng card. → **G-3A→G-3D staged AI activation HOÀN TẤT (ADR-TON-013)** |
| Chat | WTM-80 chat UI · 81 persistence SQLite v4 (local-only ADR-TON-004) · 82 Workizen AI Router (đa provider, context injection, fallback offline — ADR-TON-006) · WTM-84 **search & history**: nút search → tìm theo nội dung (đ-aware, dùng `ChatMessageStore.search` sẵn có) + lọc kỳ (Tất cả/Hôm nay/7 ngày), kết quả nhóm theo ngày + highlight từ khóa |
| Journey | WTM-87 business goals (templates + multi-step form + progress/pace + khuyến nghị) · WTM-88 goal detail: bấm goal mở chi tiết — tiến độ/pace/còn lại, **kế hoạch hành động** rule-based theo loại + pace, gợi ý (guidance), nút Sửa → form (AI plan thật kế thừa seam này sau) · WTM-124 **Drift persistence (ADR-TON-009, divergent-schema)**: `BusinessGoalController → BusinessGoalRepository → Drift` (schema v7 + `journeys.domain_snapshot`); promoted cols goal/revenueImpact/startedAt + derived status/progress/timeline; type/achieved/growth/endDate/notes trong snapshot; app thật RỖNG, sample = Demo · **WTM-89 Progress Tracking**: `JourneyProgressService` (thuần) tính **doanh thu thực tế trong kỳ mục tiêu** từ đơn hàng billable (User Data First); goal detail thêm card "Doanh thu thực tế" (additive — KHÔNG đụng progress/edit thủ công). **WTM-138 auto-derive (Founder default ADR-TON-013)**: progress goal doanh thu **tự suy từ đơn thật** (`deriveGoalProgress`, list/detail/JourneySummary đều dùng); form ẩn field nhập tay doanh thu (note "tự tính từ đơn"), KPI không suy được (growth) vẫn nhập tay; KHÔNG migrate dữ liệu |
| Opportunity | **WTM-139 Rule Engine (Founder default ADR-TON-013)**: `OpportunityRuleEngine.generate` — cơ hội THẬT từ dữ liệu (Restock hết/sắp-hết-hàng-có-bán · Win-back khách quen im lặng >30d · Goal catch-up theo gap · Category momentum); deterministic id `gen-*`, business rỗng → 0 cơ hội; wired vào `OpportunityContextProvider` (BusinessContext slice thật) + Reports pipeline real-mode + **WTM-140 feed real-mode** (feed load cơ hội generated; business rỗng → empty state; sample chỉ còn demo/tests) + **WTM-141 AI layer**: `OpportunityAiService.explain` — đánh giá/giải thích + `ĐIỂM: NN` parse (clamp 0-100, null nếu không parse được); input = snapshot + opportunity block (không đụng repo); **điểm rule vẫn authoritative**, AI chỉ annotation; nút "Đánh giá AI" trên detail; twin rule-based. → **Chuỗi Founder default Rule Engine → Opportunity → AI Scoring/Ranking/Explanation HOÀN TẤT** · **WTM-94 Opportunity Action**: nút "Tạo mục tiêu từ cơ hội" trên detail — 1 chạm tạo Journey goal (id idempotent `goal-from-<oppId>`, target = expectedImpact, 45 ngày, notes ghi nguồn cơ hội). AI chỉ layer scoring/ranking/explanation lên trên (chưa làm). · WTM-91 feed (type filter, sort relevance/recency/ROI, bookmark + saved view, swipe interested/dismiss + undo) · WTM-92 detail: bấm card mở chi tiết — điểm AI, ROI/tác động, lý do, **kế hoạch hành động** rule-based theo loại, nút quan tâm/bỏ qua/lưu đồng bộ về feed (AI scoring chờ WTM-93) |
| Timeline | WTM-114 Business Timeline (event-driven): `BusinessEvent` + `BusinessEventSource` (finance/order/opportunity/journey adapters) → `TimelineService` merge+sort desc, group-by-day; screen lọc theo loại, icon/màu theo domain, empty-state; modules EMIT events (timeline không query module) — mở từ More → Business |
| Home | WTM-14 dashboard front-door đọc data thật: đếm module, KPI doanh thu năm/đơn/AOV, Top cơ hội, mission = mục tiêu + tiến độ · WTM-128 **Home = User Data First** (G-1): KPI từ `BusinessMetrics` (0 hợp lệ, không "No Data"), `BusinessHealth` badge, onboarding CTAs (customer→product→order→goal→Demo), Demo Mode = hành động chủ động (không preload sample); giờ consume `BusinessContext` (WTM-129/132) · **WTM-143 nhãn Demo**: màn demo TỰ XƯNG — title "Demo — Dữ liệu mẫu" + banner cảnh báo (`home-demo-banner`); Home thật không bao giờ hiện nhãn (test 2 chiều). Bắt nguồn: Founder nhầm demo là dashboard thật · **WTM-144 quick actions**: business CÓ data vẫn giữ lối tắt trên Home (`home-quick-customer/product/order/goal` ActionChips) + **"Xem thử Demo" cố định trong More** (`more-demo-mode`) — field feedback: Founder tưởng mất chức năng khi Get-started tự ẩn sau bản ghi đầu tiên |
| Reports | WTM-95/96 dashboard: KPI doanh thu MTD/YTD + số đơn + AOV, biểu đồ doanh thu 6 tháng (CustomPaint, không thêm lib), top categories · WTM-97 **Top sản phẩm** (doanh thu + số bán) + **Top khách hàng** (chi tiêu + số đơn, tên resolve từ customer directory) · WTM-98 **Pipeline cơ hội** (số đang mở + tổng giá trị kỳ vọng + cơ hội điểm cao nhất, `opportunityPipeline` thuần); headline KPI giờ đọc từ `BusinessMetricsService` (WTM-127) · **WTM-115 lọc theo kỳ**: `ReportPeriod` (Tháng/Quý/Năm/Tất cả) + `PeriodBreakdown` — selector scope các breakdown (categories/products/customers) theo kỳ; **4 KPI card giữ nguyên all-business** (không đụng KPI-SoT, ADR-TON-011); mở từ More → Business |
| Orders | WTM-125 **capability độc lập** tách khỏi `consumer/` + `OrderRepository`/Controller + Drift (ADR-TON-010) · WTM-126 **Create Order**: line PHẢI reference Inventory Product (Inventory Picker); `OrderItem` = snapshot bất biến productId/name/sku/unit/qty/**soldPrice** (override được; order lịch sử KHÔNG đổi khi giá kho đổi); model chừa chỗ Invoice/Payment/Shipment/Return |
| Metrics / BusinessContext | WTM-127 **`BusinessMetricsService` = KPI SoT** (revenue·orders·customers·AOV; Reports/Home reuse, không recompute — ADR-TON-011) · WTM-129/131 **`BusinessContext` = Aggregate Root** — one Context Provider per capability, `BusinessContextService` composes (ADR-TON-012) · WTM-130 Opportunity Phase-1 rule-based signals (AI-off/offline) · WTM-132 versioned Business Snapshot + `BusinessHealth` model · WTM-133 Phase 2: Journey + Finance slices · **WTM-134 Phase 3: Timeline projection (activity-stream, live repos, loại khỏi `hasData`)** → **snapshot phi-AI HOÀN CHỈNH**. **AI reads ONLY BusinessContext**, never repos |
| Finance | WTM-27 dashboard (KPI thu/chi/lợi nhuận/biên, biểu đồ dòng tiền, chi phí theo nhóm, feed) · WTM-113 nhập giao dịch (FAB → form) · WTM-120 **Drift persistence (ADR-TON-008, User Data First)**: `FinanceController → FinanceRepository → Drift`; app thật **bắt đầu RỖNG**, entry user persist qua `TransactionsTable` (scoped `LocalWorkspace` business); sample = Demo Mode (`SampleFinanceRepository`), không ghi vào DB thật. Mở từ More → Business |
| Backup | WTM-99 CSV export (customers/products/orders, UTF-8 BOM, date range, share/email, history — D-10 Phase 2) · **WTM-100 mã hoá backup (Founder-approved 2026-07-29)**: `BackupCrypto` — AES-256-GCM + PBKDF2 (150k, iteration count nhúng trong container `TONGTAI-BACKUP-V1:` armored base64), toggle "Mã hoá bằng mật khẩu" + passphrase ≥6 ký tự trên Export screen → file `.ttbk` qua CÙNG delivery seam; passphrase không rời máy/không lưu; dep mới `cryptography` (pure Dart) |
| Brand | WTM-109 Business Fox mascot (Origami all) · 110 app icon + splash native · 111 mascot trong app (avatar chat, empty states) + đổi nhãn hiển thị "Workizen AI" |
| i18n | WTM-119 **localization foundation** (ADR-TON-007, mirror Hub — KHÔNG ARB): `AppStrings` (VI/EN) + `LanguageNotifier` (persist 'wz.locale') + `context.l10n`; `MaterialApp` wired locale + delegates; picker ở More → Ngôn ngữ đổi ngôn ngữ runtime. Migrate chuỗi UI dần Boy-Scout |
| Telemetry | **WTM-108 (D-7/ADR-TON-005, Founder-approved)**: seam `TongtaiTelemetry` (Noop mặc định · Firebase Analytics+Crashlytics khi Founder cấp config) — gradle apply Google Services CHỈ khi có `google-services.json` (build không vỡ khi thiếu); `initTongtaiTelemetry()` không bao giờ throw; event catalogue v1 (`app_open`/`screen_view`/`flow_error`) tại `docs/05-OPERATIONS/TELEMETRY-EVENTS.md`; config thật bị chặn commit qua `.gitignore`; CẤM ad/marketing/profiling |
| Fixes | WTM-105 wire `TongtaiRootGate` vào `main.dart` (onboarding lần đầu) + ADR-TON-003 |

## NOT built yet (honest gaps)

- Finance dashboard built (WTM-27, read-only over the sample ledger); a
  **transaction entry form** + Drift-backed ledger are still open. Journey:
  goals UI (87) + goal detail & rule-based plan (88); **AI-generated** plan
  còn chờ (WTM-88 seam để sẵn). Opportunity: feed (91) + detail & rule-based
  plan (92); **AI scoring** chờ WTM-93. Chat: đủ UI + persistence + Workizen
  AI Router (80/81/82); Claude adapter + per-provider key UX = follow-up
  (WTM-83).
- Backlog còn lại (WTM-78/79, 84–86, 88–90, 92–94, 97–98, 102, 108) trong Jira
  với AC đầy đủ.
- App icon/splash = Origami Business Fox trên nền navy (WTM-110, native qua
  flutter_launcher_icons + flutter_native_splash).
- iOS build unverified in-session (signing/SPM); Android debug build is the
  verified path. See [../migration/KNOWN-GAPS.md](../migration/KNOWN-GAPS.md).

## Next approved work

Run remaining Phase-2 backlog (Sprint 3+) via the Evidence-Driven Runtime —
same gates. Founder reviews/merges PRs into `main` of THIS repo now (the old
"merge feat/tongtai into Hub main" plan is obsolete — replaced by this split).

Pre-Beta gate: [RELEASE-READINESS-CHECKLIST.md](RELEASE-READINESS-CHECKLIST.md)
(WTM-118) — top gaps: accessibility, localization (WTM-119), privacy policy +
telemetry disclosure (WTM-37), iOS build + release signing (Founder).

## History

Batch reports: [../04-DELIVERY/reports/](../04-DELIVERY/reports/) —
pilot (5 stories) → batch-01 (8, incl. the placebo-catch) → WTM-57 self-heal →
batch-02 (7 + WTM-69 network false-negative, later PASS). Pre-split git history:
Hub repo `feat/tongtai`.
