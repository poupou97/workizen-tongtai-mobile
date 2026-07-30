# ADR-TON-014: Sample data seeds into the production repositories (one source for every screen)

**Status:** ✅ ACCEPTED (Founder P0 Regression Audit directive, 2026-07-30)
**Supersedes:** the parallel demo state of WTM-128 (`TongtaiHomeScreen.demo` +
screen-local `kSample*` fallbacks). **Refines** G-1/ADR-TON-008: *User Data
First* stays — nothing is preloaded; samples enter only on an explicit action.

## Problem (found in the field, by the Founder)

Demo data lived in a parallel world: a pushed demo dashboard + per-screen
`kSample*` fallbacks. Consequences the Founder hit live: two dashboards that
disagreed; Export shipping FIXTURE rows instead of user data; chat AI answering
from samples; the Timeline screen showing sample events — while 946+ tests
passed, because tests exercised the same mocked fallbacks.

## Decision

1. **One source.** Every screen and the AI read the production repositories and
   the one BusinessContext. No screen-local sample list, no demo repository in
   any production path, no `TongtaiHomeScreen.demo`.
2. **"Xem thử Demo" = seed.** `SampleDataSeeder.seed()` writes the fixtures into
   the real repositories with ids prefixed **`sample-`** (order→customer links
   remapped consistently). Idempotent (remove-then-insert). Explicit action only
   (Home CTA on an empty business; More → "Nạp dữ liệu mẫu" with confirm).
3. **Sample rows are ordinary rows.** Users may open, edit and delete them;
   Reports/Opportunity/AI treat them like any data. Home shows a banner while
   samples exist (`home-sample-banner`).
4. **Reversible.** More → "Xóa dữ liệu mẫu" calls `removeAll()` — deletes ONLY
   the `sample-` prefix (user ids are UUIDs, collision-free by construction).
   `Repository.deleteByIdPrefix(prefix)` is the seam on all five repositories.
   **Deletion order: orders FIRST** — on the real SQLite database
   `orders_table.customer_id` enforces a foreign key (PRAGMA foreign_keys=ON);
   deleting customers while sample orders exist throws SqliteException 787.
   Locked by `test/features/tongtai/p0/drift_restart_test.dart` (WTM-146 §3),
   which runs the full lifecycle across three AppDatabase sessions on one
   real .db file (the in-memory doubles never enforced the constraint).
5. **Producer** counts persisted supplier favourites (no supplier table exists;
   the catalog remains a search surface until the Phase-4 APIs) — Home and the
   Producer screens read that same favourites store.

## Test governance (§3 of the directive)

`test/features/tongtai/p0/`: seeder lifecycle (idempotency, link remap,
sample-only deletion, edit-then-remove) · cross-screen consistency (context
counts ≡ repository counts) · Opportunity e2e (persisted rows → Rule Engine →
context slice) · the full acceptance scenario (fresh → seed → create → update →
delete-samples → restart → verify). Screen tests now run production wiring or
inject fixtures EXPLICITLY — silent sample defaults are gone from `lib/`
(`WorkizenAiContextBuilder` defaults to empty; Export/Timeline/Reports load
repositories).

## Consequences

- The Export/Chat/Timeline sample leaks are fixed and regression-locked.
- `kSample*` fixtures remain ONLY as seed material + explicit test fixtures.
- WTM-143's demo labeling is replaced by the sample banner (the demo screen no
  longer exists).
