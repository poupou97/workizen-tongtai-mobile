# Information Architecture
## Kiến Trúc Thông Tin

Complete navigation structure, screen relationships, and user flows for Tổng Tài.  
Cấu trúc điều hướng hoàn chỉnh, mối quan hệ màn hình và luồng người dùng cho Tổng Tài.

**Source:** UI/UX Concept Inventory (25 screens)  
**Terminology:** TERMINOLOGY.md  
**Related:** COMPONENT-LIBRARY.md, DESIGN-SYSTEM-DRAFT.md

---

## Module Hierarchy — Hệ Thống Phân Cấp Mô-đun

### Primary Navigation (Bottom Nav)

Tổng Tài uses a 5-tab bottom navigation bar as the primary entry point.  
Tổng Tài sử dụng thanh điều hướng dưới 5 tab làm điểm vào chính.

```
┌─────────────────────────────────────────────┐
│                Main App                     │
├─────────────────────────────────────────────┤
│                                             │
│         [Screen Content Here]               │
│                                             │
├─────────────────────────────────────────────┤
│  🏠      🌱      📦      👥      ⋯          │
│ Home   Producer Inventory Consumer  More    │
│(Teal)  (Green)  (Orange)  (Blue)  (Gray)   │
└─────────────────────────────────────────────┘

Color Key: Each tab uses its domain color when active
```

### Module Tree Structure

