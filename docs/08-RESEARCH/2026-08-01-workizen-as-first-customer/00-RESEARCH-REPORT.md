# Research Report — Workizen là khách hàng đầu tiên của Tổng Tài

*Founder Directive: Product Research Before Backlog · 2026-08-01*

> **Phạm vi:** nghiên cứu, phản biện. Không Epic, không Jira, không Roadmap,
> không Product Bible, không backlog. Chỉ chuyển thành backlog **sau khi Founder
> phê duyệt kết quả**.
>
> **Nguyên tắc:** không mặc định hướng nào đúng. Phản biện trực tiếp giả định
> của Founder. Mọi khẳng định về sản phẩm đều **kiểm trong code**, không suy đoán.

---

## 0. Tám sự thật kiểm được, trước khi bàn ý kiến

Tôi kiểm trong repo trước khi phân tích, vì hai journey này đều giả định sản
phẩm biểu diễn được thứ chúng cần.

| # | Sự thật | Kiểm ở đâu |
|---|---|---|
| **F1** | **`Order` và `OrderItem` KHÔNG có trường tiền tệ.** Chỉ có `unitPrice` là `double` | `lib/features/tongtai/orders/order.dart` |
| **F2** | **Tiền tệ hard-code là VNĐ.** `TongtaiFormatters` ghi thẳng `₫`, không có tỷ giá ở đâu cả | `lib/features/tongtai/core/tongtai_formatters.dart` |
| **F3** | **Không có mô hình subscription / doanh thu định kỳ nào trong `lib/`.** grep `subscription`, `recurring`, `MRR` → **0 file** | toàn bộ `lib/` |
| **F4** | **Không có khái niệm landed cost / thuế nhập / cước.** grep `landedCost`, `customs`, `freight`, `importDuty` → **0 file** | toàn bộ `lib/` |
| **F5** | **Tổng Tài Phase 2 là MIỄN PHÍ.** D-6: RevenueCat thuộc Phase 3 | `ADR-INDEX.md` |
| **F6** | **App CHƯA phát hành.** Việc đưa lên store chính là Epic WTM-175 đang chạy | Jira · `CURRENT-STATUS.md` |
| **F7** | **AI Weekly Review đã là Epic WTM-179**, đang trong 7 ưu tiên Founder chốt sáng nay | Jira |
| **F8** | Chân dung người dùng: **chủ SME Việt Nam bán hàng online + offline** — người bán **hàng vật lý** | `PRODUCT-SCOPE.md` |

**F3 + F5 + F6 gộp lại cho một kết luận không tránh được:**

> **Journey 1 hôm nay không có dữ liệu để dogfood.**
> App chưa lên store ⇒ App Store/Google Play = 0 dòng. Sản phẩm miễn phí ⇒
> subscription = 0 đồng. Không có mô hình recurring ⇒ kể cả có tiền cũng chưa
> lưu được.

Và Journey 2 cũng không có dữ liệu, vì **Workizen chưa vận hành business
xuyên biên giới nào.** Muốn dogfood nó thì phải **mở một công ty thứ hai** —
nhập hàng thật, thuê kho thật, chôn vốn thật.

⇒ **Cả hai journey đều có 0 dòng dữ liệu thật tại thời điểm này.** Đây là phát
hiện quan trọng nhất của vòng nghiên cứu, và nó đúng cho cả hai lựa chọn.

---

## 1. Điểm mạnh

Ý tưởng có giá trị thật, tôi không định dìm nó:

