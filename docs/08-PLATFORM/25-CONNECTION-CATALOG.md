# 25 · Connection Catalog — nguồn dữ liệu nói đúng trạng thái

> **WTM-331 · C7 · Epic WTM-324**

## 1. Vì sao cần

Founder §24: ⛔ **Không gọi Demo XLSX là dữ liệu Shopify/Shopee.**

Một danh sách nguồn mà mọi dòng trông như nhau sẽ khiến người bán tin app đang
đồng bộ với sàn — trong khi thứ họ có là một file Excel họ tự tải về.

## 2. ⭐ Ba tầng, và trộn chúng là chỗ dễ nói dối nhất

| Tầng | Là gì | Trường |
|---|---|---|
| **Bằng chứng nguồn** | ta tìm thấy gì trong bộ mã đã đọc | `evidence` |
| **Tài liệu vendor** | vendor nói có gì | `vendorClaim` |
| **Quyết định sản phẩm** | ta chọn làm gì | `readiness` |

Ba tầng **có thể mâu thuẫn nhau**, và khi mâu thuẫn thì việc của catalog là
hiện cả ba chứ không hoà giải chúng.

Điều này đến thẳng từ chỉnh sửa của Founder ở Task Order trước (§21):

> *"Không được suy ra: '0 implementation trong 1124 connector' = 'Vendor không
> có API'. Đó chỉ là: NO IMPLEMENTATION FOUND IN STUDIED SOURCE SET."*

Không phải chuyện chữ nghĩa: *"vendor không có API"* **đóng lại một hướng đi**,
còn *"ta chưa tìm thấy trong bộ mã đã đọc"* thì không. Có test chặn việc viết
câu thứ nhất.

## 3. Sáu trạng thái

| Mã | Nghĩa | Ai đang ở đây |
|---|---|---|
| `connected` | nối thật, chạy được trên máy | Tự nhập nhà cung cấp |
| `file_bridge` | dữ liệu vào **qua file**, không tự cập nhật | Google Drive / Excel |
| `demo` | chỉ có dữ liệu mẫu, chưa nối gì | Alibaba · 1688 · AliExpress |
| `researched` | biết làm thế nào, **chưa dựng** | Shopify · WooCommerce |
| `partner_required` | kỹ thuật làm được, chờ **sàn duyệt** | Shopee · TikTok Shop |
| `api_future` | để sau. **Không** phải "không làm được" | eBay · Amazon · URL import |

`partner_required` tách khỏi `api_future` có lý do: một cái **chờ người duyệt**,
cái kia **chờ ta viết code**. Hai loại rào cản đó dẫn tới hai việc tiếp theo
hoàn toàn khác nhau, và gộp chúng lại sẽ khiến ta chờ nhầm thứ.

## 4. `connected` không tự khai được

Muốn khai `connected` thì phải có **một connector thật** trong
`ConnectorDescriptor.catalog`, hoặc là đường tự nhập (không cần vendor nào).
Không có đường thứ ba, và có test chặn.

Đây là chỗ luật §24 trở thành **cơ chế**: một dòng catalog sai không làm gì đỏ
trong CI thường — nó chỉ khiến người bán tin nhầm.

## 5. §D-6 — connector ≠ chỉ API

Founder: *"Connector ≠ chỉ API"* — app-to-app · share · deep link · URL import ·
file import đều là đường vào hợp lệ.

Nên mỗi nguồn khai `entryPattern`, và `file_import` / `url_import` / `manual`
đứng ngang hàng với một API. Google Drive vào bằng `file_import` và nó **đang
chạy thật**, trong khi Amazon có API đầy đủ và vẫn ở `api_future`.

## 6. Màu không được nói khác chữ

Chỉ `connected` màu xanh. `file_bridge` **màu trung tính** — "nhập qua file" là
một cách dùng thật, nhưng nó không phải "đã nối", và một chấm xanh nhạt sẽ nói
điều mà chữ bên cạnh không nói.

`partner_required` màu cam: có việc phải làm, nhưng việc đó không nằm ở ta.

## 7. Catalog là dữ liệu

Governance quét `lib/features/tongtai/ui/` tìm tên nguồn hardcode. Thêm một
nguồn phải sửa **một** chỗ; hardcode nghĩa là hai chỗ, và chỗ thứ hai sẽ bị
quên.
