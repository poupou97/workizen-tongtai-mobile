# Screen Specification — Home Dashboard

## Chi Tiết Màn Hình — Trang Chủ

---

## English — Home Screen

### Purpose

**Home** is the daily entry point and command center. It shows:
- Business summary for the day
- AI-recommended opportunities and missions
- Quick access to major modules
- Latest alerts and achievements

**User Journey:** Open app → see today's business snapshot + 3-5 recommended actions → tap to explore deeper.

### Business Goal

Help entrepreneurs start their day by:
1. Understanding today's business status at a glance
2. Discovering today's top opportunities
3. Getting AI-recommended next actions
4. Celebrating progress and milestones

### Information Architecture

```
Home Screen
├── Header
│   ├── Greeting (AI Copilot)
│   ├── Notification bell
│   └── Profile/Settings
├── Summary Section
│   ├── AI Summary ("Hôm nay tôi tìm được 12 cơ hội cho bạn")
│   └── Key stat (e.g., "Revenue +18.6%")
├── Module Cards (4 cards)
│   ├── Producer (Green)
│   ├── Inventory (Orange)
│   ├── Consumer (Blue)
│   └── Business Journey (Gold)
├── Mission Today
│   └── AI-recommended daily tasks (max 5)
├── Opportunities
│   └── Top 3 AI-discovered opportunities
├── Business Summary (KPIs)
│   ├── Revenue
│   ├── Profit
│   ├── Orders
│   └── Trend indicators
└── Bottom Navigation (5 tabs)
    ├── Home (active)
    ├── Producer
    ├── Inventory
    ├── Consumer
    └── Opportunity / More
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px height | Profile pic + notification bell + title |
| **Greeting Card** | Full-width, 80px height, AI badged | "Chào Phương! 🎉 Hôm nay tôi tìm được 12 cơ hội cho bạn." |
| **Module Card** | 1 of 4 in grid, 160x120px, tappable | Producer card: icon + title + stat + arrow |
| **Mission Card** | Full-width, 80px, checkable | Task icon + title + due date + priority |
| **Opportunity Card** | Full-width or half-width, 100px, swipeable | Image + title + market + profit + score |
| **KPI Card** | 1 of 4 in row, 80x80px | Value + label + trend indicator |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Producer Card | Producer screen | Navigate to Producer module |
| Inventory Card | Inventory screen | Navigate to Inventory module |
| Consumer Card | Consumer screen | Navigate to Consumer module |
| Business Card | Business Journey | Navigate to Journey module |
| Mission Item | Mission detail | Show AI guidance + checklist |
| Opportunity | Opportunity detail | Drill into full opportunity card |
| Notification Bell | Notifications | Show notification center |
| Profile | Settings | Show profile/account screen |

### Mock Data

```json
{
  "greeting": "Chào Phương! 🎉",
  "copilotSummary": "Hôm nay tôi tìm được 12 cơ hội cho bạn.",
  "keyStat": {
    "value": "+18.6%",
    "label": "Revenue vs last month"
  },
  "modules": [
    { "title": "Producer", "count": "18 opportunities", "color": "green" },
    { "title": "Inventory", "count": "1,256 products", "color": "orange" },
    { "title": "Consumer", "count": "215 customers", "color": "blue" },
    { "title": "Business", "count": "1 active journey", "color": "gold" }
  ],
  "missions": [
    { "id": 1, "title": "Nhập 300 sản phẩm Máy xay mini", "priority": "high", "dueDate": "Today" },
    { "id": 2, "title": "Trả lời 15 khách VIP", "priority": "high", "dueDate": "Today" },
    { "id": 3, "title": "Dùng Campaign A", "priority": "medium", "dueDate": "Today" }
  ],
  "opportunities": [
    { "title": "Quạt mini cấm tay — Arbitrage", "market": "Shopee → Amazon US", "profit": "$8.45 (42%)", "score": 92 },
    { "title": "Túi chống nước du lịch", "market": "1688 → TikTok", "profit": "$6.12 (38%)", "score": 88 },
    { "title": "Máy pha cà phê mini", "market": "Alibaba → eBay", "profit": "$9.20 (45%)", "score": 90 }
  ],
  "kpis": {
    "revenue": { "value": "$24,560", "trend": "+18.6%" },
    "profit": { "value": "$8,560", "trend": "+23.4%" },
    "orders": { "value": "1,256", "trend": "+15.2%" },
    "customers": { "value": "215", "trend": "+20.1%" }
  }
}
```

### Business Rules

1. **Personalization** — Greeting changes based on time (morning/afternoon/evening)
2. **Smart Missions** — AI recommends daily tasks based on user's goals + business status
3. **Opportunities Ranked** — Top 3 by AI score (highest profit potential first)
4. **KPI Trends** — Always show 30-day trend vs previous month
5. **Notification Badge** — Red badge on notification icon if unread alerts
6. **One-Tap Actions** — Module cards navigate directly without confirmation

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Greeting Personalization** | "Chào [Name]! Hôm nay thứ [Day]. Revenue +X% vs last week." |
| **Mission Recommendation** | Analyze user's goals, active journeys, pending tasks → recommend top 3 for today |
| **Opportunity Scoring** | Rank opportunities by profit potential + user's business profile match |
| **Alert Prioritization** | Show only the 5 most urgent alerts (low stock, customer churn, etc.) |
| **Trend Prediction** | "Revenue trending +X% based on first 4 hours of day" |

### Required APIs

```
GET /api/home/summary
  Returns: greeting, copilotSummary, keyStat, KPIs

