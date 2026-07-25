# ADR-TON-011: BusinessMetricsService — the single source of truth for KPIs

**Status:** ✅ ACCEPTED (Founder, 2026-07-25)
**Builds on:** ADR-TON-008 (Repository seam), ADR-TON-010 (Orders capability +
layered DoD, capability sequence), `DATA-FLOW-BY-CAPABILITY.md` (AI consumes a
read-only aggregate, never repositories/Drift).

## Context

Reports historically computed its own KPIs from orders (`ReportsService`); Home
computed its own counts/revenue too. As the capability sequence reaches
Reports → Home → BusinessContext → AI, letting each surface recompute KPIs would
duplicate logic and let the numbers drift apart.

## Decision

Introduce a **`BusinessMetricsService`** between the repositories and the
presentation layer. It is the **single source of truth for all business KPIs**:

```
Repositories → BusinessMetricsService → Reports → Home → BusinessContext → AI
```

- `BusinessMetrics` is a read-only aggregate (immutable). Initial KPIs:
  **revenue · orders count · customers count · average order value**
  (cancelled orders excluded — the billable rule).
- `BusinessMetricsService` reads the persisted capabilities through their
  repositories (Orders, Consumer today) and produces `BusinessMetrics`.
- **Reports and Home consume these values — they never recompute KPIs.**
  `ReportsService` keeps only the *breakdowns* (revenue trend, top
  categories/products/customers) over the same real orders; its headline
  revenue/AOV are superseded by `BusinessMetrics`.
- **Future KPIs** (top products, repeat customers, monthly trends, CLV,
  forecast…) **extend `BusinessMetricsService` / `BusinessMetrics`**, never a
  screen. Reuse over duplication.
- This service is a primary **future input to BusinessContext + AI**, which
  consume the aggregate (never the repositories/Drift) — consistent with the AI
  boundary (DATA-FLOW-BY-CAPABILITY).

## Consequences

- One place owns KPI semantics; Reports/Home/AI stay consistent by construction.
- **User Data First:** a new business loads `BusinessMetrics.empty` → surfaces
  show real (zero) state, never sample.
- First application: Reports (WTM-127). Next: Home (WTM-128, G-1). Then
  BusinessContext assembles `BusinessMetrics` + other capability aggregates for AI.
- A capability is not "layered-DoD DONE" until its KPIs flow through
  `BusinessMetricsService` (not a private calculation).
