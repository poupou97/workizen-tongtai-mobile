# Screen Specification — Opportunity Hub (Discovery, Arbitrage & Trend Analysis)

## Chi Tiết Màn Hình — Trung Tâm Cơ Hội (Khám Phá, Kinh Doanh Chênh Lệch & Phân Tích Xu Hướng)

---

## English — Opportunity Hub Screen

### Purpose

**Opportunity Hub** is the deal discovery engine. It shows:
- Top 3-5 ranked opportunities (arbitrage, seasonal, cross-border)
- AI scoring (profit potential, market fit, supplier availability)
- Detailed opportunity analysis (market data, pricing, demand)
- Save/follow actions for tracking
- Related opportunities and trend data
- Market insights and recommendations

**User Journey:** Open Hub → see top-ranked opportunity (92/100 score) → tap to see arbitrage analysis → review supplier options → save/follow for later → explore related trends.

### Business Goal

Help entrepreneurs discover profitable deals by:
1. Surfacing hidden arbitrage opportunities (price gaps across platforms)
2. Timing seasonal trend plays
3. Identifying cross-border market arbitrage
4. Analyzing market demand and competition
5. Matching opportunities to supplier capabilities

### Information Architecture

```
Opportunity Hub Screen
├── Header
│   ├── Title: "Opportunity Hub - Discovery Engine"
│   ├── Filter button (by type, region, profit range)
│   └── Search bar
├── AI Copilot Card
│   ├── "Phương, I found 3 hot opportunities today"
│   └── Status badge (alerts, new listings)
├── Top Opportunities Section
│   ├── Opportunity Card 1 (ranked 1st)
│   │   ├── Hero image/icon
│   │   ├── Title + Market (Source → Destination)
│   │   ├── Profit metrics ($profit + % margin)
│   │   ├── AI Score (92/100, green)
│   │   ├── Type badge (Arbitrage / Seasonal / Cross-Border)
│   │   ├── Save / Follow action
│   │   └── "View Details" link
│   ├── Opportunity Card 2 (ranked 2nd)
│   ├── Opportunity Card 3 (ranked 3rd)
│   └── "See All Opportunities" (pagination link)
├── Why This Matters Section (Swipeable carousel)
│   ├── Reason 1: High Demand (123,000 searches/month)
│   ├── Reason 2: Large Profit Margin (42% margin)
│   ├── Reason 3: Trusted Suppliers (4.8★ rating)
│   └── Reason 4: Low Competition
├── Market Intelligence Section
│   ├── Demand Trend Chart (30-day line graph)
│   ├── Competitor Pricing (if available)
│   └── Supply Availability
├── Related Opportunities
│   ├── "Similar to this: [Other opportunities in same category]"
│   ├── Carousel (horizontal scroll, 3-4 cards)
│   └── "Browse Category" link
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title + filter icon + search bar |
| **Copilot Card** | Full-width, 80px, gradient bg | AI badge + message + status indicator |
| **Opportunity Card** | Full-width, 180px, tappable | Hero image (120x80px) + title + market + profit + score + badge + actions |
| **AI Score Badge** | 50x50px, circular | Score number (92) + color gradient (green = high, red = low) |
| **Type Badge** | 80x20px, pill-shaped | "Arbitrage" (red), "Seasonal" (blue), "Cross-Border" (green) |
| **Action Button** | 40x40px circular | Save icon (heart) + Follow icon (bell) |
| **Why-This-Matters Card** | 1 of 4 in carousel, 100x120px | Icon + reason title + metric value |
| **Demand Chart** | Full-width, 250px height | Line graph of search volume trend |
| **Related Card** | 1 of 3-4 in scroll, 140x100px | Thumbnail + title + score |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Opportunity Card | Opportunity Detail (full screen) | Show comprehensive analysis: arbitrage breakdown, supplier options, market data |
| "View Details" link | Opportunity Detail | Same as above |
| "Why This Matters" card | Insight Detail | Expand reason with full context (e.g., "High Demand: search trend analysis") |
| Related Opportunity | Opportunity Detail | Drill into related opportunity |
| "Browse Category" | Category Opportunities | Show all opportunities in that category, filtered |
| Save (heart) | Saved List | Add to "Saved Opportunities"; toggle favorite |
| Follow (bell) | Notifications | Enable alerts for this opportunity (price changes, new suppliers) |

### Mock Data

```json
{
  "summary": {
    "copilotMessage": "Phương, tôi tìm được 5 cơ hội tuyệt vời hôm nay",
    "newOpportunities": 5,
    "alertsToday": 3,
    "savedCount": 12
  },
  "opportunities": [
    {
      "id": 1,
      "rank": 1,
      "title": "Quạt mini cấm tay — Arbitrage",
      "description": "Handheld mini fan, trending on TikTok, high profit margin",
      "source": {
        "platform": "Taobao",
        "country": "China",
        "pricePerUnit": "$2.10",
        "minOrder": 100
      },
      "destination": {
        "platform": "Shopee",
        "country": "Vietnam",
        "pricePerUnit": "$8.45",
        "monthlyDemand": "500+ units"
      },
      "profit": {
        "perUnit": "$6.35",
        "margin": "203%"
      },
      "aiScore": 92,
      "type": "arbitrage",
      "heroImage": "https://...",
      "reasons": [
        { "icon": "trending", "title": "Trending", "metric": "+42% search volume" },
        { "icon": "dollar", "title": "High Margin", "metric": "203% profit margin" },
        { "icon": "supplier", "title": "Trusted", "metric": "4.8★ supplier rating" },
        { "icon": "low-comp", "title": "Low Competition", "metric": "Only 2 sellers on Shopee" }
      ],
      "saved": false,
      "following": false,
      "updatedAt": "2 hours ago"
    },
    {
      "id": 2,
      "rank": 2,
      "title": "Túi chống nước du lịch",
      "description": "Travel waterproof bag, seasonal spike (summer), good for TikTok Shop",
      "source": {
        "platform": "1688",
        "country": "China",
        "pricePerUnit": "$3.20",
        "minOrder": 50
      },
      "destination": {
        "platform": "TikTok Shop",
        "country": "Vietnam",
        "pricePerUnit": "$9.60",
        "monthlyDemand": "300+ units"
      },
      "profit": {
        "perUnit": "$6.40",
        "margin": "200%"
      },
      "aiScore": 88,
      "type": "seasonal",
      "heroImage": "https://...",
      "reasons": [
        { "icon": "seasonal", "title": "Seasonal Peak", "metric": "+38% demand (summer)" },
        { "icon": "platform", "title": "TikTok Trending", "metric": "#TravelAccessories viral" },
        { "icon": "supplier", "title": "Reliable", "metric": "4.6★ supplier rating" }
      ],
      "saved": true,
      "following": true
    },
    {
      "id": 3,
      "rank": 3,
      "title": "Máy pha cà phê mini",
      "description": "Mini coffee maker, cross-border play to Amazon US",
      "source": {
        "platform": "Alibaba",
        "country": "China",
        "pricePerUnit": "$4.50",
        "minOrder": 50
      },
      "destination": {
        "platform": "Amazon US",
        "country": "USA",
        "pricePerUnit": "$14.50",
        "monthlyDemand": "200+ units"
      },
      "profit": {
        "perUnit": "$10.00",
        "margin": "222%"
      },
      "aiScore": 90,
      "type": "cross-border",
      "heroImage": "https://...",
      "reasons": [
        { "icon": "globe", "title": "Cross-Border", "metric": "US market demand" },
        { "icon": "high-margin", "title": "Highest Margin", "metric": "222% profit" },
        { "icon": "trend", "title": "Growing Trend", "metric": "+25% searches/month" }
      ],
      "saved": false,
      "following": false
    }
  ],
  "demandChart": {
    "productId": 1,
    "data": [
      { "date": "2026-06-13", "searches": 2500 },
      { "date": "2026-06-14", "searches": 2800 },
      { "date": "2026-06-15", "searches": 3200 },
      { "date": "2026-06-16", "searches": 2900 },
      { "date": "2026-06-17", "searches": 4100 },
      { "date": "2026-06-18", "searches": 3800 },
      { "date": "2026-06-19", "searches": 4500 }
    ]
  },
  "relatedOpportunities": [
    { "id": 101, "title": "LED Desk Lamp", "score": 85, "type": "arbitrage" },
    { "id": 102, "title": "Phone Ring Stand", "score": 82, "type": "arbitrage" },
    { "id": 103, "title": "Portable Charger", "score": 79, "type": "seasonal" }
  ]
}
```

### Business Rules

1. **Opportunity Scores Weighted** — Calculated from: profit potential (40%), demand volume (30%), supplier quality (20%), competition (10%)
2. **Types Mutually Exclusive** — Each opportunity tagged as ONE type: arbitrage/seasonal/cross-border
3. **Minimum Thresholds** — Only show opportunities with score ≥ 70 and profit margin ≥ 50%
4. **Demand Data Real-Time** — Updated daily from Google Trends, platform APIs (Shopee, TikTok), search volume data
5. **Supplier Auto-Matched** — Top 2-3 suppliers recommended based on product category + ratings
6. **Save/Follow Toggles** — User can favorite opportunities and enable notifications
7. **Rank Changes Daily** — Top 5 opportunities recalculated each morning; users notified of big changes

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Opportunity Scoring** — ML model weights profit, demand, supplier quality, competition risk |
| **Demand Forecasting** — Predict demand 30/60 days forward based on trend curve + seasonality |
| **Competitor Detection** — Monitor how many other sellers (on Shopee, TikTok) are already listing similar products |
| **Seasonal Pattern Recognition** — Flag seasonal trends (summer travel, Christmas gifts, Lunar New Year) |
| **Risk Assessment** — Estimate supply chain risk, supplier reliability, market saturation |
| **Personalization** — Rank opportunities higher if they match user's sourcing history + supplier network |

### Required APIs

```
GET /api/opportunities/summary
  Returns: copilotMessage, newOpportunities, alertsToday, savedCount

