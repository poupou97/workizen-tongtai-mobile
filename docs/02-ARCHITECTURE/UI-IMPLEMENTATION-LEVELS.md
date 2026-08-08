# UI Implementation Levels — ma trận sống

Chuẩn: [ADR-TON-015](../03-DECISIONS/ADR-TON-015-ui-maturity-and-one-data-path.md).
Cập nhật **cùng PR** mỗi khi một màn đổi level. Level = sự thật đo được từ
code, không phải ý định. Audit gần nhất: **2026-08-01** (38 màn + 3 shell — WTM-187 thêm `tongtai_journey_screen` (L3) — WTM-175 thêm `tongtai_feedback_screen`, WTM-177 thêm `tongtai_business_profile_screen`, WTM-178 thay onboarding slide bằng `tongtai_onboarding_conversation_screen`; cả ba L3).

## ⛔ Điều kiện đứng trước mọi level — Journey Reachability (Founder 2026-08-02)

**Mọi màn L2+ phải chứng minh được một User Journey dẫn tới nó**, hoặc mang
nhãn **Future Capability / Intentionally Hidden kèm lý do**. Khoá bằng
`test/features/tongtai/p0/journey_reachability_test.dart` — mức L khai trong
suite đó phải khớp bảng dưới đây, và **màn mới không khai mức ⇒ CI đỏ** (việc
khai buộc phải trả lời "người bán tới đây bằng đường nào" trước khi bàn tới
l10n/a11y).

Vì sao đứng trước: WTM-218 tìm ra `tongtai_supplier_search_screen` — L3 đầy
đủ test/a11y/l10n, được **sáu** lượt governance đánh bóng — mà **chưa bao giờ
có lối vào**. Level đo chất lượng một màn; nó không đo việc màn đó có tồn tại
với người bán hay không.

## Cách đọc

- **Data**: nguồn dữ liệu thật (repo/provider) hay nhận qua constructor từ
  luồng production.
- **CRUD**: có tạo/sửa/xoá đầy đủ trong luồng của màn.
- **Keys**: có stable test IDs theo quy ước `<screen>-<role>`.
- **Err**: có xử lý lỗi hiển thị cho người dùng khi data path hỏng.
- **→ Next**: điều kiện còn thiếu để lên level kế tiếp.

## Phát hiện hệ thống — và cách nó được đóng lại

**Audit 2026-07-30:** chỉ **1/34 màn** có error handling thật
(`tongtai_ai_key_screen`). Mọi màn khác nếu repository/IO ném lỗi sẽ hiện
trạng thái rỗng im lặng — đúng lớp lỗi "không phân biệt được *không có dữ liệu*
với *không đọc được dữ liệu*" đã sinh ra bug Consumer.

**WTM-148 (2026-07-31) đã đóng gap này** bằng **seam dùng chung**
([ADR-TON-017](../03-DECISIONS/ADR-TON-017-error-handling-seam.md)):
`ScreenState` sáu trạng thái · `TongtaiFailure` phân loại · `ScreenDataController`
(refresh lỗi giữ dữ liệu cũ) · `runTongtaiAction` (ghi không im lặng) ·
`TongtaiScreenData`/`TongtaiAsyncScreenData` (một cách render, stable key).
**22 màn** tham chiếu seam; governance test chặn màn tự chế lại
(`p0/error_handling_governance_test.dart`).

## Ma trận

### L4 — AI Enabled

| Màn | Data | CRUD | Keys | Err | Ghi chú |
|---|---|---|---|---|---|
| `tongtai_reports_screen` | BusinessContext + BusinessMetrics + orders repo | – | ✅ 19 | ✅ seam | AI G-3A→D đã ship, mỗi tính năng có rule twin |
| `tongtai_opportunity_detail_screen` | generated opportunities + goal repo + journey repo | tạo goal · **đưa vào hành trình** (cả hai guarded) | ✅ 11 | ✅ seam | AI insight (WTM-141) + rule score authoritative · WTM-191: cơ hội → node `origin = user`, chưa có hành trình thì **nói phải làm gì trước** |

### L3 — Interactive (đủ CRUD + error handling)

