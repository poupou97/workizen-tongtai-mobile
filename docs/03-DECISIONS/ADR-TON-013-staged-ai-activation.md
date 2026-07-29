# ADR-TON-013: Staged AI activation (G-3A→G-3D) — read-only AI tier over BusinessContext

**Status:** ✅ ACCEPTED (Founder directive "Automatic Gate Progression", 2026-07-29)
**Builds on:** ADR-TON-006 (Workizen AI Router, BYOK/Local), ADR-TON-012
(BusinessContext Aggregate Root + absolute AI boundary).

## Decision

The G-3 AI gate is opened **in pre-approved stages**, each strictly read-only,
auto-progressing without per-stage Founder review:

| Stage | Capability | Hard conditions |
|---|---|---|
| **G-3A** | **AI Summary** (WTM-116) | Reads ONLY BusinessContext · no repository/DB access · no mutation · no workflow · no action · BYOK/Local per ADR-TON-006 |
| **G-3B** | **AI Recommendation** | Generates recommendations only · no business-data mutation · never auto-executes · no side effects |
| **G-3C** | **AI Planner** | Generates plans/tasks/roadmaps · never auto-executes |
| **G-3D** | **BusinessHealth AI** | Assessment only · does NOT replace rule-based health · rule-based stays the default fallback |

**Product defaults locked with this decision:**
- **Opportunity chain:** `Rule Engine → Opportunity → AI Scoring → AI Ranking →
  AI Explanation`. The Rule Engine is never replaced — AI only layers analysis
  on top (extends ADR-TON-012's two-phase rule).
- **Journey:** goal progress is **auto-derived from business data**; manual
  entry remains only for KPIs that cannot be derived.
- **WTM-122 (persistence normalization) stays CLOSED** — no data migration
  without a separate Founder decision.

**Stopping rules** (the only reasons to halt the staged progression):
Accepted-ADR / Privacy / Security violation · Product-Vision change needed ·
data migration needed · AI-Policy change needed · unresolvable technical
blocker.

## Implementation invariants (all stages)

- The AI's **entire world** is the serialized `BusinessContext` — one snapshot,
  version-stamped (`businessContextPromptText`). Tests must prove the provider
  receives exactly that text and nothing else.
- Every AI feature has a **deterministic rule-based twin** used when AI is
  off/offline or every provider fails — the feature always works.
- A business with no data (`hasData == false`) never spends a provider call.
- Providers = the enabled BYOK/Local chain in the router's preference order
  (ADR-TON-006); the user only ever sees "Workizen AI".

## Consequences

- G-3A shipped as `BusinessSummaryService` (`lib/features/tongtai/ai/
  business_summary.dart`) + on-demand summary card on Reports with a provenance
  chip (provider vs Rule-based).
- G-3B/C/D and the Opportunity AI chain + Journey auto-derive follow under the
  same invariants without further gate approvals.
