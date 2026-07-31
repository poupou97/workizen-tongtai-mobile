# Chính sách quyền riêng tư — Tổng Tài · Privacy Policy

**Cập nhật / Last updated:** 2026-07-31 · **Ứng dụng / App:** Tổng Tài
(`com.workizen.tongtai`) · **Jira:** WTM-37

> Đây là **nguồn sự thật** cho bản hiển thị trong app (`AppStrings.privacy*`) và
> cho phần khai báo trên cửa hàng ứng dụng. Ba bản đó phải nói **cùng một điều**.
>
> Mọi câu dưới đây đối chiếu được với code. Không có câu nào mô tả điều app
> **định** làm — chỉ điều app **đang** làm.

---

## 1. Dữ liệu kinh doanh của bạn nằm trên máy bạn

Khách hàng, sản phẩm, đơn hàng, mục tiêu, giao dịch — tất cả lưu trong một cơ sở
dữ liệu SQLite **trên thiết bị**. Không có tài khoản, không có máy chủ Tổng Tài,
không có đồng bộ. Chúng tôi **không nhận được** dữ liệu kinh doanh của bạn.

*Your customers, products, orders, goals and transactions live in an SQLite
database **on your device**. There is no account, no Tổng Tài server and no sync.
We never receive your business data.*

## 2. Workizen AI dùng khoá của chính bạn (BYOK)

Khi bạn hỏi Workizen AI, **nội dung câu hỏi đó** được gửi **thẳng từ máy bạn**
tới nhà cung cấp AI mà bạn đã chọn (Gemini · xAI · Claude · OpenRouter ·
Cerebras), kèm khoá API của **bạn** trong header `Authorization`. Chúng tôi
**không trung chuyển, không sao chép, không thấy** nội dung đó.

Chính sách của nhà cung cấp đó áp dụng cho phần dữ liệu họ nhận — hãy đọc chính
sách của họ. Nếu bạn dùng chế độ **Local (Ollama)**, không có gì rời khỏi máy.

Khoá API lưu trong kho bảo mật của hệ điều hành (Android Keystore), không nằm
trong cơ sở dữ liệu và không nằm trong bản sao lưu.

*When you ask Workizen AI, that message goes **directly from your device** to the
provider you chose, authenticated with **your own** API key. We do not proxy it,
copy it or see it. The provider's own policy governs what they receive. In Local
(Ollama) mode nothing leaves the device. Keys are stored in the OS secure store.*

## 3. Số liệu vận hành mà chúng tôi có nhận

Đây là phần **duy nhất** rời khỏi máy về phía chúng tôi, và nó là số liệu vận
hành — **không bao giờ** là nội dung kinh doanh:

| Sự kiện | Kèm theo | Khi nào |
|---|---|---|
| `app_open` | *không có tham số nào* | mỗi lần mở app |
| `screen_error` | `screen` (tên màn), `kind` (loại lỗi), `code` (mã cố định) | một màn không đọc/ghi được dữ liệu |

**Không** có tên khách hàng, số tiền, số lượng bản ghi, tên file hay đường dẫn
trong bất kỳ sự kiện nào. Mô tả lỗi chi tiết (`detail`) **chỉ hiển thị trên máy
bạn** và không bao giờ được gửi đi.

Số liệu này chỉ hoạt động ở các bản dựng có cấu hình Firebase do chúng tôi phát
hành; bản dựng từ mã nguồn công khai **không gửi gì cả**.

*This is the only thing that reaches us, and it is operational only — never
business content. No customer names, amounts, record counts, file names or paths
appear in any event. Error `detail` text stays on your device.*

## 4. Báo cáo sự cố

Khi app crash, Firebase Crashlytics nhận **stack trace**, model máy và phiên bản
hệ điều hành — để chúng tôi sửa lỗi. Đối tượng lỗi của Tổng Tài được thiết kế để
`toString()` **cố ý bỏ** phần mô tả chi tiết, nên một báo cáo sự cố có thể gọi
tên loại lỗi mà **không** mang theo giá trị của một dòng dữ liệu, tên khách hàng
hay con số doanh thu.

