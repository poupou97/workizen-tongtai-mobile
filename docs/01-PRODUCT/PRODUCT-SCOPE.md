# Product Scope

## In scope (MVP / Phase 2)

- 8 capabilities theo [CAPABILITY-MAP](../02-ARCHITECTURE/CAPABILITY-MAP.md);
  ưu tiên build: Producer → Inventory → Consumer → Search/AI → Journey/
  Opportunity → Finance/Reports.
- Local-first + BYOK (xAI Grok); mock/stub cho mọi tích hợp ngoài.
- Android-first; iOS build được nhưng release sau.
- Bilingual EN+VI toàn bộ UI.

## Out of scope (đừng tự thêm)

- Backend/server, account system, cloud sync (Phase 3+, opt-in, qua ADR).
- Tích hợp thật: Shopee/TikTok/1688 API, payment, logistics, tax engine —
  chỉ adapter/stub interface.
- Enterprise concepts (tenant, admin console, SSO) — thuộc WorkforceOS,
  không phải sản phẩm này.
- Telemetry/ads/tracking SDK.

## Nguồn chi tiết

Boundaries đầy đủ theo capability:
[../02-ARCHITECTURE/DOMAIN-BOUNDARIES.md](../02-ARCHITECTURE/DOMAIN-BOUNDARIES.md).
Scope chỉ đổi qua Jira task được Founder duyệt — không "tiện tay" mở rộng.
