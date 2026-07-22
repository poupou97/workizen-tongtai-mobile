# Tổng Tài — Product Backlog (Living Document)
# Tổng Tài — Backlog Sản Phẩm (Tài Liệu Sống)

**Version:** 1.0  
**Last Updated:** 2026-07-13  
**Status:** 🔄 LIVING DOCUMENT (updated continuously as stories are created and prioritized)  
**Trạng Thái:** 🔄 TÀI LIỆU SỐNG (cập nhật liên tục khi story được tạo và ưu tiên hóa)

---

## 📋 EXECUTIVE SUMMARY / TÓM TẮT ĐIỀU HÀNH

### English

Tổng Tài's product backlog organizes **100+ stories across 4 development phases** (Phase 1C through Phase 4). This living document maps:

- **Phase 1C (Jul 13 — Aug 2):** Product Design Bible refinement, fit-gap analysis, Jira stories, open decision resolution
- **Phase 2 (Sep 1 — Oct 15):** Core build + closed beta (4 sprints)
- **Phase 3 (Oct 20 — Nov 15):** Open beta + refinement
- **Phase 4 (Dec+):** Growth + integrations

Each phase is organized by **Epic** (business capability), with stories mapped to acceptance criteria, effort estimates, and dependencies.

### Tiếng Việt

Backlog sản phẩm Tổng Tài tổ chức **hơn 100 story trên 4 giai đoạn phát triển** (Phase 1C đến Phase 4). Tài liệu này ánh xạ:

- **Phase 1C (20 tháng 7 — 2 tháng 8):** Phân tích fit-gap, seeding Jira, giải quyết quyết định mở
- **Phase 2 (1 tháng 9 — 15 tháng 10):** Xây dựng cốt lõi + beta đóng (4 sprint)
- **Phase 3 (20 tháng 10 — 15 tháng 11):** Beta mở + tinh chỉnh
- **Phase 4 (Tháng 12+):** Tăng trưởng + tích hợp

Mỗi giai đoạn được tổ chức theo **Epic** (khả năng kinh doanh), với các story ánh xạ tới tiêu chí chấp nhận, ước tính nỗ lực, và phụ thuộc.

---

## 📈 BACKLOG BY PHASE / BACKLOG THEO GIAI ĐOẠN

### Phase 1C: Product Design Bible Refinement (Jul 13 — Aug 2, 2026)

**Status:** 🔄 In Progress / Đang Tiến Hành  
**Duration:** 2 weeks / 2 tuần  
**Team:** Founder + PM Agent + Developer Agent + QA Agent  
**Output:** Phase 1 Completion Report + 50+ Phase 2/3 Jira stories + Founder decision gate  
**Kết Quả:** Báo cáo hoàn thành Phase 1 + 50+ story Phase 2/3 + cổng quyết định Founder

#### Phase 1C Goals (Goals / Mục Tiêu)

| Goal | Owner | Due | Status |
|---|---|---|---|
| Complete Fit-Gap Analysis (Hub reuse evaluation) | Developer Agent | Jul 25 | 🔄 In Progress |
| Resolve 3 Gating Decisions (D-1, D-2, tech stack) | Founder + PM Agent | Aug 5 | 📋 Pending Founder |
| Create 50+ Phase 2/3 stories in Jira (WTM-48+) | PM Agent | Aug 2 | ⏳ Blocked (awaiting decisions) |
| Phase 1 Completion Report + Go/No-Go recommendation | PM Agent | Aug 2 | ⏳ Ready to draft |
| Confluence documentation + team briefing | PM Agent | Aug 2 | 📋 Pending |

#### Phase 1C Stories (Phase 1C Story)

**WTM-46: Fit-Gap Analysis — Hub Core Reuse**  
Description: Evaluate which Hub packages (workizen_core, flutter_secure_storage, AI client) can be reused in Tổng Tài without modification.  
Acceptance Criteria:
- [x] Code audit completed (WTM-40/41 prototypes)
- [ ] Reuse assessment report finalized (REUSE-ASSESSMENT.md ✅ done)
- [ ] Technical debt identified (if any)
- [ ] Dependency versioning strategy confirmed
- [ ] Phase 2 squad briefed on shared package API

Epic: TECH-FOUNDATION  
Priority: P0  
Status: 📋 Ready for Development  
Linked Doc: docs/tongtai/REUSE-ASSESSMENT.md

---

**WTM-47: Decision Gate — D-1, D-2, Tech Stack Approval**  
Description: Founder approval of three gating decisions (App Separation, Package Identity, tech stack) required before Phase 2 sprint planning.  
Acceptance Criteria:
- [ ] D-1 decision recorded in OPEN-DECISIONS.md (App Separation: Option 2 recommended)
- [ ] D-2 decision recorded in OPEN-DECISIONS.md (Package Identity: com.workizen.tongtai recommended)
- [ ] Tech stack approval (Flutter stable channel, Drift ORM, Riverpod, etc.)
- [ ] Phase 2 sprint plan adjusted per decision
- [ ] Team briefed on final architecture direction

