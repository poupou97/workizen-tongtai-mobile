# Alternative Solutions

*Workizen là khách hàng đầu tiên của Tổng Tài · 2026-08-01*

> Directive yêu cầu **tối thiểu 3 phương án** và **không mặc định phương án nào
> đúng**. Dưới đây là 5. Tôi cho điểm từng cái trên 6 trục và nói rõ cái nào tôi
> chọn ở [`03-RECOMMENDATION.md`](03-RECOMMENDATION.md) — nhưng bốn cái còn lại
> được trình bày đầy đủ để anh phản đối tôi nếu muốn.

---

## Phương án A — Digital Product trước

**Nội dung:** Workizen dùng Tổng Tài để theo dõi business phần mềm của chính
mình — Gumroad, Lemon Squeezy, App Store, Google Play, Shopify, subscription.

| Trục | Điểm |
|---|---|
| Dữ liệu thật **hôm nay** | ❌ **không có** — app chưa lên store, sản phẩm miễn phí (F5, F6) |
| Khớp người dùng mục tiêu | ❌ **không** — Workizen bán phần mềm, người dùng bán hàng vật lý |
| Chi phí khởi động | ✅ thấp — không phải mở công ty mới |
| Ảnh hưởng domain model | 🔴 **nặng** — cần subscription (F3) + đa tiền tệ (F1, F2) |
| Kiểm chứng được capability nào | ⚠️ chỉ Finance (**đã L4**). Inventory/Producer **chết** |
| Ảnh hưởng ngày phát hành | 🔴 hoãn |

**Nói thẳng:** phương án này dogfood một business mà **người dùng mục tiêu không
có**, bằng **dữ liệu chưa tồn tại**, và làm **3/8 capability vô nghĩa**.

## Phương án B — Cross-border trước

**Nội dung:** Workizen mở/vận hành một hoạt động nhập hàng — 1688, Alibaba,
Taobao, kho, eBay, Shopify, logistics — và dùng Tổng Tài để chạy nó.

| Trục | Điểm |
|---|---|
| Dữ liệu thật **hôm nay** | ❌ **không có** — Workizen chưa vận hành business này |
| Khớp người dùng mục tiêu | ✅ **có** — đúng hình dạng mua → nhập → kho → bán |
| Chi phí khởi động | 🔴 **rất cao** — vốn nhập hàng, hải quan, kho, và **sự chú ý của Founder** |
| Ảnh hưởng domain model | 🔴 **nặng** — đa tiền tệ CNY→VND (F1, F2) + landed cost (F4) |
| Kiểm chứng được capability nào | ✅ **nhiều nhất** — Producer, Inventory, Finance, Consumer, Opportunity |
| Ảnh hưởng ngày phát hành | 🔴 hoãn nhiều |

**Nói thẳng:** đây là phương án **đúng về sản phẩm nhất** và **đắt nhất về đời
thật**. Nó không phải chọn một journey — nó là **mở một công ty thứ hai**. Đó là
quyết định kinh doanh của Founder, không phải hạng mục nghiên cứu sản phẩm.

> Nếu Founder **vốn dĩ đã muốn** làm business nhập khẩu vì lý do riêng, phương án
> này chuyển từ "đắt" thành "miễn phí" ngay lập tức, và trở thành lựa chọn tốt
> nhất trong năm. **Chỉ Founder trả lời được điều đó.** Tôi không giả định.

## Phương án C — Business Foundation trước, rồi mới tách vertical

**Nội dung:** hoàn thiện nền chung (đa tiền tệ, provenance, File Bridge, mô hình
doanh thu tổng quát) rồi sau đó mới tách vertical.

| Trục | Điểm |
|---|---|
| Dữ liệu thật hôm nay | ❌ không, và **không cần** |
| Khớp người dùng mục tiêu | ⚠️ trung lập |
| Chi phí khởi động | 🔴 cao — đa tiền tệ là refactor xuyên miền |
| Ảnh hưởng domain model | 🔴 nặng nhưng **có chủ đích** |
| Kiểm chứng được capability nào | ❌ **không cái nào** — đây là hạ tầng |
| Ảnh hưởng ngày phát hành | 🔴 hoãn nhiều nhất |

**Nói thẳng:** phương án này nghe "đúng kiến trúc" nhất và **nguy hiểm nhất**.
Nó xây nền cho hai vertical **chưa cái nào được chứng minh là cần**. Đây đúng
loại việc Product Reset sáng nay vừa dọn: 51 issue viết cho một kiến trúc chưa
chốt.

## Phương án D — Không vertical nào. Workizen dùng app thật, dữ liệu digital làm bộ test cho File Bridge

