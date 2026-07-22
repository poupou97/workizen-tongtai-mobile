# Screen Specification — Consumer (Customer Intelligence & CRM)

## Chi Tiết Màn Hình — Khách Hàng (Thông Tin Khách Hàng & CRM)

---

## English — Consumer Screen

### Purpose

**Consumer** is the customer intelligence and CRM hub. It shows:
- Customer database (215 customers, segmented)
- Order history and lifetime value (LTV)
- Omnichannel activity (Shopee, TikTok, Instagram, direct)
- Customer communication history
- Affiliate and referral program tracking
- Customer community and reviews

**User Journey:** Open Consumer → view customer list segmented by tier → click customer → see LTV, order history, communication → take action (email, SMS, offer).

### Business Goal

Help entrepreneurs understand and nurture customers by:
1. Building a 360° view of each customer (purchase history, preferences, lifetime value)
2. Segmenting customers for targeted campaigns
3. Managing omnichannel customer communication (Shopee messages, WhatsApp, email)
4. Tracking referral and affiliate revenue
5. Building a community around products/brand

### Information Architecture

```
Consumer Screen
├── Header
│   ├── Title: "Consumer - Customer Intelligence"
│   ├── Filter button (by segment, channel, VIP status)
│   └── Search bar
├── Overview Section
│   ├── Total Customers: 215
│   ├── Active This Month: 78
│   ├── Repeat Rate: 42%
│   ├── Avg. LTV: $456.80
│   └── Top Channel: Shopee (48%)
├── Tab Bar (Horizontal)
│   ├── CRM (customer list, active)
│   ├── CDP (data platform)
│   ├── Channels (omnichannel)
│   ├── Orders (transaction list)
│   ├── Inbox (messages)
│   ├── Reviews (feedback)
│   ├── Affiliate (partner network)
│   ├── Community (customer groups)
│   └── Segments (audience segments)
├── Main Content Area (varies by tab)
│   └── [Tab-specific content]
├── Customer List (if tab = CRM)
│   ├── Customer Row 1: Avatar + Name + Tier + Orders + LTV + Last Purchase
│   ├── Customer Row 2: ...
│   └── Pagination
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title + filter icon + search bar |
| **Overview Card** | Full-width, 140px, grid layout | 5 stat boxes (customers, active, repeat rate, avg LTV, top channel) |
| **Tab Bar** | Horizontal scroll, 50px height | 9 tabs with underline indicator |
| **Customer Row** | Full-width, 80px, tappable | Avatar (40px) + Name + Tier badge (VIP/Gold/Silver) + Order count + LTV + Last purchase date |
| **Tier Badge** | 40x20px, colored | VIP (gold), Gold (yellow), Silver (gray), Bronze (brown) |
| **Channel Icon** | 24x24px in row | Shopee, TikTok, Instagram, Direct, etc. |
| **Order Summary Card** | 100x80px | Date + amount + status + items count |
| **Review Card** | Full-width, 100px | Star rating + text snippet + date |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Customer Row | Customer Detail (SC-11) | Show full customer profile, order history, segments, LTV |
| Order Card | Order Detail | Show order items, shipping status, payment status, notes |
| Review | Review Detail | Show full review text, respond to review |
| Segment tab | Segment Detail | Show segment members, criteria, campaigns |
| "Inbox" tab | Message list | Show messages from customers (Shopee, WhatsApp, email) |
| "Affiliate" tab | Affiliate list | Show active affiliates, referral links, commissions |

### Mock Data

```json
{
  "overview": {
    "totalCustomers": 215,
    "activeThisMonth": 78,
    "repeatRate": "42%",
    "avgLTV": "$456.80",
    "topChannel": "Shopee (48%)",
    "churnRisk": 12
  },
  "customers": [
    {
      "id": 1,
      "name": "Phương Nguyễn",
      "email": "phuong@example.com",
      "phone": "+84912345678",
      "tier": "VIP",
      "avatar": "https://...",
      "totalOrders": 24,
      "totalSpent": "$2,156.80",
      "ltv": "$2,156.80",
      "repeatPurchaseRate": 85,
      "lastPurchaseDate": "2026-07-10",
      "channels": ["Shopee", "WhatsApp", "Email"],
      "segments": ["Loyal Customers", "High Value"],
      "preferredProduct": "Mini Appliances"
    },
    {
      "id": 2,
      "name": "Linh Trần",
      "email": "linh@example.com",
      "phone": "+84923456789",
      "tier": "Gold",
      "avatar": "https://...",
      "totalOrders": 8,
      "totalSpent": "$845.60",
      "ltv": "$845.60",
      "repeatPurchaseRate": 62,
      "lastPurchaseDate": "2026-06-25",
      "channels": ["TikTok", "Instagram"],
      "segments": ["Social Commerce", "Summer Active"],
      "preferredProduct": "Travel Accessories"
    },
    {
      "id": 3,
      "name": "Huy Đặng",
      "email": "huy@example.com",
      "phone": "+84934567890",
      "tier": "Silver",
      "avatar": "https://...",
      "totalOrders": 3,
      "totalSpent": "$234.50",
      "ltv": "$234.50",
      "repeatPurchaseRate": 35,
      "lastPurchaseDate": "2026-05-15",
      "channels": ["Shopee"],
      "segments": ["Occasional Buyers"],
      "preferredProduct": "Accessories"
    }
  ],
  "segments": [
    {
      "id": 1,
      "name": "Loyal Customers",
      "size": 45,
      "criteria": "3+ orders, repeat purchase rate > 70%",
      "avgLTV": "$1,234.50"
    },
    {
      "id": 2,
      "name": "High Value",
      "size": 28,
      "criteria": "Total spent > $500",
      "avgLTV": "$856.30"
    },
    {
      "id": 3,
      "name": "Social Commerce",
      "size": 67,
      "criteria": "Source: TikTok or Instagram",
      "avgLTV": "$345.20"
    },
    {
      "id": 4,
      "name": "At Risk (Churn)",
      "size": 12,
      "criteria": "No purchase in 60+ days",
      "avgLTV": "$245.80"
    }
  ],
  "channels": [
    { "name": "Shopee", "customers": 103, "orders": 456, "revenue": "$12,456.80" },
    { "name": "TikTok Shop", "customers": 78, "orders": 234, "revenue": "$8,234.50" },
    { "name": "Instagram", "customers": 34, "orders": 89, "revenue": "$3,456.20" },
    { "name": "Email/Direct", "customers": 56, "orders": 123, "revenue": "$5,678.90" }
  ],
  "affiliates": [
    { "id": 1, "name": "Blogger Trang", "referrals": 34, "conversions": 12, "commission": "$456.80", "status": "active" },
    { "id": 2, "name": "Influencer Linh", "referrals": 89, "conversions": 45, "commission": "$2,156.80", "status": "active" }
  ]
}
```

### Business Rules

1. **Customer Tiers Automatic** — VIP (LTV > $1,500), Gold (LTV $500-1,500), Silver (LTV $100-500), Bronze (LTV < $100)
2. **Repeat Rate Calculated** — # of repeat orders / total customers in segment
3. **LTV = Total Spent** — Lifetime value = sum of all order totals (refined model in Phase 2)
4. **Churn Risk Flag** — Auto-flagged if no purchase in 60+ days
5. **Segment Criteria Dynamic** — AI suggests segments based on purchase patterns; custom segments available
6. **Omnichannel Unified** — Each customer row shows all channels they use (Shopee, TikTok, Email, etc.)
7. **Privacy Compliant** — Phone numbers masked except in detail view; email opt-in tracked

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Customer Segmentation** | Auto-cluster by: purchase frequency, LTV, product preference, seasonality, channel |
| **Churn Prediction** | Flag customers at risk (no purchase 60+ days); recommend re-engagement campaign |
| **LTV Prediction** | Project future LTV based on purchase history + product category + seasonality |
| **Recommendation Engine** | Suggest products to each customer based on purchase history + similar customers |
| **Win-back Campaign** | Auto-suggest special offers for at-risk customers (churn prevention) |
| **Affiliate Matching** | Recommend top-performing affiliates for new products |

### Required APIs

```
GET /api/consumer/summary
  Returns: totalCustomers, activeThisMonth, repeatRate, avgLTV, topChannel, churnRisk