Epic: GOVERNANCE  
Priority: P0  
Status: 📋 Blocked (awaiting Founder)  
Linked Doc: docs/tongtai/OPEN-DECISIONS.md

---

**WTM-48: Phase 1 Completion Report**  
Description: Synthesize Phase 1A/1B/1C deliverables, roadmap validation, open issues, and Go/No-Go recommendation for Founder.  
Acceptance Criteria:
- [ ] Executive summary (2 pages, bilingual)
- [ ] Deliverables checklist (all 48+ docs, 100+ stories)
- [ ] Risk register summary (top 10 risks + mitigation)
- [ ] Phase 2 readiness assessment
- [ ] Go/No-Go recommendation with confidence level

Epic: GOVERNANCE  
Priority: P0  
Status: 📋 Ready to draft  
Linked Doc: docs/tongtai/PHASE-1B-EXECUTION-REPORT.md

---

**WTM-49: Jira Story Creation — Phase 2/3 Epics & Stories**  
Description: Create 50+ Jira stories for Phase 2 (4 sprints) and Phase 3, organized by epic and priority.  
Acceptance Criteria:
- [ ] All stories WTM-50 through WTM-100+ created in Jira
- [ ] Stories linked to acceptance criteria docs
- [ ] Story points estimated (relative sizing)
- [ ] Sprint assignments tentative (Sprint 1-8)
- [ ] PRODUCT-BACKLOG.md updated with real Jira IDs

Epic: GOVERNANCE  
Priority: P0  
Status: ⏳ Blocked (awaiting Phase 1C decision gate WTM-47)  
Linked Doc: docs/tongtai/ROADMAP.md

---

**WTM-50: Confluence Product Page — Team Hub**  
Description: Create Confluence landing page for Tổng Tài product, linked from Hub project space.  
Acceptance Criteria:
- [ ] Page created in Confluence WTM space
- [ ] Links to all 48+ docs in docs/tongtai/
- [ ] Team navigation (Jira backlog, Roadmap, Architecture diagrams)
- [ ] One-page product overview (vision + roadmap)
- [ ] Shared with core team for visibility

Epic: GOVERNANCE  
Priority: P1  
Status: 📋 Ready for Development

---

### Phase 2: Core Build + Closed Beta (Sep 1 — Oct 15, 2026)

**Status:** 📋 Planning / Lập Kế Hoạch  
**Duration:** 6 weeks / 6 tuần  
**Team:** 2-3 Developers + 1 Designer + 1 PM Agent + 1 QA Agent  
**Output:** Closed beta APK + IPA, runnable on real devices, 50-100 tester feedback  
**Kết Quả:** Closed beta APK + IPA, chạy trên thiết bị thực, phản hồi 50-100 tester

#### Phase 2 Sprints Overview

| Sprint | Duration | Epics | Stories | Focus |
|---|---|---|---|---|
| Sprint 1 | Sep 1-14 | DATA, NAV, AUTH, CORE | ~12 | Data layer + UI shells + navigation |
| Sprint 2 | Sep 15-28 | PRODUCER, INVENTORY, SEARCH | ~10 | Producer discovery + inventory management |
| Sprint 3 | Sep 29 — Oct 12 | CONSUMER, CHAT, CACHE | ~8 | Consumer CRM + AI copilot + caching |
| Sprint 4 | Oct 13-26 | JOURNEY, OPPORTUNITY, REPORTS | ~10 | Business journey + opportunity engine |
| **TOTAL** | | | **~40** | **Core MVP features** |

#### Phase 2 Sprint 1: Core Data Models & Storage (Sep 1-14)

**Epic: DATA — Core Data Models**  
Status: 📋 Ready  
Description: Establish SQLite schema, Drift ORM models, and local data persistence for all business entities (Producer, Inventory, Consumer, Journey, Opportunity).  
Acceptance Criteria (Epic Done):
- [ ] SQLite schema defined and versioned (migration WTM-51)
- [ ] All Drift models generated and testable
- [ ] Relationships validated (FK constraints, cascading deletes)
- [ ] Performance benchmarks met (query <100ms for 1000 rows)
- [ ] Offline-first strategy validated (sync queue structure in place)

Stories:
- **WTM-51: SQLite Schema Design & Drift Models**  
  Create core tables: Producers, Inventory, Consumers, Journeys, Opportunities, OpportunitiesActions, ChatMessages, Attachments. Include indices for frequently-queried fields.  
  Effort: 5 SP | Owner: Developer | Due: Sep 5

- **WTM-52: Drift Migration V1 (Create Tables)**  
  Implement Drift migration for schema v1. Test on Android + iOS simulators.  
  Effort: 3 SP | Owner: Developer | Due: Sep 7

- **WTM-53: Drift Model Validation & Relationships**  
  Validate FK relationships, cascading deletes, and query performance. Create test fixtures.  
  Effort: 3 SP | Owner: Developer | Due: Sep 10

- **WTM-54: Offline-First: Sync Queue & Conflict Resolution**  
  Design conflict resolution strategy for optional cloud sync (Phase 3). Implement local sync queue data structure.  
  Effort: 3 SP | Owner: Developer | Due: Sep 12

