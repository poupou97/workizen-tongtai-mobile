# 12 · Canonical Action — cửa ghi DUY NHẤT

> **Founder chấp nhận 2026-08-08:** `BusinessAction` là single write boundary cho **mọi** side effect của agent; `ProposedChange` tách riêng.

## COMP AI đã phát minh ra nó — rồi không hồi tố

`agentAction` (`20260803210000_agent_builder_foundation`) là một Canonical Action đầy đủ:

| Cột | Vai trò |
|---|---|
| `type` `"crm.activity.create"` | mã hành động canonical |
| `provider` `"crm"` | vendor |
| `targetType`/`targetId`/`targetLabel` | subject, kèm **nhãn người đọc được** |
| `summary` | câu mô tả cho người |
| `metadata` JSONB | tham số |
| `status` PLANNED→RUNNING→SUCCEEDED/FAILED/CANCELLED | vòng đời |
| `idempotencyKey` + `requestHash` | chống lặp |
| `externalId` | kết quả ở hệ ngoài |
| `attemptCount` · `errorCode` · `errorMessage` | chẩn đoán |

Giao thức thực thi (`run-runtime.ts:200-350`) — **cả bốn bước đáng bê nguyên**:

1. `lockIdempotencyKey` → tra theo key → nếu có, `assertActionRequestMatches(requestHash)`. **Cùng key khác payload ⇒ ném lỗi**, không ghi đè.
2. `SUCCEEDED` ⇒ trả `replayed: true`. Không làm lại.
3. Claim bằng lease: `PLANNED|FAILED` hoặc `RUNNING` quá hạn — cùng pattern với task queue.
4. **Side effect và cập nhật status trong MỘT transaction.** Không thể "SUCCEEDED mà chưa làm", không thể "làm rồi mà ghi FAILED".

## ⚠️ Nhưng nó chỉ phủ MỘT trong ba đường ghi

| Đường | Dùng ở | Evidence | Lifecycle | Idempotency |
|---|---|:--:|:--:|:--:|
| fact ledger | `facts.ts` | ✅ | ✅ | dedup giá trị |
| **ghi thẳng** | `fields.ts` · `portrait.ts` · `research_company.ts` · 3 tool khác | ❌ | ❌ | ❌ |
| `agentAction` | `run-runtime.ts` **chỉ** | ❌ | ✅ | ✅ |

**Không đường nào có cả ba.** Và `agentAction` — thứ tốt nhất — chỉ phục vụ runtime custom agent, không phục vụ agent nghiên cứu vốn là sản phẩm chính.

⇒ **Đây là bằng chứng phản chứng cho khuyến nghị:** COMP AI có đủ mảnh nhưng không hợp nhất, nên bề mặt mới nhất (`set_field_value`, thêm 2 ngày trước) rơi vào đường yếu nhất.

## PROPOSAL cho Tổng Tài — hai kiểu, hai vòng đời

> ⚠️ **PROPOSAL** — chưa cài đặt.

**Tách vì chúng khác bản chất:**

| | `ProposedChange` | `BusinessAction` |
|---|---|---|
| Là gì | *đề nghị đổi một sự thật nghiệp vụ* | *một việc làm ra bên ngoài* |
| Ví dụ | "giá vốn món này nên là 45.000" | "gửi tin cho khách", "tạo đơn nhập hàng" |
| Hoàn tác | đổi status | **có thể không hoàn tác được** |
| Cần | evidence + band | idempotency + duyệt + kết quả |
| Vòng đời | PROPOSED · APPLIED · DISMISSED · SUPERSEDED | PLANNED · APPROVED · RUNNING · SUCCEEDED · FAILED · CANCELLED |

Gộp chúng làm một sẽ ép "gửi tin nhắn cho khách" phải mang `evidence[]`, và ép "giá vốn nên là 45.000" phải mang `idempotencyKey`. Cả hai đều vô nghĩa.

### `BusinessAction` — trường đề xuất

```
id · correlationId
type            — mã canonical, ví dụ `customer.send_message`
vendor          — `telegram` | `internal` | …
subject         — {kind, id, label}   ← label để người đọc
summary         — câu người bán đọc được
parameters      — JSON
riskLevel       — low | medium | high        ← COMP AI KHÔNG có
approvalMode    — auto | confirm | never     ← COMP AI KHÔNG có
proposedBy      — `agent` | `rule:<tên>` | `seller`
status · idempotencyKey · requestHash
externalId · attemptCount · errorCode · errorMessage
```

Ba trường COMP AI thiếu (`riskLevel`, `approvalMode`, `proposedBy`) là cần cho Tổng Tài vì hành động ở đây **tiêu tiền thật của người bán**, không chỉ ghi CRM.

### ⭐ `vendor: "internal"` — điểm mấu chốt

Cửa ghi phải phủ **cả ghi vào DB nội bộ**, không chỉ gọi vendor ngoài. Đó chính là chỗ COMP AI hụt: `set_field_value` ghi DB của chính nó nên không ai nghĩ nó cần đi qua action.

## Ngăn bypass — ba lớp, và ta đã chứng minh hai lớp

| Lớp | Kiểm gì | Tiền lệ trong repo |
|---|---|---|
| 1 | module tool **không import** repository/drift/database | `settlement_allocation.dart` (WTM-292 lớp 1) |
| 2 | tool trả về **đề xuất/action**, không trả entity lưu được | `AllocatedSettlement` không có `id` (WTM-292 lớp 2) |
| 3 | **đúng một** chỗ trong seam gọi được đường ghi | `CapabilityClaim._()` private (WTM-293) |

Cả ba đã dùng thật, đã có test chống PASS GIẢ, và đã bắt được vi phạm thật một lần (`\bdb\.` không khớp `_db`).

⇒ **Tổng Tài có thể làm đúng ngay từ đầu thứ COMP AI làm hỏng trong một tuần.** Không phải vì ta giỏi hơn — vì ta đã trả giá cho bài học P-27/P-28 bốn lần và đã dựng công cụ.