GET /api/opportunities/top
  Query: ?limit=5&minScore=70&sort=score
  Returns: top ranked opportunities with full details, reasons, demand data

GET /api/opportunities/opportunity/{id}
  Returns: full opportunity detail with arbitrage analysis, supplier options, market data

GET /api/opportunities/demandChart
  Query: ?opportunityId=1&days=30
  Returns: daily search volume trend data for chart

GET /api/opportunities/related
  Query: ?opportunityId=1&limit=5
  Returns: related opportunities in same category or similar score range

POST /api/opportunities/opportunity/{id}/save
  Returns: save status toggled

POST /api/opportunities/opportunity/{id}/follow
  Returns: follow status toggled + notification enabled

GET /api/opportunities/saved
  Returns: list of saved opportunities by user

GET /api/opportunities/filter
  Query: ?type=arbitrage&minMargin=50&region=vietnam
  Returns: filtered opportunity list
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Copilot card (shimmer)
- Opportunity cards (5x shimmer)
- Chart (shimmer)
- Related cards (3x shimmer)
```

#### Empty State
```
No opportunities (rare):
- Icon: search icon
- Message: "No opportunities match your filters right now. Try adjusting your preferences."
- CTA: "Clear Filters" or "Adjust Preferences"
```

#### Error State
```
If API fails:
- Error message: "Could not load opportunities. Check your connection."
- Retry button
- Offline fallback: show cached top 5 opportunities with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Opportunity cards single-column, swipeable
  - Why-This-Matters carousel horizontal scroll
  - Demand chart full-width
  - Related cards horizontal scroll

