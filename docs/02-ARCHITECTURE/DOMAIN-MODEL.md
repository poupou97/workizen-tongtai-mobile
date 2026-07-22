# Domain Data Model
## Mô Hình Dữ Liệu Miền

---

## English — Domain Data Model

### Introduction: Data Model Philosophy

Tổng Tài is a **local-first, BYOK (Bring Your Own Key) application**:

1. **Primary data lives on-device** (SQLite + Drift in Flutter)
2. **User controls sync** to cloud (optional, user consent)
3. **User's API keys stay private** (BYOK: never sent to Workizen backend, only in Authorization headers to provider)
4. **Cloud is optional** for backups and multi-device sync
5. **Privacy by default** — no tracking SDKs, no telemetry

### Entity Relationship Overview

```
┌────────────────────────────────────────────────────────┐
│         Business (Root Entity - per user)              │
└────────────────────────────────────────────────────────┘
    │
    ├─ User (owner profile, auth, preferences)
    ├─ Producer (suppliers, sourcing partners)
    ├─ Product (inventory, catalog, SKU)
    ├─ Customer (CRM, segmentation, LTV)
    ├─ Order (sales transactions, order history)
    ├─ Channel (Shopee, TikTok, Amazon, Direct)
    ├─ Opportunity (AI-discovered opportunities)
    ├─ Journey (business goals, milestones)
    ├─ JourneyStep (individual steps in journey)
    ├─ Transaction (revenue, expenses, cash flow)
    ├─ Document (contracts, certificates, receipts, OCR)
    ├─ Alert (notifications, AI recommendations)
    ├─ AIChat (conversation history with copilot)
    ├─ Integration (external API credentials, OAuth)
    └─ SyncMetadata (cloud sync tracking, conflict resolution)
```

---

## Core Entities & Attributes

### 1. User Entity

**Purpose:** Business owner profile and authentication.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Unique identifier |
| `email` | String | No | UNIQUE | Login email |
| `business_id` | UUID | No | FK → Business | Owner of business |
| `name` | String | No | — | Display name |
| `language` | String | Yes | Enum: 'en', 'vi' | Preferred language |
| `timezone` | String | Yes | IANA TZ | Default: 'Asia/Ho_Chi_Minh' |
| `preferences` | JSON | Yes | — | Theme, notifications, currency |
| `created_at` | DateTime | No | Default: now | Registration date |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- 1:1 → Business (owner)
- 1:N → AIChat (conversations)
- 1:N → Integration (API credentials)

**Validation:**
- Email: valid email format, UNIQUE
- Language: 'en' or 'vi'
- Timezone: valid IANA timezone

**Example:**
```json
{
  "id": "usr_123abc",
  "email": "owner@business.com",
  "business_id": "biz_456def",
  "name": "Nguyen Van A",
  "language": "vi",
  "timezone": "Asia/Ho_Chi_Minh",
  "preferences": {"theme": "dark", "currency": "VND"}
}
```

---

### 2. Business Entity

**Purpose:** Business master record. Root of all data hierarchy.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Business ID |
| `owner_id` | UUID | No | FK → User | Business owner |
| `name` | String | No | — | Business name |
| `industry` | String | Yes | Enum | 'retail', 'ecommerce', 'manufacturing', 'service' |
| `country` | String | Yes | Country code | e.g., 'VN', 'US' |
| `currency` | String | Yes | ISO 4217 | Default: 'VND' |
| `annual_revenue` | BigDecimal | Yes | — | For recommendations |
| `employee_count` | Integer | Yes | Enum | '1', '2-5', '5-10', '10+' |
| `stage` | String | Yes | Enum | 'startup', 'growth', 'established' |
| `created_at` | DateTime | No | Default: now | Registration |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- 1:N → Product, Customer, Order, Channel, Producer, Journey, Transaction, Document

**Validation:**
- Name required and non-empty
- Currency: valid ISO 4217 code
- Industry, stage: from predefined lists

---

### 3. Producer Entity (Supplier)

