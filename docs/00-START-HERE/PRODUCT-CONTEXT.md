# Product Context — Tổng Tài là gì (và không là gì)

## Là gì

**Tổng Tài** ("I Like a Boss") — an **AI-First Business OS** on mobile for
Vietnamese SME entrepreneurs (online sellers, small traders). One app that runs
the whole business loop:

| Capability | Purpose |
|---|---|
| Producer (Nguồn Hàng) | Find/manage suppliers; AI sourcing opportunities |
| Inventory (Tồn Kho) | Products, SKU, stock, pricing, stock alerts |
| Consumer (Khách Hàng) | CRM/CDP, customer list, segments |
| Finance (Tài Chính) | Revenue/expenses/cash flow *(not built yet)* |
| Reports (Báo Cáo) | KPIs & insights *(not built yet)* |
| Business Journey | Goal orchestration — journey ≠ workflow *(DB only)* |
| Opportunity Hub | AI deal discovery *(DB only)* |
| AI Copilot | BYOK assistant (xAI Grok) *(client built, chat UI not)* |

Core ideas: **Opportunity is the central unit** · **Business Journey is
goal-driven orchestration, not a flow** · **Copilot ≠ chatbot** (Planner /
Advisor / Navigator / Executor / Monitor / Optimizer).

## KHÔNG là gì

- ❌ Not Workizen Hub (the personal scan/OCR/chat app) — different product,
  different repo, shared platform *ideas* only.
- ❌ Not WorkforceOS Enterprise — no tenants, no admin consoles, no server-side
  orchestration.
- ❌ No backend in MVP — device talks directly to AI providers (BYOK).
- ❌ No real marketplace/payment/tax integrations yet — stub/adapter only.
- ❌ Not a data-harvesting business — we monetize VALUE, never user data.

## Personas & market

Vietnamese SME sellers (Shopee/TikTok/Facebook commerce). 5 personas with
journeys: see [../01-PRODUCT/USER-JOURNEYS.md](../01-PRODUCT/USER-JOURNEYS.md).
Bilingual product: every user-facing string EN + VI.

Full vision: [../01-PRODUCT/PRODUCT-VISION.md](../01-PRODUCT/PRODUCT-VISION.md) ·
Screens: [../01-PRODUCT/SCREEN-INVENTORY.md](../01-PRODUCT/SCREEN-INVENTORY.md)