**Nội dung:**

1. Founder cài bản release và **nhập dữ liệu tài chính thật của Workizen** vào
   Finance — làm được **hôm nay**, không cần một dòng code.
2. Khi File Bridge được xây (WTM-181), **file xuất từ Gumroad / App Store /
   Google Play là bộ dữ liệu kiểm thử đầu tiên** — vì chúng có cấu trúc ổn định,
   tài liệu công khai, và không cần ai duyệt.
3. **Không** thêm subscription, **không** thêm MRR/churn, **không** thêm đa tiền
   tệ, **không** thêm màn hình. Không có vertical nào được tạo ra.
4. Song song: **20–50 người bán thật** vào closed beta — đó mới là nguồn bằng
   chứng.

| Trục | Điểm |
|---|---|
| Dữ liệu thật hôm nay | ✅ **có** — dữ liệu tài chính Workizen tồn tại ngay |
| Khớp người dùng mục tiêu | ✅ giữ nguyên — không đổi định vị |
| Chi phí khởi động | ✅ **gần bằng 0** |
| Ảnh hưởng domain model | ✅ **không** |
| Kiểm chứng được capability nào | ⚠️ Finance + File Bridge, không hơn — nhưng **không hứa hơn** |
| Ảnh hưởng ngày phát hành | ✅ **không hoãn** |

**Nói thẳng:** phương án này giữ lại **điểm mạnh lớn nhất** của ý tưởng Founder
(S1 — Founder dùng app hằng ngày; S4 — File Bridge bị ép phải thật) và **bỏ đi
toàn bộ chi phí** (vertical, đa tiền tệ, subscription, mở công ty).

Điểm yếu thật của nó: nó **không hào hứng**. Nó không cho anh một câu chuyện
"Workizen là khách hàng đầu tiên". Nó chỉ cho anh một app anh dùng mỗi ngày và
20 người bán thật.

## Phương án E — Hoãn quyết định, chạy một phép thử 1 tuần

**Nội dung:** không chọn vertical. Thay vào đó, trong 1 tuần:

1. Xuất file thật từ Gumroad / App Store / Google Play (nếu Workizen có), **và**
   xin 1–2 người bán thật một file xuất Shopee/TikTok.
2. Thử **ánh xạ tay** các file đó vào domain model hiện tại.
3. Trả lời một câu hỏi duy nhất: **domain model hôm nay biểu diễn được bao nhiêu
   phần trăm mỗi loại file, và thiếu chính xác cái gì?**

| Trục | Điểm |
|---|---|
| Dữ liệu thật hôm nay | ✅ có — file thật, không phải giả định |
| Chi phí | ✅ **1 tuần, không code** |
| Ảnh hưởng domain model | ✅ không — chỉ đo |
| Cho ra cái gì | ✅ **bằng chứng để chọn A/B/C/D**, thay vì tranh luận |
| Ảnh hưởng ngày phát hành | ⚠️ nhẹ — chạy song song với WTM-175 được |

**Nói thẳng:** đây là phương án duy nhất **biến câu hỏi này thành có thể trả lời
được**. Mọi phương án khác đều đang đoán xem file của Gumroad hay của 1688 khớp
domain model đến đâu — mà **chưa ai mở một file nào ra xem.**

---

## Bảng so sánh

| | A · Digital | B · Cross-border | C · Foundation | D · Không vertical | E · Phép thử 1 tuần |
|---|---|---|---|---|---|
| Dữ liệu thật hôm nay | ❌ | ❌ | ❌ | ✅ | ✅ |
| Khớp người dùng mục tiêu | ❌ | ✅ | ⚠️ | ✅ | ✅ |
| Chi phí | 🟡 | 🔴 | 🔴 | 🟢 | 🟢 |
| Chạm domain model | 🔴 | 🔴 | 🔴 | 🟢 | 🟢 |
| Hoãn phát hành | 🔴 | 🔴 | 🔴 | 🟢 | 🟡 |
| Cho bằng chứng mới | 🟡 | ✅ | ❌ | 🟡 | ✅ |
| Giữ được S1 (Founder dùng hằng ngày) | ✅ | ✅ | ❌ | ✅ | ⚠️ |

**Không có phương án nào thắng mọi trục.** A và B mua bằng chứng bằng thời gian
phát hành. D giữ tốc độ nhưng cho ít bằng chứng mới. E cho bằng chứng rẻ nhất
nhưng không tự nó là một hướng đi.

⇒ Đề xuất của tôi là **E rồi D**, lý do đầy đủ ở
[`03-RECOMMENDATION.md`](03-RECOMMENDATION.md).
