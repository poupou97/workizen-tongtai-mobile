# Integration Map

## Bản Đồ Tích Hợp

---

## English — External System Integrations

**Purpose:** This document maps all external systems Tổng Tài connects to, including API types, data flows, authentication, and security considerations.

---

## Integration Summary

**Total External Systems:** 12+  
**By Category:**
- **Marketplace APIs:** 4 (Shopee, TikTok, Facebook, Amazon)
- **AI Providers:** 3 (xAI, OpenRouter, OpenAI)
- **Payment Systems:** 2 (Stripe, E-wallets)
- **Cloud Services:** 2 (Google Drive, Firebase)
- **Data Sources:** 2+ (Google Trends, Supplier databases)

---

## Marketplace APIs

### 1. Shopee API

**Purpose:** Sync product listings, orders, customers  
**Data Flow:** Shopee → Tổng Tài (read-only)

**What Data Flows:**
- Products: name, SKU, price, stock, images
- Orders: order ID, items, customer, status, payment status
- Customer: buyer name, email, phone, purchase history
- Transactions: revenue, transaction date

**API Type:** REST API  
**Authentication:** OAuth 2.0 (user authorizes Shopee access)  
**Rate Limiting:** 1000 req/min (Shopee limits)

**Data Security:**
- OAuth token stored encrypted on device (flutter_secure_storage)
- Token never sent to server (only used for API calls from client)
- Auto-refresh token before expiry
- User can revoke access anytime from Shopee settings

**Frequency:** Real-time sync (polling every 5 min) or webhook (if available)

**Challenges:**
- Shopee API sandbox vs production credentials differ
- SKU mapping between Shopee + local Inventory (SKU is unique per Shopee account)
- Order status translation (Shopee's 15 statuses → Tổng Tài's 6 statuses)

**Status:** 🔄 To-do (Phase 1B or Phase 2)

**Cost:** Free (for seller accounts)

---

### 2. TikTok Shop API

**Purpose:** Sync TikTok Shop orders and product data  
**Data Flow:** TikTok Shop → Tổng Tài

**What Data Flows:**
- Orders: order ID, items, customer, status
- Products: listing, price, stock
- Customer: basic profile, purchase history

**API Type:** REST API  
**Authentication:** OAuth 2.0  
**Rate Limiting:** 500 req/min

**Data Security:**
- Same BYOK model as Shopee
- OAuth token encrypted on device
- Never sent to server

**Status:** 🔄 To-do (Phase 1B or Phase 2)

**Cost:** Free for sellers

---

### 3. Facebook Commerce API

**Purpose:** Sync Facebook Shop orders  
**Data Flow:** Facebook → Tổng Tài

**What Data Flows:**
- Orders: order ID, items, customer, status
- Products: listings, prices
- Customer: Facebook profile basics

**API Type:** Graph API (REST)  
**Authentication:** Facebook App Token + User Permission  
**Rate Limiting:** 200 req/hour (strict limits)

**Status:** 🔄 To-do (Phase 2)

**Cost:** Free (Facebook Business requires business account)

---

### 4. Amazon Seller API

**Purpose:** Sync Amazon seller products and orders  
**Data Flow:** Amazon → Tổng Tài

**What Data Flows:**
- Products: ASIN, title, price, stock
- Orders: order ID, items, customer, status
- Financials: revenue, fees, settlement

**API Type:** Amazon Selling Partner API (SP-API)  
**Authentication:** AWS IAM + Refresh Token  
**Rate Limiting:** Varies by operation (10-40 req/sec)

**Data Security:**
- AWS credentials stored securely on device
- Credentials rotated periodically
- Temp credentials via STS (no long-lived keys on device)

**Challenges:**
- Amazon's complex role/permission model
- ASIN → SKU mapping (products may differ)
- FBA vs FBM tracking (different fulfillment models)
- Multi-region selling (US, EU, Asia need separate APIs)

**Status:** 🔄 To-do (Phase 2, for US market entry)

**Cost:** Free (Amazon collects commission separately)

---

## AI Provider APIs

### 5. xAI API (Primary)

**Purpose:** AI-powered recommendations, analysis, chat  
**Data Flow:** Tổng Tài → xAI (send data) → Response (get insights)

**What xAI Powers:**
- AI Copilot chat responses
- Opportunity discovery (market analysis)
- Supplier scoring and recommendations
- Demand forecasting
- Trend analysis
- Churn prediction

**API Type:** REST API (OpenAI-compatible)  
**Authentication:** API Key (BYOK)  
**Request/Response:** JSON  
**Models Used:**
- `grok-2` (default, fastest)
- `grok-3` (if available, more capable)

**Data Sent to xAI:**
- Business context (industry, size, revenue)
- Historical sales data (aggregated, no PII)
- Customer segments (count, not names)
- Product catalog (names, prices, trends)
- Financial summary (totals, not transactions)

**Data NOT Sent:**
- User/customer personal data (names, emails, phones)
- Individual transaction records
- API keys for other services

**Rate Limiting:** Based on xAI subscription tier  
**Cost:** Pay-per-token (user brings own API key)

