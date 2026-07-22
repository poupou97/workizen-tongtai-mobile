# Business Capability Model

## Mô Hình Khả Năng Kinh Doanh

---

## English — Business Capabilities

**Purpose:** This document maps the 8 core business capabilities of Tổng Tài, showing how each capability delivers value, supports user journeys, and interacts with other capabilities.

### Capability 1: Producer (Nguồn Hàng)

**Name:** Producer  
**Alternative names:** Sourcing Hub, Supplier Ecosystem  
**Primary Screen:** SC-7 (Producer Hub)

**Description:**  
Producer is the sourcing and supply chain discovery engine. It enables businesses to find suppliers, research markets, identify arbitrage opportunities, and explore cross-border sourcing options. AI continuously surfaces new opportunities based on business intelligence.

**Business Value:**
- Reduces supplier search time by 70% through AI discovery
- Enables market arbitrage (buy low, sell high in different markets)
- Identifies cross-border sourcing for margin improvement
- Provides trend forecasting for proactive sourcing

**Key Capabilities:**
- Opportunity Discovery (AI finds arbitrage, trends, gaps)
- Supplier Scoring (rate suppliers by quality, cost, reliability)
- Trend Forecasting (Google Trends, market intelligence)
- Cross-border Research (regulatory, logistics, pricing)
- Market Intelligence (competitor analysis, pricing benchmarks)
- Supplier Rating & Reviews (community feedback)
- Smart Recommendations (personalized to business profile)

**Supported User Journeys:**
- "Enter US market" → Find suppliers + understand regulations
- "Diversify suppliers" → Compare options + assess risk
- "Follow a trend" → Discover trending products + suppliers

**Related Screens:**
- SC-7: Producer Hub (overview + opportunities + suppliers + trends)
- SC-13: Opportunity Hub (opportunity cards + AI insights)
- SC-15: Supplier Detail (rating, products, reviews, contact)
- (Assumed) Trend Detail, Opportunity Detail, Supplier Comparison

**Dependencies:**
- **Inventory** (to validate if product fits catalog)
- **AI Copilot** (for discovery, scoring, recommendations)
- **Integration Map** (Shopee API, Amazon, Google Trends, trade data)

**Maturity Levels:**
- **MVP (Phase 1):** Opportunity discovery, supplier list, basic scoring
- **Phase 2:** Supplier comparison tools, historical performance tracking, custom supplier network
- **Phase 3:** Predictive supplier reliability, supplier compliance monitoring, marketplace integrations

---

### Capability 2: Inventory (Tồn Kho)

**Name:** Inventory  
**Alternative names:** Product & Warehouse Management  
**Primary Screen:** SC-8 (Inventory Overview)

**Description:**  
Inventory is the product and warehouse management system. It maintains a catalog of products, tracks stock across multiple warehouses, manages pricing and promotions, and provides stock-level insights. AI forecasts demand and alerts on stock-outs.

**Business Value:**
- Single source of truth for all products and stock
- Real-time visibility across multiple warehouses
- Prevents stockouts and overstock through forecasting
- Enables multi-channel pricing management
- Supports document tracking (COO, certificates, compliance)

**Key Capabilities:**
- Product Catalog Management (SKU, images, details)
- Warehouse Management (location, capacity, transfers)
- Stock Tracking (real-time, by product/warehouse)
- Pricing Management (multi-channel, promotions)
- Demand Forecasting (AI predicts stock needs)
- Stock Alerts (low stock, overstock, expiry)
- Category Management (organize products)
- Variant Management (colors, sizes, versions)
- Document Tracking (certificates, compliance, origin)

**Supported User Journeys:**
- "Launch a new product" → Add to catalog + set up warehouse + pricing
- "Manage seasonal inventory" → Adjust stock + create promotions
- "Optimize warehouse space" → Analyze stock distribution + rebalance

**Related Screens:**
- SC-8: Inventory Overview (products, warehouses, categories, SKU, pricing, documents)
- SC-16: Product Detail (revenue, profit, stock by warehouse, pricing, sales channels, analytics)
- (Assumed) Warehouse Detail, Category Detail, Create Product, Stock Transfer

**Dependencies:**
- **Consumer** (to understand demand by customer segment)
- **Finance** (to track inventory value + cost)
- **Reports** (to visualize inventory trends)
- **AI Copilot** (for demand forecasting + alerts)

