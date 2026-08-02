# Dogfood 01 — thử ghi chính Workizen vào Tổng Tài

> **Founder 2026-08-02:** *"Đừng coi Producer chỉ là Supplier. Producer là
> Capability quản lý toàn bộ đầu vào của doanh nghiệp. Thiết kế Producer quanh
> **Business Input**, không quanh Supplier."*

**Phép thử:** Workizen là một doanh nghiệp có thật. Thử biểu diễn nó bằng mô
hình của Tổng Tài, xem chỗ nào mô hình chịu được và chỗ nào buộc người dùng
phải nói dối.

⚠️ **Phạm vi trung thực của lần này:** đây là dogfood **mô hình hoá** (sản phẩm
có biểu diễn được doanh nghiệp này không), **không phải** dogfood trên thiết bị
— máy thật hiện không kết nối (`adb devices` rỗng). Những gì cần mắt nhìn trên
máy (hiệu năng, cảm giác dùng, lỗi runtime) **chưa được kiểm** ở lần này.

---

## Đầu vào thật của Workizen

Đọc từ chính repo và hạ tầng đang dùng, không phải phỏng đoán:

| Đầu vào | Bản chất | Ghi ở đâu trong Tổng Tài hôm nay |
|---|---|---|
| **Chi phí AI provider** (BYOK: xAI/Grok…) | định kỳ, **theo mức dùng** | `FinanceCategory.other` |
| **Hạ tầng** (Firebase `workizen-hub`) | định kỳ, cố định | `other` |
| **Công cụ** (GitHub · Atlassian) | định kỳ, theo chỗ ngồi | `other` |
| **Thời gian người / agent** | định kỳ | `staff` (gần đúng nhất) |
| **Tài khoản Apple Developer** | một lần, hằng năm | `other` |

**Đầu vào lớn nhất của một doanh nghiệp AI-first rơi hết vào `other`.**

---

## Bốn chỗ mô hình buộc phải nói dối

### 1. `Product` là mô hình hàng VẬT LÝ, bắt buộc

`quantity`, `reorderLevel`, `sku` đều **required**. Một sản phẩm số không có
tồn kho và không có mức đặt lại. Muốn ghi Tổng Tài (chính nó) vào Tổng Tài,
người dùng phải **bịa một con số tồn kho** — và ngay sau đó máy sẽ hành xử theo
con số bịa ấy: `quantity: 0` ⇒ Inventory kêu **"Hết hàng"** và Rule Engine sinh
**cơ hội nhập hàng** cho một phần mềm.

Đây là hình dạng lỗi tệ nhất trong repo này: **sản phẩm tự tin về một điều
không có thật**.

### 2. `BusinessTrade` không có ngành sản phẩm số

`fashion · food · cosmetics · electronics · services · other`. Một doanh nghiệp
phần mềm phải khai là *dịch vụ* hoặc *khác* ⇒ hồ sơ AI mô tả sai ngay từ câu
đầu, và mọi gợi ý sau đó dựng trên mô tả sai đó.

### 3. `SalesChannel` không có kênh số

`shop · market · shopee · tiktok · facebook · zalo · wholesale`. Không có app
store, không có website, không có bán trực tiếp. Doanh thu của Workizen **không
kênh nào ghi được** ⇒ luôn là "chưa ghi" (WTM-209), và *"Doanh thu theo kênh"*
vĩnh viễn trống.

### 4. Không có khái niệm **nguồn đầu vào định kỳ**

Producer hôm nay = danh bạ nhà cung cấp hàng vật lý (MOQ, thời gian giao,
Thâm Quyến/Nghĩa Ô). Không có chỗ nào biểu diễn *"một nhà cung cấp mà tôi trả
tiền hằng tháng, chi phí tăng theo mức dùng"* — đúng thứ mà **mọi** đầu vào của
Workizen đều là.

---

## Trả lời ba câu hỏi của Founder

**Workizen cần quản lý những nguồn đầu vào nào?** Không phải nhà cung cấp hàng
hoá. Là **provider** (AI, hạ tầng, công cụ) và **thời gian**. Chung một hình
dạng: định kỳ · có chủ thể · chi phí biến thiên theo mức dùng · gắn với một
capability mà nó nuôi.

