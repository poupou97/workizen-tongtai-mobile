# Screen Specification — Producer Detail (Supplier Profile)

## Chi Tiết Màn Hình — Chi Tiết Nhà Sản Xuất (Hồ Sơ Nhà Cung Cấp)

---

## English — Producer Detail Screen

### Purpose

**Producer Detail** shows comprehensive supplier information. It displays:
- Supplier profile (name, location, certifications, years in business)
- Rating and reviews (aggregated from Alibaba, Taobao, Global Trade)
- Capabilities (product categories, certifications, capacities)
- Product portfolio (products this supplier offers)
- Pricing and terms (MOQ, lead time, payment terms)
- Contact information and negotiation tools
- Historical relationships (if user has worked with them before)

**User Journey:** See supplier card in Producer module → tap → view supplier profile → check reviews → contact supplier.

### Business Goal

Help entrepreneurs evaluate and manage suppliers by:
1. Assessing supplier reputation and reliability
2. Understanding product portfolio and capabilities
3. Comparing pricing and terms across suppliers
4. Initiating negotiations with confidence
5. Tracking supplier performance over time

### Information Architecture

```
Producer Detail Screen
├── Header
│   ├── Back button
│   ├── Title: "Supplier Profile"
│   ├── Share button
│   └── Bookmark / Favorite toggle
├── Supplier Hero Section
│   ├── Company logo (100x100px)
│   ├── Company name (large)
│   ├── Location (city, country)
│   ├── Years in business
│   ├── Certifications (badges: ISO 9001, CE mark, etc.)
│   └── Quick-access buttons: Call / Email / Message
├── Rating Section (Horizontal card)
│   ├── Overall rating (4.8 stars, 5-point scale)
│   ├── Review count (245 reviews)
│   ├── Breakdown (5★ 80%, 4★ 15%, 3★ 3%, etc.)
│   ├── Supplier response time (avg hours)
│   └── "View All Reviews" link
├── Tab Bar (Horizontal)
│   ├── Overview (active)
│   ├── Details
│   ├── Products
│   ├── Reviews
│   └── Contact
├── Main Content Area (varies by tab)
│   └── [Tab-specific content]
├── Overview Tab Content (if tab = Overview)
│   ├── Summary paragraph
│   ├── Key metrics (MOQ, lead time, payment terms)
│   ├── Certifications
│   ├── Business scope
│   └── "Contact Supplier" CTA
└── Back Navigation
    └── Android: Back swipe or button
    └── iOS: Back button
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg with shadow | Back + Title + Share + Favorite |
| **Hero Logo** | 100x100px, centered, rounded corners | Company logo with fallback initials |
| **Rating Card** | Full-width, 120px | Stars (4.8★) + count (245) + breakdown bars + response time |
| **Metric Box** | 1 of 3-4 in grid, 100x80px | Label + value (MOQ: 100 units) |
| **Tab Bar** | Horizontal scroll, 50px height | 5 tabs with underline indicator |
| **Review Card** | Full-width, 100px, scrollable | Star rating + reviewer name + review text + date + helpful count |
| **Product Row** | Full-width, 80px, tappable | Product image (40x40px) + name + SKU + price |
| **Contact Button** | Full-width or 1 of 3 in grid, 50px | Call / Email / Message icons + labels |
| **Certification Badge** | 60x20px, rounded | Text: "ISO 9001", "CE Mark", "FDA", etc. |
| **Back Navigation** | 44x44px, hit area | Back arrow icon |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Tab item | Content Switch | Switch to Details / Products / Reviews / Contact tab |
| "View All Reviews" | Reviews Full List | Show all reviews with filters and sort |
| Product Row | Product Detail | Link to specific product (if Tổng Tài tracks this supplier's catalog) |
| Call button | Phone App | Dial supplier's phone number |
| Email button | Email App | Open email draft to supplier email address |
| Message button | Message Modal | Compose message to supplier (in-app messaging if available) |
| Review (helpful) | Vote Recorded | Mark review as helpful (like counter increments) |
| Back button | Previous Screen | Return to Producer module or opportunity detail |

### Mock Data

```json
{
  "supplier": {
    "id": 1,
    "name": "TechPro Wholesale",
    "location": { "city": "Shenzhen", "country": "China", "timezone": "CST" },
    "yearsInBusiness": 12,
    "logo": "https://...",
    "website": "techprowholesale.com",
    "certifications": ["ISO 9001", "CE Mark", "FDA Approved"],
    "businessScope": "Electronics, consumer gadgets, home appliances wholesale",
    "contactPhone": "+86 755 1234 5678",
    "contactEmail": "sales@techprowholesale.com",
    "wechat": "techpro_wholesale",
    "whatsapp": "+86 755 1234 5678"
  },
  "rating": {
    "overall": 4.8,
    "scale": 5,
    "totalReviews": 245,
    "responseTime": "2-4 hours",
    "breakdown": {
      "5: 80,
      "4": 40,
      "3": 15,
      "2": 7,
      "1": 3
    }
  },
  "details": {
    "moq": "100 units",
    "leadTime": "7-14 days",
    "paymentTerms": "T/T 50% deposit, 50% balance",
    "shipping": "FOB, CIF, DDP available",
    "factorySize": "50,000 sqm",
    "employees": "500+",
    "productRanges": ["Consumer Electronics", "Gadgets", "Home Appliances", "Accessories"]
  },
  "reviews": [
    {
      "id": 1,
      "rater": "Nguyễn Phương (verified buyer)",
      "rating": 5,
      "title": "Excellent quality, fast delivery",
      "text": "I ordered 200 units of mini fans. Product quality is amazing. Delivery was 10 days as promised. Great communication throughout. Highly recommend!",
      "date": "2026-07-10",
      "helpfulCount": 23,
      "verified": true
    },
    {
      "id": 2,
      "rater": "Trần Linh (verified buyer)",
      "rating": 4,
      "title": "Good but minor issues",
      "text": "Good quality overall. Some units had minor scratches. Payment process could be smoother. Will order again.",
      "date": "2026-07-05",
      "helpfulCount": 12,
      "verified": true
    },
    {
      "id": 3,
      "rater": "Đặng Huy (verified buyer)",
      "rating": 5,
      "title": "Perfect for reselling on Shopee",
      "text": "Their wholesale pricing is competitive. I've been reselling on Shopee and making good profit margins. TechPro is reliable.",
      "date": "2026-06-28",
      "helpfulCount": 18,
      "verified": true
    }
  ],
  "products": [
    { "id": 1, "name": "Mini Handheld Fan", "sku": "FAN-001", "categories": ["Electronics", "Accessories"], "price": "$2.10/unit (MOQ 100)" },
    { "id": 2, "name": "Phone Ring Stand", "sku": "RING-001", "categories": ["Accessories"], "price": "$0.85/unit (MOQ 500)" },
    { "id": 3, "name": "Portable Phone Charger", "sku": "CHG-001", "categories": ["Electronics"], "price": "$3.50/unit (MOQ 100)" }
  ]
}
```

### Business Rules

1. **Ratings Aggregated** — Combined from Alibaba, Taobao, Global Trade Portal; minimum 50 reviews shown
2. **Certifications Verified** — Only display certs that can be verified; optional third-party validation
3. **Lead Time Ranges** — Show realistic timeframes (e.g., "7-14 days" not "10 days" for precision)
4. **MOQ Transparent** — Clearly show per-product; help user calculate cash impact
5. **Payment Terms Standard** — Show options (T/T, L/C, PayPal, escrow available)
6. **Review Verification** — Mark only verified purchases as "verified buyer"; tag others as unverified
7. **Contact Info Privacy** — Display company contact (public); personal phone/email hidden until interested

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Reputation Scoring** — Combine rating, review sentiment, response time, order fulfillment history |
| **Risk Assessment** — Flag if supplier has recent negative reviews, delays, quality issues |
| **MOQ Optimization** — Given user's cash available, suggest order quantity that balances inventory + cash |
| **Negotiation Assistant** — Suggest opening bid, walk user through negotiation conversation |
| **Supplier Comparison** — Compare this supplier to alternatives: pricing, lead time, quality, reviews |
| **Relationship Tracking** — If user has worked with supplier before, surface history + performance |

### Required APIs

```
GET /api/supplier/{id}
  Returns: full supplier profile (name, location, certifications, years, contact)

