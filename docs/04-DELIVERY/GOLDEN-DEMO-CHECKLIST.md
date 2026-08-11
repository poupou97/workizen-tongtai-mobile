# Golden Demo Path — kịch bản bấm cho buổi trình bày

> WTM-359 (S10 · Epic WTM-349) · bản build partner 15/08/2026.
> Đường này là **đường C** trong ba đường của onboarding V2.

## Điều phải nói trước khi bấm

Ba câu, nói ra trước khi mở app, vì chúng là thứ phân biệt bản demo này với
một bản dàn dựng:

1. **Không một lời gọi AI nào xảy ra.** Mọi kết luận là Rule Twin chạy trên
   máy — không mạng, không khoá, không tài khoản. Ngắt Wi-Fi vẫn chạy đủ.
2. **Bộ dữ liệu mẫu được chọn lọc; kết quả thì không.** Engine tính findings
   từ chính bộ mẫu ấy. Có test khoá điều đó
   (`test/features/tongtai/onboarding/golden_demo_path_test.dart`).
3. **Không nền tảng nào được kết nối thật.** Sàn thương mại điện tử chỉ xuất
   hiện dưới dạng một dòng chữ, không nút.

---

## Trước buổi trình bày

| | Việc | Vì sao |
|---|---|---|
| ☐ | Gỡ app cũ **hoặc** dùng máy sạch | Onboarding chỉ hiện ở lần mở đầu tiên |
| ☐ | ⚠️ Nếu máy đang giữ **dữ liệu thật** của Founder: xuất `.ttbk` trước | P-33 — gỡ app là mất dữ liệu |
| ☐ | Bật chế độ máy bay | Chứng minh câu số 1 mà không phải nói suông |
| ☐ | Tắt xoay màn hình, đặt độ sáng cao | Tránh sự cố vặt giữa buổi |

---

## Kịch bản bấm — 9 chạm

| # | Màn | Bấm gì | Nói gì |
|---|---|---|---|
| 1 | **Gặp Tổng Tài** | `Bắt đầu` | *"Ba việc: phát hiện cơ hội, cảnh báo rủi ro, đề xuất việc cần làm."* Không có dòng "Đăng nhập" — sản phẩm **không cần tài khoản** |
| 2 | **Bạn đang kinh doanh gì?** | `Bán hàng (nhập, tồn, giao)` → `Tiếp` | Câu này lấp trường `BusinessType` của ADR-TON-023 |
| 3 | Bốn câu còn lại | chọn nhanh → `Tiếp` ×4 | *"Mùa vụ là câu quan trọng nhất với người bán Việt — luật mùa vụ ăn chính tín hiệu này."* |
| 4 | **Đưa dữ liệu** | `Dùng dữ liệu mẫu` | Chỉ vào dòng chữ dưới cùng: sàn **chưa** kết nối được, nên **không có nút** |
| 5 | **Đang hiểu doanh nghiệp** | *(tự chạy)* | ⭐ Mỗi dòng xuất hiện **sau khi** việc của nó chạy xong. Số đếm là số bản ghi thật |
| 6 | | `Tiếp tục` | |
| 7 | **Tôi đã hiểu doanh nghiệp của bạn** | đọc findings → `Tiếp tục` | ⭐ Đây là khoảnh khắc đáng tiền. Mỗi phát hiện có **lý do đọc được** và một luật đứng sau. Nếu ô *Lợi nhuận* ghi **"Chưa tính được"** — **đó là tính năng**, xem ghi chú dưới |
| 8 | **Chọn mục tiêu** | `Tăng lợi nhuận` → `Tiếp` | Bảy mục tiêu tạo mục tiêu thật; *"Chỉ khám phá trước"* cố ý không tạo gì |
| 9 | **Kế hoạch đầu tiên** | `Bắt đầu điều hành cùng Tổng Tài` | ⭐ Không màn nào nói *"Hoàn tất thiết lập"*. Mỗi việc có **VẤN ĐỀ → BẰNG CHỨNG → HÀNH ĐỘNG → ƯU TIÊN** |
| — | **Trang chủ** | | Việc đầu tiên của kế hoạch nằm ngay trên đầu, bấm được |

---

## ⭐ Ba câu trả lời cho ba câu hỏi khó

**"Sao ô Lợi nhuận ghi *Chưa tính được*?"**
Vì thiếu giá vốn hoặc thiếu phí sàn. Một con số lợi nhuận thiếu hai thứ đó
**luôn đẹp hơn sự thật** — và đó là con số nguy hiểm nhất trong cả sản phẩm.
Sản phẩm chọn từ chối kèm lý do thay vì đoán. Đây là thứ đáng khoe, không phải
thứ cần giấu.

**"Có phải các con số này viết sẵn không?"**
Đẩy `Tiếp tục` rồi mở lại đường này với một bộ dữ liệu khác — findings đổi
theo. Test `golden_demo_path_test.dart` khẳng định số đếm mỗi chặng bằng đúng
số bản ghi vừa ghi xuống, và quét mã nguồn engine để chặn mọi con số của ảnh
concept (`1.246`, `328`, `12,4`…) lọt vào.

**"Nếu tôi chưa có dữ liệu gì thì sao?"**
Chọn *"Chưa có dữ liệu"* ở bước 4 — app **bỏ hẳn** bước phân tích và đi thẳng
tới mục tiêu rồi kế hoạch khởi đầu. Nó **không** hiện "đang phân tích 1.246 đơn
hàng" trên một máy chưa có đơn nào. Đó là đường B, và nó cũng được test khoá.

---

## Sau buổi trình bày

| | Việc |
|---|---|
| ☐ | `Thêm → Xoá dữ liệu mẫu` nếu máy sẽ dùng tiếp |
| ☐ | Khôi phục `.ttbk` nếu đã gỡ app để demo |
| ☐ | Ghi lại câu hỏi nào không trả lời được — chúng là backlog thật |
