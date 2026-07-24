# Dashboard Data-Flow Review (WTM-117)

**Status:** Reviewed 2026-07-24 · **Priority:** P1 (technical debt / architecture)
· **Related:** WTM-114 (event-driven Timeline), ADR-TON-001 (extractable
modules), ADR-TON-002 (Riverpod).

> Mục tiêu: mọi widget dashboard đọc dữ liệu qua **domain service / controller /
> repository**, không đụng thẳng DB hay state tạm trong UI — để sau này gắn
> **Drift / Sync / Backend** không phải sửa UI. / Every dashboard widget must
> read through a domain service — so a future Drift/Sync/Backend swap needs **no
> UI change**.

## Verdict

**Largely compliant.** No widget queries Drift (`AppDatabase`) directly today.
Aggregations and dashboards read through pure services/controllers that are the
single swap seam per module. One class of exception remains: several **list**
screens fall back to the in-memory `kSample*` constants inline instead of going
through a repository. Those are the migration points — tracked below, not a
regression.

## Seam per module (the one place to swap for Drift)

| Module | Read seam (consumed by UI) | Aggregator | UI reads via |
|---|---|---|---|
| Reports | `ReportsService` | `BusinessReport` | injected `reportsService` (Home, Reports) ✅ |
| Finance | `FinanceController` → `FinanceService` | `FinanceSummary` | injected `controller` (Finance) ✅ |
| Timeline | `TimelineService` ← `BusinessEventSource`s | `BusinessEvent` | injected `service` ✅ (event-driven, WTM-114) |
| Opportunity | `OpportunityFeedController` | — | injected `controller` (feed/detail) ✅ |
| Journey | `BusinessGoalController` | — | injected `controller` (goals/detail) ✅ |
| Inventory | `ProductCatalogController` / `ProductInventoryService` | — | screen default `?? kSampleProducts` ⚠️ |
| Consumer | `CustomerDirectoryController` / `CustomerDirectoryService` | — | screen default `?? kSampleCustomers` ⚠️ |
| Producer | `SupplierSearchService` / `SupplierFavoritesController` | — | service seam ✅ |

Legend: ✅ reads only through the seam · ⚠️ reads the seam **or** falls back to a
`kSample*` constant inline.

## Exceptions to close (Drift-swap targets)

These read `kSample*` **directly** as a default, so a Drift swap would touch the
screen unless a repository is introduced first:

- `tongtai_home_screen.dart` — module counts use `kSampleSuppliers.length`,
  `kSampleProducts.length`, `kSampleCustomers.length`, and `kSampleBusinessGoals`
  / `kSampleOpportunities` for the top lists (all injectable, but the **default**
  is the constant).
- `tongtai_inventory_screen.dart` — `widget.service?.all ?? kSampleProducts`.
- `tongtai_customer_list_screen.dart` — `widget.service?.all ?? kSampleCustomers`.
- `tongtai_export_screen.dart` — reads `kSample*` for the CSV source.

## Recommendation (do not implement now — record only)

Introduce a thin **repository per module** (e.g. `ProductRepository`,
`CustomerRepository`) that returns the `kSample*` list today and a Drift-backed
list later. Screens depend on the repository (via Riverpod, ADR-TON-002) instead
of referencing `kSample*` — then the Drift migration is a repository swap with
**zero UI change**. Aggregating services (`ReportsService`, `FinanceService`,
`TimelineService`) already take their input list through a constructor, so they
need no change — only their data source (the repository) is swapped.

**No code change is required by this ticket** — it is a review + the seam map
above. The repository introduction is a separate, prioritizable story.
