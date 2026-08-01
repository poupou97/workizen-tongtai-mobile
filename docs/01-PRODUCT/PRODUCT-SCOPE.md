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
  **Hoãn cho tới khi có bằng chứng từ người dùng thật** — ADR-TON-020.
- Tích hợp API thật: Shopee/TikTok/1688 OAuth, payment, tax engine —
  chỉ adapter/stub interface. Chúng cần backend giữ credential ⇒ đụng D-4/D-5.
- ⚠️ **Ngoại lệ — File Bridge KHÔNG nằm trong danh sách này.** Đọc file người
  dùng **tự chọn và tự xuất** từ sàn (Shopee/TikTok/GHN) là **capability chính
  thức** của sản phẩm (ADR-TON-020, Founder 2026-08-01), không phải tích hợp
  API và không cần backend. Ưu tiên sau 7 Epic delivery đang chạy.
- Enterprise concepts (tenant, admin console, SSO) — thuộc WorkforceOS,
  không phải sản phẩm này.
- Telemetry/ads/tracking SDK.

## Nguồn chi tiết

Boundaries đầy đủ theo capability:
[../02-ARCHITECTURE/DOMAIN-BOUNDARIES.md](../02-ARCHITECTURE/DOMAIN-BOUNDARIES.md).
Scope chỉ đổi qua Jira task được Founder duyệt — không "tiện tay" mở rộng.
