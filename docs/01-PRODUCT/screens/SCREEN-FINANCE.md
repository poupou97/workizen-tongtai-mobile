# Screen Specification — Finance (Revenue, Expenses, Profit & Cash Flow)

## Chi Tiết Màn Hình — Tài Chính (Doanh Thu, Chi Phí, Lợi Nhuận & Dòng Tiền)

---

## English — Finance Screen

### Purpose

**Finance** is the money management hub. It shows:
- Revenue, expenses, profit, and cash flow (30-day trends)
- Account balances (bank, e-wallet, crypto)
- Transaction history (searchable, filterable)
- Profit by channel (Shopee, TikTok, direct)
- Tax summary and financial reports
- Budget vs actual tracking

**User Journey:** Open Finance → see 30-day revenue/profit trend → filter by channel → search transactions → drill into transaction detail.

### Business Goal

Help entrepreneurs track money flow by:
1. Understanding daily/weekly/monthly revenue and profit trends
2. Tracking cash in multiple accounts (bank, Shopee wallet, TikTok, PayPal, crypto)
3. Categorizing expenses for tax planning
4. Analyzing profit by channel and product
5. Forecasting cash flow for inventory planning

### Information Architecture

```
Finance Screen
├── Header
│   ├── Title: "Finance - Revenue & Profit"
│   ├── Period selector (Today / Week / Month / Year)
│   └── Export button
├── KPI Summary Section
│   ├── Revenue (this period)
│   ├── Expenses (this period)
│   ├── Profit (this period)
│   ├── Profit Margin %
│   └── Trend indicators (vs previous period)
├── Trend Chart Section
│   ├── Revenue trend line (30 days)
│   ├── Expense trend line (30 days, overlay)
│   ├── Profit area chart (30 days)
│   └── Chart legend + date range picker
├── Tab Bar (Horizontal)
│   ├── Summary (active, this screen)
│   ├── Revenue
│   ├── Expenses
│   ├── Profit
│   ├── Cash Flow
│   └── Reports
├── Accounts Section
│   ├── Bank Account: $12,456.80
│   ├── Shopee Wallet: $3,456.20
│   ├── TikTok Pay: $1,234.50
│   ├── PayPal: $2,345.60
│   └── Total Cash: $19,492.10
├── Recent Transactions Section
│   ├── Transaction List (last 10)
│   ├── Date + Description + Amount + Category
│   └── "View All" link
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title + period selector dropdown + export button |
| **KPI Card** | 1 of 4 in grid, 80x100px | Value ($) + label + trend % + trend arrow |
| **Trend Chart** | Full-width, 250px height | Line chart (revenue, expense) + area (profit) |
| **Account Card** | 1 of 5 in scroll, 120x80px | Bank icon + name + balance + last updated |
| **Transaction Row** | Full-width, 70px, tappable | Date + description (category icon) + amount (green for income, red for expense) |
| **Category Badge** | 24x24px in row | Product Sales, Refund, Expense, Fee, etc. |
| **Period Selector** | Dropdown, 120x40px | Today / Week / Month / Year / Custom |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Transaction Row | Transaction Detail | Show full transaction info, receipt, category, notes, edit option |
| "View All" link | All Transactions List | Show complete transaction history, searchable + filterable |
| Account Card | Account Detail | Show account history, linked payment methods, last sync time |
| Chart (tap point) | Day Detail | Show transactions for that specific day |
| Period Selector | Period Picker | Select different time ranges (day/week/month/year/custom) |
| Export button | Export Modal | Export to CSV, PDF, or accounting software (Xero, FreshBooks) |

### Mock Data

```json
{
  "period": "month",
  "dateRange": { "start": "2026-06-13", "end": "2026-07-13" },
  "summary": {
    "revenue": "$24,560.00",
    "expenses": "$8,234.50",
    "profit": "$16,325.50",
    "profitMargin": "66.5%",
    "revenueVsPreviousMonth": "+18.6%",
    "expensesVsPreviousMonth": "+5.2%",
    "profitVsPreviousMonth": "+23.4%"
  },
  "trendChart": {
    "revenue": [
      { "date": "2026-06-13", "value": 680 },
      { "date": "2026-06-14", "value": 750 },
      { "date": "2026-06-15", "value": 920 },
      { "date": "2026-06-16", "value": 680 },
      { "date": "2026-06-17", "value": 1200 },
      { "date": "2026-06-18", "value": 850 },
      { "date": "2026-06-19", "value": 1050 }
    ],
    "expenses": [
      { "date": "2026-06-13", "value": 180 },
      { "date": "2026-06-14", "value": 200 },
      { "date": "2026-06-15", "value": 220 },
      { "date": "2026-06-16", "value": 180 },
      { "date": "2026-06-17", "value": 250 },
      { "date": "2026-06-18", "value": 190 },
      { "date": "2026-06-19", "value": 210 }
    ]
  },
  "accounts": [
    { "id": 1, "name": "Vietcombank", "type": "bank", "balance": "$12,456.80", "lastSync": "2 hours ago" },
    { "id": 2, "name": "Shopee Wallet", "type": "ecommerce", "balance": "$3,456.20", "lastSync": "30 min ago" },
    { "id": 3, "name": "TikTok Pay", "type": "ecommerce", "balance": "$1,234.50", "lastSync": "1 hour ago" },
    { "id": 4, "name": "PayPal", "type": "payment", "balance": "$2,345.60", "lastSync": "4 hours ago" }
  ],
  "recentTransactions": [
    { "id": 1, "date": "2026-07-13 14:30", "description": "Shopee Sales - Quạt mini (5 items)", "category": "Sales", "amount": "+$42.25", "accountName": "Shopee Wallet", "type": "income" },
    { "id": 2, "date": "2026-07-13 10:15", "description": "Supplier Payment - TechPro Wholesale", "category": "Expense", "amount": "-$234.50", "accountName": "Vietcombank", "type": "expense" },
    { "id": 3, "date": "2026-07-12 16:45", "description": "TikTok Shop Sales - Túi chống nước (3 items)", "category": "Sales", "amount": "+$28.80", "accountName": "TikTok Pay", "type": "income" },
    { "id": 4, "date": "2026-07-12 09:00", "description": "Platform Fee - Shopee Commission", "category": "Fee", "amount": "-$8.50", "accountName": "Shopee Wallet", "type": "expense" },
    { "id": 5, "date": "2026-07-11 11:20", "description": "Refund - Customer Return", "category": "Refund", "amount": "-$15.30", "accountName": "Shopee Wallet", "type": "expense" }
  ],
  "profitByChannel": [
    { "channel": "Shopee", "revenue": "$12,456.80", "expenses": "$3,456.20", "profit": "$9,000.60", "profitMargin": "72.3%" },
    { "channel": "TikTok Shop", "revenue": "$8,234.50", "expenses": "$2,234.50", "profit": "$6,000.00", "profitMargin": "72.9%" },
    { "channel": "Direct/Email", "revenue": "$3,868.70", "expenses": "$1,543.80", "profit": "$2,324.90", "profitMargin": "60.1%" }
  ]
}
```

### Business Rules

1. **Revenue = All Income** — Sum of all sales channels (Shopee, TikTok, direct) + affiliate commissions
2. **Expenses Categorized** — Product costs, platform fees, shipping, staff, marketing, other
3. **Profit = Revenue - Expenses** — Calculated net profit
4. **Profit Margin = Profit / Revenue** — Percentage metric
5. **Account Sync Daily** — Auto-fetch balances from connected banks/wallets; manual refresh available
6. **Transaction Categories Auto-Tagged** — AI suggests category; user can override
7. **Tax Summary** — Monthly tax liability calculated based on profit + tax rate (configurable per region)

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Expense Categorization** — Auto-tag transactions (product cost, fee, shipping, marketing, etc.) |
| **Profit Forecasting** — Project profit 30/60/90 days based on sales trends + seasonality |
| **Cash Flow Alert** — Flag if cash < 15 days of expenses; recommend reorder halt |
| **Tax Calculation** — Auto-estimate tax liability based on profit + region tax rate |
| **Anomaly Detection** — Flag unusual transactions or sudden revenue dips |
| **Channel Profitability** — Rank channels by profit margin; recommend resource allocation |

### Required APIs

```
GET /api/finance/summary
  Query: ?period=month&startDate=2026-06-13&endDate=2026-07-13
  Returns: revenue, expenses, profit, profitMargin, trends vs previous period

