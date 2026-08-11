# Onboarding V2 — bản build partner

> Epic **WTM-349** · `TongTai-DEMO-onboarding-v2-v0.1.0+5.apk` · 2026-08-11
> Cài **song song** app thật (`com.workizen.tongtai.demo`, nhãn *"Tổng Tài
> DEMO"*) — **không đè, không mất dữ liệu**.

## Đổi gì

Onboarding cũ hỏi bốn câu hồ sơ rồi thả người bán vào một ứng dụng trống: họ
trả lời xong và **không nhận lại gì**.

Bây giờ nó kết thúc bằng việc người bán **đã nhìn thấy một điều đúng về chính
doanh nghiệp mình**, một mục tiêu đã chọn, và một kế hoạch bấm được:

```
GẶP → HIỂU DOANH NGHIỆP → ĐƯA DỮ LIỆU → PHÂN TÍCH THẬT
    → "TÔI ĐÃ HIỂU DOANH NGHIỆP CỦA BẠN" → CHỌN MỤC TIÊU
    → KẾ HOẠCH ĐẦU TIÊN → TRANG CHỦ
```

## Ba đường, không phải một

| | Ai đi | Kết thúc bằng |
|---|---|---|
| **A** | có dữ liệu, nhập Excel/CSV | phát hiện thật + kế hoạch |
| **B** | chưa có dữ liệu | **bỏ hẳn** bước phân tích → kế hoạch khởi đầu |
| **C** | dữ liệu mẫu (đường demo) | phát hiện tính thật trên bộ mẫu |

Đường B là nhánh phổ biến nhất của người dùng mới, và concept không vẽ nó. Nó
**không bao giờ** hiện *"đang phân tích 1.246 đơn hàng"* trên một máy chưa có
đơn nào — điều đó được ép bằng cấu trúc, không bằng một câu `if` trong màn.

## Bốn thứ cố ý KHÔNG có

1. **Không lối đăng nhập.** Concept vẽ *"Đã có tài khoản? Đăng nhập"*; nó mâu
   thuẫn D-4 / Local First. Muốn có tài khoản thì cần một ADR, không phải một
   dòng chữ dưới cái nút.
2. **Không nút mang tên sàn.** Shopee · TikTok · Lazada · Shopify · Google
   Drive chỉ là một dòng chữ tĩnh. Chưa có connector nào tồn tại.
3. **Không xu hướng kênh.** *"TikTok Shop tăng 27%"* không hiện: có `vendor`
   trên đơn **không tương đương** có luật xu hướng.
4. **Không "tác động dự kiến +8,4 triệu".** Đó là lời hứa lợi nhuận cho một
   việc chưa ai làm. Trường ấy **không tồn tại** trong mã, để không ai điền nó
   "tạm".

## Thứ đáng khoe nhất lại là một lời từ chối

Ô **Lợi nhuận** có thể ghi *"Chưa tính được"* kèm lý do (thiếu giá vốn, hoặc
đơn sàn chưa có dòng đối soát). Một con số lợi nhuận thiếu hai thứ đó **luôn
đẹp hơn sự thật**, và đó là con số nguy hiểm nhất trong cả sản phẩm.

Cùng kỷ luật ấy chạy khắp nơi: *chưa đủ dữ liệu để xét* và *đã xét, không có
gì* là **hai câu khác nhau**, hiện bằng hai màn khác nhau.

## Chạy được ở đâu

Không mạng · không khoá AI · không tài khoản. Bật chế độ máy bay rồi đi trọn
cả ba đường — không lời gọi AI nào xảy ra trong toàn bộ onboarding.

## Cách xem

`docs/04-DELIVERY/GOLDEN-DEMO-CHECKLIST.md` — 9 chạm, kèm ba câu trả lời cho
ba câu hỏi khó nhất đối tác sẽ hỏi.

## Bằng chứng

| | |
|---|---|
| Test | **2590+** xanh |
| Analyze | sạch |
| CI | xanh trên cả bốn PR (#217 #218 #219 #220) |
| Governance mới | 4 bộ quét, mỗi bộ đã chứng minh **đỏ khi phá** |

## ⏳ Còn thiếu trước khi gọi là xong

- **Dogfood máy thật** (WTM-360): chưa chạy — máy S24 chưa cắm. Bài học
  WTM-342 còn nguyên giá trị: 2488 test xanh, một vòng cầm máy bắt ra bốn lỗi.
  Đây là việc duy nhất chặn giữa "suite xanh" và "partner-ready".
- **Bộ tư thế con cáo** (§17): `icon app.png` đã có; các tư thế cho từng màn
  (giơ ngón cái · ngồi máy tính · ăn mừng · chỉ tay) là **phụ thuộc asset**,
  Founder cung cấp. Không chặn đường tới hạn — bản build hiện không dùng linh
  vật.
