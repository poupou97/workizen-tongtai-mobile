# Persistence Inventory (per module)

**Governs:** ADR-TON-009 (structured columns + versioned snapshot, then normalize
on demand) · ADR-TON-008 (Repository seam) · WTM-122 (normalization TODO).

> Lightweight tracking of what each module persists — no heavy governance. A
> field graduates JSON → structured column / child table when a real trigger
> appears (query · index · report · join · constraint · FK · sync · audit · large
> payload · stable semantics). Do **not** promote just because "might need it".
> Status: **Keep in JSON** / **Promote Later** / **Promoted**.

## Finance (WTM-120 · schema v4 table `transactions_table`)

| Field | Where | Status |
|---|---|---|
| id, type, category, amount, date, description, paymentMethod | structured columns | Promoted |
| — | (no snapshot needed; `FinanceTransaction` mirrors the table) | — |

Source: Drift (real, User Data First) · Sample (demo). Query needs: date/type/
category for the dashboard aggregates — all structured. No JSON.

## Inventory (WTM-121 · schema v5 table `products_table`)

| Field | Where | Status |
|---|---|---|
| id, sku, name, category, description, listPrice(=price), totalStock(=quantity), stockAlertLevel(=reorder), updatedAt | structured columns | Promoted |
| imagePaths | `domain_snapshot` JSON (`{v:1, imagePaths:[…]}`) | Keep in JSON |
| history (edit audit) | not persisted (regenerable session state) | — |

Source: Drift (real, empty for new users) · Sample (demo). Promotion candidates:
`imagePaths` → a child `product_images` table **if** we need per-image metadata,
CDN sync, or ordering beyond a list (no trigger yet).

## Not yet persisted (still Sample/in-memory — migrate on the same seam)

| Module | Domain | Table (target) | Notes / snapshot candidates |
|---|---|---|---|
| Consumer | `Customer` | `customers_table` | `notes`, `tags`, `addresses[]` → snapshot; segments→column; history not persisted |
| Orders | `CustomerOrder` | `orders_table` | `items[]` already JSON in the table; no order-entry form yet |
| Journey | `BusinessGoal` | `journeys_table` | schema shape differs (budget/steps vs target/growth) — snapshot the domain, promote target/achieved later |
| Opportunity | `Opportunity` | `opportunities_table` | AI-generated; persist once scoring (WTM-93) lands |
| Producer | `Supplier` | `producers_table` | favorites already Drift; search results = sample |
| Timeline | derived | — | inherits real data automatically once its sources are persisted |

Reports/Home read through the Services above, so they show real data as each
underlying module is persisted — no UI change (DATA-FLOW-BY-CAPABILITY.md).

## Schema versions

v1 initial · v2 supplier_favorites · v3 products.description + FTS5 · v4
chat_messages · **v5 products.domain_snapshot** (WTM-121). Bump by exactly one +
an additive `onUpgrade` step per change (`tongtai_migrations.dart`).
