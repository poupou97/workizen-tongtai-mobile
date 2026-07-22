# Screen Flow & User Journeys

## Luồng Màn Hình & Hành Trình Người Dùng

---

## English — Screen Transitions & User Flows

**Purpose:** This document maps how users navigate through Tổng Tài screens, showing entry points, transitions, happy paths, and edge cases.

### Navigation Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│  HOME (SC-6)                                                    │
│  Entry Point: App Launch, Tap Home Tab                          │
│  ├─ AI Greeting + Status                                        │
│ ├─ 4 Module Cards (tap to navigate to module)                  │
│  ├─ Mission Today section                                       │
│  ├─ Recent Opportunities card                                   │
│  └─ Business Health Summary                                     │
├─────────────────────────────────────────────────────────────────┤
│                    BOTTOM NAVIGATION (5 Tabs)                   │
│  🏠 Home  |  🌱 Producer  |  📦 Inventory  |  👥 Consumer  | ⋯ More
├─────────────────────────────────────────────────────────────────┤
│  PRODUCER (SC-7)                                                │
│  Entry Points: Home > Producer card, Bottom nav > Producer      │
│  ├─ AI Copilot Summary (opportunities, insights)                │
│  ├─ 7 AI Capabilities tabs:                                     │
│  │   ├─ Opportunity (tap → SC-13 Opportunity Hub)               │
│  │   ├─ Supplier (tap → Supplier List)                          │
│  │   ├─ Research (search, research view)                        │
│  │   ├─ Trend (Google Trends integration)                       │
│  │   ├─ Arbitrage (price comparison)                            │
│  │   ├─ Cross-border (market research)                          │
│  │   └─ Discovery (AI-recommended opportunities)                │
│  ├─ Opportunities List                                          │
│  │   ├─ Tap opportunity → Opportunity Detail                    │
│  │   │   ├─ Market analysis, pricing, suppliers                 │
│  │   │   ├─ "Pursue" button → Create Journey                    │
│  │   │   └─ Back → Producer                                     │
│  │   └─ Save opportunity → Added to saved list                  │
│  ├─ Suppliers List                                              │
│  │   ├─ Tap supplier → SC-15 Supplier Detail                    │
│  │   │   ├─ Overview (rating, contact)                          │
│  │   │   ├─ Details tab (capabilities, team)                    │
│  │   │   ├─ Products tab                                        │
│  │   │   ├─ Reviews tab                                         │
│  │   │   ├─ "Add to sourcing" button → Inventory               │
│  │   │   └─ Back → Producer                                     │
│  │   └─ Add new supplier → Supplier form modal                  │
│  └─ Trends section (Google Trends data)                         │
│      └─ Tap trend → Trend detail view                           │
│                                                                 │
│  INVENTORY (SC-8)                                               │
│  Entry Points: Home > Inventory card, Bottom nav > Inventory    │
│  ├─ Summary cards (totals, value, charts)                       │
│  ├─ Horizontal tabs (Products, Categories, SKU, Warehouse,      │
│  │   Stock In/Out, Pricing, Documents)                          │
│  ├─ Products tab view:                                          │
│  │   ├─ Product List (sortable, filterable)                     │
│  │   ├─ Tap product → SC-16 Product Detail                      │
│  │   │   ├─ Hero section (image, metrics)                       │
│  │   │   ├─ Overview / Details / Stock / Pricing / Sales        │
│  │   │   │   Channels / Analytics tabs                          │
│  │   │   ├─ Edit button → Product form modal                    │
│  │   │   └─ Back → Inventory                                    │
│  │   ├─ "+ New Product" button → Create Product modal           │
│  │   │   ├─ Basic info (name, SKU, category)                    │
│  │   │   ├─ Pricing section                                     │
│  │   │   ├─ Warehouse assignment                                │
│  │   │   └─ Save → Product created, back to list                │
│  │   └─ Stock Alerts section (low stock warnings)               │
│  ├─ Categories tab → Category list                              │
│  │   └─ Tap category → Category detail (products in category)   │
│  └─ Warehouse tab → Warehouse list                              │
│      └─ Tap warehouse → Warehouse detail (location, capacity)   │
│                                                                 │
│  CONSUMER (SC-9)                                                │
│  Entry Points: Home > Consumer card, Bottom nav > Consumer      │
│  ├─ Overview section (totals, segments)                         │
│  ├─ Horizontal tabs (CRM, CDP, Channels, Orders, Inbox,         │
│  │   Reviews, Affiliate, Community, Segments)                   │
│  ├─ CRM tab:                                                    │
│  │   ├─ Customer List (filterable by segment/tier)              │
│  │   ├─ Tap customer → Customer Detail                          │
│  │   │   ├─ Profile (avatar, contact, tier, LTV)               │
│  │   │   ├─ Purchase History                                    │
│  │   │   ├─ Interactions (emails, messages, calls)              │
│  │   │   ├─ Segment membership                                  │
│  │   │   ├─ Action buttons (email, SMS, offer)                  │
│  │   │   └─ Back → Consumer                                     │
│  │   └─ "+ New Customer" button → Add customer form             │
│  ├─ Segments tab → Segment list                                 │
│  │   ├─ Tap segment → Segment detail                            │
│  │   │   ├─ Criteria, member count                              │
│  │   │   ├─ Member list (customers in segment)                  │
│  │   │   ├─ Campaign actions                                    │
│  │   │   └─ Back → Consumer                                     │
│  │   └─ "+ Create Segment" → Segment creation flow              │
│  └─ Orders tab → Order list (transaction history)               │
│      └─ Tap order → Order detail (items, shipping, payment)     │
│                                                                 │
│  JOURNEY (SC-12)                                                │
│  Entry Points: Home > Mission Today, Bottom nav > More > Journey│
│  ├─ Active Journey display:                                     │
│  │   ├─ Goal statement                                          │
│  │   ├─ Progress bar (%)                                        │
│  │   ├─ Timeline (8 steps, status of each)                      │
│  │   ├─ AI recommendations (next steps)                         │
│  │   ├─ Tap step → Step detail                                  │
│  │   │   ├─ Step info, objective, success criteria              │
│  │   │   ├─ Mark complete button                                │
│  │   │   ├─ AI guidance / playbook reference                    │
│  │   │   ├─ Related action (e.g., "Go to Producer")             │
│  │   │   └─ Back → Journey                                      │
│  │   └─ Pause/Edit journey buttons                              │
│  ├─ "+ New Journey" button → Journey creation                   │
│  │   ├─ Goal input (text)                                       │
│  │   ├─ AI generates plan (wait dialog)                         │
│  │   ├─ Review 8-step plan                                      │
│  │   └─ Confirm → Journey created, starts active               │
│  └─ Past Journeys list (completed, archived)                    │
│      └─ Tap journey → Past journey detail (for reference)       │
│                                                                 │
│  OPPORTUNITY HUB (SC-13)                                        │
│  Entry Points: Home > Recent Opportunities, Producer >           │
│  Opportunity tab                                                │
│  ├─ Opportunities feed (sorted by recency/score)                │
│  ├─ Each opportunity card shows:                                │
│  │   ├─ Product image/icon                                      │
│  │   ├─ Title (e.g., "Sell US stitched apparel")                │
│  │   ├─ Market (source → target, e.g., China → USA)             │
│  │   ├─ Profit estimate + trend                                 │
│  │   ├─ Score (0-100)                                           │
│  │   └─ Save/Follow button                                      │
│  ├─ Tap opportunity → Opportunity Detail                        │
│  │   ├─ Full description                                        │
│  │   ├─ Market analysis (size, growth, competition)             │
│  │   ├─ Arbitrage analysis (buy price vs sell price)            │
│  │   ├─ Supplier options (available suppliers)                  │
│  │   ├─ "Pursue" button → Launch journey or add to Inventory   │
│  │   └─ Back → Opportunity Hub                                  │
│  └─ Filter buttons (Arbitrage, Trend, Cross-border, etc.)       │
│                                                                 │
│  FINANCE (SC-10)                                                │
│  Entry Points: Bottom nav > More > Finance                      │
│  ├─ Summary cards (revenue, expenses, profit, cash flow)        │
│  ├─ Horizontal tabs (Revenue, Expenses, Profit, Cash Flow,      │
│  │   Accounts, Transactions, Reports)                           │
│  ├─ Revenue tab:                                                │
│  │   ├─ Revenue by product, channel, customer                   │
│  │   ├─ Tap metric → Drill-down detail                          │
│  │   └─ Back → Finance                                          │
│  ├─ Transactions tab:                                           │
│  │   ├─ Transaction list (sortable, filterable)                 │
│  │   ├─ Tap transaction → Transaction detail                    │
│  │   │   ├─ Date, amount, category, description                 │
│  │   │   ├─ Reconciliation status                               │
│  │   │   └─ Back → Finance                                      │
│  │   └─ "+ Add transaction" → Manual entry form                 │
│  └─ Accounts tab:                                               │
│      ├─ Account list (bank, e-wallet, cash)                     │
│      ├─ Tap account → Account detail (balance, recent tx)       │
│      └─ "+ Connect account" → Sync bank account                 │
│                                                                 │
│  REPORTS (SC-11)                                                │
│  Entry Points: Bottom nav > More > Reports                      │
│  ├─ KPI Dashboard:                                              │
│  │   ├─ Revenue, profit, growth, efficiency widgets             │
│  │   ├─ Tap widget → Drill-down analysis                        │
│  │   └─ Back → Reports                                          │
│  ├─ Channel Breakdown:                                          │
│  │   ├─ Revenue by channel (Shopee, TikTok, web, etc.)          │
│  │   ├─ Interactive pie/bar chart                               │
│  │   └─ Tap channel → Channel detail                            │
│  ├─ Trend Analysis:                                             │
│  │   ├─ Historical data, forecasts                              │
│  │   ├─ Month-over-month comparison                             │
│  │   └─ Anomaly alerts                                          │
│  └─ AI Insights:                                                │
│      ├─ Recommendations (based on data)                         │
│      ├─ Alerts (unusual metrics)                                │
│      └─ Predictions (revenue, churn, etc.)                      │
│                                                                 │
│  AI COPILOT (SC-14)                                             │
│  Entry Points: Any screen with 🧠 icon, Bottom nav > More >     │
│  Chat                                                           │
│  ├─ Chat interface (messages)                                   │
│  ├─ User asks question (text input)                             │
│  ├─ AI responds with guidance                                   │
│  ├─ Recommendations section (top 5)                             │
│  │   └─ Tap recommendation → Related screen                     │
│  ├─ Business Health summary                                     │
│  ├─ Alerts section (risks, opportunities)                       │
│  └─ Opportunities section (featured opportunities)              │
│                                                                 │
│  MORE TAB (Secondary Navigation)                                │
│  Entry Point: Bottom nav > More (⋯)                             │
│  ├─ Finance                                                     │
│  ├─ Reports                                                     │
│  ├─ Business Journey                                            │
│  ├─ Chat (AI Copilot)                                           │
│  ├─ Settings                                                    │
│  ├─ Help & Support                                              │
│  └─ Profile / Account                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Happy Path Scenarios

