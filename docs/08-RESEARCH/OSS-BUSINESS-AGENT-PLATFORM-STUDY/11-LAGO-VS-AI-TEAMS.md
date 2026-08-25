# 11 · Lago vs AI Teams — map domain billing cho SaaS đội AI agent

> WTM-452 (Epic WTM-447) · 2026-08-25 · Độ sâu NHẸ · Cặp với `10-LAGO-BILLING.md`.
> AI Teams = SaaS Workizen bán đội AI agent làm phần mềm, tính tiền usage AI + compute.

## 0. Billing AI Teams đã định hình đến đâu? (đọc lướt `workizen-ai-teams-mobile/docs/`)

**Đã có thiết kế nội bộ, chưa có quyết định giá.**
`docs/04-RESEARCH/round-2/17-COST-CREDIT-ARCHITECTURE.md` (WAT-16, 2026-08-15,
**PROPOSED — chờ Founder**) đã tự thiết kế: nguyên tắc *"meter nhiều nơi, LEDGER một nơi"*
(3 meter: LiteLLM SpendLogs · OpenHands Metrics · AWS CUR), `cost_ledger` USD nội bộ +
`credit_ledger` Credits mặt khách, **append-only + reversal**, wallet có
`available/reserved` (escrow per story), khớp nối = `PricingPolicy` versioned, chạy trên
Postgres. Tỷ giá Credits/nạp/escrow = **D-AT-5 Founder confirmation required**. Tài liệu 17
**không nhắc Lago** ⇒ study này là đầu vào đối chiếu cho chính nó.

## 1. Bảng map khái niệm

| AI Teams (doc 17 + PRODUCT-BRIEF) | Lago tương đương | Ghi chú map |
|---|---|---|
| 1 LLM call / 1 stage done (per story, per agent) | `Event` (`transaction_id` + `external_subscription_id` + `properties`) | `transaction_id` = idempotency ingest — doc 17 §1.2 đã có `UNIQUE(source_meter, source_ref)`, **cùng bài** DB-constraint |
| tokens in/out, USD spend | `BillableMetric sum_agg` trên `field_name` (`properties.tokens`) | AI Teams giấu token khỏi khách (D-AT-5) ⇒ metric token chỉ ở sổ nội bộ |
| compute-giây sandbox/OpenHands chiếm giữ | `weighted_sum_agg` (interval **seconds**) | Aggregation Lago khớp nhất với compute — đáng học nhất trong 7 kiểu |
| số story/deliverable hoàn thành | `count_agg` / `unique_count_agg` | |
| Giá theo deliverable, gói Credits, retainer | `Charge` `package`/`graduated` + Plan interval (retainer) | Taxonomy 8 charge model = từ vựng sẵn khi Founder chọn giá |
| **Workizen Credits** (khách không thấy USD/token) | `Wallet`: `credits_balance` + `rate_amount` (tỷ giá) + `expiration_at` | ⭐ map thẳng; Lago xác nhận pattern "hai đơn vị, một tỷ giá per wallet" |
| Credits tặng/beta vs mua thật | `wallet_transaction.transaction_status` `granted` vs `purchased`, **tiêu granted trước** | Doc 17 **chưa phân biệt** — nên bổ sung |
| Auto top-up khi cạn giữa story | `SOURCES` `threshold` + `threshold_top_up_service` | Doc 17 gate fail-closed khi hết credits — threshold top-up là lối thoát UX |
| **Escrow/reserve per story** (trừ available, cộng reserved, 1 transaction) | ❌ **Lago KHÔNG có** — `ongoing_balance` chỉ là ước lượng hiển thị | Khác biệt quan trọng nhất: nhu cầu lõi của AI Teams nằm NGOÀI domain Lago |
| Chốt tiền một story khi nghiệm thu | `Invoice` `draft → finalized` + `Fee` | "Finalize = bất biến, trước đó là draft" đúng nhịp nghiệm thu deliverable |
| Hoá đơn/thuế/pháp lý cho khách | `Invoice` numbering, PDF service, dunning | **Chưa dùng được**: Workizen chưa có pháp nhân (phát hiện 2026-08-22) |

## 2. Verdict 5 trục

| Trục | Verdict | Vì sao |
|---|---|---|
| Domain model (metering·wallet·invoice) | ✅ **HỌC** | Vocabulary chín: aggregation types, charge models, granted/purchased, expiry, threshold top-up, draft/finalize — đối chiếu trực tiếp vào doc 17 |
| Kiến trúc ingest | ✅ HỌC | Idempotency = DB unique constraint; high-volume (Kafka/ClickHouse) là **opt-in** — beta hàng trăm story/tháng không cần |
| **Source code** | ⛔ **AGPL-3.0 — CẤM chép**; self-host có chỉnh sửa cũng kích hoạt nghĩa vụ mở source, phải qua Founder | |
| Self-host vận hành | ❌ KHÔNG | 7 container thường trực (Rails + 2 datastore + clock + pdf) cho một SaaS chưa có khách trả tiền = nuôi hệ thống lớn hơn app chính |
| Phù hợp phase | ⚠️ MỘT PHẦN | Wallet/metering: đúng lúc (doc 17 đang PROPOSED). Invoice/thuế/dunning: **chưa** — chặn bởi pháp nhân, không phải kỹ thuật |

## 3. Câu quyết định: **(a) — chỉ HỌC domain model, build minimal equivalent**

- **Không (c) self-host Lago**: footprint 7 service; AGPL khi chỉnh sửa; và thứ AI Teams
  cần nhất (escrow/reserve per story, fail-closed gate) **Lago không có** — self-host xong
  vẫn phải tự build phần khó nhất.
- **Không (b) Stripe Billing/Metering lúc này**: mọi payment rail cần pháp nhân + tài
  khoản nhận tiền — đúng bức tường 2026-08-22 (xem
  `project_marketplace_integration_gates`); metering thuê ngoài trong khi ledger nội bộ
  đã thiết kế xong chỉ thêm một nguồn sự thật thứ hai. Xem lại (b) khi có pháp nhân và
  khách trả tiền thật.
- **Không (d)**: doc 17 đang PROPOSED chờ Founder — đầu vào đối chiếu có giá trị **ngay
  bây giờ**, để sau là mất thời điểm.
- (a) cụ thể: giữ nguyên thiết kế ledger doc 17 (đã đúng và mạnh hơn Lago ở escrow +
  append-only); **bổ sung từ Lago**: (1) `granted` vs `purchased` + thứ tự tiêu,
  (2) `expiration_at` cho credits khuyến mãi, (3) threshold top-up, (4) tách meter
  aggregation khỏi pricing (doc 17 đã có qua `PricingPolicy` — Lago xác nhận),
  (5) trạng thái draft/finalized khi chốt tiền story.

## 4. Anti-overengineering — "Không học Lago thì mất gì?"

Mất **trung bình-thấp**: doc 17 đã tự đi tới meter≠ledger, append-only, idempotency —
những bài đắt nhất. Cái thật sự mất nếu bỏ: taxonomy charge model (khi Founder chốt giá),
ba khoảng trống wallet ở §3 (granted/expiry/threshold), và bằng chứng "ongoing balance ≠
escrow" — tức Lago xác nhận rằng escrow phải tự build, đừng đợi tool ngoài. Đúng với độ
sâu NHẸ đã chọn: dừng ở đây, không đào thêm services layer.