**Maturity Levels:**
- **MVP (Phase 1):** Product catalog, stock tracking, basic warehouses
- **Phase 2:** Demand forecasting, stock alerts, pricing management
- **Phase 3:** Automated reordering, supplier integration for auto-replenishment, barcode scanning

---

### Capability 3: Consumer (Khách Hàng)

**Name:** Consumer  
**Alternative names:** Customer Intelligence Ecosystem, CRM Platform  
**Primary Screen:** SC-9 (Consumer Hub)

**Description:**  
Consumer is the customer intelligence platform. It consolidates all customer touchpoints into a unified CRM, provides a 360-degree view of each customer, enables customer segmentation, and supports omnichannel communication. AI identifies high-value customers and predicts churn.

**Business Value:**
- Single customer view across all channels
- Segment customers for targeted marketing
- Predict customer churn before it happens
- Identify upsell/cross-sell opportunities
- Track customer lifetime value
- Manage affiliate and community programs

**Key Capabilities:**
- Customer Relationship Management (contact, interaction history)
- Customer Data Platform (CDP) (unified profile, data enrichment)
- Omnichannel Management (Shopee, Facebook, TikTok, web)
- Order Management (track customer orders, history)
- Customer Segmentation (behavioral, demographic, value-based)
- Communication Management (email, SMS, chat, push)
- Customer Reviews & Feedback (collect, respond, analyze)
- Affiliate Program Management (partner tracking, commissions)
- Community Management (customer community, peer support)
- Churn Prediction (AI identifies at-risk customers)

**Supported User Journeys:**
- "Grow repeat customers" → Segment customers + create loyalty program + track retention
- "Launch a campaign" → Target segment + compose message + measure results
- "Understand customer feedback" → Collect reviews + analyze sentiment + respond

**Related Screens:**
- SC-9: Consumer Hub (CRM, CDP, Channels, Orders, Inbox, Reviews, Affiliate, Community, Segments)
- (Assumed) Customer Detail, Order Detail, Segment Detail, Campaign View

**Dependencies:**
- **Inventory** (to track customer purchases across products)
- **Finance** (to calculate customer lifetime value)
- **Business Journey** (to engage customers in marketing journeys)
- **Reports** (to analyze customer metrics)
- **AI Copilot** (for segmentation, churn prediction, recommendations)

**Maturity Levels:**
- **MVP (Phase 1):** Customer list, basic contact info, order history
- **Phase 2:** Segmentation, communication management, churn prediction
- **Phase 3:** Advanced CDP, community platform, AI-driven personalization

---

### Capability 4: Finance (Tài Chính)

**Name:** Finance  
**Alternative names:** Business Accounting & Analysis  
**Primary Screen:** SC-10 (Finance Module)

**Description:**  
Finance is the business accounting and financial analysis engine. It tracks all revenue and expenses, calculates profit margins, forecasts cash flow, manages accounts payable/receivable, and provides financial health dashboards. AI detects anomalies and optimizes spending.

**Business Value:**
- Real-time visibility into financial health
- Automates expense categorization and reporting
- Forecasts cash flow to prevent liquidity crises
- Identifies cost reduction opportunities
- Calculates profitability by product/channel
- Enables data-driven financial decisions

**Key Capabilities:**
- Revenue Tracking (by product, channel, customer)
- Expense Management (receipt capture, categorization, approval)
- Profit Calculation (gross, net, by product/channel)
- Cash Flow Forecasting (AI predicts liquidity)
- Account Management (receivable, payable, bank reconciliation)
- Transaction Tracking (sales, purchases, transfers)
- Financial Reporting (P&L, balance sheet, cash flow)
- Tax Support (categorization, deduction tracking)
- Cost Optimization (identify savings opportunities)
- Anomaly Detection (unusual transactions, fraud prevention)

**Supported User Journeys:**
- "Understand business profitability" → View P&L + profit by product/channel
- "Plan for cash flow" → Forecast cash needs + identify funding gaps
- "Optimize costs" → Analyze spending + identify savings + adjust budget

**Related Screens:**
- SC-10: Finance Module (revenue, expenses, profit, cash flow, accounts, transactions, reports)
- (Assumed) Financial Report Detail, Transaction Detail, Budget View

