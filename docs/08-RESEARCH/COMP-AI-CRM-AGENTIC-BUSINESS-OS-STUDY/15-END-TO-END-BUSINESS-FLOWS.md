# 15 · Tám luồng end-to-end

> **PROPOSAL.** Mỗi luồng ghi rõ mức khả thi **hôm nay** vs **cần đối tác** vs **khái niệm tương lai**.

Ký hiệu: 🟢 làm được với nền hiện có · 🟡 cần connector chưa có · 🔴 cần phê duyệt/đối tác

## 1 · Nhắc nhập hàng 🟢

| Bước | Bản ghi | Ghi chú |
|---|---|---|
| WHEN | `Evidence` từ `Product.totalStock` dưới ngưỡng | dữ liệu **đã có trên máy** |
| IF | Rule Twin dự báo hết trong 7 ngày | `predictive/` đã có |
| THINK | so nhà cung cấp + lead time + margin | cần `costPrice`; thiếu ⇒ `insufficient` |
| APPROVAL | `CONFIRM` mặc định | |
| DO | `BusinessAction{type: inventory.create_purchase_order, vendor: internal}` | ghi vào Producer, **chưa** gọi API sàn |
| OBSERVE | người bán cập nhật khi hàng về ⇒ `Result` | |

**Luồng khả thi nhất và nên làm đầu tiên** — không cần connector nào.

## 2 · Win-back khách VIP 🟡

`Evidence`(45 ngày chưa mua) → `AgentTask` → `ProposedChange`(ưu đãi) → duyệt → `BusinessAction{customer.send_message, vendor: telegram}` → `Result`(khách mua lại).

Chặn ở khâu **gửi**: cần connector Telegram. Phần *phát hiện + soạn nội dung* làm được ngay ở mức `SUGGEST` — người bán tự copy đi gửi. **Đó đã là giá trị thật**, và là cách rẻ nhất kiểm chứng luồng trước khi viết connector.

## 3 · Chăm sóc khách / trả lời tin 🟡

Tin đến → phân loại ý định → nạp ngữ cảnh khách → soạn nháp → duyệt → gửi → đánh dấu đã xử lý.

⚠️ **`AUTO` bị cấm mặc định ở luồng này** (xem `13-AUTONOMY-POLICY.md`): tin nhắn tới người ngoài danh bạ, và nội dung sai không thu hồi được.

## 4 · Tối ưu marketing 🔴

CPA tăng → AI phân tích → đề nghị dừng/đổi ngân sách → duyệt → thực thi → đo.

Cần Facebook App Review. **Bước "đo" phụ thuộc `SettlementLine`** (WTM-292) — không có chi phí thật thì "tối ưu" chỉ là đoán.

## 5 · Cơ hội sản phẩm 🟡

Xu hướng → cơ hội → nghiên cứu → nhà cung cấp → biên lợi nhuận → Journey.

Opportunity Hub đã có (ADR-TON-022). Thiếu **nguồn xu hướng bên ngoài**.

## 6 · Cảnh báo tài chính 🟢

Refund/phí/payout → `SettlementLine` → Rule Twin tính **lợi nhuận thật** → nếu `insufficient` thì **nói thiếu gì**, không đoán → cảnh báo → khuyến nghị.

**Nền đã xong (WTM-292).** Chỉ thiếu nguồn dữ liệu phí — hôm nay người bán tự nhập, và như vậy đã chạy được.

## 7 · Vận chuyển 🔴

Phát hiện chậm → liên hệ hãng/khách → theo dõi.

Cần connector logistics. **Phần khả thi ngay:** phát hiện đơn quá hạn giao từ dữ liệu trên máy + nhắc người bán.

## 8 · Livestream 🔴 *(phần lớn là khái niệm)*

Cơ hội → kế hoạch nội dung → lịch → kịch bản/asset → **hành động trên nền tảng** → tín hiệu hiệu quả → theo dõi.

⚠️ **Phải nói thẳng theo §17:** không giả định API livestream cho phép tự động hoá hoàn toàn.

| Phần | Mức |
|---|---|
| chọn sản phẩm, lên lịch, soạn kịch bản | 🟢 **làm được ngay** — thuần nội dung + dữ liệu trên máy |
| đẩy lịch lên nền tảng | 🔴 cần Partner API |
| điều khiển buổi live | ⚫ **khái niệm** — chưa nền tảng nào mở đủ |
| đọc số sau buổi live | 🔴 cần Partner API |

## Điều tám luồng này chứng minh

**Ba luồng có giá trị mà không cần connector nào** (1, 6, và phần soạn nội dung của 2, 5, 8). Chúng chỉ cần: `ProposedChange` có nơi lưu + `AutonomyRule` + màn Automation Card.

⇒ Đường ngắn nhất tới giá trị thật **không đi qua connector**. Nó đi qua **vòng đề xuất**.
