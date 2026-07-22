# Screen Specification — Inventory (Product & Warehouse Management)

## Chi Tiết Màn Hình — Kho Hàng (Quản Lý Sản Phẩm & Kho)

---

## English — Inventory Screen

### Purpose

**Inventory** is the product catalog and warehouse hub. It shows:
- Complete product catalog (1,256 SKUs)
- Real-time stock levels by warehouse
- Pricing matrix (cost, retail, channel pricing)
- Stock alerts (low stock, expiry, dead stock)
- Import/export activity and trends

**User Journey:** Open Inventory → see product summary → filter by warehouse/category → view product card → drill into detail → check stock movement.

### Business Goal

Help entrepreneurs manage product portfolio by:
1. Tracking 1,000+ SKUs across multiple warehouses
2. Monitoring stock health and alerts (low stock, overstock, dead stock)
3. Analyzing product profitability (revenue, margin, inventory turnover)
4. Managing pricing across channels (Shopee, TikTok, own site)
5. Forecasting inventory needs based on sales trends

### Information Architecture

```
Inventory Screen
├── Header
│   ├── Title: "Inventory - Product & Warehouse"
│   ├── Filter button (by warehouse, category, status)
│   └── Search bar
├── Summary Section
│   ├── Total Products: 1,256 SKUs
│   ├── Total Value: $156,800
│   ├── SKU Count (distinct products)
│   ├── Warehouses: 3 active
│   └── Pie chart (% by category)
├── Tab Bar (Horizontal)
│   ├── Products (active)
│   ├── Categories
│   ├── SKU
│   ├── Warehouse
│   ├── Stock In/Out
│   ├── Pricing
│   └── Documents
├── Main Content Area (varies by tab)
│   └── [Tab-specific content]
├── Alert Section (if tab = Products)
│   ├── Low Stock (5 products)
│   ├── Overstock (2 products)
│   ├── Dead Stock (1 product)
│   └── "View All Alerts" link
├── Product List (if tab = Products)
│   ├── Product Row 1: SKU + Name + Stock + Value + Trend
│   ├── Product Row 2: ...
│   └── Pagination
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg with shadow | Title + filter icon + search bar |
| **Summary Card** | Full-width, 120px, grid layout | 4 stat boxes (products, value, SKUs, warehouses) + pie chart |
| **Tab Bar** | Horizontal scroll, 50px height | 7 tabs with underline indicator |
| **Alert Card** | Full-width, 60px, colored badge | "Low Stock: 5 products" (red), "Overstock: 2 products" (orange) |
| **Product Row** | Full-width, 80px, tappable | SKU + Name + Stock level (with color: green/yellow/red) + Value ($) + Trend arrow |
| **Stock Indicator** | Visual badge in row | Green (10+ days stock), Yellow (3-10 days), Red (< 3 days) |
| **Pie Chart** | 150x150px, centered | Category breakdown (e.g., Electronics 35%, Textiles 28%, etc.) |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Product Row | Product Detail (SC-16) | Show full product profile, variants, pricing, sales channels |
| Category Tab item | Category Detail | Show products in category, category-level stats, bulk actions |
| Warehouse Tab item | Warehouse Detail | Show warehouse location, stock by product, capacity |
| Alert Card | Filtered List | Show all low-stock products with reorder actions |
| "Stock In/Out" tab | Movement History | Show recent stock movements (receipts, sales, transfers) |
| Search results | Product Detail | Tap product from search |

### Mock Data

```json
{
  "summary": {
    "totalProducts": 1256,
    "totalValue": "$156,800",
    "distinctSKUs": 342,
    "activeWarehouses": 3,
    "categoryBreakdown": {
      "Electronics": 35,
      "Textiles": 28,
      "Home Goods": 22,
      "Accessories": 15
    }
  },
  "alerts": {
    "lowStock": [
      { "sku": "SKU-001", "name": "Quạt mini", "currentStock": 5, "reorderLevel": 50 },
      { "sku": "SKU-002", "name": "Túi chống nước", "currentStock": 12, "reorderLevel": 100 }
    ],
    "overstock": [
      { "sku": "SKU-345", "name": "Máy pha cà phê", "currentStock": 500, "salesTrend": "-15%" }
    ],
    "deadStock": [
      { "sku": "SKU-789", "name": "Old Model Phone Case", "lastSale": "60+ days ago" }
    ]
  },
  "products": [
    {
      "id": 1,
      "sku": "SKU-001-A",
      "name": "Quạt mini cấm tay (Xanh)",
      "category": "Electronics",
      "costPrice": "$2.10",
      "retailPrice": "$8.45",
      "warehouseA": 45,
      "warehouseB": 120,
      "warehouseC": 30,
      "totalStock": 195,
      "daysStockRemaining": 15,
      "stockIndicator": "green",
      "value": "$1,649.75",
      "trend": "+18%",
      "lastUpdate": "2 hours ago"
    },
    {
      "id": 2,
      "sku": "SKU-002-B",
      "name": "Túi chống nước du lịch",
      "category": "Accessories",
      "costPrice": "$3.20",
      "retailPrice": "$9.60",
      "warehouseA": 8,
      "warehouseB": 45,
      "warehouseC": 0,
      "totalStock": 53,
      "daysStockRemaining": 4,
      "stockIndicator": "yellow",
      "value": "$509.60",
      "trend": "stable",
      "lastUpdate": "1 hour ago"
    },
    {
      "id": 3,
      "sku": "SKU-345-C",
      "name": "Máy pha cà phê mini",
      "category": "Electronics",
      "costPrice": "$4.50",
      "retailPrice": "$14.50",
      "warehouseA": 120,
      "warehouseB": 200,
      "warehouseC": 180,
      "totalStock": 500,
      "daysStockRemaining": 45,
      "stockIndicator": "red",
      "value": "$7,250.00",
      "trend": "-15%",
      "lastUpdate": "3 hours ago"
    }
  ],
  "categories": [
    { "id": 1, "name": "Electronics", "productCount": 440, "totalValue": "$54,880", "trend": "+12%" },
    { "id": 2, "name": "Textiles", "productCount": 352, "totalValue": "$43,904", "trend": "+8%" },
    { "id": 3, "name": "Home Goods", "productCount": 276, "totalValue": "$34,752", "trend": "+3%" },
    { "id": 4, "name": "Accessories", "productCount": 188, "totalValue": "$23,264", "trend": "+22%" }
  ],
  "warehouses": [
    { "id": 1, "name": "HCMC Main Warehouse", "location": "District 1, HCMC", "capacity": 10000, "currentStock": 2450, "utilization": "24.5%" },
    { "id": 2, "name": "Hanoi Distribution", "location": "Thanh Xuan, Hanoi", "capacity": 5000, "currentStock": 1856, "utilization": "37.1%" },
    { "id": 3, "name": "Da Nang Satellite", "location": "Hai Chau, Da Nang", "capacity": 3000, "currentStock": 694, "utilization": "23.1%" }
  ]
}
```

### Business Rules

1. **Stock Levels Real-Time** — Updated every 30 minutes from warehouse management system
2. **Alert Thresholds Automatic** — Low stock threshold set per product based on sales velocity
3. **Daysstock Calculation** — Based on 30-day average sales (velocity data from Finance module)
4. **Dead Stock Definition** — No sales for 60+ days; recommend clearance or discontinuation
5. **Overstock Flag** — Stock > 45 days of sales; potential cash flow risk
6. **Value Calculation** — Wholesale cost × quantity per warehouse
7. **Category Hierarchy** — Locked set; new categories require founder approval

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Predictive Reorder** | Analyze sales velocity; suggest reorder quantity and timing to minimize stockouts |
| **Dead Stock Detection** | Flag items with zero sales 60+ days; recommend discount or discontinuation |
| **Supplier Matching** | Link low-stock products to preferred suppliers; auto-generate RFQ |
| **Pricing Optimization** | Suggest channel-specific pricing based on demand, competitor data |
| **Inventory Forecasting** | Project stock needs 30/60/90 days forward based on sales trends |
| **Demand Forecasting** | Predict seasonal spikes; recommend pre-stocking |

### Required APIs

```
GET /api/inventory/summary
  Returns: totalProducts, totalValue, distinctSKUs, activeWarehouses, categoryBreakdown

