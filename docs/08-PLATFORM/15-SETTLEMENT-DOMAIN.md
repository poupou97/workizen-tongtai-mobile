# Settlement Domain — để trả lời "lợi nhuận thật", không chỉ "doanh thu"

> **WTM-286 · N0.4 · Epic WTM-284 (Platform Wave 2).** Ngày **2026-08-07**.
> Thiết kế, **không** code connector, **không** gọi API.

---

## Vấn đề hôm nay, nói bằng một câu

Phí sàn hiện là **giao dịch rời** trong Finance, không gắn với đơn nào. Nên khi
import đơn từ sàn, app sẽ cho **doanh thu đúng và lợi nhuận sai** — sai theo
hướng *tâng bốc*, tức hướng nguy hiểm nhất.

Một người bán nhìn "doanh thu 50 triệu" rồi nhập hàng theo đó, trong khi sàn đã
giữ lại 12% hoa hồng, 3% phí thanh toán, và một phần voucher mà **người bán tự
chịu** chứ không phải sàn tài trợ.

---

## Mô hình

```
Order ──1..n──► OrderItem
  ▲                ▲
  │                │        SettlementLine gắn được vào MỘT trong hai
  └────────┬───────┘
           │
   SettlementLine {
       kind        : SettlementKind      (10 mã canonical)
       direction   : SettlementDirection (thu | chi — TƯỜNG MINH)
       amount      : số dương, luôn luôn
       currency    : mã ISO
       fundedBy    : FundingSource       (BẮT BUỘC với voucher/discount)
       orderId     : luôn có
       orderItemId?: có khi khoản này thuộc về một món cụ thể
       payoutId?   : lô đối soát đã trả khoản này
       provenance  : Provenance (WTM-282)
       occurredAt  : khi nào phát sinh
   }

   Payout {                    ← một lô tiền về tài khoản
       id · connectionId · amount · currency · settledAt
       reconciledDelta?        ← chênh lệch CHƯA giải thích được
   }
```

---

## Mười loại — `SettlementKind`

| Mã canonical | Là gì | Thường gắn ở |
|---|---|---|
| `platform_fee` | phí sàn cố định | Order |
| `commission` | hoa hồng theo doanh số | **OrderItem** |
| `shipping_fee` | phí vận chuyển | Order |
| `voucher` | mã giảm giá | cả hai — xem §Voucher |
| `discount` | người bán tự giảm | OrderItem |
| `refund` | hoàn tiền cho khách | cả hai |
| `adjustment` | sàn điều chỉnh (bồi thường, phạt) | Order |
| `chargeback` | khách khiếu nại qua ngân hàng | Order |
| `tax` | thuế khấu trừ tại nguồn | Order |
| `payout` | tiền thực về tài khoản | *(không phải dòng — xem `Payout`)* |

Mã lạ ⇒ `unknown`, **không** ánh xạ về mã gần giống nhất (ADR-TON-018).

---

## ⭐ Ba điểm sắc nhất

### 1. Dấu tiền KHÔNG được suy từ số âm/dương

`amount` **luôn dương**; chiều nằm ở `direction` tường minh.

Vì sao: *hoàn lại một khoản phí* đảo chiều so với *khoản phí* — mà cả hai đều
mang `kind: platform_fee`. Nếu chiều nằm ở dấu của số, thì một connector viết
`-50000` và một connector khác viết `50000` cho **cùng một sự việc**, và không
ai phát hiện cho tới khi báo cáo lệch.

Đây là cùng một họ lỗi với "mã lạ rơi về default": để ngữ nghĩa nằm ngầm trong
biểu diễn thay vì nói ra.

### 2. Voucher phải khai AI TRẢ — và không có mặc định

```
FundingSource : platform | seller | shared | unknown
```

| Ai trả | Ảnh hưởng lợi nhuận người bán |
|---|---|
| `platform` — sàn tài trợ | **không phải chi phí của người bán** |
| `seller` — người bán chịu | là chi phí, trừ thẳng vào lợi nhuận |
| `shared` — chia theo tỷ lệ | phải có thêm tỷ lệ, nếu không thì là `unknown` |
| `unknown` | **lợi nhuận là chưa biết**, không phải "coi như sàn trả" |

Nhầm chỗ này làm lợi nhuận sai đúng theo hướng dễ chịu. Nên `fundedBy` **không
có giá trị mặc định** — connector không khai được thì ghi `unknown`, và Rule
Twin **từ chối** trả số lợi nhuận thay vì đoán.

### 3. Gắn ở cấp Order hay OrderItem — và cấm tự phân bổ

Hoa hồng theo món; phí vận chuyển theo đơn; voucher có thể cả hai.

Model cho phép cả hai cấp. Nhưng **cấm tự động phân bổ** một khoản cấp-đơn
xuống từng món: phân bổ là một **luật dẫn xuất**, và nếu nó chạy ngầm lúc ghi
thì sẽ có hai nguồn sự thật cho cùng một con số — đúng lỗi P-27/P-28 đã lặp
bốn lần trong repo này.

⇒ Phân bổ, nếu cần, là **hàm thuần đọc lúc hiển thị**, nằm đúng một chỗ, và
kết quả của nó **không được ghi xuống đĩa**.

---

## `Payout` — đối soát, và chỗ được phép "không biết"

Một `Payout` gom nhiều đơn. Luật:

```
Σ(doanh thu đơn) − Σ(SettlementLine chi) + Σ(SettlementLine thu)  ==?  Payout.amount
```

Lệch ⇒ ghi vào `reconciledDelta` và **hiện ra cho người bán**. Không san bằng,
không giấu vào "khác".

Vì sao đây là tính năng chứ không phải lỗi: sàn **thường** có khoản chưa giải
thích được — phí lẻ, làm tròn, khoản treo từ kỳ trước. Một hệ thống ép cho khớp
bằng cách bịa một dòng "điều chỉnh" là hệ thống nói dối. Một hệ thống nói *"lệch
47.000 đ, chưa rõ vì sao"* là hệ thống dùng được.

---

## Lợi nhuận thật — và khi nào từ chối trả lời

```
lợi nhuận thật = doanh thu
               − giá vốn (COGS)
               − Σ SettlementLine chi
               + Σ SettlementLine thu
```

**Rule Twin từ chối trả số khi:**
- thiếu giá vốn của bất kỳ món nào trong kỳ (`costPrice` null = *chưa nhập*)
- có `voucher`/`discount` với `fundedBy: unknown`
- `Payout.reconciledDelta` vượt ngưỡng chưa giải thích được

Từ chối trả về `insufficient` kèm reason code (ADR-TON-016/017), **không** trả
doanh thu và gọi nó là lợi nhuận. Đây chính là kỷ luật `null` ≠ `0` áp cho con
số quan trọng nhất trong app.

---

## Ảnh hưởng tới dữ liệu hiện có

**Không có.** Thiết kế này chỉ **thêm**:
- bảng `settlement_lines_table` và `payouts_table` — mới, rỗng
- không cột nào của `orders_table` / `transactions_table` đổi nghĩa
- giao dịch phí sàn người bán đã tự nhập **giữ nguyên** trong Finance; chúng
  không tự nhảy sang Settlement, vì di chuyển chúng là đoán ý người bán

⇒ Không đụng local-first, không migration phá huỷ. Điều kiện dừng của Task
Order **không kích hoạt**.