---

**Epic: NAV — App Navigation & Routing**  
Status: 📋 Ready  
Description: Implement bottom-tab navigation (Home / Producer / Inventory / Chat / More), with deep linking support.  
Acceptance Criteria (Epic Done):
- [ ] Bottom nav working on Android + iOS
- [ ] All 4 tabs bootable with empty states
- [ ] Deep linking tested for external flows
- [ ] Navigation state persists on back press
- [ ] No console errors on tab switch

Stories:
- **WTM-55: Bottom Nav Framework**  
  Implement BottomNavigationBar with 4 tabs (Home, Producer, Inventory, Chat, More). Wire to Riverpod state.  
  Effort: 2 SP | Owner: Developer | Due: Sep 3

- **WTM-56: Tab State Persistence**  
  Ensure tab state preserves scroll position and form state when switching tabs.  
  Effort: 2 SP | Owner: Developer | Due: Sep 5

- **WTM-57: Deep Linking Support**  
  Implement URI scheme handling for producer/consumer/opportunity deep links.  
  Effort: 2 SP | Owner: Developer | Due: Sep 8

---

**Epic: AUTH — Authentication & Onboarding**  
Status: 📋 Ready  
Description: Local UUID-based auth (no Keycloak MVP), plus first-time user onboarding flow.  
Acceptance Criteria (Epic Done):
- [ ] Local user identity created on first launch (UUID)
- [ ] Onboarding flow guides users through app tour
- [ ] Settings persist across restarts
- [ ] Logout + re-login works (clears local data)
- [ ] No analytics/telemetry without consent

Stories:
- **WTM-58: Local User Identity (UUID)**  
  Generate and persist local user UUID on first app launch. Store in secure storage.  
  Effort: 1 SP | Owner: Developer | Due: Sep 2

- **WTM-59: Onboarding Flow (Tutorial)**  
  Create screens: Welcome → App Tour → Data Import Option → Ready to Use.  
  Effort: 3 SP | Owner: Developer + Designer | Due: Sep 8

---

**Epic: CORE — Shared Core Packages**  
Status: 📋 Ready  
Description: Integrate reusable packages from Hub (workizen_core, AI client, components).  
Acceptance Criteria (Epic Done):
- [ ] workizen_core package imported (or forked if Hub changes too fast)
- [ ] AI client (xAI/OpenRouter) functional
- [ ] Component library (Card, Button, Input, Avatar) working
- [ ] Shared Drift schema accessible
- [ ] Build time < 2 minutes

Stories:
- **WTM-60: Shared Core Package Integration**  
  Import workizen_core into Tổng Tài as path dependency (or pub.dev after D-1 decision).  
  Effort: 2 SP | Owner: Developer | Due: Sep 4

- **WTM-61: AI Client Setup (xAI Grok)**  
  Wire xAI client for chat, with BYOK API key handling. Test with xAI Grok API.  
  Effort: 2 SP | Owner: Developer | Due: Sep 7

- **WTM-62: Component Library Integration**  
  Import Card, Button, Input, Avatar, Chip, Modal from Hub component library.  
  Effort: 1 SP | Owner: Designer + Developer | Due: Sep 5

---

#### Phase 2 Sprint 2: Producer & Inventory Screens (Sep 15-28)

**Epic: PRODUCER — Supplier Discovery & Management**  
Status: 📋 Ready  
Description: Supplier/producer search, research, and favorites management. Integration with 1688/Shopee APIs for data enrichment.  
Acceptance Criteria (Epic Done):
- [ ] User can search suppliers by name/category
- [ ] Supplier detail view shows ratings, contact, price range
- [ ] Users can save suppliers to favorites
- [ ] Supplier scoring (AI-powered) visible
- [ ] FTS5 indexing working for <200ms search

Stories:
- **WTM-63: Supplier Search Screen UI**  
  Design and build search bar + filter chips (category, min-rating, price-range). Connect to search engine.  
  Effort: 3 SP | Owner: Developer + Designer | Due: Sep 18

- **WTM-64: Supplier Detail View**  
  Display: name, category, ratings, reviews, contact info, price range, product samples.  
  Effort: 3 SP | Owner: Developer | Due: Sep 20

- **WTM-65: Supplier Favorites (Save & Recall)**  
  Add to favorites, view saved suppliers list, remove from favorites.  
  Effort: 2 SP | Owner: Developer | Due: Sep 22

- **WTM-66: Supplier Scoring & AI Ranking**  
  Display AI-generated score (0-100) based on ratings, product match, responsiveness.  
  Effort: 3 SP | Owner: Developer | Due: Sep 25

- **WTM-67: 1688/Shopee API Integration (Phase 2 MVP: Shopee only)**  
  Fetch supplier data from Shopee Open API. Handle rate limits.  
  Effort: 4 SP | Owner: Developer | Due: Sep 28

---

