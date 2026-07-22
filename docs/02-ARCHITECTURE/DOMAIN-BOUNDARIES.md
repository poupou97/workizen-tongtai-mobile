# Domain Boundaries

## Ranh Giới Miền

---

## English — What IS and IS NOT Tổng Tài

**Purpose:** This document clearly defines the in-scope and out-of-scope features and responsibilities for Tổng Tài, preventing scope creep and clarifying module boundaries.

---

## Core Promise — What Tổng Tài IS

**Tổng Tài is an AI-first Business Operating System for entrepreneurs and SMEs.**

It consolidates the business owner's key decision-making and execution needs into one app:

- **See** your business clearly (unified data, real-time metrics)
- **Decide** confidently (AI insights, recommendations, forecasts)
- **Act** quickly (integrated workflows, AI guidance)
- **Grow** systematically (opportunities, journeys, tracking)

---

## Module Scope Matrix

### 1. Producer (Sourcing Hub)

#### ✅ IN SCOPE

**Discovery & Research:**
- AI finds suppliers matching business profile
- Trend discovery (Google Trends, market signals)
- Arbitrage analysis (price differences across markets)
- Cross-border opportunity identification
- Competitor price monitoring

**Supplier Management:**
- Add/manage supplier contacts
- Rate and review suppliers
- Track supplier performance (on-time delivery, quality)
- Store supplier communication history
- Supplier comparison tools

**Opportunity Actions:**
- Save opportunities for later
- Tag opportunities by type (arbitrage, trend, market gap)
- View opportunity details and ROI analysis
- Launch journey from opportunity ("Pursue")

#### ❌ OUT OF SCOPE

- **Supplier payments** (handled by Finance)
- **Purchase order management** (would be Supplier Order capability, Phase 2)
- **Supplier contract drafting** (legal tool, out of scope)
- **Customs/regulatory compliance tracking** (specialized compliance tool, not in MVP)
- **Direct API integration to supplier catalogs** (Phase 2, marketplace integration)

---

### 2. Inventory (Product & Warehouse Management)

#### ✅ IN SCOPE

**Product Catalog:**
- Add products with SKU, name, description, images
- Manage product variants (sizes, colors, versions)
- Track cost and selling price
- Assign products to categories
- Store product metadata (barcode, weight, dimensions)

**Warehouse Management:**
- Add warehouse locations (physical or virtual)
- Track capacity and utilization
- Store warehouse contact info
- Move stock between warehouses (transfers)
- Support for 1-N warehouses

**Stock Tracking:**
- Real-time stock levels by product + warehouse
- Reorder points and automatic alerts
- Stock in/stock out tracking (partial)
- Visibility into reserved stock vs available stock
- Stock status indicators (OK, low stock, out of stock, overstock)

**Pricing Management:**
- Multi-channel pricing rules (different price on Shopee vs TikTok vs web)
- Bulk pricing for wholesale customers
- Seasonal or promotion pricing

