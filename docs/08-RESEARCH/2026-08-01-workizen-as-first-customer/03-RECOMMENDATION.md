# Recommendation

*Workizen là khách hàng đầu tiên của Tổng Tài · 2026-08-01*

---

## Khuyến nghị: **E rồi D. Không chọn vertical trong vòng này.**

**Bước 1 — Phương án E (1 tuần, không code, chạy song song WTM-175):**
mở file thật ra xem. Xuất file từ Gumroad / App Store / Google Play của
Workizen, **và** xin 1–2 người bán thật một file xuất Shopee/TikTok. Ánh xạ tay
vào domain model hiện tại. Trả lời đúng một câu:

> **Domain model hôm nay biểu diễn được bao nhiêu phần trăm mỗi loại file, và
> thiếu chính xác cái gì?**

**Bước 2 — Phương án D (bắt đầu ngay hôm nay, song song):**
Founder cài bản release và **nhập dữ liệu tài chính thật của Workizen** vào
Finance. Không cần một dòng code nào. Đây là toàn bộ giá trị của "dogfooding"
mà không có chi phí nào của "vertical".

**Không chọn A, B hay C trong vòng này.**

---

## Vì sao

### 1. Cả hai journey đều có 0 dòng dữ liệu hôm nay

Đây là phát hiện quyết định, và nó khiến câu hỏi "chọn journey nào" trở nên
sớm:

- **Journey 1:** app chưa lên store (F6), sản phẩm miễn phí ở Phase 2 (F5),
  không có mô hình recurring trong code (F3). *"Subscription · Revenue"* là dữ
  liệu **chưa tồn tại**.
- **Journey 2:** Workizen **chưa vận hành** business xuyên biên giới nào.

Chọn giữa hai bộ dữ liệu rỗng là chọn giữa hai giả thuyết. Phương án E biến nó
thành chọn giữa hai **quan sát**, với chi phí một tuần.

### 2. Chưa ai mở một file nào ra xem

Toàn bộ tranh luận này — của anh và của tôi — đang đoán xem file Gumroad hay
file 1688 khớp domain model đến đâu. Câu hỏi đó **trả lời được trong một tuần,
không cần code**, và câu trả lời sẽ quyết định giúp chúng ta.

Tôi có thể sai trong bản phân tích này. Phương án E là cách rẻ nhất để biết.

### 3. Điều tốt nhất trong ý tưởng của anh không cần vertical nào

Anh muốn trở thành người dùng của sản phẩm. **Việc đó làm được hôm nay** — cài
app, nhập dữ liệu tài chính Workizen vào Finance. Không cần chọn journey, không
cần Epic, không cần một dòng code.

Mọi thứ còn lại trong directive — Gumroad, Lemon Squeezy, 1688, kho, logistics —
là **danh sách connector**, và ADR-TON-020 sáng nay đã trả lời câu hỏi connector:
**file trước, API sau**.

### 4. Vertical là đổi định vị sản phẩm, không phải chọn dữ liệu

Tổng Tài được thiết kế **ngang**: 8 capability cho **mọi** người bán SME Việt
Nam. Chọn một vertical là **thay đổi định vị**, và nó đang đi vào dưới dạng
"nghiên cứu journey".

Nếu anh muốn Tổng Tài trở thành sản phẩm dọc, đó là quyết định lớn và xứng đáng
có **ADR riêng, tường minh**. Không nên quyết ngầm qua việc chọn nguồn dữ liệu.

### 5. Nó mâu thuẫn với quyết định anh vừa ký

ADR-TON-020, vài giờ trước:

> *"Mục tiêu lớn nhất từ bây giờ: đưa sản phẩm đến người dùng thật càng sớm càng
> tốt."*

