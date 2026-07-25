# Current Status — 2026-07-25

## Where we are

- **Phase 1 (Product Design Bible):** ✅ DONE + Founder-approved. 60 docs.
- **Phase 2 (build):** 🔄 IN PROGRESS — developed autonomously by the
  Evidence-Driven Runtime. `flutter analyze` clean; **828/828 tests passing**.
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
- **Founder-gates blocking the next tier** (see OPEN-DECISIONS "Còn mở"): Orders
  entry UX · Home demo-vs-User-Data-First · Workizen AI activation (BYOK/router,
  privacy red-line). No non-gated persistence migration remains.

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
| AI | WTM-61 xAI Grok BYOK client + key screen |
| Chat | WTM-80 chat UI · 81 persistence SQLite v4 (local-only ADR-TON-004) · 82 Workizen AI Router (đa provider, context injection, fallback offline — ADR-TON-006) · WTM-84 **search & history**: nút search → tìm theo nội dung (đ-aware, dùng `ChatMessageStore.search` sẵn có) + lọc kỳ (Tất cả/Hôm nay/7 ngày), kết quả nhóm theo ngày + highlight từ khóa |
| Journey | WTM-87 business goals (templates + multi-step form + progress/pace + khuyến nghị) · WTM-88 goal detail: bấm goal mở chi tiết — tiến độ/pace/còn lại, **kế hoạch hành động** rule-based theo loại + pace, gợi ý (guidance), nút Sửa → form (AI plan thật kế thừa seam này sau) · WTM-124 **Drift persistence (ADR-TON-009, divergent-schema)**: `BusinessGoalController → BusinessGoalRepository → Drift` (schema v7 + `journeys.domain_snapshot`); promoted cols goal/revenueImpact/startedAt + derived status/progress/timeline; type/achieved/growth/endDate/notes trong snapshot; app thật RỖNG, sample = Demo |
| Opportunity | WTM-91 feed (type filter, sort relevance/recency/ROI, bookmark + saved view, swipe interested/dismiss + undo) · WTM-92 detail: bấm card mở chi tiết — điểm AI, ROI/tác động, lý do, **kế hoạch hành động** rule-based theo loại, nút quan tâm/bỏ qua/lưu đồng bộ về feed (AI scoring chờ WTM-93) |
| Timeline | WTM-114 Business Timeline (event-driven): `BusinessEvent` + `BusinessEventSource` (finance/order/opportunity/journey adapters) → `TimelineService` merge+sort desc, group-by-day; screen lọc theo loại, icon/màu theo domain, empty-state; modules EMIT events (timeline không query module) — mở từ More → Business |
| Home | WTM-14 dashboard front-door đọc data thật: đếm module (Producer/Inventory/Consumer/Journey), KPI doanh thu năm/đơn/AOV (từ `ReportsService`), Top 3 cơ hội theo điểm AI, mission = mục tiêu + tiến độ (thay placeholder "0"/"No … yet") |
| Reports | WTM-95/96 dashboard: KPI doanh thu MTD/YTD + số đơn + AOV, biểu đồ doanh thu 6 tháng (CustomPaint, không thêm lib), top categories · WTM-97 **Top sản phẩm** (doanh thu + số bán) + **Top khách hàng** (chi tiêu + số đơn, tên resolve từ customer directory) · WTM-98 **Pipeline cơ hội** (số đang mở + tổng giá trị kỳ vọng + cơ hội điểm cao nhất, `opportunityPipeline` thuần); nguồn `ReportsService` (sample orders, local-first), mở từ More → Business |
| Finance | WTM-27 dashboard (KPI thu/chi/lợi nhuận/biên, biểu đồ dòng tiền, chi phí theo nhóm, feed) · WTM-113 nhập giao dịch (FAB → form) · WTM-120 **Drift persistence (ADR-TON-008, User Data First)**: `FinanceController → FinanceRepository → Drift`; app thật **bắt đầu RỖNG**, entry user persist qua `TransactionsTable` (scoped `LocalWorkspace` business); sample = Demo Mode (`SampleFinanceRepository`), không ghi vào DB thật. Mở từ More → Business |
| Backup | WTM-99 CSV export (customers/products/orders, UTF-8 BOM, date range, share/email, history — D-10 Phase 2) |
| Brand | WTM-109 Business Fox mascot (Origami all) · 110 app icon + splash native · 111 mascot trong app (avatar chat, empty states) + đổi nhãn hiển thị "Workizen AI" |
| i18n | WTM-119 **localization foundation** (ADR-TON-007, mirror Hub — KHÔNG ARB): `AppStrings` (VI/EN) + `LanguageNotifier` (persist 'wz.locale') + `context.l10n`; `MaterialApp` wired locale + delegates; picker ở More → Ngôn ngữ đổi ngôn ngữ runtime. Migrate chuỗi UI dần Boy-Scout |
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