**Document Tracking:**
- Store product-related documents (certificates, compliance docs, COO)
- No document processing/OCR (that's in Chat/Copilot)

#### ❌ OUT OF SCOPE

- **Purchase Order Management** (buy from suppliers — Phase 2)
- **Bill of Materials (BOM)** (manufacturing planning — out of scope)
- **Supplier Invoice Management** (that's Finance)
- **Barcode Scanning** (Tổng Tài is mobile, scanning would be separate feature in Phase 2)
- **Serial Number Tracking** (ultra-detailed inventory for electronics/pharma — Phase 2)
- **Logistics/Shipping Label Printing** (marketplace/logistics APIs handle this)
- **Returns Management** (would integrate with orders in Consumer)

---

### 3. Consumer (Customer Intelligence)

#### ✅ IN SCOPE

**Customer Data:**
- Import/add customers (email, phone, address, company)
- Store customer contact info and communication history
- Track customer tier (Bronze, Silver, Gold, Platinum)
- Calculate and track Lifetime Value (LTV)
- Order history and payment status

**Customer Relationships:**
- Interaction log (emails sent, calls made, messages)
- Purchase history with dates and amounts
- Customer communication preferences
- Churn risk prediction (AI)

**Segmentation:**
- Create customer segments (behavioral, demographic, value-based)
- Auto-populate segment members based on criteria
- View segment performance (revenue, avg order value, retention)

**Omnichannel:**
- Track which channel customer came from (Shopee, TikTok, Facebook, web)
- Unified customer view across channels (single customer = one record)
- Omnichannel communication (SMS, email, push notification capability)

**Community Features:**
- View customer feedback / reviews
- Affiliate program tracking (customers who refer others)
- Basic community view (customer community groups)

#### ❌ OUT OF SCOPE

- **Marketing Automation** (email campaign creation — Consumer Segment can trigger campaigns, but campaign builder is future)
- **SMS Gateway / Push Notification Infrastructure** (we store preferences, but sending is via partner)
- **Payment Processing** (Stripe, Shopee, etc. are external)
- **Customer Support Ticketing** (Help desk is separate product)
- **Advanced CDP Features** (data enrichment from third-party sources like Clearbit)
- **Customer Loyalty Program Management** (tracking only, not platform)

---

### 4. Finance (Business Accounting)

#### ✅ IN SCOPE

**Revenue Tracking:**
- Record sales/revenue from different sources
- Link revenue to customer or order
- Revenue by product, channel, customer
- Track payment status (paid, partial, unpaid, refunded)

**Expense Tracking:**
- Record business expenses
- Categorize expenses (COGS, salary, rent, marketing, etc.)
- Receipt tracking (metadata, not OCR)
- Link expenses to accounts (bank, e-wallet, cash)

**Profit Calculation:**
- Gross profit (revenue - COGS)
- Net profit (revenue - all expenses)
- Profit by product, channel, customer
- Margin analysis

**Cash Flow:**
- Track account balances (bank, e-wallet, cash)
- Project cash flow (AI forecasting)
- Identify cash flow bottlenecks
- Cash runway tracking

**Financial Reporting:**
- P&L statement (Profit & Loss)
- Cash flow statement
- Basic balance sheet view
- Custom financial reports

#### ❌ OUT OF SCOPE

- **Bank Account Integration** (API sync — Phase 2)
- **Bill Management / AP Tracking** (payables tracking — Phase 2)
- **Accounts Receivable Aging** (AR aging details — Phase 2)
- **Tax Calculation & Filing** (complex, country-specific — future)
- **Payroll Management** (employee payments — separate product)
- **Multi-Currency Support** (Phase 2, for cross-border)
- **Advanced Financial Modeling** (complex scenarios — beyond Phase 1)
- **Cryptocurrency / Forex** (not MVP, risky)

---

### 5. Reports (Business Analytics)

#### ✅ IN SCOPE

**KPI Dashboard:**
- Revenue, profit, growth metrics
- Efficiency metrics (ROI, margins, turnover)
- Customer metrics (acquisition, retention, LTV)
- Inventory metrics (turnover, value)

**Breakdown Analytics:**
- Revenue by product, channel, customer, region
- Expenses by category
- Customer acquisition by channel
- Inventory movement by category/warehouse

**Trend Analysis:**
- Historical data visualization (line charts, trends)
- Month-over-month, year-over-year comparison
- Forecasting (AI predicts next month's revenue/expenses)

**Anomaly Detection:**
- Alert on unusual metrics (revenue drop, spike in returns, etc.)
- Automated detection without manual setup

**Custom Reports:**
- Flexible report templates
- Drill-down capabilities
- Export to PDF/CSV

#### ❌ OUT OF SCOPE

- **Advanced BI** (complex data warehouse queries — BI tool)
- **Machine Learning Model Building** (data science — out of scope)
- **Predictive Analytics** (beyond revenue/expense forecasting)
- **Industry Benchmarking Database** (gathering competitor data — ethical/legal questions)
- **Real-time Data Streaming** (complex infrastructure)

---

### 6. Business Journey (Goal Orchestration)

#### ✅ IN SCOPE

**Journey Planning:**
- User sets business goal/intent (e.g., "Enter US market")
- AI generates 8-step plan with timeline
- AI estimates outcomes (revenue, time, investment)

**Journey Execution:**
- Track progress on each step
- Mark steps as complete
- View overall journey progress (%)
- Forecasted time to goal

**Milestone Tracking:**
- Define major milestones within journey
- Track milestone progress
- Celebrate milestone completions

**AI Guidance:**
- Chat with Copilot within journey
- Get step-by-step guidance
- Receive recommendations for next steps
- Reference similar journeys (playbooks)

**Playbook Library:**
- Browse similar journeys others have taken
- Learn from others' experiences
- Get inspired by success stories

#### ❌ OUT OF SCOPE

- **Complex Workflows / BPM** (Workflow engine — Phase 2)
- **Team Collaboration** (task assignment, comments — Phase 2)
- **Custom Journey Templates** (Phase 2 — users create own journey types)
- **Dependency Management** (task A must complete before B — Phase 2)
- **Risk Management** (track risks/blockers — Phase 2)

---

### 7. Opportunity Hub (AI Opportunity Discovery)

#### ✅ IN SCOPE

**Opportunity Discovery:**
- AI scans markets, trends, supplier data
- Surfaces opportunities relevant to business
- Opportunities include: arbitrage, trends, market gaps, cross-border

**Opportunity Analysis:**
- Detailed market analysis (size, growth, competition)
- Profit potential (estimated ROI, investment needed)
- Supplier options for opportunity
- Competitive landscape

**Opportunity Management:**
- Save/bookmark opportunities
- Tag opportunities
- Track pursued opportunities
- View opportunity history

**Scoring & Ranking:**
- AI scores opportunities (0-100)
- Ranked by potential ROI, risk, relevance

#### ❌ OUT OF SCOPE

- **Real-time Market Data Subscriptions** (Bloomberg Terminal is separate)
- **Regulatory Compliance Checks** (country-specific rules — Phase 2)
- **Supplier Vetting** (deep background checks — specialized service)
- **Market Research Reports** (users conduct their own research)

---

### 8. AI Business Copilot (Unified Assistant)

#### ✅ IN SCOPE

**Chat Interface:**
- Conversational Q&A with AI
- Business-specific questions (e.g., "How do I scale revenue?")
- Contextual to user's data (e.g., "Based on your business...")

**Recommendations:**
- Proactive business recommendations
- Based on data analysis and AI reasoning
- Prioritized by potential impact

**Health Alerts:**
- Alert on business risks (revenue drop, churn spike, cash flow issue)
- Opportunity alerts (new market trends, supplier matching)

**Business Summaries:**
- Digest of key metrics
- Daily or weekly summary
- Personalized based on goals

**Document Intelligence:**
- Analyze uploaded documents (receipts, invoices, reports)
- Extract key data automatically
- Answer questions about documents

#### ❌ OUT OF SCOPE

- **Real-time Meeting Transcription** (separate capability, privacy concerns)
- **Email/Messaging Integration** (privacy, complexity — Phase 2)
- **Autonomous Task Execution** (AI directly modifies data without user approval — not MVP)
- **Advanced NLP** (beyond MVP language understanding)

---

## Cross-Module Boundaries

### Producer ↔ Inventory

**Producer responsibility:** Find suppliers, research trends, discover opportunities  
**Inventory responsibility:** Manage products and stock

**Handoff:**
- Producer finds supplier → User adds supplier's products to Inventory
- Inventory warns of low stock → User can go to Producer to find replacement supplier
- Producer finds opportunity → User can add opportunity's product to Inventory

**NOT a handoff:**
- Producer does NOT manage purchase orders (Phase 2)
- Inventory does NOT track supplier contracts (Producer manages)

---

### Consumer ↔ Finance

**Consumer responsibility:** Manage customers, segments, communication  
**Finance responsibility:** Track revenue, expenses, profit

**Handoff:**
- Consumer records sale → Finance sees revenue transaction
- Finance tracks expense → Consumer sees cost attribution (if applicable)
- Consumer creates segment → Finance can report revenue by segment

**NOT a handoff:**
- Consumer does NOT track payments (Finance does)
- Finance does NOT segment customers (Consumer does)

---

### Inventory ↔ Finance

**Inventory responsibility:** Stock levels, product catalog, warehouse management  
**Finance responsibility:** Financial tracking (cost, revenue, profit)

**Handoff:**
- Inventory tracks cost price → Finance uses for COGS calculation
- Finance tracks revenue by product → Inventory shows profitability per SKU
- Inventory calculates inventory value → Finance shows on balance sheet

**NOT a handoff:**
- Inventory does NOT track cash (Finance does)
- Finance does NOT physically move inventory (Inventory does)

---

### Journey ↔ Producer/Inventory/Consumer

**Journey responsibility:** Goal orchestration, step tracking, AI guidance  
**Other modules responsibility:** Execution capabilities

**Handoff:**
- Journey says "Find suppliers" → User goes to Producer
- Journey says "Launch product" → User goes to Inventory
- Journey says "Create segment" → User goes to Consumer
- Journey tracks progress ← Other modules execute actions

**NOT a handoff:**
- Journey does NOT execute actions directly (user does)
- Journey does NOT manage workflows (Phase 2)

---

### Reports ↔ All Other Modules

**Reports responsibility:** Aggregate data, analyze trends, forecast  
**All modules responsibility:** Generate primary data

**Handoff:**
- Modules generate data → Reports reads and analyzes
- Reports identifies anomaly → User drills into specific module to investigate

**NOT a handoff:**
- Reports does NOT modify source data (read-only)
- Modules do NOT aggregate their own analytics (Reports does)

---

## Data Ownership & Boundaries

### User Data

- **User owns:** All business data, customer data, financial data, documents
- **User controls:** Sync to cloud, backup, deletion
- **Tổng Tài role:** Store on device, optionally sync if user enables

### API Keys (BYOK Model)

- **User owns:** API keys for AI providers, payment providers, etc.
- **User controls:** Which providers to use, when to revoke access
- **Tổng Tài role:** Store encrypted on device, use only in Authorization headers, never send to server

### Cloud Features

- **Tổng Tài Phase 1 (MVP):** Local-first, no required cloud sync
- **Future phases:** User-opted cloud backup, multi-device sync
- **Always optional:** Never force cloud if user prefers device-only

---

## Performance Boundaries

### Real-Time Requirements

| Feature | Requirement |
|---|---|
| Dashboard load | < 2 seconds |
| List/search results | < 1 second |
| Chart rendering | < 1.5 seconds |
| Chat response | < 3 seconds |
| Save action | < 500ms |
| Notification alert | Immediate |

### Data Volume Limits (MVP)

| Entity | MVP Limit | Phase 2 Limit |
|---|---|---|
| Products | 1,000 | 10,000+ |
| Customers | 10,000 | 100,000+ |
| Orders | 50,000 | 1M+ |
| Transactions | 100,000 | 1M+ |
| Warehouses | 5 | 50+ |
| Suppliers | 500 | 5,000+ |

**Note:** Limits are soft. Exceeding them may cause performance degradation. Phase 2 will optimize for larger data sets.

---

## Boundary Between Tổng Tài & External Systems

### What Tổng Tài Integrates With

**Marketplace APIs:**
- Shopee (read product/order data)
- TikTok Shop (read product/order data)
- Facebook Commerce (read product/order data)
- Amazon (read product/order data)
- Goal: Unified customer/order view

**AI Providers:**
- xAI (recommendations, insights)
- OpenRouter (alternative models)
- OpenAI API (if user provides key)
- Goal: AI features without vendor lock-in

**Payment Systems:**
- Stripe (read transaction data, future payment collection)
- E-wallets (Momo, ZaloPay API reads)
- Goal: Unified payment tracking

### What Tổng Tài Does NOT Do

- **Email/SMS sending** (partner services handle sending, Tổng Tài stores preferences)
- **Payment processing** (marketplace + payment gateways do this)
- **Accounting software sync** (Phase 2, for QuickBooks, Xero)
- **CRM system sync** (separate CRM products handle this)
- **Help desk ticketing** (separate support product)
- **Project management** (Jira, Asana, etc. own this)

---

## Scope Creep Prevention — What NOT to Add

### ❌ DO NOT ADD (Ever)

- **Email/SMS campaign management** (ConvertKit, Mailchimp domain)
- **Advanced CRM features** (Salesforce domain)
- **ERP features** (SAP, NetSuite domain)
- **HR/Payroll** (BambooHR, Gusto domain)
- **Compliance/Legal** (specialized regulatory tools)
- **Accounting software** (QuickBooks, Xero domain)
- **CMS/Website builder** (Wix, Shopify domain)

### ⚠️ CAREFULLY CONSIDER (Likely Phase 2+)

- Purchase order management (supplier ordering)
- Workflow/automation (complex multi-step processes)
- Team collaboration (multiple users, assignments)
- Advanced BI (data warehouse, custom queries)
- Marketplace integrations (expand to more channels)
- Bank account sync (automated reconciliation)
- Custom fields (user-defined data)

### ✅ PRIORITIZE (Phase 1 & Early Phase 2)

- Core modules fully working (Producer, Inventory, Consumer, Finance, Reports, Journey, Opportunity)
- Mobile excellence (fast, responsive, touch-optimized)
- AI quality (accurate recommendations, predictions)
- Data integrity (no corruption, proper backups)
- User onboarding (easy first-time setup)

---

## Success Definition for Scope

**Phase 1 MVP Success:**
- All 8 core capabilities work independently
- Cross-module integrations work smoothly
- Real-time data visibility for business metrics
- AI provides useful recommendations
- Users can complete key workflows (opportunity → journey → execution)

**No scope expansion until MVP ships and user validates product-market fit.**

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B  
**Date:** 2026-07-13  
**Related Docs:** BUSINESS-CAPABILITY-MODEL.md, SCREEN-FLOW.md  
**Next:** INTEGRATION-MAP.md