### Scenario 1: "Find & Pursue an Opportunity"

```
1. User opens Tổng Tài
   HOME (SC-6)
   └─ Tap "Opportunities" card
   └─ Or: Bottom nav > Producer > Opportunity tab

2. PRODUCER (SC-7)
   └─ Tap Opportunity tab
   └─ See opportunities list (AI-ranked)

3. OPPORTUNITY HUB (SC-13)
   └─ Browse opportunities
   └─ Tap "Sell US stitched apparel"

4. OPPORTUNITY DETAIL
   ├─ Review market analysis
   ├─ Check suppliers
   ├─ Read profit estimate
   └─ Tap "Pursue"

5. Choice: Create Journey or Add to Inventory
   ├─ Option A: Create Journey "Enter US market"
   │   └─ JOURNEY (SC-12) created with 8-step plan
   │   └─ Step 1: "Find suppliers" links to Producer
   │   └─ Step 2: "Add product" links to Inventory
   │   └─ Continue execution...
   │
   └─ Option B: Add to Inventory
       └─ INVENTORY (SC-8) shows new product
       └─ Set warehouse, pricing
       └─ Continue with sourcing

6. REPORTS (SC-11) tracks opportunity impact
   └─ Monitor revenue from new product
```

### Scenario 2: "Manage Inventory & Stock"

