> ⚠️ **HISTORICAL PLANNING SNAPSHOT (2026-07-13, Phase 1B)** — trạng thái thật xem `docs/00-START-HERE/CURRENT-STATUS.md` (SOURCE-OF-TRUTH rule).

---

## 📍 Đối chiếu thực tế — 2026-08-01

Kế hoạch dưới đây **đã bị thực tế vượt qua**. Ghi lại để không ai đọc nhầm:

| Kế hoạch nói | Thực tế 2026-08-01 |
|---|---|
| *Phase 1B — IN PROGRESS, Aug 1-28* | ✅ **XONG** — 144 doc, 19 ADR, 14 screen spec |
| *Phase 1C — Go/No-Go, Aug 22-28* | ✅ **XONG** — Founder duyệt, đã chuyển sang thực thi |
| *Phase 2 Build — Sep 1 → Oct 15* | ✅ **ĐÃ THỰC THI XONG** — 8/8 capability, **1418 test**, CI xanh, chạy được trên máy thật |
| *Phase 3 — AI nâng cao, forecasting* | ✅ **PHẦN LỚN XONG** — AI tier G-3A→D (ADR-TON-013), dự báo doanh thu + rủi ro khách (ADR-TON-016), export/backup/restore |
| *Phase 4 — tích hợp Shopee/1688* | ⏳ **CHƯA** — WTM-67, WTM-79 (chặn bởi API/đối tác bên ngoài) |

**Nói ngắn gọn:** dự án đang ở **cuối Phase 3** chứ không phải giữa Phase 1B.
Việc còn lại để phát hành không phải là code mà là **nội dung pháp lý** (địa chỉ
liên hệ, điều khoản dịch vụ) và **ký iOS**.

Backlog thật còn **10 issue** — xem `docs/06-GOVERNANCE/JIRA-BACKLOG-AUDIT-2026-08-01.md`.

---

# Tổng Tài — Product Roadmap (4-Phase)

## English

**Purpose:** Define the multi-phase product roadmap from design to public release, with timelines, scope, and success criteria.

**Last Updated:** 2026-07-13  
**Status:** 🔄 Phase 1B In Progress

---

## Roadmap Overview

```
Phase 1: Product Foundation (Design)
├── 1A ✅ DONE (9 docs, July 2026)
├── 1B 🔄 IN PROGRESS (30 docs, design + arch, Aug 2026)
└── 1C (Go/No-Go review, end Aug 2026)

Phase 2: Build & Closed Beta (8-10 weeks, Sep-Oct 2026)
├── Sprint 1: Core Data Models (Week 1-2)
├── Sprint 2: Producer + Inventory Screens (Week 3-4)
├── Sprint 3: Consumer + AI Copilot (Week 5-6)
├── Sprint 4: Business Journey + Opportunity Engine (Week 7-8)
└── Beta Launch: Sep 30 — Oct 15, 2026 (50-100 testers)

Phase 3: Refine & Open Beta (4-6 weeks, Oct-Nov 2026)
├── Public beta on Play Store + App Store beta track
├── Full Finance module + Reports
├── Advanced AI (forecasting, trend analysis)
├── Export/sharing features
└── Production Launch: Late November 2026

Phase 4: Growth & Expansion (Ongoing, Dec 2026+)
├── Integrations (Shopee, TikTok, 1688 APIs)
├── Advanced analytics + dashboards
├── Team collaboration (multi-user)
├── Marketplace plugins
└── International expansion
```

---

## Phase 1A: Foundation Docs (DONE ✅ — July 2026)

**Status:** Completed  
**Duration:** ~3 weeks (mid-June to early July)  
**Team:** Founder + PM Agent + Designer  
**Output:** 9 foundational documents

**Scope:**
1. TERMINOLOGY.md — Business glossary (single source of truth)
2. PRODUCT-VISION.md — North Star and product story
3. PRODUCT-BOUNDARIES.md — In-scope for Phase 2, deferred features
4. BUSINESS-JOURNEY-BIBLE.md — User goal orchestration and flows
5. OPPORTUNITY-ENGINE.md — AI discovery engine specification
6. AI-BUSINESS-COPILOT.md — AI assistant capabilities and integration
7. UI-UX-CONCEPT-INVENTORY.md — Analysis of 25 UI mockup images
8. INFORMATION-ARCHITECTURE.md — Data model and navigation hierarchy
9. DESIGN-SYSTEM-DRAFT.md — Color, typography, spacing, component patterns

**Success Criteria:**
- ✅ All 9 docs bilingual (EN + VI)
- ✅ Terminology consistent across docs
- ✅ Product vision clear and compelling to founder
- ✅ Phase 2 team can read and understand product requirements
- ✅ No ambiguities on in-scope vs deferred features

