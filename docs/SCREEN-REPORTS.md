# Screen Specification — Reports (KPIs, Analytics & Business Insights)

## Chi Tiết Màn Hình — Báo Cáo (KPI, Phân Tích & Thông Tin Kinh Doanh)

---

## English — Reports Screen

### Purpose

**Reports** is the business intelligence hub. It shows:
- Key performance indicators (KPIs) dashboard with 30/90-day trends
- Channel breakdown (Shopee/TikTok/Instagram/Direct by revenue, orders, profit)
- Trend analysis (products, categories, seasonal patterns)
- AI insights and recommendations
- Custom report builder
- Export capabilities (CSV, PDF, charts)

**User Journey:** Open Reports → see KPI summary → drill into channel breakdown → filter by product → view trend chart → export insights.

### Business Goal

Help entrepreneurs measure business health by:
1. Tracking core metrics (revenue, profit, orders, conversion rate, AOV)
2. Understanding which channels drive profit
3. Identifying product/category trends
4. Spotting seasonal patterns for inventory planning
5. Getting AI recommendations for optimization

### Information Architecture

```
Reports Screen
├── Header
│   ├── Title: "Reports - Analytics & Insights"
│   ├── Date range selector (Last 7 / 30 / 90 days)
│   └── Export button
├── KPI Dashboard Section
│   ├── 6-8 KPI cards in grid
│   │   ├── Revenue
│   │   ├── Profit
│   │   ├── Orders
│   │   ├── Conversion Rate
│   │   ├── AOV (Average Order Value)
│   │   ├── Repeat Purchase Rate
│   │   ├── Customer Acquisition Cost
│   │   └── Return Rate
│   └── Trend indicators (vs previous period)
├── Tab Bar (Horizontal)
│   ├── Overview (active, this screen)
│   ├── Channels
│   ├── Products
│   ├── Categories
│   ├── Customer Trends
│   └── AI Insights
├── Main Content Area (varies by tab)
│   └── [Tab-specific content]
├── Channel Breakdown Section
│   ├── Pie chart (revenue by channel)
│   ├── Table (channel, orders, revenue, profit, % of total)
│   └── Ranking (top performers)
├── Trend Analysis Section
│   ├── Line chart (product sales trend, last 30 days)
│   ├── Filter by product or category
│   └── Comparison option (compare 2 products)
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title + date range selector + export button |
| **KPI Card** | 1 of 6-8 in grid, 100x100px | Metric name + value + % change + trend arrow |
| **Pie Chart** | 200x200px, centered | Channel breakdown with legend |
| **Line Chart** | Full-width, 250px height | Product trend line, configurable (7/30/90 days) |
| **Channel Row** | Full-width, 70px, tappable | Channel icon + name + orders + revenue + profit + % of total |
| **Tab Bar** | Horizontal scroll, 50px height | 6 tabs with underline indicator |
| **AI Insight Card** | Full-width, 100px, highlighted | Icon + title + description + "Learn more" link |
| **Export Menu** | Dropdown, 150x150px | Export to CSV, PDF, Google Sheets, Email |
| **Date Range Selector** | Dropdown, 150x40px | Last 7 / 30 / 90 days / Custom |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| KPI Card | KPI Detail Drill-down | Show daily breakdown of that metric for selected date range |
| Channel Row | Channel Detail | Show channel-specific products, orders, profit breakdown |
| Product Chart point | Product Detail | Drill into full product analytics (SC-16, Analytics tab) |
| "Learn more" (AI Insight) | Insight Detail | Show full recommendation with action steps |
| Pie Chart segment | Channel filtered view | Show all products/orders for that channel |
| Date Range Selector | Date Picker | Select 7/30/90 days or custom range |

### Mock Data

```json
{
  "dateRange": { "period": "30 days", "start": "2026-06-13", "end": "2026-07-13" },
  "kpis": [
    { "id": 1, "name": "Revenue", "value": "$24,560.00", "trend": "+18.6%", "trendDirection": "up" },
    { "id": 2, "name": "Profit", "value": "$16,325.50", "trend": "+23.4%", "trendDirection": "up" },
    { "id": 3, "name": "Orders", "value": "1,256", "trend": "+15.2%", "trendDirection": "up" },
    { "id": 4, "name": "Conversion Rate", "value": "3.42%", "trend": "+0.8%", "trendDirection": "up" },
    { "id": 5, "name": "AOV (Avg Order Value)", "value": "$19.56", "trend": "+2.1%", "trendDirection": "up" },
    { "id": 6, "name": "Repeat Purchase Rate", "value": "42%", "trend": "+5.3%", "trendDirection": "up" },
    { "id": 7, "name": "Customer Acquisition Cost", "value": "$3.24", "trend": "-8.2%", "trendDirection": "down" },
    { "id": 8, "name": "Return Rate", "value": "2.1%", "trend": "-0.5%", "trendDirection": "down" }
  ],
  "channelBreakdown": [
    { "channel": "Shopee", "orders": 600, "revenue": "$12,456.80", "profit": "$9,000.60", "percentOfTotal": "50.7%" },
    { "channel": "TikTok Shop", "orders": 400, "revenue": "$8,234.50", "profit": "$6,000.00", "percentOfTotal": "33.5%" },
    { "channel": "Instagram", "orders": 156, "revenue": "$3,868.70", "profit": "$2,325.00", "percentOfTotal": "15.8%" }
  ],
  "productTrends": [
    { "date": "2026-06-13", "quanMini": 45, "tuiChongNuoc": 32, "mayPhaCaPhe": 28 },
    { "date": "2026-06-14", "quanMini": 52, "tuiChongNuoc": 41, "mayPhaCaPhe": 35 },
    { "date": "2026-06-15", "quanMini": 68, "tuiChongNuoc": 48, "mayPhaCaPhe": 42 },
    { "date": "2026-06-16", "quanMini": 45, "tuiChongNuoc": 35, "mayPhaCaPhe": 30 },
    { "date": "2026-06-17", "quanMini": 89, "tuiChongNuoc": 56, "mayPhaCaPhe": 52 }
  ],
  "aiInsights": [
    { "id": 1, "title": "Shopee Opportunity", "description": "Your Shopee sales are up 28% this week. Consider increasing inventory for high-performers.", "priority": "high", "actionType": "inventory" },
    { "id": 2, "title": "Seasonal Trend Alert", "description": "Travel Accessories trending +42% this month. Good time to promote 'Túi chống nước'.", "priority": "high", "actionType": "marketing" },
    { "id": 3, "title": "CAC Improvement", "description": "Customer Acquisition Cost down 8.2%. Your marketing efficiency is improving.", "priority": "medium", "actionType": "insight" },
    { "id": 4, "title": "Dead Stock Risk", "description": "Old Model Phone Case: zero sales for 60+ days. Consider 30% discount to clear.", "priority": "medium", "actionType": "pricing" }
  ]
}
```

### Business Rules

1. **KPI Baseline** — All metrics calculated from Finance, Inventory, Consumer modules
2. **Trend Comparison** — Always compare vs previous period (7/30/90 days)
3. **Channel Definition** — Shopee, TikTok, Instagram, Direct/Email, Amazon (if configured)
4. **AOV = Revenue / Orders** — Tracks average order value per channel
5. **Conversion Rate = Orders / Clicks** — Requires traffic data (e.g., from ads or analytics connectors)
6. **Return Rate = Returned Orders / Total Orders** — Calculated from Consumer order data
7. **AI Insights Prioritized** — Ranked by business impact; actionable recommendations only

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Anomaly Detection** — Flag sudden revenue dips, unusual order patterns |
| **Trend Prediction** — Forecast category/product trends 30 days ahead |
| **Channel Optimization** — Recommend which channels to invest in based on ROI |
| **Product Recommendation** — Suggest products to promote based on profitability + demand |
| **Seasonal Pattern Recognition** — Identify recurring seasonal peaks; recommend pre-stocking |
| **Competitive Benchmarking** — Compare AOV, conversion rate to industry averages |

### Required APIs

```
GET /api/reports/summary
  Query: ?period=30days&startDate=2026-06-13&endDate=2026-07-13
  Returns: all KPIs with trends, channel breakdown, product trends