Tablet (600px+): Side-by-side layout
  - Left: Opportunity cards (wider)
  - Right: Why-This-Matters + related opportunities
  - Demand chart full-width below
```

### Accessibility

- ✅ Heading hierarchy: H1 (Opportunity Hub) → H2 (Top Opportunities) → H3 (Opportunity items)
- ✅ Touch targets: 44px minimum (cards, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All badges have text (e.g., "Arbitrage" not just icon)
- ✅ Chart: Include data table alternative for screen readers
- ✅ Score: Show number + color indicator + description

### Future Enhancements

1. ⏳ Custom filters (profit range, lead time, supplier rating, market)
2. ⏳ Opportunity alerts (email/SMS when score hits target)
3. ⏳ Competitive tracking (see if other users are pursuing same opportunity)
4. ⏳ AI negotiation assistant (auto-generate RFQ email to supplier)
5. ⏳ Community ratings (users rate opportunities they pursued: did it work out?)
6. ⏳ Market sentiment (social listening on product mentions, sentiment analysis)
7. ⏳ Trend forecasting (predict which categories will boom in 3/6/12 months)

---

## Tiếng Việt — Màn Hình Trung Tâm Cơ Hội

### Mục Đích

**Trung Tâm Cơ Hội** là công cụ phát hiện giao dịch. Nó hiển thị:
- Các cơ hội hàng đầu được xếp hạng (kinh doanh chênh lệch, mùa vụ, xuyên biên giới)
- Điểm số của AI
- Phân tích cơ hội chi tiết
- Hành động lưu/theo dõi
- Cơ hội liên quan và dữ liệu xu hướng
- Thông tin thị trường và khuyến nghị

### Mục Tiêu Kinh Doanh

Giúp doanh nhân khám phá các giao dịch có lợi nhuận cao bằng cách:
1. Bề mặt cơ hội kinh doanh chênh lệch ẩn
2. Thời gian các trò chơi xu hướng mùa vụ
3. Xác định các cơ hội kinh doanh chênh lệch thị trường xuyên biên giới
4. Phân tích nhu cầu thị trường và cạnh tranh
5. Kết hợp các cơ hội với khả năng của nhà cung cấp

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 10 main components  
**API Calls:** 10 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-AI-COPILOT.md
