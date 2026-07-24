# ADR-TON-009: Persistence — Structured columns + versioned domain snapshot (then normalize on demand)

**Status:** ✅ ACCEPTED (Founder-directed, 2026-07-24 — option B, P0.4)
**Builds on:** ADR-TON-008 (Repository seam, User Data First)
**Related:** WTM-121 (first pattern — Inventory), WTM-123 (second — Consumer),
WTM-124 (third — Journey, divergent-schema case), WTM-122 (normalization TODO),
`docs/02-ARCHITECTURE/DATA-FLOW-BY-CAPABILITY.md`,
`docs/02-ARCHITECTURE/PERSISTENCE-INVENTORY.md` (Capability Persistence Matrix).

## Context / Bối cảnh

Finance persisted cleanly (WTM-120) because `FinanceTransaction` was built to
mirror `TransactionsTable`. The other domain models diverged from the WTM-51
schema: `Product.imagePaths`, `Customer.notes/tags/addresses`, and
`BusinessGoal` (target/achieved/growth vs `JourneysTable` budget/steps) have no
matching columns — direct column mapping would be **lossy**.

## Decision (option B) / Quyết định

**NOW — quick win:** each entity table keeps its **structured columns** for core
fields **plus** a nullable **versioned domain snapshot** column (JSON) for the
extended/nested/not-yet-queried fields.

- **Repository owns** the Domain ↔ Persistence mapping.
- **Structured column = Source of Truth** for a field once it is *promoted*.
- The snapshot is **versioned** (`{"v": N, ...}`) so future reads can migrate.
- **UI, Domain Service and AI never know the persistence format** — they see the
  domain object / aggregate only (ADR-TON-008, DATA-FLOW-BY-CAPABILITY).
- Lossless, additive migration (one nullable column), no domain/UI/test breakage.

First pattern at **Inventory (Product)** — verified by test, then reused at
**Consumer (Customer)** (WTM-123): structured columns for
name/phone/city/email/orderCount/totalSpent/lastOrderDate + a structured
`segments` JSON-array column, with `addresses/tags/notes` in the snapshot. A
shared, corrupt-tolerant codec (`lib/features/tongtai/core/domain_snapshot.dart`)
is reused by every repository, and the Consumer test set covers round-trip,
backward compatibility, corrupt-JSON fallback, version tolerance, structured
precedence and business isolation.

The third application — **Journey (BusinessGoal)** (WTM-124) — is the canonical
**divergent-schema** case: `journeys_table` (goal/status/budget/steps/timeline)
does not line up with the `BusinessGoal` domain (type/target/achieved/growth/
dates/notes). The Repository promotes what maps cleanly and is queryable
(`goal`←name, `revenueImpact`←targetAmount, `startedAt`←startDate; `status`/
`progressPercent`/`timelineDays` derived for query only) and snapshots the
lossless remainder (type, achievedAmount, growth, endDate, notes). Same shared
codec, same six-part test set. This proves the pattern absorbs a table whose
shape predates the current domain **without** a breaking migration.

## This is transitional, NOT the permanent model

The JSON snapshot is a **transitional extensibility mechanism**, not a long-term
replacement for relational modelling. Avoid **both** extremes: normalizing too
early, and leaving everything in JSON forever.

## Long-term — normalize on real product demand

A snapshot field is **promoted** out of JSON to a structured column / child table
/ relation table / dedicated aggregate when a real **trigger** appears:

> frequent query · index · report · join · unique constraint · foreign key ·
> independent sync · conflict resolution · audit · permission/governance ·
> large/slow JSON payload · stable business semantics.

**Do not promote just because "might need it later."** Promotion is an **additive
migration, never breaking**. The **Repository and Domain Service interfaces stay
stable** across all phases:

```
Phase 1  Structured columns + versioned snapshot        ← we are here
Phase 2  Promote business-critical fields
Phase 3  Normalize complex collections → child/relation tables
Phase 4  Schema ready for Cloud Sync · Multi-Business · Collaboration
```

## Inventory of snapshot fields

Tracked in `docs/02-ARCHITECTURE/PERSISTENCE-INVENTORY.md` per module: structured
fields · fields-in-JSON · schemaVersion · query/report need · sync need ·
promotion candidate · status (Keep in JSON / Promote Later / Promoted).
Lightweight — no heavy governance process (WTM-122 tracks promotions).

## Execution rule

Apply B now; continue Autonomous Product Build. Do **not** stop a sprint for
wholesale normalization — pull a promotion into a sprint only when a business
trigger is clear or it directly concerns the capability under development.