**Người bán sản phẩm số cần gì?** Không cần tồn kho. Cần biết **chi phí biến
đổi trên mỗi đơn vị bán ra** (với Workizen: token AI mỗi phiên) — thứ thay thế
vai trò của giá vốn trong mô hình hàng hoá. Không có nó thì lợi nhuận của một
sản phẩm số **không tính được**, và ROI/margin hiện đang dựa vào `costPrice`
của mô hình vật lý.

**Capability nào còn thiếu?** Producer đúng nghĩa **Business Input**: nguồn vào
định kỳ + chi phí theo mức dùng + nối vào Finance (chi) và Journey (bước hành
động khi một đầu vào phình lên).

---

## Ranh giới — cái gì tôi tự làm, cái gì phải Founder quyết

**Founder Gate (product positioning):** thêm ngành *sản phẩm số* vào
`BusinessTrade` và kênh số vào `SalesChannel` là **mở rộng đối tượng phục vụ**
của Tổng Tài — hôm nay Concept nhắm người bán lẻ SME Việt Nam. Không tự quyết.

**Tự làm được (Data First, không đụng positioning) — đã làm cả hai:**
* ~~`FinanceCategory` thiếu mã cho **chi phí công cụ / hạ tầng / AI**~~ →
  **WTM-236**: thêm `infrastructure` · `tooling` · `provider`, dùng **đúng mã
  của `BusinessInputKind`** để hai vựng từ không thể lệch.
* ~~Chi phí **định kỳ** chưa biểu diễn được~~ → **WTM-229/234**: `InputCadence`
  + tổng cam kết hằng tháng, và **WTM-235** đưa nó vào hành trình.

## Lần 2 — trên máy thật (2026-08-02, Nokia 6.1, bản release)

Lần 1 chỉ là dogfood **mô hình hoá**; phần này trả nốt.

Máy đang chạy bản cài ngày 2026-08-01, tức schema **trước** v14 — nên lần cài
đè này chạy trọn chuỗi **v13 → v16** (ProductKind + `quantity` nullable ·
`typeCode` · `business_inputs_table`) trên **dữ liệu thật của Founder**. Đây là
thứ 1795 test không kiểm được: trước đó chính thiết bị đã bắt hai lỗi migration
mà suite xanh không thấy.

**Kết quả:** dữ liệu nguyên vẹn (14 sản phẩm · 66,9tr đ tồn kho · 17 cơ hội) ·
`logcat -b crash` **rỗng** · không một dòng `SqliteException` / `no such column`
/ `duplicate column`.

Đi thật, không chỉ mở lên nhìn:

| Việc | Kết quả |
|---|---|
| Producer → *Nguồn đầu vào* → thêm **Firebase · Hạ tầng · Hằng tháng · 500.000 đ** | lưu được, danh sách hiện đúng |
| `force-stop` rồi mở lại | *Cam kết mỗi tháng* vẫn **500.000 đ** — bảng v16 sống qua lần đóng app |
| Kho → Thêm sản phẩm → chọn **Sản phẩm số** | ô tồn kho + mức đặt lại **biến mất**, hiện *"Loại này không có tồn kho để đếm."*, nhãn giá vốn đổi thành *"Chi phí mỗi lượt bán"* |

Bốn chỗ mô hình từng buộc phải nói dối: **(1)** đã xong (WTM-227/233) ·
**(3)** đã xong (WTM-232) · **(4)** đã xong (WTM-229/230/234) · **(2)**
`BusinessTrade` thiếu ngành sản phẩm số — nay thay bằng `BusinessType`
(WTM-228), là chiều đúng để hỏi.

## Việc chưa làm được

Không còn ở phần thiết bị. Còn lại là món nợ đã ghi trong
`test/database_upgrade_test.dart`: **chưa test nào tái hiện được lỗi
migration-replay** — bằng chứng cho bản vá đó vẫn chỉ là thiết bị.
