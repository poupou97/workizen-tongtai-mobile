# Navigation Map

## Bản Đồ Điều Hướng

---

## English — Complete Navigation Hierarchy

**Purpose:** This document defines the complete navigation structure of Tổng Tài, including primary, secondary, tertiary navigation, and deep linking strategy.

---

## Primary Navigation — Bottom Tab Bar

The main entry point to all major capabilities. Visible on every screen except modals and detail views.

```
┌────────────────────────────────────────────────────────┐
│  Screen Content                                        │
├────────────────────────────────────────────────────────┤
│  🏠 Home  │  🌱 Producer  │  📦 Inventory  │  👥 Consumer  │  ⋯ More  │
└────────────────────────────────────────────────────────┘

Tab 1: Home (Teal #00C9A7)
Tab 2: Producer (Green #4CAF50)
Tab 3: Inventory (Orange #FF9800)
Tab 4: Consumer (Blue #2196F3)
Tab 5: More (Gray #757575)
```

### Primary Tab Definitions

| Tab | Icon | Color | Screen | Purpose |
|---|---|---|---|---|
| **Home** | 🏠 | Teal | SC-6 | Dashboard, overview, quick access |
| **Producer** | 🌱 | Green | SC-7 | Sourcing, suppliers, opportunities |
| **Inventory** | 📦 | Orange | SC-8 | Products, warehouses, stock |
| **Consumer** | 👥 | Blue | SC-9 | Customers, orders, segments |
| **More** | ⋯ | Gray | Menu | Secondary features (Finance, Reports, Journey, Chat, Settings) |

---

## Secondary Navigation — Module-Level Structure

### 1. Home Module (SC-6)

**Purpose:** Dashboard and entry point to all capabilities.

```
HOME Dashboard
├─ AI Greeting section
│  ├─ Greeting message ("Good morning, Phương!")
│  └─ Business health score
├─ 4 Module Quick-Access Cards (tap to navigate)
│  ├─ Producer card → go to Producer module
│  ├─ Inventory card → go to Inventory module
│  ├─ Consumer card → go to Consumer module
│  └─ Finance card → go to Finance module
├─ Mission Today section
│  ├─ Current Journey progress
│  ├─ Daily tasks (from active journey)
│  └─ Tap to go to Journey detail
├─ Recent Opportunities section
│  ├─ Last 3 opportunities
│  └─ Tap to go to Opportunity Hub
└─ Shortcuts (tap for quick actions)
   ├─ Add product
   ├─ Add customer
   ├─ Create journey
   └─ View reports
```

**Navigation Rules:**
- Tapping any card/section jumps to related module
- Does NOT include back navigation (home is destination)

---

### 2. Producer Module (SC-7)

**Purpose:** Sourcing and opportunity discovery hub.

```
PRODUCER Hub
├─ Horizontal Capability Tabs (top)
│  ├─ Opportunity (tap → shows opportunities list + SC-13)
│  ├─ Supplier (tap → shows suppliers list + filters)
│  ├─ Research (tap → search/research view)
│  ├─ Trend (tap → Google Trends data)
│  ├─ Arbitrage (tap → price comparison view)
│  ├─ Cross-border (tap → international opportunities)
│  └─ Discovery (tap → AI-recommended opportunities)
│
├─ When "Opportunity" tab active:
│  ├─ List of opportunities (SC-13)
│  │  ├─ Each card shows: image, title, market, profit, score
│  │  ├─ Tap card → Opportunity Detail (SC-13-detail)
│  │  │  ├─ Market analysis, suppliers, ROI analysis
│  │  │  ├─ "Pursue" button → Create Journey or add to Inventory
│  │  │  └─ Back → Producer > Opportunity tab
│  │  └─ "Save" button → Added to saved opportunities
│  └─ Filter chips (Arbitrage, Trend, Cross-border)
│
├─ When "Supplier" tab active:
│  ├─ List of suppliers
│  │  ├─ Search by name, category, country
│  │  ├─ Filter by rating, lead time
│  │  ├─ Tap supplier → SC-15 Supplier Detail
│  │  │  ├─ Overview tab (rating, contact, team)
│  │  │  ├─ Details tab (capabilities, products)
│  │  │  ├─ Products tab (what they supply)
│  │  │  ├─ Reviews tab (community feedback)
│  │  │  ├─ Contact section (email, phone, website)
│  │  │  ├─ "Add to sourcing" button → adds to Inventory
│  │  │  └─ Back → Producer > Supplier tab
│  │  └─ "+ Add Supplier" button → Supplier form modal
│  │      ├─ Name, country, category
│  │      ├─ Contact, website
│  │      └─ Save → Supplier created, list refreshed
│
└─ AI Copilot sidebar (always visible)
   ├─ "Based on your business profile, try:"
   ├─ Recommended opportunities (top 3)
   ├─ Tap recommendation → drill into opportunity detail
   └─ Chat button → open AI Copilot SC-14

Navigation within Producer:
- Horizontal tab switching (Opportunity ↔ Supplier ↔ Research, etc.)
- Tap opportunity/supplier → Detail screen → Back returns to list
- Detail screen can link to other modules (Inventory, Journey)
```

