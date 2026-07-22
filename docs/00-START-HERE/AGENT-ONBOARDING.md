# Agent Onboarding — đọc file này ĐẦU TIÊN

You are working on **Tổng Tài** (`workizen-tongtai-mobile`) — a standalone
product. Everything you need is in THIS repo; you never need the Hub repo or
any prior conversation.

## Reading order (15 phút)

1. This file — how to work here.
2. [PRODUCT-CONTEXT.md](PRODUCT-CONTEXT.md) — what the product is / is not.
3. [CURRENT-STATUS.md](CURRENT-STATUS.md) — what exists today, what's next.
4. [WORKING-RULES.md](WORKING-RULES.md) — gates, workflow, forbidden actions.
5. [../02-ARCHITECTURE/CURRENT-STATE-ARCHITECTURE.md](../02-ARCHITECTURE/CURRENT-STATE-ARCHITECTURE.md) — the code as it really is.
6. [../03-DECISIONS/ADR-INDEX.md](../03-DECISIONS/ADR-INDEX.md) — decisions in force.
7. [SOURCE-OF-TRUTH.md](SOURCE-OF-TRUTH.md) — which doc wins when they disagree.

## The 60-second version

- **Product:** AI-First Business OS for Vietnamese SME sellers. Flutter,
  Android-first. 8 capabilities (Producer/Inventory/Consumer/Finance/Reports/
  Journey/Opportunity/Copilot). Bilingual EN+VI.
- **Principles:** Local-first (SQLite/Drift) · BYOK (user's own AI keys,
  xAI Grok) · Privacy by default (no telemetry) · Riverpod only (never GetIt).
- **State:** 22 verified stories shipped (519 passing tests at split). App
  launches to `TongtaiAppShell` from `lib/main.dart`.
- **Workflow:** stories come from Jira **WTM**; development is evidence-driven
  (your claims don't count — `flutter analyze` + `flutter test` output does).
- **Gates:** `main` is Founder-only. Work on feature branches, open PRs.
  Never placebo tests (`expect(true, true)` is auto-rejected).

## How to build & test (proof it works)

```bash
flutter pub get
flutter analyze          # must be clean
flutter test             # 519+ tests must pass
flutter run              # launches Tổng Tài shell
```

## Provenance

Split from `workizen-ai-personal-wallet` @ `feat/tongtai` (commit `145a5c5`)
on 2026-07-22. Full pre-split git history lives there; this repo starts at the
`split-baseline` tag. Upstream policy: [../upstream/HUB-UPSTREAM.md](../upstream/HUB-UPSTREAM.md).
