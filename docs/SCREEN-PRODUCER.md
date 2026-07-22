# Screen Specification — Producer (Sourcing Hub)

## Chi Tiết Màn Hình — Nhà Sản Xuất (Trung Tâm Nguồn Cung)

---

## English — Producer Screen

### Purpose

**Producer** is the sourcing command center. It shows:
- AI-discovered sourcing opportunities (arbitrage, seasonal trends, cross-border)
- Supplier directory with ratings and capabilities
- Real-time market trends and price monitoring
- Bulk import and negotiation tools

**User Journey:** Open Producer → see 18+ opportunities ranked by profit → drill into opportunity detail → view suppliers → start sourcing negotiation.

### Business Goal

Help entrepreneurs find profitable sourcing opportunities by:
1. Discovering untapped arbitrage plays (e.g., Taobao → Shopee)
2. Monitoring supplier capabilities and ratings
3. Accessing real-time market trends
4. Managing supplier relationships and price negotiations

### Information Architecture

```
Producer Screen
├── Header
│   ├── Title: "Producer - Sourcing Hub"
│   ├── Filter button (by type, region)
│   └── Search bar
├── AI Summary Section
│   ├── Copilot insight card
│   └── "18 opportunities found today"
├── Capability Pills (7 items, horizontal scroll)
│   ├── Arbitrage Finder
│   ├── Seasonal Trends
│   ├── Cross-Border Routes
│   ├── Supplier Matcher
│   ├── Price Intelligence
│   ├── Trend Analyzer
│   └── Supplier Community
├── Opportunities Section
│   ├── Opportunity List (swipeable)
│   │   ├── Card 1: Title + Market + Profit + Score
│   │   ├── Card 2: ...
│   │   └── Card 3: ...
│   └── "See All" link
├── Suppliers Section
│   ├── Top-rated suppliers (4 cards)
│   ├── Rating + Count + Location
│   └── "Browse All Suppliers" CTA
├── Trends Section
│   ├── Trending categories (scroll)
│   ├── Trend line chart
│   └── "View Trend Details" CTA
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg with shadow | Title + filter icon + search bar |
| **Copilot Card** | Full-width, 80px, gradient green bg | "Tôi tìm được 5 cơ hội arbitrage mới hôm nay" |
| **Capability Pill** | 100x50px, pill-shaped, tappable | "Arbitrage Finder" with icon |
| **Opportunity Card** | Full-width, 120px, swipeable | Image + title + market (Taobao→Shopee) + profit ($8.45, 42%) + score (92/100) |
| **Supplier Card** | 1 of 4 in row, 100x120px | Logo + name + rating (4.8★) + review count + location |
| **Trend Chart** | Full-width, 200px height | Line graph of search volume over 30 days |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Opportunity Card | Opportunity Detail | Show full analysis, supplier options, arbitrage data |
| Supplier Card | Supplier Detail (SC-15) | Show profile, ratings, capabilities, products, reviews |
| Capability Pill | Filtered list | Filter opportunities by type (e.g., all arbitrage plays) |
| "Browse All Suppliers" | Suppliers Directory | Show all suppliers with filters |
| Trend Line | Trend Detail | Show historical data, related opportunities |
| Filter Button | Filter Modal | Filter by region, category, profit range |

### Mock Data

```json
{
  "summary": {
    "copilotMessage": "Tôi tìm được 5 cơ hội arbitrage mới hôm nay với lợi nhuận cao",
    "totalOpportunities": 18,
    "topCategory": "Consumer Electronics"
  },
  "capabilities": [
    { "id": 1, "name": "Arbitrage Finder", "icon": "target", "color": "green" },
    { "id": 2, "name": "Seasonal Trends", "icon": "trending-up", "color": "blue" },
    { "id": 3, "name": "Cross-Border Routes", "icon": "globe", "color": "orange" },
    { "id": 4, "name": "Supplier Matcher", "icon": "users", "color": "purple" },
    { "id": 5, "name": "Price Intelligence", "icon": "dollar", "color": "green" },
    { "id": 6, "name": "Trend Analyzer", "icon": "chart", "color": "teal" },
    { "id": 7, "name": "Supplier Community", "icon": "community", "color": "pink" }
  ],
  "opportunities": [
    {
      "id": 1,
      "title": "Quạt mini cấm tay — Arbitrage",
      "source": "Taobao",
      "destination": "Shopee Vietnam",
      "costPerUnit": "$2.10",
      "sellPrice": "$8.45",
      "profit": "$6.35 (203%)",
      "volume": "500+ monthly demand",
      "score": 92,
      "trend": "+18% this week",
      "type": "arbitrage"
    },
    {
      "id": 2,
      "title": "Túi chống nước du lịch",
      "source": "1688",
      "destination": "TikTok Shop Vietnam",
      "costPerUnit": "$3.20",
      "sellPrice": "$9.60",
      "profit": "$6.40 (200%)",
      "volume": "300+ monthly demand",
      "score": 88,
      "trend": "stable",
      "type": "seasonal"
    },
    {
      "id": 3,
      "title": "Máy pha cà phê mini",
      "source": "Alibaba",
      "destination": "Amazon US",
      "costPerUnit": "$4.50",
      "sellPrice": "$14.50",
      "profit": "$10.00 (222%)",
      "volume": "200+ monthly demand",
      "score": 90,
      "trend": "+25% this month",
      "type": "cross-border"
    }
  ],
  "suppliers": [
    {
      "id": 1,
      "name": "TechPro Wholesale",
      "location": "Shenzhen, China",
      "rating": 4.8,
      "reviewCount": 245,
      "categories": ["Electronics", "Accessories"],
      "minOrder": "100 units",
      "leadTime": "7-14 days"
    },
    {
      "id": 2,
      "name": "Global Trade Partners",
      "location": "Bangkok, Thailand",
      "rating": 4.6,
      "reviewCount": 189,
      "categories": ["Apparel", "Home Goods"],
      "minOrder": "50 units",
      "leadTime": "10-21 days"
    },
    {
      "id": 3,
      "name": "Vietnam Manufacturing Hub",
      "location": "Ho Chi Minh City, Vietnam",
      "rating": 4.7,
      "reviewCount": 156,
      "categories": ["Textiles", "Goods"],
      "minOrder": "200 units",
      "leadTime": "5-10 days"
    },
    {
      "id": 4,
      "name": "Indonesia Export Specialists",
      "location": "Jakarta, Indonesia",
      "rating": 4.5,
      "reviewCount": 134,
      "categories": ["Coconut Products", "Agriculture"],
      "minOrder": "500 units",
      "leadTime": "14-21 days"
    }
  ],
  "trends": [
    {
      "id": 1,
      "category": "Mini Appliances",
      "searchVolume": "125,000/month",
      "trend": "+42%",
      "period": "last 30 days"
    },
    {
      "id": 2,
      "category": "Travel Accessories",
      "searchVolume": "89,000/month",
      "trend": "+18%",
      "period": "last 30 days"
    },
    {
      "id": 3,
      "category": "Smart Home Devices",
      "searchVolume": "156,000/month",
      "trend": "+8%",
      "period": "last 30 days"
    }
  ]
}
```

### Business Rules

1. **Opportunities Ranked by Score** — AI scores by profit potential, demand volume, supplier availability, and user profile match
2. **Supplier Ratings Verified** — All ratings aggregated from multiple platforms (Alibaba, Taobao, Global Trade Portal)
3. **Real-Time Trends** — Market trends updated daily from Google Trends, Shopee, TikTok search data
4. **Min Order Quantities** — Always shown; helps user assess cash flow impact
5. **Lead Time Transparent** — Days to delivery clearly displayed; impacts sourcing decisions
6. **Type Tagging** — Each opportunity tagged (arbitrage/seasonal/cross-border) for filtering
7. **Supplier Verification** — Only suppliers with 4.0+ rating shown by default; filter available

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Opportunity Discovery** | Daily ML scan of price deltas across platforms; flag new gaps + trend acceleration |
| **Supplier Matching** | Recommend suppliers based on: product category, user's sourcing history, lead-time needs, min order fit |
| **Trend Projection** | Forecast demand 30 days forward; recommend timing for bulk orders |
| **Arbitrage Scoring** | Calculate profit potential factoring: cost, sell price, platform fees, currency, shipping |
| **Risk Assessment** | Flag supplier reputation dips, lead-time delays, seasonal demand cliff |

### Required APIs

```
GET /api/producer/summary
  Returns: copilotMessage, totalOpportunities, topCategory