---

### 3. Inventory Module (SC-8)

**Purpose:** Product and warehouse management.

```
INVENTORY Hub
├─ Summary Cards (top)
│  ├─ Total Products
│  ├─ Total Value
│  ├─ Total SKUs
│  └─ Stock by Category (pie chart)
│
├─ Horizontal View Tabs (main navigation)
│  ├─ Products (tap → shows product list)
│  ├─ Categories (tap → shows categories)
│  ├─ SKU (tap → shows SKU list)
│  ├─ Warehouse (tap → shows warehouse locations)
│  ├─ Stock In/Out (tap → movement history)
│  ├─ Pricing (tap → price management)
│  └─ Documents (tap → compliance documents)
│
├─ When "Products" tab active:
│  ├─ Product List (sortable: name, SKU, stock, revenue)
│  │  ├─ Search products
│  │  ├─ Filter by category, warehouse, stock status
│  │  ├─ Tap product → SC-16 Product Detail
│  │  │  ├─ Hero section (image, basic metrics)
│  │  │  ├─ Horizontal tabs:
│  │  │  │  ├─ Overview (description, category, cost/sell price)
│  │  │  │  ├─ Details (variants, SKU, barcode)
│  │  │  │  ├─ Stock (by warehouse, reorder points)
│  │  │  │  ├─ Pricing (multi-channel pricing rules)
│  │  │  │  ├─ Sales Channels (Shopee, TikTok, web)
│  │  │  │  └─ Analytics (charts: revenue, profit, sales trend)
│  │  │  ├─ Edit button → Product form modal
│  │  │  └─ Back → Inventory > Products tab
│  │  └─ "+ New Product" button → Create Product modal
│  │      ├─ Basic info (name, SKU, category)
│  │      ├─ Pricing (cost, sell price)
│  │      ├─ Images (product photos)
│  │      ├─ Warehouse assignment
│  │      └─ Save → Product created, added to list
│  │
│  └─ Stock Alerts section (low stock, overstock)
│      ├─ "Red Shirt - 5 units left in Hanoi"
│      └─ Tap alert → Drill into warehouse stock detail
│
├─ When "Categories" tab active:
│  ├─ Category List
│  │  ├─ Category name, product count
│  │  ├─ Tap category → Category Detail
│  │  │  ├─ Products in category
│  │  │  ├─ Category-level stats (total revenue, profit)
│  │  │  ├─ Bulk actions (edit category, archive products)
│  │  │  └─ Back → Inventory > Categories tab
│  │  └─ "+ New Category" button → Category form modal
│
└─ When "Warehouse" tab active:
   ├─ Warehouse List (location, capacity used, product count)
   │  ├─ Tap warehouse → Warehouse Detail
   │  │  ├─ Location info (address, capacity)
   │  │  ├─ Stock by product (products stored here)
   │  │  ├─ Capacity utilization (chart)
   │  │  ├─ Recent transfers in/out
   │  │  └─ Back → Inventory > Warehouse tab
   │  └─ "+ Add Warehouse" button → Warehouse form modal
   │      ├─ Name, location, type (physical/virtual/dropship)
   │      └─ Save → Warehouse created

Navigation within Inventory:
- Horizontal tab switching (Products ↔ Categories ↔ Warehouse, etc.)
- Tap product/category/warehouse → Detail screen → Back returns to list
- Detail screen can link to other modules (Producer for suppliers, Finance for costs)
```

