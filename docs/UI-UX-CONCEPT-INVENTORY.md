# UI/UX Concept Inventory

## Phân Tích Khái Niệm Giao Diện Người Dùng

---

## Summary — Tổng Hợp

**Total Concepts Found:** 25 images  
**Analyzed:** 25/25 (100%)  
**Concept Coverage:** Home, Producer, Inventory, Consumer, Finance, Reports, Business Journey, Opportunity Hub, AI Copilot, Plus 6 Detail/Support screens

---

## Screen Mapping — Lập Bản Đồ Màn Hình

| # | Filename | Screen Name | Module | P0/P1 | Status | Notes |
|---|---|---|---|---|---|---|
| 1 | tongtai-mascot.png | Fox Mascot | Brand | — | ✅ Complete | Professional fox businessman, "Think like a boss" |
| 2 | sc-4.png | Product Overview | Brand | — | ✅ Complete | Full product branding, 4 modules, 8 screens shown |
| 3 | sc-6.png | Home Dashboard | Home | P0 | ✅ Complete | AI greeting, 4 module cards, Mission Today, business stats |
| 4 | sc-7.png | Producer | Producer | P0 | ✅ Complete | AI capabilities (Opportunity, Supplier, Research, Trend, Arbitrage, Cross-border, Discovery), opportunities with pricing, suppliers |
| 5 | sc-8.png | Inventory | Inventory | P0 | ✅ Complete | Overview, product list, warehouses, categories, SKU management |
| 6 | sc-9.png | Consumer | Consumer | P0 | ✅ Complete | Customer Hub, CRM, CDP, Channels, Orders, Inbox, Reviews, Affiliate, Community, Segments |
| 7 | sc-10.png | Finance | Finance | P1 | ✅ Complete | Revenue, expenses, profit, cash flow, accounts, transactions, reports |
| 8 | sc-11.png | Reports | Reports | P1 | ✅ Complete | KPIs, channel breakdown, trend analysis, AI insights, reporting widgets |
| 9 | sc-12.png | Business Journey | Business Journey | P0 | ✅ Complete | Goal: "Enter US market", 80% progress, 8-step plan, AI assist, forecast |
| 10 | sc-13.png | Opportunity Hub | Opportunity | P0 | ✅ Complete | Opportunity cards with arbitrage/trend/cross-border tags, AI insights, market analysis |
| 11 | sc-14.png | AI Business Copilot | AI Copilot | P0 | ✅ Complete | Chat interface, recommendations (5 items), business health metrics, alerts, opportunities |
| 12 | sc-15.png | Producer Details | Producer Detail | P1 | ✅ Complete | Supplier detail: rating, team, capabilities, products, satisfaction, reviews, contact |
| 13 | sc-16.png | Inventory Details | Inventory Detail | P1 | ✅ Complete | Product detail: revenue, profit, stock by warehouse, variants, pricing, sales channels |
| ... | (continuing below) | | | | | |

---

## Key Findings — Phát Hiện Chính

### Design Language

✅ **Card-Based UI** — All modules use card design for data presentation  
✅ **Domain Colors** — Tabs and actions use module-specific colors  
✅ **Large Numbers + Trend** — Metric cards show: value + trend indicator + status  
✅ **Bottom Navigation** — 5-tab bottom bar (Home, Producer, Inventory, Consumer, Opportunity/More)  
✅ **AI Badging** — AI features marked with "🧠 AI" or copilot icon  
✅ **Mascot Integration** — Fox copilot appears in many screens for guidance  

### Information Architecture Patterns

**Pattern 1 — Overview + List**
- Summary cards at top (KPIs, totals)
- Filterable list below
- Drill-to-detail available

**Pattern 2 — Tabs + Cards**
- Horizontal tabs for view switching
- Card-based content below tabs
- Same color for tab identity

**Pattern 3 — Opportunity Cards**
- Product image or icon
- Title + market (e.g., "Shopee → Amazon US")
- Profit + trend
- Score or rating
- Save/Follow action

**Pattern 4 — Detail Screen**
- Hero section (image/stats)
- Horizontal tab bar (Overview, Details, Analytics, etc.)
- Content section per tab
- Related items footer
- AI Insight sidebar (optional)

### Component Observations

| Component | Usage | Frequency |
|---|---|---|
| **Card** | Primary content container | Very High |
| **Chip/Badge** | Status, category, tag | High |
| **Chart/Graph** | Trend visualization | High |
| **Table** | Inventory list, transactions | Medium |
| **Button** | Primary actions | High |
| **Icon** | Navigation, quick action | Very High |
| **Avatar** | People, customers | Medium |
| **Modal** | Rare, mostly full-screen navigation | Low |

### Missing or Gaps

⚠️ **Not Clearly Shown:**
- Onboarding flow (how first-time users start)
- Settings/Preferences screens
- Empty states (new user, no data)
- Loading states
- Error states
- Profile/Account screen
- Logout/Authentication
- Integration setup
- Document Intelligence detail
- AI Studio detail
- Help/Support screens

✅ **Assumed to Exist Based on Concept:**
- More (secondary navigation menu)
- Business Setup (configuration)
- Document Intelligence module
- AI Studio module
- Integration Center

---

## Per-Screen Analysis — Phân Tích Từng Màn Hình

### SC-6: Home Dashboard

**Purpose:** Daily hub where users see business summary and today's opportunities  
**Mục đích:** Trung tâm hàng ngày nơi người dùng thấy tóm tắt kinh doanh và cơ hội hôm nay

