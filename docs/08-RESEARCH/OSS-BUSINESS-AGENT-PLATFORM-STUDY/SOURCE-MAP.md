# SOURCE MAP — evidence nằm ở đâu

> Bản đồ thư mục cho người đọc study muốn tự kiểm một trích dẫn. Mọi đường dẫn
> tương đối với `~/projects/_reference/` và neo vào studied SHA trong
> `01-SOURCE-BASELINE.md`. External source **read-only** (REFERENCE-REGISTRY).

## ERPNext (`erpnext/` · GPL-3.0 · Python/Frappe)

| Vùng | Đường | Ghi chú |
|---|---|---|
| DocType schema | `erpnext/<module>/doctype/<name>/<name>.json` | schema = JSON khai báo, không phải migration |
| Controller | `erpnext/<module>/doctype/<name>/<name>.py` | lifecycle validate/submit/cancel |
| **Base controllers** | `erpnext/controllers/` | `accounts_controller.py` · `stock_controller.py` — mọi chứng từ kế thừa từ đây |
| Bút toán kho | `erpnext/stock/stock_ledger.py` | Stock Ledger Entry, valuation |
| Bút toán sổ cái | `erpnext/accounts/general_ledger.py` | `make_gl_entries` |
| Reorder | `erpnext/stock/reorder_item.py` | |
| 44 module | `erpnext/` | accounts · buying · selling · stock · manufacturing · crm · … |

## Relaticle (`relaticle/` · AGPL-3.0 · Laravel/Filament)

| Vùng | Đường | Ghi chú |
|---|---|---|
| **MCP server** | `app/Mcp/` | tool cho agent |
| Models | `app/Models/` | People · Company · Opportunity/Deal · Task … |
| Actions/Services | `app/Actions/` · `app/Services/` | write path |
| Policies | `app/Policies/` | permission |
| Custom fields | composer vendor `relaticle/custom-fields` ^3.8.0 | ⚠️ KHÔNG nằm trong `packages/` như bản đầu đoán — vendor không có trong clone, nên phần custom-field chỉ verify được ở tầng app (17 loại) |
| Routes | `routes/` | REST + MCP endpoint |

## Trigger.dev (`trigger-dev/` · Apache-2.0 root · TS monorepo)

| Vùng | Đường | Ghi chú |
|---|---|---|
| **Run engine** | `internal-packages/run-engine/` | state machine vòng đời run |
| Queue | `internal-packages/run-queue/` | concurrency, fairness |
| Store | `internal-packages/run-store/` · `database/` | Prisma schema |
| Schedule | `internal-packages/schedule-engine/` | cron |
| Redis worker | `packages/redis-worker/` | |
| **Supervisor** | `apps/supervisor/` | ⭐ trùng vai supervisor AI-WF |
| Webapp services | `apps/webapp/app/v3/` | |
| SDK contracts | `packages/core/src/v3/` | schemas |
| Self-host | `hosting/` · `docker/` | |

## Plane (`plane/` · AGPL-3.0 · Django + Next.js)

| Vùng | Đường | Ghi chú |
|---|---|---|
| Models | `apps/api/plane/db/models/` | `issue.py` là gốc |
| External API | `apps/api/plane/api/` | cho automation |
| Web | `apps/web/` | UX pattern |

## Lago (`lago-api/` · AGPL-3.0 · Rails — `lago/` chỉ là VỎ docker)

| Vùng | Đường | Ghi chú |
|---|---|---|
| Models (105) | `app/models/` | `event.rb` · `billable_metric.rb` · `plan.rb` · `charge.rb` · `wallet.rb` |
| Services | `app/services/` | ingest, billing |
| Self-host evidence | `../lago/docker-compose.yml` | đếm service |

## Phía Workizen (đối chiếu)

| Hệ | Đường | Vùng chạm |
|---|---|---|
| Tổng Tài | `~/projects/workizen-tongtai-mobile/lib/features/tongtai/` | commerce · orders · finance/settlement · producer · consumer · core/provenance · attributes |
| AI-WF Runtime | `~/projects/workizen-ai-workforce-runtime/src/` | autonomous/ · evidence/ |
| ADR nền | `docs/03-DECISIONS/` | ADR-TON-016 · 022 · 023 · 024 |