**Key Decisions Made:**
- Product is AI-first Business OS (not just CRM or inventory app)
- Target: Vietnamese SMEs (1-10 employees)
- Core journey: Opportunity → Action → Monitoring
- Card-based UI for business data
- Local-first with optional sync later
- No backend in MVP

**Learnings for Phase 1B:**
- Founder prefers concrete product stories over abstract frameworks
- Visual mockups (UI concept inventory) accelerated alignment
- Bilingual docs double writing load but essential for team clarity
- Terminology groundwork prevents mid-project rework

---

## Phase 1B: Architecture & Detailed Specs (IN PROGRESS 🔄 — Aug 1-28, 2026)

**Status:** Currently executing  
**Duration:** 4 weeks (Aug 1-28)  
**Team:** PM Agent + Founder + Developer Agent (research) + Designer  
**Output:** 30 additional documents + 100+ Jira stories

**Scope:**

### Week 1-2: Detailed Screen Specs (Aug 1-14)
- SCREEN-HOME.md (landing page + quick actions)
- SCREEN-PRODUCER.md (supplier discovery + research)
- SCREEN-INVENTORY.md (product catalog + SKU management)
- SCREEN-CONSUMER.md (customer data + segmentation)
- SCREEN-BUSINESS-JOURNEY.md (goal setup + tracking)
- SCREEN-OPPORTUNITY-DETAILS.md (opportunity card + action plan)
- SCREEN-AI-CHAT.md (copilot chat interface)
- SCREEN-REPORTS.md (KPIs + trend analysis)
- SCREEN-SETTINGS.md (account + preferences)
- SCREEN-BACKUP.md (local export + restore)
- SCREEN-ONBOARDING.md (first-time user experience)
- SCREEN-SEARCH.md (unified business search)
- SCREEN-NOTIFICATIONS.md (alerts + reminders)

### Week 1-2: Data Architecture (Aug 1-14)
- DOMAIN-DATA-MODEL.md (entities, relationships, constraints)
- STORAGE-SCHEMA.md (Drift/SQLite tables, indices, versioning)
- AI-INTEGRATION-API.md (xAI/OpenRouter client, prompt templates)
- CACHE-STRATEGY.md (in-memory caching, offline handling)

### Week 2-3: Technical Architecture (Aug 8-21)
- APP-ARCHITECTURE-OVERVIEW.md (layered, hexagonal, packages)
- SHARED-CORE-DESIGN.md (packages reusable from Hub)
- NAVIGATION-ARCHITECTURE.md (routing, deep links, tab management)
- STATE-MANAGEMENT-DESIGN.md (Riverpod + Drift + BLoC patterns)
- SEARCH-ENGINE-ARCHITECTURE.md (FTS5, indexing, ranking)
- OPPORTUNITY-ENGINE-ARCHITECTURE.md (AI workflow, scoring)
- BUSINESS-JOURNEY-RUNTIME.md (orchestration engine, state machine)
- OFFLINE-FIRST-STRATEGY.md (sync conflict resolution, fallback patterns)

### Week 2-3: Design System Finalization (Aug 8-21)
- COMPONENT-LIBRARY.md (reusable UI components, specs)
- DESIGN-TOKENS.md (colors, spacing, typography, shadows)
- ANIMATION-SPEC.md (transitions, micro-interactions)
- ACCESSIBILITY-GUIDELINES.md (WCAG 2.1, Vietnamese language support)

### Week 3-4: Integration & Deployment (Aug 15-28)
- APP-SEPARATION-PLAN.md (multi-package structure, dependencies)
- ANDROID-IOS-IDENTITY-PLAN.md (package ID decision, Firebase setup)
- BUILD-AND-RUN-GUIDE.md (local development setup)
- CI-CD-PIPELINE.md (GitHub Actions, Firebase App Distribution)
- CRASH-REPORTING-PLAN.md (Firebase Crashlytics setup)
- ANALYTICS-PRIVACY-PLAN.md (privacy-first data collection approach)
- PERFORMANCE-TARGETS.md (load times, memory, battery benchmarks)
- TESTING-STRATEGY.md (unit, integration, E2E test plan)

### Week 3-4: Project Setup (Aug 15-28)
- JIRA-EPIC-STRUCTURE.md (how epics organize Phase 2 sprints)
- DEVELOPER-ONBOARDING.md (how to clone, build, run locally)
- DESIGN-HANDOFF-PROCESS.md (Figma → code workflow)
- DECISION-LOG.md (open decisions pending Founder approval)