GET /api/finance/chart
  Query: ?metric=revenue&period=month&days=30
  Returns: daily trend data for chart (revenue, expenses, profit)

GET /api/finance/accounts
  Returns: list of connected accounts with balances, last sync time

GET /api/finance/transactions
  Query: ?limit=20&sort=date&category=sales
  Returns: transaction history with date, description, amount, category, account

GET /api/finance/transaction/{id}
  Returns: full transaction detail with receipt, metadata, edit history

GET /api/finance/profitByChannel
  Query: ?period=month
  Returns: profit breakdown by sales channel (Shopee, TikTok, direct, etc.)

GET /api/finance/taxSummary
  Query: ?period=month&region=vietnam
  Returns: tax liability estimate, breakdown by category, recommended actions

GET /api/finance/export
  Query: ?format=csv&period=month
  Returns: download link for exported transactions
```

### States

#### Loading State
```
Show skeleton/placeholder:
- KPI cards (4x shimmer)
- Chart (shimmer)
- Account cards (4x shimmer)
- Transaction rows (5x shimmer)
```

#### Empty State
```
No transactions:
- Icon: wallet icon
- Message: "No transactions yet. Start by connecting your bank account or adding sales."
- CTA: "Connect Bank Account" or "Add Manual Transaction"
```

#### Error State
```
If API fails:
- Error message: "Could not load financial data. Check your connection."
- Retry button
- Offline fallback: show cached summary + last-known transactions with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - KPI cards stacked (4 cards)
  - Chart full-width, scrollable
  - Account cards horizontal scroll
  - Transaction rows single-column

