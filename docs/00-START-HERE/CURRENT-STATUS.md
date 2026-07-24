# Current Status — 2026-07-22 (repo split day)

## Where we are

- **Phase 1 (Product Design Bible):** ✅ DONE + Founder-approved. 60 docs.
- **Phase 2 (build):** 🔄 IN PROGRESS — **22 stories verified & shipped**,
  developed autonomously by the Evidence-Driven Runtime (3 batches + pilot).
- **This repo:** split from the Hub on 2026-07-22 (`split-baseline` tag);
  app runs standalone; `flutter analyze` clean; **519/519 tests passing**.
- **Post-split fixes:** WTM-105 — split regression: `main.dart` bypassed
  `TongtaiRootGate` so the first-launch tutorial never showed; rewired + 5
  app-level boot tests (suite: 524) + ADR-TON-003 (repo split) recorded.

## Shipped stories (all at Jira "Code Review", code on this repo's main)

| Area | Stories |
|---|---|
| Data | WTM-51 schema (17 tables) · 52 migrations · 53 relationships · 54 sync-queue outbox |
| Shell/Nav | WTM-55 bottom nav · 56 tab persistence · 57 deep links · 59 onboarding (6 màn) |
| Identity/Core | WTM-58 UUID identity · 60 core utils (formatters/enums) · 62 design tokens+showcase |
| Producer | WTM-63 supplier search · 64 supplier detail · 65 favorites |
| Inventory | WTM-68 product list · 69 add/edit product · 70 stock alerts |
| Search | WTM-72 FTS5 (đ-aware) · 73 unified search · 74 ranking + A/B |
| Consumer | WTM-75 customer list · 76 add/edit customer (form, multi-address, audit trail, duplicate check) · 77 purchase history (orders, filters, AOV/repurchase) |
| AI | WTM-61 xAI Grok BYOK client + key screen |
| Chat | WTM-80 chat UI · 81 persistence SQLite v4 (local-only ADR-TON-004) · 82 Workizen AI Router (đa provider, context injection, fallback offline — ADR-TON-006) |
| Journey | WTM-87 business goals: templates + multi-step form + progress/pace + khuyến nghị rule-based (AI plan chờ WTM-88) |
| Opportunity | WTM-91 feed: type filter, sort relevance/recency/ROI, bookmark + saved view, swipe interested/dismiss + undo (AI scoring chờ WTM-93) |
| Backup | WTM-99 CSV export (customers/products/orders, UTF-8 BOM, date range, share/email, history — D-10 Phase 2) |
| Brand | WTM-109 Business Fox mascot (10 concept, Founder chọn Origami all) · 110 app icon + splash native từ 08a |
| Fixes | WTM-105 wire `TongtaiRootGate` vào `main.dart` (onboarding lần đầu) + ADR-TON-003 |

## NOT built yet (honest gaps)

- Finance, Reports **screens** (DB tables exist; UI does not). Journey:
  goals UI có (87), step-plan/AI chờ 88/89. Opportunity: feed có (91),
  detail/scoring chờ 92/93. Chat: đủ UI + persistence + Workizen AI Router
  (80/81/82); Claude adapter + per-provider key UX = follow-up (WTM-83).
- Backlog còn lại (WTM-78/79, 84–86, 88–90, 92–98, 102, 108) trong Jira với
  AC đầy đủ.
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
