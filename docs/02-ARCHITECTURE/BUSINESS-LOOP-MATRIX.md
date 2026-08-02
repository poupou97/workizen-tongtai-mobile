# Business Loop Matrix

> **Founder Directive 2026-08-02 — Business Loop Completion.**
> *"Capability PASS là điều kiện cần. Business Loop PASS mới là điều kiện đủ."*

**Bảng này độc lập với [CAPABILITY-PASS-MATRIX.md](CAPABILITY-PASS-MATRIX.md).**
Ma trận kỹ thuật hỏi *"code có đúng không"*; bảng này hỏi *"người bán có đi hết
được một vòng kinh doanh không"*. Hai chiều đánh giá, **không gộp**.

**Cập nhật lần cuối:** 2026-08-02 · sau WTM-223/224/225/226 — **Business Loop Foundation đóng**.

---

## Cách audit — bắt buộc

**Xuất phát từ User Journey và Business Goal, KHÔNG phải từ source code.**
Tìm widget vắng mặt bằng `grep` chỉ ra được chỗ *chưa có nút*; nó không bao giờ
hỏi được câu quan trọng nhất:

> **"Sau khi người dùng hoàn thành hành động này, họ có biết việc tiếp theo để
> đạt mục tiêu kinh doanh là gì không?"**

Cách làm: chọn một `GoalType` → đọc kế hoạch Rule Twin lập cho nó → đi từng
bước như người bán → tại mỗi điểm dừng, trả lời câu hỏi trên. Chưa trả lời được
⇒ **chưa PASS**.

## Năm nhịp

| Nhịp | Câu hỏi |
|---|---|
| 1 | Người dùng phát hiện vấn đề hoặc cơ hội ở đâu? |
| 2 | Người dùng thực hiện hành động ở đâu? |
| 3 | Kết quả của hành động được phản ánh ở đâu? |
| 4 | Business Journey thay đổi như thế nào? |
| 5 | Người dùng biết bước tiếp theo là gì? |

**Luật:** không dùng Snackbar/Toast làm điểm kết thúc · không ép điều hướng ·
trạng thái thường trực đọc từ Single Source of Truth · không tạo state mới.

---

## Vòng theo capability

| Capability | 1 Thấy | 2 Làm | 3 Kết quả | 4 Journey đổi | 5 Bước tiếp | Vòng |
|---|---|---|---|---|---|---|
| **Business Journey** | ✅ | ✅ WTM-220 | ✅ | ✅ WTM-224 | ✅ WTM-226 | ✅ |
| **Opportunity** | ✅ | ✅ | ✅ WTM-223 | ✅ | ✅ WTM-223 | ✅ |
| **Finance** | ✅ | ✅ | ✅ | ✅ WTM-224 | ✅ | ✅ |
| **Inventory** | ✅ | ✅ | ✅ | ✅ WTM-224 | ✅ WTM-225 | ✅ |
| **Consumer** | ✅ | ✅ | ✅ | ✅ WTM-224 | ✅ WTM-225 | ✅ |
| **Reports** | ✅ | — | ✅ | — | ⚠️ | ⚠️ |
| **Producer** (Business Input) | ✅ WTM-234 | ✅ WTM-234 | ✅ WTM-234 | ❌ | ❌ | ⚠️ |
| **Producer** (danh bạ NCC) | — | — | — | — | — | Future Capability |

`—` = không áp dụng (Reports không phải nơi hành động; danh bạ nhà cung cấp
chờ dữ liệu thật).

---

## ✅ Vòng ở tầng MỤC TIÊU — đã khép (WTM-226)

**Founder 2026-08-02: WTM-226 là điểm kết thúc của Business Loop Foundation.**
Không đào sâu Goal Lifecycle thêm; Autonomous Loop chuyển sang **Producer +
Dogfood**. Nguyên tắc mới: *"Product thực tế là nguồn phát hiện bug tốt nhất —
để việc sử dụng sản phẩm dẫn dắt backlog, không để backlog tự dẫn dắt backlog."*

Đã sửa: hành trình **kết thúc được** (`JourneyState.completed` suy từ cây node,
không thêm cờ), màn Journey ghi nhận bằng **trạng thái thường trực** và mời đặt
mục tiêu kế — **mời, không tự tạo**: chỉ người bán đặt mục tiêu (WTM-191).

Và nói đúng thứ đã xảy ra: khối ghi *"đi hết hành trình"*, **không** nói *"đạt
mục tiêu"*. Làm hết mọi bước Rule Twin lập ra vẫn có thể chưa chạm số — kế hoạch
là lời khuyên tốt nhất của app, không phải lời bảo đảm. Gộp hai thứ lại là lời
nói dối đầu tiên app nói với người bán.