| # | Điểm mạnh | Mức độ thật |
|---|---|---|
| S1 | **Founder trở thành người dùng hằng ngày.** Không ai nói dối được về UX khi mình phải mở app mỗi sáng | ⭐⭐⭐ rất thật |
| S2 | **Vòng phản hồi tính bằng giờ**, không phải tuần. Không cần lịch phỏng vấn, không cần dụ ai cài app | ⭐⭐⭐ rất thật |
| S3 | **Chi phí thu hút khách = 0** | ⭐⭐ thật nhưng dễ đánh lừa (xem W1) |
| S4 | **Ép File Bridge phải thật.** Nếu chính Workizen phải nhập file mỗi tuần, không ai làm cho có | ⭐⭐⭐ rất thật |
| S5 | **Dữ liệu thật thay dữ liệu mẫu.** Sản phẩm hôm nay chỉ được kiểm bằng seed `sample-` | ⭐⭐ thật, nhưng n=1 |
| S6 | *(riêng Journey 2)* **Đúng hình dạng người dùng mục tiêu**: mua → nhập → kho → bán → lãi | ⭐⭐⭐ rất thật |
| S7 | *(riêng Journey 1)* **Workizen đã có business này rồi**, không phải mở mới | ⭐⭐ đúng về nguyên tắc, sai về dữ liệu (F5, F6) |

**Điểm mạnh lớn nhất là S1 + S4.** Founder dùng sản phẩm thật mỗi ngày là thứ
tiền không mua được. Tôi giữ nguyên điều này trong mọi phương án đề xuất.

## 2. Điểm yếu

| # | Điểm yếu | Vì sao |
|---|---|---|
| **W1** | **n = 1, và cái n đó là chính người xây.** Dogfooding cho phản hồi **nhanh**, không cho phản hồi **đại diện**. Nó chữa được lỗi dùng được/không dùng được; **không** trả lời được *ai chịu trả tiền và vì sao* | |
| **W2** | **Journey 1: Workizen KHÔNG phải người dùng mục tiêu.** F8 nói người bán hàng **vật lý**. Một công ty phần mềm bán sản phẩm số **không có tồn kho, không có nhà cung cấp, không có vận đơn, không có COD** | ⇒ **3/8 capability chết** |
| **W3** | **Journey 1 làm sản phẩm lệch về nhu cầu của công ty phần mềm**: MRR, churn, payout đa tiền tệ, thuế nền tảng 30%. Đó **không phải** thứ chị bán quần áo ở Bình Thạnh cần | |
| **W4** | **Journey 2: Workizen KHÔNG vận hành business đó.** Dogfood nó = **mở một công ty nhập khẩu thật** — vốn, hải quan, kho, và sự chú ý của Founder | |
| **W5** | **Cả hai journey đều cần thứ domain model không có**: đa tiền tệ (F1, F2). Journey 1 cần USD, Journey 2 cần CNY. Đây **không** phải một trường thêm vào — nó chạm mọi công thức lãi lỗ, mọi báo cáo, mọi Rule Twin | |
| **W6** | **Journey 1 trùng một phần backlog đã cam kết.** "AI Weekly Review" đã là WTM-179 (F7). Đưa nó vào một journey mới sẽ tạo hai đường tới cùng một việc | |
| **W7** | **Danh sách của cả hai journey gần như toàn tên tích hợp** — Gumroad, Lemon Squeezy, 1688, eBay, Shopify… Đây là **danh sách connector**, không phải business journey. Mà ADR-TON-020 sáng nay đã trả lời câu hỏi connector rồi: **file trước, API sau** | |

**W7 đáng dừng lại.** Bóc lớp vỏ ra, câu hỏi thật của directive này không phải
*"vertical nào"* mà là *"đọc định dạng file nào trước"*. Và câu đó nhỏ hơn nhiều
so với một vòng chọn vertical.

## 3. Rủi ro

→ Chi tiết ở [`02-RISK-ANALYSIS.md`](02-RISK-ANALYSIS.md). Ba cái nặng nhất:

- **R1 — Trì hoãn phát hành.** Cả hai journey đều là việc **trước** khi có người
  dùng thật, trong khi ADR-TON-020 (2 giờ trước) đặt mục tiêu lớn nhất là
  *"đưa sản phẩm đến người dùng thật càng sớm càng tốt"*.