```
Tổng Tài
│
├─ 🏠 Home (Dashboard)
│  ├─ SC-6: Home Dashboard
│  │   ├─ AI Greeting
│  │   ├─ Module Cards (tap to navigate)
│  │   ├─ Mission Today section
│  │   └─ Recent Opportunities
│  └─ Quick Access to all modules
│
├─ 🌱 Producer (Sourcing)
│  ├─ SC-7: Producer Hub
│  │   ├─ AI Copilot Summary
│  │   ├─ 7 AI Capabilities (tabs/pills)
│  │   ├─ Opportunities List
│  │   ├─ Suppliers List
│  │   └─ Trends Section
│  ├─ SC-15: Supplier Detail
│  │   ├─ Overview tab
│  │   ├─ Details tab (rating, team, capabilities)
│  │   ├─ Products tab
│  │   ├─ Reviews tab
│  │   └─ Contact Info
│  ├─ SC-13: Opportunity Hub
│  │   ├─ Opportunities feed
│  │   ├─ AI insights per opportunity
│  │   └─ Save/Follow actions
│  ├─ Opportunity Detail (not shown, assumed)
│  │   ├─ Arbitrage analysis
│  │   ├─ Market data
│  │   ├─ Supplier options
│  │   └─ "Pursue" action
│  └─ Trend Detail (not shown, assumed)
│      ├─ Google Trend data
│      ├─ Historical graph
│      └─ Related opportunities
│
├─ 📦 Inventory (Product & Warehouse)
│  ├─ SC-8: Inventory Overview
│  │   ├─ Summary (total products, value, SKUs, pie chart)
│  │   ├─ Tab Bar (Products, Categories, SKU, Warehouse, Stock In/Out, Pricing, Documents)
│  │   ├─ Product List view
│  │   ├─ Stock Alerts section
│  │   └─ Recent Activity
│  ├─ SC-16: Product Detail
│  │   ├─ Hero Section (image, basic metrics)
│  │   ├─ Overview tab
│  │   ├─ Details tab (revenue, profit, variants)
│  │   ├─ Stock by Warehouse
│  │   ├─ Pricing tab
│  │   ├─ Sales Channels tab
│  │   ├─ Analytics tab (charts)
│  │   └─ Related Products
│  ├─ Category Detail (assumed)
│  │   ├─ Products in category
│  │   ├─ Category-level stats
│  │   └─ Bulk actions
│  ├─ Warehouse Detail (assumed)
│  │   ├─ Location info
│  │   ├─ Stock by product
│  │   ├─ Capacity metrics
│  │   └─ Transfer history
│  └─ Create Product (modal)
│      ├─ Basic info (name, SKU, category)
│      ├─ Pricing
│      ├─ Warehouse assignment
│      └─ Save
│
├─ 👥 Consumer (Customer Intelligence)
│  ├─ SC-9: Consumer Hub
│  │   ├─ Overview section
│  │   ├─ Tab Bar (CRM, CDP, Channels, Orders, Inbox, Reviews, Affiliate, Community, Segments)
│  │   ├─ CRM List View
│  │   │   ├─ Customer cards with tier, LTV, order count
│  │   │   └─ Filter by segment
│  │   ├─ CDP View (customer data platform)
│  │   ├─ Channels View (omnichannel)
│  │   ├─ Orders View (transaction list)
│  │   ├─ Inbox View (customer messages)
│  │   ├─ Reviews View (customer feedback)
│  │   ├─ Affiliate View (partner network)
│  │   ├─ Community View (customer community)
│  │   └─ Segments View (audience segments)
│  ├─ Customer Detail
│  │   ├─ Profile (avatar, name, contact)
│  │   ├─ Purchase History
│  │   ├─ Segment membership
│  │   ├─ Communication history
│  │   ├─ Lifetime Value
│  │   └─ Action buttons (email, SMS, offer)
│  ├─ Order Detail
│  │   ├─ Order info (date, amount, items)
│  │   ├─ Shipping status
│  │   ├─ Payment status
│  │   ├─ Notes/communication
│  │   └─ Return/exchange options
│  └─ Segment Detail
│      ├─ Segment criteria
│      ├─ Member count
│      ├─ Member list
│      └─ Campaign actions
│
├─ ⋯ More (Secondary Navigation)
│  ├─ SC-10: Finance Module
│  │   ├─ Revenue section
│  │   ├─ Expenses section
│  │   ├─ Profit section
│  │   ├─ Cash Flow section
│  │   ├─ Accounts List
│  │   ├─ Transactions List (sortable, filterable)
│  │   └─ Financial Reports
│  │
│  ├─ SC-11: Reports Module
│  │   ├─ KPIs Dashboard
│  │   ├─ Channel Breakdown (by platform, region, product)
│  │   ├─ Trend Analysis (charts)
│  │   ├─ AI Insights (recommendations)
│  │   ├─ Custom Report Builder (assumed)
│  │   └─ Export options
│  │
│  ├─ SC-12: Business Journey (Goal Orchestration)
│  │   ├─ Active Goal Display
│  │   │   ├─ Goal title, progress circle (80%)
│  │   │   ├─ Timeline visualization
│  │   │   ├─ Step-by-step plan (8 steps)
│  │   │   ├─ Step status (done, in-progress, waiting, blocked)
│  │   │   └─ AI Assistant sidebar (chat)
│  │   ├─ Milestones section
│  │   │   ├─ Task count
│  │   │   ├─ Timeline
│  │   │   └─ Cost estimate & forecast
│  │   ├─ Playbooks section
│  │   │   └─ Similar goals for reference
│  │   └─ Goal list (all goals, create new)
│  │
│  ├─ SC-14: AI Copilot
│  │   ├─ Chat interface
│  │   ├─ Quick recommendations (5 items)
│  │   ├─ Business Health metrics
│  │   ├─ Alerts section
│  │   ├─ Opportunities feed
│  │   └─ Conversation history
│  │
│  ├─ Document Intelligence (assumed)
│  │   ├─ Scan interface (camera)
│  │   ├─ OCR result preview
│  │   ├─ Document extraction (tables, forms)
│  │   ├─ Document library
│  │   └─ Export options (PDF, CSV, JSON)
│  │
│  ├─ AI Studio (assumed)
│  │   ├─ Custom AI workflow builder
│  │   ├─ Template library
│  │   ├─ Execution history
│  │   └─ Analytics
│  │
│  ├─ Integration Center (assumed)
│  │   ├─ Available integrations
│  │   ├─ Connected apps
│  │   ├─ Webhooks
│  │   ├─ API keys
│  │   └─ Sync logs
│  │
│  ├─ Business Setup (Configuration)
│  │   ├─ Company info
│  │   ├─ Team management
│  │   ├─ Roles & permissions
│  │   ├─ Warehouse setup
│  │   ├─ Payment settings
│  │   └─ API configuration
│  │
│  └─ Settings
│      ├─ Profile
│      ├─ Notifications
│      ├─ Privacy
│      ├─ Dark mode
│      ├─ Language
│      └─ Logout

```

---

## Navigation Patterns — Mẫu Điều Hướng

### Pattern 1: Bottom Tab Navigation

**Primary entry points via 5-tab bottom bar.**

```
User Action:           Tap "Producer" tab
Navigation:            Home → Producer Hub (SC-7)
Visual Feedback:       Tab highlights (green), underline appears
Back Behavior:         Back button or swipe closes detail screens
```

