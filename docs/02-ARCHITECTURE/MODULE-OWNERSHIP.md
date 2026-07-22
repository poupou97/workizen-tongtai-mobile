# Module Ownership — cái gì thuộc ai

## Tổng Tài — Only (100% code trong repo này)

Toàn bộ `lib/` hiện tại: database, navigation shell, identity, onboarding,
deep links, producer/inventory/consumer/search/ai modules, design tokens,
core utils. **Không file nào import code feature của Hub** (verified at split).

## Shared Foundation của Hub — CHƯA adopt (cố ý)

Các nền tảng sau tồn tại bên Hub nhưng Tổng Tài **không dùng** hôm nay, nên
KHÔNG copy sang (tránh dead code; xem consumer-rule trong migration report):

| Hub foundation | Vì sao chưa adopt | Nếu cần thì |
|---|---|---|
| AI Gateway / Router (multi-provider, LAN, quota) | Tổng Tài có BYOK client xAI riêng (WTM-61) đủ cho MVP | Adopt qua upstream policy khi cần multi-provider |
| Auth (Keycloak/Google/Apple) | MVP không account — local UUID (WTM-58) | Khi có cloud sync opt-in |
| Chat/Document/OCR foundation | Chưa có story nào cần | Khi làm Copilot chat UI, đánh giá Fit/Gap |
| Analytics/notification | Privacy-first, chưa cần | Qua ADR nếu bao giờ cần |
| RevenueCat/billing | Chưa monetize | Phase sau |

## Hub — Only (không bao giờ port)

Academy, RSS/News, Personal Memory, Hub onboarding/home, Studio/Output,
Arcade, store-release rules của Hub, Hub feature flags/schema.

## Quy tắc

Muốn adopt gì từ Hub → theo [../upstream/HUB-UPSTREAM.md](../upstream/HUB-UPSTREAM.md)
(fetch-only remote, phân loại MUST-ADOPT/CANDIDATE/HUB-ONLY/NOT-APPLICABLE,
ghi vào HUB-ADOPTION-LOG, có test evidence).