| Màn | Data | Err qua seam | Ghi chú |
|---|---|---|---|
| `tongtai_home_screen` | BusinessContext + 5 nguồn, một `_HomeData` **+ `businessBriefProvider`** | `ScreenDataController` + `runTongtaiAction` (seed) | KPI = 0 do đọc hỏng nay là **failed**, không phải "doanh thu 0 ₫". **WTM-304:** thẻ brief nằm ngay dưới hero, **trên** mọi ô số — nó tự lo trạng thái riêng vì đọc theo nhịp khác (Rule Twin trên toàn sổ sách, không phải 5 con số của Home) |
| `tongtai_consumer_screen` | customerRepository | `ScreenDataController` | màn của bug gốc — có suite hành vi riêng |
| `tongtai_producer_screen` | favorites store + generated opportunities | `ScreenDataController` | hai nguồn, một trạng thái |
| `tongtai_inventory_screen` | productRepository | `ScreenDataController` + guarded upsert | |
| `tongtai_customer_list_screen` | customer + order + product repo | `ScreenDataController` + guarded upsert | |
| `tongtai_goals_screen` | goal repo + orders | `ScreenDataController` + guarded upsert | |
| `tongtai_finance_screen` | financeRepository | `ScreenDataController` + guarded add | |
| `tongtai_timeline_screen` | 4 repo (derived projection) | `ScreenDataController` | |
| `tongtai_opportunity_feed_screen` | generated opportunities **+ phản ứng đã lưu** | `ScreenDataController` | WTM-190: lưu/gạt bỏ sống sót qua lần đóng app. **WTM-192: là TAB thứ 5** (Founder chọn phương án B) — Home/Reports **chuyển tab** chứ không push bản sao |
| `tongtai_forecast_screen` | RevenueCapabilityContext + Rule Twin | `TongtaiAsyncScreenData` | `insufficient` ≠ `failed` ≠ `empty` |
| `tongtai_customer_risk_screen` | CustomerCapabilityContext + Rule Twin + customer repo | `TongtaiAsyncScreenData` | khách rỗng = **empty**, không phải từ chối |
| `tongtai_agent_screen` | `businessBriefProvider` (Rule Twin → BriefItem) + `briefDecisionsProvider` | `TongtaiAsyncScreenData` | **WTM-304 · Epic WTM-302.** Nơi ở của agent. `empty` = *chưa có việc nào cần bạn quyết* (một **tin tốt**, không phải lỗi) ≠ `failed` = *chưa tính được*. Hàng dựng bằng widget dùng chung với thẻ brief trên Home — một khách không thể được hai bề mặt mô tả khác nhau |
| `tongtai_brief_story_screen` | `BriefItem` truyền vào + `briefInboxProvider` (ghi) | `runTongtaiAction` ×3 | **WTM-305 · trải nghiệm #2.** `WHAT → WHY → SUGGEST → DECIDED → NEXT` trên một màn. **Ba** nút, không hai: *Để sau* tạo `AgentTask` thật, nên một việc chưa nghĩ xong không bị ép thành "bỏ qua". Nhãn **diễn tập** đọc từ chính `vendor`+kết quả, không từ một cờ riêng của màn |
| `tongtai_activity_screen` | `agentActivityProvider` (3 bảng vòng đời + số bản ghi đã quét) | `runTongtaiAction` (runner) + `TongtaiAsyncScreenData` | **WTM-305 · trải nghiệm #5.** Gộp theo **ngày**, không theo loại — người bán nhớ "hôm nay tôi đã làm gì". Không dòng nào chứa tên bảng/mã lỗi/id; có test khoá. **WTM-307:** mang **Runner V1** — tự chạy một lượt khi mở màn, và một nút chạy tay để Founder *nhìn thấy* `scheduled → claimed → processed → recheck`. Một lượt runner đóng việc ⇒ phát `invalidateBusinessDataProviders` (governance `business_loop` bắt được thiếu sót này) |
| `tongtai_autonomy_screen` | `autonomySettingsProvider` (prefs) | trực tiếp (ghi prefs) | **WTM-306 · trải nghiệm #4 + #3.** ⛔ Bảy việc cấm auto **không chọn được** — chặn bằng `enabled:`, không bằng một dòng cảnh báo. Khối *"Luôn hỏi bạn"* liệt kê chúng ra, nhìn thấy được và không tắt được. `Tự động` mang nhãn **Xem trước** vì chưa có runner nền. Thẻ orchestration đọc **cùng** cấu hình nên gạt công tắc là thấy dòng `APPROVAL` đổi |
| `tongtai_export_screen` | 3 repo + history store | `ScreenDataController` + guarded export | sửa `try/finally` **không có catch** |
| `tongtai_more_screen` | seeder + prefs | `runTongtaiAction` ×3 | invalidate cache **chỉ khi ghi thành công** |
| `tongtai_chat_screen` | chat store + 3 repo | `ScreenDataController` + guarded attach | ảnh bị từ chối quyền nay báo rõ |
| `tongtai_chat_search_screen` | chat store | `ScreenDataController` | bỏ `_searchToken` tự chế — seam lo drop response cũ |
| `tongtai_unified_search_screen` | FTS5 + history + favorites | `TongtaiFailureView` + controller mang `failure` | FTS hỏng từng làm spinner quay mãi |
| `tongtai_customer_history_screen` | orderController thật | `runTongtaiAction` | đơn vừa nhập không thể mất im lặng |
| `tongtai_business_profile_screen` | `businessProfileProvider` (1 dòng, 4 enum) | `runTongtaiAction` + `showTongtaiFailure` | WTM-177. Đọc một lần, không có đường refresh và không có trạng thái *stale* để giữ ⇒ `ScreenDataController` sẽ là nghi thức thừa. **Không có TextField nào** — có test khoá |
| `tongtai_feedback_screen` | không đọc dữ liệu (chỉ ghi ra share sheet) | `runTongtaiAction` + `showTongtaiFailure` | WTM-175. Share thất bại có snack lỗi + nút bật lại |
| `tongtai_journey_screen` | `journeysProvider` (cây node + plan version) | `TongtaiAsyncScreenData` | WTM-187. Ba trạng thái **phân biệt rõ**: `empty` (chưa có hành trình) ≠ `insufficient` (có hành trình nhưng chưa lập được kế hoạch) ≠ `failed`. Mỗi bước hiện **nguồn gốc** (`ruleTwin`) và **cách đo** (`derived`) — không có nhãn đó thì ranh giới ADR-TON-016 vô hình đúng chỗ quan trọng nhất. WTM-191: node đến từ cơ hội có nhãn riêng, nếu không nó đọc như một milestone do rule nghĩ ra |
| `tongtai_onboarding_conversation_screen` | không đọc; ghi `BusinessProfile` khi kết thúc | `runTongtaiAction` + `showTongtaiFailure` | WTM-178, thay 6 slide tĩnh. **Chạy trọn vẹn không cần AI** — kịch bản tất định. Ghi lỗi **không chặn** người dùng mới vào app |
| `tongtai_supplier_search_screen` | curated catalog + favorites persisted | `runTongtaiAction` (toggle) | |
| `tongtai_supplier_favorites_screen` | favorites persisted | `runTongtaiAction` (toggle) | |
| `tongtai_business_inputs_screen` | `businessInputRepositoryProvider` | `ScreenDataController` + `runTongtaiAction` (lưu/xoá) | WTM-234. Tổng cam kết **suy tại chỗ đọc** (`BusinessInputSummary`), không lưu cột tổng — và luôn hiện kèm số nguồn chưa cộng được: một tổng không tự khai mình thiếu gì sẽ được đọc như một tổng đầy đủ |
| `tongtai_ai_key_screen` | secure storage (BYOK) | `runTongtaiAction` | `TongtaiAiException` nay là `TongtaiClassifiedError` |
| `tongtai_key_scan_screen` | camera | `errorBuilder` → `TongtaiFailureView` | camera bị từ chối nay có màn lỗi, không phải khung đen |