**Dependencies:**
- **Inventory** (to track cost of goods sold)
- **Consumer** (to track revenue by customer)
- **Reports** (to visualize financial metrics)
- **AI Copilot** (for anomaly detection + forecasting + recommendations)

**Maturity Levels:**
- **MVP (Phase 1):** Revenue/expense tracking, basic financial reporting
- **Phase 2:** Cash flow forecasting, cost analysis, tax support
- **Phase 3:** Advanced financial modeling, automated reconciliation, tax filing integration

---

### Capability 5: Reports (Báo Cáo)

**Name:** Reports  
**Alternative names:** Business Analytics & Insights  
**Primary Screen:** SC-11 (Reports Dashboard)

**Description:**  
Reports is the business analytics and insights engine. It aggregates data from all modules (Producer, Inventory, Consumer, Finance) and provides unified dashboards, KPI tracking, trend analysis, and predictive insights. AI surfaces actionable recommendations.

**Business Value:**
- Single dashboard for all business metrics
- Identify trends and patterns automatically
- Predict future performance (sales, revenue, churn)
- Benchmark against industry/competitors
- Support data-driven decision making
- Track progress against goals

**Key Capabilities:**
- KPI Dashboard (revenue, profit, growth, efficiency)
- Channel Breakdown (revenue, orders, customers by channel)
- Product Performance (sales, revenue, margins by product)
- Customer Metrics (acquisition, retention, LTV, churn)
- Trend Analysis (historical data, forecasting)
- Anomaly Detection (unusual metrics, alerts)
- Custom Reports (flexible reporting templates)
- Comparison Analytics (month-over-month, year-over-year)
- Competitor Benchmarking (market position, pricing)
- Predictive Insights (AI forecasts future metrics)

**Supported User Journeys:**
- "Review business performance" → View dashboard + drill into details
- "Prepare for board meeting" → Generate reports + analyze trends
- "Make strategic decisions" → Analyze alternatives + forecast outcomes

**Related Screens:**
- SC-11: Reports Dashboard (KPIs, channel breakdown, trend analysis, AI insights)
- (Assumed) Report Detail, Comparison View, Forecast View

**Dependencies:**
- **Producer** (trend data + opportunity metrics)
- **Inventory** (product performance metrics)
- **Consumer** (customer metrics)
- **Finance** (financial metrics)
- **Business Journey** (goal tracking, progress)
- **AI Copilot** (for analysis, anomaly detection, predictions)

**Maturity Levels:**
- **MVP (Phase 1):** Basic dashboards, KPI tracking, simple analytics
- **Phase 2:** Advanced analytics, predictive insights, custom reports
- **Phase 3:** AI-driven insights, industry benchmarking, scenario planning

---

### Capability 6: Business Journey (Hành Trình Doanh Nghiệp)

**Name:** Business Journey  
**Alternative names:** Goal-Driven Orchestration  
**Primary Screen:** SC-12 (Business Journey)

**Description:**  
Business Journey is the goal orchestration engine. It enables businesses to set strategic goals, receive AI-generated step-by-step plans, track progress, and receive adaptive guidance. Each journey is a narrative from goal to achievement.

**Business Value:**
- Breaks down complex goals into manageable steps
- Provides AI-guided roadmap with timelines
- Tracks progress and keeps business on track
- Adapts plan based on actual progress
- Connects business opportunities to goals
- Celebrates milestones and provides motivation

**Key Capabilities:**
- Goal Definition (user specifies business intent)
- Journey Planning (AI generates 8-step roadmap)
- Milestone Tracking (progress, status, timeline)
- Mission Management (groups of related steps)
- Task Breakdown (daily work items)
- Playbook Reference (similar successes from community)
- AI Guidance (in-journey chat, recommendations)
- Progress Forecasting (AI predicts time to goal)
- Adaptive Planning (adjust plan based on progress)
- Opportunity Connection (surface relevant opportunities)

**Supported User Journeys:**
- "Enter new market" → Define goal → Get AI plan → Track progress
- "Scale revenue" → Define goal → Get AI plan → Track milestones
- "Expand product line" → Define goal → Get AI plan → Get recommendations