**Success Criteria:**
- ✅ All 30 docs bilingual
- ✅ 100+ Jira stories created (ready for Phase 2 sprints)
- ✅ Architecture design review passed (no critical blockers)
- ✅ Designer + Founder + Developer consensus on app structure
- ✅ Prototype of app separation completed (WTM-41)
- ✅ All open decisions documented and recommended (OPEN-DECISIONS.md)

**Key Decisions to Finalize (by Aug 28):**
- D-1: App separation (multi-package vs single app)
- D-2: Package identity (`com.workizen.tongtai` vs alternative)
- D-3: MVP launch path (closed beta → open beta → production)
- D-4: Auth strategy (local-only vs Keycloak optional)
- D-5: Backend scope (none vs light sync in Phase 3)
- D-6: Monetization (free MVP vs lite freemium)
- D-7: Analytics (privacy-first no telemetry vs opt-in)
- D-8: Language priority (Vietnamese primary vs bilingual)
- D-9: AI model (xAI primary vs multi-provider)
- D-10: Export/BI (Phase 2 include vs Phase 3 deferral)

**Jira Story Creation (WTM-12+):**
- Create Epics: DATA, PRODUCER, INVENTORY, CONSUMER, JOURNEY, OPPORTUNITY, COPILOT, REPORTS
- Create Stories under each epic (prioritized for Phase 2 sprints)
- Link stories to screen specs and architecture docs

---

## Phase 1C: Go/No-Go Review (Aug 22-28, 2026)

**Status:** Planning  
**Duration:** 1 week (Aug 22-28)  
**Team:** Founder + PM Agent + Developer Agent + QA Agent  
**Output:** Phase 1 Completion Report + Phase 2 Readiness Assessment

**Scope:**
- Founder reviews all Phase 1B deliverables
- Architecture Design Review (technical team consensus)
- Risks & Mitigation Review (address top 5 risks before Phase 2)
- Phase 2 Sprint Planning (assign teams, estimate story points)
- Decision finalization (close all 10 open decisions)
- Go/No-Go gate (proceed to Phase 2 or rework Phase 1B)

**Go Criteria (ALL must be YES):**
- ✅ Founder approves product vision + roadmap
- ✅ All 10 open decisions resolved
- ✅ Architecture design review passed (no critical blockers)
- ✅ Phase 2 sprint plan confirmed (sprints 1-4 estimated)
- ✅ Developer team size and skills aligned (estimated 2-3 engineers)
- ✅ Jira backlog seeded with 100+ stories
- ✅ No critical risks unmitigated

**No-Go Criteria:**
- Architecture conflicts unresolved (e.g., app separation still TBD)
- Phase 2 resourcing impossible (not enough developers)
- Product scope creep detected (scope not matching MVP vision)
- Critical risk cannot be mitigated

**Likely Outcome:** GO (Phase 2 begins early Sep)

---

## Phase 2: Build & Closed Beta (Sep 1 — Oct 15, 2026)

**Status:** Planning  
**Duration:** ~6-8 weeks (Sep 1 — Oct 15)  
**Team:** 2-3 Developers + 1 Designer + 1 PM Agent + 1 QA Agent  
**Outputs:** Closed beta APK + IPA, 50-100 tester feedback, bug fixes

**Scope by Sprint:**

### Sprint 1: Core Data Models & Storage (Sep 1-14, Week 1-2)
**Goals:** Establish data layer, UI shells, navigation structure

**Epics / Stories:**
- (DATA-001) Create SQLite schema + Drift models (Producer, Inventory, Consumer, Journey, Opportunity)
- (NAV-001) Implement app navigation (bottom nav 4 tabs: Home / Producer / Inventory / Chat)
- (UI-001) Build reusable card components (OpportunityCard, SupplierCard, ProductCard)
- (STORAGE-001) Implement local data persistence layer
- (AUTH-001) Local UUID generation + onboarding flow (no Keycloak MVP)
- (CORE-001) Shared core package integration (Drift, AI client, components from Hub)

**Success Criteria:**
- App boots, bottom nav works, sample data shows in empty states
- Drift migrations working, local SQLite functional
- Component library integrated and testable
- Build time < 2 minutes

### Sprint 2: Producer & Inventory Screens (Sep 15-28, Week 3-4)
**Goals:** First user journey: search suppliers → add to inventory