GET /api/supplier/{id}/rating
  Returns: overall rating, reviews count, breakdown, response time

GET /api/supplier/{id}/details
  Returns: MOQ, lead time, payment terms, shipping options, factory details

GET /api/supplier/{id}/reviews
  Query: ?limit=20&sort=helpful
  Returns: reviews list with ratings, text, verification status, helpful count

GET /api/supplier/{id}/products
  Returns: products this supplier offers with SKUs, categories, pricing

GET /api/supplier/{id}/riskAssessment
  Returns: AI risk assessment (red/yellow/green flag)

POST /api/supplier/{id}/favorite
  Returns: bookmark/favorite status toggled

POST /api/supplier/{id}/message
  Body: { message, context }
  Returns: message sent to supplier (if available)
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Hero logo (shimmer)
- Rating card (shimmer)
- Tab bar (shimmer)
- Content area (5x shimmer rows)
```

#### Empty State
```
No products for this supplier (rare):
- Message: "This supplier hasn't listed products yet. Contact them to learn about their portfolio."
```

#### Error State
```
If API fails:
- Error message: "Could not load supplier profile. Check your connection."
- Retry button
- Offline fallback: show cached profile with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Hero section full-width
  - Rating card full-width
  - Tab bar horizontal scroll
  - Content single-column
  - Contact buttons stacked or grid (2x2)

