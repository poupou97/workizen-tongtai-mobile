# ADR Index — quyết định kiến trúc đang hiệu lực

| ADR | Quyết định | Trạng thái | Ngày |
|---|---|---|---|
| [ADR-TON-001](ADR-TON-001-app-separation-single-app-flavors.md) | App separation: tách rõ Platform/Product layer; không phụ thuộc code feature Hub; module phải extractable. Phần "single-app + flavors" bị **supersede bởi ADR-TON-003**; ba yêu cầu kiến trúc giữ nguyên hiệu lực | ✅ ACCEPTED (Founder) | 2026-07-16 |
| [ADR-TON-002](ADR-TON-002-di-riverpod.md) | DI/state = **Riverpod duy nhất** (GetIt trong AC cũ = lỗi spec) | ✅ ACCEPTED (Founder) | 2026-07-16 |
| [ADR-TON-003](ADR-TON-003-repo-split.md) | Repo độc lập `workizen-tongtai-mobile` (supersede phần flavors của ADR-TON-001); Hub = upstream fetch-only, không thêm build flavor | ✅ ACCEPTED (Founder) | 2026-07-22 |
| [ADR-TON-004](ADR-TON-004-chat-persistence-local-only.md) | Chat persistence **local-only** (bảng v4, KHÔNG vào sync outbox — chờ D-5); mã hoá = chuẩn nền tảng, SQLCipher là option chờ Founder | 🟡 PROPOSED (agent) — chờ Founder duyệt | 2026-07-22 |

## Quyết định Founder khác (chưa thành ADR riêng)

| Quyết định | Nội dung | Nguồn |
|---|---|---|
| D-2 Package ID | `com.workizen.tongtai` (Android + iOS) | Founder GO khi split, đã implement |
| Model policy | Dev agent: Opus 4.8 mặc định; task khó/retry → Fable 5 | Founder 2026-07-16 |
| Evidence-Driven Runtime | Verdict từ evidence, không tin agent report; cấm placebo test | Founder 2026-07-14 |
| Self-planning | Runtime tự lập kế hoạch trong phạm vi feature branch; Founder giữ Vision/Direction/Goals/Architecture/main | Founder 2026-07-16 |

## Còn mở (chưa quyết)

Xem [OPEN-DECISIONS.md](OPEN-DECISIONS.md) — đáng chú ý: mascot (business fox)
chưa chốt → icon/splash còn placeholder; auth strategy MVP (hiện: local UUID,
không account); analytics (hiện: không có, privacy-first).

## Quy tắc

Không silently mâu thuẫn ADR. Thay đổi = ADR mới `ADR-TON-00N-*.md` ghi rõ
supersede, chờ Founder duyệt, cập nhật index này.