GET /api/producer/opportunities
  Query: ?type=arbitrage&limit=18&sort=score
  Returns: list of opportunities with scores, profit data, supplier match

GET /api/producer/suppliers
  Query: ?minRating=4.0&limit=10
  Returns: supplier directory with ratings, location, categories, min order, lead time

GET /api/producer/trends
  Returns: trending categories with search volume, trend line (30-day chart)

GET /api/producer/opportunity/{id}
  Returns: full opportunity detail with supplier options + arbitrage analysis

GET /api/producer/supplier/{id}
  Returns: supplier profile (SC-15)
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Copilot card (shimmer)
- Capability pills (4x shimmer)
- Opportunity cards (3x shimmer)
- Suppliers grid (4x shimmer)
- Trends chart (shimmer)
```

#### Empty State
```
No opportunities found:
- Icon: search icon
- Message: "No opportunities match your filters. Try adjusting region or category."
- CTA: "Browse Trending Categories" or "Update Preferences"
```

#### Error State
```
If API fails:
- Error message: "Could not load opportunities. Check your connection."
- Retry button
- Offline fallback: show cached supplier directory
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Capability pills horizontal scroll
  - Opportunity cards single-column, swipeable
  - Suppliers grid 2x2
  - Trends chart full-width

Tablet (600px+): Side-by-side layout
  - Left: Opportunities feed
  - Right: Suppliers sidebar + trends chart
  - Capability pills horizontal
