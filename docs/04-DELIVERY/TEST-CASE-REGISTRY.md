# Sổ Test Case — mục chung

> Founder yêu cầu 2026-08-22: *"lưu lại các test case vào mục chung để sau này
> tự động test."*

## Sổ này KHÔNG phải danh sách test tự động

Test tự động đã có chỗ của nó: `test/`, chạy trong CI mỗi PR, ~2900 case. Chép
lại chúng ra đây chỉ tạo một bản sao hết hạn ngay ngày hôm sau.

Sổ này giữ thứ **chưa** tự động được — kịch bản hôm nay còn phải có người ngồi
kiểm. Mỗi mục ghi ba thứ:

| Cột | Nghĩa |
| --- | --- |
| **Kiểm gì** | thao tác + dấu hiệu chứng minh đạt |
| **Vì sao chưa tự động** | lý do thật, không phải "chưa có thời gian" |
| **Cần gì để tự động** | điều kiện cụ thể để chuyển mục này sang `test/` |

Cột thứ ba là mục đích của cả sổ: nó biến *"để sau tự động"* thành một danh
sách việc, thay vì một lời hứa.

⚠️ **Mục nào tự động được thì XOÁ khỏi đây** và để lại mã test trong `test/`.
Một sổ chỉ dài ra là một sổ không ai đọc.

---

## A · Nhập file sàn (Epic WTM-440)

### A-1 · File xuất THẬT của một sàn đọc đúng
* **Kiểm gì:** người bán xuất file đơn từ Seller Centre của họ → nhập vào app →
  số đơn và doanh thu khớp con số sàn hiển thị.
* **Vì sao chưa tự động:** không có file thật nào trong repo, và **không được
  phép có** — file đơn mang tên · số điện thoại · địa chỉ **khách hàng của
  người bán**. Đưa vào repo là làm lộ dữ liệu cá nhân của bên thứ ba.
* ⚠️ **Đính chính 2026-08-22:** bản đầu ghi *"Founder xuất file từ shop Shopee
  của mình"*. **Sai — Founder KHÔNG có shop trên sàn nào.** Tôi suy điều đó từ
  một thông báo lỗi (*"không phải Mall/Preferred Seller"*) thay vì hỏi, và
  thông báo ấy đúng với cả hai trường hợp *"có shop hạng thấp"* lẫn *"không có
  shop"*. Cùng hình dạng với [P-45]/[P-46].
* **Hệ quả:** **không ai trong đội có đường lấy file thật.** Sáu hồ sơ cột
  (WTM-442) vẫn là **giả định**, và bước ghép cột (WTM-443) là lưới an toàn
  cho đúng tình huống này.
* **Cần gì để tự động:** một file đã **ẩn danh hoàn toàn**, do chính người bán
  tạo trên máy họ và đồng ý chia sẻ. Hoặc: một người bán thật dùng app và kể
  lại app hiện gì — **file không rời máy họ**.

### A-2 · Ghép cột trên máy thật với file thật
* **Kiểm gì:** file sàn app chưa nhận ra → hiện bảng ghép cột → chọn đủ vai trò
  bắt buộc → lưu → đọc lại ra đơn. Lần nhập sau **không hỏi lại**.
* **Vì sao chưa tự động:** vế "đọc lại ra đơn" đã có test widget
  (`import_screen_test.dart`). Vế **chưa** có là *bảng ghép cột có dùng được
  bằng ngón tay không* — số ô chọn, độ dài danh sách cột, cuộn trên màn 5 inch.
* **Cần gì để tự động:** không tự động được. Đây là câu hỏi về trải nghiệm, và
  câu trả lời chỉ có trên thiết bị (doctrine *"máy thật thấy thứ suite không
  thấy"*).

### A-3 · Báo cáo đối soát Amazon dạng DÀI
* **Kiểm gì:** file settlement thật của Amazon (`amount-type` ·
  `amount-description` · `amount`, mỗi dòng một khoản) nhập được.
* **Vì sao chưa tự động:** **app chưa hỗ trợ**. Hồ sơ Amazon hiện giả định bản
  xuất *dạng rộng* (mỗi phí một cột). Đây là khoảng cách đã biết, ghi trong
  `marketplace_profile.dart`.
* **Cần gì để tự động:** một reader dạng dài. Đây là vé phát triển, không phải
  vé test.

> ~~**A-4 · Bản đồ cột sống sót qua sao lưu/khôi phục**~~ — **ĐÃ TỰ ĐỘNG HOÁ
> (WTM-445), xoá khỏi sổ.** Nay là `test/features/tongtai/export/
> column_map_backup_roundtrip_test.dart`. Giữ lại một dòng gạch ngang duy nhất
> ở đây làm ví dụ cho luật *"tự động được thì xoá đi"* — mục kế tiếp được
> chuyển sang `test/` thì xoá luôn cả dòng này.

---

## B · Thiết bị thật

### B-1 · Smoke-launch bản release
* **Kiểm gì:** cài bản release lên máy thật, mở app, `adb logcat -b crash`
  **rỗng**.
* **Vì sao chưa tự động:** không có thiết bị trong CI. Và theo `CLAUDE.md`, mọi
  story chạm native/gradle/Firebase **bắt buộc** có bước này.
* **Cần gì để tự động:** một device farm. Chưa có, và chưa đáng.

### B-2 · TalkBack đi hết luồng chính
* **Kiểm gì:** bật screen reader, đi onboarding → Home → tạo đơn → Reports →
  Cài đặt.
* **Vì sao chưa tự động:** cổng a11y tĩnh kiểm **contrast** và **tap target**.
  Thứ hay hỏng là **thứ tự đọc** và **nhãn rỗng trên icon** — nghe mới biết.
* **Cần gì để tự động:** một phần tự động được bằng `SemanticsTester` (nhãn
  rỗng). Thứ tự đọc thì không.

### B-3 · Xoá dữ liệu mẫu giữ nguyên dữ liệu THẬT (WTM-387)
* **Kiểm gì:** trên máy có dữ liệu kinh doanh thật — xoá dữ liệu mẫu, đếm bản
  ghi trước/sau, chứng minh dữ liệu thật còn nguyên.
* **Vì sao chưa tự động:** chỉ trả lời được trên máy **có dữ liệu thật**, tức
  máy Founder. ⛔ Cần Founder cho phép từng lần.
* **Cần gì để tự động:** vế logic **đã** có test (`ADR-TON-014`, tiền tố
  `sample-`). Vế còn lại là niềm tin, và niềm tin cần mắt người.

---

## C · Trực quan

### C-1 · Bám concept
* **Kiểm gì:** đối chiếu từng màn với ảnh trong `docs/01-PRODUCT/concept-1/`.
* **Vì sao chưa tự động:** *"không phạm luật nào mà vẫn sai"* (P-43) — một icon
  đúng mọi cổng vẫn có thể trông thô.
* **Cần gì để tự động:** golden test bắt được **thay đổi ngoài ý muốn**, không
  bắt được **chưa đẹp**. Vế thứ hai không tự động được.

---

## Khi thêm mục vào sổ này

1. Đã chắc **không** tự động được chưa? Tự động được thì viết test, đừng viết
   vào đây.
2. Cột *"cần gì để tự động"* có phải một việc cụ thể không? Nếu là *"chưa có
   thời gian"* thì đó là một test chưa viết, không phải một mục của sổ.
3. Có mục nào cũ nay tự động được không? Xoá nó đi.
