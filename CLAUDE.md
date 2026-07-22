# CLAUDE.md — Tổng Tài Mobile

Working agreement for AI-assisted development on this repository.

## ⭐ New agent? Read IN THIS ORDER (bắt buộc)

1. `docs/00-START-HERE/AGENT-ONBOARDING.md`
2. `docs/00-START-HERE/PRODUCT-CONTEXT.md`
3. `docs/02-ARCHITECTURE/CURRENT-STATE-ARCHITECTURE.md`
4. `docs/03-DECISIONS/ADR-INDEX.md`
5. `docs/00-START-HERE/CURRENT-STATUS.md`
6. `.claude/README.md`

Everything you need is in THIS repo — no Hub repo, no old conversations.
`.claude`/memory is operating context only; decisions live version-controlled
under `docs/` (see `docs/00-START-HERE/SOURCE-OF-TRUTH.md`).

## What this is

**Tổng Tài** ("I Like a Boss") — an **AI-First Business OS** for SME
entrepreneurs in Vietnam. Flutter, Android-first + iOS. applicationId
`com.workizen.tongtai`. Split from the Workizen Hub repo on 2026-07-22
(ADR-TON-001); full pre-split history lives in
`workizen-ai-personal-wallet` branch `feat/tongtai`.

8 capabilities: Producer (sourcing) · Inventory · Consumer (CDP/CRM) ·
Finance · Reports · Business Journey (goal orchestration) · Opportunity Hub ·
AI Copilot. The Product Design Bible in `docs/` is the spec — screens,
domain model, AI matrix, ADRs.

## Non-negotiable principles (inherited from the Workizen ecosystem)

1. **Local First** — all business data on-device (SQLite/Drift); works offline.
2. **BYOK** — AI keys are the user's; they leave the device only in the
   Authorization header of a direct provider call (xAI Grok primary).
3. **Privacy by Default** — no account required, no telemetry SDKs.
4. **Practical over ambitious** — ship the boring, working thing.

## Architecture decisions in force

- **ADR-TON-001** — single-app product (split from Hub); Platform/Product layer
  separation; every module must remain extractable.
- **ADR-TON-002** — **Riverpod** is the only DI/state framework (never GetIt).
- SQLite + Drift, schema versioned in `lib/database/migrations/`;
  FTS5 search (đ-aware tokenizer) in `lib/database/search/`.
- `lib/features/tongtai/` = product code · `lib/core/` = platform seams.

## Development workflow (Evidence-Driven Runtime)

This repo is developed by the AI Workforce Runtime
(`workizen-ai-workforce-runtime`): Developer agent → EvidenceCollector →
Judge → Supervisor → Jira. **Verdicts come from evidence (flutter analyze +
flutter test run by the Runtime), never from an agent's report.** No placebo
tests (`expect(true, true)` is auto-rejected). Model policy: Opus 4.8 default,
Fable 5 for hard tasks/retries.

- Jira: project **WTM** · Confluence space **workizento** (see `.workforce.json`).
- Run a story: `./handover.sh WTM-XX` (always-on host recommended).

## Gates

- **`main` is Founder-only** — agents work on feature branches, open PRs,
  never merge/push main, never tag/release/deploy.
- Every PASS story parks at Jira **Code Review** until the Founder merges.

## Conventions

- Bilingual docs (EN + VI). Conventional commits with the WTM key.
- Tests are real integration/widget tests; every feature ships with them
  (519 passing at split time — keep it green).
