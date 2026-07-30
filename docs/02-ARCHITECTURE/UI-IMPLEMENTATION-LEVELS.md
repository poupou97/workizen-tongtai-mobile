# UI Implementation Levels — ma trận sống

Chuẩn: [ADR-TON-015](../03-DECISIONS/ADR-TON-015-ui-maturity-and-one-data-path.md).
Cập nhật **cùng PR** mỗi khi một màn đổi level. Level = sự thật đo được từ
code, không phải ý định. Audit gần nhất: **2026-07-30** (34 màn + 3 shell — +2 màn predictive WTM-160/161).

## Cách đọc

- **Data**: nguồn dữ liệu thật (repo/provider) hay nhận qua constructor từ
  luồng production.
- **CRUD**: có tạo/sửa/xoá đầy đủ trong luồng của màn.
- **Keys**: có stable test IDs theo quy ước `<screen>-<role>`.
- **Err**: có xử lý lỗi hiển thị cho người dùng khi data path hỏng.
- **→ Next**: điều kiện còn thiếu để lên level kế tiếp.

## Phát hiện hệ thống (2026-07-30)

**Chỉ 1/32 màn có error handling thật** (`tongtai_ai_key_screen`). Mọi màn
khác nếu repository/IO ném lỗi sẽ hiện trạng thái rỗng im lặng — đúng lớp lỗi
"không phân biệt được *không có dữ liệu* với *không đọc được dữ liệu*" đã sinh
ra bug Consumer. Vì vậy phần lớn màn dừng ở **L2 (+CRUD)**, chưa phải L3.

→ Một backlog item hệ thống (**WTM-148**) — seam xử lý lỗi dùng chung cho mọi
màn — sẽ nâng ~25 màn từ L2 lên L3 cùng lúc. Đây là nợ **hiện**, không phải nợ ẩn.

## Ma trận

### L4 — AI Enabled
*(chưa màn nào đạt: tính năng AI đã ship nhưng L3 chưa xong — xem 2 màn dưới)*

### L2 + AI shipped (lên L4 ngay khi L3 error handling xong)

| Màn | Data | CRUD | Keys | Err | → Next |
|---|---|---|---|---|---|
| `tongtai_reports_screen` | BusinessContext + BusinessMetrics + orders repo | – | ✅ 19 | ❌ | error handling → L3 → L4 (AI G-3A→D đã ship, có rule twin) |
| `tongtai_opportunity_detail_screen` | generated opportunities + goal repo | tạo goal | ✅ 9 | ❌ | error handling → L3 → L4 (AI insight đã ship) |

### L3 — Interactive (đủ CRUD + error handling)

| Màn | Data | CRUD | Keys | Err | Ghi chú |
|---|---|---|---|---|---|
| `tongtai_ai_key_screen` | secure storage (BYOK) | lưu/đổi/xoá khoá | ✅ 8 | ✅ | mẫu chuẩn: `catch (TongtaiAiException)` → status hiển thị |

### L2 — Production Data (số liệu đúng nguồn; phần lớn có CRUD, thiếu error handling)