**Used by:** All 5 tabs (Home, Producer, Inventory, Consumer, More)

### Pattern 2: Module-Level Tabs (Horizontal)

**Switch between sub-sections within a module.**

```
Example: Inventory Module (SC-8)
         ┌──────────────────────────────────┐
         │ Products│ Categories│ SKU│ ... │
         │ ────────│           │    │     │
         └──────────────────────────────────┘

User Action:           Tap "Pricing" tab
Navigation:            Content switches below tabs
Persistence:           Selected tab remembers on back/return
Animation:             Fade/slide transition (300ms)
```

**Modules using this:**
- Inventory: Products, Categories, SKU, Warehouse, Stock In/Out, Pricing, Documents
- Consumer: CRM, CDP, Channels, Orders, Inbox, Reviews, Affiliate, Community, Segments
- Finance: Revenue, Expenses, Profit, Cash Flow sections
- Reports: KPIs, Channels, Trends, AI Insights

### Pattern 3: Detail Screen Navigation (Card → Detail)

**Tap a card or list item to drill into detail.**

```
Example: Opportunity List → Opportunity Detail

Opportunity Card (SC-13)
├─ Title + Market
├─ Profit + Trend
├─ Rating + Score
└─ Tap anywhere → Opportunity Detail

Detail Screen Layout:
├─ Back button (top-left)
├─ Hero Section (opportunity image/icon)
├─ Tab Bar (Overview, Analysis, Actions)
├─ Content per tab
└─ Related Items footer
```

**Modules using this:**
- Producer: Opportunity Card → Opportunity Detail, Supplier Card → Supplier Detail (SC-15)
- Inventory: Product Card → Product Detail (SC-16)
- Consumer: Customer Card → Customer Detail
- Finance: Transaction Card → Transaction Detail
- Reports: Chart/Trend → Drill-down Detail

### Pattern 4: Modal/Sheet Creation

**Create new items via bottom sheet or full-screen modal.**

```
Example: Add New Product

User Action:           Tap "+" (add) button
Navigation:            Bottom sheet slides up (or full-screen modal)
Form Layout:           Fields with labels (required marked *)
Validation:            Real-time (email format, required fields)
Actions:               "Cancel" (discard), "Save" (create)
Success:               Toast "Product added", return to list
```

**Create Journeys:**
- Add Opportunity (Producer)
- Add Product (Inventory)
- Add Customer (Consumer)
- Add Account / Transaction (Finance)
- Add Goal (Business Journey)

### Pattern 5: Search & Filter Entry

**Access search/filter at section top.**

```
Example: Find Product

Search Bar (top of Inventory)
├─ Magnifying glass icon
├─ Placeholder "Search products..."
├─ Clear (X) button when typing
└─ Tap to expand to full search

Filter Button (often right of search)
├─ Funnel icon
├─ Sheet opens with filter options
│  ├─ Category dropdown
│  ├─ Price range slider
│  ├─ Stock status checkbox
│  └─ "Apply" / "Reset"
└─ Filtered list updates
```

**Screens using this:**
- Producer: Search suppliers, filter by rating/MOQ
- Inventory: Search products, filter by category/warehouse/status
- Consumer: Search customers, filter by segment/tier
- Finance: Search transactions, filter by date/category/account
- Reports: Filter by date range, channel, product

### Pattern 6: AI Copilot Integration

**Quick access to AI from multiple entry points.**

```
Entry Points:
├─ Floating chat button (all screens)
├─ "Ask AI..." search bar (Home)
├─ AI Copilot tab (More menu)
├─ AI recommendations card (various sections)
└─ AI Assistant sidebar (Business Journey detail)

Chat Flow:
├─ User types question
├─ AI responds with suggestion (text + optional action)
├─ Tap to execute (e.g., "Create this opportunity")
└─ Action completes, return to context
```

### Pattern 7: Cross-Module Navigation

**Navigate between related data across modules.**

```
Example: Supplier → Product → Customer

Supplier Detail (SC-15)
└─ "Products" tab → Product list
   └─ Tap Product → Product Detail (SC-16)
      └─ "Sales Channels" tab → Channel + Customer data
         └─ Tap Customer → Customer Detail
            └─ Back chain: Customer → Product → Supplier
```