**Purpose:** Supplier/sourcing partner records.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Supplier ID |
| `business_id` | UUID | No | FK → Business | Business managing supplier |
| `name` | String | No | — | Supplier name |
| `category` | String | Yes | Enum | e.g., 'coffee', 'textile', 'electronics' |
| `country` | String | Yes | Country code | Supplier location |
| `rating` | Float | Yes | 0-5 | User's rating |
| `reliability_score` | Float | Yes | 0-100 | AI-calculated score |
| `min_order_qty` | BigDecimal | Yes | — | Minimum order quantity |
| `lead_time_days` | Integer | Yes | — | Days from order to delivery |
| `certifications` | JSON | Yes | Array | e.g., ['ISO9001', 'Fair Trade'] |
| `contact_email` | String | Yes | — | Contact email |
| `contact_phone` | String | Yes | — | Contact phone |
| `external_id` | String | Yes | — | ID from external system (1688, Alibaba) |
| `external_source` | String | Yes | Enum | 'manual', '1688', 'alibaba', 'other' |
| `created_at` | DateTime | No | Default: now | Record created |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- M:N → Product (supplies)

**Validation:**
- Name required
- Rating: 0-5 if provided
- Reliability score: 0-100

---

### 4. Product Entity

**Purpose:** Product catalog and inventory management.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Product ID |
| `business_id` | UUID | No | FK → Business | Owner business |
| `sku` | String | No | UNIQUE per biz | Stock Keeping Unit |
| `name` | String | No | — | Product name |
| `category` | String | Yes | — | Product category |
| `cost_per_unit` | BigDecimal | Yes | — | COGS per unit |
| `list_price` | BigDecimal | No | >0 | Default selling price |
| `current_price` | BigDecimal | Yes | >0 | Currently active price |
| `profit_per_unit` | BigDecimal | Yes | — | Calculated: price - cost |
| `total_stock` | BigDecimal | No | >=0 | Total across all warehouses |
| `stock_by_warehouse` | JSON | Yes | — | {"wh_1": 100, "wh_2": 50} |
| `stock_alert_level` | BigDecimal | Yes | — | Trigger alert when below |
| `supplier_id` | UUID | Yes | FK → Producer | Primary supplier |
| `sales_channels` | JSON | Yes | — | {"shopee": "id", "tiktok": "id"} |
| `is_active` | Boolean | Yes | Default: true | For sale? |
| `created_at` | DateTime | No | Default: now | Product added |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- N:1 → Producer (primary supplier)
- 1:N → Order (line items)

**Validation:**
- SKU: UNIQUE per business
- List price: > 0
- Stock: >= 0
- Profit: calculated as price - cost

---

### 5. Customer Entity