### L2 — Production Data (không có đường IO riêng để hỏng)

Các màn dưới đây **không tự đọc/ghi IO**: chúng nhận dữ liệu qua constructor từ
một màn L3 và trả kết quả về cho màn đó ghi (nơi ghi đã được `runTongtaiAction`
bảo vệ). Chúng lên L3 khi/nếu tự chạm IO.

| Màn | Nguồn | Ghi ở đâu |
|---|---|---|
| `tongtai_create_order_screen` | products inject | `customer_history` ghi (guarded) |
| `tongtai_customer_form_screen` | form → parent | `customer_list` ghi (guarded) |
| `tongtai_product_form_screen` | form → parent | `inventory` ghi (guarded) |
| `tongtai_goal_form_screen` | form → parent | `goals` ghi (guarded) |
| `tongtai_transaction_form_screen` | form → parent | `finance` ghi (guarded) |
| `tongtai_goal_detail_screen` | goal + realized revenue inject | read-only |
| `tongtai_inventory_picker_screen` | products inject | read-only |
| `tongtai_stock_alerts_screen` | catalog inject (derived) | catalog chung với `inventory` |
| `tongtai_supplier_detail_screen` | catalog profile inject | read-only |
| `tongtai_business_input_form_screen` | form → parent | `business_inputs` ghi (guarded) |

### L1 — Static UI

*Trống.* `tongtai_component_showcase_screen` — màn duy nhất từng ở mức này —
**đã xoá ở WTM-217**: dev-only, không route nào tới được, và đang mua hai
ngoại lệ file trong lưới l10n. Nguồn sự thật của design system là
`tongtai_design_tokens.dart`; lịch sử git giữ lại màn catalogue nếu cần dựng
lại. (Bước 4 Shift Priority: loại bỏ màn không nhất quán với Concept.)

### Không áp dụng (chrome/nav, không mang business data)

`tongtai_app_shell` · `tongtai_bottom_nav` · `tongtai_root_gate` ·
`tongtai_onboarding_screen` (nội dung hướng dẫn tĩnh theo thiết kế;
persistence do RootGate giữ).

## Ánh xạ Jira

| Level thật | Story Jira liên quan (label `IMPLEMENTATION_LEVEL`) |
|---|---|
| L4 | WTM-95/96/97 (Reports) · WTM-91/92 (Opportunity detail) |
| L3 | WTM-24 (Producer) · WTM-26 (Consumer) · WTM-25/68 (Inventory) · WTM-75 (Customer list) · WTM-87/89 (Journey) · WTM-27/113 (Finance) · WTM-99/100 (Export) · WTM-80/84 (Chat) · WTM-73 (Search) · WTM-63/64/65 (Supplier) · WTM-114 (Timeline) · WTM-160/161 (Forecast/Risk) · WTM-61/83 (AI key BYOK) |
| L2 | form/picker/detail screens — nhận dữ liệu qua constructor, không tự chạm IO |
| L1 | WTM-12/13/17/18/20/22/23 (component design stories — chưa production) |

**Luật:** không đóng story ở level cao hơn ma trận này.
