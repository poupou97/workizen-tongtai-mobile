# Screen Specification — Inventory Detail (Product Profile & Analytics)

## Chi Tiết Màn Hình — Chi Tiết Kho Hàng (Hồ Sơ Sản Phẩm & Phân Tích)

---

## English — Inventory Detail Screen

### Purpose

**Inventory Detail** shows comprehensive product information. It displays:
- Product profile (name, SKU, category, images)
- Revenue and profit metrics (30-day trending)
- Stock levels by warehouse and location
- Pricing (cost, retail, channel-specific)
- Variants and options (color, size)
- Sales channels (Shopee, TikTok, direct presence)
- Analytics (sales trend, customer reviews, profit breakdown)
- Supplier information (linked supplier)
- Related products (often bought together)

**User Journey:** See product row in Inventory module → tap → view product profile → check stock by warehouse → analyze profit by channel → adjust pricing.

### Business Goal

Help entrepreneurs manage products by:
1. Understanding product profitability in detail
2. Monitoring stock health across warehouses
3. Optimizing pricing per channel
4. Identifying top and bottom performers
5. Making informed decisions (expand, discontinue, optimize)

### Information Architecture

```
Inventory Detail Screen
├── Header
│   ├── Back button
│   ├── Title: "Product Detail"
│   ├── Share button
│   └── Edit / Manage menu
├── Product Hero Section
│   ├── Product image carousel (swipeable)
│   ├── Product name (large)
│   ├── SKU + Category badges
│   ├── Star rating (customer reviews)
│   └── Stock status badge (in stock / low stock / out of stock)
├── KPI Summary Cards
│   ├── Revenue (30 days): $4,560
│   ├── Profit (30 days): $3,200
│   ├── Orders (30 days): 280
│   └── Profit Margin: 70%
├── Tab Bar (Horizontal)
│   ├── Overview (active)
│   ├── Details
│   ├── Stock
│   ├── Pricing
│   ├── Channels
│   ├── Analytics
│   └── Settings
├── Main Content Area (varies by tab)
│   └── [Tab-specific content]
├── Overview Tab Content (if tab = Overview)
│   ├── Product description
│   ├── Key metrics grid
│   ├── Supplier info (linked supplier card)
│   ├── Stock by warehouse (summary)
│   ├── Pricing summary (cost, retail)
│   └── "Quick Actions" (reorder, adjust price, etc.)
└── Back Navigation
    └── Return to Inventory module
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg with shadow | Back + Title + Share + Menu |
| **Image Carousel** | Full-width, 300px height, swipeable | Product photos + dot indicators |
| **KPI Card** | 1 of 4 in grid, 100x100px | Metric value ($) + label + trend % |
| **Tab Bar** | Horizontal scroll, 50px height | 7 tabs with underline indicator |
| **Stock Row** | Full-width, 70px, tappable | Warehouse name + quantity + status indicator |
| **Pricing Row** | Full-width, 70px | Label (Cost / Retail / Channel) + price |
| **Analytics Chart** | Full-width, 250px | Sales trend line or profit breakdown pie |
| **Variant Card** | 1 of 3+ in scroll, 120x100px | Variant name (e.g., "Red - M") + stock + price |
| **Channel Badge** | 60x20px, rounded | Shopee / TikTok / Instagram / Direct |
| **Supplier Card** | Full-width, 80px, tappable | Supplier logo + name + rating + "View Profile" link |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Tab item | Content Switch | Switch to Details / Stock / Pricing / Channels / Analytics / Settings |
| Stock Row | Stock Detail | Show warehouse-specific stock, movements, reorder info |
| Warehouse | Warehouse Detail | Show warehouse location, capacity, other products stored there |
| Supplier Card | Supplier Detail (SC-15) | Navigate to supplier profile in Producer module |
| Variant Card | Variant Detail | Show variant-specific pricing, stock, analytics |
| Channel Badge | Channel Detail | Show channel-specific sales data, reviews, performance |
| "Edit" menu | Product Edit Modal | Edit product info (name, description, images, pricing) |
| "Reorder" button | Reorder Modal | Initiate reorder from linked supplier |
| Back button | Previous Screen | Return to Inventory module |

### Mock Data

```json
{
  "product": {
    "id": 1,
    "sku": "SKU-001-A",
    "name": "Quạt mini cấm tay (Xanh)",
    "category": "Electronics",
    "subcategory": "Gadgets",
    "description": "Portable handheld mini fan. USB rechargeable, 8-hour battery. Trending on TikTok, perfect for summer sales.",
    "images": [
      "https://...",
      "https://...",
      "https://..."
    ],
    "costPrice": "$2.10",
    "retailPrice": "$8.45",
    "rating": 4.7,
    "reviewCount": 89,
    "supplierId": 1,
    "supplierName": "TechPro Wholesale"
  },
  "kpis": {
    "revenue30days": "$4,560.00",
    "profit30days": "$3,200.00",
    "orders30days": 280,
    "profitMargin": 70
  },
  "stock": {
    "totalQuantity": 195,
    "byWarehouse": [
      { "warehouseId": 1, "warehouseName": "HCMC Main", "quantity": 45, "lastUpdated": "2 hours ago" },
      { "warehouseId": 2, "warehouseName": "Hanoi Distribution", "quantity": 120, "lastUpdated": "1 hour ago" },
      { "warehouseId": 3, "warehouseName": "Da Nang Satellite", "quantity": 30, "lastUpdated": "3 hours ago" }
    ],
    "reorderLevel": 50,
    "daysStockRemaining": 15,
    "lastRestockDate": "2026-07-01",
    "nextPlannedRestock": "2026-07-15"
  },
  "pricing": {
    "costPrice": "$2.10",
    "retailPrice": "$8.45",
    "byChannel": [
      { "channel": "Shopee", "price": "$7.99", "profit": "$5.89 (280%)", "commission": "15%" },
      { "channel": "TikTok Shop", "price": "$8.50", "profit": "$6.40 (305%)", "commission": "10%" },
      { "channel": "Instagram", "price": "$9.99", "profit": "$7.89 (376%)", "commission": "5%" },
      { "channel": "Direct/Email", "price": "$8.45", "profit": "$6.35 (303%)", "commission": "0%" }
    ]
  },
  "variants": [
    { "id": 1, "name": "Blue - Standard", "stock": 85, "price": "$8.45", "sku": "SKU-001-A-BLUE" },
    { "id": 2, "name": "Pink - Standard", "stock": 56, "price": "$8.45", "sku": "SKU-001-A-PINK" },
    { "id": 3, "name": "Green - Standard", "stock": 54, "price": "$8.45", "sku": "SKU-001-A-GREEN" }
  ],
  "channels": [
    { "platform": "Shopee", "isActive": true, "url": "https://shopee.vn/...", "followers": 12300, "reviews": 89, "averageRating": 4.7 },
    { "platform": "TikTok Shop", "isActive": true, "url": "https://vn-live.tiktokshop.com/...", "followers": 5600, "reviews": 42, "averageRating": 4.8 },
    { "platform": "Instagram", "isActive": true, "url": "https://instagram.com/...", "followers": 2100, "reviews": 15, "averageRating": 4.6 }
  ],
  "analytics": {
    "salesTrend": [
      { "date": "2026-06-13", "units": 12, "revenue": "$101.40" },
      { "date": "2026-06-14", "units": 14, "revenue": "$118.30" },
      { "date": "2026-06-15", "units": 18, "revenue": "$152.10" },
      { "date": "2026-06-16", "units": 12, "revenue": "$101.40" },
      { "date": "2026-06-17", "units": 25, "revenue": "$211.25" }
    ],
    "profitByChannel": {
      "Shopee": 45,
      "TikTok": 35,
      "Instagram": 15,
      "Direct": 5
    },
    "topReview": {
      "text": "Amazing product! Works great for summer. Highly recommend.",
      "rating": 5,
      "reviewer": "Phương N.",
      "date": "2026-07-10"
    }
  }
}
```

### Business Rules

1. **Pricing Calculated Per Channel** — Account for platform commissions (Shopee 15%, TikTok 10%, etc.)
2. **Stock Real-Time** — Updated every 30 minutes from warehouse management system
3. **Profit Margin Dynamic** — Recalculated if cost price changes (e.g., supplier price negotiated down)
4. **Variants Independently Tracked** — Each variant has own stock, pricing, SKU, performance metrics
5. **Channel Activity Audited** — Can enable/disable product on any channel independently
6. **Supplier Linked** — Products linked to one primary supplier for easy reordering
7. **Analytics Aggregated** — Sales, reviews, ratings aggregated across all active channels

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Pricing Optimization** — Recommend channel-specific pricing based on demand, competition, cost |
| **Inventory Forecasting** — Predict stock needs 30/60 days forward based on sales velocity |
| **Dead Stock Detection** — Flag if sales dropped 50%+ vs previous month; recommend discount |
| **Variant Performance** — Which variants sell best? Recommend focusing on top 3 |
| **Channel Strategy** — Recommend where to focus (e.g., "TikTok has highest margin, expand there") |
| **Related Products** — Suggest products often bought together (bundle opportunity) |

### Required APIs

```
GET /api/inventory/product/{id}
  Returns: full product profile (name, SKU, category, images, pricing, supplier)

