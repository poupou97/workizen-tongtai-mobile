# Integration Sandbox — và sự thật là phần lớn "sandbox" đòi đúng thủ tục như production

> **WTM-290 · N4 · Epic WTM-284 (Platform Wave 2).** Ngày **2026-08-07**.
> **Không** đăng ký app thật, **không** OAuth, **không** gọi API.

Luật của Founder: *"Mọi connector phải thử trước trên Dogfood."*

---

## ⭐ Điều tài liệu này phải nói thật

Một sandbox **không giống production** thì tệ hơn không có — nó tạo niềm tin
sai. Và với phần lớn nền tảng trong danh sách, "môi trường thử" đòi **đúng bộ
thủ tục phê duyệt** như production: đăng ký app, duyệt scope, thẩm định doanh
nghiệp.

Nên kế hoạch sandbox không phải danh sách mong muốn. Nó là **bảng phân loại
theo thứ thật sự chặn**.

---

## Bốn nhóm

### 🟢 Thử được hôm nay — không ai phải duyệt

| Nền tảng | Cách | Thời gian |
|---|---|---|
| **Telegram** | `@BotFather` tạo bot, có token ngay | ~5 phút |
| **n8n** | đang chạy: `tongtai.workizen.net` | có sẵn |
| **Oracle VM** | đang chạy: 137.131.33.103 | có sẵn |
| **GitHub** | PAT chỉ-đọc — **đã chạy thật** (WTM-268/274) | xong |

⇒ **Đây là chỗ connector thứ hai nên bắt đầu**, và nó nên là **Telegram**: rẻ
nhất, không ai duyệt, và nó chạm đúng một capability chưa có (`chat`).

### 🟡 Thử được sau vài ngày — tự đăng ký, duyệt tự động

| Nền tảng | Vướng gì |
|---|---|
| **Shopify** | tạo development store miễn phí, custom app token |
| **GA4 · Search Console** | tài khoản Google thường + OAuth consent nội bộ |
| **Stripe** | test mode có ngay, nhưng webhook **cần backend** — Optional Integration Runtime đã có |

### 🔴 Chặn bởi phê duyệt — hồ sơ doanh nghiệp, hàng tuần

| Nền tảng | Vướng gì |
|---|---|
| **Shopee Partner** | hồ sơ doanh nghiệp, duyệt thủ công |
| **TikTok Shop Partner** | như Shopee |
| **Facebook / Messenger** | App Review cho `pages_messaging` |
| **Gmail** | OAuth **restricted scope** ⇒ **CASA** $500–4.500/năm, **thẩm định lại mỗi 12 tháng** |

⚠️ **Đây là nhóm kế hoạch dễ nói dối nhất.** Ghi *"test Shopee"* trong sprint
nghe như một việc kỹ thuật; thực ra nó là hồ sơ pháp lý mất hàng tuần, và
không lập trình viên nào rút ngắn được.

**Gmail đáng nhắc riêng:** đắt nhất **không vì kỹ thuật** mà vì CASA hằng năm
(kết luận WTM-238). Khuyến nghị giữ nguyên: **Share Sheet thay API**.

### ⚫ Chưa có gì để thử

| Nền tảng | Vì sao |
|---|---|
| **RevenueCat** | app **chưa lên store** ⇒ không có giao dịch nào |

Bài học đã trả giá: RevenueCat từng được dựng **trước**, publish, rồi phải gỡ.
Founder bắt được bằng một câu — *"đã lên store đâu"*. Một receiver không bao giờ
nhận gì chính là hình dạng "thứ chết trông như đang sống" mà repo này đã dọn
nhiều lần (`opportunities_table` · `channels_table` · `integrations_table`).

---

## Môi trường Dogfood — nó là gì, cụ thể

**Không phải** một bản sao hạ tầng. Là **ba lớp** đã có sẵn:

```
1. Dữ liệu thật của Workizen   — nguồn duy nhất đáng tin để thử
2. n8n Integration Runtime      — tongtai.workizen.net (đang chạy)
3. Máy thật                     — S24 Ultra + Nokia 6.1 (máy tầm thấp)
```

Không dựng thêm gì. Nguyên tắc §21 Task Order PLATFORM-002: **không tự xây thứ
đã có**.

---

## Điều kiện một connector được coi là "đã thử trên Dogfood"

Đúng bộ điều kiện WTM-268 đã đặt ra và chứng minh được — không phát minh lại:

| # | Điều kiện | Vì sao |
|---|---|---|
| 1 | Không credential ⇒ **từ chối** (403/401) | endpoint mở là endpoint bị dùng |
| 2 | Số liệu **khớp** với một phép đo độc lập | "chạy được" ≠ "đúng" |
| 3 | Gọi hai lần ⇒ `event_id` **trùng khít** | retry không được đẻ bản ghi thứ hai |
| 4 | Tham số nhạy cảm **ghim server-side** | request không được điều khiển phạm vi token |
| 5 | `truncated` khai báo trung thực | *"0 kết quả"* đọc từ dữ liệu lấy thiếu là lời nói dối trông y hệt sự thật |

Thiếu bất kỳ điều nào ⇒ **chưa** phải `verifiedOnDogfood` trong Capability
Matrix (WTM-288).

---

## Thứ tự đề xuất

| # | Connector | Vì sao trước |
|---|---|---|
| 1 | ~~GitHub~~ | ✅ xong |
| 2 | **Telegram** | rẻ nhất, không ai duyệt, chạm capability `chat` chưa có |
| 3 | **Shopify dev store** | sàn thật đầu tiên, tự tạo được, có settlement để thử WTM-286 |
| 4 | Shopee / TikTok | bắt đầu **hồ sơ** ngay từ bây giờ vì nó chạy song song, không chặn việc khác |
| 5 | RevenueCat | **sau khi** app lên store |

⚠️ Cả năm đều **chặn bởi N0**: app phải có `Provenance` (✅ WTM-282),
`Connection` (✅ WTM-283), `IdentityResolution` (WTM-285) và `Settlement`
(WTM-286) **trước** khi nạp dữ liệu thật — làm ngược thì phải migrate dữ liệu
người bán về sau.
