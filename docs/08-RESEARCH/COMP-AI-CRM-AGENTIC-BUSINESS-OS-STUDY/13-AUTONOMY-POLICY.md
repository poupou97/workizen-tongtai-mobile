# 13 · Autonomy Policy — tối giản, enforce ở boundary

> **Founder chấp nhận 2026-08-08:** giữ tối giản, enforce tại action/tool boundary, **không** xây policy engine.

## COMP AI: ba cơ chế nhỏ ở ba biên, tổng cộng ~40 dòng

| Tầng | Cài ở đâu | Hình dạng |
|---|---|---|
| **Mỗi tool** | `sensitiveWrite()` — **29 dòng** | session tự động ⇒ **TỪ CHỐI**; người đang ngồi ⇒ hỏi duyệt |
| **Mỗi agent** | `agentVersion.manifest` JSONB | `{trigger, dataScope, actions, access}` + `sandboxPolicy` |
| **Mỗi task** | `budget` + `spend(units)` | đếm **lượt gọi vendor**, enforce trong tool |

```js
// lib/approval.ts — toàn bộ mô hình duyệt của một sản phẩm production
export function sensitiveWrite(instead: string): Approval {
  return ({ session }) =>
    isAutomated(session)
      ? { type: "denied", reason: `Not something to do unattended. ${instead}` }
      : "user-approval";
}
```

**Chỉ 2 tool dùng nó**: `archive_field`, `record_job_change`.

⭐ **Chi tiết đáng học nhất:** mỗi object policy **mang theo `summary` người đọc được**:

```js
sandboxPolicy = { backend: "eve-default", networkPolicy: "deny-all",
                  credentials: "app-runtime-only",
                  summary: "Isolated sandbox · deny-all network · bounded CRM tools" }
dataScope = { mode, summary: scopeSummary(...), resources }
```

Cấu hình và lời giải thích của nó **đi cùng nhau**, nên UX không phải dịch lại JSON. Đây là cầu nối trực tiếp sang §16.

## Vì sao mô hình của họ KHÔNG đủ cho Tổng Tài

`sensitiveWrite` đủ khi hành động tệ nhất là **ghi sai chức danh**. Không đủ khi hành động có thể **đặt đơn nhập hàng 20 triệu**.

Khác biệt không phải mức độ, mà là **loại**: hành động của COMP AI đều hoàn tác được bằng một lần sửa. Hành động của Tổng Tài có loại **không hoàn tác được** — tin đã gửi cho khách, tiền đã chuyển, đơn đã đặt.

## PROPOSAL — MVP bốn trường, không engine

> ⚠️ **PROPOSAL** — chưa cài đặt.

```
AutonomyRule {
  capability     — customer_care | inventory | marketing | finance
  actionType     — customer.send_message | inventory.create_purchase_order | …
  mode           — OFF | SUGGEST | CONFIRM | AUTO
  conditions?    — điều kiện tối giản (segment, ngưỡng)
  limits?        — { maxPerPeriod, maxAmount }
}
```

**Bốn mode khớp đúng bốn mức tự chủ của Founder:**

| Mode | = Level | Nghĩa |
|---|---|---|
| `OFF` | L0 Observe | AI đọc, không đề nghị |
| `SUGGEST` | L1 Suggest | tạo `ProposedChange`, không tạo action |
| `CONFIRM` | L2 Prepare | tạo `BusinessAction` `status=PLANNED`, chờ người bấm |
| `AUTO` | L3 Policy | tự chạy **trong limits** |

**Enforce ở đúng một chỗ:** hàm dựng `BusinessAction` tra `AutonomyRule` theo `(capability, actionType)`. Không có rule ⇒ mặc định `SUGGEST`. Không engine, không DSL, không đánh giá biểu thức.

## Mặc định phải là **an toàn**, không phải tiện

| Nguyên tắc | Vì sao |
|---|---|
| Không có rule ⇒ `SUGGEST` | thêm action mới **không** tự động được quyền chạy |
| `AUTO` phải có `limits` | assert lúc dựng rule, giống `D ⟹ evidence != null` (WTM-293) |
| `AUTO` không áp cho `riskLevel: high` | assert, không phải nội quy |

## ⛔ Danh sách TUYỆT ĐỐI không auto mặc định

Founder hỏi thẳng ở §27 câu 13. Đề xuất — mỗi mục kèm lý do, không phải cảm tính:

| Hành động | Vì sao không bao giờ auto mặc định |
|---|---|
| **Chuyển tiền / thanh toán** | không hoàn tác được, và sai một lần là mất tiền thật |
| **Xoá hoặc gộp bản ghi khách** | đã cấm bằng cấu trúc (ADR-TON-024 luật 4) |
| **Gửi tin cho khách chưa từng mua** | rủi ro spam ⇒ mất kênh, không chỉ mất một khách |
| **Đổi giá bán** | ảnh hưởng mọi đơn sau đó; người bán phải là người quyết |
| **Đặt đơn nhập hàng vượt `maxAmount`** | tiền thật |
| **Bất cứ gì tới người ngoài danh bạ** | ranh giới riêng tư (D-4, không tài khoản) |
| **Sửa dữ liệu người bán đã tự nhập tay** | nguyên tắc 3 — người thắng máy |

Bảy mục này nên là **hằng số trong code kèm assert**, không phải mặc định cấu hình — cùng cách `CapabilityClaim` chặn ở constructor.

## Điều KHÔNG làm

- **Không policy engine.** Không DSL, không rule chaining, không biểu thức người dùng viết.
- **Không quyền per-field.** COMP AI có `agentFilled` per field; với Tổng Tài, `capability + actionType` là đủ thô và đủ dùng.
- **Không "bật AI toàn quyền".** Founder đã nói; source cũng không có.