---

### 4. Consumer Module (SC-9)

**Purpose:** Customer relationship and data management.

```
CONSUMER Hub
├─ Summary Cards (top)
│  ├─ Total Customers
│  ├─ Total Revenue
│  ├─ Avg Customer LTV
│  └─ Segment Breakdown (pie chart)
│
├─ Horizontal View Tabs (main navigation)
│  ├─ CRM (customer list)
│  ├─ CDP (customer data platform)
│  ├─ Channels (omnichannel)
│  ├─ Orders (transactions)
│  ├─ Inbox (messages)
│  ├─ Reviews (feedback)
│  ├─ Affiliate (partner network)
│  ├─ Community (customer community)
│  └─ Segments (audience segments)
│
├─ When "CRM" tab active:
│  ├─ Customer List (sortable: name, tier, LTV, orders)
│  │  ├─ Search customers
│  │  ├─ Filter by segment, tier (Bronze/Silver/Gold/Platinum), status
│  │  ├─ Tap customer → Customer Detail
│  │  │  ├─ Profile (avatar, name, tier, LTV, contact)
│  │  │  ├─ Purchase History (past orders with dates/amounts)
│  │  │  ├─ Interaction History (emails, calls, messages)
│  │  │  ├─ Segment Membership (which segments they belong to)
│  │  │  ├─ Communication section (email, SMS, push, direct message buttons)
│  │  │  ├─ Lifetime Value calculation
│  │  │  ├─ Churn Risk indicator (AI prediction)
│  │  │  ├─ "Send Campaign" button → Campaign form modal
│  │  │  └─ Back → Consumer > CRM tab
│  │  └─ "+ Add Customer" button → Customer form modal
│  │      ├─ Basic info (name, email, phone)
│  │      ├─ Company (for B2B)
│  │      ├─ Address
│  │      └─ Save → Customer created, added to list
│
├─ When "Segments" tab active:
│  ├─ Segment List (name, member count, avg LTV)
│  │  ├─ Tap segment → Segment Detail
│  │  │  ├─ Segment criteria (behavioral, demographic, value-based)
│  │  │  ├─ Member count
│  │  │  ├─ Member list (customers in segment)
│  │  │  ├─ Campaign actions (email, SMS, push, offer)
│  │  │  ├─ Segment performance (revenue from segment, engagement)
│  │  │  └─ Back → Consumer > Segments tab
│  │  └─ "+ Create Segment" button → Segment form modal
│  │      ├─ Segment name
│  │      ├─ Criteria (LTV > 1000, purchase frequency, etc.)
│  │      └─ Save → Segment created, members auto-populated
│
└─ When "Orders" tab active:
   ├─ Order List (sortable: date, customer, amount, status)
   │  ├─ Search orders
   │  ├─ Filter by status (pending, confirmed, shipped, delivered)
   │  ├─ Tap order → Order Detail
   │  │  ├─ Order info (number, date, customer, total)
   │  │  ├─ Order items (products, qty, price)
   │  │  ├─ Shipping status (tracking)
   │  │  ├─ Payment status (paid/unpaid/partial)
   │  │  ├─ Communication (notes, messages with customer)
   │  │  ├─ Actions (cancel, refund, reship)
   │  │  └─ Back → Consumer > Orders tab
   │  └─ Filter: by customer, by date range

Navigation within Consumer:
- Horizontal tab switching (CRM ↔ Segments ↔ Orders, etc.)
- Tap customer/segment/order → Detail screen → Back returns to list
- Detail screens can link to other modules (Journey for campaigns)
```

---

### 5. More Menu (Secondary Navigation)

**Purpose:** Access to Finance, Reports, Journey, Chat, and Settings.