*Crash reports carry stack traces, device model and OS version. Tổng Tài's error
type deliberately omits its detail text from `toString()`, so a crash report can
name the failure without carrying a row value, a customer name or a revenue
figure.*

## 5. Không quảng cáo, không hồ sơ người dùng — và điều đó kiểm chứng được

Không có SDK quảng cáo, không theo dõi tiếp thị, không lập hồ sơ, không quảng
cáo cá nhân hoá. Quyền **Advertising ID** và ba quyền Ad Services của Android bị
**gỡ khỏi manifest** bằng `tools:node="remove"` — app đã phát hành không xin
chúng, và điều này đọc được trong `AndroidManifest.xml`.

Quyền duy nhất app xin là **INTERNET** (để gọi nhà cung cấp AI bạn chọn).

*No ad SDKs, no marketing tracking, no profiling, no personalised ads. The
Advertising ID permission and the three Android Ad Services permissions are
**stripped from the manifest**. The only permission requested is INTERNET.*

## 6. Sao lưu (`.ttbk`)

Bản sao lưu được tạo **trên máy bạn** và chỉ rời khỏi máy nếu **bạn** chủ động
chia sẻ nó. Bạn có thể đặt mật khẩu (AES-GCM). Mỗi bản sao lưu có SHA-256 để
phát hiện file hỏng — **đó là chống hỏng, không phải chống giả mạo**: ai sửa nội
dung cũng tính lại được hash. Chỉ bản **có mật khẩu** mới chứng thực được nguồn
gốc.

Bản sao lưu chứa dữ liệu kinh doanh của bạn. **Không** chứa khoá API.

*Backups are created on your device and leave it only if you share them. You can
set a passphrase (AES-GCM). The SHA-256 detects corruption — it is **not**
tamper-proofing. Backups contain your business data; they never contain API keys.*

## 7. Dữ liệu mẫu

"Xem thử Demo" ghi dữ liệu mẫu vào **chính** kho dữ liệu thật, với tiền tố
`sample-`, và "Xóa dữ liệu mẫu" gỡ đúng những bản ghi đó. Dữ liệu bạn tự nhập
**không bao giờ** bị xoá bởi thao tác này.

*Sample data is written into the real repositories with a `sample-` prefix and
removed by the same prefix. Your own data is never deleted by that action.*

## 8. Quyền của bạn

- **Xoá tất cả:** gỡ app, hoặc xoá dữ liệu ứng dụng trong Cài đặt Android. Vì dữ
  liệu chỉ nằm trên máy, làm vậy là xoá sạch — không có bản sao ở nơi khác.
- **Mang dữ liệu đi:** xuất CSV (mở bằng Excel) hoặc tạo `.ttbk` (khôi phục lại
  được).
- **Tắt AI:** xoá khoá API; app vẫn chạy đủ chức năng không cần AI.

*Delete everything by uninstalling or clearing app data — since the data is only
on your device, that is the whole of it. Take your data with CSV or `.ttbk`.
Remove your API key to turn AI off; the app works fully without it.*

## 9. Trẻ em

Tổng Tài dành cho người kinh doanh và **không hướng tới trẻ em dưới 13 tuổi**.
Chúng tôi không cố ý thu thập dữ liệu của trẻ em.

## 10. Thay đổi & liên hệ

Chính sách này thay đổi khi hành vi của app thay đổi — không thay đổi trước.
Ngày cập nhật ở đầu trang.

**Liên hệ:** [TBD — Founder cần cung cấp địa chỉ liên hệ trước khi phát hành lên
cửa hàng.]

---

## Ghi chú cho người bảo trì

- Bản trong app: `AppStrings.privacy*` → `TongtaiPrivacyPolicyScreen`.
- Danh mục sự kiện: `docs/05-OPERATIONS/TELEMETRY-EVENTS.md`. **Thêm một sự kiện
  telemetry ⇒ sửa §3 ở đây cùng PR.** Một chính sách nói ít hơn app làm là một
  lời khai sai, không phải một thiếu sót giấy tờ.
- `screen_view` và `flow_error` **có trong danh mục nhưng chưa nối** vào code
  (2026-07-31). §3 chỉ liệt kê thứ **đang chạy** — khi nối chúng vào, thêm dòng.
