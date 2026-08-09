# Lời thật sau phí · So sánh nhà cung cấp

> **WTM-328 / WTM-329 · Epic WTM-324**

## 1. Câu hỏi

> *"Tháng này tôi lời bao nhiêu **thật**?"*

Người bán tính nhẩm `giá bán − giá vốn`. Con số đó **luôn dương** với mọi sản
phẩm họ bán:

```
doanh thu 259.000  −  giá vốn 240.000  =  lãi gộp 19.000   ← ai cũng thấy
                   −  hoa hồng sàn 14.245
                   −  phí thanh toán 7.252
                   =  LỖ 2.497                              ← không ai thấy
```

Sản phẩm đó vẫn nằm trong danh sách bán chạy. **Càng bán càng lỗ, bảng doanh
thu vẫn xanh.**

## 2. ⛔ Không có Finance truth thứ hai

`CommerceProfitContext` **không tự tính** lợi nhuận. Nó gom đúng ba mảnh mà
`TrueProfitRule` (WTM-231, ADR-TON-016) đòi — doanh thu · giá vốn từng món ·
các dòng đối soát — rồi giao cho quy tắc đó quyết.

Công thức nằm ở **đúng một chỗ**, và đó là chỗ đã có từ trước.

## 3. Bốn quyết định đáng ghi

| Quyết định | Vì sao |
|---|---|
| Đơn **đã huỷ/hoàn** không tính doanh thu | tính vào rồi trừ ở phần hoàn tiền ra đúng *tổng* nhưng sai *từng sản phẩm* — và người bán đọc theo sản phẩm |
| Khoá giá vốn gồm **mã đơn** | hai đơn cùng sản phẩm là **hai** khoản vốn; gộp lại sẽ tính thiếu vốn cho đúng món bán nhiều nhất |
| Phí đơn nhiều món phân bổ theo **tỷ trọng doanh thu** | sàn không cung cấp phí theo dòng; đây là cách phân bổ duy nhất không cần thông tin không tồn tại |
| Chưa nhập giá vốn ⇒ **từ chối trả số** | coi vốn bằng 0 sẽ biến mọi sản phẩm chưa nhập vốn thành sản phẩm siêu lời |

## 4. So sánh nhà cung cấp — rẻ hơn ≠ tốt hơn

Rẻ hơn 12% mà **giao chậm hơn 6 ngày** là một **đánh đổi**, không phải một câu
trả lời. `clearWin` chỉ trả về khi *rẻ hơn* **và** *không chậm hơn*.

### ⭐ Chưa biết thì nói chưa biết

`leadTimeDays == null` ⇒ `slowerByDays == null`, và lựa chọn đó **không** được
gọi là "rõ ràng tốt hơn".

Coi `null` là 0 sẽ biến một nguồn chưa ai hỏi giao bao lâu thành một nguồn
"giao nhanh ngang" — và câu gợi ý *"rẻ hơn 12% và giao nhanh hơn"* lúc đó là
bịa ra một nửa lời khuyên.

### Mốc so sánh là **giá vốn đang ghi trên sản phẩm**

`Product` không mang `supplierId` trong miền. Không truyền `currentUnitCost`
thì mốc rơi về "báo giá rẻ nhất", và khi đó **không lựa chọn nào rẻ hơn được**
— engine im lặng vĩnh viễn dù dữ liệu có nguồn tốt hơn hẳn.

Bug này đã xảy ra thật và test trên dataset bắt được: `rule:supplier-comparison`
không sinh ra việc nào trong khi 12 sản phẩm có ≥2 báo giá.

## 5. Cơ hội **suy ra**, không hardcode (§16)

| Loại | Điều kiện | Đề xuất |
|---|---|---|
| `rule:true-profit` | lời thật âm | **giá hoà vốn có số**: `vốn / (1 − 8,3%)`, làm tròn **lên** |
| `rule:stock-level` | tồn ≤ mức đặt lại | tạo phiếu nhập |
| `rule:dead-stock` | còn tồn **và không bán được món nào** trong kỳ | giảm 20% xả hàng |
| `rule:supplier-comparison` | có nguồn rẻ hơn và không chậm hơn | đổi nguồn |

Ba điều đáng chú ý:

- **Đề xuất phải có số.** "Anh xem lại giá đi" là một đề xuất người bán phải tự
  làm lại từ đầu. Giá hoà vốn làm tròn **lên** nghìn — làm tròn xuống cho ra một
  con số vẫn lỗ, và một đề xuất vẫn lỗ thì tệ hơn không đề xuất.
- **Hàng nằm = không bán được món nào**, không phải "bán ít". Bán ít vẫn là bán;
  gọi nó là hàng chết sẽ khiến người bán thanh lý nhầm thứ đang chạy chậm mà đều.
- **`quantity == null` không bao giờ "sắp hết hàng"** (ADR-TON-023) — một dịch vụ
  không có tồn kho để hết.

## 6. Vào chung MỘT brief

Việc thương mại đi vào `businessBriefProvider` cùng việc khách hàng và cảnh báo,
sắp theo mức khẩn.

Người bán không có "mục cơ hội thương mại" trong đầu; họ có *"sáng nay tôi cần
làm gì"*. **Hai danh sách song song là hai chỗ để bỏ sót.**

Trần: **ba việc mỗi loại**. Một danh mục 100 sản phẩm sinh ra hàng chục việc, và
một danh sách ba mươi dòng tương đương một danh sách trống.