GET /api/inventory/product/{id}/kpis
  Query: ?period=30days
  Returns: revenue, profit, orders, margin for selected period

GET /api/inventory/product/{id}/stock
  Returns: stock by warehouse with quantities, last updates, reorder info

GET /api/inventory/product/{id}/pricing
  Returns: cost, retail, by-channel pricing with commissions

GET /api/inventory/product/{id}/variants
  Returns: list of variants with stock, pricing, SKU, performance

GET /api/inventory/product/{id}/channels
  Returns: active channels with URLs, followers, reviews, ratings

GET /api/inventory/product/{id}/analytics
  Query: ?metric=sales&period=30days
  Returns: sales trend, profit breakdown, reviews, performance

PUT /api/inventory/product/{id}/pricing
  Body: { channelId, newPrice }
  Returns: pricing updated + margin recalculated

POST /api/inventory/product/{id}/reorder
  Body: { supplierId, quantity, notes }
  Returns: reorder initiated (initiates RFQ to supplier)
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Image carousel (shimmer)
- KPI cards (4x shimmer)
- Tab bar (shimmer)
- Content area (5x shimmer rows)
```

#### Empty State
```
No variants / No channels:
- Message: "This product has no variants yet. Add variants to expand product options."
- CTA: "Add Variant" or "Add Channel"
```

#### Error State
```
If API fails:
- Error message: "Could not load product. Check your connection."
- Retry button
- Offline fallback: show cached profile with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Image carousel full-width
  - KPI cards grid (2x2)
  - Tab bar horizontal scroll
  - Content single-column

