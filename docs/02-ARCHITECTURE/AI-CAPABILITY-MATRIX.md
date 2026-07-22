# AI Capability Matrix

## Ma Trận Khả Năng AI

---

## English — AI Features & Requirements

**Purpose:** This document maps all AI features in Tổng Tài, showing what data they need, where they're used, what they produce, and their cost/performance characteristics.

---

## AI Features Summary

**Total AI Features:** 12+  
**By Category:**
- **Discovery:** 3 (Opportunity discovery, Supplier scoring, Trend detection)
- **Intelligence:** 4 (Demand forecasting, Churn prediction, Sentiment analysis, Insight generation)
- **Planning:** 2 (Journey planning, Task recommendation)
- **Guidance:** 2 (Chat/conversation, Context-aware help)
- **Optimization:** 1+ (Price optimization, inventory balancing)

---

## Discovery Features

### 1. Opportunity Discovery

**Purpose:** AI finds business opportunities (arbitrage, trends, market gaps)  
**Where Used:** Opportunity Hub (SC-13), Producer (SC-7), Home Dashboard  
**User Goal:** "Never miss a profitable opportunity"

**What It Does:**
1. Scans Google Trends data (trending search terms)
2. Correlates with Shopee/TikTok data (what's selling)
3. Cross-references with supplier data (cost structures)
4. Calculates potential arbitrage (buy low, sell high in different markets)
5. Scores opportunities by ROI, risk, relevance

**Input Data Needed:**
- User's business profile (industry, size, revenue, geography)
- User's sales history (what they currently sell)
- User's customer profile (who buys from them)
- Market trend data (Google Trends, social signals)
- Supplier catalogs (pricing data)
- Competitor pricing (if available)

**Output Generated:**
- Opportunity card (title, market, ROI estimate, risk level)
- Opportunity detail (full analysis, suppliers, action steps)
- Score (0-100, AI confidence)
- Recommendation (pursue or skip)

**AI Model Required:**
- Language model (xAI Grok-2): analysis + scoring
- Optional: Vision model (for product image analysis)

**Performance:**
- Discovery frequency: Daily or on-demand
- Typical execution: 5-10 seconds per opportunity analysis
- Cost: ~0.01-0.05 USD per opportunity (xAI tokens)

**Example:**
```
User's profile: E-commerce seller in Vietnam, apparel focus, $500K annual revenue
Google Trends data: "Stitched polyester" trending +25% in US
Shopee data: Users selling similar products at $8 wholesale
Amazon data: US buyers paying $25 retail
AI Analysis:
  - Arbitrage opportunity: $8 cost → $25 retail = $17 profit
  - Market size: ~10K searches/month in US
  - Potential revenue: $170K/month if captured 1% of market
  - Investment needed: $5K for initial stock
  - Risk: Medium (requires FBA setup, logistics)
  
Output:
  - Opportunity score: 85/100
  - Recommendation: "HIGH POTENTIAL - Pursue this"
  - Suggested next step: "Find 3 suppliers in Producer tab"
```

**MVP Status:** ✅ Built (basic discovery)

**Phase 2 Improvements:**
- Real-time trend monitoring (not just daily)
- Social media signal integration (TikTok trending sounds, Instagram hashtags)
- Competitor analysis (track competitor pricing over time)
- Market size estimation (more accurate)
- Seasonality detection (when to launch, when to wind down)

---

### 2. Supplier Scoring

**Purpose:** AI ranks suppliers by quality, reliability, value  
**Where Used:** Producer (SC-7), Supplier Detail (SC-15)  
**User Goal:** "Find trustworthy suppliers quickly"

**What It Does:**
1. Collects supplier data (name, country, certifications, reviews, price, lead time)
2. Weighs multiple factors (quality, speed, cost, reliability)
3. Generates score (0-100)
4. Creates recommendation (suitable for this business profile?)

**Input Data Needed:**
- Supplier information (country, industry, certifications)
- Historical reviews (from community or Alibaba/Global Sources)
- Pricing data (MOQ, unit price, payment terms)
- Lead time information
- User's requirements (quality level, price sensitivity, speed)

**Output Generated:**
- Score (0-100): Overall supplier rating
- Component scores: Quality (40%), Reliability (30%), Value (20%), Speed (10%)
- Recommendation: Suitable for this business?
- Risk assessment: Low, Medium, High

**AI Model Required:**
- Language model: weighing factors, scoring logic
- Optional: Document analysis (certifications)

**Performance:**
- Scoring: Real-time (instant)
- Cost: ~0.001-0.005 USD per supplier (low token usage)

**Example:**
```
Supplier: "XYZ Apparel Factory" (China)
Data collected:
  - Certifications: ISO 9001, BSCI
  - Alibaba reviews: 4.8/5 (500+ reviews)
  - MOQ: 100 units
  - Price: $5 per piece
  - Lead time: 15-20 days
  - Payment: 50% deposit

AI Scoring:
  - Quality score: 90/100 (certifications + reviews)
  - Reliability: 88/100 (historical delivery performance)
  - Value: 75/100 ($5 is mid-range for stitched apparel)
  - Speed: 70/100 (15-20 days is standard)
  
Overall: 82/100 ✅ "TRUSTED SUPPLIER"
Recommendation: "Good fit for your quality standards. Price is competitive."
```

**MVP Status:** ✅ Built (basic scoring)

**Phase 2 Improvements:**
- Integration with supplier databases (automatic data collection)
- Fraud detection (flagging suspicious suppliers)
- Delivery tracking (predict reliability from actual performance)
- Price trend analysis (is price rising/falling?)

---

### 3. Trend Detection

**Purpose:** AI identifies rising trends relevant to user's business  
**Where Used:** Producer (SC-7) Trend tab, Reports  
**User Goal:** "Know what's trending before competitors"

**What It Does:**
1. Monitors Google Trends for relevant keywords
2. Correlates with sales data (what's users buying now?)
3. Predicts trend trajectory (will it grow or fade?)
4. Suggests actions (stock up, launch marketing, etc.)

**Input Data Needed:**
- User's industry keywords (e.g., "stitched apparel", "polyester", "eco-friendly")
- Google Trends data (historical + current)
- User's sales history (what's selling)
- Social media signals (if available)
- Competitor monitoring (what are competitors selling?)

**Output Generated:**
- Trend card (keyword, trend direction, forecast)
- Trend graph (historical, with forecast)
- Suggestion: Actions to capitalize (stock up, create content, etc.)

**AI Model Required:**
- Time series forecasting: trend projection
- Language model: action suggestions

**Performance:**
- Frequency: Daily check
- Forecasting: 7-day, 30-day, 90-day projections
- Cost: ~0.01-0.03 USD per trend analysis

**Example:**
```
Trend: "Stitched sustainable polyester apparel"
Historical data:
  - Month 1: 100 searches
  - Month 2: 125 searches (+25%)
  - Month 3: 160 searches (+28%)
  - Month 4: 200 searches (+25%)

AI Forecast (next 3 months):
  - Month 5: ~250 searches (+25% growth expected)
  - Month 6: ~300 searches (peak predicted)
  - Month 7: ~280 searches (slight decline as market saturates)

Recommendation:
  - Status: 🔥 RISING TREND
  - Action: "Stock up NOW. Peak expected in Month 6."
  - Alert: "Competitors are jumping on this. Move fast."
```

**MVP Status:** ✅ Built (basic trend detection)

**Phase 2 Improvements:**
- Real-time trending (not just daily)
- Hashtag tracking (#SustainableAF)
- Viral potential prediction (will this blow up?)
- Seasonality analysis (when to launch/retire products)

---

## Intelligence Features

### 4. Demand Forecasting

**Purpose:** AI predicts future product demand  
**Where Used:** Inventory (SC-8), Finance (SC-10), Reports (SC-11)  
**User Goal:** "Know how much to order without overstock"

**What It Does:**
1. Analyzes historical sales data (last 12 months)
2. Identifies seasonality (summer sales higher? holiday peaks?)
3. Detects trends (growth rate over time)
4. Generates forecast (next 30/90 days demand)

**Input Data Needed:**
- Historical sales by product (past 12 months minimum)
- Seasonality factors (holidays, seasons, events)
- Current inventory levels
- Promotional calendar (planned sales events)
- External signals (trends, competitor activity, macro events)

**Output Generated:**
- Forecast: Expected units sold next 30/90 days
- Confidence interval: "likely 80-120 units (80% confidence)"
- Recommendation: "Reorder 100 units to stay ahead"

**AI Model Required:**
- Time series forecasting (ARIMA, Prophet, or equivalent)
- Language model: generating recommendations

**Performance:**
- Accuracy target: MAPE < 20% (mean absolute percentage error)
- Frequency: Daily or weekly update
- Execution time: < 2 seconds
- Cost: ~0.01-0.02 USD per product (low cost)

**Example:**
```
Product: Red T-Shirt (SKU: TS-RED-01)
Historical sales:
  - Jan: 50 units
  - Feb: 55 units
  - Mar: 45 units (dip due to weather)
  - Apr: 60 units
  - May: 75 units (trending up)
  - Jun: 80 units (summer)
  - Jul: 85 units
  - Aug: 90 units (peak summer)
  - Sep: 70 units (back-to-school, mixed)
  - Oct: 65 units
  - Nov: 100 units (holiday prep)
  - Dec: 150 units (holiday peak)

AI Forecast (Next 30 days = Jan):
  - Expected demand: 55-65 units (forecast: 60 units)
  - Confidence: 85%
  - Recommendation: "Order 80 units to build buffer. Demand rising."

AI Forecast (Next 90 days = Jan-Mar):
  - Seasonal pattern: Dip in March (colder weather)
  - Total forecast: 170 units (55+60+55 avg)
  - Recommendation: "March dip expected. Don't overbuy then."
```

**MVP Status:** ✅ Built (basic forecasting)

**Phase 2 Improvements:**
- Incorporate external signals (weather, events, competitor actions)
- Customer behavior signals (search patterns, wishlist adds)
- Promotional impact (estimate lift from campaigns)
- Multi-product correlation (bundled products)

---

### 5. Churn Prediction

**Purpose:** AI identifies customers likely to stop buying  
**Where Used:** Consumer (SC-9), Reports (SC-11), AI Copilot  
**User Goal:** "Save at-risk customers before they leave"

**What It Does:**
1. Analyzes customer purchase history
2. Identifies behavioral patterns (frequency, recency, spending)
3. Scores churn risk (0-100, where 100 = will definitely churn)
4. Suggests retention actions

**Input Data Needed:**
- Customer purchase history (dates, amounts, products)
- Recency: When was last purchase?
- Frequency: How often do they buy?
- Monetary: How much do they spend?
- Engagement: Do they open emails? Click links?
- Product affinity: What do they buy?

**Output Generated:**
- Churn risk score (0-100)
- Risk category: Low / Medium / High
- Prediction: "70% likely to churn in next 30 days"
- Suggested action: "Send 20% retention offer"

**AI Model Required:**
- Classification model (logistic regression, random forest, or neural network)
- Language model: action recommendations

**Performance:**
- Accuracy target: > 75% precision
- Frequency: Daily or weekly scoring
- Cost: ~0.001 USD per customer (low cost)

**Example:**
```
Customer: Phương (repeat buyer)
Purchase history:
  - First purchase: 12 months ago
  - Purchase frequency: ~2x per month
  - Total spent: $1,200 (high LTV)
  - Last purchase: 45 days ago (normally every 14 days)
  - Email opens: 2 out of last 5 (declining engagement)
  - Reviews: Always 5-star (satisfied)
  - Product affinity: High-end stitched apparel

Churn risk analysis:
  - Recency: 45 days (increasing, bad)
  - Frequency trend: Declining from 2x/month to 1.5x/month (concerning)
  - Engagement: Emails unopened recently (disengaging)
  - Product satisfaction: Still high (not quality issue)

AI Prediction:
  - Churn risk: 65/100 ("MEDIUM-HIGH RISK")
  - Probability of churn in 30 days: 62%
  - Root cause: "Possible switching to competitor OR taking break"
  
Recommendation:
  - Action: "Send 'we miss you' email with 15% discount"
  - Timing: "Send within 3 days (window closing)"
  - Expected impact: "Likely to recover as repeat customer"
```

**MVP Status:** ✅ Built (basic churn prediction)

**Phase 2 Improvements:**
- Cause analysis (why is churn happening?)
- Cohort analysis (do certain customer groups churn more?)
- Win-back campaigns (re-engage churned customers)
- Sensitivity analysis (how much discount needed to retain?)

---

### 6. Sentiment Analysis

**Purpose:** AI understands customer sentiment from reviews/feedback  
**Where Used:** Consumer (SC-9), Reports (SC-11)  
**User Goal:** "Know how customers really feel"

**What It Does:**
1. Reads customer reviews and feedback
2. Extracts sentiment (positive, neutral, negative)
3. Identifies key topics (quality, shipping, price, etc.)
4. Suggests actions (fix common complaints)

**Input Data Needed:**
- Customer reviews (text)
- Customer ratings (1-5 stars)
- Customer messages/comments
- Product feedback

**Output Generated:**
- Sentiment score: -100 (very negative) to +100 (very positive)
- Topics: ["Quality issues", "Shipping delay", "Good value"]
- Trend: Is sentiment improving or declining?
- Suggested action: "Customers complain about shipping. Improve logistics."

**AI Model Required:**
- Sentiment classification (NLP model, pre-trained or fine-tuned)
- Topic extraction (identify key themes)

**Performance:**
- Accuracy: > 85%
- Frequency: Real-time (as reviews come in)
- Cost: ~0.002 USD per review

**Example:**
```
Customer review:
"Product quality is amazing! But shipping took 3 weeks. Very frustrating."

AI Analysis:
- Sentiment: +40/100 (Mixed: positive about product, negative about shipping)
- Topics: ["Quality", "Shipping delay", "Frustration"]
- Breakdown:
  - Product sentiment: +85/100 (very positive)
  - Shipping sentiment: -70/100 (very negative)
  
Aggregated feedback (across 100 reviews):
- Product quality sentiment: +78/100 (strong)
- Shipping sentiment: -35/100 (weak)
- Price sentiment: +50/100 (neutral)
- Customer service sentiment: +60/100 (good)

Recommendation:
  - Strength: Product quality is a major differentiator
  - Weakness: Shipping speed is hurting satisfaction
  - Action: "Negotiate faster shipping with logistics partner"
  - Expected impact: "Could improve overall satisfaction by 20 points"
```

**MVP Status:** 🔄 To-do (Phase 2)

---

### 7. AI Insights Generation

**Purpose:** AI surfaces actionable business insights  
**Where Used:** Home Dashboard, Reports (SC-11), AI Copilot (SC-14)  
**User Goal:** "Understand what's happening in my business"

**What It Does:**
1. Aggregates data from all modules
2. Detects patterns and anomalies
3. Generates natural language insights
4. Prioritizes by business impact

**Input Data Needed:**
- All business data (sales, expenses, customers, inventory, etc.)
- Historical trends
- Benchmarks (if available)
- User's goals (journeys)

**Output Generated:**
- Insight card: "Revenue up 15% last week. Main driver: TikTok channel."
- Anomaly alert: "Churn rate spiked to 8%. Investigate immediately."
- Opportunity insight: "Product XYZ has highest ROI. Consider scaling."

**AI Model Required:**
- Language model: natural language generation

**Performance:**
- Frequency: Daily or on-demand
- Execution: Real-time insights
- Cost: ~0.01-0.05 USD per insight (depends on data volume)

**Example:**
```
Data aggregation (last 7 days):
- Revenue: $5,200 (vs $4,500 previous week, +15%)
- New customers: 45 (vs 30 previous week, +50%)
- Repeat customers: 12 (vs 18 previous week, -33%)
- Inventory value: $25,000 (up from $22,000, new stock added)
- Customer satisfaction: 4.2/5 (up from 4.0)

AI Analysis:
- Revenue driver: TikTok orders increased from 30% to 40% of revenue
- Customer acquisition: New customer acquisition cost down 20%
- Retention concern: Repeat customer orders down (concerning)
- Inventory: Stock levels healthy

AI Insights Generated:
1. "🔥 TikTok channel performing well. +50% new customers. Consider increasing budget."
2. "⚠️ Repeat customer orders declined. Check if satisfaction or product issue."
3. "✅ Customer satisfaction improving. Keep up good work."
4. "💡 Total revenue up 15%. At this growth rate, you'll hit $20K/month goal in 6 weeks."
```

**MVP Status:** ✅ Built (basic insights)

**Phase 2 Improvements:**
- Predictive insights ("revenue will drop next week due to X")
- Comparative insights ("you're 30% below industry average on X")
- Root cause analysis ("churn spiked because of shipping delays")

---

## Planning Features

### 8. Journey Planning (AI-Generated)

**Purpose:** AI breaks down business goals into actionable steps  
**Where Used:** Business Journey (SC-12), AI Copilot  
**User Goal:** "Achieve big goals systematically"

**What It Does:**
1. User states goal: "Enter US market"
2. AI analyzes the goal and business context
3. Generates 8-step plan with timeline
4. Estimates outcomes (revenue, time, investment)

**Input Data Needed:**
- Business goal (user input: "Enter US market")
- Business profile (industry, size, current revenue)
- Available resources (cash, team size, time)
- Risk tolerance (conservative vs aggressive)

**Output Generated:**
- 8-step journey plan
- Timeline (estimated days per step)
- Investment estimate
- Revenue potential
- Risk assessment

**AI Model Required:**
- Language model: plan generation, reasoning about steps
- Knowledge base: reference journeys (similar goals)

**Performance:**
- Planning time: 5-10 seconds
- Accuracy: Depends on user feedback and adaptations
- Cost: ~0.05-0.10 USD per plan (higher token usage)

**Example:**
```
User goal: "Enter US market"
Business context:
  - Current revenue: $500K Vietnam
  - Team size: 2 people
  - Products: Stitched apparel
  - Target: $5K/month US revenue in 6 months

AI Generated Plan:

Step 1: Research US Market (3 days)
  - Research: Market size, competitor landscape
  - Deliverable: Market analysis doc
  
Step 2: Find US Suppliers (7 days)
  - Sourcing: Evaluate 5 US apparel suppliers
  - Deliverable: Supplier shortlist
  
Step 3: Register Business (14 days)
  - Legal: Form LLC, get EIN
  - Deliverable: Business registration complete
  
Step 4: Set Up Payments (7 days)
  - Banking: Open US business bank account
  - Deliverable: Bank account ready
  
Step 5: Launch on Amazon (14 days)
  - Operations: Set up FBA, list products
  - Deliverable: First 20 SKUs live
  
Step 6: Optimize Listings (7 days)
  - Marketing: A/B test titles, images, descriptions
  - Deliverable: Conversion rate > 1%
  
Step 7: Ramp Marketing (14 days)
  - Ads: Set up PPC, target US customers
  - Deliverable: $500+ daily ad spend
  
Step 8: Scale Operations (14 days)
  - Growth: Increase inventory, add SKUs
  - Deliverable: 50+ SKUs, $5K/month revenue

Forecast:
  - Timeline: 90 days (3 months to goal)
  - Investment: $10K-15K
  - Expected revenue by Month 3: $5K-8K
  - Success probability: 70% (with good execution)
```

**MVP Status:** ✅ Built (AI journey generation)

**Phase 2 Improvements:**
- Collaborative planning (AI + user refine steps)
- Risk mitigation (AI suggests backup plans)
- Dependency tracking (step A before step B)
- Resource planning (what do I need to complete?)

---

### 9. Task Recommendation

**Purpose:** AI suggests next actions within a journey  
**Where Used:** Business Journey (SC-12), Home Dashboard  
**User Goal:** "Know what to do next"

**What It Does:**
1. Analyzes current journey progress
2. Identifies blockers or next logical step
3. Suggests action with context

**Input Data Needed:**
- Current journey state (which steps complete/in-progress)
- Step completion dates
- Business metrics (revenue, inventory, customers)
- User's calendar/availability

**Output Generated:**
- "Next step: Find suppliers for US market"
- "You're behind on supplier research. Priority: High"
- "Suggested action: Use Producer tab to find suppliers"

**AI Model Required:**
- Language model: reasoning, suggestions
- Knowledge: workflow patterns

**Performance:**
- Real-time suggestions
- Cost: ~0.01-0.02 USD per recommendation

**MVP Status:** ✅ Built (basic recommendations)

---

## Guidance Features

### 10. AI Copilot Chat

**Purpose:** Conversational AI assistant for business questions  
**Where Used:** AI Copilot (SC-14), all screens  
**User Goal:** "Get business advice instantly"

**What It Does:**
1. User asks question: "How do I set up FBA on Amazon?"
2. AI understands context (user's business, stage, goal)
3. Provides relevant answer with actionable steps
4. Learns from user's business data

**Input Data Needed:**
- User's question (natural language)
- Business context (industry, revenue, team)
- Document knowledge (uploaded files, playbooks)
- Conversation history

**Output Generated:**
- Answer with step-by-step guidance
- Related resources ("See 'US Market Journey' for details")
- Follow-up suggestions ("Next, you'll need a business bank account")

**AI Model Required:**
- Large language model (xAI Grok-2, GPT-4, or similar)
- Retrieval (access to user's data + playbooks)
- Reasoning (understand complex business questions)

**Performance:**
- Response time: < 3 seconds (most queries)
- Accuracy: Depends on AI model quality
- Cost: ~0.01-0.05 USD per query (variable token usage)

**Example:**
```
User: "How do I set up FBA on Amazon?"

AI Response (with context awareness):
"Based on your profile (Vietnam seller, new to US), here's how to set up Amazon FBA:

1. Create Amazon Seller Central Account
   - Go to sellercentral.amazon.com
   - Sign up with email + business info
   - Time: ~15 minutes

2. Register Tax ID (EIN)
   - If you don't have US EIN, apply first (see Step 3 in your Journey)
   - Amazon requires this for FBA
   
3. Set Up FBA
   - In Seller Central, go to "Settings" → "Fulfillment by Amazon"
   - Choose FBA for your products
   - Time: ~30 minutes
   
4. Ship Inventory to Amazon
   - Arrange logistics from Vietnam to Amazon warehouse
   - Typical cost: $0.50-1.00 per unit (for 100-unit shipment)
   - Lead time: 2-4 weeks
   
Next: 'How do I calculate FBA fees?' or 'What products work best on Amazon?'"

System also generates:
- Related resources: "See 'FBA Cost Calculator' doc"
- Follow-up suggestion: "Set up business bank account (Step 4 in your journey)"
- Confidence: "High - based on 1000+ US seller success stories"
```

**MVP Status:** ✅ Built (basic chat)

**Phase 2 Improvements:**
- Document analysis ("Upload your P&L and I'll analyze profitability")
- Real-time data context ("Based on your $500 this week, here's why")
- Multi-turn reasoning (complex multi-step questions)
- Proactive assistance ("I notice X trend. Consider Y action.")

---

### 11. Context-Aware Help

**Purpose:** AI provides contextual help without user asking  
**Where Used:** All screens (inline help, tooltips, prompts)  
**User Goal:** "Understand features without reading docs"

**What It Does:**
1. User opens a screen (e.g., Opportunity Hub)
2. AI detects context (what is user doing?)
3. Offers relevant help: "Did you know you can save opportunities for later?"
4. Provides micro-learning

**MVP Status:** 🔄 To-do (Phase 2)

---

## Optimization Features

### 12. Price Optimization

**Purpose:** AI recommends optimal pricing for products  
**Where Used:** Inventory (SC-8), Product Detail, Reports  
**User Goal:** "Maximize profit without losing sales"

**What It Does:**
1. Analyzes product pricing across channels
2. Compares competitor prices
3. Estimates price elasticity (how demand changes with price)
4. Recommends optimal price

**Input Data Needed:**
- Product cost price
- Historical sales at different prices (if available)
- Competitor prices
- Customer segments (price sensitivity)
- Inventory levels (urgency to sell)

**Output Generated:**
- Recommended price: $25 (vs current $20)
- Expected impact: Revenue +30%, margin +15%
- Confidence: 75%
- Risks: Might lose price-sensitive customers

**AI Model Required:**
- Regression/pricing model: price elasticity
- Competitive intelligence: monitor competitor prices

**Performance:**
- Frequency: Weekly or on-demand
- Cost: ~0.01-0.03 USD per product

**Example:**
```
Product: Red T-Shirt
Data:
- Current price: $20
- Current cost: $8
- Historical sales at $20: 50 units/week
- Competitor prices: $18-30 (average $22)
- Inventory level: 500 units (high)

AI Analysis:
- Price elasticity: -1.2 (1% price increase → 1.2% demand decrease)
- Competitor price: $22 average
- Profit margin: ($20 - $8) / $20 = 60%
- Market positioning: You're 10% cheaper than average
- Inventory: High (should push sales)

AI Recommendation:
- Optimal price: $23 (increase by $3)
- Expected impact:
  - Sales: 45 units/week (vs 50, -10%)
  - Revenue: $1,035/week (vs $1,000, +3.5%)
  - Profit: $675/week (vs $600, +12.5%)
- Alternative: Keep at $20 but run 7-day promo at $18 to clear inventory

Confidence: 70% (model has 500+ samples for training)
```

**MVP Status:** 🔄 To-do (Phase 2)

---

## AI Capability Maturity Matrix

| Feature | MVP (Phase 1) | Phase 2 | Phase 3 |
|---|---|---|---|
| **Opportunity Discovery** | ✅ Basic | ↕️ Real-time | ↕️ ML-refined |
| **Supplier Scoring** | ✅ Basic | ↕️ Fraud detection | ↕️ Auto-sync data |
| **Trend Detection** | ✅ Google Trends | ↕️ Social signals | ↕️ Viral prediction |
| **Demand Forecasting** | ✅ Time-series | ↕️ External signals | ↕️ ML optimization |
| **Churn Prediction** | ✅ Scoring | ↕️ Root cause | ↕️ Win-back campaign |
| **Sentiment Analysis** | 🔄 To-do | ✅ Basic | ↕️ Topic-specific |
| **Insights Generation** | ✅ Basic | ↕️ Predictive | ↕️ Causal analysis |
| **Journey Planning** | ✅ AI-generated | ↕️ Collaborative | ↕️ Multi-goal |
| **Task Recommendation** | ✅ Basic | ↕️ Learning | ↕️ Adaptive |
| **Copilot Chat** | ✅ Basic | ↕️ Document understanding | ↕️ Autonomous tasks |
| **Context-Aware Help** | 🔄 To-do | ✅ Basic | ↕️ Predictive |
| **Price Optimization** | 🔄 To-do | ✅ Basic | ↕️ Dynamic pricing |

---

## AI Infrastructure & Costs

### Model Choices

**Primary (MVP):** xAI Grok-2  
- Fast, cost-effective
- Good for business reasoning
- Available via API
- BYOK (user brings key)

**Secondary (Phase 2):** OpenRouter  
- Multiple models to choose from
- Fallback if xAI unavailable
- BYOK model

**Optional (Phase 2+):** OpenAI GPT-4  
- Higher quality reasoning
- More expensive
- BYOK model

### Estimated Monthly Costs (1,000 users)

| Feature | Requests/Month | Cost/Request | Total Cost |
|---|---|---|---|
| Opportunity Discovery | 50K | $0.02 | $1,000 |
| Demand Forecasting | 100K | $0.01 | $1,000 |
| Churn Prediction | 500K | $0.001 | $500 |
| Copilot Chat | 200K | $0.03 | $6,000 |
| Insights Generation | 50K | $0.02 | $1,000 |
| **Total** | **~900K** | **~$0.01 avg** | **~$9,500/mo** |

**User Cost:** ~$10/user/month (high-volume discount applies)  
**Pricing Model:** Freemium, Premium subscribers get more AI features

---

## Data Privacy & AI

### What Data is Sent to AI?

**Sent to xAI (aggregated, no PII):**
- Business summary (industry, revenue, size)
- Product names and prices
- Sales trends (numbers, not individual transactions)
- Customer segments (count, not names)

**NOT Sent:**
- Customer names, emails, phones
- Individual customer transactions
- Payment information
- Employee data
- User's personal correspondence

### User Control

- User can disable AI features
- User chooses AI provider
- User provides API key (not shared with server)
- All data processed on-device when possible

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B (MVP AI features only)  
**Date:** 2026-07-13  
**Related Docs:** BUSINESS-CAPABILITY-MODEL.md, INTEGRATION-MAP.md, AI-BUSINESS-COPILOT.md  
**Next:** Create Jira Stories + Confluence Page
