# Commerce Demo Dataset — nguồn hàng thật-giả lập

> **WTM-325 / WTM-326 · Epic WTM-324** — Commerce Dogfood / File Bridge

## 1. File

`assets/demo/TongTai-Commerce-Demo-100-Products.xlsx` — đóng gói **vào app**,
nên Founder nhập được ngay cả khi chưa nối Google Drive.

Sinh bằng `python3 tool/generate_commerce_demo.py` với seed cố định
(`SEED = 20260809`, `TODAY = 2026-08-09`). Chạy lại cho ra **đúng cùng một
file**. Đó là điều kiện để test khẳng định được số lượng từng nhóm — một
dataset ngẫu nhiên thì test chỉ khẳng định được "khoảng chừng", và "khoảng
chừng" không bắt được lỗi.

## 2. Tám bảng

| Bảng | Số dòng | Ghi chú |
|---|---|---|
| PRODUCTS | 100 | 29 cột, có cột `scenario` để test đếm được từng nhóm |
| VARIANTS | 75 | 26 sản phẩm có phiên bản; một phần **cố ý để trống giá** (kế thừa mẹ) |
| SUPPLIERS | 12 | Alibaba · 1688 · AliExpress · local VN · wholesale · manufacturer |
| SUPPLIER_QUOTES | 124 | nhóm G có 3 báo giá/sản phẩm; một số **cố ý thiếu lead time** |
| CUSTOMERS | 40 | VIP · returning · new · dormant · one-time; email `.invalid` |
| ORDERS | 112 | mọi đơn trỏ tới sản phẩm **có thật** (§7) |
| SETTLEMENT | 255 | hoa hồng · phí thanh toán · phí ship · giảm giá · hoàn tiền |
| SHIPMENTS | 8 | delivered · in_transit · delayed · failed |

## 3. Mười nhóm kịch bản (§6)

| Nhóm | Số | Rule Twin phải thấy |
|---|---|---|
| A · bán chạy + sắp hết | 12 | REORDER |
| B · tồn nhiều, bán chậm | 10 | DEAD STOCK |
| C · margin cao | 10 | HIGH MARGIN |
| D · **lỗ sau phí** | 9 | LOW MARGIN ALERT |
| E · sản phẩm mới | 10 | |
| F · sắp tới điểm đặt lại | 10 | REORDER SOON |
| G · ≥2 báo giá | 12 | SUPPLIER COMPARISON |
| H · bán kèm | 10 | CROSS-SELL |
| I · hết hàng | 5 | OUT OF STOCK |
| J · **bình thường** | 12 | *(không có gì)* |

### ⭐ Nhóm J tồn tại vì một lý do dễ quên

Không có nhóm đối chứng thì **mọi sản phẩm đều "có vấn đề"**, và một danh sách
mà mọi dòng đều đỏ là một danh sách không ai đọc. Test khoá nó: sản phẩm nhóm J
phải còn tồn trên điểm đặt lại **và** lãi gộp trên 15%.

### ⭐ Nhóm D là câu hỏi "tháng này tôi lời bao nhiêu THẬT"

Markup `1.05` — lãi gộp ~4,8% giá bán, trong khi phí sàn Shopee/TikTok là
5,0–5,5% hoa hồng cộng 2,5–2,8% phí thanh toán. **Lãi gộp dương, lời thật âm.**

Markup từng là `1.08` và hỏng: làm tròn giá tới nghìn đẩy lãi gộp lên vài trăm
đồng, đủ để một sản phẩm "lỗ sau phí" hoá ra hoà vốn. Kịch bản phải đúng **kể
cả sau làm tròn**.

## 4. Đường đi vào app

```
XLSX → XlsxReader → SheetTable → XlsxCommerceSource → CommerceImportPreview
                                                              ↓ (người bán xem)
                                       CommerceImporter → repository production
                                                              ↓
                        Product · Variant · SupplierQuote · Customer · Order · Settlement
```

**Không** seed thẳng SQLite (§15). Bộ demo đi **cùng một đường** với file người
bán tự chọn — hỏng thì hỏng ở cả hai, không có lối tắt riêng cho demo.

## 5. Ba thứ dataset cố ý làm "chưa hoàn hảo"

Một dataset hoàn hảo chỉ chứng minh được đường hạnh phúc.

| Cố ý | Để chứng minh |
|---|---|
| vài báo giá **thiếu lead time** | so sánh nói *"chưa biết"* chứ không đoán (§17) |
| vài phiên bản **để trống giá** | `null` = kế thừa giá mẹ, không phải 0 đồng |
| 5 sản phẩm **tồn = 0** | `0` (hết hàng) khác `null` (không theo dõi tồn) — ADR-TON-023 |

## 6. Không phải dữ liệu thật của ai

Email `khach###@demo.tongtai.invalid` (`.invalid` là TLD dành riêng theo
RFC 2606 — không bao giờ phân giải được). Số điện thoại theo khuôn `09xx000xxx`.
Tên ghép từ ba danh sách. Cột `source` ghi `DEMO/FILE_BRIDGE`.

⛔ **Không** trình bày như dữ liệu vendor synced thật (§14). Mỗi bản ghi mang
`provenance = file_bridge`, và lần nhập mang `isDemo = true`.

## 7. Đặt lại

Xoá theo **`importJobId`**, không theo cờ `isDemo` trên từng dòng.

Cách theo cờ hỏng ngay lần đầu người bán sửa một sản phẩm demo thành sản phẩm
thật của họ — cờ vẫn `true`, và lần reset sau xoá mất việc của họ.
