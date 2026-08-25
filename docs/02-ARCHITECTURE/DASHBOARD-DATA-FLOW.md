# Dashboard Data-Flow Review (WTM-117)

> Per-capability map + AI consumption boundary:
> [DATA-FLOW-BY-CAPABILITY.md](DATA-FLOW-BY-CAPABILITY.md).


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

---

## WTM-462 — Home tile ⇄ destination screen source audit (2026-08-25)

> Follow-up to **WTM-461** (PR #298, `f5bab0b`), which found the Home "Nguồn
> hàng" tile counting the **favourites** store while its tap opened the
> Business-Inputs screen — a summary tile reading a **different source** than
> the screen it opens (the [[P-50]] shape). WTM-461 fixed only the Producer
> tile; this audit checks the same shape on the other four and locks all five
> with a gate (`test/features/tongtai/p0/home_tiles_one_path_test.dart`).

Contract (ADR-TON-015): **Summary Count == Domain Visible Records** — the number
on a Home capability tile must come from the *same source* the screen its tap
opens reads, so the two can never contradict each other.

| Tile (`Key`) | Tile reads | Destination screen | Screen reads | Same source? |
|---|---|---|---|---|
| `home-tile-producer` | `businessInputRepository.loadAll().length` — `tongtai_home_screen.dart:190,210` | `TongtaiBusinessInputsScreen` | `businessInputRepository.loadAll()` — `tongtai_business_inputs_screen.dart` | ✅ same (fixed in WTM-461) |
| `home-tile-inventory` | `context.inventory.productCount` — `tongtai_home_screen.dart:207` → `InventorySummary.from(productRepository.loadAll())` `inventory_context.dart:94` | `TongtaiInventoryScreen` | `productRepositoryProvider` via `ProductCatalogController` — `tongtai_inventory_screen.dart:101` | ✅ same |
| `home-tile-consumer` | `context.customers.total` — `tongtai_home_screen.dart:208` → `CustomerSummary.from(customerRepository.loadAll())` `customer_context.dart:39` | `TongtaiCustomerListScreen` | `customerRepositoryProvider` via `CustomerDirectoryController` — `tongtai_customer_list_screen.dart:116` | ✅ same |
| `home-tile-journey` | `goals.length` — `tongtai_home_screen.dart:110,185` → `deriveGoalsProgress(businessGoalRepository.loadAll(), …)` | ~~`TongtaiJourneyScreen`~~ → **`TongtaiGoalsScreen`** (`onJourney` `tongtai_home_screen.dart:672`) | `businessGoalRepositoryProvider` via `BusinessGoalController` — `tongtai_goals_screen.dart:82` | ❌→✅ **was different** (`journeyRepository`, a different domain); **fixed** by opening the Goals list |
| `home-tile-finance` | `FinanceService(financeRepository, orders: orderRepository).summaryAsOf(now).receivables` — `tongtai_home_screen.dart:200-203` | `TongtaiFinanceScreen` | `FinanceController(financeRepository, orders: orderRepository)` → `FinanceService(_txns, orders: _sales)` — `finance_controller.dart` | ❌→✅ **was different** (controller built `FinanceService(_txns)` with **no orders** ⇒ receivables always 0, block never rendered); **fixed** by wiring `orderRepository` into the controller |

**Two divergences fixed (like Producer, to One Data Path):**

1. **Journey** — the tile's number is a **goals** count (unit "mục tiêu",
   `count_list_contract_test` gates it against `businessGoalRepository`), but the
   tap opened the Journey **plan** screen, which reads `journeyRepository`. A
   seller with 3 goals and no journey saw "3" then an empty "no journey" screen.
   `onJourney` now opens `TongtaiGoalsScreen`, which lists exactly those goals.
   The Journey plan stays one tap away via the "Nhiệm vụ hôm nay" section
   (`home-open-journey`, kept green by `nav_availability_test`).
2. **Finance** — the tile shows **receivables**, derived from unpaid **orders**
   (WTM-211). The Finance screen's `FinanceController` built its `FinanceService`
   with `orders: const []`, so `receivables` (and `salesIncome`, WTM-196) were
   always 0 — the receivables block (`finance-receivables`) never rendered while
   the tile showed a real figure. `FinanceController` now reads the order
   repository, exactly as `FinanceContextProvider` already did.

Inventory and Consumer were already one-source (both the tile — via
`BusinessContext` — and the screen read the same repository); the gate now locks
that too, so a future refactor cannot silently split them.
