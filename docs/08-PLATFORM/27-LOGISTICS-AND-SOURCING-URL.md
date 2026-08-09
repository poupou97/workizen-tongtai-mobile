# 27 · Vận chuyển + URL import cho nguồn hàng

> **WTM-323 · C7 · Epic WTM-315**

## 1. ⭐ Cảnh báo đáng giá nhất không phải "đơn bị chậm"

*"Trễ hơn dự kiến"* xảy ra với cả nghìn đơn mỗi mùa cao điểm. Cảnh báo theo nó
là cảnh báo bị tắt trong tuần đầu.

Thứ người bán cần:

> **Đơn TT-042 đứng im 5 ngày trong khi 2 đơn cùng tuyến đã tới**

Vế sau mới là thông tin. Nó **loại được nguyên nhân chung** (bão, quá tải, nghỉ
lễ) và chỉ còn lại nguyên nhân riêng của **kiện đó** — đúng lúc gọi hãng còn kịp.

### Điều kiện so sánh, và vì sao mỗi điều kiện tồn tại

| Điều kiện | Nếu bỏ |
|---|---|
| **cùng tuyến** | so một kiện đi Hà Nội với một kiện đi Cần Thơ — so sánh vô nghĩa dẫn tới cảnh báo vô nghĩa |
| **cùng hãng** | GHN nhanh hơn J&T không nói được gì về kiện J&T này |
| **gửi cùng đợt** (±3 ngày) | so với kiện gửi tháng trước là so hai điều kiện đường sá khác nhau |
| **≥2 kiện đã tới** | một kiện đối chiếu là một **trùng hợp**; hai kiện trở lên mới là một **mẫu** |

Thiếu điều kiện nào ⇒ hạ xuống *"lâu không có tin"*, **không** kết luận thay.

## 2. `null` ở đâu cũng có nghĩa

| | `null` nghĩa là | ⛔ không được thành |
|---|---|---|
| `lastUpdate` | **chưa có tin nào** từ hãng | "cập nhật lúc 0" ⇒ đứng im vô hạn |
| `eta` | hãng chưa hẹn ngày | "hẹn hôm nay" ⇒ trễ ngay lập tức |
| `carrier` | **không đoán được** hãng | chọn bừa ⇒ mọi lần tra sau đó trỏ nhầm cửa, và người bán kết luận *app không tra được* chứ không kết luận *app đoán sai* |
| `route` | thiếu một đầu | so hai kiện không biết cùng tuyến hay không |

Nhận hãng từ mã vận đơn dùng luật **hẹp có chủ ý**: một luật rộng bắt được
nhiều mã hơn cũng bắt nhầm nhiều hơn.

## 3. Trạng thái: `delayed` KHÔNG phải một trạng thái

File demo có `delayed`, và nó ánh xạ về `in_transit`.

Kiện vẫn đang trên đường. Việc nó chậm là **kết luận của Rule Twin**, không phải
một ô trong file — nếu lưu nó thành trạng thái thì hôm sau kiện tới nơi mà ô vẫn
ghi "chậm".

Mã lạ ⇒ **bỏ dòng**, không rơi về `in_transit`. Rơi về "đang giao" khiến một
kiện đã hoàn về kho trông như đang trên đường tới khách — và **không ai đi tìm
nó**.

## 4. Bảng riêng, không phải cột trên `orders`

Một đơn tách được thành nhiều kiện (sàn tách theo kho) và một kiện gộp được
nhiều đơn. Nhét mã vận đơn thành một cột sẽ hỏng ở cả hai chiều — và **hỏng im
lặng**, vì cột vẫn nhận được một giá trị.

Không khoá ngoại tới `orders`: một kiện có thể tới trước khi đơn được nhập, và
*"đã giao cho khách này"* vẫn là sự thật sau khi đơn bị xoá.

## 5. ⭐ URL import — connector KHÔNG chỉ là API (§D-6)

```
Người bán đang ở app Alibaba/1688
   ↓ Share / Copy URL
Tổng Tài nhận
   ↓ nhận ra: nền tảng + mã sản phẩm
Người bán điền: giá · MOQ · lead time
   ↓
SupplierQuote → So sánh nhà cung cấp → Opportunity → Journey
   ↓
"Xem tại Alibaba" → deep link về app gốc
```

Đây là đường **rẻ nhất** trong các đường vào: không OAuth, không đăng ký, không
ai duyệt.

### ⛔ Không scraping — và điều đó quyết định app biết được gì

Từ một URL, app **chỉ** suy ra được **nền tảng** và **mã sản phẩm**. Giá, MOQ,
thời gian giao đều nằm sau một trang web mà lấy về là vi phạm điều khoản.

Nên `SourcingUrl.toDraft()` trả về một **khung còn trống**, không phải một báo
giá. Người bán nhìn số trên màn hình Alibaba và gõ vào — mất mười giây, và con
số đó **đúng**.

**Cách sai là để trống rồi hiện `0`:** một báo giá 0 đồng sẽ **thắng mọi so sánh
nhà cung cấp**, và app sẽ khuyên người bán đổi sang một nguồn không có giá.

`SourcingDraft.unknownFields` nói thẳng ba thứ app chưa biết. Nói ra trung thực
hơn nhiều so với hiện ba ô trống không giải thích.

### Bỏ tham số theo dõi

Link chia sẻ từ app di động mang hàng chục tham số quảng cáo. Giữ nguyên thì hai
lần dán cùng một sản phẩm ra hai chuỗi khác nhau và **chống trùng không chạy**.

Link lạ ⇒ `null`, để giao diện nói *"chưa nhận ra trang này"* thay vì tạo một
báo giá trỏ đi đâu không rõ.

## 6. Còn thiếu: API hãng vận chuyển

GHN/GHTK là **DIRECT MOBILE** (API key lấy trong tài khoản shop, một GET, không
ai duyệt) — nhưng cần Founder lấy key. Cho tới lúc đó, Rule Twin chạy trên
**dữ liệu đã có trong sổ**, và điều đó đã đủ để cảnh báo *"đứng im trong khi
đơn cùng tuyến đã tới"*.

Theo dõi liên tục khi app đóng vẫn là **BACKEND** (n8n định kỳ) — không nằm
trong story này.
