# 02 — Architecture Decisions

Nguồn: [ADR-TON-016](../../docs/03-DECISIONS/ADR-TON-016-capability-context-and-predictive-foundation.md)
· thi công: [CAPABILITY-BIBLE](../../docs/02-ARCHITECTURE/CAPABILITY-BIBLE.md)
· ma trận AI: [AI-CAPABILITY-MATRIX phần B](../../docs/02-ARCHITECTURE/AI-CAPABILITY-MATRIX.md)

## QĐ-1 — Capability Context là đơn vị phân tích

BusinessContext **chỉ** giữ: identity · metadata · health · **summary nhẹ** ·
current snapshot. Mọi phân tích chuyên sâu đóng gói thành Capability Context
độc lập, **tải on-demand**.

*Vì sao:* cách sửa ngây thơ (nhồi chuỗi 12 tháng + danh sách khách vào
BusinessContext) biến nó thành **God Object** — mỗi capability mới lại phình
thêm một mảng, mọi màn phải tải toàn bộ, prompt AI phình vô hạn.

*Đã làm:* `RevenueCapabilityContext`, `CustomerCapabilityContext` +
`revenueCapabilityProvider`, `customerCapabilityProvider` — **không** nối vào
`BusinessContextService`.

## QĐ-2 — One Data Path (mở rộng ADR-TON-015)

```
Repository → Aggregation Services → Capability Context → BusinessContext (summary)
          → Rule Twin → AI Router → AI → (Tool Runtime optional) → Human
```

**Cấm:** duplicate aggregation · summary · counting · repository query.

*Bằng chứng tuân thủ:* `isBillableOrder` từng bị chép tay ở 6 chỗ → gom về
`metrics/business_metrics.dart`, mọi tầng tái dùng.

## QĐ-3 — Rule Twin là authoritative

```dart
RuleTwinResult<T>(result, confidence, sufficiency, reasonCodes, version, generatedAt)
```
- `result == null` **⟺** `sufficiency == insufficient` — **assert trong
  constructor**, nên "chưa đủ dữ liệu" không thể giả dạng dự báo (Testing Bible P-08).
- `ForecastConfidence` là **dải giải thích được**, không phải xác suất.
- `ReasonCode` = hợp đồng chung rule ↔ UI ↔ AI; đổi ý nghĩa = bump `version`.
- `provenance` chỉ chứa code + dải, **không PII, không tiền thô** → an toàn cho
  cả prompt lẫn telemetry.

## QĐ-4 — AI chỉ giải thích

| AI ĐƯỢC | AI KHÔNG ĐƯỢC |
|---|---|
| giải thích kết quả twin · mô tả xu hướng · tóm tắt · gợi ý | đưa con số khác · sửa forecast/risk · query DB · gọi repository · mutate · execute |

*Cưỡng chế bằng cấu trúc, không chỉ bằng lời:* `PredictiveAiService` **không
giữ** repository/Ref/capability provider — nó nhận sẵn context + twin. Số liệu
được **copy** từ twin, không bao giờ parse từ text model.

## QĐ-5 — AI Runtime Boundary: thiết kế sẵn, KHÔNG bật

`ai/ai_runtime_boundary.dart` khai báo `AiToolRuntime` + `DisabledAiToolRuntime`
(ném `StateError` trỏ về ADR-TON-016 / red-line G-3). **Không tool calling,
không ReAct, không autonomous agent.**

*Ratchet:* test quét toàn bộ `lib/` khẳng định **không file nào** tham chiếu
`AiToolRuntime` — boundary tồn tại để sau này mở rộng không phải refactor, và
không thể "vô tình" được bật.

## QĐ-6 — Sample = dữ liệu thật, không phải chế độ

Generator ghi qua **chính production repository**, prefix `sample-`
(ADR-TON-014 giữ nguyên): không demo business riêng, không parallel state,
sửa/xoá như bản ghi thường, reset chỉ đụng prefix.

*Hệ quả đã lộ ra khi test:* người dùng có thể ghi đơn của **họ** cho một khách
mẫu → reset phải giữ khách đó lại thay vì crash FK (xem `08-Regression-Mapping`).
