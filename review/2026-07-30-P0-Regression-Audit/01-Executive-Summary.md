# 01 — Executive Summary | Tóm tắt điều hành

**P0 Regression Audit — 2026-07-30** · Jira: WTM-144 · WTM-145 · WTM-146 ·
PRs: #66 #67 #68 #70 #71 (all merged to `main`, final tip `3c851d2`) ·
Evidence: 990/990 tests, analyze clean, 8× CI green (see `07-Test-Evidence/`).

## What triggered this / Nguyên nhân

Founder field-testing on a real device (Galaxy S24 Ultra, 2026-07-30) found:
two different Home dashboards showing different numbers, the demo entry and
create buttons "disappearing", and mixed-language labels across the app.
Root-cause analysis confirmed three systemic defects, not isolated bugs.

## The three root causes / Ba nguyên nhân gốc

1. **Parallel demo state.** Screens carried silent `kSample*` / `.sample()`
   fallbacks; demo mode was a separate widget tree over fixtures. Export sent
   fixture CSVs, Chat-AI answered from fixture data, Timeline showed fixture
   events, and two dashboards could disagree. Old tests pumped the same
   fallbacks production used — they verified the fixtures rendered, not that
   the data source was right.
2. **Bilingual hard-coded labels.** The old "VI · EN" / "VI | EN" convention
   made language switching impossible and locked tests to the wrong strings.
3. **Mock-only test wiring.** Widget tests injected their own services instead
   of running the app's provider graph, so mis-wiring was invisible.

## What was done / Đã làm gì

| § | Fix | PR | Jira |
|---|---|---|---|
| §1 | ADR-TON-014: sample data seeds INTO the production repositories (`sample-` id prefix); every screen + BusinessContext reads ONE source; seed/remove reversible from More; all silent fixture fallbacks removed | #66 #67 | WTM-144 ✅ Done |
| §2 | Single-locale localization: ~290 AppStrings keys (VI/EN), every UI-chrome string keyed, runtime switch updates the whole app and persists; enum labels only via `label(languageCode)` | #68 #70 | WTM-145 ✅ Done |
| §3 | Test governance: 27 P0 suites through production wiring — literal ratchet, `.sample()` ban, placeholder consistency, nav/action availability, overflow (320px/1.3×/2.0×), real-SQLite-file restart lifecycle | #71 | WTM-146 ✅ (this package closes it) |
| §4 | Jira audit: root-cause comments on WTM-99/114/82/95; WTM-119 completed→Done; WTM-102 superseded→Done; backlog swept — no other at-risk story | — | comments 11182–11188 |

## Bugs the NEW suites caught before users did

- `SampleDataSeeder.removeAll` deleted customers before orders →
  **FOREIGN KEY 787 on the real database** (in-memory doubles never enforced
  it — the exact §1 bug class, caught by the new real-file restart suite).
- Home overflowed at 320 px / 1.3× text scale in three places.

## Honest boundaries / Ranh giới trung thực

- **Domain-generated content stays Vietnamese by design** (rule summaries,
  timeline event titles, AI text, sample fixtures): it is data, not chrome.
  Extending l10n into the content layer is a separate Founder decision.
- The app ships **vi + en**; the "long locale" overflow requirement is covered
  by a 2.0× text-scale proxy until a third language exists.
- The supplier catalog is a curated static directory (Phase 2 design, no
  supplier repository) — allowlisted, documented, not a data-masking bug.
- Release/tag/production deploy remain Founder-only; nothing was released.
