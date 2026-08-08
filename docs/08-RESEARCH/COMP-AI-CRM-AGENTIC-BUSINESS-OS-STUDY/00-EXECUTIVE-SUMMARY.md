# 00 · Executive Summary

> **WTM-296 · P0 RESEARCH.** Đọc source thật `trycompai/crm` @ `c26a08d` (MIT, 2026-08-07).
> **Không implement gì.** Founder + GPT phản biện trước khi mở implementation story.

## Ba câu trả lời quan trọng nhất

**1. Confidence phải được TÍNH từ evidence, không do chỗ gọi khai.**
COMP AI không cho phép khai confidence ở **bất kỳ đâu** — `record_fact` không có tham số `score`. Agent chỉ khai *thấy gì* (`kind` từ từ vựng đóng); một hàm thuần định giá. Skill nói thẳng: *"You never set a confidence. You report what you saw, and the ledger prices it."*
⇒ Tổng Tài đang làm ngược ở đúng một chỗ: `IdentityCandidate.confidence`. **Đây là điểm sửa rẻ nhất và có giá trị nhất** (R-1) — 0 connector, 0 migration.

**2. Thiếu vòng đề xuất là thứ chặn Tổng Tài ở L1.**
COMP AI có `PROPOSED · APPLIED · SUPERSEDED · DISMISSED`. Cái ở giữa — *"đề xuất treo cho người duyệt"* — là mảnh Tổng Tài **không có**. `SuggestLink` chỉ sống trong bộ nhớ, không qua nổi một lần đóng app.
⇒ Không có nó thì **không thể** lên L2 · Prepare (R-2).

**3. Cửa ghi duy nhất phải làm TRƯỚC agent đầu tiên, không phải sau.**
COMP AI có **ba kỷ luật ghi song song**: ledger (evidence+lifecycle), ghi thẳng (không gì cả), `agentAction` (idempotency+lifecycle). Không đường nào có cả ba. Và **tính năng mới hơn rơi vào đường yếu hơn** — `set_field_value` thêm 5 ngày sau ledger, bỏ qua hoàn toàn.
⇒ Vì họ **không có boundary test nào** (24 file test, 0 file kiểm ranh giới). Tổng Tài đã có công cụ đó và đã dùng 3 lần (R-3).

## Hai giả định của Tổng Tài bị source thách thức

| Giả định | Source nói gì |
|---|---|
| `IdentityCandidate` khai confidence | không hệ nào cho phép — kể cả ở tool tương đương gần nhất, `identify_contact`, vốn đi **cùng một cửa** `recordFact()` |
| `CanonicalEvent` cần thiết | COMP AI **không có tầng event** và vẫn chạy production. Ta hiện **0 producer, 0 consumer** ⇒ giữ hypothesis |

## Hai chỗ Tổng Tài đang ĐI TRƯỚC

| | |
|---|---|
| **Governance bằng cấu trúc** | 3 suite khoá luật + test chống PASS GIẢ. COMP AI không có gì tương đương — và trả giá thấy được |
| **Capability Matrix 3 cột** | `platformSupports` / `connectorCovers` / `verifiedOnDogfood`. COMP AI trộn thành một boolean. Với 10+ sàn và AI nói chuyện với người bán, tách là **bắt buộc** |

## Kết luận về entity mới

| Ứng viên | Phán quyết |
|---|---|
| `BusinessConversation` | ❌ **bác bỏ** — COMP AI dựng "câu chuyện" **lúc đọc**; `correlationId` là đủ |
| `CanonicalEvent` | ⏸ **hypothesis** — chờ ≥2 producer/consumer |
| `Evidence` · `AgentTask` · `ProposedChange` · `BusinessAction` · `AutonomyRule` | ✅ **cần** |
| `correlationId` | ✅ **một trường**, không phải bảng |
| Runtime mới (Temporal/Kafka) | ❌ Postgres + cron + `SKIP LOCKED` = **174 dòng**, chạy production |

## Khoảng cách lớn nhất — chưa giải được

COMP AI có **server luôn thức**. Tổng Tài **cố ý không có backend** cho dữ liệu nghiệp vụ (D-5), và điện thoại không chạy nền tuỳ ý.

Ba hướng ở `17-TARGET-ARCHITECTURE.md`; khuyến nghị bắt đầu bằng **chạy lúc mở app** — vì `AgentTask` có giá trị ngay cả khi chỉ chạy lúc mở, và nó không khoá đường lên sau này. **Chọn hướng là Founder Gate (D-4).**

## Điều COMP AI KHÔNG dạy được cho ta

Họ giải bài toán *"agent làm giàu dữ liệu CRM"* — hành động tệ nhất là ghi sai chức danh, sửa mất 5 giây. Mô hình duyệt của họ là **29 dòng**.

Tổng Tài giải bài toán *"AI vận hành việc kinh doanh"* — hành động tệ nhất là **đặt đơn 20 triệu**. Mọi thứ ở `13-AUTONOMY-POLICY.md` vượt quá source là **có chủ ý**, và phải đọc như đề xuất **chưa có bằng chứng vận hành**.

## Cần Founder quyết

**Bốn quyết định 🔴 chặn mọi implementation:** D-1 (confidence) · D-2 (ProposedChange) · D-3 (BusinessAction trước/sau) · D-4 (durable agent local-first — **doctrine**).

Chi tiết + lựa chọn + hệ quả nếu hoãn: `21-FOUNDER-DECISIONS.md`.