### Ghi lại — vì sao chỗ này bị bỏ sót lâu đến vậy

Audit đi từ `GoalType` chứ không từ màn hình, và nó tìm ra điều mà mọi vòng
audit trước bỏ sót:

**Người bán đạt được mục tiêu của mình, và sản phẩm không nói gì cả.**

Bằng chứng đọc từ code sau khi đặt câu hỏi từ phía mục tiêu:

* `JourneyState.completed` **tồn tại nhưng không có gì từng gán nó** — một hành
  trình không bao giờ kết thúc, nó chỉ đứng ở 100%.
* `GoalPace.completed` chỉ được dùng cho **một màu** và **một phép đếm**. Không
  có chỗ nào phản ứng với việc mục tiêu đã đạt.

Đi theo người bán: họ đặt *"Doanh thu 50 triệu"* → Rule Twin lập hành trình →
họ làm hết các bước → họ chạm mốc. Rồi màn hình hiện thanh tiến độ 100% và **im
lặng**. Khoảnh khắc quan trọng nhất của cả sản phẩm — người bán đạt được thứ họ
đặt ra — **không có phản hồi nào**.

Câu hỏi bắt buộc, trả lời trung thực: *"sau khi hoàn thành, họ có biết việc tiếp
theo để đạt mục tiêu kinh doanh không?"* → **Không.** Không có mục tiêu tiếp
theo, không có lời ghi nhận, không có gì.

⇒ **Business Journey: vòng ở tầng hành động PASS, vòng ở tầng mục tiêu FAIL.**

Mỗi màn đều có nút, mỗi hành động đều có kết quả, mọi suite đều xanh. Chỗ đứt
nằm ở **cuối một cung đường dài nhiều tuần** — không widget nào vắng mặt, nên
không `grep` nào tìm được. Chỉ có cách đi từ mục tiêu mới thấy.

---

## Quy tắc giữ bảng này trung thực

1. Một ô chỉ ✅ khi **đi thật được vòng đó** trong test hành vi, không phải khi
   "có widget".
2. Ô nào chưa audit ghi `?` — như ma trận kỹ thuật, `?` **không phải** PASS.
3. Vòng ở **tầng hành động** và vòng ở **tầng mục tiêu** là hai câu hỏi khác
   nhau. Một capability có thể PASS cái trước và FAIL cái sau — Business Journey
   đúng như vậy cho tới WTM-226.

---

## Vòng kế tiếp — Producer, dẫn dắt bởi Dogfood

Founder 2026-08-02: sau khi Business Loop Foundation đóng, Autonomous Loop
chuyển sang **Producer** theo thứ tự Dogfood → Concept Alignment → Source Data
còn thiếu → Business Loop của Producer.

Producer từng ghi `—` ở mọi nhịp vì danh bạ nhà cung cấp là
`SupplierSearchService.sample()` — **dữ liệu bịa**. Khép vòng cho nó bằng dữ
liệu giả là đúng thứ quyết định *Future Capability* bảo vệ, nên nhịp đầu tiên
(*"người dùng phát hiện cơ hội ở đâu"*) chưa có câu trả lời trung thực nào.

**Dogfood tìm ra câu trả lời ở chỗ khác** (ADR-TON-023): Producer không phải
danh bạ nhà cung cấp — nó quản lý **toàn bộ đầu vào**, và đầu vào thì **người
bán tự khai**, nên nó không cần danh bạ bịa nào cả. WTM-234 mở được ba nhịp
đầu bằng dữ liệu thật 100%: thấy *"tháng này tôi cam kết bao nhiêu"* · thêm/sửa
nguồn · tổng đổi ngay.

**Hai nhịp cuối vẫn ❌, và nói thẳng là ❌:**

* **Journey đổi** — chưa node hay mục tiêu nào đọc `BusinessInput`. Ghi thêm
  một khoản cam kết 500.000 đ/tháng **không** làm hành trình kinh doanh đổi một
  chữ nào.
* **Bước tiếp** — khai xong một nguồn, người bán không được nói gì về việc tiếp
  theo. Câu hỏi bắt buộc của phương pháp audit (*"sau khi hoàn thành hành động
  này, họ có biết việc tiếp theo để đạt mục tiêu kinh doanh là gì không?"*) ở
  đây trả lời là **không**.

Đó là vòng Producer kế tiếp — và nó là việc **nối** (chi phí đầu vào vào
Finance và Journey), không phải việc thêm màn.
