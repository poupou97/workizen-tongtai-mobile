# Jira Backlog Audit — 2026-08-01

**Vì sao có file này:** Jira còn **62 issue chưa Done**. Đối chiếu từng cái với
code và docs cho thấy **53 trong số đó đã hoàn thành từ lâu** nhưng chưa ai
đóng. Một bảng kế hoạch sai lệch như vậy nguy hiểm hơn là không có bảng: dùng nó
để lập kế hoạch sẽ dẫn đến làm lại việc đã làm.

Mỗi dòng dưới đây là **một lần kiểm chứng thật** — trỏ vào file trong repo, ADR,
hoặc PR đã merge. Không đóng cái nào bằng phỏng đoán.

**Trạng thái repo lúc audit:** `main` = `ee2f607` · CI xanh · **1418 test** ·
`flutter analyze` sạch · bản release dựng và chạy được trên thiết bị thật.

| Jira | Loại | Việc | Kết luận | Bằng chứng |
|---|---|---|---|---|
| **WTM-1** | Epic | Tổng Tài — Phase 1: Product Design Bible & App Bootstrap | ✅ ĐÓNG | Epic Phase-1: 39 deliverable đã giao — `docs/01-PRODUCT/` (11 doc) · `docs/01-PRODUCT/screens/` (14 spec) · `docs/02-ARCHITECTURE/` · app bootstrap chạy được |
| **WTM-2** | Story | Concept Image Analysis & UI/UX Inventory | ✅ ĐÓNG | `docs/01-PRODUCT/UI-UX-CONCEPT-INVENTORY.md` + `concepts/` |
| **WTM-3** | Story | Core Product Design Bible (7 docs) | ✅ ĐÓNG | `docs/01-PRODUCT/` — PRODUCT-VISION · PRINCIPLES · SCOPE · BUSINESS-JOURNEY-BIBLE · OPPORTUNITY-ENGINE · AI-BUSINESS-COPILOT · USER-JOURNEYS |
| **WTM-4** | Story | Information Architecture & Design System (6 docs) | ✅ ĐÓNG | `docs/02-ARCHITECTURE/design/DESIGN-TOKENS.md` + `DESIGN-SYSTEM-DRAFT.md`; token đã thực thi trong `lib/features/tongtai/navigation/tongtai_design_tokens.dart` |
| **WTM-5** | Story | Screen Specifications (13 screens) | ✅ ĐÓNG | `docs/01-PRODUCT/screens/` — 14 spec (yêu cầu 13) |
| **WTM-6** | Story | Domain Data Model & Business Capability Model (2 docs) | ✅ ĐÓNG | `docs/02-ARCHITECTURE/DOMAIN-MODEL.md` + `CAPABILITY-MAP.md` + `CAPABILITY-BIBLE.md` |
| **WTM-7** | Story | Technical Planning & Fit/Gap Preparation (7 docs) | ✅ ĐÓNG | `docs/02-ARCHITECTURE/` (7 doc kiến trúc) + `docs/03-DECISIONS/ADR-INDEX.md` (19 ADR) |
| **WTM-8** | Story | App Bootstrap — Flutter foundation (structure, routes, shells, theme) | ✅ ĐÓNG | App Flutter chạy được: `lib/main.dart` · `tongtai_app_shell.dart` · 35 màn · theme + routes |
| **WTM-9** | Story | Build & Test Validation | ✅ ĐÓNG | CI GitHub Actions (format+analyze+test) xanh trên `main`; **1418 test** |
| **WTM-10** | Story | Governance & Handoff (Open Decisions, Risks, Roadmap, Phase-1 Report) | ✅ ĐÓNG | `docs/03-DECISIONS/OPEN-DECISIONS.md` · `docs/04-DELIVERY/RISKS-AND-CONSTRAINTS.md` · `ROADMAP.md` · báo cáo Phase-1 |
| **WTM-11** | Story | [SPONSOR DECISION] Tổng Tài product-foundation decisions | ✅ ĐÓNG | Cả 7 quyết định đã chốt: tách repo riêng (ADR-TON-001) · applicationId `com.workizen.tongtai` · shared-core reference-only · thuật ngữ (`TERMINOLOGY.md`) · **không cần tài khoản** (D-4) · mascot (`MASCOT-BUSINESS-FOX.md`) |
| **WTM-12** | Story | Implement Card Component with Domain Color Support | ✅ ĐÓNG | Card + màu theo miền: `tongtai_design_tokens.dart`, dùng khắp 35 màn |
| **WTM-13** | Story | Build Opportunity Scoring Badge & Trend Indicator Component | ✅ ĐÓNG | `tongtai_opportunity_signal_badges.dart` + `_ScoreBadge` trong opportunity detail |
| **WTM-15** | Story | Design Detail Screen Navigation Pattern (Tabs + Hero Section) | ✅ ĐÓNG | Detail screen pattern: supplier/product/customer/goal/opportunity detail đều đã dựng |
| **WTM-16** | Story | Implement AI Copilot Chat Interface & Recommendation Cards | ✅ ĐÓNG | `tongtai_chat_screen.dart` + `lib/features/tongtai/ai/` (BYOK, ADR-TON-013) |
| **WTM-17** | Story | Implement Chart Components (Line, Area, Bar, Pie, Sparkline) | ✅ ĐÓNG | Chart: forecast/reports/timeline dùng CustomPaint + sparkline |
| **WTM-18** | Story | Implement Data Tables (Product List, Transaction List, Supplier List) | ✅ ĐÓNG | Danh sách có phân trang: inventory · customer-list · timeline · finance |
| **WTM-19** | Story | Build Bottom Navigation + Module Tab Navigation Framework | ✅ ĐÓNG | `tongtai_bottom_nav.dart` + `tongtai_app_shell.dart` (IndexedStack 5 tab) |
| **WTM-20** | Story | Design Empty/Loading/Error States Library | ✅ ĐÓNG | **Chính là seam ADR-TON-017**: `ScreenState` 6 trạng thái + `TongtaiScreenData` — 29 màn dùng chung |
| **WTM-21** | Story | Finalize Design System & Design Token Implementation | ✅ ĐÓNG | `tongtai_design_tokens.dart`; WTM-168 bổ sung cặp màu đọc được (WCAG 4.5:1) |
| **WTM-22** | Story | Create Avatar & Customer Profile Components | ✅ ĐÓNG | Avatar + hồ sơ khách: `tongtai_customer_list_screen.dart` · `tongtai_customer_history_screen.dart` |
| **WTM-23** | Story | Design Input & Form Components with Validation | ✅ ĐÓNG | Form + validation: customer/product/goal/transaction form, có `_errors` theo field |
| **WTM-24** | Story | Design Producer (Sourcing) Screen | ✅ ĐÓNG | `tongtai_producer_screen.dart` + `tongtai_supplier_search_screen.dart` |
| **WTM-25** | Story | Design Inventory (Product Management) Screen | ✅ ĐÓNG | `tongtai_inventory_screen.dart` (phân trang, lọc, sắp xếp, cảnh báo tồn) |
| **WTM-26** | Story | Design Consumer (Customer Intelligence) Screen | ✅ ĐÓNG | `tongtai_consumer_screen.dart` + `tongtai_customer_list_screen.dart` |
| **WTM-28** | Story | Design Reports & Analytics | ✅ ĐÓNG | `tongtai_reports_screen.dart` (KPI, breakdown theo kỳ, AI card) |
| **WTM-29** | Story | Design Business Journey (Orchestration) Screen | ✅ ĐÓNG | `tongtai_goals_screen.dart` + `tongtai_goal_detail_screen.dart` (auto-derive WTM-138) |
| **WTM-30** | Story | Design Opportunity Hub | ✅ ĐÓNG | `tongtai_opportunity_feed_screen.dart` + detail + Rule Engine (WTM-139/140/141) |
| **WTM-31** | Story | Design AI Copilot Chat Interface | ✅ ĐÓNG | Trùng WTM-16 — `tongtai_chat_screen.dart` |
| **WTM-32** | Story | Design Detail Screens (Supplier, Product, Customer) | ✅ ĐÓNG | supplier/product/customer detail đều đã dựng |
| **WTM-33** | Story | Design More / Navigation Menu | ✅ ĐÓNG | `tongtai_more_screen.dart`; WTM-169 dọn nút chết + thêm màn Giới thiệu |
| **WTM-34** | Task | Validate Open Decisions & Roadmap | ✅ ĐÓNG | `docs/03-DECISIONS/OPEN-DECISIONS.md` + `ADR-INDEX.md` (19 ADR đã Accepted) |
| **WTM-35** | Task | Create Risk Register & Mitigation Plans | ✅ ĐÓNG | `docs/04-DELIVERY/RISKS-AND-CONSTRAINTS.md` |
| **WTM-36** | Task | Plan Phase 2 Sprints & Team Assignment | ✅ ĐÓNG | Phase 2 đã **thực thi xong** chứ không chỉ lập kế hoạch — 8/8 capability shipped |
| **WTM-38** | Story | SQLite Schema Design & Drift Models | ✅ ĐÓNG | `lib/database/database.dart` — 17 bảng Drift |
| **WTM-39** | Story | Drift Migration V1 (Create Tables) | ✅ ĐÓNG | `lib/database/migrations/` + `buildTongtaiMigrationStrategy` |
| **WTM-40** | Story | Drift Model Validation & Relationships | ✅ ĐÓNG | FK + cascade bật qua `PRAGMA foreign_keys` (`beforeOpen`); test FK trong P0 suite |
| **WTM-41** | Story | Offline-First: Sync Queue & Conflict Resolution | ⏳ GIỮ MỞ | **Tôi đã đóng nhầm cái này rồi mở lại.** Bảng `SyncQueueItemsTable` CÓ trong schema, nhưng đó chỉ là outbox để dành. AC thật (retry backoff · phát hiện + giải quyết xung đột · báo người dùng) **chưa có gì**, và theo D-5 thì Phase 2 **không có backend, không có sync** ⇒ không làm được ở giai đoạn này. Giữ cho Phase 3. |
| **WTM-42** | Story | Bottom Nav Framework | ✅ ĐÓNG | `tongtai_bottom_nav.dart` |
| **WTM-43** | Story | Tab State Persistence | ✅ ĐÓNG | `tongtaiSelectedTabProvider` + SharedPreferences |
| **WTM-44** | Story | Deep Linking Support | ✅ ĐÓNG | `lib/features/tongtai/navigation/deeplink/` + xử lý link hỏng (WTM-57) |
| **WTM-45** | Story | Local User Identity (UUID) | ✅ ĐÓNG | `tongtai_identity_provider.dart` (UUID cục bộ, không tài khoản — D-4) |
| **WTM-46** | Story | Onboarding Flow (Tutorial) | ✅ ĐÓNG | `tongtai_onboarding_screen.dart` + `TongtaiRootGate` |
| **WTM-47** | Story | Shared Core Package Integration | ✅ ĐÓNG | ADR-TON-001: shared-core là **reference-only**, không nhúng — quyết định đã chốt |
| **WTM-48** | Story | AI Client Setup (xAI Grok) | ✅ ĐÓNG | `lib/features/tongtai/ai/tongtai_ai_client.dart` (BYOK, đa provider) |
| **WTM-49** | Story | Component Library Integration | ✅ ĐÓNG | Component library nội bộ: `lib/features/tongtai/ui/widgets/` |
| **WTM-50** | Story | Supplier Search Screen UI | ✅ ĐÓNG | `tongtai_supplier_search_screen.dart` (tìm, lọc, yêu thích) |
| **WTM-66** | Story | Supplier Scoring & AI Ranking | Xếp hạng & Điểm số Nhà cung cấp bằng AI | ⏳ GIỮ MỞ | CHƯA có trong code. Cần quyết định sản phẩm: AI xếp hạng nhà cung cấp. |
| **WTM-67** | Story | 1688/Shopee API Integration | Tích hợp API 1688/Shopee | ⏳ GIỮ MỞ | CHƯA có. **Chặn bởi bên ngoài** — cần API/đối tác 1688 & Shopee. |
| **WTM-71** | Story | Pricing Optimizer (AI) | Tối ưu hóa Giá cả bằng AI | ⏳ GIỮ MỞ | CHƯA có. Cần quyết định sản phẩm: AI tối ưu giá. |
| **WTM-78** | Story | Customer Segmentation & AI Analysis | ✅ ĐÓNG | RFM: `lib/features/tongtai/analytics/customer_rfm.dart` + `customer_capability.dart` + màn Rủi ro khách hàng (WTM-152) |
| **WTM-79** | Story | Omnichannel Customer View (Shopee/Facebook) | Xem khách hàng Ó mnichannel (Shopee/Facebook) | ⏳ GIỮ MỞ | CHƯA có. **Chặn bởi bên ngoài** — cần API Shopee/Facebook. |
| **WTM-85** | Story | In-Memory Cache Layer (Riverpod) | 🔀 GỘP | **Gộp vào Epic WTM-167.** AC của story này (cache toàn cục có TTL, sống qua restart) **mâu thuẫn trực tiếp** với ràng buộc Founder đặt cho WTM-167: *"không tạo cache toàn cục khó kiểm soát"*. Vấn đề thật (đọc lặp) đã được đo và ghi ở ADR-TON-019. |
| **WTM-86** | Story | Offline Data Availability | Sẻ không không Có sẵn Dữ liệu | ✂️ THU HẸP | App **đã local-first** (mọi dữ liệu trên máy, chạy offline) — phần lớn AC đã đạt. Còn thiếu đúng **chỉ báo mất mạng** cho các tính năng AI. Nên thu hẹp phạm vi. |
| **WTM-90** | Story | Journey Guidance & Resource Links | ⏳ GIỮ MỞ | CHƯA có. Nặng về nội dung (thư viện tài nguyên, đánh giá) — giá trị biên. |
| **WTM-93** | Story | Opportunity Scoring (AI) | ✅ ĐÓNG | `opportunity_rule_engine.dart` (điểm rule authoritative) + `OpportunityAiService.explain` (WTM-141). AI **chỉ giải thích** — ADR-TON-016 |
| **WTM-101** | Story | Onboarding Tutorial Screens | ✅ ĐÓNG | Trùng WTM-46 — `tongtai_onboarding_screen.dart` |
| **WTM-103** | Epic | M1 – Product Design Bible Completed | ✅ ĐÓNG | Epic M1 — trùng WTM-1 |
| **WTM-104** | Epic | WTM-104 – PILOT SPRINT: Validate Runtime End-to-End (5 Stories) | ✅ ĐÓNG | Pilot runtime đã được kiểm chứng **rất nhiều lần**: >40 story shipped qua runtime, CI xanh liên tục |
| **WTM-112** | Story | Marketing mascot kit — HIGH-FIDELITY (needs designer / image-gen) | Bộ mascot marketing | ⏳ GIỮ MỞ | **Cần designer** — không tự làm được. |
| **WTM-122** | Story | [mid-term][tech] Persistence Normalization & JSON Field Promotion | Chuẩn hóa schema dần | ⏳ GIỮ MỞ | Founder đã đóng lại trước đó (KEEP CLOSED cho tới khi quyết riêng). Giữ nguyên ở Ideas. |
| **WTM-167** | Epic | Capability Context Performance — một lượt đọc dữ liệu phục vụ nhiều Capability Context | ⏳ GIỮ MỞ | Epic đang mở, chờ Founder chọn hướng. ADR-TON-019 DRAFT + benchmark baseline đã sẵn. |