```
MORE Menu (accessed via ⋯ tab)
├─ Finance (SC-10)
│  ├─ Revenue section
│  ├─ Expenses section
│  ├─ Profit section
│  ├─ Cash Flow section
│  ├─ Accounts (bank, e-wallet)
│  ├─ Transactions (all financial history)
│  └─ Reports (P&L, balance sheet)
│
├─ Reports (SC-11)
│  ├─ KPI Dashboard (revenue, profit, growth, efficiency)
│  ├─ Channel Breakdown (by Shopee, TikTok, web, etc.)
│  ├─ Product Performance (revenue by product)
│  ├─ Customer Metrics (acquisition, retention, LTV)
│  ├─ Trend Analysis (historical, forecasting)
│  └─ AI Insights (anomalies, predictions, recommendations)
│
├─ Business Journey (SC-12)
│  ├─ Active Journey (current goal)
│  │  ├─ Goal statement
│  │  ├─ 8-step plan with progress
│  │  ├─ Tap step → Step detail (objective, criteria, guidance)
│  │  └─ Pause/Edit buttons
│  ├─ Past Journeys (completed, archived)
│  └─ "+ New Journey" button → Goal creation form
│     ├─ Goal input
│     ├─ AI generates plan (wait for processing)
│     └─ Review + Confirm
│
├─ Chat / AI Copilot (SC-14)
│  ├─ Conversation history
│  ├─ Text input for questions
│  ├─ AI responses (contextual to business)
│  ├─ Recommendations section (top suggestions)
│  ├─ Business health alerts
│  └─ Featured opportunities
│
├─ Settings
│  ├─ Profile
│  │  ├─ Name, avatar, bio
│  │  ├─ Business name, industry
│  │  └─ Save
│  ├─ Preferences
│  │  ├─ Language (EN, VI)
│  │  ├─ Theme (Light, Dark)
│  │  ├─ Timezone, Currency
│  │  └─ Notifications on/off
│  ├─ BYOK AI Provider
│  │  ├─ Select provider (xAI, OpenRouter, etc.)
│  │  ├─ Enter API Key (encrypted storage)
│  │  └─ Test connection
│  ├─ Data & Privacy
│  │  ├─ Data deletion options
│  │  ├─ Export data
│  │  └─ Privacy policy link
│  └─ Logout
│
└─ Help & Support
   ├─ FAQ
   ├─ Contact support
   ├─ Send feedback
   └─ Version info
```

**Navigation Rules for More Menu:**
- Tap Finance → go to Finance module (SC-10), stay in app
- Tap Reports → go to Reports module (SC-11), stay in app
- Tap Business Journey → go to Journey module (SC-12), stay in app
- Tap Chat → go to AI Copilot module (SC-14), stay in app
- Tap Settings → open Settings sheet, return to previous screen

---

## Tertiary Navigation — Detail Screens & Modals

### Modal Workflows (Non-Navigational, Task-Focused)

```
List Screen
└─ Tap "+ New" button (or "Edit" on existing item)
   └─ Modal Dialog appears (bottom sheet or full-screen)
   │  ├─ Form fields (e.g., Product name, SKU, price)
   │  ├─ Save button (validates, creates/updates item)
   │  ├─ Cancel button (dismisses without saving)
   │  └─ After Save → Modal closes, list item added/updated
   │
   └─ On validation error:
      ├─ Show error message inline
      ├─ Highlight invalid fields
      └─ User can correct + try again (no modal dismiss)
```

### Modal Types Used in Tổng Tài

| Modal | Triggers | Fields | Action |
|---|---|---|---|
| Create Product | "+ New Product" in Inventory | name, SKU, category, cost, price, warehouse | Save → item added to list |
| Add Supplier | "+ Add Supplier" in Producer | name, country, category, contact, website | Save → item added to list |
| Create Segment | "+ Create Segment" in Consumer | name, criteria (filter rules) | Save → AI populates members |
| New Journey | "+ New Journey" in Journey | goal statement (text) | Save → AI generates plan |
| Send Campaign | "Send Campaign" on Customer detail | channel, message, recipients, schedule | Save → campaign queued |
| Confirm Action | Delete, archive, pause | "Are you sure?" message | Yes/No → action executed |

---

### Detail Screen Pattern