```
1. User opens app
   HOME (SC-6)
   └─ Tap "Inventory" card
   └─ Or: Bottom nav > Inventory

2. INVENTORY (SC-8)
   ├─ Review summary (total products, value, SKUs)
   └─ See stock alerts section

3. Action: Investigate low stock
   ├─ Tap stock alert "Red Shirt - 5 units left"
   │
   └─ PRODUCT DETAIL (SC-16)
       ├─ Hero: Image, basic metrics
       ├─ Tap "Stock" tab
       ├─ See: Hanoi warehouse (5 units), Saigon (20 units)
       ├─ Tap "Reorder" button
       │
       └─ Reorder Modal
           ├─ Select supplier (from Producer)
           ├─ Set quantity (e.g., 100 units)
           └─ Confirm → Purchase order created

4. PRODUCER automatically triggered
   └─ Suggest suppliers for "Red Shirt"
   └─ Show pricing, lead times

5. FINANCE tracks cost
   └─ Create purchase expense record
   └─ Track payment terms

6. Delivery received → Update stock
   └─ INVENTORY stock levels updated
   └─ REPORTS reflect inventory value change
```

### Scenario 3: "Launch a Marketing Campaign"

```
1. User opens app
   HOME (SC-6)
   └─ Tap "Customers" card
   └─ Or: Bottom nav > Consumer

2. CONSUMER (SC-9)
   └─ Tap "Segments" tab
   └─ See VIP Customers segment (250 people)

3. Action: Launch campaign to VIP Customers
   ├─ Tap "VIP Customers" segment
   │
   └─ SEGMENT DETAIL
       ├─ Review criteria (LTV > $1000)
       ├─ See member count (250)
       ├─ Tap "Launch Campaign"
       │
       └─ Campaign Creation Modal
           ├─ Choose channel (Email, SMS, Push)
           ├─ Compose message
           ├─ Set timing
           └─ Confirm → Campaign created

4. AI Copilot suggests message
   └─ "Based on VIP behavior, try: '20% discount + free shipping'"

5. CONSUMER tracks response
   └─ Open rate, click rate, conversions

6. FINANCE tracks revenue impact
   └─ Revenue from campaign attributed to segment
   └─ ROI calculated (spend vs revenue)

7. REPORTS show campaign performance
   └─ Dashboard updated with campaign KPIs
```

