# Screen Specification — Consumer Detail (Customer Profile)

## Chi Tiết Màn Hình — Chi Tiết Khách Hàng (Hồ Sơ Khách Hàng)

---

## English — Consumer Detail Screen

### Purpose

**Consumer Detail** shows comprehensive customer information. It displays:
- Customer profile (name, contact, location)
- Purchase history (order list, total spent, LTV)
- Segment membership (which customer segments they belong to)
- Communication history (messages, emails, notes)
- Lifetime Value (LTV) and CLV (Customer Lifetime Value)
- Preferred products and purchase patterns
- Loyalty tier status
- Action buttons (email, SMS, special offer, export)

**User Journey:** See customer row in Consumer module → tap → view customer profile → check purchase history → send targeted offer.

### Business Goal

Help entrepreneurs understand and nurture customers by:
1. Building complete customer profiles
2. Understanding purchase preferences and patterns
3. Identifying high-value vs at-risk customers
4. Personalizing communication and offers
5. Building long-term customer relationships

### Information Architecture

```
Consumer Detail Screen
├── Header
│   ├── Back button
│   ├── Title: "Customer Profile"
│   ├── Share button
│   └── More menu (export, delete, etc.)
├── Customer Hero Section
│   ├── Customer avatar (initial or photo)
│   ├── Customer name (large)
│   ├── Tier badge (VIP / Gold / Silver / Bronze)
│   ├── Location (city, country)
│   ├── Joined date
│   └── Quick-access buttons: Call / Email / Message
├── Key Metrics Summary
│   ├── Total Spent: $2,156.80
│   ├── Orders: 24
│   ├── LTV: $2,156.80
│   ├── Repeat Purchase Rate: 85%
│   └── Last Purchase: 2026-07-10
├── Tab Bar (Horizontal)
│   ├── Overview (active)
│   ├── Orders
│   ├── Communication
│   ├── Segments
│   └── Settings
├── Main Content Area (varies by tab)
│   └── [Tab-specific content]
├── Overview Tab Content (if tab = Overview)
│   ├── Customer info summary
│   ├── Contact details
│   ├── Preferred products (top 3)
│   ├── Segment membership
│   ├── Loyalty status
│   └── "Send Offer" CTA
└── Back Navigation
    └── Return to Consumer module
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg with shadow | Back + Title + Share + Menu |
| **Avatar** | 80x80px, rounded, centered | Customer initials or photo |
| **Tier Badge** | 60x20px, colored | VIP (gold), Gold (yellow), Silver (gray), Bronze (brown) |
| **Metric Card** | 1 of 4 in grid, 100x100px | Metric value + label |
| **Tab Bar** | Horizontal scroll, 50px height | 5 tabs with underline indicator |
| **Order Row** | Full-width, 80px, tappable | Date + order ID + amount + status badge |
| **Message Bubble** | Full-width, 70px min | Sender + message snippet + date + unread indicator |
| **Segment Badge** | 80x20px, rounded | Segment name (e.g., "Loyal Customers", "High Value") |
| **Product Card** | 1 of 3 in scroll, 100x120px | Product image + name + purchase count + last purchased date |
| **Action Button** | 1 of 3-4 in row, 50px | Call / Email / Message / Offer icons |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Tab item | Content Switch | Switch to Orders / Communication / Segments / Settings |
| Order Row | Order Detail | Show order items, shipping status, payment status, tracking |
| Message | Conversation Detail | Show full message thread or email conversation |
| Product Card | Product Detail (SC-16) | Navigate to product page in Inventory module |
| Segment Badge | Segment Detail | Show segment criteria, member count, campaigns available |
| Call button | Phone App | Dial customer's phone number |
| Email button | Email App | Open email draft to customer email address |
| "Send Offer" button | Offer Modal | Create and send personalized offer (discount, exclusive product) |
| Back button | Previous Screen | Return to Consumer module |

### Mock Data

```json
{
  "customer": {
    "id": 1,
    "name": "Phương Nguyễn",
    "tier": "VIP",
    "email": "phuong@example.com",
    "phone": "+84912345678",
    "location": { "city": "Ho Chi Minh City", "country": "Vietnam" },
    "joinedDate": "2026-01-15",
    "avatar": "https://...",
    "source": "Shopee",
    "lastContactDate": "2026-07-12"
  },
  "metrics": {
    "totalSpent": "$2,156.80",
    "totalOrders": 24,
    "ltv": "$2,156.80",
    "repeatPurchaseRate": 85,
    "lastPurchaseDate": "2026-07-10",
    "avgOrderValue": "$89.87",
    "churnRisk": "Low"
  },
  "contactInfo": {
    "email": "phuong@example.com",
    "emailVerified": true,
    "phone": "+84912345678",
    "wechat": "phuong_2026",
    "facebook": "phuong.nguyen.2026"
  },
  "preferredProducts": [
    { "productId": 1, "name": "Quạt mini cấm tay", "purchaseCount": 4, "lastPurchased": "2026-07-10", "spent": "$33.80" },
    { "productId": 2, "name": "Túi chống nước du lịch", "purchaseCount": 3, "lastPurchased": "2026-06-25", "spent": "$28.80" },
    { "productId": 5, "name": "Portable Phone Charger", "purchaseCount": 2, "lastPurchased": "2026-05-30", "spent": "$25.00" }
  ],
  "segments": [
    { "id": 1, "name": "Loyal Customers", "criteria": "3+ orders, repeat rate > 70%", "joinedDate": "2026-02-01" },
    { "id": 2, "name": "High Value", "criteria": "Total spent > $500", "joinedDate": "2026-03-15" }
  ],
  "orders": [
    { "id": "ORD-001", "date": "2026-07-10", "items": 2, "amount": "$16.90", "status": "Delivered", "channel": "Shopee" },
    { "id": "ORD-002", "date": "2026-07-05", "items": 1, "amount": "$8.45", "status": "Delivered", "channel": "TikTok" },
    { "id": "ORD-003", "date": "2026-06-30", "items": 3, "amount": "$25.35", "status": "Delivered", "channel": "Shopee" }
  ],
  "communication": [
    { "id": 1, "type": "message", "channel": "Shopee", "message": "Can you ship to my office?", "date": "2026-07-12 14:30", "replied": false },
    { "id": 2, "type": "review", "channel": "Shopee", "message": "Great product! Works perfectly.", "rating": 5, "date": "2026-07-10", "replied": true },
    { "id": 3, "type": "email", "subject": "Order Confirmation - ORD-001", "date": "2026-07-10 09:15", "status": "Opened" }
  ],
  "loyaltyStatus": {
    "tier": "VIP",
    "points": 2156,
    "nextTierRequirements": "Already at highest tier",
    "exclusive": "Free shipping on orders over $10, Priority customer service"
  }
}
```

### Business Rules

1. **Tier Auto-Calculated** — VIP (LTV > $1,500), Gold (LTV $500-1,500), Silver (LTV $100-500), Bronze (< $100)
2. **LTV = Total Spent** — Lifetime value equals sum of all order totals (simplified model in Phase 1)
3. **Repeat Rate = Repeat Orders / Total Orders** — What % of customers buy more than once?
4. **Churn Risk Flag** — Auto-flagged if no purchase in 60+ days
5. **Contact Privacy** — Full phone number shown only in detail view; masked elsewhere
6. **Segment Auto-Assign** — AI assigns segments based on purchase patterns; manual override available
7. **Order History Complete** — Shows all orders from all channels (Shopee, TikTok, direct, etc.) unified

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Churn Prediction** — Flag if no purchase 60+ days; recommend re-engagement offer |
| **LTV Projection** — Forecast future LTV based on purchase history + product affinity |
| **Personalized Offer Generation** — Suggest discount/product offer based on purchase history + segment |
| **Win-back Campaign** — Auto-draft message to at-risk customers (e.g., "We miss you! Here's 20% off") |
| **Segment Assignment** — Auto-cluster into segments (loyal, high-value, at-risk, new) |
| **Next-Buy Prediction** — When is this customer likely to buy next? Recommend outreach timing |

### Required APIs

```
GET /api/consumer/customer/{id}
  Returns: full customer profile (name, contact, tier, joined date, location, source)