---

## Tổng kết

| | |
|---|---|
| ✅ Đóng (đã hoàn thành, có bằng chứng) | **51** |
| 🔀 Gộp vào Epic khác | **1** (WTM-85 → WTM-167) |
| ✂️ Thu hẹp phạm vi | **1** (WTM-86) |
| ⏳ Giữ mở | **9** |

**Kết quả:** 62 issue mở → **10**.

## Một chỗ tôi làm sai giữa chừng

Tôi đóng **WTM-41** dựa trên việc `SyncQueueItemsTable` tồn tại trong schema —
tức là nhìn tiêu đề chứ không đọc AC. Đọc kỹ thì AC của nó là **retry với
exponential backoff · phát hiện và giải quyết xung đột · báo người dùng khi
xung đột**: chưa có gì cả, và theo **D-5** thì Phase 2 **không có backend,
không có sync**, nên nó *không thể* làm được ở giai đoạn này.

Đã mở lại và ghi lý do đúng vào issue. Ghi ở đây vì một bản audit giấu đi chỗ
mình sai thì không dùng để tin được nữa.

## Tám việc thật sự còn mở

| Jira | Vì sao còn mở |
|---|---|
| **WTM-167** (Epic) | Chờ Founder chọn hướng — ADR-TON-019 DRAFT + benchmark baseline đã sẵn sàng |
| **WTM-66** · **WTM-71** | Cần **quyết định sản phẩm**: AI xếp hạng nhà cung cấp · AI tối ưu giá |
| **WTM-67** · **WTM-79** | **Chặn bởi bên ngoài** — cần API/đối tác 1688 · Shopee · Facebook |
| **WTM-112** | **Cần designer** |
| **WTM-86** | Đã thu hẹp: chỉ còn **chỉ báo mất mạng** cho tính năng AI |
| **WTM-90** | Nặng nội dung (thư viện tài nguyên), giá trị biên |
| **WTM-122** | Founder đã chủ động đóng lại — giữ nguyên tới khi có quyết định riêng |

