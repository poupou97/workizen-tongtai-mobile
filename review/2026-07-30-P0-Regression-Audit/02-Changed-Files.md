# 02 — Changed Files | Mọi file thay đổi + lý do

Diffs đầy đủ trong `06-Diff/` (một file .diff cho mỗi PR). Dưới đây là giải
thích theo nhóm — mọi file xuất hiện trong 5 PR đều thuộc đúng một nhóm.

## PR #66 (`215a232`) — WTM-144: create actions luôn hiện diện (§1.6)

| File | Lý do |
|---|---|
| `lib/features/tongtai/ui/screens/tongtai_home_screen.dart` | Thêm 4 quick-action chips (`home-quick-customer/product/order/goal`) khi business có dữ liệu — trước đó nút create "biến mất" sau bản ghi đầu (onboarding-gated), Founder tưởng bị xoá |
| `lib/features/tongtai/ui/screens/tongtai_more_screen.dart` | Entry Demo cố định trong More (không còn phụ thuộc empty-state) |
| `test/features/tongtai/tongtai_home_screen_test.dart` | Test khoá hành vi: quick actions hiện với dữ liệu, CTA hiện khi trống |

## PR #67 (`8b1e1d8`) — WTM-144: one source (§1 core, ADR-TON-014)

| File | Lý do |
|---|---|
| `lib/features/tongtai/sample/sample_data_seeder.dart` (MỚI) | `SampleDataSeeder`: seed fixtures VÀO production repos với prefix `sample-`; idempotent (remove-then-insert); remap link order→customer; `removeAll()` chỉ xoá prefix; `hasSamples()` |
| `lib/features/tongtai/providers/tongtai_sample_provider.dart` (MỚI) | Provider dựng seeder trên 5 repository providers thật |
| 5× repository (`customer/product/order/business_goal/finance_repository.dart`) | Thêm seam `deleteByIdPrefix(prefix)` (interface + Drift + InMemory + Sample) |
| 5× model (`customer/product/order/business_goal/finance_transaction.dart`) | `withId`/`withIds` remap helpers cho seeder |
| `lib/features/tongtai/ui/screens/tongtai_home_screen.dart` | XOÁ `.demo()`/`isDemo`/banner WTM-143 → một Home duy nhất; `home-sample-banner` khi có sample; CTA demo seed tại chỗ; Top-Opportunities đọc generated |
| `lib/features/tongtai/ui/screens/tongtai_more_screen.dart` | Nạp/Xóa mẫu với dialog xác nhận (`more-demo-confirm`, `more-remove-sample-confirm`) |
| `lib/features/tongtai/ai/workizen_ai_context.dart` | Builder defaults RỖNG — AI không bao giờ trả lời từ fixture ngầm |
| `lib/features/tongtai/providers/tongtai_chat_provider.dart` | `_RealDataChatResponder`: mỗi lượt chat load customers/products/orders từ repos thật |
| `lib/features/tongtai/ui/screens/tongtai_export_screen.dart` | Export đọc repos thật (bug: từng xuất fixture CSV) |
| `lib/features/tongtai/ui/screens/tongtai_timeline_screen.dart` | Timeline build từ finance/order/goal repos + generated opportunities (bug: từng hiện sự kiện mẫu) |
| `lib/features/tongtai/ui/screens/tongtai_reports_screen.dart` | Bỏ sample-pipeline fallback |
| `test/features/tongtai/p0/sample_data_seeder_test.dart` (MỚI) | 5 test lifecycle: counts+prefix, link remap, idempotent, removeAll giữ user, edit-sample-then-remove |
| `test/features/tongtai/p0/one_source_consistency_test.dart` (MỚI) | Cross-screen ≡ BusinessContext ≡ repos; Opportunity e2e; ACCEPTANCE fresh→seed→create→edit→remove→restart |
| `test/features/tongtai/tongtai_home_screen_test.dart` | Viết lại production-wiring: shared in-memory repos, CÙNG container cho screen + assertions |
| `test/features/tongtai/tongtai_csv_export_test.dart`, `tongtai_workizen_ai_router_test.dart`, `tongtai_reports_screen_test.dart` | Inject fixtures TƯỜNG MINH (governance: không còn default ngầm) |
| `docs/03-DECISIONS/ADR-TON-014-sample-data-seeding.md` (MỚI) + ADR-INDEX + CURRENT-STATUS | Ghi quyết định |