GET /api/consumer/customer/{id}/metrics
  Returns: totalSpent, totalOrders, LTV, repeatRate, lastPurchase, churnRisk

GET /api/consumer/customer/{id}/preferredProducts
  Returns: top products purchased with counts, dates, amounts

GET /api/consumer/customer/{id}/segments
  Returns: segments customer belongs to with criteria, joined dates

GET /api/consumer/customer/{id}/orders
  Query: ?limit=20&sort=recent
  Returns: order history from all channels with amounts, statuses

GET /api/consumer/customer/{id}/communication
  Query: ?limit=20&sort=recent
  Returns: messages, reviews, emails, calls with dates, status

GET /api/consumer/customer/{id}/offers
  Returns: offers sent to this customer with acceptance rate

POST /api/consumer/customer/{id}/offer
  Body: { discountPercent, productIds, validUntil }
  Returns: offer created + sent to customer

POST /api/consumer/customer/{id}/message
  Body: { message, channel }
  Returns: message sent to customer

PUT /api/consumer/customer/{id}
  Body: { name, email, phone, notes }
  Returns: customer profile updated
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Avatar (shimmer)
- Metric cards (4x shimmer)
- Tab bar (shimmer)
- Content area (5x shimmer rows)
```

#### Empty State
```
No orders / No communication:
- Message: "This customer hasn't placed any orders yet." or "No messages yet. Start a conversation!"
- CTA: "Send Welcome Message" or "Browse Catalog"
```

#### Error State
```
If API fails:
- Error message: "Could not load customer. Check your connection."
- Retry button
- Offline fallback: show cached profile with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Hero section full-width
  - Metric cards grid (2x2)
  - Tab bar horizontal scroll
  - Content single-column
  - Action buttons stacked or grid

