# ADR-TON-023 — Định vị mở rộng · Product Type · Producer = Business Input

**Trạng thái:** Accepted (Founder, 2026-08-02)
**Thay thế/mở rộng:** giả định "SME bán hàng vật lý" ngầm định trong ADR-TON-001

---

## Bối cảnh

Dogfood Workizen ([DOGFOOD-WORKIZEN-01](../07-PRODUCT-RESET/DOGFOOD-WORKIZEN-01.md))
thử biểu diễn chính Workizen — một doanh nghiệp phần mềm — bằng mô hình của
Tổng Tài. Mô hình gãy ở bốn chỗ, và chỗ nặng nhất là:

`Product` bắt buộc `quantity` · `reorderLevel`. Sản phẩm số không có tồn kho.
Muốn ghi nó, người dùng **phải bịa một con số** — rồi máy hành xử theo con số
bịa đó: `quantity: 0` ⇒ Inventory kêu *"Hết hàng"* và Rule Engine **sinh cơ hội
nhập hàng cho một phần mềm**.

Founder: *"Đây không phải bug. Đây là phát hiện kiến trúc."*

## Quyết định

### 1. Định vị

Tổng Tài là **AI Business Operating System cho SME**, không giới hạn ở bán hàng
vật lý. Bốn loại hình đều là công dân hạng nhất: **Physical · Digital ·
Service · Hybrid**.

### 2. Producer = Business Input

Producer **không phải** danh bạ nhà cung cấp. Nó là capability quản lý **toàn bộ
đầu vào** của doanh nghiệp. **Supplier chỉ là một loại Business Input**; các
loại khác gồm provider định kỳ (AI, hạ tầng, công cụ) và thời gian.

### 3. Product Type

`ProductKind`: `physical` · `digital` · `service`.

`quantity` và `reorderLevel` **nullable**, và `null` nghĩa là **"không áp
dụng"**, không phải 0. Đây là kỷ luật đã có trong repo, nay áp cho một chiều
mới:

| Trường | `null` nghĩa là | Không bao giờ nghĩa là |
|---|---|---|
| `paymentStatus` (WTM-211) | chưa ghi | đã trả / còn nợ |
| `costPrice` (WTM-204) | chưa ai nhập | miễn phí |
| `quantity` (đây) | **không áp dụng cho loại này** | hết hàng |

## Ba luật không được vi phạm

1. **Không bịa dữ liệu.** Không có ô nào buộc người dùng điền một con số vô
   nghĩa với loại hình của họ.
2. **Không ép doanh nghiệp số thành doanh nghiệp hàng hoá.** Sản phẩm số không
   có trạng thái kho, không sinh cơ hội nhập hàng, không nằm trong chỉ số tồn.
3. **Không ép doanh nghiệp hàng hoá thành doanh nghiệp số.** Mọi thứ đang hoạt
   động cho hàng vật lý giữ nguyên hành vi; dữ liệu cũ mặc định `physical` vì
   **đó là sự thật** — chúng được nhập dưới mô hình chỉ-có-hàng-vật-lý.

## Hệ quả

* **Schema v14**: thêm `kind`; nới `quantity`/`reorderLevel` thành nullable.
* `stockStatus` không áp dụng cho phi vật lý ⇒ `StockAlert.forProduct` trả
  `null`; Rule Engine không sinh `gen-restock-*`; `InventorySummary` chỉ đếm
  hàng vật lý trong chỉ số kho.
* `.ttbk`: `kind` lưu **mã canonical**; mã lạ ⇒ bản ghi hỏng, **không đoán**
  (ADR-TON-018).
* Lợi nhuận sản phẩm số cần **chi phí biến đổi trên mỗi đơn vị bán**, không
  phải giá vốn nhập kho — đó là ADR/story riêng (Digital Cost Model, ưu tiên #4
  của Founder), **không** giải quyết ở đây.

## Thứ tự triển khai (Founder) — trạng thái 2026-08-02

| # | Việc | Story | Trạng thái |
|---|---|---|---|
| 1 | **Product Type** | WTM-227 (miền, schema v14) · WTM-233 (ô chọn trên form) | ✅ |
| 2 | **Business Type** | WTM-228 (schema v15, `null` = *chưa hỏi*) | ✅ |
| 3 | **Business Input** | WTM-229 (miền) · WTM-230 (`.ttbk`) · WTM-234 (màn + đường vào) | ✅ |
| 4 | **Digital Cost Model** | WTM-231 — `costPrice` **không phải "giá nhập"** mà là *chi phí biến đổi mỗi đơn vị bán*; đổi nhãn theo loại, **không** thêm trường thứ hai | ✅ |
| 5 | **Sales Channel** | WTM-232 (`website` · `app_store` · `direct`) | ✅ |

Kiểm trên máy thật 2026-08-02 (chuỗi v13→v16, dữ liệu thật của Founder, crash
buffer rỗng): [DOGFOOD-WORKIZEN-01 §Lần 2](../07-PRODUCT-RESET/DOGFOOD-WORKIZEN-01.md).

**Việc còn hở, đã ghi rõ chứ không tính là xong:** chi phí đầu vào **chưa nối**
vào Finance và Journey — thêm một khoản cam kết không làm hành trình kinh doanh
đổi gì (xem [BUSINESS-LOOP-MATRIX](../02-ARCHITECTURE/BUSINESS-LOOP-MATRIX.md)).

## Điều ADR này KHÔNG quyết

Không thiết kế riêng cho Workizen. Workizen là **ca thử** làm lộ ra chỗ mô hình
nói dối; mô hình phải biểu diễn trung thực **nhiều loại SME**, không phải vừa
vặn một doanh nghiệp cụ thể.
