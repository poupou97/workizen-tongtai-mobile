# Sprint Report — Autonomous Batch 02 (Evidence-Driven Runtime)

**Date:** 2026-07-16 · **Branch:** `feat/tongtai` (pushed; `main` untouched)
**Mode:** Evidence-Driven Autonomous + **Smart Retry** (self-healing) — verdicts from evidence only
**Companion:** `SPRINT-AUTONOMOUS-01-REPORT.md` (batch 01, 8 PASS / 1 FAIL)

---

## 1. Results (grounded in the ArtifactStore)

| Story | Verdict | Tests | Attempts | Note |
|-------|---------|-------|----------|------|
| WTM-64 Supplier Detail View | ✅ PASS | 35/0 | 1 | |
| WTM-65 Supplier Favorites | ✅ PASS | 6/0 | 2 | **self-healed** by Smart Retry |
| WTM-69 Add/Edit Product | ❌ FAIL | 0/0 | 2 | infra false-negative — see §3 |
| WTM-70 Stock Level Alerts | ✅ PASS | 84/0 | 2 | **self-healed** by Smart Retry |
| WTM-72 FTS5 Search Index | ✅ PASS | 42/0 | 1 | đ-aware tokenizer, schema v3 |
| WTM-73 Unified Search Screen | ✅ PASS | 48/0 | 1 | |
| WTM-74 Search Ranking & Relevance | ✅ PASS | 39/0 | 1 | A/B variant framework |
| WTM-61 AI Client (xAI BYOK) | ✅ PASS | 54/0 | 1 | key store + validator + client |

**7 PASS / 1 FAIL · 308 passing tests this batch · all PASS → Code Review.**
Between batches, **WTM-57 self-healed** via Smart Retry (32 tests → Code Review).

**Cumulative Phase-2 autonomous total: 21 stories PASS, 560+ real tests, `main` never touched.**

## 2. ⭐ Smart Retry proved itself live

Built this sprint (runtime `d11b89b`): on FAIL the Runtime extracts the concrete,
evidence-grounded failure (placebo file, analyze errors, failing tests) into a
targeted fix brief and retries a fresh Developer attempt. Live results:
**WTM-65 and WTM-70 both failed attempt 1 and healed on attempt 2 with no human
involvement.** WTM-57 (batch-01's reject) also recovered — and in doing so
exposed a real Runtime bug: the placebo detector false-positived on a `{` inside
a test *name* (`…/{id}`). Root-cause fixed in the detector (`3e27f33`), not
band-aided in the test.

## 3. WTM-69 — infrastructure false-negative, not bad code

Evidence shows the FAIL was environmental: `flutter test` could not download the
sqlite3 native library (`SocketException … github.com`) because the run coincided
with the host losing network (MacBook lid closed → system sleep). No code was
committed; the story stays parked. **Action:** re-run on an awake host (in
progress). **Runtime lesson (next improvement):** classify infra/build failures
(download timeouts, "Building native assets failed") as INFRA-RETRY, distinct
from code-quality FAIL.

## 4. Ops lesson — laptops sleep; autonomy needs an always-on host

Lid-close suspends every process (observed: dev agent at 1h54m wall-clock, 32s
CPU) and freezes timers, so even timeouts cannot fire. Mitigations shipped:

- **Robust hang-kill** (`93bc583`): process-GROUP SIGKILL on timeout (proved by
  test: hung child killed at 300ms; whole tree, not just the direct child).
- **`handover.sh`** (runtime `6fb2ac9`, hub `068d75a`): one-command run on an
  always-on host (NUC/server) — preflight, branch sync (never main),
  sleep-inhibit, per-story logs, Founder digest.
- **`--sync-jira`** (`4baa4b2`): after an Atlassian MCP outage, replays the
  Runtime's stored verdict decisions so the Jira board catches up losslessly.
- **`--founder-digest`**: every report now carries an auto-generated
  "Awaiting Founder Approval" section (below) so nothing is missed.

## 5. Founder decisions recorded this sprint

- **D-1 App Separation → Single-app + Flavors** (`ADR-TON-001`), with the
  Platform/Product-layer separation, no-direct-Hub-dependency, and
  extractable-modules requirements. Re-evaluate monorepo at ~100k users.
- **DI → Riverpod** (`ADR-TON-002`); "GetIt" in WTM-60's AC recorded as a spec
  error. WTM-60 can close.
- `OPEN-DECISIONS.md` updated (EN + VI) accordingly.

## 6. 🔔 Awaiting Founder Approval (auto-digest)

- **Branches to review + merge (Founder-only):** Hub `feat/tongtai`
  (30+ commits ahead of `main`) · runtime `feat/evidence-driven-runtime`
  (10+ commits ahead of `master`).
- **Stories at Code Review:** WTM-52/53/54/56/57/59/61/63/64/65/68/70/72/73/74/75.
- **Decisions pending: 0** (D-1 + DI decided).
- **Parked:** WTM-69 (infra false-negative; re-run scheduled). *Nothing blocks the Runtime.*

## 7. Next (self-planned)

1. Re-run WTM-69 on an awake host → expect PASS.
2. Runtime: INFRA-RETRY classification for environmental test failures.
3. Jira reconcile via `--sync-jira` once the Atlassian MCP session is stable.
4. Sprint-3 batch (Consumer/Chat stories) — same evidence gates.
