# 18 · ADOPT / ADAPT / REJECT

Mười bốn pattern §20 yêu cầu, mỗi cái kèm **lý do**, không chỉ nhãn.

## ✅ ADOPT — bê gần nguyên hình dạng

| Pattern | Vì sao | Trace |
|---|---|---|
| **Evidence kind + hàm thuần định giá** | Chỗ gọi không khai được confidence ⇒ không nói dối được. Tổng Tài đang là ngoại lệ duy nhất. | `lib/evidence.ts:99` |
| **`contradiction` KẸP điểm, không trừ** | Hai nguồn mâu thuẫn không phải "60% đúng", mà là **chưa ngã ngũ**. | `evidence.ts:95,118` |
| **Primary vs supporting** | Gộp mười nguồn yếu không bao giờ nên bằng một nguồn định danh trực tiếp. | `evidence.ts:22-78` |
| **Fact lifecycle 4 trạng thái** | Mảnh thiếu để Tổng Tài lên L2 · Prepare. | `lib/facts.ts` |
| **`SUPERSEDED` thay vì xoá** | Phát hiện thay đổi là **hệ quả miễn phí**. | `facts.ts:193` |
| **Task queue: lease + attempts + `SKIP LOCKED`** | 174 dòng, không dependency, chạy trên SQLite được. | `lib/tasks.ts` |
| **Chống trùng lúc *đặt lịch*** | Gọi trigger 50 lần vẫn một việc. Rẻ hơn chống trùng lúc chạy. | `tasks.ts:128` |
| **Retry = *tiếp tục*, không *làm lại*** | | `dispatch.ts:140` |
| **`idempotencyKey` + `requestHash`** | Cùng key khác payload ⇒ **ném lỗi**. `CanonicalEvent` của ta thiếu hash. | `run-runtime.ts:207` |
| **Side effect + status trong MỘT transaction** | Không thể "SUCCEEDED mà chưa làm". | `run-runtime.ts:292` |
| **Cấu hình mang theo `summary` người đọc** | Giải quyết §16 mà không cần tầng dịch riêng. | `builder-runtime.ts:212` |
| **Phân biệt *chưa cấu hình* với *thất bại*** | Không có nó, agent retry thứ không bao giờ thành công. | `capabilities.ts:78` |
| **Skill runtime = tài liệu thi hành được** | Code thi hành luật; skill giải thích ý định. | `agent/skills/*.md` |

## 🔧 ADAPT — hình dạng đúng, chi tiết phải đổi

| Pattern | Đổi gì | Vì sao |
|---|---|---|
| **Capability discovery** | env var → **`Connection` per-seller** | họ single-tenant; ta mỗi người bán một bộ |
| **`humanOwns()`** | suy-ra → **cờ tường minh + suy ra** | miền ta rộng hơn; `agentFilled` per field của họ quá mịn, `humanOwns` quá ngầm |
| **`sensitiveWrite` (tự động ⇒ từ chối)** | thêm `riskLevel` + `limits` | hành động của ta **tiêu tiền thật**, của họ chỉ ghi CRM |
| **`budget` lượt gọi vendor** | thêm **tiền** cho hành động mua | lượt gọi đủ cho nghiên cứu, không đủ cho nhập hàng |
| **Durable loop cron mỗi phút** | → chạy **lúc mở app** (hướng A) | không có backend luôn thức |
| **`DISMISSED` vĩnh viễn** | thêm **`reconsiderAfter` / `reconsiderOnNewEvidenceKind`** | đúng cho tên người, **sai** cho giá nhà cung cấp *(Founder chỉ đạo 2026-08-08)* |
| **Agent builder bằng hội thoại** | → **Automation Card** chọn sẵn | người bán SME không dựng agent; họ bật/tắt việc |

## ❌ REJECT — không mang sang

| Pattern | Vì sao không |
|---|---|
| **Ba kỷ luật ghi song song** | Đây là **lỗi**, không phải thiết kế. Bằng chứng: `set_field_value` (mới 2 ngày) bỏ qua ledger. |
| **`BusinessConversation` như entity** | COMP AI có `agentConversation` nhưng nó là chat thread. Projection + `correlationId` đủ. |
| **Bảng event nghiệp vụ (lúc này)** | 0 producer/consumer. Giữ hypothesis. |
| **Sandbox chạy code tuỳ ý** | Tổng Tài là app di động — không có bash sandbox, và không cần. |
| **Agent tự tạo/xoá field (schema)** | `manage_fields`/`archive_field` cho agent đổi schema. Với Tổng Tài, schema là ADR + migration + governance test. **Tuyệt đối không.** |
| **`agentFilled` per field** | quá mịn; `capability + actionType` là mức đúng cho SME. |
| **Vector store / memory service** | họ không có, ta cũng không cần — trí nhớ là bản ghi nghiệp vụ. |
| **Skill kéo từ GitHub khoá hash** | hợp cho agent viết code, không liên quan agent nghiệp vụ. |

## Không phân loại được — cần dữ liệu thật

| Pattern | Thiếu gì để quyết |
|---|---|
| Trọng số cụ thể (0.95/0.85/0.4…) | trọng số của họ hợp CRM. Của Tổng Tài phải rút ra từ **lỗi thật của người bán**, không chép. |
| Ngưỡng band (.85/.55/.3) | như trên |
| Hai làn visible/research | ta chưa có agent nên chưa biết có cần tách |