**Common Cross-Module Flows:**
- Opportunity → Supplier Details → Supplier Products
- Product → Sales Channels → Top Customers
- Customer Order → Product → Supplier Details
- Business Goal → Required Products → Inventory Stock

---

## Screen Relationship Map — Bản Đồ Mối Quan Hệ Màn Hình

```
HOME (SC-6)
├─ Tap Producer card → Producer Hub (SC-7)
├─ Tap Inventory card → Inventory Overview (SC-8)
├─ Tap Consumer card → Consumer Hub (SC-9)
├─ Tap Business card → Business Journey (SC-12)
└─ Tap mission → Mission Detail (assume)

PRODUCER HUB (SC-7)
├─ Tap Opportunity card → Opportunity Detail
├─ Tap Supplier card → Supplier Detail (SC-15)
├─ Tap "View" button → Opportunity Detail
└─ Swipe tabs for capabilities → sub-sections

OPPORTUNITY HUB (SC-13)
├─ Tap Opportunity card → Opportunity Detail
├─ "Save" button → Add to saved list
└─ "AI Insights" → Recommendation detail

SUPPLIER DETAIL (SC-15)
├─ Tap product in "Products" tab → Product Detail (SC-16)
├─ Tap review in "Reviews" tab → Review detail
├─ Contact section → Send message / call options
└─ Related suppliers footer → Supplier carousel

INVENTORY OVERVIEW (SC-8)
├─ Tap Product → Product Detail (SC-16)
├─ Swipe tabs for categories, SKU, warehouse
├─ Tap "+" → Add Product modal
├─ Tap stock alert → Low stock detail / reorder

PRODUCT DETAIL (SC-16)
├─ Tap "Suppliers" section → Find suppliers (Producer)
├─ Tap sales channel → Channel analytics
├─ Tap warehouse → Warehouse detail
├─ Tap variant → Variant detail
└─ Tap "Edit" → Product edit modal

CONSUMER HUB (SC-9)
├─ Tap customer → Customer Detail
├─ Swipe tabs for segments, orders, reviews, etc.
├─ Tap "+" → Add Customer modal
└─ Tap segment → Segment detail

CUSTOMER DETAIL
├─ Tap order → Order Detail
├─ Tap channel → Channel communication history
└─ "Send offer" → Offer creation modal

FINANCE (SC-10)
├─ Tap transaction → Transaction Detail
├─ Tap account → Account detail / balance history
└─ Swipe sections for Revenue, Expenses, Profit, Cash Flow

REPORTS (SC-11)
├─ Tap KPI card → KPI detail / drill-down
├─ Tap chart segment → Detailed chart view
├─ Tap "Export" → Export options
└─ Tap date range picker → Custom report

BUSINESS JOURNEY (SC-12)
├─ Tap step → Step detail (edit, view resources)
├─ Tap "View Playbook" → Playbook detail
├─ AI Assistant chat → Recommendation + action
└─ Tap milestone → Milestone detail / tracking

AI COPILOT (SC-14)
├─ Tap recommendation card → Execute action / navigate
├─ Tap "View More" → Full recommendation detail
├─ Tap opportunity link → Opportunity Detail (SC-13)
└─ Chat message → Response + context

```

---

## Cross-Module Flows — Luồng Xuyên Mô-đun

### Flow 1: Opportunity Discovery to Action

**AI finds opportunity → User reviews → Takes action**

```
User Entry: Home (SC-6)
1. Scroll to "Recent Opportunities" section
2. Tap Opportunity card
   ↓ Navigate to Opportunity Detail
3. Read: Arbitrage analysis, market data, potential profit
4. View: List of matching suppliers
5. Tap Supplier → Supplier Detail (SC-15)
6. Review: Ratings, team, MOQ, lead time
7. Action: "Request Quote" or "Create PO"
   ↓ Save as note or task
8. Return to Home or Producer Hub (SC-7)
```

### Flow 2: Product Management Lifecycle

**Create Product → Set Price/Stock → Monitor Sales → Update**

```
User Entry: Inventory Hub (SC-8)
1. Tap "+" button → Add Product modal
2. Fill: Name, SKU, Category, Price, Warehouse
3. Save → List updates
4. Tap new Product → Product Detail (SC-16)
5. Configure: Variants, pricing by channel, warehouse stock
6. Monitor: Sales chart, stock levels, revenue
7. Alert: Low stock triggers notification
8. Action: Reorder or adjust pricing
9. Return to Inventory list
```

### Flow 3: Customer Relationship Management

