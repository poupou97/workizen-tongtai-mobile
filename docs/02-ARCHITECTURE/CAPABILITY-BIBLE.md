# Capability Bible — cách thêm một capability mới

Chuẩn: [ADR-TON-016](../03-DECISIONS/ADR-TON-016-capability-context-and-predictive-foundation.md)
(Capability Context · Rule Twin · AI Runtime Boundary) trên nền
[ADR-TON-012](../03-DECISIONS/ADR-TON-012-business-context-aggregate-root.md)
(Progressive Aggregation) và [ADR-TON-015](../03-DECISIONS/ADR-TON-015-ui-maturity-and-one-data-path.md)
(One Data Path). Đây là tài liệu **thi công**: đọc file này trước khi viết
capability thứ N+1, để Hub / AI Teams / Compute và các vertical khác tái dùng
được cùng một khuôn.

## 1. Đường dữ liệu — không có đường tắt nào khác

```
Repository            dữ liệu thô, đã persist
   ↓
Aggregation Services  thuần, deterministic, KHÔNG đọc clock/repo bên trong
   ↓
Capability Context    đơn vị phân tích, tải ON-DEMAND
   ↓
BusinessContext       CHỈ summary nhẹ (identity · metadata · health · snapshot)
   ↓
Rule Twin             AUTHORITATIVE — chạy không cần AI/mạng/key
   ↓
AI Router → AI        CHỈ giải thích
   ↓
(Tool Runtime)        thiết kế sẵn, CHƯA bật — Founder decision
   ↓
Human
```

**Cấm:** duplicate aggregation · duplicate summary · duplicate counting ·
duplicate repository query. Một phép tính chỉ tồn tại ở đúng một nơi.

Ví dụ thật: định nghĩa "billable" từng bị chép tay ở **6 chỗ**; nay là
`isBillableOrder` + extension `.billable` trong `metrics/business_metrics.dart`,
mọi tầng khác tái dùng.

## 2. Bốn tầng, bốn thư mục

| Tầng | Thư mục | Đặc tính bắt buộc |
|---|---|---|
| Aggregation | `lib/features/tongtai/analytics/` | hàm thuần; `now` luôn là **tham số**; input rỗng → cấu trúc rỗng hợp lệ, không throw |
| Capability Context | `lib/features/tongtai/capability/` | value object read-only; `hasData` trung thực; `promptBlock()` **không PII** |
| Rule Twin | `lib/features/tongtai/predictive/` | trả `RuleTwinResult`; không AI/mạng/key; không bịa kết luận |
| AI | `lib/features/tongtai/ai/` | chỉ giải thích; số liệu **copy** từ twin, không parse từ text model |

## 3. Công thức thêm capability mới (6 bước)

**B1 — Aggregation.** Viết hàm thuần trong `analytics/`. Nếu cần một con số mà
analytics chưa có: **thêm vào analytics + test**, tuyệt đối không tính tay
trong capability/rule/UI.

**B2 — Capability Context.** Implement:

```dart
abstract class CapabilityContext {
  String get capability;   // 'revenue', 'customer', …
  int get version;         // schema version của RIÊNG capability này
  DateTime get generatedAt;
  bool get hasData;
  String promptBlock();    // PII-free, dành cho AI
}
```
+ một `CapabilityContextProvider<T>` nhận repository + `DateTime Function() clock`.

**B3 — Riverpod provider** trong `providers/tongtai_capability_provider.dart`,
kiểu `FutureProvider`, **on-demand**. KHÔNG nối vào `BusinessContextService`
(đó là cách BusinessContext phình thành God Object).

**B4 — Rule Twin** trong `predictive/`, trả `RuleTwinResult<T>`:

```dart
RuleTwinResult(result, confidence, sufficiency, reasonCodes, version, generatedAt)
```
- `result == null` **⟺** `sufficiency == insufficient` (assert trong constructor).
- `reasonCodes` không bao giờ rỗng, xếp theo mức quan trọng giảm dần.
- `version` dạng `'<tên>/<số>'`, ví dụ `revenue-forecast/1`.
- Thêm ReasonCode mới = additive; **đổi ý nghĩa** một code = breaking → bump version.

**B5 — UI** (Level ≥ 2 theo ADR-TON-015): đọc production provider, mọi chuỗi qua
`AppStrings` key, stable test ID `<screen>-<role>`, đăng ký màn vào
`p0/stable_test_ids_test.dart` + `overflow_test.dart` + `nav_availability_test.dart`
**trong cùng PR**. Trạng thái `insufficient` phải hiện **lời từ chối + lý do**,
tuyệt đối không render số 0 giả làm như đã dự báo.

**B6 — AI (tuỳ chọn).** Chỉ giải thích: prompt = `promptBlock()` + rule block;
`ruleVersion`/`reasonCodes` copy nguyên từ twin; có bản giải thích rule-based
chạy khi không key/không mạng/insufficient (**zero provider spend**).

## 4. Ranh giới không được vượt

| Được | Không được |
|---|---|
| Capability đọc repository của chính nó | Capability đọc repository của capability khác *(dùng aggregation chung)* |
| BusinessContext nhận **summary nhẹ** | BusinessContext nhận mảng nặng / chuỗi thời gian / danh sách khách |
| AI đọc Capability Context + Rule Twin output | AI đọc Repository/Entity/DB; AI sửa số; AI mutate/execute |
| Rule Twin nói "chưa đủ dữ liệu" | Rule Twin bịa số khi thiếu dữ liệu |
| UI join id → tên từ repository | Twin/AI mang tên/SĐT/email khách |

## 5. Test bắt buộc cho một capability

| Loại | Yêu cầu |
|---|---|
| Aggregation | giá trị **tính tay**, biên tháng (`00:00` ngày 1 và `23:59` ngày cuối), input rỗng |
| Capability | qua provider thật + in-memory repo; `hasData` sai/đúng; `promptBlock()` không chứa tên/SĐT của fixture |
| Rule Twin | mọi ngưỡng sufficiency (2↔3, 5↔6, 11↔12 tháng…); determinism; envelope assert |
| Contract | `Summary Count == Domain Visible Records` (helper `test/support/count_list_contract.dart`) |
| AI input | prompt chứa đúng 2 khối; **không** PII; hostile-AI không đổi được số |
| Edge | file SQLite thật · restart · reset sample · user data cùng tồn tại · timezone |

## 6. Capability đã có

| Capability | Context | Rule Twin | UI | AI |
|---|---|---|---|---|
| Revenue | `RevenueCapabilityContext` | `RevenueForecastRule` (`revenue-forecast/1`) | Dự báo doanh thu | giải thích |
| Customer | `CustomerCapabilityContext` | `CustomerRiskRule` (`customer-risk/1`) | Rủi ro khách hàng | giải thích |
| Business (cross) | *(dùng 2 context trên)* | `BusinessAlertsRule` (`business-alerts/1`) | *(chưa có màn riêng)* | giải thích |

Kế tiếp theo ADR-TON-016: Forecast · Risk · Inventory · Finance · Goal ·
Opportunity — mỗi cái theo đúng 6 bước trên.