**Related Screens:**
- SC-12: Business Journey (goal, 80% progress, 8-step plan, AI assist, forecast)
- (Assumed) Journey Detail, Mission Detail, Task Detail, Step Execution

**Dependencies:**
- **Producer** (surface sourcing opportunities)
- **Inventory** (connect to product launches)
- **Consumer** (connect to customer growth)
- **Finance** (track financial impact)
- **Reports** (progress tracking against metrics)
- **AI Copilot** (planning, guidance, adaptation)

**Maturity Levels:**
- **MVP (Phase 1):** Goal setting, AI-generated plans, progress tracking
- **Phase 2:** Multi-journey management, adaptive replanning, playbook library
- **Phase 3:** Collaborative journeys, team-based execution, community playbooks

---

### Capability 7: Opportunity Hub (Sàn Cơ Hội)

**Name:** Opportunity Hub  
**Alternative names:** AI Opportunity Engine  
**Primary Screen:** SC-13 (Opportunity Hub)

**Description:**  
Opportunity Hub is the AI-driven opportunity discovery engine. It continuously scans market data, trend data, supplier networks, and business performance to surface profitable opportunities. Each opportunity is scored, analyzed, and connected to potential actions.

**Business Value:**
- Never miss a profitable opportunity
- AI scores opportunities by ROI and risk
- Reduce manual market research time by 80%
- Surface opportunities matched to business profile
- Connect opportunities to execution (via Journey or direct action)
- Enable proactive growth instead of reactive management

**Key Capabilities:**
- Opportunity Discovery (arbitrage, trends, market gaps, cross-border)
- Opportunity Scoring (ROI estimation, risk assessment)
- Market Analysis (competitive landscape, pricing benchmarks)
- Trend Intelligence (Google Trends, social signals, market data)
- Arbitrage Detection (price differences across channels)
- Cross-border Opportunities (regulations, logistics, pricing)
- Opportunity Alerts (new opportunities matching profile)
- Opportunity Save/Follow (for later action)
- Smart Recommendations (personalized to business)
- Connection to Action (pursue in Producer, launch via Journey)

**Supported User Journeys:**
- "Diversify revenue" → Browse opportunities → Analyze potential → Pursue
- "Enter new market" → Receive opportunity alerts → Filter + analyze → Launch journey
- "Spot trends" → View trending products → Find suppliers → Plan entry

**Related Screens:**
- SC-13: Opportunity Hub (opportunities feed, AI insights, save/follow)
- (Assumed) Opportunity Detail (arbitrage analysis, market data, supplier options, pursue action)

**Dependencies:**
- **Producer** (source opportunities)
- **Inventory** (validate product fit)
- **Consumer** (match to customer demand)
- **Finance** (ROI calculation)
- **Reports** (trend analysis)
- **AI Copilot** (discovery, scoring, alerts)

**Maturity Levels:**
- **MVP (Phase 1):** Opportunity discovery, basic scoring, opportunity feed
- **Phase 2:** Advanced scoring, opportunity clustering, follow-up tracking
- **Phase 3:** Predictive opportunities, community opportunity sharing, opportunity marketplace

---

### Capability 8: AI Business Copilot (AI Tổng Tài)

**Name:** AI Business Copilot  
**Alternative names:** Unified AI Assistant  
**Primary Screen:** SC-14 (AI Business Copilot)

**Description:**  
AI Business Copilot is the unified AI assistant embedded throughout Tổng Tài. It provides chat-based guidance, business recommendations, health alerts, and intelligent suggestions. It acts as business advisor, planner, executor, monitor, and optimizer.

**Business Value:**
- 24/7 business advisor in the user's pocket
- Contextual recommendations at point of decision
- Proactive alerts on business risks
- Saves time on routine analysis and planning
- Improves decision quality through AI insights
- Reduces dependency on external consultants

**Key Capabilities:**
- Conversational Interface (chat-based Q&A)
- Business Recommendations (context-aware suggestions)
- Health Alerts (risks, opportunities, anomalies)
- Data Summarization (digest complex data into insights)
- Document Intelligence (OCR, document analysis)
- Plan Generation (journey planning, goal breakdown)
- Market Research (trend analysis, competitor research)
- Decision Support (pros/cons, scenario analysis)
- Learning & Adaptation (personalized to business profile)
- Proactive Notifications (alerts, suggestions, opportunities)

