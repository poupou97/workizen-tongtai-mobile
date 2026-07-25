# ADR-TON-012: BusinessContext — the Aggregate Root of the business (Progressive Aggregation) + AI boundary

**Status:** ✅ ACCEPTED (Founder, 2026-07-25)
**Builds on:** ADR-TON-011 (BusinessMetricsService = KPI SoT), ADR-TON-008
(Repository seam), `DATA-FLOW-BY-CAPABILITY.md` (AI consumes a read-only
aggregate, never repositories/Drift).

## Decision

`BusinessContext` is the **Aggregate Root of the business** — a single read-only
snapshot the presentation layer and **Workizen AI** consume.

```
Repositories → BusinessMetricsService → BusinessContext → BusinessHealth → Home → Workizen AI
```

### Progressive Aggregation
BusinessContext is **not** blocked on completing every capability. It grows:
- **Phase 1 (now, WTM-129):** `BusinessMetrics` + Customers + Orders + Inventory.
- **Later:** Opportunity · Journey · Timeline · Goals · Finance — folded into the
  same aggregate without changing what AI or Home consume.

Phase-1 shape: `BusinessContext { metrics, customers: CustomerSummary,
orders: OrderSummary, inventory: InventorySummary }`, assembled by
`BusinessContextService` over the Order/Customer/Product repositories.

### AI boundary (absolute)
**Workizen AI reads ONLY the BusinessContext** — never a Repository, Store, or
Drift, and never a screen's private state. BusinessContext is the one seam
between the data layer and AI. `BusinessHealth` derives from BusinessContext
(the `BusinessContext → BusinessHealth` step); Home consumes BusinessContext for
its KPIs + counts + health. `BusinessMetrics` remains the KPI source of truth
inside the context.

## Opportunity — two phases (not locked to AI)

Opportunity is **decoupled from AI** so its value ships before AI activation:
- **Phase 1 — rule-based:** classify opportunities as **High Value · High Risk ·
  Urgent · Stale** from the persisted data. No AI, no gate.
- **Phase 2 — AI:** **Win Probability · AI Recommendation · AI Summary**, once
  Workizen AI is activated (G-3).

This unblocks Opportunity from the AI gate (its persistence + rule-based
classification can proceed; only the AI scoring waits).

## Consequences

- One aggregate root owns "the state of the business"; AI/Home/health stay
  consistent and the AI boundary is enforceable by construction.
- **User Data First:** a new business yields `BusinessContext.empty`.
- Adding a capability to the context is additive — no change to AI/Home contracts.
- Next: extend the context (Opportunity Phase-1, Journey, Timeline, Goals,
  Finance) as those capabilities mature; AI activation itself remains G-3.
