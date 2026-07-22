# Sync Queue & Conflict Resolution — Tổng Tài (WTM-54)

**Status:** Implemented (data layer) · **Epic:** DATA · **Depends on:** WTM-52 (Drift Migration V1)
**Related:** `DOMAIN-DATA-MODEL.md` · Phase 3 (Cloud Sync) — *design only, not built*

---

## 1. Purpose

Tổng Tài is **local-first**: the app is fully usable offline, and cloud sync is
**optional and user-controlled** (see `DOMAIN-DATA-MODEL.md § Data Residency & Sync`).
This story ships the **on-device foundation** for a future Phase-3 cloud sync:
a durable **outbox** that records every local write so it can be replayed to the
cloud once connectivity and consent exist.

Phase 3 (the network sync worker itself) is **out of scope**. What lands here is
the queue, its API, and the conflict-resolution *strategy* — enough that the sync
worker can be built later without re-touching the schema.

## 2. Data structure — `SyncQueueItemsTable`

One row per pending write operation. Declared in
`mobile/app/lib/database/tables/sync_queue_items.dart` and created by the V1
migration (`onCreate → createAll`).

| Column           | Type      | Notes |
|------------------|-----------|-------|
| `id`             | INTEGER PK, auto-increment | Monotonic **sequence number** — also the FIFO ordering key. |
| `operation_type` | TEXT      | `create` \| `update` \| `delete` (the `SyncOperationType` enum name). |
| `entity_type`    | TEXT      | Entity kind, e.g. `product`, `order`, `customer`. |
| `entity_id`      | TEXT      | Primary key of the affected row in its own table. |
| `timestamp`      | DATETIME  | **Logical** time of the operation; drives last-write-wins (see §4). |
| `payload`        | TEXT, nullable | JSON snapshot of the entity's fields. `NULL` for a delete. |

**Why an auto-increment `id` and not order-by-timestamp?**
Wall-clock timestamps collide at millisecond resolution, so two operations made
in quick succession can share a `timestamp`. The auto-increment `id` is strictly
monotonic and therefore the only reliable FIFO key. `timestamp` is kept separate
because it means something different — it is the *logical* time used for conflict
resolution, not ordering.

**No foreign key to the mutated entity — on purpose.** A queued `delete` must
outlive the row it deletes, so the queue cannot depend (via FK) on that row still
existing.

## 3. Queue API — `SyncQueueRepository`

`mobile/app/lib/features/tongtai/sync/sync_queue_repository.dart`

| Method | Behaviour |
|--------|-----------|
| `enqueue({operationType, entityType, entityId, payload?, timestamp?})` | Append to the tail; returns the new sequence id. `payload` is a JSON-serialisable map (`null` for deletes); `timestamp` defaults to now. |
| `peek()` | Oldest item **without** removing it, or `null` when empty. |
| `dequeue()` | Remove **and** return the oldest item (FIFO), or `null` when empty. Read + delete run in one transaction, so concurrent drainers never double-hand an item. |
| `pending()` | All items in FIFO order (read-only inspection). |
| `count()` / `isEmpty()` | Size of the queue. |
| `clear()` | Drop every item (e.g. after a full successful sync). |

Items are returned as `SyncOperation` — a Drift-free value object exposing a
typed `SyncOperationType` and a decoded `payloadMap`, so nothing outside the data
layer touches generated Drift classes.

## 4. Conflict resolution — **Last-Write-Wins (default)**

When the sync worker replays a queued local operation and the server already holds
a different version of that entity, the two must be reconciled. The Tổng Tài
default is **Last-Write-Wins (LWW)**:

> The version with the **newer `timestamp` survives**; the older one is discarded.

Implemented as `LastWriteWinsResolver` in
`mobile/app/lib/features/tongtai/sync/sync_operation.dart`:

- `resolve({local, remote})` → `ConflictWinner.local` / `.remote` by comparing timestamps.
- `pick<T>({local, localTimestamp, remote, remoteTimestamp})` → returns the winning value.
- **Exact ties** resolve to `remote` by default (configurable via `tieBreak`), so
  when two writes are genuinely indistinguishable in time every device converges
  on the server's shared copy instead of each keeping its own.

### Why LWW

- **Deterministic** and requires **no user prompt** — fits a single-user,
  single-business app where true concurrent edits are rare.
- Given a shared clock reference, **all devices converge** to the same value.
- Simple to reason about and cheap to compute.

### Known trade-offs (accepted for MVP)

- A slower/late write can clobber a concurrent one ("lost update"). Acceptable
  because concurrent edits to the same entity from two devices are rare for the
  target user.
- Relies on trustworthy timestamps. Phase 3 should stamp `timestamp` from a
  monotonic/normalised clock and, ideally, reconcile against server time on sync.

### Phase-3 upgrade path (not built)

The strategy is intentionally isolated behind `LastWriteWinsResolver`, so a later
phase can add per-entity policies without changing the queue:

- **Field-level merge** for additive data (e.g. append-only notes).
- **Server-wins / client-wins** overrides for specific `entity_type`s.
- **Manual resolution** UI for high-value conflicts (e.g. financial `transaction`).

## 5. Testing

`mobile/app/test/database/tongtai_sync_queue_test.dart` — real in-memory SQLite:

- **AC4** — enqueue 5 operations, dequeue in FIFO order, verify the sequence.
- FIFO holds even when all items share one `timestamp` (proves id-ordering).
- `peek` does not consume; `dequeue`/`peek` on an empty queue return `null`.
- JSON payload round-trips; deletes carry a `null` payload.
- `SyncOperationType` round-trips and rejects unknown values.
- `LastWriteWinsResolver`: newer wins, tie → remote (configurable), `pick()` value.

---

**Version:** 1.0 · **Language:** EN (VI summary in code labels)