## Một mâu thuẫn tìm được khi audit

**WTM-85 (In-Memory Cache Layer)** không chỉ trùng Epic WTM-167. Điều kiện
nghiệm thu của nó — *"in-memory cache with configurable TTL"*, *"cache
persistence across app session restarts"* — **mâu thuẫn trực tiếp** với ràng
buộc Founder đặt cho WTM-167: **"không tạo cache toàn cục khó kiểm soát"**, và
với ADR-TON-015 (One Data Path, cấm parallel cache).

Nếu ai đó nhặt WTM-85 lên làm theo đúng AC, họ sẽ vi phạm hai quyết định đang có
hiệu lực. Vì vậy nó được **gộp vào WTM-167**, nơi vấn đề thật (đọc lặp
`orders` ×5, `customers`/`goals` ×4) đã được đo và ghi lại tử tế.

## Ghi chú về ROADMAP

`docs/04-DELIVERY/ROADMAP.md` ghi *"Phase 1B — IN PROGRESS, Aug 1-28"* và
*"Phase 2: Build & Closed Beta — Sep 1"*. Hôm nay là **2026-08-01** và Phase 2
**đã thực thi xong**: 8/8 capability, 1418 test, AI tier G-3A→D, backup/restore,
accessibility, privacy policy. Roadmap đã được thực tế vượt qua và cần viết lại
theo mốc thật.