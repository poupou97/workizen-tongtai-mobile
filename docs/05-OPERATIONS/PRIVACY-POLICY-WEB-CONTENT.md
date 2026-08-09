# Nội dung Chính sách riêng tư cho web — phần Tổng Tài

*WTM-175 · 2026-08-01 · để đăng lên `https://www.workizen.net/privacy`*

---

## Vì sao có tài liệu này

**Founder Decision 2026-08-01:**

> *"Privacy Policy sử dụng `https://www.workizen.net/privacy`. Nếu URL public,
> HTTPS và **nội dung đầy đủ** thì dùng làm URL chính thức cho App Store và
> Google Play."*

Tôi đã kiểm trang đó (bản ngày **9 tháng 7, 2026**). Kết quả theo đúng ba điều
kiện Founder đặt ra:

| Điều kiện | |
|---|---|
| Public | ✅ đạt |
| HTTPS | ✅ đạt |
| **Nội dung đầy đủ cho Tổng Tài** | ❌ **chưa đạt** |

⇒ Theo chính điều kiện của Founder, **chưa dùng được làm URL chính thức**. Bốn
khoảng trống dưới đây, trong đó **khoảng trống 1 là loại nguy hiểm**.

## Bốn khoảng trống

### ❗ 1. Trang không nhắc gì tới telemetry và báo cáo sự cố — nhưng app có

Trang hiện tại **không có một chữ nào** về analytics, crash reporting hay
Firebase. Tổng Tài **có dùng** Firebase Analytics + Crashlytics (ADR-TON-005,
Founder duyệt 2026-07-23).

Đây là **khai ít hơn app làm**. `docs/05-OPERATIONS/STORE-DATA-SAFETY.md` viết
đúng câu này sáng nay:

> *"Khai nhiều hơn app làm là tự chuốc nghi ngờ; khai **ít hơn** app làm là
> **khai sai** và Google/Apple gỡ app vì điều đó."*

**Đây là lý do chính khiến chưa dùng được ngay.**

### 2. Trang nói app thu thập tài khoản/email — Tổng Tài thì không

Trang liệt kê *"Account & authentication data (email, authentication tokens)"*.
Tổng Tài **không có tài khoản** (D-4). Một người bán đọc trang này sẽ tưởng phải
đăng ký và giao email — **đúng cái sản phẩm cố tình không làm**.

Khai thừa không bị gỡ app, nhưng nó **phá đúng lời hứa mạnh nhất** của sản phẩm.

### 3. Trang không nhắc tên Tổng Tài

Trang phủ *"workizen.net và các sản phẩm preview liên quan"* + *"Workizen Hub
mobile app"*. Không có `Tổng Tài`, không có `com.workizen.tongtai`.

Cả Google Play lẫn App Store đều yêu cầu chính sách **áp dụng cho app đang
nộp**. Người xét duyệt phải đọc thấy tên app.

### 4. Chỉ có tiếng Anh

Sản phẩm là **VI primary** (D-8), người dùng là chủ SME Việt Nam. Cửa hàng
không bắt buộc song ngữ, nhưng một chính sách người dùng không đọc được thì
không phải là thông báo cho họ.

---

## Cách sửa — hai lựa chọn

| | |
|---|---|
| **A** | Thêm **một mục "Tổng Tài"** vào trang hiện tại — nội dung bên dưới. Giữ nguyên một URL `/privacy` |
| **B** | Tạo trang riêng `/privacy/tongtai` và dùng URL đó cho cả hai cửa hàng |

**Tôi đề nghị A** — một URL dễ bảo trì hơn, và trang hiện tại đã nói đúng phần
BYOK rồi. Nhưng dù A hay B, **mục 2 (tài khoản/email) phải ghi rõ là không áp
dụng cho Tổng Tài**, nếu không nó vẫn mâu thuẫn.

---

## Nội dung để đăng — tiếng Việt

> Bản này lấy **nguyên văn** từ chính sách trong app (`AppStrings`, WTM-37) để
> hai bên không bao giờ lệch nhau. Sửa một bên ⇒ sửa bên kia **trong cùng PR**.

---

### Tổng Tài (`com.workizen.tongtai`)

*Cập nhật 01/08/2026*

Tổng Tài là ứng dụng **local-first**. Mục này áp dụng riêng cho Tổng Tài và
**thay thế** phần "Account & authentication data" ở trên: **Tổng Tài không có
tài khoản, không yêu cầu email, không phát hành token đăng nhập.**

**Dữ liệu kinh doanh nằm trên máy bạn**
Khách hàng, sản phẩm, đơn hàng, mục tiêu, giao dịch — tất cả lưu trên thiết bị
này. Không tài khoản, không máy chủ Tổng Tài, không đồng bộ. Chúng tôi không
nhận được dữ liệu kinh doanh của bạn.

**Workizen AI dùng khoá của chính bạn**
Khi bạn hỏi Workizen AI, nội dung câu hỏi đi thẳng từ máy bạn tới nhà cung cấp
bạn đã chọn, kèm khoá API của bạn. Chúng tôi không trung chuyển và không thấy
nội dung đó — chính sách của nhà cung cấp áp dụng cho phần họ nhận. Dùng chế độ
Local thì nội dung chỉ đi tới máy trong mạng nội bộ của chính bạn. Khoá lưu
trong kho bảo mật của hệ điều hành, không nằm trong bản sao lưu.

**Số liệu vận hành chúng tôi nhận**
Chỉ hai thứ: app được mở (không kèm tham số nào), và một màn không đọc được dữ
liệu (kèm tên màn, loại lỗi, mã lỗi cố định). Không có tên khách hàng, số tiền,
số bản ghi, tên file hay đường dẫn. Mô tả lỗi chi tiết chỉ hiện trên máy bạn.