GET /api/consumer/customers
  Query: ?segment=loyal&tier=VIP&channel=shopee&limit=50
  Returns: customer list with LTV, order count, last purchase, segments

GET /api/consumer/customer/{id}
  Returns: full customer profile (SC-11)

GET /api/consumer/segments
  Returns: list of segments with size, criteria, avgLTV

GET /api/consumer/channels
  Returns: channel breakdown with customer count, orders, revenue

GET /api/consumer/orders
  Query: ?customerId=1&limit=20
  Returns: customer's order history with dates, amounts, statuses

GET /api/consumer/reviews
  Returns: recent customer reviews with ratings, text, dates

GET /api/consumer/affiliates
  Returns: affiliate list with referral stats, commissions, status

GET /api/consumer/inbox
  Returns: unread messages from customers (Shopee, WhatsApp, Email)
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Overview card (shimmer)
- Tab bar (shimmer)
- Customer rows (5x shimmer)
- Segment cards (4x shimmer)
```

#### Empty State
```
No customers found:
- Icon: people icon
- Message: "No customers yet. Start by adding your first order or importing customer data."
- CTA: "Import Customers" or "Create First Order"
```

#### Error State
```
If API fails:
- Error message: "Could not load customers. Check your connection."
- Retry button
- Offline fallback: show cached customer list with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Overview card stacked (5 stat boxes)
  - Tab bar horizontal scroll
  - Customer rows single-column
  - Tier badges on the right