Tablet (600px+): Side-by-side layout
  - Left: Hero + metrics + preferred products
  - Right: Tab content (scrollable)
  - Action buttons side-by-side (4 in row)
```

### Accessibility

- ✅ Heading hierarchy: H1 (Customer name) → H2 (Sections) → H3 (Items)
- ✅ Touch targets: 44px minimum (tabs, buttons, order items)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All buttons have text (e.g., "Call", "Email", "Send Offer")
- ✅ Avatar: Initials or photo; alt text "Avatar for [Name]"
- ✅ Tier: Label included (e.g., "VIP Tier" not just gold color)
- ✅ Dates: Formatted consistently, localized to user's timezone

### Future Enhancements

1. ⏳ Customer notes / timeline (add private notes, see interaction history)
2. ⏳ Lifetime interactions (all touchpoints: orders, messages, reviews, returns)
3. ⏳ Personalized email campaigns (send targeted campaigns to specific customers)
4. ⏳ Referral tracking (did this customer refer others? track commissions)
5. ⏳ Wishlist sync (see items customer added to wishlist but didn't buy)
6. ⏳ Loyalty program (manual point adjustment, exclusive tier rewards)
7. ⏳ Customer health score (composite score: LTV, frequency, recency, engagement)

---

## Tiếng Việt — Màn Hình Chi Tiết Khách Hàng

### Mục Đích

**Chi Tiết Khách Hàng** hiển thị thông tin khách hàng toàn diện. Nó hiển thị:
- Hồ sơ khách hàng
- Lịch sử mua hàng
- Thành viên phân loại
- Lịch sử giao tiếp
- Giá trị suốt đời
- Sản phẩm ưa thích
- Trạng thái tiers tính trung thực
- Nút hành động

### Mục Tiêu Kinh Doanh

Giúp doanh nhân hiểu và nuôi dưỡng khách hàng bằng cách:
1. Xây dựng hồ sơ khách hàng hoàn chỉnh
2. Hiểu sở thích và mẫu mua hàng
3. Xác định khách hàng có giá trị cao so với có nguy hiểm
4. Cá nhân hóa giao tiếp và ưu đãi
5. Xây dựng mối quan hệ khách hàng dài hạn

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 10 main components  
**API Calls:** 10 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-MORE.md