**Purpose:** CRM records and customer segmentation.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Customer ID |
| `business_id` | UUID | No | FK → Business | Business managing |
| `external_id` | String | Yes | — | ID from sales channel |
| `external_source` | String | Yes | Enum | 'shopee', 'tiktok', 'manual', 'facebook' |
| `name` | String | No | — | Customer name |
| `email` | String | Yes | — | Email address |
| `phone` | String | Yes | — | Phone number |
| `address` | String | Yes | — | Address |
| `city` | String | Yes | — | City |
| `country` | String | Yes | Country code | Location |
| `segments` | JSON | Yes | Array | Segment IDs customer belongs to |
| `lifetime_value` | BigDecimal | Yes | >=0 | Total revenue from customer |
| `order_count` | Integer | Yes | >=0 | Number of orders |
| `total_spent` | BigDecimal | Yes | >=0 | Sum of order amounts |
| `avg_order_value` | BigDecimal | Yes | — | Calculated: total_spent / order_count |
| `last_order_date` | DateTime | Yes | — | Date of last order |
| `churn_risk` | Float | Yes | 0-100 | AI-predicted churn risk % |
| `created_at` | DateTime | No | Default: now | Customer added |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- 1:N → Order (customer's orders)

**Validation:**
- Name required
- Email/phone: valid if provided
- Churn risk: 0-100
- LTV: >= 0

---

### 6. Order Entity

**Purpose:** Sales transaction tracking.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Order ID |
| `business_id` | UUID | No | FK → Business | Business |
| `customer_id` | UUID | No | FK → Customer | Who ordered |
| `channel_id` | UUID | Yes | FK → Channel | Sales channel |
| `order_number` | String | Yes | — | External order number |
| `order_date` | DateTime | No | — | When ordered |
| `total_quantity` | Integer | No | >0 | Total items |
| `subtotal` | BigDecimal | No | >=0 | Sum before discount |
| `discount` | BigDecimal | Yes | Default: 0 | Discount amount |
| `shipping_cost` | BigDecimal | Yes | — | Shipping fee |
| `total_amount` | BigDecimal | No | >=0 | Final amount |
| `status` | String | No | Enum | 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled' |
| `payment_status` | String | Yes | Enum | 'pending', 'paid', 'failed' |
| `items` | JSON | No | Array | [{product_id, quantity, unit_price}] |
| `external_id` | String | Yes | — | ID from channel |
| `created_at` | DateTime | No | Default: now | Order created |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- N:1 → Customer
- N:1 → Channel
- M:N → Product (via items)

**Validation:**
- Total amount: subtotal - discount + shipping
- Order date: not future
- Items: non-empty array
- Status: from predefined list

---

### 7. Channel Entity

**Purpose:** Sales channel integration (Shopee, TikTok, Amazon, Direct).

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Channel ID |
| `business_id` | UUID | No | FK → Business | Business managing |
| `name` | String | No | — | Channel name |
| `type` | String | No | Enum | 'shopee', 'tiktok', 'amazon', 'facebook', 'direct', 'other' |
| `platform_id` | String | Yes | — | Platform store/shop ID |
| `status` | String | Yes | Enum | 'active', 'inactive', 'disconnected' |
| `is_connected` | Boolean | Yes | Default: false | API active? |
| `credentials_encrypted` | String | Yes | Encrypted | API keys/tokens (encrypted) |
| `metrics` | JSON | Yes | — | Monthly revenue, order count |
| `last_sync_date` | DateTime | Yes | — | Last data sync |
| `created_at` | DateTime | No | Default: now | Channel added |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- 1:N → Order (orders from channel)

**Validation:**
- Credentials: always encrypted
- Type: from predefined list
- Last sync: not future date

---

### 8. Opportunity Entity

**Purpose:** AI-discovered business opportunities.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Opportunity ID |
| `business_id` | UUID | No | FK → Business | Business |
| `type` | String | No | Enum | 'arbitrage', 'trend', 'market_gap', 'cross_border' |
| `title` | String | No | — | Opportunity title |
| `description` | String | Yes | — | Detailed description |
| `market` | String | Yes | — | Target market (e.g., 'USA') |
| `estimated_roi` | Float | Yes | — | Estimated ROI % |
| `estimated_investment` | BigDecimal | Yes | — | Estimated investment needed |
| `risk_score` | Float | Yes | 0-100 | Risk level |
| `feasibility_score` | Float | Yes | 0-100 | Feasibility level |
| `ai_score` | Float | Yes | 0-100 | Overall AI score |
| `status` | String | Yes | Enum | 'new', 'viewed', 'interested', 'pursuing', 'completed' |
| `related_products` | JSON | Yes | Array | Related product IDs |
| `related_suppliers` | JSON | Yes | Array | Related supplier IDs |
| `discovered_at` | DateTime | No | Default: now | When discovered |
| `expires_at` | DateTime | Yes | — | Relevance expiry date |
| `created_at` | DateTime | No | Default: now | Record created |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business

**Validation:**
- Title required
- Type: from predefined list
- Scores: 0-100 if provided
- Status: from predefined list

---

### 9. Journey Entity

**Purpose:** Business goal tracking and orchestration.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Journey ID |
| `business_id` | UUID | No | FK → Business | Business |
| `goal` | String | No | — | Goal statement |
| `status` | String | No | Enum | 'draft', 'active', 'paused', 'completed', 'archived' |
| `progress_percent` | Integer | Yes | 0-100 | Progress % |
| `total_steps` | Integer | Yes | — | Total steps planned |
| `completed_steps` | Integer | Yes | Default: 0 | Steps completed |
| `budget` | BigDecimal | Yes | — | Estimated budget |
| `spent` | BigDecimal | Yes | Default: 0 | Amount spent |
| `timeline_days` | Integer | Yes | — | Estimated days to completion |
| `revenue_impact` | BigDecimal | Yes | — | Expected revenue |
| `created_at` | DateTime | No | Default: now | Journey created |
| `started_at` | DateTime | Yes | — | When activated |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- 1:N → JourneyStep

**Validation:**
- Goal required
- Status: from predefined list
- Progress: 0-100
- Progress: (completed_steps / total_steps) * 100

---

### 10. JourneyStep Entity

**Purpose:** Individual steps within a journey.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Step ID |
| `journey_id` | UUID | No | FK → Journey | Parent journey |
| `step_number` | Integer | No | >0 | Order (1, 2, 3...) |
| `title` | String | No | — | Step title |
| `status` | String | No | Enum | 'pending', 'in_progress', 'completed', 'blocked' |
| `milestone` | Boolean | Yes | Default: false | Major milestone? |
| `start_date` | DateTime | Yes | — | When started |
| `end_date` | DateTime | Yes | — | When completed |
| `forecast_days` | Integer | Yes | — | Estimated days |
| `depends_on` | JSON | Yes | Array | Step IDs this depends on |
| `guidance` | String | Yes | — | AI guidance |
| `created_at` | DateTime | No | Default: now | Step created |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Journey

**Validation:**
- Title required
- Step number: positive
- Status: from predefined list
- End date >= start date

---

### 11. Transaction Entity

**Purpose:** Financial transaction tracking (revenue, expenses).

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Transaction ID |
| `business_id` | UUID | No | FK → Business | Business |
| `type` | String | No | Enum | 'revenue', 'expense', 'transfer' |
| `category` | String | Yes | — | Category (COGS, Marketing, etc.) |
| `amount` | BigDecimal | No | >0 | Transaction amount |
| `currency` | String | Yes | ISO 4217 | Currency (default: business currency) |
| `date` | DateTime | No | — | Transaction date |
| `account` | String | Yes | — | Account (cash, bank, credit card) |
| `order_id` | UUID | Yes | FK → Order | If from order |
| `description` | String | Yes | — | Description |
| `payment_method` | String | Yes | Enum | 'cash', 'bank_transfer', 'credit_card', 'e_wallet' |
| `is_reconciled` | Boolean | Yes | Default: false | Reconciled? |
| `created_at` | DateTime | No | Default: now | When recorded |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- N:1 → Order (if applicable)

**Validation:**
- Amount: > 0
- Type: from predefined list
- Date: not future
- Category: from predefined list

---

### 12. Document Entity

**Purpose:** Document storage (contracts, certificates, receipts, OCR).

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Document ID |
| `business_id` | UUID | No | FK → Business | Business |
| `type` | String | No | Enum | 'contract', 'certificate', 'receipt', 'invoice', 'other' |
| `name` | String | No | — | Document name |
| `file_name` | String | Yes | — | Original file name |
| `file_type` | String | Yes | — | MIME type (pdf, image, etc.) |
| `file_size` | Long | Yes | — | Size in bytes |
| `local_path` | String | Yes | — | Local storage path |
| `extracted_text` | String | Yes | — | OCR-extracted text |
| `extracted_data` | JSON | Yes | — | Structured data (invoice #, date, etc.) |
| `related_entity_type` | String | Yes | Enum | 'product', 'supplier', 'customer', 'order' |
| `related_entity_id` | UUID | Yes | — | ID of related entity |
| `is_synced` | Boolean | Yes | Default: false | Backed up to cloud? |
| `created_at` | DateTime | No | Default: now | Document uploaded |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business
- References: Product, Producer, Customer, Order (flexible)

**Validation:**
- Name required
- Type: from predefined list
- File size: reasonable (< 100MB)
- File type: allowed (PDF, images, docs)

---

### 13. Alert Entity

**Purpose:** Notifications and AI recommendations.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Alert ID |
| `business_id` | UUID | No | FK → Business | Business |
| `type` | String | No | Enum | 'low_stock', 'churn_risk', 'opportunity', 'milestone', 'anomaly' |
| `severity` | String | No | Enum | 'info', 'warning', 'critical' |
| `title` | String | No | — | Alert title |
| `description` | String | Yes | — | Description |
| `ai_recommendation` | String | Yes | — | Suggested action |
| `status` | String | Yes | Enum | 'new', 'viewed', 'acted', 'dismissed' |
| `created_at` | DateTime | No | Default: now | Alert created |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business

**Validation:**
- Title required
- Type, severity: from predefined lists

---

### 14. AIChat Entity

**Purpose:** Conversation history with AI Copilot.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Chat ID |
| `business_id` | UUID | No | FK → Business | Business |
| `user_id` | UUID | No | FK → User | User |
| `messages` | JSON | No | Array | [{role, content, timestamp}] |
| `context` | JSON | Yes | — | Context (entity_type, entity_id) |
| `summary` | String | Yes | — | AI summary of conversation |
| `tokens_used` | Integer | Yes | — | For cost tracking |
| `created_at` | DateTime | No | Default: now | Chat started |
| `updated_at` | DateTime | No | Default: now | Last message |

**Relationships:**
- N:1 → Business
- N:1 → User

---

### 15. Integration Entity

**Purpose:** External provider integrations and encrypted credentials.

| Attribute | Type | Nullable | Constraints | Notes |
|-----------|------|----------|-------------|-------|
| `id` | UUID | No | PK | Integration ID |
| `business_id` | UUID | No | FK → Business | Business |
| `provider` | String | No | Enum | 'shopee', 'tiktok', '1688', 'xai', 'openrouter', 'google', 'facebook' |
| `status` | String | Yes | Enum | 'connected', 'disconnected', 'error' |
| `api_key_encrypted` | String | Yes | Encrypted | API key (BYOK) |
| `api_secret_encrypted` | String | Yes | Encrypted | API secret |
| `access_token_encrypted` | String | Yes | Encrypted | OAuth token |
| `refresh_token_encrypted` | String | Yes | Encrypted | OAuth refresh token |
| `config` | JSON | Yes | — | Provider-specific config |
| `last_sync_at` | DateTime | Yes | — | Last successful sync |
| `created_at` | DateTime | No | Default: now | Integration created |
| `updated_at` | DateTime | No | Default: now | Last update |

**Relationships:**
- N:1 → Business

**Validation:**
- Provider: from predefined list
- Credentials: MUST be encrypted before storage
- At least one credential field required

---

## Data Constraints & Business Rules

### Cardinality Summary

| Relationship | Cardinality | Notes |
|---|---|---|
| User ↔ Business | 1:1 | One user owns one business (MVP) |
| Business ↔ Product | 1:N | Business has many products |
| Business ↔ Customer | 1:N | Business has many customers |
| Business ↔ Order | 1:N | Business has many orders |
| Business ↔ Producer | 1:N | Business has many suppliers |
| Business ↔ Journey | 1:N | Business has many goals |
| Customer ↔ Order | 1:N | Customer places many orders |
| Producer ↔ Product | M:N | Suppliers supply multiple products |
| Order ↔ Product | M:N | Order contains multiple products |
| Channel ↔ Order | 1:N | Channel has many orders |

### Critical Data Constraints

1. **Inventory Consistency**
   - `total_stock = SUM(stock_by_warehouse[*])`

2. **Financial Accuracy**
   - `Order.total_amount = subtotal - discount + shipping_cost`
   - `Transaction.amount > 0`

3. **Date Logic**
   - `order_date <= shipped_date <= delivered_date`
   - `end_date >= start_date`
   - No dates in future

4. **Journey Progress**
   - `progress_percent = (completed_steps / total_steps) * 100`

5. **Uniqueness**
   - SKU unique per business
   - Order number unique per business
   - Provider unique per business (one integration per provider)

### Data Validation Rules

- All amounts in correct currency
- Prices > 0 (no free products in MVP)
- Stock >= 0 (no negative inventory)
- Email/phone: valid format
- Dates: ISO 8601 format
- Enums: predefined values only

---

## Indexes for Performance

**Priority Indexes (MVP must-have):**

```sql
Product(business_id, sku) — Fast SKU lookup
Order(business_id, order_date) — Historical queries
Customer(business_id, email) — Customer lookup
Transaction(business_id, date) — Financial queries
Journey(business_id, status) — Active journey retrieval
Producer(business_id, reliability_score) — Supplier ranking
Opportunity(business_id, ai_score) — Top opportunities
Document(business_id, type) — Document filtering
Alert(business_id, severity) — Critical alerts first
```

---

## Data Residency & Sync

### On-Device (SQLite + Drift)
- All business entities
- All metadata
- Encrypted credentials

### Cloud (Optional, User-Controlled)
- Backups (user consent required)
- AI analysis results
- Sync state tracking

### Never Stored
- ❌ API keys in plain text (BYOK model)
- ❌ Credit cards (process via gateway)
- ❌ Plain passwords (OAuth or tokens only)
- ❌ Excessive PII (only what business needs)

---

## Success Criteria

✅ 15 core entities defined  
✅ All attributes, types, and constraints specified  
✅ Relationships and cardinality documented  
✅ Validation rules clear and implementable  
✅ Ready for Drift ORM schema generation  
✅ No conflicts with PRODUCT-VISION.md  
✅ Supports all 8 core capabilities  
✅ Data model reflects local-first, BYOK philosophy  

---

## Tiếng Việt — Tóm Tắt Mô Hình Dữ Liệu

### 15 Thực Thể Cốt Lõi

1. **User** — Hồ sơ chủ sở hữu, xác thực
2. **Business** — Hồ sơ chính, doanh nghiệp gốc
3. **Producer** — Nhà cung cấp, tài liệu sourcing
4. **Product** — Danh mục sản phẩm, tồn kho, giá cả
5. **Customer** — CRM, phân đoạn khách hàng
6. **Order** — Giao dịch bán hàng, lịch sử đơn hàng
7. **Channel** — Kênh bán hàng (Shopee, TikTok, etc.)
8. **Opportunity** — Cơ hội do AI phát hiện
9. **Journey** — Mục tiêu kinh doanh, mốc tiến độ
10. **JourneyStep** — Bước trong hành trình
11. **Transaction** — Giao dịch tài chính (doanh thu, chi phí)
12. **Document** — Tài liệu (hợp đồng, chứng chỉ, chứng từ)
13. **Alert** — Thông báo, đề xuất AI
14. **AIChat** — Lịch sử trò chuyện
15. **Integration** — Tích hợp nhà cung cấp, thông tin xác thực

### Chiến Lược Lưu Trữ Dữ Liệu

**Trên Thiết Bị** (SQLite + Drift):
- Tất cả thực thể kinh doanh
- Tất cả metadata
- Thông tin xác thực được mã hóa

**Đám Mây** (Tùy chọn, Người dùng Kiểm soát):
- Sao lưu (nếu người dùng cho phép)
- Kết quả phân tích AI
- Trạng thái đồng bộ

**Không Bao Giờ Lưu Trữ**:
- ❌ Khóa API ở dạng văn bản
- ❌ Thông tin thẻ tín dụng
- ❌ Mật khẩu ở dạng văn bản

---

**Phiên bản:** 1.0  
**Trạng thái:** ✅ APPROVED by Founder  
**Tiếp theo:** Drift schema implementation + SQLite DDL

