# Removed / Not-Carried Files

Split theo whitelist (chỉ mang thứ Tổng Tài dùng) nên không có "xoá" — mà là
**không mang theo**:

## Không mang từ Hub (Hub-only, đúng lệnh)

- Toàn bộ features Hub: academy, ai_news/RSS, memory (Personal Memory),
  home/onboarding Hub, chat/docchat, scan/OCR, knowledge, output/Studio,
  arcade, my_voice, qr, subscription, wallet, vault, settings, growth,
  leaderboard, mascot, lan, portal, agent_lab, smart_tools, ai_gateway,
  assistant, ingestion, journey (Hub), library, more (Hub), auth, usage,
  news_sources…
- Hub assets, l10n, feature flags, tools, store-assets, experiments.
- Hub tests ngoài phạm vi tongtai.
- Mọi config nhạy cảm: google-services.json, keystore, provisioning,
  dev-secrets — **không tồn tại trong phạm vi copy**.

## Không mang dù "shared-looking" (consumer-rule)

AI Gateway/Router, auth foundation, chat/document foundation,
analytics/notification, RevenueCat — Tổng Tài chưa tiêu thụ →
xem [../02-ARCHITECTURE/MODULE-OWNERSHIP.md](../02-ARCHITECTURE/MODULE-OWNERSHIP.md).

## Xoá trong repo này sau scaffold

- `test/widget_test.dart` (template flutter create, tham chiếu MyApp không tồn tại).
