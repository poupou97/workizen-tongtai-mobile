# Sprint Report — Autonomous Batch 01 (Evidence-Driven Runtime)

**Date:** 2026-07-14 (executed unattended while Founder offline)
**Branch:** `feat/tongtai` (all pushed to origin; **`main` never touched**)
**Mode:** Evidence-Driven Autonomous — Runtime is Source of Truth, verdict from evidence, never the agent's report
**Runtime:** `workizen-ai-workforce-runtime` @ `feat/evidence-driven-runtime`

---

## 1. Executive summary

The upgraded Runtime ran **9 real development Work Orders end-to-end with zero human input** — one verification cycle (WTM-56) plus an 8-story batch. Each cycle: an opus Developer agent wrote code + tests, then the **Runtime itself** ran `flutter analyze` + `flutter test`, scanned for fake tests, judged the evidence against acceptance criteria, decided the workflow transition, updated Jira, stored replayable artifacts, and pushed the feature branch.

- **8 PASS / 1 FAIL** — 8 stories advanced to **Code Review**; 1 (WTM-57) was **correctly rejected** and parked.
- **228 real tests** green across the 8 passing stories (260 counting the rejected one).
- **~2 hours** wall-clock for the 8-story batch (~11–19 min/story), fully sequential.
- **0 human approvals**, **0 commits to main**, 9 commits pushed to `feat/tongtai`.

**The headline result is the FAIL, not the passes** — see §3.

## 2. Results (grounded in the ArtifactStore, not agent reports)

| Story | Commit | Verdict | Quality | analyze | tests | Jira |
|-------|--------|---------|---------|---------|-------|------|
| WTM-56 Tab state persistence | `14b5250` | ✅ PASS | 93 | clean | 27/0 | Code Review |
| WTM-57 Deep linking | `f5496da` | ❌ **FAIL** | 40 | clean | 32/0¹ | Parked (In Progress) |
| WTM-59 Onboarding (6 screens) | `a151dfa` | ✅ PASS | 93 | clean | 27/0 | Code Review |
| WTM-52 Drift Migration V1 | `2e1b6c9` | ✅ PASS | 93 | clean | 12/0 | Code Review |
| WTM-53 Drift model validation | `adf7a36` | ✅ PASS | 93 | clean | 9/0 | Code Review |
| WTM-54 Offline sync queue | `66173f4` | ✅ PASS | 93 | clean | 32/0 | Code Review |
| WTM-63 Supplier search UI | `5806d1e` | ✅ PASS | 93 | clean | 34/0 | Code Review |
| WTM-68 Inventory + product list | `8332998` | ✅ PASS | 93 | clean | 44/0 | Code Review |
| WTM-75 Customer list | `f863aa3` | ✅ PASS | 93 | clean | 43/0 | Code Review |

¹ WTM-57's 32 tests *ran green* — but one was a **placebo** (see §3), so the evidence gate rejected the whole Work Order.

## 3. ⭐ The FAIL that proves the system works — WTM-57

The Deep-Linking Developer agent produced code that **passed `flutter analyze` cleanly and had 32 passing tests**, and (as agents do) it would have reported success. Under the *old* report-driven runtime this would have sailed into Code Review.

Instead the Evidence Collector's **placebo scanner** found **1 fake/assertion-free test** hidden in the suite. The Judge applied the hard gate:

> `verdict=FAIL — placebo/fake tests detected (1) — tests rejected` · quality capped at 40/100

→ Supervisor kept it in **In Progress** (parked for rework), did **not** advance it, and the batch moved straight on to the next story without idling.

This is exactly the **pilot finding F-2** (WTM-51's `expect(true,true)` placebo tests that the old Developer agent falsely reported as "7/7 passed"). The upgrade's whole purpose was to make that undetectable-before failure **automatically caught** — and here it caught a real one, unattended. **Evidence is the source of truth; a clean analyze + green tests is not enough if a test is fake.**

## 4. What the 8 passing stories delivered

- **WTM-56** — tab scroll/state persistence across navigation (27 tests)
- **WTM-59** — 6-screen onboarding tutorial with skip + first-launch gate (27 tests)
- **WTM-52** — Drift Migration V1: create-tables strategy + first-launch version check + integrity verify (12 tests)
- **WTM-53** — Drift model validation, relationships & fixtures; added `ON DELETE CASCADE` on `Product.supplierId` (9 tests)
- **WTM-54** — offline-first sync queue (outbox) + conflict resolution; new `SyncQueueItem` table (32 tests)
- **WTM-63** — supplier search screen: input, filters, suggestions, responsive results (34 tests)
- **WTM-68** — inventory screen + product list: search, category filter, sort, colour-coded stock, pagination (44 tests)
- **WTM-75** — customer list: search, location filter, sort, VIP tier badges, pagination (43 tests)

All isolated under `mobile/app/lib/features/tongtai/` and `lib/database/`; **no Hub production files modified**.

## 5. Git & Jira state

- `feat/tongtai`: 9 autonomous commits, **all pushed** to origin, branch in-sync.
- `main`: untouched — merge remains the **Founder-only gate**.
- 8 PASS stories → **Code Review** (via the live Jira gateway, each with an evidence-grounded comment: commit, analyze result, test counts, per-criterion verdict).
- WTM-57 → **In Progress** with a rejection comment stating the placebo finding.
- Every run is **replayable**: `~/.local/state/ai-wf/artifacts/WTM-XX/` (run.json + analyze.log + test.log).

## 6. Runtime performance & reliability

- Throughput: 8 stories in ~1h55m, sequential (one dev agent at a time to avoid branch contention).
- Guardrails exercised: hard timeouts (dev 45m / Jira 5m, SIGKILL) — none triggered; safe-boundary branch-guard held (0 main pushes); FAIL → park + continue (never idle).
- Evidence gate: analyze-clean + tests-green + **placebo-free** enforced on every story; 1 rejection.

## 7. Runtime findings / next improvements

1. **Smart retry (not yet implemented).** WTM-57 was parked but not auto-fixed. A retry that feeds the FAIL evidence (the specific placebo) back to a fresh dev agent would likely close it without human help. *Recommended next Runtime feature.*
2. **Per-story test count varies (9–44).** Low-count stories (WTM-53: 9) still passed the ≥1 gate; consider a per-story minimum-coverage criterion.
3. **Jira MCP dependency.** The live gateway shells to `claude` for Jira; a transient Atlassian MCP disconnect would degrade transitions (code/evidence unaffected). Consider a direct REST fallback.

## 8. Recommendation

- **Founder action:** review + merge the 8 Code-Review stories on `feat/tongtai` when ready (Founder-only gate).
- **WTM-57:** re-run with smart-retry once implemented, or hand-fix the one placebo test.
- **Runtime:** GO to continue autonomous batches; reliability held across 9 unattended cycles with the evidence gate doing its job.

**Bottom line:** the Evidence-Driven Runtime shipped 8 verified stories overnight with no human input, and — more importantly — *refused* to ship the one that hid a fake test. Reliability over speed, as specified.