Tablet (600px+): Side-by-side layout
  - Left: Hero + rating + key metrics
  - Right: Tab content (scrollable)
  - Contact buttons side-by-side (3 in row)
```

### Accessibility

- ✅ Heading hierarchy: H1 (Supplier name) → H2 (Tabs) → H3 (Reviews, Products)
- ✅ Touch targets: 44px minimum (tabs, buttons, review items)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All buttons have text (e.g., "Call", "Email", "Message")
- ✅ Star rating: Numeric text + visual (e.g., "4.8 out of 5 stars")
- ✅ Certifications: Expandable tooltips explain each cert
- ✅ Review sentiment: Indicated by color (5★ green, 1★ red)

### Future Enhancements

1. ⏳ Order history (if user has worked with this supplier, show past orders)
2. ⏳ Price tracking (alert if supplier's prices change)
3. ⏳ Comparison view (side-by-side with other suppliers)
4. ⏳ Certification verification (QR code to verify authenticity)
5. ⏳ Video verification (supplier's factory walkthrough)
6. ⏳ Supplier messaging (in-app chat, file sharing)
7. ⏳ Sample order builder (AI suggests MOQ + qty for sample order)

---

## Tiếng Việt — Màn Hình Chi Tiết Nhà Sản Xuất

### Mục Đích

**Chi Tiết Nhà Sản Xuất** hiển thị thông tin nhà cung cấp toàn diện. Nó hiển thị:
- Hồ sơ nhà cung cấp
- Xếp hạng và đánh giá
- Khả năng
- Danh mục sản phẩm
- Giá cả và điều khoản
- Thông tin liên hệ
- Mối quan hệ lịch sử

### Mục Tiêu Kinh Doanh

Giúp doanh nhân đánh giá và quản lý nhà cung cấp bằng cách:
1. Đánh giá danh tiếng và độ tin cậy của nhà cung cấp
2. Hiểu danh mục sản phẩm và khả năng
3. So sánh giá cả và điều khoản
4. Bắt đầu đàm phán với tự tin
5. Theo dõi hiệu suất nhà cung cấp

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 8 main components  
**API Calls:** 7 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-INVENTORY-DETAIL.md
