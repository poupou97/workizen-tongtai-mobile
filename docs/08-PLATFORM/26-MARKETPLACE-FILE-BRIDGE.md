# 26 · File Bridge cho sàn — Shopee · TikTok Shop

> **WTM-322 · C6 · Epic WTM-315** — D-3: *File Bridge NOW, partner API SONG SONG*

## 1. ⚠️ Đính chính vẫn còn hiệu lực (§21)

File Bridge **không phải** kết luận rằng Shopee/TikTok không có API. Nghiên cứu
WTM-309 chỉ chứng minh **không tìm thấy implementation trong bộ source đã đọc**.
Vendor **có** API.

⇒ File Bridge là **đường đi trước**, không phải kiến trúc vĩnh viễn.

## 2. Hai đường, MỘT đích

```
File Bridge  ─┐
              ├─→ Canonical Domain ─→ Agentic Foundation
Vendor API   ─┘
```

`MarketplaceExportSource` **không có kiểu dữ liệu riêng** — nó trả về đúng
`CustomerOrder` và `SettlementLine` mà mọi chỗ khác đã dùng. Ngày có API, thứ
thêm là một adapter cạnh nó.

## 3. ⚠️ Tôi KHÔNG có file thật — và điều đó định hình thiết kế

Tên cột trong `MarketplaceProfile` đến từ tài liệu, **chưa đối chiếu file thật
của Founder**.

| Cách làm | Hậu quả |
|---|---|
| đoán một bộ tên cột rồi hardcode | ngày gặp file thật, app báo *"không đọc được"* và không ai biết vì sao |
| **nhận dạng theo điểm số trên nhiều bí danh, không khớp thì kể lại các cột đã thấy** | file thật **tự nói** cho ta biết tên cột đúng |

Câu app nói khi không nhận ra:

> Chưa nhận ra đây là file của sàn nào. Các cột đọc được: Mã vận đơn · Người
> nhận · Ghi chú giao hàng

Đó là lý do `SheetTable.headers` **giữ nguyên hoa/thường như trong file** — một
câu báo lỗi ghi `mã vận đơn` trong khi file ghi `Mã vận đơn` biến chính thứ
đang cần đối chiếu thành thứ không đối chiếu được.

Ngưỡng nhận dạng: **4 cột**. Dưới mức đó rất có thể đang khớp nhầm với một file
bất kỳ có cột tên "Số lượng".

## 4. ⭐ Hai file, không phải một

| File | Cho gì |
|---|---|
| Đơn hàng | doanh thu · khách · sản phẩm |
| **Báo cáo thu nhập** | **hoa hồng · phí thanh toán · vận chuyển · voucher · payout** |

Thiếu file thứ hai ⇒ app tính **doanh thu đúng mà lợi nhuận sai** — con số nguy
hiểm nhất có thể in ra.

### Cơ chế chặn, không phải lời nhắc

`ProfitBlocker.missingMarketplaceFees`: một đơn có **kênh bán là sàn** mà không
có dòng phí nào ⇒ lợi nhuận trả về `insufficient`.

Suy ra từ **kênh bán**, không từ *"không thấy dòng phí"* — một đơn bán tại quầy
không có phí sàn là chuyện bình thường, một đơn Shopee thì không. Nhầm hai
chuyện đó làm lợi nhuận sai theo hướng tâng bốc.

## 5. Ba quyết định nghiệp vụ

### Đơn hàng KHÔNG tạo sản phẩm

File đơn của sàn có tên và SKU nhưng **không có giá vốn**. Tạo sản phẩm từ đó
sinh ra một danh mục toàn món không biết vốn — và lợi nhuận của **toàn bộ** danh
mục lập tức thành *"chưa tính được"*.

SKU không khớp ⇒ ERROR cho đơn đó, kèm câu nói rõ phải làm gì: *"Nhập danh mục
sản phẩm trước rồi nhập lại đơn."* Thứ tự này là một sự thật nghiệp vụ, không
phải một hạn chế kỹ thuật.

### Nhiều dòng cùng mã đơn = MỘT đơn

Sàn xuất một dòng cho mỗi món. Không gom thì số đơn nhân lên, và mọi chỉ số đếm
theo đơn sai theo.

### Voucher SÀN tài trợ không phải chi phí người bán

`fundedBy: platform` chứ không phải `seller`. ADR-TON-024 gọi đúng tên: nhầm chỗ
này làm lợi nhuận sai theo **hướng tâng bốc** — kiểu sai không ai đi kiểm.

## 6. Mỗi khoản một `kind` riêng

⛔ Không cộng gộp thành một con số "phí sàn". Gộp lại thì không ai trả lời được
*"hoa hồng bao nhiêu"* — đúng câu người bán hỏi khi thấy lợi nhuận mỏng.

`commission` · `platformFee` (phí thanh toán + dịch vụ) · `shippingFee` ·
`voucher`.

Phí ghi số âm trong báo cáo vẫn ra `amount` **dương** + `direction: outbound`
(ADR-TON-024: chiều nằm ở `direction`, không ở dấu).

## 7. Chống trùng

Mã canonical `mkt-<vendor>-<mã đơn của sàn>`. Nhập lại cùng file ⇒ đơn đã có
được bỏ qua và **nói ra**, không im lặng.

## 8. Cột chưa dùng tới được NÓI RA (§11)

Báo cáo `Mapped / Unmapped / Ignored / Invalid`. Field không map được **không bị
nuốt im lặng**.

⚠️ Hôm nay chúng chỉ được **báo cáo**, chưa có chỗ lưu — tầng thuộc tính động
(WTM-334) là nhà tương lai của chúng. Cho tới lúc đó, báo cáo là hành xử đúng:
lưu vào một chỗ tạm sẽ tạo nhà thứ ba cho một trường, đúng điều Founder vừa cấm.

## 9. Một nút, không phải ba

`CommerceSourceResolver` tự nhận file danh mục hay file sàn. Bắt người bán tự
khai loại file là đẩy việc phân loại sang người ít có khả năng phân loại nhất.

Thử sàn trước vì phép thử của nó chặt hơn (4 cột trùng tên), và file danh mục
nhận ra chắc chắn bằng **tên sheet `PRODUCTS`**.

## 10. Song song: đường partner

Founder cần làm nếu muốn API thật:

- **Shopee**: đăng ký Shopee Open Platform, chờ duyệt tài khoản partner, ký
  request theo chuẩn của họ
- **TikTok Shop**: đăng ký developer, tạo app, chờ duyệt

⛔ **Không chặn sản phẩm chờ nó.** Catalog đã khai `partner_required` cho cả hai
— rào cản là **thương mại**, không phải kỹ thuật.