Tablet (600px+): Side-by-side layout
  - Left: Customer list (2-column)
  - Right: Segment summary + channel breakdown
  - Tab bar full-width
```

### Accessibility

- ✅ Heading hierarchy: H1 (Consumer) → H2 (Segments) → H3 (Individual segments)
- ✅ Touch targets: 44px minimum (rows, tabs, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text); tier badges have text labels
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All icons have text labels
- ✅ Phone masking: +84912***678 format for privacy

### Future Enhancements

1. ⏳ Customer communication history (unified inbox for all channels)
2. ⏳ SMS/Email campaign builder (send targeted messages to segments)
3. ⏳ Loyalty program tracking (points, rewards, tier progression)
4. ⏳ Customer feedback sentiment analysis (AI analyze reviews)
5. ⏳ Win-back automation (AI-suggested offers for at-risk customers)
6. ⏳ Referral program automation (track referral links, auto-calculate commissions)
7. ⏳ Customer community (private group for loyal customers)

---

## Tiếng Việt — Màn Hình Khách Hàng

### Mục Đích

**Khách Hàng** là trung tâm thông tin khách hàng và CRM. Nó hiển thị:
- Cơ sở dữ liệu khách hàng (215 khách, được phân loại)
- Lịch sử đơn hàng và giá trị suốt đời
- Hoạt động xuyên kênh
- Lịch sử giao tiếp khách hàng
- Theo dõi chương trình tiếp thị liên kết
- Cộng đồng và đánh giá khách hàng

### Mục Tiêu Kinh Doanh

Giúp doanh nhân hiểu và nuôi dưỡng khách hàng bằng cách:
1. Xây dựng chế độ xem 360° cho từng khách hàng
2. Phân loại khách hàng cho các chiến dịch được nhắm mục tiêu
3. Quản lý giao tiếp khách hàng xuyên kênh
4. Theo dõi doanh thu tiếp thị liên kết
5. Xây dựng cộng đồng xung quanh sản phẩm

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 8 main components  
**API Calls:** 9 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-FINANCE.md