GET /api/reports/kpis
  Query: ?period=30days
  Returns: 8 KPI cards with values, trends, trend direction

GET /api/reports/channelBreakdown
  Query: ?period=30days
  Returns: channel list with orders, revenue, profit, % of total

GET /api/reports/productTrends
  Query: ?period=30days&type=sales
  Returns: daily sales trend data for top 5 products

GET /api/reports/categoryTrends
  Query: ?period=30days
  Returns: daily trend data by category

GET /api/reports/insights
  Query: ?limit=5&priority=high
  Returns: AI-generated insights ranked by priority + actionability

GET /api/reports/customReport
  Query: ?metrics=revenue,profit,orders&period=30days
  Returns: custom report data for export

GET /api/reports/export
  Query: ?format=pdf&period=30days
  Returns: download link for PDF report
```

### States

#### Loading State
```
Show skeleton/placeholder:
- KPI cards (8x shimmer)
- Pie chart (shimmer)
- Line chart (shimmer)
- Insight cards (4x shimmer)
```

#### Empty State
```
No data for selected period:
- Icon: chart icon
- Message: "No data for this period. Check your date range or sync your data."
- CTA: "Select Different Dates" or "Sync Data"
```

#### Error State
```
If API fails:
- Error message: "Could not load reports. Check your connection."
- Retry button
- Offline fallback: show cached summary from last period with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - KPI cards stacked (8 cards in 2x4 grid)
  - Pie chart full-width
  - Line charts full-width, swipeable for date range
  - Tab bar horizontal scroll
  - Insight cards single-column