## PR #68 (`67ffb0f`) — WTM-145 phase 1: cấm label song ngữ (§2)

| File | Lý do |
|---|---|
| `lib/core/l10n/app_strings.dart` | +37 key VI/EN (titles, More, KPI, sections, AI actions/results…) |
| 8× screens (home, more, reports, finance, timeline, goal_detail, opportunity_detail…) | Mọi nhãn " · " 2 ngôn ngữ → `context.l10n.<key>` |
| `test/features/tongtai/p0/localization_test.dart` (MỚI) | 4 lock: bilingual-scan (fail trên code cũ) · unused-key · vi≠en · switch runtime + persist |
| 4× test files | Assertion sang chuỗi đơn-locale |

## PR #70 (`2ee7b6c`) — WTM-145 phase 2: migrate toàn bộ (§2)

| File | Lý do |
|---|---|
| `lib/core/l10n/app_strings.dart` | +~110 key + methods có tham số + `languageCode` |
| 19× screens | ~173 literal VI + " \| " pipes + empty-state 2 dòng song ngữ → keys |
| `lib/features/tongtai/consumer/customer_directory_service.dart`, `inventory/product_inventory_service.dart` | CustomerSort/ProductSort thêm `labelVi` + `label(languageCode)` |
| `lib/features/tongtai/ui/...` (8 file labelEn trực tiếp) | `label(context.l10n.languageCode)` thay labelVi/labelEn |
| `.github/workflows/ci.yml` | +`workflow_dispatch` (sự cố GitHub trễ deliver pull_request events — xem 07) |
| `test/features/tongtai/p0/localization_test.dart` | +3 lock: ban " \| ", ban chuỗi VN trong ui/, ban labelVi/labelEn trong ui/ |
| ~10× test files | Assertion EN đơn-locale |

## PR #71 (`3c851d2`) — WTM-146: test governance (§3)

| File | Lý do |
|---|---|
| `lib/features/tongtai/sample/sample_data_seeder.dart` | **BUG THẬT:** removeAll xoá orders TRƯỚC customers (FK 787 trên SQLite thật) |
| `lib/features/tongtai/ui/screens/tongtai_home_screen.dart` | **BUG THẬT:** 3 điểm overflow @320px/1.3× → Flexible+FittedBox |
| `lib/features/tongtai/ui/screens/tongtai_reports_screen.dart`, `tongtai_customer_history_screen.dart` | Kill 2 fallback `.sample()` tiềm ẩn → rỗng, không bao giờ fixture |
| `lib/features/tongtai/ui/tongtai_bottom_nav.dart` | 5 nav label → keys |
| `lib/core/l10n/app_strings.dart` | +~140 key (EN chrome sweep + nav + lifecycle + form/save…) |
| 20× screens | ~180 EN-literal chrome → keys (EN value GIỮ NGUYÊN — không đổi hành vi EN); More entries có Keys ổn định |
| `lib/features/tongtai/timeline/business_event.dart` | BusinessEventType + labelEn + label() |
| `test/features/tongtai/p0/` +5 suite MỚI | sample_fallback_scan · l10n_placeholder · nav_availability · overflow · drift_restart |
| `test/features/tongtai/p0/localization_test.dart` | Lock #8: KHÔNG literal trong mọi vị trí text của ui/ |
| `docs/03-DECISIONS/ADR-TON-014-...md`, `docs/00-START-HERE/CURRENT-STATUS.md` | Ghi FK-order + trạng thái §3 |
| 3× test files | Thu/Chi→Income/Expense (EN), Purchase history case |

## Không đổi (chủ đích)

- `tongtai_component_showcase_screen.dart` — dev-only, KHÔNG reachable từ
  production navigation (đã verify bằng grep); exclude khỏi scan, ứng viên xoá.
- Supplier catalog data (`kSampleSuppliers`) — curated directory Phase 2.
- Domain content tiếng Việt (rule summaries, event titles, fixtures) — là data.