- **R2 — Dogfooding thay thế customer discovery.** Nguy hiểm nhất vì nó **cảm
  giác giống** việc xác thực sản phẩm.
- **R3 — Đa tiền tệ là refactor xuyên miền**, không phải một story.

## 4. Những giả định đang được đưa ra

Tôi tách ra để anh nhìn thấy chúng — vì phần lớn không được nói thành lời:

| # | Giả định ngầm |
|---|---|
| A1 | Workizen là **người dùng đại diện** của Tổng Tài |
| A2 | Dogfooding cho **cùng loại tín hiệu** với customer discovery |
| A3 | Sản phẩm **cần một vertical** (Tổng Tài vốn được thiết kế **ngang**: 8 capability cho mọi người bán SME) |
| A4 | Có dữ liệu doanh thu của chính mình trong app thì **xác thực được sản phẩm** |
| A5 | Workizen **vận hành được** một business xuyên biên giới |
| A6 | Làm việc này **trước** khi phát hành sẽ **đẩy nhanh** việc phát hành |
| A7 | Journey chọn xong sẽ **định hướng kiến trúc** |
| A8 | Hai journey này là **hai lựa chọn thay thế nhau** |

## 5. Giả định nào CHƯA có bằng chứng

| # | Trạng thái | Nói thẳng |
|---|---|---|
| **A1** | ❌ **Có bằng chứng ngược** | F8 + W2: Workizen bán phần mềm, người dùng mục tiêu bán hàng vật lý. Với Journey 1, **A1 sai** |
| **A2** | ❌ **Sai theo định nghĩa** | n=1 và n đó là người xây. Dogfooding trả lời *"dùng được không"*, không trả lời *"ai trả tiền"* |
| **A3** | ⚠️ **Chưa xét bao giờ** | Không ADR nào, không tài liệu nào nói Tổng Tài cần vertical. Đây là một **thay đổi định vị sản phẩm**, đang đi vào dưới dạng "nghiên cứu journey" |
| **A4** | ⚠️ **Xác thực nhầm thứ** | Nó xác thực **Finance**, capability **đã ở L4**. Ba capability yếu (Producer · Opportunity · Consumer đa kênh) không được xác thực gì thêm |
| **A5** | ❌ **Không có bằng chứng nào** | Chưa có vốn nhập hàng, kho, giấy tờ hải quan nào được nhắc tới ở bất cứ đâu |
| **A6** | ❌ **Nhiều khả năng ngược lại** | Cả hai journey đều **thêm** việc trước ngày phát hành |
| **A7** | ❌ **Sai** | ADR-TON-020 đã chốt kiến trúc: File Bridge. Journey chỉ đổi **định dạng file đọc trước**, không đổi kiến trúc |
| **A8** | ⚠️ **Sai — đây là câu hỏi giả** | Xem §7 |

**Bằng chứng còn thiếu, nói cụ thể:** không có một người bán SME Việt Nam nào
đang dùng sản phẩm. Không phải một. Mọi ưu tiên — kể cả bản phân tích này —
đều đang được quyết bằng suy luận, không bằng quan sát.

## 6. Có use case nào quan trọng hơn không

**Có. Ba cái, và cả ba đều quan trọng hơn cả hai journey.**

| | Use case | Vì sao quan trọng hơn |
|---|---|---|
| **U1** | **Người bán đã có 6–12 tháng dữ liệu Shopee/TikTok và xuất được file** | Đây là người dùng mục tiêu **thật**, có dữ liệu **thật**, **hôm nay**. Họ kiểm chứng File Bridge, Finance, Inventory, Consumer cùng lúc. Journey 1 không kiểm được cái nào trong bốn |
| **U2** | **"Tháng này tôi lãi bao nhiêu, thật, sau hết phí sàn?"** | Product Reset kết luận đây là câu hỏi số 1 của người bán và là khoảng trống giá trị lớn nhất. Nó **không phụ thuộc** journey nào |
| **U3** | **Người bán mới cài app, chưa có dữ liệu gì** | Trạng thái đầu tiên **mọi** người dùng đi qua. Nếu 5 phút đầu vô nghĩa, không có journey nào cứu được |