GET /api/inventory/products
  Query: ?warehouse=1&category=electronics&status=low-stock&limit=50
  Returns: product list with stock levels, prices, trends, alerts

GET /api/inventory/alerts
  Returns: lowStock[], overstock[], deadStock[] arrays

GET /api/inventory/categories
  Returns: list of categories with product counts, values, trends

GET /api/inventory/warehouses
  Returns: warehouse list with capacity, current stock, utilization

GET /api/inventory/product/{id}
  Returns: full product detail (SC-16)

GET /api/inventory/stockmovement
  Query: ?productId=1&limit=20
  Returns: recent stock in/out movements (receipts, sales, transfers)

GET /api/inventory/pricing/{productId}
  Returns: cost price, retail price, channel-specific pricing (Shopee/TikTok/etc)
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Summary card (shimmer)
- Alert cards (3x shimmer)
- Tab bar (shimmer)
- Product rows (5x shimmer)
- Pie chart (shimmer)
```

#### Empty State
```
No products in this warehouse:
- Icon: package icon
- Message: "No products in selected warehouse. Try a different filter."
- CTA: "Add Products" or "Change Warehouse"
```

#### Error State
```
If API fails:
- Error message: "Could not load inventory. Check your connection."
- Retry button
- Offline fallback: show cached summary + last-known product list with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Summary card stacked (4 stat boxes)
  - Pie chart full-width
  - Tab bar horizontal scroll
  - Product rows single-column
  - Alert section full-width