**Add Customer → Record Order → Segment → Campaign**

```
User Entry: Consumer Hub (SC-9)
1. Tap "+" button → Add Customer modal
2. Fill: Name, contact, source, tier
3. Save → Customer added to list
4. Tap Customer → Customer Detail
5. Log: New order or interaction
6. Assign: Segment membership (e.g., "VIP")
7. Action: Send offer, email campaign
8. Monitor: LTV, order frequency, satisfaction
9. Return to Consumer list
```

### Flow 4: Financial Reconciliation

**Record Transaction → Categorize → Generate Report**

```
User Entry: Finance (SC-10)
1. Tap "+" button → Add Transaction modal
2. Fill: Date, amount, category, account, note
3. Save → Transaction appears in list
4. View: Tap transaction → Transaction Detail
5. Reconcile: Match to invoice or PO
6. Reports: Generate P&L, cash flow by date range
7. Export: Download for accounting
8. Return to Finance overview
```

### Flow 5: Business Goal Orchestration

**Define Goal → Create Plan → Execute Steps → Track Progress**

```
User Entry: Business Journey (SC-12)
1. Tap "Create Goal" button → Goal creation modal
   Fill: Goal title, target date, description
2. AI Generates: 8-step plan, resource estimates
3. Review: "Enter US market" goal with 80% progress
4. View: Each step with status (done/in-progress/waiting/blocked)
5. Action: Click step → Edit, add note, mark done
6. Monitor: Progress bar updates, milestones tracked
7. AI Assist: Sidebar chat for step guidance
8. Complete: Mark goal done, celebrate!
9. Return to goal list or create new goal
```

### Flow 6: Business Decision Support

**User Question → AI Analysis → Recommendation → Action**

```
User Entry: Any screen (floating chat or AI Copilot tab)
1. Tap "Ask AI..." or chat button
2. Type: "Should I increase price for Product X?"
3. AI Responds:
   - Market analysis (competitors, demand)
   - Recommendation (increase by 5%)
   - Impact (revenue +$500/month)
4. Tap "Apply recommendation" → Change price
5. Or: Tap "View more" → Analysis detail
6. Return to previous screen or chat history
```

---

## Modal Flows — Luồng Cửa Sổ Bật Lên

### Add Product Modal

```
Entry Point: Inventory Hub (SC-8) → "+" button

Modal Structure:
├─ Title: "Add Product"
├─ Required Fields:
│  ├─ Name (text input)
│  ├─ SKU (text input)
│  ├─ Category (dropdown)
│  ├─ Price (number input)
│  └─ Warehouse (dropdown/multi-select)
├─ Optional Fields:
│  ├─ Description (text area)
│  ├─ Image upload
│  └─ Tags
├─ Actions:
│  ├─ "Cancel" (discard changes)
│  └─ "Save" (create product)
└─ Success: Toast "Product added", return to list
```

### Create Opportunity Modal

```
Entry Point: Producer Hub (SC-7) → "Add Opportunity" or "Create from AI"

Modal Structure (Bottom Sheet):
├─ Title: "New Opportunity"
├─ Fields:
│  ├─ Market pair (from → to, e.g., Alibaba → Amazon)
│  ├─ Product category
│  ├─ Estimated profit
│  ├─ Supplier (select from list or add new)
│  └─ Notes
├─ AI Analysis:
│  ├─ Suggested price
│  ├─ Risk score
│  └─ Similar opportunities (reference)
├─ Actions:
│  ├─ "Save for later"
│  ├─ "Create PO" (if supplier selected)
│  └─ "Cancel"
└─ Success: Toast, opportunity appears in list
```

### Create Business Journey Modal

```
Entry Point: Business Journey (SC-12) → "New Goal" button

Modal Structure:
├─ Title: "Create Business Goal"
├─ Fields:
│  ├─ Goal title (e.g., "Enter US market")
│  ├─ Category (Growth, Profitability, Efficiency, etc.)
│  ├─ Target date (date picker)
│  ├─ Budget estimate (number)
│  └─ Description
├─ AI Recommendation:
│  ├─ Suggested plan (8 steps)
│  ├─ Resource estimate ($X, Y weeks)
│  └─ Success rate forecast
├─ Actions:
│  ├─ "Edit plan" (customize steps)
│  ├─ "Accept & Start"
│  └─ "Cancel"
└─ Success: Goal created, full detail screen opens
```