**xAI API Key Security:**
- Stored encrypted on device (flutter_secure_storage)
- Encrypted at rest using AES-256-GCM
- Only decrypted when making API call
- Key never logged or sent to Tổng Tài server
- User can rotate key anytime

**Example Request:**
```json
POST /v1/messages
{
  "model": "grok-2",
  "messages": [
    {
      "role": "user",
      "content": "Analyze my supplier options for apparel. Revenue last month: $5K, target: $20K."
    }
  ],
  "max_tokens": 1024
}
```

**Status:** ✅ Built (basic integration, expand in Phase 2)

---

### 6. OpenRouter API

**Purpose:** Alternative AI provider (fallback, comparison)  
**Data Flow:** Same as xAI

**What OpenRouter Powers:**
- Alternative AI models (Claude, GPT-4, others)
- Fallback if xAI unavailable
- User can choose preferred model

**API Type:** REST API (OpenAI-compatible format)  
**Models Available:** 100+ (user can select)

**BYOK Model:**
- User brings own OpenRouter API key
- Key stored encrypted on device
- User can select any model on platform

**Rate Limiting:** Per user's subscription

**Cost:** Varies by model (user pays directly)

**Status:** 🔄 To-do (Phase 2, for model choice)

---

### 7. OpenAI API (Optional)

**Purpose:** Alternative for users who prefer OpenAI  
**Data Flow:** Same as xAI

**Models:** GPT-4, GPT-4 Turbo, GPT-3.5-Turbo

**BYOK Model:**
- User brings OpenAI API key
- Key stored encrypted on device

**Cost:** Pay-per-token (OpenAI pricing)

**Status:** 🔄 To-do (Phase 2)

---

## Payment & Financial Systems

### 8. Stripe API

**Purpose:** Process payments, track transactions  
**Data Flow:**
- Tổng Tài → Stripe: Payment intent creation
- Stripe → Tổng Tài: Transaction status updates (webhook)

**What Data Flows:**
- Payment details (amount, currency, customer)
- Transaction status and receipt
- Settlement information

**API Type:** REST API + Webhooks  
**Authentication:** API Key (Secret key, server-side)

**Data Security:**
- Payment card data: NOT stored in Tổng Tài (PCI-DSS compliance)
- Card entered in Stripe's hosted iframe
- Tổng Tài receives token only, never card number
- Webhook signature verification (prevent spoofing)

**Use Cases:**
- Accept customer payments (for paid subscriptions, future feature)
- Track payments for transactions
- Generate payment receipts

**Status:** 🔄 To-do (Phase 2, for paid features)

**Cost:** 2.9% + $0.30 per transaction (Stripe standard)

---

### 9. E-Wallet APIs (Momo, ZaloPay)

**Purpose:** Track payments from e-wallet channels  
**Data Flow:** E-wallet → Tổng Tài (read transaction history)

**Momo API:**
- Read transaction history
- Reconcile received payments
- No payment collection (Shopee/TikTok handle that)

**ZaloPay API:**
- Read transaction history
- Same as Momo

**Authentication:** API Key + Signature  
**Rate Limiting:** 100 req/min

**Data Security:**
- API keys encrypted on device
- Signatures verified
- Transaction data encrypted in transit

**Status:** 🔄 To-do (Phase 2, for cash flow tracking)

---

## Data & Cloud Services

### 10. Google Drive API

**Purpose:** Backup business data, store documents  
**Data Flow:**
- Tổng Tài → Google Drive: Backup files (optional, user-enabled)
- Google Drive → Tổng Tài: Restore files

**What Data Flows:**
- Database backups (encrypted SQLite)
- Uploaded documents (PDFs, images)

**Authentication:** OAuth 2.0 (Google Drive scope)  
**Scope:** `drive.file` (app-only folder, limited access)

**Data Security:**
- User grants permission ("Backup to Google Drive?")
- Data encrypted before upload
- Stored in user's personal Google Drive (user's control)
- Can be deleted anytime from Google Drive

**Status:** 🔄 To-do (Phase 2, optional backup)

**Cost:** Free (within Google Drive quota)

---

### 11. Google Trends API

**Purpose:** Monitor market trends  
**Data Flow:** Google Trends → Tổng Tài (read trends)

**What Data Flows:**
- Trend scores (search volume) for keywords
- Historical trend data
- Related queries

**API Type:** REST API (unofficial but stable)  
**Authentication:** No API key needed (public data)  
**Rate Limiting:** 1000 req/hour

**Use Cases:**
- "Stitched apparel" trend (is it growing or shrinking?)
- Supplier trend (is XYZ supplier gaining popularity?)
- Market opportunity identification

**Status:** ✅ Built (basic integration)

**Cost:** Free

---

### 12. Firebase (Cloud Messaging, Analytics)

**Purpose:** Push notifications, optional analytics  
**Data Flow:**
- Tổng Tài → Firebase: Send push notifications
- Tổng Tài → Firebase: Analytics events (optional)

**What Data Flows:**
- Push notification payloads (alert, recommendation)
- Device token (for push targeting)
- Analytics events (if user opts-in)

**Data Security:**
- Analytics off by default (privacy first)
- User can enable/disable anytime
- Device tokens stored securely
- Minimal data sent (no PII)