U1 và U3 là **trạng thái vào và ra của cùng một người dùng thật**. Hai journey
trong directive không chạm tới cái nào.

## 7. Có business journey nào nên ưu tiên hơn không

**Có — và tôi cho rằng câu hỏi đang đặt sai.**

Hai journey được trình bày như hai lựa chọn thay thế nhau (A8). Nhưng chúng
không cùng loại:

```
Journey 1  = business Workizen CÓ, nhưng người dùng KHÔNG có
Journey 2  = business người dùng CÓ, nhưng Workizen KHÔNG có
```

Không cái nào cho anh **cả hai vế**. Đó là lý do cả hai đều không phải phép thử
tốt.

Journey đáng ưu tiên hơn cả hai — và nó **đã tồn tại**:

> **Người bán hàng vật lý ở Việt Nam, bán qua Shopee/TikTok + bán trực tiếp,
> nhập hàng từ nhà cung cấp trong nước hoặc Trung Quốc, giao qua GHN/GHTK.**

Đây chính là journey mà 8 capability được thiết kế cho. Nó **không cần** vòng
nghiên cứu nào — nó cần **một người bán thật** cài app.

Nếu buộc phải xếp hạng ba: **journey người bán thật (đã có) > Cross-border >
Digital Product.**

## 8. Có đang làm sản phẩm quá rộng không

**Có. Rõ ràng có.**

Bằng chứng, không phải cảm tính:

- Sản phẩm có **8 capability**, **3 trong đó chưa trọn vẹn** (Producer,
  Opportunity, Consumer đa kênh) — Product Reset sáng nay đã kết luận.
- Thêm một vertical **không** đóng bất kỳ khoảng trống nào trong ba cái đó. Nó
  mở khoảng trống **mới**: đa tiền tệ (W5), recurring revenue (F3), landed cost
  (F4).
- Journey 1 làm **3/8 capability trở thành vô nghĩa** (Inventory, Producer,
  và phần vận đơn của Consumer) — tức là làm sản phẩm **rộng ra và rỗng đi**
  cùng lúc.

Sáng nay backlog vừa được dọn từ **62 issue xuống 10**, và 51 issue bị đóng phần
lớn vì được viết cho một kiến trúc chưa chốt. Mở một vertical mới trước khi có
người dùng đầu tiên là **cùng một lỗi, mặc áo khác**.

## 9. Có làm mất focus MVP không

**Có — và mâu thuẫn trực tiếp với quyết định anh vừa ký cách đây hai giờ.**

ADR-TON-020, Founder chốt 2026-08-01:

> *"Mục tiêu lớn nhất từ bây giờ: đưa sản phẩm đến người dùng thật càng sớm càng
> tốt. Mọi quyết định tiếp theo phải ưu tiên tăng giá trị sản phẩm hơn là mở
> rộng tài liệu hoặc quy trình."*

Và:

> *"Không xây backend hoặc OAuth trước nhu cầu thực tế."*

Cả hai journey đều là **việc làm trước khi có nhu cầu thực tế**. Sản phẩm hôm
nay cách cửa hàng **hai hạng mục nội dung** (địa chỉ liên hệ, điều khoản dịch
vụ) và **một chữ ký iOS**. Không hạng mục nào là code, và không hạng mục nào
được giải quyết bởi việc chọn vertical.

Tôi có trách nhiệm nói thẳng: **directive này, nếu chuyển thành backlog ngay,
sẽ hoãn ngày phát hành.**

## 10. Nếu chỉ được chọn MỘT journey

**Digital Product — nhưng KHÔNG phải như một vertical của sản phẩm.**