### Confirmation Dialogs

| Action | Dialog | Buttons |
|---|---|---|
| Delete Product | "Delete Product X?" + Warning | Cancel, Delete |
| Complete Step | "Mark step done?" | Cancel, Mark Done |
| Clear Cache | "Clear all local data?" | Cancel, Clear |
| Logout | "Sign out?" | Cancel, Logout |

---

## User Paths — Hành Trình Người Dùng

### Path 1: First-Time User (Onboarding)

```
1. App Launch
   ├─ Splash screen (fox mascot)
   ├─ "Welcome to Tổng Tài" intro
   ├─ "Build your business operating system"
   └─ "Get started" button

2. Authentication (assumed, not shown in concepts)
   ├─ Phone / Email entry
   ├─ OTP verification
   └─ Profile setup (name, business type, country)

3. Business Setup
   ├─ Company name & info
   ├─ Add first product (tutorial)
   ├─ Add first supplier (tutorial)
   └─ Invite team members (optional)

4. Home Dashboard
   ├─ Greeting: "Welcome, John! 👋"
   ├─ Empty states with "Get started" CTAs
   └─ Feature highlights (tooltips)

5. Guided Tour
   ├─ "Explore Producer" (find suppliers)
   ├─ "Explore Inventory" (add products)
   ├─ "Explore Consumer" (track customers)
   └─ "All set! You're ready to grow."

6. Deep Dive
   ├─ User explores Producer Hub (SC-7)
   ├─ Discovers first opportunity
   ├─ Adds supplier
   └─ Feels confident to explore independently
```

### Path 2: Daily User

```
1. Open app → Home Dashboard (SC-6)
2. Quick scan:
   ├─ AI Greeting: "Good morning! 12 new opportunities"
   ├─ Module cards (Producer, Inventory, Consumer)
   ├─ Mission Today (3 recommended tasks)
   └─ Recent Opportunities (new deals)

3. Action: "Review New Opportunities"
   ├─ Tap opportunity card → Opportunity Detail
   ├─ Read: Market analysis, profit forecast
   ├─ Tap supplier → Supplier Detail (SC-15)
   ├─ Review: Ratings, MOQ, lead time
   └─ Action: Save or request quote

4. Quick Check: Inventory
   ├─ Swipe to Inventory tab
   ├─ View: Low stock alerts
   ├─ Action: Adjust reorder quantities
   └─ Return to Home

5. Customer Follow-up
   ├─ Swipe to Consumer tab
   ├─ Filter: "Pending orders"
   ├─ Action: Send shipment updates
   └─ Back to Home

6. End: Return to Home or close app
```

### Path 3: Power User (Analytics & Strategy)

```
1. Weekly Business Review
   ├─ Open app → Home
   ├─ Tap "Reports" tab (More menu)
   ├─ View: KPIs, channel breakdown, trends

2. Deep Dive: Reports (SC-11)
   ├─ Revenue by channel (chart)
   ├─ Top products by profit
   ├─ Customer LTV distribution
   ├─ Trend forecasts

3. Analysis: Drill-down
   ├─ Tap chart → Detail view
   ├─ Filter by date range, product, channel
   ├─ Export data (CSV, PDF)
   └─ Share with team

4. Strategy: Business Journey
   ├─ View active goals (SC-12)
   ├─ Track progress: "Enter US market" (80%)
   ├─ Review milestones: 12 tasks, 15 days
   ├─ Check AI forecast: $28,500 potential revenue
   └─ Update step status as work progresses

5. Optimization: AI Insights
   ├─ Open AI Copilot (SC-14)
   ├─ Review recommendations:
   │  ├─ "Increase price for Product X: +$500/month"
   │  ├─ "Add supplier from Vietnam: 15% cost savings"
   │  ├─ "Launch VIP segment campaign: +$800/week"
   │  └─ "Optimize warehouse B: free 200 SKUs"
   ├─ Tap to execute or save for later

6. Decision: Act on insights
   ├─ Implement top 2-3 recommendations
   ├─ Monitor impact over next week
   ├─ Return to Reports for verification
   └─ Close with confidence
```

### Path 4: Team Lead (Delegation)