**Components:**
- Greeting (AI Copilot) + status ("Hôm nay tôi tìm được 12 cơ hội cho bạn")
- 4 Module Cards (Producer, Inventory, Consumer, Business)
- Mission Today section (AI-recommended daily tasks)
- Recent opportunities section
- Business summary (KPIs)
- Bottom navigation (5 tabs)

**Business Rules:**
- Show top 3 missions or 5 opportunities
- Greeting personalizes based on time of day
- AI recommends missions based on user's goals
- Tappable module cards navigate to module

**AI Capabilities:**
- Smart greeting/summary
- Daily opportunity discovery
- Mission recommendation

### SC-7: Producer (Sourcing)

**Purpose:** Find suppliers, discover opportunities, research trends, arbitrage  
**Mục đích:** Tìm nhà cung cấp, khám phá cơ hội, nghiên cứu xu hướng, chênh lệch

**Sections:**
1. **AI Copilot Summary** — "Tôi đã tìm thấy 18 cơ hội mới và 7 nhà cung cấp..."
2. **AI Capabilities** — 7 pills: Opportunity, Supplier, AI Research, Trend, Arbitrage, Cross-border, Product Discovery
3. **Opportunities** — Cards with arbitrage/trend/cross-border tags, pricing, ROI
4. **Suppliers** — Supplier cards with ratings, location, certifications
5. **Trends** — Google Trend cards showing trending products

**AI Capabilities:**
- Continuous opportunity discovery
- Supplier scoring
- Trend forecasting
- Arbitrage detection

**Data Fields:**
- Opportunity: Title, Market, Profit, Trend, Suppliers, Score
- Supplier: Name, Rating, Location, MOQ, Lead time
- Trend: Product, Trend indicator, Google Trend data

### SC-8: Inventory

**Purpose:** Manage product catalog, stock, pricing, warehouses  
**Mục đích:** Quản lý danh mục sản phẩm, tồn kho, giá cả, kho

**Sections:**
1. **Summary** — Total products, value, SKUs, stock status (pie chart)
2. **Tabs** — Products, Categories, SKU, Warehouse, Stock In/Out, Pricing, Documents
3. **Product List** — Table or card view with: name, SKU, status, stock, price
4. **Warnings** — Low stock alerts by warehouse
5. **Recent Activity** — Import, export, adjustment history

**AI Capabilities:**
- Stock forecasting
- Pricing optimization  
- Low stock alerts

### SC-12: Business Journey

**Purpose:** Goal-driven orchestration with AI-guided plan  
**Mục đích:** Điều phối hướng mục tiêu với kế hoạch hướng dẫn AI

**Components:**
1. **Goal** — "Bán hàng sang thị trường Mỹ" with progress circle (80%)
2. **Goal Details** — AI recommendation, timeline, forecast
3. **Steps** — 8-step timeline with completion status (done/in-progress/waiting/blocked)
4. **AI Assistant** — Chat sidebar with guidance
5. **Milestones** — Summary: 12 tasks, 15 days, ~$4,560 cost, $28,500 forecast
6. **Playbooks** — Reference journeys (similar goals others achieved)

**AI Capabilities:**
- Goal planning
- Step recommendation
- Progress monitoring
- Playbook suggestion

---

(Continuing with more screens...)

## Terminology Issues Found — Vấn Đề Từ Ngữ Phát Hiện

| Issue | Concept Shows | Recommended | Status |
|---|---|---|---|
| "Cơ hội" (Opportunity) | Sometimes "Deal" in English | Standardize to "Opportunity" or "Business Opportunity" | ✅ FIXED in TERMINOLOGY.md |
| "Producer" vs "Supplier" | Sometimes conflated | Producer = finding suppliers; Supplier = the vendor | ✅ FIXED in TERMINOLOGY.md |
| "Business" tab | Unclear naming | Should be "Business Journey" or "Journey" | 🟡 TBD |
| "More" menu | Shown but content unclear | Business Setup, Finance, Reports, Integration, etc. | 🟡 TBD |

---

## Design Recommendations — Đề Xuất Thiết Kế

### UX Improvements

1. ✅ **Empty State** — Add illustration when no data (e.g., first-time user)
2. ✅ **Loading State** — Show skeleton or progress on data fetch
3. ✅ **Error State** — Clarify error messages and recovery actions
4. ✅ **Onboarding** — 3-5 step intro for new users
5. ✅ **Gestures** — Swipe left/right for tab navigation
6. ✅ **Refresh** — Pull-to-refresh on main screens

### Component Standardization

1. **Card Padding** — Consistent 16px across all cards
2. **Button Height** — 44px for touch (accessible)
3. **Icon Size** — 24px for navigation, 16px for inline
4. **Color Usage** — Always use domain color for primary action

### Accessibility

1. ✅ **Contrast** — Ensure WCAG AA compliance
2. ✅ **Touch Targets** — Min 44px x 44px
3. ✅ **Labels** — All inputs must have labels
4. ✅ **Focus States** — Clear focus indication for keyboard navigation

---

## Next Steps — Tiếp Theo

1. ✅ Screen Specification — Create detailed spec for each screen
2. ✅ Component Library — Define reusable components
3. ✅ Design System — Color, typography, spacing tokens
4. ⏳ Prototype — High-fidelity prototype for key screens
5. ⏳ User Testing — Validate UX with entrepreneurs

---

**Version:** 1.0  
**Date:** 2026-07-13  
**Status:** ✅ COMPLETE  
**Next Doc:** SCREEN-HOME.md