Tablet (600px+): Side-by-side layout
  - Left: Images + basic info
  - Right: KPI summary + content tabs (scrollable)
```

### Accessibility

- ✅ Heading hierarchy: H1 (Product name) → H2 (Sections: Stock, Pricing, Analytics) → H3 (Items)
- ✅ Touch targets: 44px minimum (tabs, variant cards, channel items)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Image alt text: Descriptive alt text for all product images
- ✅ Charts: Include data table alternative for screen readers
- ✅ Stock status: Labeled clearly (e.g., "Low Stock" not just red)
- ✅ Pricing: Always include currency symbol and formatted clearly

### Future Enhancements

1. ⏳ Bulk editing (edit multiple products at once)
2. ⏳ Duplicate product (template for new variant)
3. ⏳ Customer feedback sentiment (AI analyze reviews for trends)
4. ⏳ A/B pricing (test price on one channel, compare to others)
5. ⏳ Recommended actions (AI suggest next steps: restock, adjust price, promote)
6. ⏳ Bundle builder (create product bundles, auto-calculate pricing)
7. ⏳ Content library (auto-generate product descriptions, SEO-optimized)

---

## Tiếng Việt — Màn Hình Chi Tiết Kho Hàng

### Mục Đích

**Chi Tiết Kho Hàng** hiển thị thông tin sản phẩm toàn diện. Nó hiển thị:
- Hồ sơ sản phẩm
- Chỉ số doanh thu và lợi nhuận
- Mức tồn kho theo kho
- Giá cả
- Biến thể
- Kênh bán hàng
- Phân tích

### Mục Tiêu Kinh Doanh

Giúp doanh nhân quản lý sản phẩm bằng cách:
1. Hiểu lợi nhuận sản phẩm chi tiết
2. Giám sát sức khỏe tồn kho
3. Tối ưu hóa giá theo kênh
4. Xác định các nhà hoạt động hàng đầu và hàng tồn kho chậm
5. Đưa ra quyết định sáng suốt

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 10 main components  
**API Calls:** 9 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-CONSUMER-DETAIL.md