Tablet (600px+): Side-by-side layout
  - Left: Summary + alerts
  - Right: Product list (2-column)
  - Pie chart on summary card
```

### Accessibility

- ✅ Heading hierarchy: H1 (Inventory) → H2 (Alerts) → H3 (Individual alerts)
- ✅ Touch targets: 44px minimum (rows, tabs, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text); color indicators have text labels
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All status indicators have text (e.g., "Low Stock" not just red)
- ✅ Pie chart: Include data table alternative for screen readers

### Future Enhancements

1. ⏳ Barcode scanning (mobile camera to look up product)
2. ⏳ Bulk import from spreadsheet (CSV, Excel)
3. ⏳ Batch stock adjustment (receive, adjust, transfer multiple items)
4. ⏳ Supplier-linked reordering (auto-send RFQ for low-stock items)
5. ⏳ Inventory forecasting (AI predict stock needs 30/60/90 days)
6. ⏳ Cost price versioning (track historical costs per supplier)
7. ⏳ Lot tracking (expiry dates, batch numbers for perishables)

---

## Tiếng Việt — Màn Hình Kho Hàng

### Mục Đích

**Kho Hàng** là trung tâm danh mục sản phẩm và kho. Nó hiển thị:
- Danh mục sản phẩm hoàn chỉnh (1,256 SKU)
- Mức tồn kho thực tế theo kho
- Ma trận giá (giá vốn, giá bán, giá theo kênh)
- Cảnh báo tồn kho (tồn kho thấp, hạn dùng, hàng chết)
- Hoạt động nhập/xuất và xu hướng

### Mục Tiêu Kinh Doanh

Giúp doanh nhân quản lý danh mục sản phẩm bằng cách:
1. Theo dõi 1.000+ SKU trên nhiều kho
2. Giám sát sức khỏe tồn kho và cảnh báo
3. Phân tích lợi nhuận sản phẩm
4. Quản lý giá theo kênh bán
5. Dự báo nhu cầu tồn kho

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 8 main components  
**API Calls:** 8 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-CONSUMER.md
