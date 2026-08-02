# Mobile ↔ Backend Contract — Canonical Event Envelope

> **WTM-270 · Wave 7 của PLATFORM-002.** Đây là **hợp đồng**, không phải mô tả:
> mọi connector phải sinh ra đúng hình dạng này, và app chỉ chấp nhận hình dạng này.

Nguyên tắc chi phối (WTM-249): **Backend biết dữ liệu ĐẾN TỪ ĐÂU. Chỉ Mobile biết
dữ liệu đó NGHĨA LÀ GÌ.**

---

## Envelope — đã chạy thật, không phải đề xuất trên giấy

Đoạn dưới là **output thật** từ Node chạy trong container n8n, ngày 2026-08-02:

```json
{
  "envelope_version": 1,
  "event_id": "9C4F4B27-0001",
  "event_type": "subscription.started",
  "occurred_at": "2026-08-02T12:50:00.000Z",
  "received_at": "2026-08-02T13:00:53.288Z",
  "provenance": {
    "source": "connector", "connector": "revenuecat",
    "connection_id": "rc-workizen", "external_id": "9C4F4B27-0001",
    "raw_type": "INITIAL_PURCHASE"
  },
  "freshness": { "mode": "webhook", "confidence": 1 },
  "external_identity": {
    "platform": "revenuecat", "external_id": "workizen-founder-001",
    "confidence": 0.9
  },
  "payload": {
    "product_id": "tongtai_pro_monthly", "store": "APP_STORE",
    "currency": "VND", "amount": 199000,
    "environment": "PRODUCTION", "period_type": "NORMAL"
  }
}
```

---

## Từng trường, và **vì sao** nó bắt buộc

| Trường | Bắt buộc | Vì sao — bằng một lỗi thật nó chặn |
|---|:--:|---|
| `envelope_version` | ✅ | Đổi hình dạng mà không có version = mọi bản app cũ đọc sai trong im lặng |
| `event_id` | ✅ | **Khoá chống trùng.** Webhook được gửi lại là chuyện thường; thiếu nó thì một lần retry = một đơn hàng ma |
| `event_type` | ✅ | Mã canonical, **không** phải chuỗi của vendor. `INITIAL_PURCHASE` là từ vựng RevenueCat; `subscription.started` là từ vựng Tổng Tài |
| `occurred_at` vs `received_at` | ✅ | Hai mốc **khác nhau**. Webhook chậm 3 tiếng thì doanh thu thuộc về lúc *xảy ra*, không phải lúc *nhận* |
| `provenance` | ✅ | Người bán phải phân biệt *"số tôi tự nhập"* với *"số connector đẩy về"*. Đây là thứ WTM-240 xác định là **chặn mọi connector** |
| `freshness.confidence` | ✅ | AI đọc dữ liệu cũ 3 ngày lẫn dữ liệu hôm nay mà không biết ⇒ **nói sai một cách tự tin** |
| `external_identity.confidence` | ✅ | Sàn thường không trả số điện thoại thật. **Gộp nhầm hai khách tệ hơn không gộp** — nên độ tin cậy phải đi kèm, không được ngầm định |
| `payload` | ✅ | Dữ liệu thô đã chuẩn hoá **hình dạng**, chưa diễn giải ý nghĩa |

---

## Điều backend **không** được đặt vào envelope

Danh sách này quan trọng ngang danh sách trên:

| Không được có | Vì sao |
|---|---|
| `revenue`, `mrr`, `profit` | Đó là **kết luận kinh doanh** ⇒ Rule Twin trên máy. Backend tính hộ = tạo nguồn thứ hai (P-27) |
| `is_important`, `priority`, `score` | Quyết định cái gì đáng chú ý là việc của Opportunity engine |
| `should_notify` | Thông báo là kết luận, không phải sự kiện |
| `customer_id` (id nội bộ của app) | Backend **không biết** danh bạ khách của người bán. Nó chỉ đưa `external_identity`; việc gộp là của Mobile |
| bất kỳ token/secret nào | Luật credential Founder |

Đoạn code trong workflow có ghi thẳng một dòng nhắc điều này, để người sửa sau
đọc được ngay tại chỗ:

```
note: 'backend chi chuan hoa hinh dang; y nghia kinh doanh do Mobile quyet dinh'
```

---

## Idempotency — luật, không phải khuyến nghị

1. Backend **luôn** gửi `event_id`.
2. Mobile lưu `event_id` đã xử lý; gặp lại thì **bỏ qua im lặng**, không phải lỗi.
3. Retry của n8n **không được** tạo bản ghi nghiệp vụ thứ hai.
4. Khoá chống trùng là `(connector, event_id)`, **không** phải `(connector, occurred_at)` —
   hai sự kiện khác nhau có thể trùng mốc thời gian.

---

## Ánh xạ event_type — RevenueCat (connector đầu tiên)

| RevenueCat | Canonical |
|---|---|
| `INITIAL_PURCHASE` | `subscription.started` |
| `RENEWAL` | `subscription.renewed` |
| `CANCELLATION` | `subscription.cancelled` |
| `EXPIRATION` | `subscription.expired` |
| `PRODUCT_CHANGE` | `subscription.changed` |
| `BILLING_ISSUE` | `subscription.billing_issue` |
| `REFUND` | `payment.refunded` |
| `NON_RENEWING_PURCHASE` | `payment.captured` |
| *(không khớp)* | `subscription.unknown` — **không đoán** |

Dòng cuối là kỷ luật ADR-TON-018 áp cho event: **mã lạ thì nói là lạ**, không
ánh xạ bừa về mã gần giống nhất.

---

## Điều app hiện **chưa** có (nợ đã biết)

Envelope này giả định app có `Provenance`, `CustomerIdentity`, `Fee/Refund/Payout`
— cả ba **chưa tồn tại** trong schema v16. Đó chính là **N0** trong roadmap
WTM-246, và là lý do N0 phải làm trước connector đầu tiên: có envelope mà không
có chỗ đặt thì dữ liệu sẽ rơi vào cột sai.

⇒ **Hợp đồng này đã sẵn sàng ở phía backend. Phía mobile còn nợ N0.**
