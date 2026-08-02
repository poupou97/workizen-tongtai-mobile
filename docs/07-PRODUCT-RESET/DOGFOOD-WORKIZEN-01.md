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

**Tự làm được (Data First, không đụng positioning):**
* `FinanceCategory` thiếu mã cho **chi phí công cụ / hạ tầng / AI** — đây là
  vựng từ chi phí, không phải đối tượng phục vụ; và nó đã là bài học WTM-197.
* Chi phí **định kỳ** chưa biểu diễn được: mọi khoản chi đều là sự kiện một
  lần, nên không capability nào trả lời được *"tháng này tôi cam kết trả bao
  nhiêu?"*.

## Việc chưa làm được ở lần dogfood này

Dùng thật trên thiết bị. Cần bản release + máy thật + `adb`; khi có, phải kiểm
đúng những thứ chỉ máy mới lộ (bài học WTM-166/172: quét tĩnh có trần).
