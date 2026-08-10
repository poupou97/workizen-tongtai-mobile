# Ma trận trải nghiệm — Tổng Tài

> WTM-341 (E5 · Epic WTM-336) · cập nhật **2026-08-10** · nguồn: `main` sau PR #212.
> Founder Task Order EXPERIENCE-FIRST BUSINESS SIMULATION §39.

Ma trận này trả lời **một** câu hỏi: *hành trình nào thật sự chạy trọn, và hành
trình nào mới có dữ liệu mà chưa có màn?*

**Ô trống là thông tin, không phải thất bại.** Tô đầy bằng ô "có" giả sẽ phá
đúng cái mà ma trận sinh ra để đo.

---

## Ký hiệu

| | Nghĩa |
|---|---|
| **✅** | Chạy thật, có test khoá |
| **◐** | Có, nhưng **là kịch bản viết sẵn** hoặc mới một phần — đọc chú thích |
| **—** | Chưa có |

## ⚠️ Ba điều phải đọc trước khi đọc ma trận (§40)

1. **Không một lời gọi AI nào xảy ra trong bản demo.** Cột *Kết luận* là **Rule
   Twin** — luật chạy trên máy, không cần mạng, không cần khoá. Những câu ký tên
   "Tổng Tài" trong hội thoại là **kịch bản viết sẵn** (`demo_scenario.dart`),
   không phải văn bản do mô hình sinh. AI Router chỉ chạy khi người bán tự nhập
   khoá (BYOK) và bản demo **không** gọi nó.
2. **Không nền tảng nào được kết nối thật.** Mười nền tảng mang nhãn
   `Demo — đang phát` là **đồng hồ mô phỏng đang sinh việc mang tên chúng**.
   Không token, không request, không byte nào rời máy.
3. **Cột *Hành động* là thật, cột *tới đích* thì không.** Mọi hành động đi trọn
   `plan → approve → run` với vòng đời, lease và chống lặp; chỉ bước cuối — gửi
   ra ngoài — chưa xảy ra, và nó tự khai bằng `vendor: demo` + `externalId` tiền
   tố `demo:`.

---

## Ma trận · 21 hành trình × 8 cột

| # | Hành trình | Dữ liệu demo | Màn hình | Kết luận (Rule Twin) | Đề xuất | Duyệt | Hành động | Kết quả | Dòng thời gian |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Discover** — khách biết tới shop | ✅ kênh chạm đầu tiên | ✅ Khách 360 | ✅ suy từ việc sớm nhất | — | — | — | — | ✅ |
| 2 | **Lead** — khách quan tâm chưa mua | ✅ bình luận FB/IG | ✅ Hội thoại | — | — | — | — | — | ✅ |
| 3 | **Conversation** — nhắn qua lại | ✅ 4 hội thoại | ✅ Hội thoại + chi tiết | ◐ nháp **kịch bản** | ◐ nháp | ✅ `Cần bạn duyệt` | ✅ `customer.send_message` | ✅ `demo:` | ✅ |
| 4 | **Recommendation** — gợi ý hàng cho khách | ✅ từ đơn thật | ✅ Khách 360 | ✅ mua kèm, có lý do | ✅ 3 gợi ý | — | — | — | — |
| 5 | **Order** — đơn về | ✅ 112 nhập + ~90 sinh | ✅ Trang chủ · Khách 360 | ✅ doanh thu · AOV | — | — | — | ✅ | ✅ |
| 6 | **Payment** — tiền vào tài khoản | ✅ ngân hàng báo có | ◐ Tài chính | — | — | — | — | — | ✅ |
| 7 | **Fulfillment** — đóng gói, bàn giao | ✅ bàn giao → đang giao → đã giao | ✅ Dòng thời gian | ◐ | — | — | — | ✅ kiện vào sổ | ✅ |
| 8 | **Shipment** — kiện đi tới đâu | ✅ 3 hãng, có chậm | ◐ chỉ trong Brief/Cơ hội, **không có màn riêng** | ✅ so hàng xóm cùng tuyến | ✅ | ✅ Brief | — chưa có handler liên hệ hãng | — | ✅ |
| 9 | **Support** — khách phàn nàn | ✅ khách giận ngày 5 | ✅ Hội thoại | ◐ | ◐ | ✅ bắt buộc duyệt | ✅ | ✅ | ✅ |
| 10 | **Refund** — hoàn tiền | ✅ đòi → duyệt → hoàn | ✅ Hội thoại · Tài chính | ✅ vào lời thật | ◐ | ✅ bắt buộc duyệt | ◐ | ✅ dòng đối soát chiều ra | ✅ |
| 11 | **Review** — đánh giá | ✅ 3 sao, nối câu chuyện kiện chậm | ✅ Khách 360 | — | — | — | — | — | ✅ |
| 12 | **Repeat** — tới nhịp mua lại | ✅ ngày 28 | ✅ Khách hàng · Cơ hội | ✅ RFM | ✅ | ✅ Brief | ◐ qua `customer.send_message` | ◐ | ✅ |
| 13 | **Churn** — khách lặng lâu | ✅ ngày 21 | ✅ Khách hàng rủi ro | ✅ `customer_risk_rule` | ✅ | ✅ Brief | ◐ | ◐ | ✅ |
| 14 | **Sourcing** — tìm nguồn | ✅ 1688 báo giá | ✅ Nguồn hàng · So sánh NCC | ✅ `supplier_comparison` | ✅ | ✅ Brief | ✅ `inventory.create_purchase_order` | ✅ `demo:` | ✅ |
| 15 | **Inventory** — tồn kho | ✅ tồn giảm theo đơn | ✅ Kho · Cảnh báo tồn | ✅ sắp hết · hàng nằm | ✅ | ✅ Brief | ✅ | ✅ | ✅ |
| 16 | **Supplier** — nhà cung cấp | ✅ 12 NCC · 124 báo giá | ✅ Nhà cung cấp | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ |
| 17 | **Campaign** — quảng cáo | ✅ ngày 14 | — **không có màn chiến dịch** | ◐ câu kịch bản | — | — | — chưa đăng ký handler | — | ✅ |
| 18 | **Settlement** — đối soát sàn | ✅ mỗi tuần | ✅ Tài chính | ✅ phí sàn vào lời thật | ✅ | ✅ Brief | ◐ | ◐ | ✅ |
| 19 | **Profit** — lời thật | ✅ suy từ đơn + phí | ✅ Báo cáo · Tài chính | ✅ `TrueProfitRule` | ✅ lỗ sau phí | ✅ Brief | ◐ | ◐ | ◐ |
| 20 | **Goal** — mục tiêu kinh doanh | — kịch bản không tạo mục tiêu | ✅ Mục tiêu · Hành trình | ✅ tiến độ | ✅ kế hoạch | — | — | — | — |
| 21 | **Automation** — tự chủ | ◐ | ✅ Tự chủ · Hoạt động | ✅ | ✅ | ✅ 4 mức | ✅ | ✅ | ✅ |

