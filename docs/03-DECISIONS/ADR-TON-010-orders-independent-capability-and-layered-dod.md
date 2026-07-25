# ADR-TON-010: Orders is an independent capability + layered Definition-of-Done

**Status:** ✅ ACCEPTED (Founder, 2026-07-25 — decisions G-1/G-2/G-3)
**Builds on:** ADR-TON-008 (Repository seam, User Data First), ADR-TON-009
(structured columns + versioned snapshot).
**Related:** `docs/02-ARCHITECTURE/PERSISTENCE-INVENTORY.md`,
`docs/02-ARCHITECTURE/DATA-FLOW-BY-CAPABILITY.md`, `OPEN-DECISIONS.md` (G-1/2/3).

## Context

After the persistence arc for the four user-authored capabilities (Finance,
Inventory, Consumer, Journey) completed, the Runtime surfaced three gate
decisions (OPEN-DECISIONS G-1/G-2/G-3). The Founder resolved them, which sets the
architecture for the next tier of the Business Data Foundation.

## Decisions

### G-1 — Home dashboard: User Data First (APPROVED)
The Home dashboard must **always display real business data**. A new user sees a
**zero-state with meaningful onboarding CTAs**, never sample numbers. Demo data
exists **only** inside an explicit Demo Mode; production and demo data are never
mixed. (Applies D-5 / ADR-TON-008 to Home, superseding WTM-14's sample-as-real
placeholder.)

### G-2 — Orders is an independent business capability (APPROVED w/ adjustment)
**Orders owns:** order lifecycle · revenue · order items · payment · (future)
invoice · shipment · returns. Business logic for orders must **not** be embedded
inside Consumer. Consumer Detail **may launch** a "Create Order" action, but the
logic lives in the Orders module. **Reports and Home KPIs consume the Orders
Repository** (revenue is owned by Orders, not recomputed downstream).

Implementation: `lib/features/tongtai/orders/` (domain relocated out of
`consumer/`, re-export shim for compatibility); `OrderRepository`
(Drift/Sample/InMemory) over `orders_table` — structured revenue columns
(`orderDate/status/totalQuantity/subtotal/totalAmount`) are the query SoT for
aggregation, line detail rides the tolerant `items` JSON array; `OrderController`
(hydrate/upsert); `orderRepositoryProvider`. User Data First (WTM-125).

### G-3 — AI is DEFERRED (DECISION)
Do **not** start AI implementation yet. Complete the Business Data Foundation
first, in this order:

```
Consumer → Orders → Reports → Home KPI → Opportunity → Journey → Timeline
        → BusinessContext → AI Summary → AI Recommendation → AI Planner
```

The Workizen AI activation (BYOK/Router, privacy red-line — ADR-TON-006) waits
until the foundation and BusinessContext are real.

## Layered Definition of Done (new product rule)

A capability is **DONE only when every layer is complete**:

```
UI → Repository → Persistence → Report/Dashboard → BusinessContext → AI-Ready
```

Do **not** mark a capability Done while any **downstream consumer still relies on
Sample data**. (E.g. Orders is not "Done" until Reports/Home read the real
OrderRepository and BusinessContext can expose it.) This makes "Done" mean
end-to-end real data, not just a shipped screen.

## Consequences

- Orders becomes the backbone that unblocks real Reports + Home KPIs.
- `PERSISTENCE-INVENTORY.md` (Capability Persistence Matrix) tracks each
  capability against the layered DoD; a capability stays "in progress" until no
  downstream Sample dependency remains.
- No AI work starts until the sequence reaches BusinessContext.
