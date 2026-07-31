# ADR-TON-016 — Capability Context, Rule Twin & AI Runtime Boundary

- **Status:** ✅ ACCEPTED (Founder Decision "Capability-Driven Predictive Foundation", 2026-07-30)
- **Jira:** WTM-149 (Epic) · WTM-150…163
- **Extends:** ADR-TON-011 (BusinessMetricsService = KPI SoT) · ADR-TON-012
  (BusinessContext aggregate root, Progressive Aggregation) · ADR-TON-013
  (staged AI activation, rule twin bắt buộc) · ADR-TON-015 (One Data Path,
  UI maturity)
- **Supersedes:** không. **Ràng buộc mới:** BusinessContext **không được**
  phình thành God Object.

## Vấn đề

Câu hỏi của Founder — *"AI dự đoán được doanh thu và khách rời bỏ không?"* —
lộ ra giới hạn kiến trúc, không phải giới hạn dữ liệu:

`businessContextPromptText` (thứ **duy nhất** AI nhìn thấy) là một snapshot
**phẳng**: doanh thu tổng, số đơn, số khách, AOV, tồn kho, sức khỏe. Không có
chuỗi thời gian, không có recency từng khách. Dù seed 12 tháng dữ liệu, prompt
vẫn **y hệt về hình dạng** — chỉ là con số tổng to hơn. Không thể ngoại suy từ
một con số.

Cách sửa ngây thơ — nhồi thêm chuỗi 12 tháng + danh sách khách vào
BusinessContext — sẽ biến nó thành **God Object**: mỗi capability mới lại phình
thêm một mảng, mọi màn phải tải toàn bộ, prompt AI phình vô hạn.

## Quyết định 1 — Capability Context là đơn vị phân tích

**BusinessContext giữ nguyên vai trò cũ và CHỈ chứa:**

- business identity + metadata (`version`, `generatedAt`)
- `health`
- **lightweight summary** mỗi capability (đếm/tổng, cỡ vài trường)
- current snapshot

**Mọi phân tích chuyên sâu được đóng gói thành Capability Context độc lập**,
tải **on-demand** bởi màn/tính năng cần nó:

| Capability Context | Nội dung |
|---|---|
| `RevenueCapabilityContext` | revenue history, monthly series, order history, billable revenue, AOV, growth, comparison, trend, metadata |
| `CustomerCapabilityContext` | active/new/returning/churned/win-back, recency/frequency/monetary, lifecycle, interaction, segmentation |
| *(mở rộng sau)* | Forecast · Risk · Inventory · Finance · Goal · Opportunity |

**Luật:** một capability mới **không được** thêm mảng dữ liệu nặng vào
BusinessContext. Nó tạo Capability Context riêng và (nếu cần) đóng góp **một
summary nhẹ** vào BusinessContext như hiện nay.

## Quyết định 2 — Đường dữ liệu chuẩn (One Data Path, mở rộng)

```
Repository
   ↓
Aggregation Services          ← thuần, deterministic, không repo/clock nội bộ
   ↓
Capability Context            ← đơn vị phân tích, tải on-demand
   ↓
BusinessContext (summary only)
   ↓
Rule Twin                     ← AUTHORITATIVE
   ↓
AI Router
   ↓
AI                            ← chỉ giải thích
   ↓
(Tool Runtime — OPTIONAL, chưa triển khai)
   ↓
Human
```

**CẤM tuyệt đối:** duplicate aggregation · duplicate summary · duplicate
counting · duplicate repository query. Một phép tính chỉ tồn tại ở **một** nơi
(ví dụ định nghĩa "billable" nằm ở tầng metrics, mọi nơi khác tái dùng).

## Quyết định 3 — Rule Twin là authoritative

Mọi câu trả lời dự báo/rủi ro đến từ **Rule Twin deterministic**, chạy được
khi **không có AI, không có key, không có mạng**.

Contract dùng chung (`lib/features/tongtai/predictive/rule_twin.dart`):

```dart
RuleTwinResult<T>(result, confidence, sufficiency, reasonCodes, version, generatedAt)
```

- `result == null` **khi và chỉ khi** `sufficiency == insufficient` (assert
  trong constructor) — "chưa đủ dữ liệu" không bao giờ giả dạng một dự báo thật.
- `ForecastConfidence` là **dải giải thích được** (none/low/medium/high) suy từ
  độ dài + độ ổn định của lịch sử — **không phải xác suất**.
- `ReasonCode` là hợp đồng chung giữa rule ↔ UI ↔ AI: UI render bản dịch, AI
  giải thích bằng văn xuôi, test assert trên code. Đổi ý nghĩa một code =
  breaking change, phải bump `version`.
- `provenance` chỉ chứa code + dải, **không chứa PII, không chứa số tiền thô** —
  an toàn cho cả prompt AI lẫn telemetry (D-7/ADR-TON-005).

**Không được tạo kết luận giả khi dữ liệu chưa đủ.**

## Quyết định 4 — AI chỉ giải thích

AI đọc **Capability Context + Rule Twin output** (không còn snapshot phẳng).

| AI ĐƯỢC | AI KHÔNG ĐƯỢC |
|---|---|
| giải thích kết quả Rule Twin | sửa forecast |
| mô tả xu hướng | sửa risk |
| tóm tắt | query DB / gọi Repository / đọc Entity |
| gợi ý, action plan | mutate dữ liệu |
| | execute action |

Nếu AI trả về con số khác Rule Twin, **Rule Twin thắng** — test hostile-AI phải
chứng minh điều này (mẫu có sẵn: `business_health_ai` giữ `ruleHealth` verbatim).

## Quyết định 5 — AI Runtime Boundary (thiết kế sẵn, chưa triển khai)

Kiến trúc chừa sẵn chỗ cho `Tool Runtime` **giữa AI và Human**, nhưng
capability này:

- **KHÔNG** triển khai tool calling
- **KHÔNG** ReAct
- **KHÔNG** autonomous agent

Mục đích: sau này mở rộng mà **không phải refactor**. Mở Tool Runtime là quyết
định riêng của Founder (chạm red-line G-3: AI hành động thay vì đọc).

## Hệ quả

- Thư mục mới: `analytics/` (aggregation thuần) · `capability/` (capability
  contexts) · `predictive/` (rule twins).
- `SampleDataSeeder` mở rộng thành generator lịch sử **có tham số**
  (months/seed/profile/seasonality/growth/customer-mix) — vẫn seed vào
  production repository, prefix `sample-`, reset an toàn, **không** tạo demo
  business riêng, **không** parallel state (ADR-TON-014 giữ nguyên).
- UI mới (Revenue Forecast, Customer Risk) tuân thủ ADR-TON-015: đọc production
  providers, `Summary Count == Visible Records`, stable test IDs, l10n key.
- Test bắt buộc trên **SQLite thật + production wiring**; contract test cho
  **AI input** (chứng minh AI không thấy repository/PII ngoài phạm vi cho phép).

## Rủi ro đã cân nhắc

**Nhiều tầng hơn = nhiều chỗ lệch hơn.** Giảm thiểu bằng: aggregation thuần
(dễ test hand-computed), contract test cross-layer, và luật cấm duplicate —
một phép tính sai chỉ sai ở đúng một nơi, sửa một lần.