---

## Edge Cases & Error Handling

### Edge Case 1: Empty States

| Screen | Empty State | Action |
|---|---|---|
| Producer | No suppliers added | Show "Add supplier" CTA |
| Inventory | No products | Show "Create product" CTA |
| Consumer | No customers | Show "Import customers" CTA |
| Journey | No active journey | Show "Create journey" CTA |
| Opportunity | No opportunities found | Show "Set preferences" CTA |
| Finance | No transactions | Show "Add account" CTA |

### Edge Case 2: Loading States

- **Opportunity discovery**: Show skeleton loaders while AI searches
- **Journey planning**: Show planning animation while AI generates steps
- **Report generation**: Show progress bar for data aggregation
- **Image upload**: Show upload progress for product images

### Edge Case 3: Error States

| Error | Recovery |
|---|---|
| Failed to create product | Show error message + "Try again" button |
| Supplier not found | Suggest "Add manually" |
| Payment processing failed | Suggest "Retry" or "Use different payment" |
| Journey plan generation failed | Suggest "Simplify goal" or "Try different phrasing" |

### Edge Case 4: Offline Mode

- Users can browse cached data (products, customers, past reports)
- Create/edit actions queue locally and sync when online
- Chat with copilot limited (uses cached knowledge)

---

## Deep Linking & Entry Points

```
tongtai://producer/opportunity/opp-123
  → Opens Opportunity Detail for opp-123

tongtai://inventory/product/prod-456
  → Opens Product Detail for prod-456

tongtai://consumer/customer/cust-789
  → Opens Customer Detail for cust-789

tongtai://journey/active
  → Opens current active journey

tongtai://reports/kpi?period=this_month
  → Opens KPI dashboard for current month

tongtai://chat?question=how%20to%20enter%20market
  → Opens chat with pre-filled question
```

---

## Navigation Patterns

### Pattern 1: Drill-Down Detail View

```
List (many items)
└─ Tap item
   └─ Detail screen (full content)
   └─ Tabs for different aspects
   └─ Action buttons (edit, delete, etc.)
   └─ Back → returns to list
```

### Pattern 2: Modal Workflows

```
List screen
└─ Tap "+ New" button
   └─ Modal dialog appears
   └─ Form fields
   └─ Cancel / Save buttons
   └─ After save → Item added to list, modal closes
```

### Pattern 3: Tab Navigation

```
Screen with multiple views
├─ Horizontal tab bar at top
├─ Tap tab → content switches
└─ Tab state persists when navigating back
```

### Pattern 4: Breadcrumb Navigation

```
Home > Producer > Supplier Detail > Supplier "XYZ Factory"
└─ Tap any breadcrumb to jump back
```

---

## Back Button Behavior

- **Standard case**: Back button returns to previous screen
- **Modal**: Back button closes modal without saving
- **List filtered**: Back button returns to list with same filters applied
- **From deep link**: Back button navigates to Home (no infinite loop)

---

## Success Metrics

| Flow | Success Metric |
|---|---|
| Opportunity to Journey | < 30 seconds from tap to journey creation |
| Add Product | < 2 minutes for full product creation |
| Create Segment | < 1 minute for segment creation |
| View Reports | Dashboard renders < 2 seconds |
| Chat with Copilot | Response < 3 seconds |

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B  
**Related Docs:** INFORMATION-ARCHITECTURE.md, NAVIGATION-MAP.md, COMPONENT-INVENTORY.md  
**Next:** NAVIGATION-MAP.md
