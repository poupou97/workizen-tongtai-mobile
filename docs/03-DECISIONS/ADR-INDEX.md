# ADR Index — quyết định kiến trúc đang hiệu lực

| ADR | Quyết định | Trạng thái | Ngày |
|---|---|---|---|
| [ADR-TON-001](ADR-TON-001-app-separation-single-app-flavors.md) | App separation: tách rõ Platform/Product layer; không phụ thuộc code feature Hub; module phải extractable. Phần "single-app + flavors" bị **supersede bởi ADR-TON-003**; ba yêu cầu kiến trúc giữ nguyên hiệu lực | ✅ ACCEPTED (Founder) | 2026-07-16 |
| [ADR-TON-002](ADR-TON-002-di-riverpod.md) | DI/state = **Riverpod duy nhất** (GetIt trong AC cũ = lỗi spec) | ✅ ACCEPTED (Founder) | 2026-07-16 |
| [ADR-TON-003](ADR-TON-003-repo-split.md) | Repo độc lập `workizen-tongtai-mobile` (supersede phần flavors của ADR-TON-001); Hub = upstream fetch-only, không thêm build flavor | ✅ ACCEPTED (Founder) | 2026-07-22 |
| [ADR-TON-004](ADR-TON-004-chat-persistence-local-only.md) | Chat persistence **local-only** (bảng v4, KHÔNG vào sync outbox — D-5 đã xác nhận: Phase 2 không backend/sync); mã hoá = chuẩn nền tảng, SQLCipher là option chờ Founder | ✅ ACCEPTED (Founder) | 2026-07-23 |
| [ADR-TON-005](ADR-TON-005-analytics-firebase-operational.md) | Analytics (D-7 Updated): Phase 2 cho phép **Firebase Analytics + Crashlytics** (operational-only, giám sát closed beta); CẤM ad/marketing/profiling — red line giữ nguyên | ✅ ACCEPTED (Founder) | 2026-07-23 |
| [ADR-TON-006](ADR-TON-006-workizen-ai-router.md) | AI Provider (D-9 Updated): **Workizen AI Router** đa provider (Gemini/xAI/Claude/OpenRouter/Cerebras/Ollama), 3 chế độ Managed/BYOK/Local — supersede xAI-first; Phase 2 = BYOK + Local | ✅ ACCEPTED (Founder) | 2026-07-23 |
| [ADR-TON-007](ADR-TON-007-localization-appstrings.md) | Localization = **custom `AppStrings` + `LanguageNotifier`** (mirror Hub, KHÔNG ARB/gen-l10n/gói ngoài); `context.l10n`, đổi ngôn ngữ runtime EN+VI; migrate dần Boy-Scout (WTM-119) | ✅ ACCEPTED (Founder-directed) | 2026-07-24 |
| [ADR-TON-008](ADR-TON-008-drift-persistence-user-data-first.md) | Drift persistence: **UI→Controller→Repository→Store→Drift**, Repository quyết định nguồn; **User Data First** (DB thật KHÔNG seed sample, user mới rỗng; sample chỉ Demo Mode); **Local Business** root aggregate (mở rộng multi-business/cloud/login sau). Finance-first (WTM-120) | ✅ ACCEPTED (Founder-directed) | 2026-07-24 |

## Quyết định Founder khác (chưa thành ADR riêng)

| Quyết định | Nội dung | Nguồn |
|---|---|---|
| D-2 Package ID | `com.workizen.tongtai` (Android + iOS) | Founder GO khi split; tái xác nhận 2026-07-23 |
| D-3 Launch | Closed Beta → Open Beta → Production (tái dùng quy trình Hub) | Founder 2026-07-23 |
| D-4 Auth | Phase 2 không login (UUID local); Phase 3 Keycloak optional | Founder 2026-07-23 |
| D-5 Backend | Phase 2 không backend/không sync; Portal để sau | Founder 2026-07-23 |
| D-6 Monetization | Phase 2 free; Phase 3 RevenueCat (subscription/credits/premium AI) | Founder 2026-07-23 |
| D-8 Ngôn ngữ | VI primary, EN secondary | Founder 2026-07-23 |
| D-10 Export | Phase 2 có CSV export; Reports/BI Phase 3 | Founder 2026-07-23 |
| Model policy | Dev agent: Opus 4.8 mặc định; task khó/retry → Fable 5 | Founder 2026-07-16 |
| Evidence-Driven Runtime | Verdict từ evidence, không tin agent report; cấm placebo test | Founder 2026-07-14 |
| Self-planning | Runtime tự lập kế hoạch trong phạm vi feature branch; Founder giữ Vision/Direction/Goals/Architecture/main | Founder 2026-07-16 |

## Còn mở (chưa quyết)

Xem [OPEN-DECISIONS.md](OPEN-DECISIONS.md) (SSoT, cập nhật 2026-07-23) —
còn: mascot/icon (WTM-11) · scope WTM-83 · WTM-101 nghi trùng · SQLCipher.

## Quy tắc

Không silently mâu thuẫn ADR. Thay đổi = ADR mới `ADR-TON-00N-*.md` ghi rõ
supersede, chờ Founder duyệt, cập nhật index này.
