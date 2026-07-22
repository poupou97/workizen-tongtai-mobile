# Component Audit & Inventory

## Kiểm Toán & Kho Thành Phần Giao Diện

---

## English — Complete Component Audit

**Purpose:** This document audits all UI components across the 25 concept images, identifies reusable patterns, and tracks implementation status.

---

## Component Summary

**Total Components Identified:** 18 core component types  
**Reusable Components:** 14 (77%)  
**Custom Components:** 4 (23%)  
**Total Usage Instances:** 120+ across 25 screens

---

## Core Component Inventory

### 1. Card Component

**Usage:** Very High (60+ instances)  
**Description:** Main content container for all business data.

| Screen | Usage | Variant |
|---|---|---|
| Home (SC-6) | 4 | Module cards, stats cards |
| Producer (SC-7) | 8 | Opportunity cards, supplier summary |
| Inventory (SC-8) | 6 | Product cards, summary cards |
| Consumer (SC-9) | 7 | Customer cards, segment cards |
| Finance (SC-10) | 5 | Transaction cards, account cards |
| Reports (SC-11) | 4 | KPI cards, metric cards |
| Journey (SC-12) | 3 | Milestone cards, step cards |
| Opportunity Hub (SC-13) | 8 | Opportunity cards (primary) |
| AI Copilot (SC-14) | 4 | Recommendation cards, alert cards |

**Variants:**
- Metric Card (number + trend + status)
- Opportunity Card (image + title + profit + score)
- Customer Card (avatar + name + tier + LTV)
- Summary Card (total + breakdown + chart)

**Status:** ✅ Built (reusable across all modules)

---

### 2. Bottom Navigation Tab

**Usage:** Very High (1 instance, always present)  
**Description:** Primary navigation bar with 5 tabs.