**Epics / Stories:**
- (PRODUCER-001) Supplier discovery screen (search, filter, compare)
- (PRODUCER-002) Supplier research view (details, ratings, contact)
- (PRODUCER-003) Add supplier to saved list (favorites)
- (INVENTORY-001) Product/SKU management screen
- (INVENTORY-002) Stock level tracking + low-stock alerts
- (INVENTORY-003) Pricing optimization recommendations (AI)
- (SEARCH-001) FTS5 indexing for suppliers + products
- (UI-002) Producer + Inventory card designs finalized

**Success Criteria:**
- Users can search 1688/Shopee suppliers, see details, save favorites
- Users can add products to inventory, track stock, see pricing tips
- Search is fast (<200ms for 1000 SKUs)
- AI supplier scoring visible (Opportunity Engine integration)

### Sprint 3: Consumer & AI Copilot (Sep 29 — Oct 12, Week 5-6)
**Goals:** Customer data + basic AI chat integration

**Epics / Stories:**
- (CONSUMER-001) Customer CRM screen (contacts, purchase history, segments)
- (CONSUMER-002) Customer segmentation view (high-value, churn risk, etc.)
- (CHAT-001) AI Copilot chat interface (xAI Grok integration)
- (CHAT-002) Prompt routing (business question → relevant context → xAI)
- (CHAT-003) Chat history + persistence
- (CONSUMER-003) Omnichannel customer view (Shopee / Facebook / email contacts)
- (CACHE-001) Caching layer for repeated queries