```

### Accessibility

- ✅ Heading hierarchy: H1 (Producer) → H2 (Opportunities) → H3 (Opportunity items)
- ✅ Touch targets: 44px minimum (cards, pills, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All buttons have descriptive text
- ✅ Trend chart: Include data table alternative for screen readers

### Future Enhancements

1. ⏳ Advanced filtering (profit range, lead time, supplier type)
2. ⏳ Supplier comparison view (side-by-side ratings)
3. ⏳ Price history chart (track supplier pricing over time)
4. ⏳ Bulk negotiation assistant (AI-drafted RFQ emails)
5. ⏳ Integration with supplier messaging (WhatsApp, WeChat)
6. ⏳ Custom alerts (set profit target, get notified when met)

---

## Tiếng Việt — Màn Hình Nhà Sản Xuất

### Mục Đích

**Nhà Sản Xuất** là trung tâm điều hành nguồn cung. Nó hiển thị:
- Cơ hội nguồn cung được AI phát hiện (kinh doanh chênh lệch, xu hướng mùa vụ, xuyên biên giới)
- Thư mục nhà cung cấp với xếp hạng và khả năng
- Xu hướng thị trường và giám sát giá thực tế
- Công cụ nhập khẩu hàng loạt và đàm phán

### Mục Tiêu Kinh Doanh

Giúp doanh nhân tìm cơ hội nguồn cung có lợi nhuận cao bằng cách:
1. Phát hiện các cơ hội kinh doanh chênh lệch chưa được khai thác (ví dụ: Taobao → Shopee)
2. Giám sát khả năng và xếp hạng nhà cung cấp
3. Truy cập xu hướng thị trường thực tế
4. Quản lý quan hệ nhà cung cấp và đàm phán giá

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 7 main components  
**API Calls:** 6 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-INVENTORY.md
