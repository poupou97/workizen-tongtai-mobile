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
- **Phase 1 (WTM-129/130/131):** `BusinessMetrics` + Customers + Orders +
  Inventory + Opportunity (rule-based slice).
- **Phase 2 (WTM-133):** **Journey** (goals, keyed by `GoalPace`) + **Finance**
  (reuses the capability's own `FinanceSummary`). Both are Drift-backed and start
  empty (User Data First); the provider owns its own clock for the time-relative
  reads. Folded in as two more providers — no change to what AI or Home consume.
- **Phase 3 (WTM-134):** **Timeline** — a *derived projection* (activity stream)
  over the other capabilities' events. `TimelineContextProvider` builds a real,
  non-sample `TimelineService` from the live Finance/Order/Journey repositories.
  It is a read-only *view*, so it is **excluded from `hasData`** (its events
  re-derive from finance/orders/journey, which already drive `hasData`) — no
  double-counting. This completes the non-AI Business Snapshot.
- Business Journey **is** the goal-orchestration capability, so the single
  `JourneySummary` slice covers the snapshot's Journey/Goals concern (one Context
  Provider per capability).

Current shape (through Phase 3 — the full non-AI snapshot): `BusinessContext {
version, generatedAt, metrics, customers: CustomerSummary, orders: OrderSummary,
inventory: InventorySummary, opportunity: OpportunitySummary, journey:
JourneySummary, finance: FinanceSummary, timeline: TimelineSummary, health:
BusinessHealth }`.

### One Context Provider per capability (WTM-131)
Do **not** build many independent summary services. **Each capability owns a
single Context Provider** (implementing `CapabilityContextProvider<T>` in
`core/`) that turns its repository into its read-only summary slice —
`CustomerContextProvider`, `OrderContextProvider`, `InventoryContextProvider`,
`OpportunityContextProvider`, … `BusinessContextService` just **composes** the
providers + `BusinessMetricsService`. Adding a capability (Journey, Timeline,
Goals, Finance) is one more provider wired in — no other change to Home or AI.

The `OpportunityContextProvider` counts the **rule-based** signals (WTM-130), so
the opportunity slice works with **AI off/offline**. Its summary is keyed by
`OpportunitySignal`, so the backlog signals (New / Won Recently / Lost Recently /
Follow-up Today / No Activity / Near Deadline) extend it without a breaking
change. **Rule Engine owns the basic signals; AI only adds analysis, prediction
and recommendation.**

### BusinessContext is a versioned Business Snapshot (WTM-132)
BusinessContext is a **Business Snapshot**, not just a DTO: it carries a
`version` (`kBusinessContextVersion`) + `generatedAt`, embeds the capability
slices, **and embeds the [BusinessHealth] read** — so AI reads one self-contained
snapshot. Target structure (grows via Progressive Aggregation): `version ·
generatedAt · BusinessMetrics · Customers · Orders · Inventory · Opportunity ·
Journey · Timeline · Goals · Finance · BusinessHealth`.

`BusinessHealth` is a **model** (not just an enum), kept simple but extensible:
`status` (Healthy | NotEnoughData) · `reason` (short text) · `confidence` (1.0
for the rule-based v1). A later AI assessor replaces the derivation with richer
status/reason/confidence **without changing Home's UI or the API** — Home only
reads the model.

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
- The non-AI Business Snapshot is **complete** (WTM-134). Next is AI Phase-2
  (Opportunity Win Probability / Recommendation / Summary, BusinessHealth AI
  assessor) — all reading the same BusinessContext. AI activation remains **G-3**
  (deferred, Founder-only privacy red-line).
