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
   Phase 2 has no backend and no sync (D-5, 2026-07-23).
2. **Workizen AI** — users interact only with "Workizen AI"; an AI Router picks
   the provider (Gemini/xAI/Claude/OpenRouter/Cerebras/Ollama — ADR-TON-006).
   Phase 2 modes: BYOK (user keys leave the device only in the Authorization
   header of a direct provider call) + Local (Ollama); Managed waits for
   Phase 3.
3. **Privacy by Default** — no account required (D-4); no ad SDKs, marketing
   tracking, profiling, or personalized ads — ever. Operational telemetry
   (Firebase Analytics + Crashlytics, closed-beta quality only) is allowed per
   D-7/ADR-TON-005.
4. **Practical over ambitious** — ship the boring, working thing.

## Architecture decisions in force

- **ADR-TON-001** — single-app product (split from Hub); Platform/Product layer
  separation; every module must remain extractable.
- **ADR-TON-002** — **Riverpod** is the only DI/state framework (never GetIt).
- SQLite + Drift, schema versioned in `lib/database/migrations/`;
  FTS5 search (đ-aware tokenizer) in `lib/database/search/`.
- `lib/features/tongtai/` = product code · `lib/core/` = platform seams.
- **ADR-TON-014** — sample data seed vào production repos (prefix `sample-`);
  KHÔNG parallel demo state.
- **ADR-TON-015** — **UI Implementation Maturity Model (L0–L4)** + **One Data
  Path**: `Repository → Context Provider → BusinessContext → Screen`. Cấm
  parallel cache, hardcode business data, mỗi màn tự tính summary. Contract
  bắt buộc: **Summary Count == Domain Visible Records**. Level trong Jira PHẢI
  == level thật trong code (ma trận:
  `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`).

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

- **Autonomous merge (Founder-authorized 2026-07-29):** Tổng Tài is an
  independent repo and the AI has **full Git rights, including merging its own
  PRs to `main`**, once **CI is green · no regression · no Founder Gate touched ·
  no Accepted ADR violated**. Do **not** pause at routine Git/PR/merge steps —
  self-merge and continue to the next backlog item. Then move the story to Jira
  **Done**. (This repo-local grant deviates from the ecosystem "gates are
  Founder-only" default in the root workspace `CLAUDE.md`; it applies to this
  repo only, by the Founder's decision.)
- **Founder Gates (the only reasons to stop)** — surface and wait for these,
  nothing less: product vision/direction · ADR conflict · multiple genuinely
  valid directions · security/privacy/legal (incl. the **G-3** Workizen-AI /
  BYOK / privacy red-line) · genuinely blocked.
- **Release / tag / deploy to production remain Founder-only.**

## Conventions

- Bilingual docs (EN + VI) — nhưng **UI chỉ một locale**, mọi chuỗi qua
  `AppStrings` key (ADR-TON-007). Conventional commits with the WTM key.
- Tests are real integration/widget tests; every feature ships with them
  (~992 passing — keep it green).
- **Story có UI phải khai `IMPLEMENTATION_LEVEL=L0..L4` trong Jira** và cập
  nhật ma trận cùng PR. Cấm đóng story ở level cao hơn thực tế.
- **Stable test IDs** `<screen>-<role>` cho mọi màn L2+; test hành vi tìm bằng
  Key, không bằng text hiển thị.
- **Bug mới ⇒ thêm Pattern vào `docs/04-DELIVERY/TESTING-BIBLE.md`**
  (Root-Cause · Regression · Test Pattern · Prevention Rule), không chỉ thêm
  test case. Đọc file này trước khi viết test cho lỗi tương tự.
- **Story chạm native/gradle/Firebase**: bắt buộc smoke-launch bản **release**
  trên máy thật (`adb logcat -b crash` rỗng) trước khi coi là xong.