**Success Criteria:**
- Users can chat with AI about their business (customers, opportunities, trends)
- AI responses are contextual (grounded in user's data, not hallucinations)
- Chat history persists and is searchable
- BYOK (bring your own API key) flow works for xAI

### Sprint 4: Business Journey & Opportunity Engine (Oct 13 — Oct 26, Week 7-8)
**Goals:** Core business journey orchestration + Opportunity Engine MVP

**Epics / Stories:**
- (JOURNEY-001) Business Journey setup flow (define business goal, AI creates plan)
- (JOURNEY-002) Journey tracking view (milestones, progress, next steps)
- (JOURNEY-003) AI guidance engine (step-by-step coaching, resource links)
- (OPPORTUNITY-001) Opportunity discovery feed (AI surfaces trends + arbitrage)
- (OPPORTUNITY-002) Opportunity detail + action plan (research → supplier → inventory)
- (OPPORTUNITY-003) Opportunity ROI scoring + risk assessment
- (REPORTS-001) Basic home dashboard (quick KPIs: revenue, top customers, opportunities)
- (BACKUP-001) Local export (CSV backup of all data)
- (ONBOARDING-001) First-time user onboarding (tutorials, demo data)

**Success Criteria:**
- User can set a business goal ("I want to find cheap smartphone chargers")
- AI creates a step-by-step plan (research markets → find suppliers → check pricing)
- AI surfaces opportunities proactively (e.g., "Opportunity: USB-C chargers trending in Southeast Asia")
- Home dashboard shows at-a-glance business health (top-line KPIs)
- Users can export all their data as CSV for backup

### Phase 2 Go-Live (Oct 15-30)
- Internal testing (developers + founder)
- Firebase App Distribution setup
- Closed beta invite: 50-100 testers (via Firebase App Distribution + Google Play closed track)
- Daily standup for bug fixes + feedback
- Target: Stable APK + IPA by Oct 30

**Risks (Phase 2 Critical Path):**
- Shared core extraction delays app separation (mitigate: WTM-40/41 prototypes)
- xAI API rate limits during beta (mitigate: OpenRouter fallback, quota planning)
- Drift schema versioning for users updating beta builds (mitigate: schema versioning tests)
- Tester onboarding complexity (mitigate: in-app tutorials, support email)

**Team Size Recommendation:**
- 1 Backend/Data Engineer (SQLite, data model, search)
- 1 Frontend Engineer (UI screens, navigation, state management)
- 1 AI Integration Engineer (Copilot, Opportunity Engine, prompt routing)
- 1 Designer (QA on screen specs, accessibility, polish)
- 1 QA Engineer (test automation, beta tester management)
- 1 PM Agent (roadmap, prioritization, Jira, feedback synthesis)

**Resource Estimate:** ~2000 story points (estimated 6-8 weeks at 250-300 points/week for 3 engineers)

---

## Phase 3: Refine & Open Beta (Oct 15 — Nov 30, 2026)

**Status:** Planning  
**Duration:** ~6 weeks (Oct 15 — Nov 30)  
**Team:** Same as Phase 2 + 1-2 contractors for Polish/QA  
**Outputs:** Public beta (10,000+ testers), Production launch

**Scope:**

### Oct 15 — Nov 15: Open Beta Phase
- **Week 1:** Gather Phase 2 closed beta feedback
- **Week 2-3:** Major bug fixes + UX polish
- **Week 4-5:** Advanced features (Finance module, Reports, Forecasting)
- **Week 6:** Stability hardening

**Major Features (Phase 3):**
- Finance module (revenue, expenses, profit tracking, cash flow forecasting)
- Advanced Reports (trend analysis, forecasting, anomaly alerts)
- Export (CSV/Excel export of business data)
- Sharing (share reports, opportunities, journeys with team members — Phase 3B)
- Local Sync Preparation (foundation for Phase 4 Portal sync)
- Analytics (optional, privacy-first telemetry)

**Open Beta Launch (Oct 15):**
- Publish to Google Play beta track (10,000+ testers)
- Publish to App Store TestFlight (public beta)
- Public beta page + user manual
- Community feedback channels (email support, in-app feedback)
- Target 1,000+ installs by week 1, 5,000+ by week 4

**Success Criteria (Production Go/No-Go):**
- ✅ Crash rate < 1% (stability)
- ✅ 90%+ app start time < 2 seconds
- ✅ Core journey testable (all 4 epics working)
- ✅ Top 10 bugs from Phase 2 fixed
- ✅ At least 500+ feedback responses collected
- ✅ Production store submission ready (privacy policy, content rating, etc.)

### Nov 15-30: Production Preparation
- Final polish and performance optimization
- Store submission (Google Play production track + App Store review)
- Monitoring setup (Crashlytics, performance tracking)
- Support onboarding (FAQ, email support, community channel)
- Marketing campaign (social media, founder networks)

**Production Launch (Late Nov, ~Nov 25, 2026):**
- App goes live on Google Play + App Store
- Announcement via founder channels
- Initial push for user acquisition (target 10,000+ installs in first 2 weeks)

---

## Phase 4: Growth & Expansion (Dec 2026+)

**Status:** Planning  
**Duration:** Ongoing (3-6 months)  
**Scope:** Post-launch features, integrations, team features

**Features Planned (Prioritized):**

### Q4 2026 — Q1 2027 (High Priority)
- **Integrations:** Shopee API (product sync), TikTok Shop (sales channel)
- **Team Collaboration:** Multi-user accounts, shared vaults, audit logs
- **Advanced Analytics:** Custom dashboards, predictive forecasting, anomaly alerts
- **Compliance:** Tax reporting integration, accounting export (localized for Vietnam)
- **Marketplace:** Third-party extensions, AI skill marketplace
- **Cloud Sync (Opt-in):** Portal integration, encrypted backup, cross-device sync

### Q1-Q2 2027 (Medium Priority)
- **International Expansion:** Support for Malaysia, Thailand, Indonesia, Philippines
- **Advanced AI:** Autonomous opportunity agents, business co-pilot voice mode
- **Supply Chain Optimization:** Supplier route planning, inventory forecasting
- **Channel Management:** Omnichannel inventory sync (Shopee + TikTok + own website)

### Q2-Q3 2027 (Lower Priority, Future Vision)
- **Enterprise Module:** Team workflows, approval processes, multi-location support
- **Ecosystem:** API for third-party integrations
- **AI Academy:** Founder training, business courses (knowledge hub)

---

## Timeline Gantt Chart (High Level)

```
July      Aug       Sep       Oct       Nov       Dec
Phase 1A  Phase 1B  Phase 2   Phase 3   Phase 4
✅ DONE   🔄 NOW   → BUILD   → BETA    → GROWTH
   (9 docs) (30 docs,
             decisions)
                   Closed Beta    Open Beta   Production
                   (50-100)       (10,000+)   Launch
                                              (10,000+)
```

---

## Success Metrics by Phase

| Phase | Metric | Target | Status |
|---|---|---|---|
| 1A | Docs Complete | 9 bilingual | ✅ DONE |
| 1B | Docs Complete | 30 bilingual | 🔄 IN PROGRESS |
| 1B | Jira Stories | 100+ ready | 🔄 IN PROGRESS |
| 1B | Open Decisions | All resolved | 🔄 IN PROGRESS |
| 2 | Closed Beta Users | 50-100 | Planning |
| 2 | Core Features | 4 epics working | Planning |
| 2 | Crash Rate | < 5% | Planning |
| 3 | Open Beta Users | 10,000+ | Planning |
| 3 | Production Ready | Go/No-Go | Planning |
| 3 | Crash Rate | < 1% | Planning |
| 4 | Production Users | 10,000+ | Planning |
| 4 | DAU | 1,000+ | Planning |
| 4 | Churn (30-day) | < 15% | Planning |
| 4 | Rating (Play Store) | 4.5+ | Planning |

---

---

## Tiếng Việt

**Mục Đích:** Xác định lộ trình sản phẩm đa giai đoạn từ thiết kế đến phát hành công khai, với dòng thời gian, phạm vi và tiêu chí thành công.

**Cập Nhật Lần Cuối:** 2026-07-13  
**Trạng Thái:** 🔄 Phase 1B Đang Tiến Hành

### Tổng Quan Lộ Trình

```
Phase 1: Nền Tảng Sản Phẩm (Design)
├── 1A ✅ DONE (9 tài liệu, Tháng 7 2026)
├── 1B 🔄 ĐANG TIẾN HÀNH (30 tài liệu, design + arch, Tháng 8 2026)
└── 1C (Review Go/No-Go, cuối Tháng 8 2026)

Phase 2: Xây Dựng & Closed Beta (8-10 tuần, Tháng 9-10 2026)
├── Sprint 1: Mô Hình Dữ Liệu Cốt Lõi (Tuần 1-2)
├── Sprint 2: Màn Hình Producer + Inventory (Tuần 3-4)
├── Sprint 3: Consumer + AI Copilot (Tuần 5-6)
├── Sprint 4: Business Journey + Opportunity Engine (Tuần 7-8)
└── Beta Launch: 30 Tháng 9 — 15 Tháng 10, 2026 (50-100 người kiểm thử)

Phase 3: Tinh Chỉnh & Open Beta (4-6 tuần, Tháng 10-11 2026)
├── Public beta trên Play Store + App Store beta track
├── Module Tài Chính Đầy Đủ + Báo Cáo
├── AI Nâng Cao (dự báo, phân tích xu hướng)
├── Tính Năng Xuất/Chia Sẻ
└── Production Launch: Cuối Tháng 11 2026

Phase 4: Tăng Trưởng & Mở Rộng (Liên Tục, Tháng 12 2026+)
├── Tích Hợp (Shopee, TikTok, 1688 APIs)
├── Phân Tích Nâng Cao + Bảng Điều Khiển
├── Cộng Tác Đội Nhóm (đa người dùng)
├── Các Plugin Marketplace
└── Mở Rộng Quốc Tế
```

### Phase 1A: Tài Liệu Nền Tảng (HOÀN THÀNH ✅ — Tháng 7 2026)

**Trạng Thái:** Hoàn thành  
**Thời Gian:** ~3 tuần (giữa Tháng 6 đến đầu Tháng 7)  
**Đội:** Founder + PM Agent + Designer  
**Đầu Ra:** 9 tài liệu nền tảng

**Phạm Vi:**
1. TERMINOLOGY.md — Từ Vựng Kinh Doanh
2. PRODUCT-VISION.md — North Star và câu chuyện sản phẩm
3. PRODUCT-BOUNDARIES.md — Phạm vi Phase 2, tính năng hoãn lại
4. BUSINESS-JOURNEY-BIBLE.md — Về mục tiêu người dùng và luồng
5. OPPORTUNITY-ENGINE.md — Quy định công cụ khám phá AI
6. AI-BUSINESS-COPILOT.md — Khả năng trợ lý AI
7. UI-UX-CONCEPT-INVENTORY.md — Phân tích 25 hình ảnh khái niệm UI
8. INFORMATION-ARCHITECTURE.md — Mô hình dữ liệu và phân cấp điều hướng
9. DESIGN-SYSTEM-DRAFT.md — Màu sắc, kiểu chữ, khoảng cách, mẫu thành phần

**Tiêu Chí Thành Công:**
- ✅ 9 tài liệu song ngữ (EN + VI)
- ✅ Thuật ngữ nhất quán
- ✅ Tầm nhìn sản phẩm rõ ràng
- ✅ Đội Phase 2 hiểu yêu cầu
- ✅ Không có sự mơ hồ về phạm vi

### Phase 1B: Kiến Trúc & Quy Định Chi Tiết (ĐANG TIẾN HÀNH 🔄 — 1 Tháng 8 — 28 Tháng 8, 2026)

**Trạng Thái:** Đang thực hiện  
**Thời Gian:** 4 tuần (1 Tháng 8 — 28 Tháng 8)  
**Đội:** PM Agent + Founder + Developer Agent + Designer  
**Đầu Ra:** 30 tài liệu bổ sung + 100+ câu chuyện Jira

**Phạm Vi:**

### Tuần 1-2: Quy Định Màn Hình Chi Tiết (1 Tháng 8 — 14 Tháng 8)
- SCREEN-HOME.md (trang đích + hành động nhanh)
- SCREEN-PRODUCER.md (khám phá nhà cung cấp + nghiên cứu)
- SCREEN-INVENTORY.md (danh mục sản phẩm + quản lý SKU)
- SCREEN-CONSUMER.md (dữ liệu khách hàng + phân đoạn)
- SCREEN-BUSINESS-JOURNEY.md (thiết lập mục tiêu + theo dõi)
- SCREEN-OPPORTUNITY-DETAILS.md (thẻ cơ hội + kế hoạch hành động)
- SCREEN-AI-CHAT.md (giao diện trò chuyện copilot)
- SCREEN-REPORTS.md (KPIs + phân tích xu hướng)
- SCREEN-SETTINGS.md (tài khoản + tùy chọn)
- SCREEN-BACKUP.md (xuất cục bộ + khôi phục)
- SCREEN-ONBOARDING.md (trải nghiệm người dùng lần đầu)
- SCREEN-SEARCH.md (tìm kiếm kinh doanh thống nhất)
- SCREEN-NOTIFICATIONS.md (cảnh báo + nhắc nhở)

### Tuần 2-3: Kiến Trúc Kỹ Thuật (8 Tháng 8 — 21 Tháng 8)
- APP-ARCHITECTURE-OVERVIEW.md (layered, hexagonal, packages)
- SHARED-CORE-DESIGN.md (packages tái sử dụng từ Hub)
- NAVIGATION-ARCHITECTURE.md (định tuyến, liên kết sâu, quản lý tab)
- STATE-MANAGEMENT-DESIGN.md (mẫu Riverpod + Drift)
- SEARCH-ENGINE-ARCHITECTURE.md (FTS5, indexing, xếp hạng)
- OPPORTUNITY-ENGINE-ARCHITECTURE.md (quy trình làm việc AI, tính điểm)
- BUSINESS-JOURNEY-RUNTIME.md (công cụ hợp nhất, máy trạng thái)
- OFFLINE-FIRST-STRATEGY.md (giải quyết xung đột đồng bộ, mẫu dự phòng)

### Tiêu Chí Thành Công:
- ✅ 30 tài liệu song ngữ
- ✅ 100+ câu chuyện Jira được tạo
- ✅ Xem xét thiết kế kiến trúc thông qua (không có trở ngại nghiêm trọng)
- ✅ Đồng thuận thiết kế, Founder, nhà phát triển
- ✅ Prototype tách ứng dụng hoàn thành (WTM-41)
- ✅ Tất cả quyết định mở được ghi lại (OPEN-DECISIONS.md)

### Phase 1C: Review Go/No-Go (22 Tháng 8 — 28 Tháng 8, 2026)

**Phạm Vi:**
- Founder xem xét tất cả kết quả 1B
- Review Thiết Kế Kiến Trúc
- Review Rủi Ro & Giảm Thiểu
- Lập Kế Hoạch Sprint Phase 2
- Hoàn Thiện Quyết Định (đóng tất cả 10 quyết định mở)
- Cơi Go/No-Go (tiếp tục Phase 2 hoặc sửa chữa)

**Tiêu Chí Go (TẤT CẢ phải đúng):**
- ✅ Founder phê duyệt tầm nhìn sản phẩm
- ✅ 10 quyết định mở được giải quyết
- ✅ Review Thiết Kế Kiến Trúc thông qua
- ✅ Kế Hoạch Sprint Phase 2 được xác nhận
- ✅ Kích Thước Đội Nhà Phát Triển Căn Chỉnh
- ✅ Backlog Jira được gieo với 100+ câu chuyện
- ✅ Không có rủi ro nghiêm trọng chưa được giảm thiểu

**Kết Quả Có Thể Xảy Ra:** GO (Phase 2 bắt đầu sớm Tháng 9)

### Phase 2: Xây Dựng & Closed Beta (1 Tháng 9 — 15 Tháng 10, 2026)

**Thời Gian:** ~6-8 tuần  
**Đội:** 2-3 Nhà Phát Triển + 1 Designer + 1 PM Agent + 1 QA Agent  
**Đầu Ra:** Closed beta APK + IPA, phản hồi 50-100 người kiểm thử

**Sprint 1: Mô Hình Dữ Liệu Cốt Lõi (1 Tháng 9 — 14 Tháng 9)**
- Tạo Lược Đồ SQLite + mô hình Drift
- Triển Khai Điều Hướng Ứng Dụng
- Xây Dựng Thành Phần Thẻ Tái Sử Dụng
- Thực Hiện Lớp Lưu Trữ Dữ Liệu Cục Bộ
- Tích Hợp Gói Shared Core

**Sprint 2: Màn Hình Producer & Inventory (15 Tháng 9 — 28 Tháng 9)**
- Màn Hình Khám Phá Nhà Cung Cấp (tìm kiếm, lọc, so sánh)
- Quản Lý Sản Phẩm / SKU
- Theo Dõi Mức Tồn Kho + Cảnh Báo
- Khuyến Nghị Tối Ưu Hóa Giá (AI)

**Sprint 3: Consumer & AI Copilot (29 Tháng 9 — 12 Tháng 10)**
- Màn Hình CRM Khách Hàng
- Xem Phân Đoạn Khách Hàng
- Giao Diện Trò Chuyện Copilot AI (tích hợp xAI Grok)
- Định Tuyến Lời Nhắc (câu hỏi kinh doanh → bối cảnh liên quan → xAI)
- Lịch Sử Trò Chuyện & Tính Bền Vững

**Sprint 4: Business Journey & Opportunity Engine (13 Tháng 10 — 26 Tháng 10)**
- Luồng Thiết Lập Business Journey
- Xem Theo Dõi Journey
- Công Cụ Hướng Dẫn AI
- Bảng Cơ Hội (AI bề ngoài xu hướng)
- Chi Tiết Cơ Hội + Kế Hoạch Hành Động
- Tính Điểm ROI + Đánh Giá Rủi Ro
- Bảng Điều Khiển Trang Chủ Cơ Bản
- Xuất Cục Bộ (CSV sao lưu)
- Onboarding Người Dùng Lần Đầu

### Phase 3: Tinh Chỉnh & Open Beta (15 Tháng 10 — 30 Tháng 11, 2026)

**Thời Gian:** ~6 tuần  
**Phạm Vi:**
- Tập Hợp Phản Hồi Closed Beta (Tuần 1)
- Sửa Lỗi Chính + UX Polish (Tuần 2-3)
- Tính Năng Nâng Cao (Module Tài Chính, Báo Cáo, Dự Báo) (Tuần 4-5)
- Cứng Hóa Ổn Định (Tuần 6)

**Các Tính Năng Chính (Phase 3):**
- Module Tài Chính (theo dõi doanh thu, chi phí, lợi nhuận, dự báo dòng tiền)
- Báo Cáo Nâng Cao (phân tích xu hướng, dự báo, cảnh báo bất thường)
- Xuất (CSV/Excel xuất dữ liệu kinh doanh)
- Chia Sẻ (chia sẻ báo cáo, cơ hội, journey)
- Chuẩn Bị Đồng Bộ Cục Bộ (nền tảng cho đồng bộ Portal Phase 4)
- Phân Tích (tùy chọn, privacy-first telemetry)

**Open Beta Launch (15 Tháng 10):**
- Xuất Bản để Google Play beta track (10,000+ người kiểm thử)
- Xuất Bản để App Store TestFlight
- Trang Beta Công Khai + Hướng Dẫn Người Dùng
- Kênh Phản Hồi Cộng Đồng

**Production Launch (Cuối Tháng 11, ~25 Tháng 11, 2026):**
- Ứng Dụng Có Sẵn Trên Google Play + App Store
- Thông Báo Qua Kênh Founder
- Đẩy Lên Để Tăng Tương Tác Người Dùng (mục tiêu 10,000+ cài đặt trong 2 tuần)

### Phase 4: Tăng Trưởng & Mở Rộng (Tháng 12 2026+)

**Thời Gian:** Liên Tục (3-6 tháng)  
**Phạm Vi:** Tính Năng Sau Khi Phát Hành, Tích Hợp, Tính Năng Đội Nhóm

**Tính Năng Dự Kiến (Ưu Tiên):**

### Q4 2026 — Q1 2027 (Ưu Tiên Cao)
- **Tích Hợp:** Shopee API (đồng bộ sản phẩm), TikTok Shop (kênh bán hàng)
- **Cộng Tác Đội Nhóm:** Tài khoản đa người dùng, khoá chia sẻ, nhật ký kiểm toán
- **Phân Tích Nâng Cao:** Bảng điều khiển tùy chỉnh, dự báo dự đoán, cảnh báo bất thường
- **Tuân Thủ:** Tích hợp báo cáo thuế, xuất tính kế toán
- **Marketplace:** Tiện ích của Bên Thứ Ba, Marketplace Kỹ Năng AI
- **Đồng Bộ Đám Mây (Opt-in):** Tích Hợp Portal, Sao Lưu Mã Hóa, Đồng Bộ Giữa Các Thiết Bị

---

**Cập Nhật Lần Cuối:** 2026-07-13  
**Trạng Thái:** 🔄 Sẵn Sàng Cho Founder Review