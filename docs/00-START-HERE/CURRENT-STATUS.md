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
| Consumer | WTM-75 customer list · 76 add/edit customer (form, multi-address, audit trail, duplicate check) |
| AI | WTM-61 xAI Grok BYOK client + key screen |

## NOT built yet (honest gaps)

- Finance, Reports, Business Journey, Opportunity Hub **screens** (DB tables
  exist; UI does not). AI Copilot **chat UI** (client foundation only).
- Sprint-3+ backlog (WTM-77…102: purchase history, chat, journey, reports…)
  exists in Jira with full ACs — not yet run (WTM-76 done, first of Sprint 3).
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