| Màn | Data | CRUD | Keys | → L3 |
|---|---|---|---|---|
| `tongtai_home_screen` | BusinessContext + 5 repo + favorites | qua nav | ✅ 21 | error handling |
| `tongtai_forecast_screen` | RevenueCapabilityContext + RevenueForecastRule (on-demand) | – | ✅ | error handling *(mới 2026-07-30, WTM-160)* |
| `tongtai_customer_risk_screen` | CustomerCapabilityContext + CustomerRiskRule + customerRepository (join id→tên) | – | ✅ | error handling *(mới 2026-07-30, WTM-161)* |
| `tongtai_consumer_screen` | customerRepository | qua list | ✅ | error handling *(sửa 2026-07-30: từng là L1 static shell)* |
| `tongtai_producer_screen` | favorites store + generated opportunities | qua favorites | ✅ | error handling *(sửa 2026-07-30: từng là L1 static shell)* |
| `tongtai_inventory_screen` | productRepository | ✅ thêm/sửa/xoá | ✅ | error handling |
| `tongtai_customer_list_screen` | customer + order + product repo | ✅ | ✅ | error handling |
| `tongtai_goals_screen` | goal repo + orders (auto-derive) | ✅ | ✅ | error handling |
| `tongtai_finance_screen` | financeRepository | ✅ ghi giao dịch | ✅ 6 | error handling |
| `tongtai_timeline_screen` | finance/order/goal repo + opportunities | read-only | ✅ 2 | error handling |
| `tongtai_opportunity_feed_screen` | generated opportunities | quan tâm/bỏ qua | ✅ 5 | error handling |
| `tongtai_export_screen` | 3 repo thật | xuất + mã hoá | ✅ 5 | `try/finally` **không có catch** → error handling |
| `tongtai_more_screen` | seeder + prefs | seed/xoá mẫu | ✅ 12 | error handling |
| `tongtai_chat_screen` | chat store + 3 repo (per-turn context) | gửi/xoá | ✅ 8 | error handling |
| `tongtai_chat_search_screen` | chat store (inject từ chat) | – | ✅ 5 | error handling |
| `tongtai_unified_search_screen` | FTS5 + history + favorites store | – | ✅ | error handling |
| `tongtai_customer_history_screen` | orderController thật | tạo đơn | ✅ 4 | error handling |
| `tongtai_create_order_screen` | products thật (inject) | tạo đơn | ✅ 8 | error handling |
| `tongtai_customer_form_screen` | form → parent persist | ✅ | ✅ 13 | error handling |
| `tongtai_product_form_screen` | form → parent persist | ✅ | ✅ 7 | error handling |
| `tongtai_goal_form_screen` | form → parent persist | ✅ | ✅ 14 | error handling |
| `tongtai_transaction_form_screen` | form → parent persist | ✅ | ✅ 7 | error handling |
| `tongtai_goal_detail_screen` | goal thật + realized revenue | sửa qua form | ✅ 4 | error handling |
| `tongtai_inventory_picker_screen` | products thật (inject) | chọn | ✅ | error handling |
| `tongtai_stock_alerts_screen` | catalog thật (derived) | – | ✅ | error handling |
| `tongtai_supplier_search_screen` | curated catalog (Phase 2) + favorites persisted | ✅ favorite | ✅ | error handling |
| `tongtai_supplier_favorites_screen` | favorites persisted | ✅ bỏ favorite | ✅ | error handling |
| `tongtai_supplier_detail_screen` | catalog profile (inject) | – | ✅ | error handling |
| `tongtai_key_scan_screen` | camera → trả khoá (không có business data) | – | – | error handling khi camera lỗi |

### L1 — Static UI

| Màn | Tình trạng |
|---|---|
| `tongtai_component_showcase_screen` | **dev-only, KHÔNG reachable** từ navigation production (đã verify bằng grep). Ứng viên xoá — nếu giữ phải đánh dấu rõ là dev tool. |

### Không áp dụng (chrome/nav, không mang business data)

`tongtai_app_shell` · `tongtai_bottom_nav` · `tongtai_root_gate` ·
`tongtai_onboarding_screen` (nội dung hướng dẫn tĩnh theo thiết kế;
persistence do RootGate giữ).

## Ánh xạ Jira

| Level thật | Story Jira liên quan (label `IMPLEMENTATION_LEVEL`) |
|---|---|
| L2 | WTM-24 (Producer) · WTM-26 (Consumer) · WTM-25/68 (Inventory) · WTM-75 (Customer list) · WTM-87/89 (Journey) · WTM-27/113 (Finance) · WTM-95/96/97 (Home/Reports) · WTM-91/92 (Opportunity) · WTM-99/100 (Export) · WTM-80/84 (Chat) · WTM-73 (Search) · WTM-63/64/65 (Supplier) · WTM-114 (Timeline) |
| L3 | WTM-61/83 (AI key BYOK) |
| L1 | WTM-12/13/17/18/20/22/23 (component design stories — chưa production) |

**Luật:** không đóng story ở level cao hơn ma trận này.