**Epic: INVENTORY — Product & SKU Management**  
Status: 📋 Ready  
Description: Product catalog, stock tracking, pricing recommendations. AI-powered inventory insights.  
Acceptance Criteria (Epic Done):
- [ ] User can add/edit products (name, SKU, cost, stock qty, selling price)
- [ ] Stock level alerts for low inventory
- [ ] Pricing suggestions based on cost + margin target
- [ ] Inventory dashboard shows top products
- [ ] Bulk import from CSV (Phase 2 MVP: manual entry only)

Stories:
- **WTM-68: Inventory Screen & Product List**  
  Display list of products with stock status (in stock / low / out). Quick-add button.  
  Effort: 2 SP | Owner: Developer | Due: Sep 16

- **WTM-69: Add/Edit Product**  
  Form: name, SKU, category, cost, stock qty, selling price, supplier link.  
  Effort: 2 SP | Owner: Developer + Designer | Due: Sep 18

- **WTM-70: Stock Level Alerts**  
  Set low-stock threshold. Notify user when qty falls below threshold.  
  Effort: 2 SP | Owner: Developer | Due: Sep 20

- **WTM-71: Pricing Optimizer (AI)**  
  Suggest selling price based on cost + user's target margin. Show competitor prices (if API available).  
  Effort: 3 SP | Owner: Developer | Due: Sep 25

---

**Epic: SEARCH — Full-Text Search Engine**  
Status: 📋 Ready  
Description: FTS5-based search across all business entities (suppliers, products, customers, conversations).  
Acceptance Criteria (Epic Done):
- [ ] FTS5 indices built for Suppliers, Inventory, Consumers
- [ ] Search returns results in <200ms for 1000+ records
- [ ] Results ranked by relevance (title match > description match)
- [ ] Search available from unified search screen
- [ ] Offline search works (no network required)

Stories:
- **WTM-72: FTS5 Index Setup (Suppliers, Inventory, Consumers)**  
  Create FTS5 virtual tables, populate on app startup.  
  Effort: 3 SP | Owner: Developer | Due: Sep 18

- **WTM-73: Unified Search Screen**  
  Single search bar that searches across all entity types. Grouped results.  
  Effort: 2 SP | Owner: Developer | Due: Sep 22

- **WTM-74: Search Result Ranking & Relevance**  
  Rank results by match quality (exact > prefix > substring). Score by recency.  
  Effort: 2 SP | Owner: Developer | Due: Sep 25

---

#### Phase 2 Sprint 3: Consumer & AI Copilot (Sep 29 — Oct 12)

**Epic: CONSUMER — Customer CRM & Segmentation**  
Status: 📋 Ready  
Description: Customer data management, purchase history, segmentation (high-value, churn risk, etc.).  
Acceptance Criteria (Epic Done):
- [ ] User can add/edit customer records (name, phone, email, address, tags)
- [ ] View customer purchase history and lifetime value
- [ ] Segment customers by value (high/medium/low) or risk (churn risk, etc.)
- [ ] Export customer list (CSV)
- [ ] Omnichannel customer view (Shopee / Facebook / email contacts)

Stories:
- **WTM-75: Customer List Screen**  
  Display all customers with key info (name, phone, last purchase, LTV). Sortable by LTV / last purchase.  
  Effort: 2 SP | Owner: Developer | Due: Oct 1

- **WTM-76: Add/Edit Customer**  
  Form: name, phone, email, address, tags (VIP, wholesale, etc.).  
  Effort: 2 SP | Owner: Developer | Due: Oct 3

- **WTM-77: Customer Purchase History**  
  Show all past orders with dates, amounts, products. Calculate LTV, repeat rate.  
  Effort: 2 SP | Owner: Developer | Due: Oct 5

- **WTM-78: Customer Segmentation & AI Analysis**  
  Segment customers by value + churn risk. Show AI insights (e.g., "High-value customers buying less recently").  
  Effort: 3 SP | Owner: Developer | Due: Oct 8

- **WTM-79: Omnichannel Customer View (Shopee/Facebook)**  
  Fetch and unify customer records from Shopee + Facebook. De-duplicate by phone/email.  
  Effort: 4 SP | Owner: Developer | Due: Oct 12

---