Tablet (600px+): Side-by-side layout
  - Left: KPI summary + chart
  - Right: Accounts + recent transactions
  - Both full-height, scrollable sections
```

### Accessibility

- ✅ Heading hierarchy: H1 (Finance) → H2 (KPIs) → H3 (Individual metrics)
- ✅ Touch targets: 44px minimum (rows, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All transaction types have text (e.g., "Income" not just green)
- ✅ Chart: Include data table alternative for screen readers
- ✅ Currency: Always displayed with symbol and localized format

### Future Enhancements

1. ⏳ Budget tracking (set monthly budget, track vs actual)
2. ⏳ Recurring transaction templates (auto-categorize repeat expenses)
3. ⏳ Tax optimization (AI suggest deductions, estimated quarterly taxes)
4. ⏳ Invoice management (issue invoices, track payment status)
5. ⏳ Payroll integration (track employee payments, tax withholding)
6. ⏳ Accounting software sync (sync with Xero, FreshBooks, QuickBooks)
7. ⏳ Financial forecasting (project cash flow 6-12 months ahead)

---

## Tiếng Việt — Màn Hình Tài Chính

### Mục Đích

**Tài Chính** là trung tâm quản lý tiền. Nó hiển thị:
- Doanh thu, chi phí, lợi nhuận và dòng tiền (xu hướng 30 ngày)
- Số dư tài khoản (ngân hàng, ví điện tử, tiền điện tử)
- Lịch sử giao dịch (có thể tìm kiếm, lọc)
- Lợi nhuận theo kênh
- Tóm tắt thuế và báo cáo tài chính
- Theo dõi ngân sách so với thực tế

### Mục Tiêu Kinh Doanh

Giúp doanh nhân theo dõi dòng tiền bằng cách:
1. Hiểu xu hướng doanh thu và lợi nhuận hàng ngày/tuần/tháng
2. Theo dõi tiền mặt trên nhiều tài khoản
3. Phân loại chi phí để lập kế hoạch thuế
4. Phân tích lợi nhuận theo kênh
5. Dự báo dòng tiền để lập kế hoạch hàng tồn kho

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 8 main components  
**API Calls:** 8 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-REPORTS.md