Sản phẩm cách cửa hàng **hai hạng mục nội dung** (địa chỉ liên hệ, điều khoản
dịch vụ) và **một chữ ký iOS** — sáng nay iOS đã build thành công lần đầu, nên
chỉ còn chữ ký. Không hạng mục nào là code, và **không hạng mục nào được giải
quyết bởi việc chọn vertical**.

---

## Nếu anh vẫn muốn chọn một journey ngay

Tôi làm theo. Trong trường hợp đó:

**Chọn Digital Product (A)** — nhưng với ranh giới cứng:

> Dữ liệu digital product của Workizen là **bộ dữ liệu kiểm thử đầu tiên cho
> File Bridge**, **KHÔNG** phải một vertical của sản phẩm.
>
> Không thêm mô hình subscription. Không thêm MRR/churn. Không thêm đa tiền tệ.
> Không thêm màn hình nào.

Lý do chọn A thay vì B: Workizen **đã có** business đó (không phải mở công ty
thứ hai), file xuất có cấu trúc ổn định và tài liệu công khai, và đọc sai file
của chính mình thì **không ai mất tiền**.

**Không chọn B** trừ khi anh **vốn dĩ đã muốn** làm business nhập khẩu vì lý do
riêng. Nếu có, hãy nói — điều đó lật ngược toàn bộ phân tích này, vì lúc đó chi
phí lớn nhất của B bằng 0 và nó trở thành lựa chọn tốt nhất trong năm. **Chỉ anh
trả lời được câu đó.**

**Không chọn C.** Xây nền cho hai vertical chưa cái nào được chứng minh là cần —
đúng loại việc mà 51 issue bị đóng sáng nay đã minh hoạ.

---

## Thứ tự tôi đề nghị

```
HÔM NAY   Founder cài app, nhập dữ liệu tài chính Workizen thật  (phương án D)
          → 0 dòng code, giữ nguyên mọi ưu tiên

TUẦN NÀY  WTM-175 Release Readiness tiếp tục — không bị chặn bởi nghiên cứu này
          Song song: phép thử file 1 tuần                        (phương án E)

SAU ĐÓ    Founder đọc kết quả phép thử → chọn A / B / D / không chọn gì
          → CHỈ khi đó mới tạo Epic
```

---

## Điều tôi cần từ anh

| # | Câu hỏi | Ảnh hưởng |
|---|---|---|
| 1 | **Anh có vốn dĩ muốn làm business nhập khẩu không**, độc lập với Tổng Tài? | Lật ngược toàn bộ đánh giá phương án B |
| 2 | Workizen **hôm nay có doanh thu thật** từ Gumroad/Lemon Squeezy/Shopify không? | F5/F6 nói App Store và subscription = 0; các nguồn kia tôi **không biết** và không đoán |
| 3 | Anh muốn Tổng Tài là sản phẩm **ngang** hay **dọc**? | Nếu dọc: cần ADR định vị, không quyết ngầm qua chọn journey |
| 4 | Duyệt phương án **E + D**, hay chọn một journey ngay? | Quyết định đầu ra của vòng nghiên cứu này |

---

## Một câu cuối, nói thẳng

Ý tưởng "Workizen là khách hàng đầu tiên" có một hạt nhân rất tốt: **người
quyết hướng sản phẩm nên là người dùng nó mỗi ngày.** Tôi giữ nguyên hạt nhân
đó trong khuyến nghị.

Nhưng "khách hàng đầu tiên" và "người dùng đầu tiên" là hai thứ khác nhau.
Workizen có thể là **người dùng** đầu tiên ngay hôm nay. Nó **không thể** là
**khách hàng** đầu tiên, vì nó không có bài toán mà sản phẩm này giải — trừ khi
anh mở đúng cái business mà sản phẩm phục vụ, và đó là câu hỏi số 1 ở trên.

Người bán hàng thật, có 6 tháng dữ liệu Shopee và một file xuất trong máy, vẫn
là khách hàng đầu tiên đáng giá hơn. Và họ đang ở cách chúng ta **hai hạng mục
nội dung**.
