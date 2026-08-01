# Risk Analysis

*Workizen là khách hàng đầu tiên của Tổng Tài · 2026-08-01*

---

## Rủi ro cao

### R1 — Trì hoãn phát hành

| | |
|---|---|
| **Xảy ra khi** | Journey nào cũng được chuyển thành backlog trước closed beta |
| **Hệ quả** | Ngày ra cửa hàng lùi ít nhất 4–8 tuần cho A, 3–6 tháng cho B |
| **Vì sao nặng** | Mâu thuẫn trực tiếp ADR-TON-020 ký cách đây vài giờ: *"đưa sản phẩm đến người dùng thật càng sớm càng tốt"*. Sản phẩm cách cửa hàng **2 hạng mục nội dung + 1 chữ ký iOS** — không hạng mục nào là code |
| **Giảm thiểu** | Bất kỳ journey nào cũng đứng **sau** WTM-175 |

### R2 — Dogfooding thay thế customer discovery

| | |
|---|---|
| **Xảy ra khi** | Phản hồi từ Workizen được coi là bằng chứng thị trường |
| **Hệ quả** | Sản phẩm tối ưu cho **một** người dùng, và người đó là người xây nó |
| **Vì sao nguy hiểm nhất** | Nó **cảm giác giống** xác thực sản phẩm. Có dữ liệu thật, có bug thật, có cải tiến thật — nhưng không có **người lạ nào** nói *"tôi sẽ trả tiền cho cái này"* |
| **Dấu hiệu nhận ra** | Có tính năng được xây vì Founder khó chịu, chứ không vì người bán nào phàn nàn |
| **Giảm thiểu** | Dogfooding **cộng thêm** closed beta, không **thay thế** |

### R3 — Đa tiền tệ là refactor xuyên miền, không phải một story

| | |
|---|---|
| **Xảy ra khi** | Journey A (USD) hoặc B (CNY) được chấp nhận |
| **Bằng chứng** | `Order`/`OrderItem` **không có trường tiền tệ** (F1); `TongtaiFormatters` **hard-code `₫`** (F2) |
| **Hệ quả** | Chạm mọi công thức lãi lỗ · mọi báo cáo · mọi Rule Twin · `.ttbk` v2 · migration. Và **tỷ giá là dữ liệu theo thời gian** — lãi tính theo tỷ giá ngày mua hay ngày bán? Đó là câu hỏi kế toán, không phải câu hỏi lập trình |
| **Giảm thiểu** | Nếu làm: ADR riêng, **trước** mọi story implementation |

### R4 — Journey 1 làm rỗng sản phẩm trong khi làm rộng nó

| | |
|---|---|
| **Xảy ra khi** | Digital Product trở thành vertical thật |
| **Hệ quả** | Inventory, Producer và phần vận đơn của Consumer **vô nghĩa** với sản phẩm số ⇒ 3/8 capability không được dùng, không được kiểm, dần mục |
| **Nguy hiểm phụ** | Sản phẩm bắt đầu tối ưu cho **nhu cầu của công ty phần mềm** (MRR, churn, payout 30% của store) — thứ chị bán quần áo ở Bình Thạnh không cần |
| **Giảm thiểu** | Ranh giới cứng: dữ liệu digital là **bộ test**, không phải **vertical** |

### R5 — Journey 2 là quyết định kinh doanh đội lốt quyết định sản phẩm

| | |
|---|---|
| **Xảy ra khi** | Cross-border được chấp nhận |
| **Hệ quả thật** | Vốn nhập hàng · thủ tục hải quan · kho · hàng chôn vốn · **và sự chú ý của Founder chia đôi** đúng lúc sản phẩm cần ra thị trường |
| **Điểm mù** | Nếu business đó thua lỗ, sản phẩm mất luôn người dùng duy nhất |
| **Giảm thiểu** | Chỉ chọn nếu Founder **vốn dĩ đã muốn** làm business này vì lý do riêng. Không mở công ty để kiểm thử phần mềm |

## Rủi ro trung bình

| # | Rủi ro | Giảm thiểu |
|---|---|---|
| **R6** | **Trùng backlog đã cam kết** — "AI Weekly Review" đã là WTM-179 (F7); journey 1 tạo đường thứ hai tới cùng việc | Không tạo story mới cho việc đã có epic |
| **R7** | **Sản phẩm đổi định vị mà không có ADR.** Tổng Tài được thiết kế **ngang** (8 capability cho mọi người bán SME). Chọn vertical là **đổi định vị**, đang đi vào dưới dạng "nghiên cứu journey" | Nếu chọn vertical: **ADR tường minh**, không quyết ngầm |
| **R8** | **Backlog phình lại lần hai.** Sáng nay 62 → 10 issue; 51 issue bị đóng phần lớn vì viết cho kiến trúc chưa chốt | Không tạo Jira cho đến khi Founder duyệt nghiên cứu — **đúng như directive đã yêu cầu** |
| **R9** | **Nền tảng số thay đổi điều khoản.** Gumroad/Lemon Squeezy/App Store đổi định dạng báo cáo hoặc chính sách payout | File Bridge là adapter — chịu được đổi định dạng tốt hơn OAuth |
| **R10** | **Dữ liệu doanh thu của chính công ty nằm trong app** đang phát triển | Nó local-first và không rời máy — nhưng nếu bật `.ttbk` chia sẻ thì phải cẩn thận |

## Rủi ro thấp nhưng đáng ghi

| # | |
|---|---|
| **R11** | File xuất của các sàn Trung Quốc (1688/Taobao) thường **encoding GBK**, không phải UTF-8 — sẽ là bài kiểm tra thật cho File Bridge |
| **R12** | Journey 1 dùng nhiều nguồn nhỏ (Gumroad, Lemon Squeezy, 2 store, Shopify) ⇒ **5 connector cho một doanh nghiệp** |

---

## Rủi ro **không** tồn tại — để anh không lo nhầm

- ❌ *"Dogfooding là ý tưởng tồi"* — **không phải.** Founder dùng app hằng ngày
  là điều tốt nhất trong directive này. Vấn đề nằm ở **vertical**, không nằm ở
  dogfooding.
- ❌ *"Ý tưởng này phá kiến trúc"* — không. File Bridge (ADR-TON-020) đọc file
  Gumroad hay file Shopee bằng **cùng một cơ chế**. Kiến trúc chịu được cả hai.
- ❌ *"Phải chọn ngay"* — không. Phương án E (phép thử 1 tuần) biến câu hỏi này
  thành có thể trả lời bằng bằng chứng, với chi phí gần bằng 0.

---

## Rủi ro của việc **không làm gì**

Cần nói cho công bằng — ý tưởng của Founder ra đời từ một vấn đề có thật:

| | |
|---|---|
| **Sản phẩm chưa có người dùng thật nào.** | Mọi ưu tiên, kể cả bản phân tích này, đang được quyết bằng suy luận |
| **Toàn bộ kiểm thử chạy trên dữ liệu mẫu** (`sample-` seed) | Chưa ai biết sản phẩm cư xử thế nào với dữ liệu bừa bộn thật |
| **Founder chưa dùng sản phẩm hằng ngày** | Người quyết hướng sản phẩm chưa phải người dùng nó |

**Ba điều này đều đúng, và cả ba đều được giải quyết bởi phương án D — không cần
vertical nào.**