```
1. Business Setup
   ├─ Navigate to "More" → "Business Setup"
   ├─ Team section: Invite members
   ├─ Set roles: Manager, Operator, Viewer
   └─ Assign permissions per module

2. Assignment
   ├─ Tap team member
   ├─ Assign tasks: "Review suppliers", "Update products"
   ├─ Set deadline
   └─ Send notification

3. Monitoring
   ├─ Return to Home dashboard
   ├─ View team activity widget
   ├─ Check: Tasks completed, products added, orders processed
   └─ Review notifications

4. Feedback
   ├─ Tap task completion
   ├─ Leave comment or approval
   ├─ Tap "Mark Done" or "Needs Revision"
   └─ Team member notified

5. Strategy
   ├─ Open Reports (SC-11)
   ├─ Team productivity dashboard
   ├─ Set KPIs per team member
   └─ Coach based on data
```

---

## Search & Filter Entry Points — Điểm Vào Tìm Kiếm & Lọc

### Search Patterns

| Screen | Search Type | Location | Placeholder |
|---|---|---|---|
| Producer Hub (SC-7) | Supplier search | Top of screen | "Search suppliers..." |
| Inventory (SC-8) | Product search | Top of screen | "Search products..." |
| Consumer (SC-9) | Customer search | Top of screen | "Search customers..." |
| Finance (SC-10) | Transaction search | Top of screen | "Search transactions..." |
| AI Copilot (SC-14) | Chat search | Bottom message box | "Ask AI..." |

### Filter Patterns

| Screen | Filter Options | Button Location | Sheet |
|---|---|---|---|
| Producer (SC-7) | Rating, MOQ, Lead time, Certification | Right of search | Opens bottom sheet |
| Inventory (SC-8) | Category, Warehouse, Stock status, Price range | Right of search | Opens bottom sheet |
| Consumer (SC-9) | Segment, Tier, Region, Order count | Right of search | Opens bottom sheet |
| Finance (SC-10) | Date range, Account, Category, Amount range | Right of search | Opens bottom sheet |
| Reports (SC-11) | Date range, Channel, Product, Region | Top section | Horizontal picker |

---

## Navigation Guidelines — Hướng Dẫn Điều Hướng

### Back Navigation

- **Back Button:** Always present in top-left of detail screens
- **Swipe Back:** Gesture support (iOS native, Android edge-swipe)
- **Bottom Sheet:** Swipe down to close or tap backdrop
- **Modal:** Tap "Cancel" or close icon
- **Breadcrumb:** For multi-level drills (rarely used on mobile)

**Example:**
```
Home (SC-6)
├─ Tap Producer tab
└─ Producer Hub (SC-7)
   ├─ Tap Supplier card
   └─ Supplier Detail (SC-15)
      ├─ Tap "Products" tab
      └─ Product card
         ├─ Tap Product
         └─ Product Detail (SC-16)
            └─ Back → Product list → Supplier Detail → Producer Hub
```

### Tab Persistence

- **Bottom Navigation:** Remembers selected tab when returning
- **Module Tabs:** Remembers active tab when navigating away
- **Example:** User in Inventory → View Product Detail → Back → Still on same Inventory tab

### State Management

- **Scroll Position:** List maintains scroll when navigating back
- **Filter State:** Filters remain active until cleared
- **Search Term:** Search remains visible for quick re-filter
- **Form Draft:** Unsaved form data persists (warn on discard)

---

## Accessibility in Navigation

### Focus Management

- **Focus starts** at top of new screen (H1 or top-left button)
- **Focus trapped** in modals (Tab cycles within modal only)
- **Focus released** on modal close (returns to previous focus)

### Screen Reader Announcements

- **Screen title** announced on load
- **Tab change** announced: "Producer tab, selected"
- **List item count** announced: "Product list, 12 items"
- **Success action** announced: "Product saved, navigating to list"

### Keyboard Navigation

- **Tab/Shift-Tab:** Navigate between focusable elements
- **Arrow keys:** Navigate within lists or tab bars
- **Enter/Space:** Activate buttons
- **Escape:** Close modals, cancel actions

---

## Related Documentation

- **Component Library:** COMPONENT-LIBRARY.md (UI component specs)
- **Design System:** DESIGN-SYSTEM-DRAFT.md (visual language)
- **Terminology:** TERMINOLOGY.md (consistent naming)
- **UI/UX Concepts:** UI-UX-CONCEPT-INVENTORY.md (screen references)

---

**Version:** 1.0  
**Date:** 2026-07-13  
**Status:** ✅ COMPLETE  
**Maintained By:** Claude Code (Developer Agent)  
**Next Review:** 2026-08-13

