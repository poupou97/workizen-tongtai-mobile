# Canonical Events — từ vựng đóng, và hai điều connector không được làm

> **WTM-289 · N3 · Epic WTM-284 (Platform Wave 2).** Ngày **2026-08-07**.

Luật của Founder: *"Connector chỉ được emit Canonical Event. Không emit event
riêng từng nền tảng."*

---

## Nền móng đã có — tài liệu này KHÔNG làm lại

`09-MOBILE-BACKEND-CONTRACT.md` (WTM-270) đã chốt **bao bì**: `envelope_version` ·
`event_id` (khoá chống trùng) · `event_type` · `occurred_at` vs `received_at` ·
`provenance` · `freshness.confidence` · `external_identity.confidence` ·
`payload`. Connector GitHub đã chạy thật trên bao bì đó — 366 sự kiện, `event_id`
trùng khít qua hai lần gọi (WTM-268/274).

Tài liệu này chuẩn hoá **từ vựng `event_type`**.

---

## Từ vựng

Quy ước: `<miền>.<việc đã xảy ra>` — danh từ trước, động từ quá khứ sau.

| Miền | Mã |
|---|---|
| **order** | `order.created` · `order.updated` · `order.paid` · `order.cancelled` · `order.fulfilled` |
| **inventory** | `inventory.changed` |
| **customer** | `customer.created` · `customer.updated` |
| **payment** | `payment.received` · `payment.failed` |
| **refund** | `refund.completed` |
| **shipment** | `shipment.created` · `shipment.delivered` · `shipment.failed` |
| **settlement** | `settlement.line_recorded` · `settlement.payout_settled` *(WTM-286)* |
| **subscription** | `subscription.started` · `.renewed` · `.cancelled` · `.expired` · `.changed` · `.billing_issue` |
| **delivery** | `delivery.commit` · `delivery.change_merged` · `delivery.released` *(đã chạy)* |
| **thoát** | `<miền>.unknown` |

---

## ⭐ Hai luật, và cả hai là TỪ CHỐI

### 1. Mã lạ ⇒ `<miền>.unknown`, KHÔNG ánh xạ về mã gần giống nhất

Đã áp trong connector RevenueCat, và đúng kỷ luật ADR-TON-018: mã không nhận ra
là **bản ghi lạ**, không phải cơ hội để đoán.

Cám dỗ cụ thể: Shopee có `TO_CONFIRM_RECEIVE`. Nó *gần giống* `order.fulfilled`.
Ánh xạ bừa vào đó sẽ làm doanh thu ghi nhận sớm một khâu — và không ai phát hiện
cho tới khi có đơn bị trả.

### 2. Backend KHÔNG được đặt kết luận kinh doanh vào event

Cấm: `revenue` · `mrr` · `profit` · `is_important` · `priority` · `score` ·
`should_notify`.

Đó là việc của Rule Twin trên máy (ADR-TON-016). Backend biết dữ liệu **đến từ
đâu**; chỉ Mobile biết nó **nghĩa là gì** (WTM-249).

---

## ⭐ Điều tài liệu này thêm vào so với contract cũ

**Cùng một sự việc ở hai nền tảng phải ra CÙNG một mã.**

Shopee *"đơn đã xác nhận"* và TikTok *"order confirmed"* **không được** thành
hai `event_type` khác nhau. Nếu chúng khác nhau, Rule Twin phải biết từng nền
tảng — tức là chính thứ mà canonical sinh ra để tránh, và mỗi sàn mới lại thêm
một nhánh `if` vào lõi nghiệp vụ.

Phép thử để biết một mã mới có chính đáng không:

> *Nếu ngày mai có sàn thứ tư làm cùng việc này, nó có dùng được mã này không?*

Không ⇒ mã đang mô tả **cách nền tảng nói**, không phải **việc đã xảy ra**.

### Bảng ánh xạ là một phần của connector, không phải của lõi

Mỗi connector giữ bảng riêng `mã nền tảng → mã canonical`, kèm dòng cuối
*"không khớp ⇒ unknown"*. Lõi nghiệp vụ **không bao giờ** thấy mã nền tảng.

Ví dụ đã chạy thật (GitHub, WTM-268):

| GitHub | Canonical |
|---|---|
| commit | `delivery.commit` |
| pull request đã merge | `delivery.change_merged` |
| release | `delivery.released` |
| PR đóng **không** merge | *(không sinh sự kiện — không phải một lần giao hàng)* |
| tag | *(không sinh sự kiện — `split-baseline` là mốc kỹ thuật)* |

Hai dòng cuối đáng chú ý hơn tám dòng trên: **không phải mọi thứ nền tảng có
đều đáng thành một sự kiện.** Ánh xạ tag → release là đúng kiểu "đoán về mã gần
giống nhất" mà luật 1 cấm.

---

## Thứ tự và trùng lặp

- Khoá chống trùng: `(connector, event_id)` — **không** phải
  `(connector, occurred_at)`; hai sự việc khác nhau có thể trùng mốc thời gian
- Sự kiện đến **không đảm bảo đúng thứ tự**. `occurred_at` quyết định thứ tự
  nghiệp vụ, `received_at` chỉ để chẩn đoán
- Sự kiện đến **muộn hơn** một sự kiện mới hơn của cùng đối tượng ⇒ **không
  được ghi đè**. Đây là chỗ hay hỏng nhất khi có retry
