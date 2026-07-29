# Capability Persistence Matrix

**Governs:** ADR-TON-009 (structured columns + versioned snapshot, then normalize
on demand) · ADR-TON-008 (Repository seam, User Data First) · WTM-122
(normalization TODO). **SoT for persistence readiness across the product.**

> The single architecture dashboard for persistence. Each capability migrates onto
> the **same** approved pattern (Repository seam + structured columns + versioned
> `domain_snapshot`) — reuse, don't invent (Autonomous V2: *consistency over
> innovation*). A field graduates JSON → structured column / child table only when a
> real trigger appears (query · index · report · join · constraint · FK · sync ·
> audit · large payload · stable semantics). Do **not** promote speculatively.

## Dashboard

| Capability | Repository | Structured Columns | Domain Snapshot | Drift Ready | Sample Ready | Cloud Ready | Version | Migration Status |
|---|---|---|---|---|---|---|---|---|
| Finance | `FinanceRepository` | id, type, category, amount, date, description, paymentMethod | — (domain mirrors table) | ✅ | ✅ | ⛔ | v4 | Promoted |
| Inventory | `ProductRepository` | id, sku, name, category, description, price, quantity, reorder, updatedAt | `imagePaths` | ✅ | ✅ | ⛔ | v5 | Promoted + JSON |
| Consumer | `CustomerRepository` | id, name, phone, city(=location), email, orderCount, totalSpent, lastOrderDate, `segments[]` | `addresses[]`, `tags[]`, `notes` | ✅ | ✅ | ⛔ | v6 | Promoted + JSON |
| Journey | `BusinessGoalRepository` | id, goal(=name), status*, revenueImpact(=targetAmount), startedAt(=startDate), progressPercent*, timelineDays* | `type`, `achievedAmount`, `growthTarget`, `growthAchieved`, `endDate`, `notes` | ✅ | ✅ | ⛔ | v7 | Promoted + JSON (divergent-schema) |
| Orders | `OrderRepository` | id, customerId, orderNumber, orderDate, totalQuantity, subtotal, totalAmount, status | `items[]` snapshot (productId/name/sku/unit/qty/soldPrice) | ✅ | ✅ | ⛔ | orders_table | UI+Repo+Persistence ✅ (WTM-125/126); Reports ✅ via BusinessMetricsService (WTM-127); **Home rewire pending** (layered DoD) |
| **BusinessMetricsService** (KPI SoT) | `BusinessMetricsService` over Orders+Consumer repos | KPIs: revenue · ordersCount · customersCount · AOV (billable) | — (read-only aggregate `BusinessMetrics`) | ✅ | ✅ | ⛔ | — | ADR-TON-011: Reports/Home reuse (no recompute); future KPIs extend it; feeds BusinessContext |
| **BusinessContext** (Aggregate Root) | `BusinessContextService` **composes one Context Provider per capability** (Customer/Order/Inventory/Opportunity) + `BusinessMetricsService` | metrics + CustomerSummary + OrderSummary + InventorySummary + OpportunitySummary (rule-based signal counts) | — (read-only aggregate `BusinessContext`) | ✅ | ✅ | ⛔ | — | ADR-TON-012: **AI reads ONLY this** (never repos). `CapabilityContextProvider<T>` seam — add journey/timeline/goals/finance = one more provider. Home consumes it (WTM-129/131) |
| Opportunity | `Opportunity` → `opportunities_table` | — | — | ⛔ | ✅ | ⛔ | — | **Phase 1 rule-based signals ✅** (WTM-130: High Value/High Risk/Urgent/Stale, no AI). Persistence + Phase-2 AI (Win Prob/Recommendation/Summary) still pending (G-3) |
| Producer | `Supplier` → `producers_table` | favorites only (Drift) | — | 🟡 | ✅ | ⛔ | v2 | Favorites Drift; catalogue = sample |
| Timeline | derived (no table) | — | — | n/a | ✅ | ⛔ | — | Inherits from its sources |
| Reports | via BusinessMetricsService (KPIs) + ReportsService (breakdowns) | — | — | ✅ | ✅ | ⛔ | — | Real data ✅ (WTM-127); breakdowns over real orders; opportunities still sample (AI-gated) |
| Home | BusinessMetricsService (KPIs) + BusinessHealth | — | — | ✅ | ✅ | ⛔ | — | User Data First ✅ (WTM-128, G-1): real KPIs (zero valid), real counts, BusinessHealth badge, onboarding CTAs; Demo Mode = explicit action, never preloaded |

Legend: ✅ done · 🟡 partial · ⛔ not yet · n/a not applicable. `*` = derived
column written for query/report only (the domain recomputes it; not read back).
**Cloud Ready** stays ⛔ for the whole product in Phase 2 (local-only, no
backend/sync — D-5); the Repository seam + `LocalWorkspace` root aggregate are
what make a later cloud phase additive.

## Per-capability detail

### Finance (WTM-120 · schema v4 `transactions_table`)
All fields structured — `FinanceTransaction` mirrors the table, no snapshot
needed. Query needs (date/type/category dashboard aggregates) are all columns.

### Inventory (WTM-121 · schema v5 `products_table`)
Structured: id, sku, name, category, description, listPrice(=price),
totalStock(=quantity), stockAlertLevel(=reorder), updatedAt. Snapshot (`{v:1}`):
`imagePaths`. `history` not persisted (regenerable). Promotion candidate:
`imagePaths` → a child `product_images` table **if** per-image metadata / CDN
sync / ordering is ever needed (no trigger yet).

### Consumer (WTM-123 · schema v6 `customers_table`)
Structured (SoT): id, name, phone, city(=location), email, orderCount,
totalSpent, lastOrderDate(=lastPurchaseDate), plus `segments[]` in its own
JSON-array column. Snapshot (`{v:1}`): `addresses[]`, `tags[]`, `notes`.
`history` not persisted; `tier` derived from `totalSpent`. A stale copy of a
promoted field in the snapshot is ignored on read (structured-precedence test).

### Journey (WTM-124 · schema v7 `journeys_table`) — divergent-schema case
The table shape (`goal/status/budget/steps/timeline`) differs from the
`BusinessGoal` domain (`type/target/achieved/growth/dates/notes`), so this is the
canonical ADR-TON-009 option-B application. The Repository owns the mapping:
- **Promoted (SoT, read back from the column):** `goal`←name, `revenueImpact`←
  targetAmount, `startedAt`←startDate.
- **Derived (write-only, query/report):** `status` (active/completed),
  `progressPercent`, `timelineDays` — the domain recomputes these on read.
- **Snapshot (`{v:1}`, lossless remainder):** `type`, `achievedAmount`,
  `growthTarget`, `growthAchieved`, `endDate` (epoch ms), `notes`.
- `budget/spent/totalSteps/completedSteps` belong to a different (steps/budget)
  journey model — left at their column defaults, candidates to wire or drop later.

Promotion candidates: promote `achievedAmount`/`growthAchieved` to real columns
once Reports (WTM-96) aggregate goal attainment; promote `type` to a column if
goal-type filtering/reporting arrives.

## Schema versions

v1 initial · v2 supplier_favorites · v3 products.description + FTS5 · v4
chat_messages · v5 products.domain_snapshot (WTM-121) · v6 customers.domain_snapshot
(WTM-123) · **v7 journeys.domain_snapshot** (WTM-124). Bump by exactly one + an
additive `onUpgrade` step per change (`tongtai_migrations.dart`).