**Báo cáo sự cố**
Khi app dừng đột ngột, chúng tôi nhận stack trace, model máy và phiên bản hệ
điều hành để sửa lỗi. Báo cáo gọi tên loại lỗi nhưng cố ý không mang theo giá
trị dữ liệu, tên khách hàng hay con số doanh thu.

**Không quảng cáo, không hồ sơ người dùng**
Không SDK quảng cáo, không theo dõi tiếp thị, không lập hồ sơ, không quảng cáo
cá nhân hoá. Quyền Advertising ID bị gỡ khỏi ứng dụng. Quyền duy nhất app xin
là truy cập Internet, để gọi nhà cung cấp AI bạn chọn.

**Sao lưu**
Bản sao lưu tạo trên máy bạn và chỉ rời khỏi máy nếu bạn chủ động chia sẻ. Bạn
có thể đặt mật khẩu. Mã kiểm tra SHA-256 dùng để phát hiện file hỏng — đó là
chống hỏng, không phải chống giả mạo. Bản sao lưu chứa dữ liệu kinh doanh,
không chứa khoá API.

**Phản hồi bạn gửi cho chúng tôi**
Khi bạn dùng "Gửi phản hồi", app soạn sẵn nội dung bạn viết kèm bốn thông tin
kỹ thuật: phiên bản app, nền tảng, phiên bản hệ điều hành, ngôn ngữ giao diện.
Bạn thấy toàn bộ nội dung đó trước khi gửi, và **bạn** chọn ứng dụng để gửi.
Không có dữ liệu kinh doanh nào được đính kèm.

**Quyền của bạn**
Gỡ app là xoá toàn bộ dữ liệu trên máy. Không có bản sao nào ở phía chúng tôi
để yêu cầu xoá, vì chúng tôi chưa từng nhận. Bạn có thể xuất dữ liệu ra CSV
hoặc tạo bản sao lưu bất cứ lúc nào.

**Liên hệ:** workizen.labs@gmail.com

---

## Nội dung để đăng — tiếng Anh

### Tổng Tài (`com.workizen.tongtai`)

*Updated 1 August 2026*

Tổng Tài is a **local-first** app. This section applies specifically to Tổng Tài
and **supersedes** the "Account & authentication data" section above: **Tổng Tài
has no account, requires no email address, and issues no authentication tokens.**

**Your business data stays on your device**
Customers, products, orders, goals and transactions are all stored on this
device. No account, no Tổng Tài server, no sync. We never receive your business
data.

**Workizen AI uses your own key**
When you ask Workizen AI, your message goes directly from this device to the
provider you chose, authenticated with your own API key. We do not proxy it and
never see it — the provider's own policy governs what they receive. In Local
mode your message only reaches a machine on your own network. Keys live in the
operating system secure store and are never included in a backup.

**The operational data we do receive**
Two things only: that the app was opened (with no parameters at all), and that
a screen failed to load data (with the screen name, the failure kind and a fixed
error code). No customer names, amounts, record counts, file names or paths.
Detailed error text stays on your device.

**Crash reports**
If the app stops unexpectedly we receive a stack trace, your device model and OS
version so we can fix it. A report names the kind of failure but deliberately
carries no data value, customer name or revenue figure.

**No ads, no profiling**
No ad SDKs, no marketing tracking, no profiling, no personalised ads. The
Advertising ID permission is stripped from the app. The only permission
requested is internet access, to reach the AI provider you chose.

**Backups**
A backup is created on your device and leaves it only if you share it. You can
set a passphrase. The SHA-256 checksum detects a corrupted file — it is
corruption protection, not tamper protection. Backups contain your business
data; they never contain API keys.

**Feedback you send us**
When you use "Send feedback", the app composes what you wrote together with four
technical facts: app version, platform, OS version and interface language. You
see all of it before sending, and **you** choose which app sends it. No business
data is attached.

**Your choices**
Uninstalling the app deletes all data on the device. There is no copy on our
side to request deletion of, because we never received one. You can export to
CSV or create a backup at any time.

**Contact:** workizen.labs@gmail.com

---

## Sau khi đăng — kiểm lại 5 điểm

- [ ] Trang có chữ **"Tổng Tài"** và **`com.workizen.tongtai`**
- [ ] Trang **có nói** về telemetry + crash reporting (khoảng trống ❗1)
- [ ] Trang **nói rõ** phần tài khoản/email **không áp dụng** cho Tổng Tài
- [ ] Có bản tiếng Việt
- [ ] Nội dung khớp `AppStrings` trong app (VI **và** EN)

Xong 5 điểm ⇒ URL dùng được cho **cả Play Console lẫn App Store Connect**, và
`docs/05-OPERATIONS/STORE-DATA-SAFETY.md` gạch được mục *"URL chính sách riêng
tư công khai"*.

## Một mục đã gạch được ngay

> **Đổi 2026-08-09:** Founder chốt `workizen.labs@gmail.com`. Địa chỉ trước đó
> (`privacy@workizen.net`) **chưa bao giờ tồn tại** — không có email công ty. Ba
> trang đang hứa quyền yêu cầu xoá dữ liệu qua một hộp thư không nhận được thư;
> đó là cam kết không thực hiện được, không phải lỗi hiển thị.

Trang hiện tại **đã có** `workizen.labs@gmail.com`. Đó là **địa chỉ liên hệ** — một
trong ba hạng mục Founder Gate của WTM-175. ✅

Còn lại: **Điều khoản dịch vụ** (`moreTerms` trong app vẫn *"sắp có"*).