Tablet (600px+): Side-by-side layout
  - Left: KPI summary + insights
  - Right: Charts (pie + line) in tabbed interface
  - Both scrollable sections
```

### Accessibility

- ✅ Heading hierarchy: H1 (Reports) → H2 (KPIs) → H3 (Individual metrics)
- ✅ Touch targets: 44px minimum (cards, tabs, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All metrics have descriptive labels
- ✅ Charts: Include data table alternatives for screen readers
- ✅ Trend arrows: Labeled ("Up", "Down") not just visual

### Future Enhancements

1. ⏳ Custom report builder (select metrics, dimensions, date range, export format)
2. ⏳ Comparative analysis (compare 2 products/channels side-by-side)
3. ⏳ Cohort analysis (track customer cohorts by acquisition date)
4. ⏳ Funnel analysis (awareness → consideration → purchase → repeat)
5. ⏳ A/B test tracking (compare marketing campaign performance)
6. ⏳ Scheduled reports (auto-email KPI summary daily/weekly)
7. ⏳ Competitor benchmarking (compare metrics to industry averages)

---

## Tiếng Việt — Màn Hình Báo Cáo

### Mục Đích

**Báo Cáo** là trung tâm thông minh kinh doanh. Nó hiển thị:
- Bảng điều khiển KPI với xu hướng 30/90 ngày
- Phân tích kênh
- Phân tích xu hướng
- Thông tin và khuyến nghị của AI
- Trình tạo báo cáo tùy chỉnh
- Khả năng xuất
  
### Mục Tiêu Kinh Doanh

Giúp doanh nhân đo lường sức khỏe kinh doanh bằng cách:
1. Theo dõi các chỉ số chính
2. Hiểu kênh nào tạo ra lợi nhuận
3. Xác định xu hướng sản phẩm/danh mục
4. Phát hiện các mẫu mùa vụ
5. Nhận được khuyến nghị tối ưu hóa

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 9 main components  
**API Calls:** 8 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-BUSINESS-JOURNEY.md