**Supported User Journeys:**
- "Need business advice" → Chat with copilot → Get recommendations → Take action
- "Understand business health" → View health summary → Drill into issues
- "Plan next steps" → Ask copilot → Get guided plan → Execute

**Related Screens:**
- SC-14: AI Business Copilot (chat, recommendations, health metrics, alerts, opportunities)
- (Assumed) Chat Detail, Recommendation Drill-down, Alert Response

**Dependencies:**
- All other capabilities (Producer, Inventory, Consumer, Finance, Reports, Journey, Opportunity)
- External AI models (xAI, OpenRouter, etc.)
- Document intelligence (OCR, analysis)

**Maturity Levels:**
- **MVP (Phase 1):** Chat interface, basic recommendations, business summaries
- **Phase 2:** Proactive alerts, market research, document intelligence
- **Phase 3:** Advanced reasoning, multi-step planning, autonomous task execution

---

## Capability Interactions — Tương Tác Giữa Các Khả Năng

### Dependency Matrix

| From ↓ To → | Producer | Inventory | Consumer | Finance | Reports | Journey | Opportunity | Copilot |
|---|---|---|---|---|---|---|---|---|
| **Producer** | — | Validates products | — | — | — | — | Execution path | Data source |
| **Inventory** | Filter options | — | Demand signal | COGS tracking | Performance data | Execution | Triggers discovery | Data source |
| **Consumer** | — | Purchase patterns | — | Revenue signal | Customer metrics | Engagement | Demand validation | Data source |
| **Finance** | ROI calculation | Cost tracking | LTV calculation | — | Key metrics | Budget constraints | Scoring input | Data source |
| **Reports** | Analysis | Analysis | Analysis | Analysis | — | Progress tracking | Performance review | Insight source |
| **Journey** | Sourcing action | Product launch | Customer growth | Financial goal | Track progress | — | Execution path | Guidance provider |
| **Opportunity** | Primary source | Validation | Demand check | ROI estimate | Performance data | Connection | — | Scoring engine |
| **Copilot** | Scorer | Forecaster | Segmenter | Analyzer | Analyzer | Planner | Discoverer | — |

### Data Flow Example: "Pursue an Opportunity"

```
Opportunity Hub (SC-13)
  ↓ [User sees opportunity: "Sell USA stitched apparel"]
AI Copilot (SC-14)
  ↓ [Scores ROI, market fit]
Business Journey (SC-12)
  ↓ [Generate plan: "Enter US Market" in 8 steps]
Producer (SC-7)
  ↓ [Find suppliers for apparel]
Inventory (SC-8)
  ↓ [Add new product, set up warehouse]
Consumer (SC-9)
  ↓ [Target US customers, create campaign]
Finance (SC-10)
  ↓ [Track revenue, margins, cash flow]
Reports (SC-11)
  ↓ [Monitor progress, ROI vs forecast]
```

---

## Success Metrics by Capability

| Capability | MVP Success Metric | Phase 2 Metric |
|---|---|---|
| **Producer** | 50+ opportunities surfaced | Avg opportunity ROI score > 70% |
| **Inventory** | 100% product/stock visibility | Forecast accuracy > 85% |
| **Consumer** | 360° customer view | Churn prediction accuracy > 80% |
| **Finance** | Real-time P&L | Cash flow forecast MAPE < 15% |
| **Reports** | Dashboard renders < 2s | Anomaly detection F1 > 0.8 |
| **Journey** | 1 active journey per user | Adaptive replan success > 70% |
| **Opportunity** | 10+ opportunities/week | Opportunity conversion > 30% |
| **Copilot** | Chat response < 3s | Recommendation adoption > 50% |

---

## Conclusion

These 8 capabilities form an integrated system where each capability enhances the others. Producer discovers opportunities, Inventory manages products, Consumer understands customers, Finance tracks results, Reports analyze performance, Journey orchestrates goals, Opportunity surfaces options, and Copilot guides decisions. Together, they create a unified business operating system.

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B  
**Related Docs:** PRODUCT-VISION.md, BUSINESS-JOURNEY-BIBLE.md, OPPORTUNITY-ENGINE.md, AI-BUSINESS-COPILOT.md  
**Next:** DOMAIN-DATA-MODEL.md