**Status:** 🔄 To-do (Phase 2, for push notifications)

**Cost:** Free tier covers 100M notifications/month

---

## Data Supplier APIs (Future)

### 13. Trade Data API (Phase 2+)

**Purpose:** Cross-border trade insights  
**Data:** Import/export data, tariff info, regulations

**Providers:** TradeShift, UN Comtrade, Panjiva  
**Use Case:** "What's the market size for stitched apparel in US?"

**Status:** 🔄 To-do (Phase 2)

---

### 14. Supplier Database APIs (Phase 2+)

**Purpose:** Verify supplier credentials, compliance  
**Data:** Business registration, certifications, ratings

**Providers:** Alibaba, Global Sources, TradeKey  
**Use Case:** "Is this supplier verified and trustworthy?"

**Status:** 🔄 To-do (Phase 2)

---

## Integration Security Guidelines

### General Rules

1. **BYOK (Bring Your Own Key) Model**
   - Users provide API keys for AI providers, Shopee, etc.
   - Keys stored encrypted on device (flutter_secure_storage)
   - Keys NEVER sent to Tổng Tài server
   - Keys only used for API calls from mobile app

2. **Encryption in Transit**
   - All API calls use HTTPS/TLS
   - Certificate pinning for sensitive integrations
   - Webhook signature verification

3. **Data Minimization**
   - Only request data needed for feature
   - Don't store sensitive data (no card numbers, no plain passwords)
   - Aggregate/anonymize before storing locally

4. **User Control**
   - User grants permission for each integration
   - User can revoke access anytime
   - User can switch AI providers (xAI → OpenRouter)
   - Clearing app data removes all stored API keys

### Sensitive Data Handling

| Data Type | Storage | Transmission | Deletion |
|---|---|---|---|
| API Keys | Encrypted on device | HTTPS only | On app clear |
| User credentials | None (OAuth instead) | HTTPS only | N/A |
| Financial data | Encrypted SQLite | HTTPS to API | On logout |
| Customer data | Encrypted SQLite | HTTPS to API | User delete |
| Payment card | NOT stored | Stripe iframe only | Auto-clear |

---

## Integration Failure Handling

### If API Unavailable

| API | Fallback | Impact |
|---|---|---|
| Shopee | Offline mode (cached data) | Can't sync new orders |
| xAI | Show cached responses | Chat limited to cached knowledge |
| Google Trends | Use archived trend data | Trends not real-time |
| Firebase | Send later (queue notification) | Slight delay in alerts |

### Retry Strategy

- Automatic retry on transient errors (max 3 attempts)
- Exponential backoff (1s, 2s, 4s)
- User notified if integration fails consistently
- Manual retry button in settings

---

## Phase 1 vs Phase 2 Integrations

### Phase 1 (MVP)

**Priority:**
- ✅ Google Trends (identify opportunities)
- ✅ xAI / OpenRouter (AI features)
- 🔄 Shopee API (if time permits, otherwise manual import)

**Optional:**
- 🔄 Google Drive backup

### Phase 2 (Post-MVP)

**Add:**
- TikTok Shop API
- Facebook Commerce API
- Stripe (for payments)
- E-wallet APIs
- Firebase notifications
- Multi-AI model support

### Phase 3+

**Research:**
- Trade data APIs
- Supplier verification APIs
- Advanced accounting sync (QuickBooks)
- Team collaboration integrations

---

## API Documentation References

| System | Docs | Notes |
|---|---|---|
| Shopee | api.shopee.com | Multiple regions (TH, VN, etc.) |
| TikTok | developers.tiktok.com | China vs international |
| Facebook | developers.facebook.com/docs/commerce | Graph API |
| Amazon | developer.amazonservices.com | SP-API complex |
| xAI | docs.x.ai (if available) | OpenAI-compatible format |
| OpenRouter | openrouter.ai/docs | Proxy to multiple models |
| OpenAI | platform.openai.com/docs | GPT-4, etc. |
| Google Drive | developers.google.com/drive | Standard OAuth |
| Google Trends | Unofficial (via 3rd party lib) | PyTrends pattern |
| Stripe | stripe.com/docs | Standard REST |
| Firebase | firebase.google.com/docs | Cloud Messaging docs |

---

## Monitoring & Observability

### Health Checks

**Daily Checks:**
- Are integrations responding?
- Are API quotas healthy?
- Any authentication failures?

**Monthly Checks:**
- API usage vs limits
- Cost tracking (for paid APIs)
- Performance metrics (latency, errors)

### Logging

**What to Log:**
- API request/response (for debugging)
- Authentication failures
- Rate limit hits
- Data sync issues

**What NOT to Log:**
- API keys (never)
- User personal data (minimize)
- Card numbers (never)
- Sensitive customer data

---

**Version:** 1.0  
**Status:** ✅ APPROVED for Phase 1B (Phase 1 integrations only)  
**Date:** 2026-07-13  
**Related Docs:** DOMAIN-BOUNDARIES.md, AI-CAPABILITY-MATRIX.md  
**Next:** AI-CAPABILITY-MATRIX.md