GET /api/home/missions
  Returns: list of today's missions with priority, due date, completion status

GET /api/home/opportunities
  Returns: top 3 opportunities with scores ranked

GET /api/home/notifications
  Returns: unread notification count + list
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Greeting card (shimmer)
- Module cards (4x shimmer boxes)
- Mission items (3x shimmer)
- KPI cards (4x shimmer boxes)
```

#### Empty State
```
First-time user:
- Welcome graphic with fox mascot
- "Welcome to Tổng Tài! Let's set up your first business goal."
- CTA: "Create a Business Journey"
```

#### Error State
```
If data fails to load:
- Error message: "Could not load today's data. Check your connection."
- Retry button
- Offline fallback: show last cached data with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Module cards in 2x2 grid
  - Single-column opportunities

Tablet (600px+): Wider layout
  - Module cards in 1x4 horizontal scroll
  - 2-column opportunity cards
```

### Accessibility

- ✅ Heading hierarchy: H1 (Greeting) → H2 (Missions) → H3 (Items)
- ✅ Touch targets: 44px minimum (module cards, nav buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on interactive elements
- ✅ Labels: All buttons have text labels

### Future Enhancements

1. ⏳ Customizable widget dashboard (drag-drop modules)
2. ⏳ Voice greeting (AI speaks the greeting)
3. ⏳ Gesture quick-actions (swipe for shortcuts)
4. ⏳ Dark mode theme toggle
5. ⏳ Widget for home screen (iOS/Android)

---

## Tiếng Việt — Màn Hình Trang Chủ

### Mục Đích

**Trang Chủ** là điểm vào hàng ngày và trung tâm điều khiển. Nó hiển thị:
- Tóm tắt kinh doanh cho ngày
- Cơ hội và sứ mệnh được AI đề xuất
- Truy cập nhanh các mô-đun chính
- Cảnh báo và thành tích mới nhất

### Mục Tiêu Kinh Doanh

Giúp doanh nhân bắt đầu ngày họ bằng cách:
1. Hiểu trạng thái kinh doanh hôm nay một cách nhanh chóng
2. Khám phá các cơ hội hàng đầu hôm nay
3. Nhận được hành động tiếp theo được AI đề xuất
4. Kỷ niệm tiến độ và mốc

(Xem tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 6 main components  
**API Calls:** 4 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-PRODUCER.md