| Tab | Icon | Color | Screen Target |
|---|---|---|---|
| Home | 🏠 | Teal (#00C9A7) | SC-6 |
| Producer | 🌱 | Green (#4CAF50) | SC-7 |
| Inventory | 📦 | Orange (#FF9800) | SC-8 |
| Consumer | 👥 | Blue (#2196F3) | SC-9 |
| More | ⋯ | Gray (#757575) | Menu |

**Status:** ✅ Built (core navigation)

---

### 3. Horizontal Tab Bar

**Usage:** High (12 instances)  
**Description:** Secondary navigation within modules.

| Module | Tab Bar | Tab Count |
|---|---|---|
| Producer | Opportunity, Supplier, Research, Trend, Arbitrage, Cross-border, Discovery | 7 |
| Inventory | Products, Categories, SKU, Warehouse, Stock In/Out, Pricing, Documents | 7 |
| Consumer | CRM, CDP, Channels, Orders, Inbox, Reviews, Affiliate, Community, Segments | 9 |
| Finance | Revenue, Expenses, Profit, Cash Flow, Accounts, Transactions, Reports | 7 |
| Reports | KPI, Channel Breakdown, Trend Analysis, AI Insights | 4 |
| Product Detail | Overview, Details, Stock, Pricing, Sales Channels, Analytics | 6 |
| Supplier Detail | Overview, Details, Products, Reviews | 4 |

**Variants:**
- Scrollable tab bar (when > 5 tabs)
- Fixed tab bar (for 3-5 tabs)
- Tab indicator (underline or pill background)

**Status:** ✅ Built (reusable, highly used)

---

### 4. Chart/Graph Component

**Usage:** High (25+ instances)  
**Description:** Visualizations for trends, breakdowns, and metrics.

| Chart Type | Screens | Count |
|---|---|---|
| Line Chart (trend over time) | Reports, Finance, Journey, Product Detail | 8 |
| Pie Chart (breakdown) | Home, Inventory, Consumer, Reports | 6 |
| Bar Chart (comparison) | Reports, Finance, Consumer | 5 |
| Sparkline (inline trend) | Cards in Home, Producer, Consumer | 8+ |
| Progress Bar (journey progress, stock) | Journey, Inventory, Opportunity | 4 |

**Status:** ✅ Built (use Fl Charts or similar library)

---

### 5. Chip/Badge Component

**Usage:** High (40+ instances)  
**Description:** Status indicators, categories, tags.

| Type | Usage | Examples |
|---|---|---|
| Status Badge | Product list, journey steps, orders | "ACTIVE", "PENDING", "COMPLETED" |
| Category Chip | Filter options, product categories | "Apparel", "Electronics", "Food" |
| Opportunity Type Badge | Opportunity cards | "ARBITRAGE", "TREND", "CROSS-BORDER" |
| Tier Badge | Customer cards | "BRONZE", "SILVER", "GOLD", "PLATINUM" |
| AI Badge | AI-powered features | "🧠 AI", "✨ Recommended" |

**Status:** ✅ Built (reusable, many variants)

---

### 6. List Component

**Usage:** High (15+ instances)  
**Description:** Displays sets of items (products, customers, suppliers, etc.).

| List Type | Screens | Features |
|---|---|---|
| Product List | Inventory, Category Detail | Sortable, filterable, selection |
| Supplier List | Producer | Sortable, filterable, rating display |
| Customer List | Consumer/CRM | Sortable, filterable, segment display |
| Order List | Consumer/Orders | Sortable, filterable, status display |
| Opportunity List | Opportunity Hub | Ranked by score, saveable |
| Transaction List | Finance | Sortable, filterable, categorized |
| Journey Step List | Journey | Sequential, status indicators |

**Variants:**
- Simple list (text + optional icon)
- Rich list (image + title + subtitle + metadata)
- Expandable list (collapse/expand rows)

**Status:** ✅ Built (very common, reusable)

---

### 7. Button Component

**Usage:** Very High (50+ instances)  
**Description:** Primary, secondary, and action buttons.

| Button Type | Color | Usage |
|---|---|---|
| Primary Button | Module color (teal, green, etc.) | "Save", "Create", "Pursue", "Send" |
| Secondary Button | Light gray | "Cancel", "Skip", "Edit", "More" |
| Danger Button | Red | "Delete", "Archive", "Cancel Order" |
| Ghost Button | Outline only | "Learn more", "View details" |
| Floating Action | Module color | "+ New product", "+ Add supplier" |
| Icon Button | Module color | Quick actions (share, edit, delete) |

**Status:** ✅ Built (standard Flutter button styles)

---

### 8. Text Input & Form Field

**Usage:** High (20+ instances)  
**Description:** User input for creating/editing items.

| Field Type | Used In | Examples |
|---|---|---|
| Text Input | Product name, supplier name, search | Name, title, description |
| Number Input | Pricing, quantity, investment | Cost, price, quantity, investment amount |
| Date Picker | Orders, journey timeline | Order date, step date |
| Dropdown Select | Category, status, segment | Category dropdown, status select |
| Text Area | Description, notes | Product description, customer notes |
| Currency Input | Pricing, finance | Price, revenue, expense amount |

**Status:** ✅ Built (standard Flutter form widgets)

---

### 9. Image Component

**Usage:** High (30+ instances)  
**Description:** Product images, supplier logos, customer avatars.

| Image Type | Screens | Usage |
|---|---|---|
| Product Image | Inventory, Product Detail, Opportunity | 15+ instances |
| Supplier Logo | Producer, Supplier List/Detail | 5+ instances |
| Customer Avatar | Consumer, Customer Detail | 8+ instances |
| Chart/Graph Image | Reports, Analytics screens | 6+ instances |
| Brand Mascot | Home, Journey, AI Copilot | 4 instances |

**Handling:**
- Placeholder while loading
- Fallback icon if no image
- Lightbox/zoom on tap
- Upload/change capability in edit modals

**Status:** ✅ Built (image loading libraries)

---

### 10. Avatar Component

**Usage:** Medium (12+ instances)  
**Description:** Profile pictures for users, customers, suppliers.

| Avatar Type | Screens | Size |
|---|---|---|
| User Avatar | Profile, Home greeting | 48px, 64px |
| Customer Avatar | Customer List, Customer Detail | 40px |
| Supplier Logo | Supplier List, Supplier Detail | 48px |
| Team Member | Supplier Detail (team section) | 32px |

**Variants:**
- Circular avatar (default)
- Initials (when no image)
- Placeholder icon (default)
- Border/badge (status indicator)

**Status:** ✅ Built (reusable avatar component)

---

### 11. Modal/Dialog Component

**Usage:** Medium (8-10 usage patterns)  
**Description:** Overlays for forms, confirmations, and menus.

| Modal Type | Screens | Purpose |
|---|---|---|
| Form Modal | All modules | Create/edit items (product, customer, etc.) |
| Confirmation Modal | All modules | "Delete?", "Archive?", confirmation |
| Error Modal | All modules | Display error messages |
| Success Modal | All modules | Confirmation after action |
| Bottom Sheet | Producer, Consumer | Filters, quick actions |
| Full-Screen Modal | Modals with complex forms | Journey creation, campaign builder |

**Status:** ✅ Built (Flutter showDialog, showModalBottomSheet)

---

### 12. Header/AppBar Component

**Usage:** Very High (all screens)  
**Description:** Top navigation and screen title.

| Header Type | Elements |
|---|---|
| Simple Header | Title, back button |
| Header with Search | Title, search icon, back button |
| Header with Tabs | Title, horizontal tabs, back button |
| Header with Actions | Title, action buttons (menu, more), back button |

**Status:** ✅ Built (Flutter AppBar)

---

### 13. Floating Action Button (FAB)

**Usage:** High (10+ instances)  
**Description:** Quick actions for creating items.

| Screen | FAB Action | Color |
|---|---|---|
| Inventory | "+ New Product" | Orange (Inventory color) |
| Producer | "+ Add Supplier" | Green (Producer color) |
| Consumer | "+ Add Customer" | Blue (Consumer color) |
| Journey | "+ New Journey" | Purple (Journey color) |
| Opportunity | "Save opportunity" | Green (save action) |

**Status:** ✅ Built (Flutter FloatingActionButton)

---

### 14. Search Bar Component

**Usage:** Medium (6+ instances)  
**Description:** Input for searching items within a module.

| Search Type | Screens | Searches |
|---|---|---|
| Product Search | Inventory, Producer (Research) | By name, SKU, category |
| Supplier Search | Producer | By name, country, category |
| Customer Search | Consumer/CRM | By name, email, phone |
| Global Search | Header (all screens) | Across all data types |
| Opportunity Search | Opportunity Hub | By title, type, market |

**Status:** ✅ Built (text field with icon)

---

### 15. Filter & Sort Controls

**Usage:** High (10+ instances)  
**Description:** Filtering and sorting UI for lists.

| Control Type | Screens | Options |
|---|---|---|
| Filter Chips | Producer, Inventory, Consumer, Reports | Category, status, tier, type |
| Sort Dropdown | All list screens | By name, date, value, score |
| Date Range Picker | Finance, Reports, Orders | Custom date filtering |
| Multi-Select Checkbox | Segments, bulk actions | Select multiple items |

**Status:** ✅ Built (custom filter UI)

---

### 16. Alert/Notification Banner

**Usage:** Medium (8+ instances)  
**Description:** In-app alerts for stocks, opportunities, risks.

| Alert Type | Screens | Content |
|---|---|---|
| Info Alert | Home, Producer | "New opportunity available", "AI insight" |
| Warning Alert | Inventory, Finance | "Low stock warning", "Cash flow alert" |
| Success Alert | All modules | "Product created", "Order shipped" |
| Error Alert | All modules | "Failed to save", "Network error" |

**Status:** ✅ Built (SnackBar, banner widgets)

---

### 17. Card with Expandable Content

**Usage:** Medium (6-8 instances)  
**Description:** Cards that expand to show more details.

| Expandable Card | Screens | Expands To Show |
|---|---|---|
| Opportunity Card | Opportunity Hub | Full description, suppliers, ROI analysis |
| Customer Card | Consumer | Purchase history, segment info, LTV |
| Product Card | Inventory | Variants, pricing, stock details |
| Supplier Card | Producer | Capabilities, products, reviews |

**Status:** ✅ Built (custom expandable card)

---

### 18. AI Recommendation/Insight Widget

**Usage:** Medium (8+ instances)  
**Description:** Special cards highlighting AI insights.

| Widget Type | Screens | Content |
|---|---|---|
| Recommendation Card | Producer, Copilot, Opportunity | "Try this opportunity", "Next step" |
| Insight Card | Reports, Copilot | "Revenue is up 15%", "Churn risk detected" |
| Suggestion Pill | Various | Quick-access action pills |
| AI Badge | Cards, buttons | Marks AI-powered features with 🧠 icon |

**Status:** ✅ Built (custom recommendation widget)

---

## Component Usage Matrix

### By Screen

| Screen | Card | Tab | Chart | Chip | List | Button | FAB | Other |
|---|---|---|---|---|---|---|---|---|
| Home (SC-6) | 8 | — | 2 | 4 | — | 4 | — | Alert banner, summary |
| Producer (SC-7) | 8 | 7 | 1 | 6 | 2 | 4 | 1 | AI sidebar, search |
| Inventory (SC-8) | 6 | 7 | 1 | 8 | 4 | 5 | 1 | Summary, alerts |
| Consumer (SC-9) | 7 | 9 | 1 | 6 | 4 | 6 | 1 | Avatar, filter |
| Finance (SC-10) | 5 | 7 | 4 | 4 | 3 | 4 | — | Account list |
| Reports (SC-11) | 4 | 4 | 8 | 2 | 2 | 2 | — | Insights, alerts |
| Journey (SC-12) | 3 | — | 1 | 3 | 1 | 3 | 1 | Timeline, progress bar |
| Opportunity (SC-13) | 8 | — | — | 4 | 1 | 2 | — | Search, filter |
| AI Copilot (SC-14) | 4 | — | — | 2 | 1 | 2 | — | Chat bubble, avatar |
| Details (SC-15, 16) | 6 | 6 | 2 | 4 | 2 | 3 | — | Hero section, related |

---

## Custom Components (Not Standard)

### 1. Opportunity Card (Custom)

**Purpose:** Specialized card for showing opportunities.  
**Screens:** Opportunity Hub (SC-13), Producer (SC-7)  
**Elements:**
- Product image/icon (left)
- Title + market (center)
- Profit estimate + trend arrow
- AI score (0-100)
- Save/follow button

**Rationale:** Standard card doesn't have enough space for opportunity-specific layout.

**Status:** 🔄 To-do (needs implementation)

---

### 2. AI Copilot Chat Bubble (Custom)

**Purpose:** Specialized component for chat messages.  
**Screens:** AI Copilot (SC-14), in-journey guidance  
**Elements:**
- Message text (left/right based on sender)
- Sender avatar
- Timestamp
- Action buttons (e.g., "Learn more", "Accept recommendation")

**Rationale:** Standard message list doesn't support AI-specific interactions.

**Status:** 🔄 To-do (needs implementation)

---

### 3. Journey Timeline Widget (Custom)

**Purpose:** Visual representation of journey steps.  
**Screens:** Business Journey (SC-12)  
**Elements:**
- Vertical timeline (step sequence)
- Step circle (status indicator: completed, in-progress, pending, blocked)
- Step title + date
- Connected lines between steps

**Rationale:** Standard list view doesn't convey sequential progress visually.

**Status:** 🔄 To-do (needs implementation)

---

### 4. Smart Metric Card (Custom)

**Purpose:** Displays metric with trend and status.  
**Screens:** Home, Reports, Finance (used 15+ times)  
**Elements:**
- Metric name (top left)
- Large number (center)
- Trend indicator (↑ green or ↓ red)
- Percentage change (e.g., "+15%")
- Status color (green/red/yellow based on performance)

**Rationale:** Standard card needs special styling for metrics.

**Status:** ✅ Built (high reuse)

---

## Implementation Status Summary

| Component Type | Status | Priority | Notes |
|---|---|---|---|
| Card | ✅ Built | P0 | Highly reusable, foundation |
| Bottom Navigation | ✅ Built | P0 | Core navigation |
| Horizontal Tab Bar | ✅ Built | P0 | Module navigation |
| Chart/Graph | ✅ Built | P1 | Use Fl Charts lib |
| Chip/Badge | ✅ Built | P0 | Small elements |
| List | ✅ Built | P0 | Core data display |
| Button | ✅ Built | P0 | Standard Flutter |
| Form Field | ✅ Built | P0 | Standard Flutter |
| Image | ✅ Built | P0 | With placeholders |
| Avatar | ✅ Built | P1 | User/customer profiles |
| Modal/Dialog | ✅ Built | P1 | Flutter showDialog |
| Header/AppBar | ✅ Built | P0 | Standard Flutter |
| FAB | ✅ Built | P1 | Create actions |
| Search Bar | ✅ Built | P1 | Filter lists |
| Filter & Sort | ✅ Built | P1 | List controls |
| Alert Banner | ✅ Built | P1 | Notifications |
| Expandable Card | 🔄 To-do | P2 | Drill-down UX |
| AI Insight Widget | 🔄 To-do | P1 | AI recommendations |
| **Custom: Opportunity Card** | 🔄 To-do | P0 | Unique to Tổng Tài |
| **Custom: Chat Bubble** | 🔄 To-do | P1 | AI Copilot feature |
| **Custom: Timeline Widget** | 🔄 To-do | P1 | Journey visualization |
| **Custom: Metric Card** | ✅ Built | P0 | Reused across modules |

---

## Design System Consistency

**All components must follow:**

1. **Color Palette** (from DESIGN-TOKENS.md)
   - Primary colors by module (teal, green, orange, blue)
   - Grayscale for text/backgrounds
   - Status colors (green=success, red=error, yellow=warning)

2. **Typography**
   - Headlines: Inter Bold, 18-24px
   - Body: Inter Regular, 14-16px
   - Captions: Inter Regular, 12-14px

3. **Spacing**
   - 8px base unit
   - Margins: 8, 16, 24px
   - Padding: 8, 12, 16px

4. **Border Radius**
   - Cards: 8-12px
   - Buttons: 4-8px
   - Modals: 12-16px

5. **Shadows**
   - Elevated cards: shadow 2
   - Modals: shadow 8
   - Buttons: no shadow (flat design)

---

## Performance Considerations

| Component | Performance Impact | Optimization |
|---|---|---|
| List (100+ items) | High | Lazy load, virtual scrolling |
| Chart (real-time updates) | Medium | Debounce updates, cache data |
| Image (10+ per screen) | Medium | Lazy load, cache in memory |
| Modal with form | Low | Lazy load modal content |
| Search (instant results) | Medium | Debounce search, limit results |

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B  
**Date:** 2026-07-13  
**Related Docs:** DESIGN-SYSTEM-DRAFT.md, COMPONENT-LIBRARY.md, DESIGN-TOKENS.md  
**Next:** USER-JOURNEYS.md