Chọn nó vì:

1. **Workizen đã vận hành business đó rồi.** Không phải mở công ty thứ hai (W4).
2. **File xuất từ Gumroad / App Store / Google Play có cấu trúc ổn định**, tài
   liệu công khai, và **không cần ai duyệt** — đúng mô hình File Bridge.
3. **Rủi ro thấp nhất.** Đọc sai file của chính mình thì không ai mất tiền.

Nhưng chọn nó với **một ranh giới cứng**:

> Dữ liệu digital product của Workizen là **bộ dữ liệu kiểm thử đầu tiên cho
> File Bridge**, **KHÔNG** phải một vertical của sản phẩm.
>
> ⇒ **Không** thêm mô hình subscription. **Không** thêm MRR/churn. **Không** thêm
> đa tiền tệ. **Không** thêm màn hình nào.

Vì sao ranh giới này quan trọng: khoảnh khắc "theo dõi doanh thu Gumroad" trở
thành **tính năng**, Tổng Tài bắt đầu trở thành phần mềm cho công ty phần mềm —
và người bán quần áo ở Bình Thạnh, người mà toàn bộ 8 capability được thiết kế
cho, không được lợi một dòng nào.

**Nếu ranh giới đó không giữ được, tôi khuyên không chọn journey nào cả** và
dồn toàn bộ vào WTM-175 để lên store.

---

## Founder Challenge — phản biện trực tiếp

Anh yêu cầu nói thẳng. Bốn điểm:

**1. "Workizen sẽ trở thành khách hàng đầu tiên của Tổng Tài" — với Journey 1,
câu này không đúng về mặt sự kiện.**
Tổng Tài phục vụ người bán hàng vật lý (F8). Workizen bán phần mềm. Workizen có
thể là **người dùng** đầu tiên; nó không thể là **khách hàng** đầu tiên, vì nó
không có bài toán mà sản phẩm giải.

**2. Journey 1 hôm nay không có dữ liệu.**
App chưa lên store (F6). Sản phẩm miễn phí ở Phase 2 (F5). Không có mô hình
recurring trong code (F3). *"Subscription · Revenue"* trong danh sách của anh
là **dữ liệu chưa tồn tại**. Không thể dogfood doanh thu của một sản phẩm miễn
phí chưa phát hành.

**3. Journey 2 không phải chọn một journey — nó là mở một công ty.**
1688 + Alibaba + Taobao + Import + Warehouse + Logistics nghĩa là vốn nhập hàng,
thủ tục hải quan, kho thật, hàng chôn vốn thật. Đó là quyết định kinh doanh của
anh chứ không phải một hạng mục nghiên cứu sản phẩm — và nếu làm, sự chú ý của
anh chia đôi đúng lúc sản phẩm cần được đưa ra thị trường.

**4. Cả hai danh sách đều là danh sách connector, không phải business journey.**
Gumroad · Lemon Squeezy · Shopify · 1688 · eBay — đó là **nguồn dữ liệu**. Câu
hỏi *"đọc nguồn nào trước"* đã được ADR-TON-020 trả lời sáng nay: **file trước,
API sau**. Vòng nghiên cứu này, ở dạng hiện tại, đang hỏi lại một câu vừa được
quyết — chỉ khác là lần này kèm theo một vertical.

**Điều tôi KHÔNG phản đối:** anh trở thành người dùng hằng ngày của sản phẩm.
Đó là ý tưởng tốt nhất trong toàn bộ directive này, và nó **không cần** chọn
vertical nào — chỉ cần anh cài app và nhập dữ liệu kinh doanh thật của Workizen
vào Finance. Việc đó làm được **hôm nay**, không tốn một dòng code nào.

---

**Đọc tiếp:** [Alternatives](01-ALTERNATIVES.md) ·
[Risk Analysis](02-RISK-ANALYSIS.md) · [Recommendation](03-RECOMMENDATION.md)
