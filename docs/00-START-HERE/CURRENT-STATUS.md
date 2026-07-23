# Current Status — 2026-07-22 (repo split day)

## Where we are

- **Phase 1 (Product Design Bible):** ✅ DONE + Founder-approved. 60 docs.
- **Phase 2 (build):** 🔄 IN PROGRESS — **22 stories verified & shipped**,
  developed autonomously by the Evidence-Driven Runtime (3 batches + pilot).
- **This repo:** split from the Hub on 2026-07-22 (`split-baseline` tag);
  app runs standalone; `flutter analyze` clean; **519/519 tests passing**.

## Shipped stories (all at Jira "Code Review", code on this repo's main)

| Area | Stories |
|---|---|
| Data | WTM-51 schema (17 tables) · 52 migrations · 53 relationships · 54 sync-queue outbox |
| Shell/Nav | WTM-55 bottom nav · 56 tab persistence · 57 deep links · 59 onboarding (6 màn) |
| Identity/Core | WTM-58 UUID identity · 60 core utils (formatters/enums) · 62 design tokens+showcase |
| Producer | WTM-63 supplier search · 64 supplier detail · 65 favorites |
| Inventory | WTM-68 product list · 69 add/edit product · 70 stock alerts |
| Search | WTM-72 FTS5 (đ-aware) · 73 unified search · 74 ranking + A/B |
| Consumer | WTM-75 customer list |
| AI | WTM-61 xAI Grok BYOK client + key screen |
| Chat | WTM-80 AI Copilot chat UI (bubbles/ticks/attachments/typing) · 81 persistence SQLite v4 (hydrate/search, local-only ADR-TON-004; AI routing chờ WTM-82) |

## NOT built yet (honest gaps)

- Finance, Reports, Business Journey, Opportunity Hub **screens** (DB tables
  exist; UI does not). AI Copilot chat: UI (WTM-80) + persistence (WTM-81)
  có; **AI routing** (WTM-82) chưa nối — reply hiện là echo cục bộ.
- Sprint-3+ backlog (WTM-76…102: consumer detail, chat, journey, reports…)
  exists in Jira with full ACs — not yet run.
- App icon/splash = Flutter defaults (mascot "business fox" not finalized —
  open decision).
- iOS build unverified in-session (signing/SPM); Android debug build is the
  verified path. See [../migration/KNOWN-GAPS.md](../migration/KNOWN-GAPS.md).

## Next approved work

Run remaining Phase-2 backlog (Sprint 3+) via the Evidence-Driven Runtime —
same gates. Founder reviews/merges PRs into `main` of THIS repo now (the old
"merge feat/tongtai into Hub main" plan is obsolete — replaced by this split).

## History

Batch reports: [../04-DELIVERY/reports/](../04-DELIVERY/reports/) —
pilot (5 stories) → batch-01 (8, incl. the placebo-catch) → WTM-57 self-heal →
batch-02 (7 + WTM-69 network false-negative, later PASS). Pre-split git history:
Hub repo `feat/tongtai`.