**Epic: CHAT — AI Copilot & Chat Interface**  
Status: 📋 Ready  
Description: Chat interface for AI business assistant. Context-aware responses grounded in user's data.  
Acceptance Criteria (Epic Done):
- [ ] Chat UI displays messages with sender avatars
- [ ] User can type questions, AI responds with context (user's data)
- [ ] Chat history persists and is searchable
- [ ] Typing indicator + error handling
- [ ] BYOK API key flow working (xAI Grok)

Stories:
- **WTM-80: Chat Screen UI**  
  Message list + input field + send button. Show loading spinner during response.  
  Effort: 2 SP | Owner: Developer + Designer | Due: Oct 1

- **WTM-81: Chat Message Persistence**  
  Store messages in Drift. Load history on screen open.  
  Effort: 1 SP | Owner: Developer | Due: Oct 2

- **WTM-82: AI Prompt Routing & Context Injection**  
  Detect question type (supplier search? customer analysis? opportunity?). Inject relevant context from DB.  
  Effort: 3 SP | Owner: Developer | Due: Oct 6

- **WTM-83: BYOK API Key Handling**  
  Let user input xAI API key, store securely, use in requests. Show key status (valid/expired).  
  Effort: 2 SP | Owner: Developer | Due: Oct 4

- **WTM-84: Chat Search & History**  
  Search past chat messages by keyword. Show recent conversations.  
  Effort: 2 SP | Owner: Developer | Due: Oct 8

---

**Epic: CACHE — Caching & Performance Optimization**  
Status: 📋 Ready  
Description: In-memory caching for frequently-accessed data (suppliers, products, customers). Offline support.  
Acceptance Criteria (Epic Done):
- [ ] Frequently-used data cached in memory (invalidated on refresh)
- [ ] App works offline when cache present
- [ ] Sync queue populated when offline
- [ ] Performance benchmarks met (screen load <1s)

Stories:
- **WTM-85: In-Memory Cache Layer (Riverpod)**  
  Design cache invalidation strategy using Riverpod providers. Cache TTL configurable.  
  Effort: 2 SP | Owner: Developer | Due: Oct 3

- **WTM-86: Offline Data Availability**  
  When offline, serve data from cache. Queue sync actions for later.  
  Effort: 2 SP | Owner: Developer | Due: Oct 6

---

#### Phase 2 Sprint 4: Business Journey & Opportunity Engine (Oct 13-26)

**Epic: JOURNEY — Business Journey Orchestration**  
Status: 📋 Ready  
Description: User sets a business goal (e.g., "Find suppliers for eco-friendly phone chargers"). AI creates step-by-step action plan.  
Acceptance Criteria (Epic Done):
- [ ] User can define a business goal via conversational flow
- [ ] AI generates 5-10 step action plan
- [ ] Milestones shown with progress tracking
- [ ] Next-step guidance and resource links provided
- [ ] Journey history persists, editable by user

Stories:
- **WTM-87: Business Goal Input Flow**  
  Conversational onboarding: "What's your business goal?" → "Tell me more" → "Create plan?"  
  Effort: 3 SP | Owner: Developer + Designer | Due: Oct 15

- **WTM-88: AI Action Plan Generation (Claude/xAI)**  
  Given goal, generate step-by-step plan. Example: "Research market → Find suppliers → Evaluate pricing → Place order"  
  Effort: 4 SP | Owner: Developer | Due: Oct 18

- **WTM-89: Journey Progress Tracking**  
  Show milestones, allow user to mark steps complete. Calculate % progress.  
  Effort: 2 SP | Owner: Developer | Due: Oct 20

- **WTM-90: Journey Guidance & Resource Links**  
  Show next recommended step + relevant docs/tools (YouTube links, supplier websites).  
  Effort: 2 SP | Owner: Developer | Due: Oct 22

---

**Epic: OPPORTUNITY — Opportunity Discovery & Engine**  
Status: 📋 Ready  
Description: AI surfaces business opportunities (market trends, supplier arbitrage, customer upsell). Opportunities ranked by ROI + risk.  
Acceptance Criteria (Epic Done):
- [ ] Opportunity feed shows daily AI-generated opportunities
- [ ] Each opportunity has detail view: research + supplier suggestions + ROI estimate
- [ ] Users can action opportunity (create journey, add supplier)
- [ ] Opportunity history tracked (opportunities completed, rejected)
- [ ] Risk/ROI scoring visible

Stories:
- **WTM-91: Opportunity Feed Screen**  
  Display list of opportunities ranked by score. Card design: title, category, ROI, risk.  
  Effort: 2 SP | Owner: Developer + Designer | Due: Oct 15

- **WTM-92: Opportunity Detail & Action Plan**  
  Show: opportunity research, market size, similar suppliers, suggested action plan, ROI estimate.  
  Effort: 3 SP | Owner: Developer | Due: Oct 18

- **WTM-93: Opportunity Scoring (AI)**  
  Score opportunities 0-100 based on ROI potential, market trend confidence, supplier availability.  
  Effort: 3 SP | Owner: Developer | Due: Oct 20

- **WTM-94: Opportunity Action (Create Journey / Add Supplier)**  
  Quick actions: convert opportunity to journey, add suggested supplier to favorites.  
  Effort: 2 SP | Owner: Developer | Due: Oct 22

---

**Epic: REPORTS — Dashboard & KPIs**  
Status: 📋 Ready  
Description: Home dashboard showing business health at a glance (revenue, top customers, active opportunities).  
Acceptance Criteria (Epic Done):
- [ ] Dashboard shows: total revenue (MTD/YTD), top 5 customers, top products, active opportunities
- [ ] Charts are interactive (tap to drill down)
- [ ] Time period selector (MTD / YTD / custom range)
- [ ] Refresh button + auto-refresh on tab open

Stories:
- **WTM-95: Dashboard Layout & Widgets**  
  Design home dashboard with card-based KPI widgets. Use Responsive grid layout.  
  Effort: 2 SP | Owner: Developer + Designer | Due: Oct 16

- **WTM-96: Revenue KPI (MTD/YTD)**  
  Calculate total revenue for selected period. Show trend sparkline.  
  Effort: 2 SP | Owner: Developer | Due: Oct 18

- **WTM-97: Top Customers & Products Widgets**  
  Show top 5 customers by revenue, top 5 products by qty sold.  
  Effort: 2 SP | Owner: Developer | Due: Oct 20

- **WTM-98: Active Opportunities Card**  
  Show count of active opportunities + quick link to feed.  
  Effort: 1 SP | Owner: Developer | Due: Oct 21

---

**Epic: BACKUP — Data Export & Restore**  
Status: 📋 Ready  
Description: Local backup via CSV export. Users can restore data on new device.  
Acceptance Criteria (Epic Done):
- [ ] Export all data to single CSV file (downloadable)
- [ ] CSV includes: customers, inventory, suppliers, journeys, chats
- [ ] Import CSV (restore) working on new app install
- [ ] Backup file encrypted (secure storage)

Stories:
- **WTM-99: Data Export to CSV**  
  Export customers, inventory, suppliers, journeys to single ZIP with CSVs.  
  Effort: 2 SP | Owner: Developer | Due: Oct 20

- **WTM-100: Backup Encryption & Storage**  
  Encrypt backup file, store locally. User can choose cloud storage (Phase 3).  
  Effort: 1 SP | Owner: Developer | Due: Oct 22

---

**Epic: ONBOARDING — First-Time User Experience**  
Status: 📋 Ready  
Description: Guided tutorial for first-time users, with demo data to explore.  
Acceptance Criteria (Epic Done):
- [ ] Tutorial screens: app overview, core features, navigation
- [ ] Option to load demo data (sample suppliers, products, customers)
- [ ] Skip tutorial option
- [ ] Demo data can be cleared via Settings

Stories:
- **WTM-101: Onboarding Tutorial Screens**  
  4 screens: Welcome → Features Overview → Navigation → Ready to Start.  
  Effort: 2 SP | Owner: Developer + Designer | Due: Oct 18

- **WTM-102: Demo Data Loading**  
  Seed app with 20 sample suppliers, 30 sample products, 10 sample customers for exploration.  
  Effort: 2 SP | Owner: Developer | Due: Oct 20

---

### Phase 2 Closed Beta Launch (Oct 27-30)

| Activity | Owner | Status |
|---|---|---|
| Internal testing (build on real devices) | Developers + Founder | 📋 Planned |
| Firebase App Distribution setup | DevOps | 📋 Planned |
| Closed beta tester recruitment (50-100) | PM Agent | 📋 Planned |
| Release notes + known issues doc | PM Agent | 📋 Planned |
| Daily standup + bug triage | All | 📋 Planned |

---

### Phase 3: Open Beta + Refinement (Oct 20 — Nov 15, 2026)

**Status:** 📋 Planning  
**Duration:** 3-4 weeks  
**Output:** Open beta on Play Store / App Store beta track, community feedback, polish  
**Kết Quả:** Open beta trên Play Store / App Store beta track, phản hồi cộng đồng, polish

#### Phase 3 Epics (High-Level Overview)

| Epic | Count | Focus |
|---|---|---|
| FINANCE | 8 | Advanced financial tracking, profit margins, cash flow forecasting |
| ANALYTICS | 6 | Advanced KPI dashboards, trend analysis, forecasting (AI) |
| INTEGRATIONS | 10 | Shopee, Facebook, TikTok Shop, Gmail, Zapier |
| EXPORT | 4 | Advanced export (PDF reports, Google Drive sync) |
| NOTIFICATIONS | 3 | Push notifications, email alerts, webhook integrations |
| **TOTAL** | **31** | **Open beta scope** |

#### Phase 3 Story Count: ~31 stories (WTM-103+)

---

### Phase 4: Growth & Expansion (Dec 2026+)

**Status:** 📋 Roadmap  
**Duration:** Ongoing  
**Output:** New integrations, team collaboration, marketplace plugins, international expansion

#### Phase 4 Epics (High-Level Roadmap)

| Epic | Count | Focus |
|---|---|---|
| TEAM-COLLAB | 12 | Multi-user workspace, shared journeys, team analytics |
| MARKETPLACE | 8 | Plugin ecosystem, third-party apps |
| INTERNATIONAL | 6 | Language support, localization, regional integrations |
| ADVANCED-AI | 5 | ML-powered forecasting, trend prediction, anomaly detection |
| **TOTAL** | **31** | **Growth phase scope** |

#### Phase 4 Story Count: ~31 stories (WTM-134+)

---

## 📊 BACKLOG BY EPIC / BACKLOG THEO EPIC

### EPIC Definitions & Stories

| Epic Code | Epic Name | Count | Phase | Status |
|---|---|---|---|---|
| TECH-FOUNDATION | Tech Foundation (Drift, AI client, shared core) | 6 | 1C-2 | 📋 Planning |
| GOVERNANCE | Governance (Jira, decisions, roadmap) | 5 | 1C | 📋 Planning |
| DATA | Core Data Models (SQLite, schema) | 4 | 2 | 📋 Ready |
| NAV | Navigation & Routing | 3 | 2 | 📋 Ready |
| AUTH | Authentication & Onboarding | 2 | 2 | 📋 Ready |
| CORE | Shared Core Packages | 3 | 2 | 📋 Ready |
| PRODUCER | Producer Discovery & Management | 5 | 2 | 📋 Ready |
| INVENTORY | Inventory & SKU Management | 4 | 2 | 📋 Ready |
| SEARCH | Full-Text Search | 3 | 2 | 📋 Ready |
| CONSUMER | Customer CRM | 5 | 2 | 📋 Ready |
| CHAT | AI Copilot & Chat | 5 | 2 | 📋 Ready |
| CACHE | Caching & Performance | 2 | 2 | 📋 Ready |
| JOURNEY | Business Journey Orchestration | 4 | 2 | 📋 Ready |
| OPPORTUNITY | Opportunity Discovery & Engine | 4 | 2 | 📋 Ready |
| REPORTS | Dashboard & KPIs | 5 | 2 | 📋 Ready |
| BACKUP | Data Export & Restore | 2 | 2 | 📋 Ready |
| ONBOARDING | Onboarding & Tutorial | 2 | 2 | 📋 Ready |
| **PHASE 2 SUBTOTAL** | | **~63** | **2** | |
| FINANCE | Financial Tracking (Phase 3) | 8 | 3 | 📋 Planning |
| ANALYTICS | Advanced Analytics (Phase 3) | 6 | 3 | 📋 Planning |
| INTEGRATIONS | Integrations (Phase 3) | 10 | 3 | 📋 Planning |
| EXPORT | Advanced Export (Phase 3) | 4 | 3 | 📋 Planning |
| NOTIFICATIONS | Notifications & Alerts (Phase 3) | 3 | 3 | 📋 Planning |
| **PHASE 3 SUBTOTAL** | | **~31** | **3** | |
| TEAM-COLLAB | Team Collaboration (Phase 4) | 12 | 4 | 📋 Roadmap |
| MARKETPLACE | Marketplace & Plugins (Phase 4) | 8 | 4 | 📋 Roadmap |
| INTERNATIONAL | International Expansion (Phase 4) | 6 | 4 | 📋 Roadmap |
| ADVANCED-AI | Advanced AI & ML (Phase 4) | 5 | 4 | 📋 Roadmap |
| **PHASE 4 SUBTOTAL** | | **~31** | **4** | |
| **GRAND TOTAL** | | **~160** | | |

---

## 📈 STORY COUNTS & PROGRESS

| Phase | Epic Count | Story Count (Est.) | Completed | In Progress | Ready | Status |
|---|---|---|---|---|---|---|
| **1C** | 1 (GOVERNANCE) | 5 | 3 | 1 | 1 | 🔄 In Progress |
| **2** | 17 | ~63 | 0 | 0 | 63 | 📋 Ready for Dev |
| **3** | 5 | ~31 | 0 | 0 | 0 | 📋 Planning |
| **4** | 4 | ~31 | 0 | 0 | 0 | 📋 Roadmap |
| **TOTAL** | **27** | **~130** | **3** | **1** | **64** | |

---

## 🔴 HIGH-PRIORITY BLOCKING STORIES (Must Complete Before Phase 2 Dev Starts)

| Story | Epic | Impact | Owner | Due |
|---|---|---|---|---|
| WTM-47 | GOVERNANCE | Unblocks D-1, D-2 decision gate for tech decisions | Founder | Aug 5 |
| WTM-48 | GOVERNANCE | Phase 1 completion report, Go/No-Go to Phase 2 | PM Agent | Aug 2 |
| WTM-49 | GOVERNANCE | Create all 50+ Phase 2/3 Jira stories | PM Agent | Aug 2 |
| WTM-46 | TECH-FOUNDATION | Fit-gap analysis, Hub reuse validation | Developer | Jul 25 |

---

## 🟡 BLOCKED STORIES (Waiting for Decisions or Dependencies)

| Story | Epic | Blocker | Unblock Date |
|---|---|---|---|
| WTM-49 | GOVERNANCE | Awaiting Phase 1C decision gate (WTM-47) | Aug 5 |
| WTM-50-102 | PHASE-2 | Awaiting WTM-49 Jira creation | Aug 2 |

---

## 📝 BACKLOG GROOMING NOTES

### Known Issues & Gaps

1. **Phase 3 Stories Not Yet Detailed**  
   - Finance, Analytics, Integrations epics are placeholder counts
   - Detailed specs pending Phase 2 feedback and Founder input
   - Estimated: Aug 15 (after Phase 2 sprint 1 starts)

2. **Phase 4 Roadmap (Growth) is Founder-Driven**  
   - Story details will emerge from founder feedback + user testing
   - Currently placeholder counts based on typical SaaS growth roadmap
   - Estimated: Sep 2026 (after Phase 2 closed beta results)

3. **API Integration Stories (Shopee, Facebook, TikTok)**  
   - WTM-67, WTM-79: Dependent on API access + rate limit handling
   - Fallback: Manual entry if API integration slips
   - Risk: Medium (APIs subject to rate limits, auth complexity)

4. **AI Scoring & Opportunity Engine Stories (WTM-66, WTM-93)**  
   - Dependent on xAI API quotas + Claude API (for planning)
   - BYOK strategy mitigates cost risk (user provides API key)
   - Risk: Low (fallback: simpler rule-based scoring if AI unavailable)

5. **Offline-First Validation (WTM-54, WTM-86)**  
   - Sync conflict resolution strategy still TBD in Phase 2 Sprint 3
   - Phase 3 will add optional cloud sync (decision D-5: Backend scope)
   - Risk: Low (MVP is local-only, sync is Phase 3+)

### Tech Debt & Future Refactoring

- **Drift Schema Migrations:** WTM-52 V1 only; plan V2-V3 for Phase 3 (new fields as features ship)
- **Component Library Stability:** WTM-62 imports from Hub; Hub changes may require backports. Plan quarterly sync.
- **Search Index Performance:** WTM-72-74 FTS5 baseline; if >1000 SKUs, consider Meilisearch fork to app (Phase 4 scalability).
- **AI Prompt Engineering:** WTM-88, WTM-93 use simple templates; Phase 3+ will refactor to prompt engineering framework (e.g., LLM routing library).

### Story Refinement Checklist (Before Sprint Start)

Before each sprint starts, stories must pass:

- [ ] Acceptance criteria bilingual (EN + VI)
- [ ] Related documentation linked (screen spec, architecture doc)
- [ ] Effort estimate confirmed by developer
- [ ] Dependencies identified (blockers, related stories)
- [ ] Design assets available (Figma, wireframes, or clear description)
- [ ] Risk assessment documented (if effort > 4 SP or complex)
- [ ] Definition of Done agreed (code review, tests, build, device test)

---

## 🔗 RELATED DOCUMENTS

**Phase Planning:**
- [ROADMAP.md](ROADMAP.md) — 4-phase roadmap with timelines
- [OPEN-DECISIONS.md](OPEN-DECISIONS.md) — 10 decisions pending Founder approval

**Specifications:**
- [SCREEN-*.md](.) — Individual screen specs (Home, Producer, Inventory, Consumer, Chat, Reports, etc.)
- [DOMAIN-DATA-MODEL.md](DOMAIN-DATA-MODEL.md) — Entity relationships, constraints
- [COMPONENT-LIBRARY.md](COMPONENT-LIBRARY.md) — UI component specs

**Architecture:**
- [REUSE-ASSESSMENT.md](REUSE-ASSESSMENT.md) — Hub code reuse evaluation
- Various ARCHITECTURE docs in tech/ subfolder

**Status:**
- [PHASE-1B-EXECUTION-REPORT.md](PHASE-1B-EXECUTION-REPORT.md) — Phase 1B completion report
- [PHASE-1-REPORT.md](PHASE-1-REPORT.md) — Earlier Phase 1A report

---

## 📅 SPRINT PLANNING REFERENCE

### Phase 2 Sprint Duration & Dates

| Sprint | Start | End | Focus | Stories |
|---|---|---|---|---|
| Sprint 1 | Sep 1 | Sep 14 | Data + Navigation + Auth + Core | WTM-51 to WTM-62 |
| Sprint 2 | Sep 15 | Sep 28 | Producer + Inventory + Search | WTM-63 to WTM-74 |
| Sprint 3 | Sep 29 | Oct 12 | Consumer + Chat + Cache | WTM-75 to WTM-86 |
| Sprint 4 | Oct 13 | Oct 26 | Journey + Opportunity + Reports + Backup + Onboarding | WTM-87 to WTM-102 |

### Effort Capacity Assumption

- **Team:** 2 Developers (10 SP/week each = 20 SP/sprint)
- **Sprint 1:** 12 stories, ~20 SP ✅ Fits
- **Sprint 2:** 12 stories, ~21 SP ⚠️ Tight (consider parallelizing API work)
- **Sprint 3:** 12 stories, ~18 SP ✅ Fits
- **Sprint 4:** 16 stories, ~22 SP ⚠️ Consider splitting into 8+8

**Recommendation:** Adjust story counts after Phase 2 Sprint 1 velocity is known. This is a **planning estimate**, not a commitment.

---

## 🎯 SUCCESS CRITERIA (Phase 1C Complete)

✅ Phase 1C is DONE when:

1. ✅ PRODUCT-BACKLOG.md created and published
2. ✅ 50+ Phase 2/3 Jira stories created (WTM-50+)
3. ✅ All stories linked to acceptance criteria docs
4. ✅ Story points estimated
5. ✅ Phase 2 sprint plan finalized + team briefed
6. ✅ Open decisions (D-1, D-2, tech stack) resolved by Founder
7. ✅ Confluence team hub updated with backlog link
8. ✅ Phase 2 ready to start Sep 1

---

**Last Updated:** 2026-07-13  
**Next Review:** 2026-07-20 (Phase 1C progress update)  
**Document Owner:** PM Agent  
**Approval Gate:** Founder (before Phase 2 start)