```
Detail Screen (e.g., SC-16 Product Detail)
├─ Hero Section (image, key metrics)
│  ├─ Product image/icon
│  ├─ Name, SKU
│  └─ Primary metrics (price, stock, revenue)
│
├─ Horizontal Tab Bar (secondary navigation within detail)
│  ├─ Overview tab
│  ├─ Details tab
│  ├─ Stock tab
│  ├─ Pricing tab
│  ├─ Sales Channels tab
│  └─ Analytics tab
│
├─ Tab Content (changes based on selected tab)
│  └─ Context-specific fields and actions
│
├─ Related Items Section (bottom)
│  └─ "Similar products", "Same category", "Same supplier"
│
└─ Action Buttons (context-sensitive)
   ├─ Edit button (opens form modal)
   ├─ Delete button (opens confirmation modal)
   ├─ Share button (share via SMS, email, social)
   └─ Back button (returns to list with filters preserved)
```

---

## Search & Discovery Navigation

### Global Search

**Access:** Search icon in header (all screens)

```
Tap Search Icon
└─ Search box opens (full-screen or expanded)
   ├─ Text input: "Search..."
   └─ Results organized by type:
      ├─ Products (matching products)
      ├─ Suppliers (matching suppliers)
      ├─ Customers (matching customers)
      ├─ Opportunities (matching opportunities)
      └─ Tap result → Open relevant detail screen
```

### Filters & Sorting

**Available on all list screens:**

| Screen | Filter Options | Sort Options |
|---|---|---|
| Product List | Category, warehouse, stock status | Name, SKU, revenue, profit |
| Supplier List | Country, rating, category | Name, rating, lead time |
| Customer List | Segment, tier, status | Name, LTV, last order |
| Opportunity List | Type (arbitrage, trend), score range | Date discovered, potential ROI |
| Order List | Status, date range, customer | Date, amount, status |

---

## Deep Linking Strategy

Apps support deeplinks to jump directly to a specific screen:

```
tongtai://home
  → HOME dashboard

tongtai://producer
  → PRODUCER hub (Opportunity tab active)

tongtai://producer/suppliers
  → PRODUCER hub (Supplier tab active)

tongtai://inventory/products
  → INVENTORY hub (Products tab active)

tongtai://inventory/product/{productId}
  → Product Detail screen for specific product

tongtai://consumer/customers
  → CONSUMER hub (CRM tab active)

tongtai://consumer/customer/{customerId}
  → Customer Detail screen for specific customer

tongtai://journey/active
  → Current active Business Journey

tongtai://reports
  → Reports dashboard (KPI tab active)

tongtai://finance/accounts
  → Finance module (Accounts tab active)

tongtai://chat
  → AI Copilot chat interface

tongtai://opportunity/{opportunityId}
  → Opportunity Detail screen

tongtai://search?q={query}
  → Search results for query
```

---

## Breadcrumb Navigation

**Shown on detail screens for context:**

```
Home > Producer > Supplier > "XYZ Factory"
└─ Tap "Producer" → back to Producer module
└─ Tap "Supplier" → back to Supplier list
└─ Tap home icon → back to Home
```

**Breadcrumb Rules:**
- Only shown on screens 3+ levels deep
- Tapping any breadcrumb jumps to that level
- Breadcrumbs follow the last taken path (not a fixed hierarchy)

---

## Back Button Behavior

| Scenario | Back Button Behavior |
|---|---|
| Detail screen (from list) | Returns to list with filters preserved |
| Nested detail (A → B → C) | Goes from C → B → A (follows breadcrumb) |
| Search results | Returns to previous screen (not search input) |
| Modal open | Closes modal, stays on previous screen |
| First screen of app | Does nothing (or shows exit confirmation) |
| From deep link | Goes to Home (prevents getting stuck) |

---

## Navigation Performance Guidelines

| Navigation Type | Target Speed |
|---|---|
| Tab switching (Home, Producer, Inventory, Consumer, More) | < 300ms |
| List to detail screen | < 500ms |
| Detail screen tab switching | < 200ms |
| Modal open | < 400ms |
| Search query → results | < 2000ms (wait for AI if needed) |
| Deep link jump | < 1000ms |

---

## Accessibility

**Navigation for users with accessibility needs:**
- VoiceOver support (iOS) / TalkBack support (Android)
- Large touch targets (min 48px height)
- Clear screen titles announced
- Tab navigation reachable via keyboard
- Form fields properly labeled for screen readers

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B  
**Related Docs:** SCREEN-FLOW.md, INFORMATION-ARCHITECTURE.md, COMPONENT-INVENTORY.md  
**Next:** COMPONENT-INVENTORY.md