### Đếm theo cột

| Cột | ✅ | ◐ | — |
|---|---|---|---|
| Dữ liệu demo | **18** | 2 | 1 |
| Màn hình | **16** | 3 | 2 |
| Kết luận | **13** | 4 | 4 |
| Đề xuất | **9** | 3 | 9 |
| Duyệt | 10 | 0 | 11 |
| Hành động | 5 | 5 | 11 |
| Kết quả | **8** | 4 | 9 |
| Dòng thời gian | **19** | 2 | 0 |

---

## Đọc ma trận này thế nào

**Bốn hành trình chạy trọn từ đầu tới cuối** — có dữ liệu, có màn, có kết luận,
có đề xuất, có cửa duyệt, có hành động, có kết quả:
`Conversation` · `Sourcing` · `Inventory` · `Supplier`.

**Hình dạng của phần còn lại nói một điều rõ ràng:** cột *Dòng thời gian* gần
đầy (15 ✅) trong khi cột *Hành động* gần trống (5 ✅). Tổng Tài hôm nay **thấy**
gần hết doanh nghiệp và **làm** được rất ít phần của nó. Đó không phải lỗi — đó
là chỗ đang đứng, và là dữ kiện cho câu hỏi concept số 2 dưới đây.

**`Refund` và `Review` đã đóng** (WTM-345): hai hàng đó chỉ thiếu kịch bản, và
loại sự kiện lẫn cấu trúc đối soát đều đã có sẵn — đóng chúng **không** cần kiến
trúc mới. Hoàn tiền nay vào **sổ đối soát thật** (`kind: refund`, `direction:
outbound`, `fundedBy: seller`) nên nó ăn vào **lời thật** của người bán, đúng chỗ
người bán Việt Nam mất tiền nhiều nhất mà báo cáo hay bỏ sót.

**Không còn hàng nào trống hoàn toàn** (WTM-347). Ba hàng cuối đóng bằng **tái
dùng**, không thêm màn nào:

* **Discover** — kênh chạm đầu tiên, suy từ việc sớm nhất có mang tên nền tảng.
  Khách gõ tay vào danh bạ thì **để trống**, vì đoán một kênh cho họ là bịa ra
  một nguồn khách.
* **Recommendation** — mua kèm, suy từ đơn **thật**, kèm lý do đọc được ("3
  khách khác mua kèm"). **Rỗng khi chưa biết gì**, không rơi về danh sách bán
  chạy — một danh sách bán chạy đội lốt gợi ý cá nhân luôn có nội dung, nên
  không ai nhận ra nó chưa bao giờ biết gì về khách.
* **Fulfillment** — bàn giao → đang giao → đã giao. Trước đây chỉ kiện **hỏng**
  mới thành bản ghi, nên người bán chỉ thấy khi có chuyện; phần lớn thời gian
  mọi thứ chạy đúng, và nhìn thấy điều đó cũng là một tính năng.

Cột **Hành động** vẫn 5 ✅ — đó là khoảng cách thật còn lại giữa *thấy* và *làm*,
và là dữ kiện cho câu hỏi concept "Business OS hay ERP mini".

---

## Nguồn kiểm chứng

| Khẳng định | Kiểm ở đâu |
|---|---|
| 10 nền tảng đang phát | `test/features/tongtai/connection/demo_connected_test.dart` — đếm từ **kịch bản thật** |
| demo không đè `connected`/`fileBridge` | cùng file, hai chiều |
| nháp là nháp cho tới khi bấm Gửi | `test/features/tongtai/simulation/customer_conversation_test.dart` |
| Gửi ⇒ hành động thật, khai là mô phỏng | `test/features/tongtai/simulation/conversation_screen_test.dart` |
| đẩy đồng hồ đổi **miền thật** | `test/features/tongtai/simulation/business_life_screen_test.dart` |
| hoàn tiền vào sổ đối soát, đòi hoàn thì chưa | `test/features/tongtai/simulation/simulation_engine_test.dart` |
| Discover không đoán kênh · gợi ý rỗng khi chưa biết | `test/features/tongtai/consumer/customer_insight_test.dart` |
| một dòng thời gian, cơ hội không lên đó | `test/features/tongtai/simulation/business_life_screen_test.dart` |
| toàn bộ | `flutter test` — 2513 xanh |
