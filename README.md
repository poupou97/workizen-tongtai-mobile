# Tổng Tài — AI-First Business OS (Workizen)

Mobile app (Flutter) giúp chủ kinh doanh nhỏ tại Việt Nam vận hành toàn bộ
vòng kinh doanh: nguồn hàng → tồn kho → khách hàng → tài chính → cơ hội —
với AI Copilot BYOK. **Local-first · BYOK · Privacy by default.**

| | |
|---|---|
| App ID | `com.workizen.tongtai` (Android + iOS) |
| Stack | Flutter · Riverpod · SQLite/Drift (FTS5) · xAI Grok (BYOK) |
| Trạng thái | Phase 2 — 22 story shipped, 519 tests, chưa lên store |
| Jira / Confluence | `WTM` / `workizento` (workizen.atlassian.net) |

## Bắt đầu

```bash
flutter pub get
flutter analyze && flutter test   # phải sạch + xanh
flutter run
```

**Agent AI / dev mới:** đọc [`docs/00-START-HERE/AGENT-ONBOARDING.md`](docs/00-START-HERE/AGENT-ONBOARDING.md)
trước tiên (15 phút hiểu toàn bộ). Luật làm việc + gates: [`CLAUDE.md`](CLAUDE.md).

## Cấu trúc

```
lib/            # app (core/ + database/ + features/tongtai/)
test/           # 519+ real tests
docs/           # Product Design Bible + handoff (00-START-HERE … 06-GOVERNANCE)
handover.sh     # chạy story qua Evidence-Driven Runtime
```

## Nguồn gốc

Split từ Workizen Hub (`workizen-ai-personal-wallet` @ `feat/tongtai`,
commit `145a5c5`) ngày 2026-07-22 — chi tiết:
[`docs/migration/MIGRATION-REPORT.md`](docs/migration/MIGRATION-REPORT.md).
`main` là Founder-gate: mọi thay đổi qua feature branch + PR.
