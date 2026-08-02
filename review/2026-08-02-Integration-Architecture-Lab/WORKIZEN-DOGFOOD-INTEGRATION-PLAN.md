# Wave 1 — 10 nền tảng Workizen dùng thật: kết nối bằng cách nào

> **WTM-241 · Wave 1 của Epic WTM-238.** Không code, không dependency, không
> connector. Mỗi nền tảng phải kết luận **đúng một** mô hình theo Founder
> Decision 2026-08-02: `Device-direct` · `App-to-App` · `File Bridge` · `MCP` ·
> `Optional Integration Runtime` · `Hybrid`.

**Thứ tự ưu tiên Founder đặt:** Device-direct (nếu an toàn và khả thi) →
App-to-App → File Bridge → MCP (nếu thực sự phù hợp) → Optional Integration
Runtime (khi API/OAuth/webhook bắt buộc).

**Luật credential (Founder chốt):** không lưu token trong SQLite nghiệp vụ ·
không đưa credential vào `.ttbk` · mobile dùng Keychain/Keystore · backend dùng
secret vault · DB chỉ giữ **credential reference + connection metadata**.

**Độ tin cậy:** ✅ = đã tra tài liệu/nguồn hiện hành trong phiên này ·
🔶 = dựa trên hiểu biết về nền tảng, **phải xác minh lại trong story spike**.

---

## ⭐ Phát hiện quan trọng nhất của Wave 1

**Chỉ 1 trong 10 nền tảng thật sự bắt buộc Optional Integration Runtime.**

| Mô hình | Số nền tảng |
|---|---|
| Device-direct | **6** |
| Hybrid (File Bridge trước, device-direct sau) | 2 |
| App-to-App | 1 |
| **Optional Integration Runtime (bắt buộc)** | **1** — RevenueCat |
| MCP | **0** |

Nghĩa là **lời hứa local-first sống sót gần như nguyên vẹn** qua Wave 1. Backend
không phải điều kiện để Tổng Tài có dữ liệu ngoài — nó chỉ cần cho đúng một
loại nhu cầu: **bí mật không được đặt trong app** và **webhook realtime**.

Và một cảnh báo chi phí phải báo Founder ngay: **Gmail API là thứ đắt nhất
trong danh sách** — không phải vì kỹ thuật, mà vì kiểm định bảo mật hằng năm.

---

## Một phân biệt quyết định mọi con số chi phí bên dưới

Google (và phần nào Apple) tính chi phí **theo phạm vi phát hành**, không theo
kỹ thuật:

| | Dogfood (chỉ tài khoản của Founder) | Sản phẩm (phát cho SME) |
|---|---|---|
| Google OAuth | chế độ **Testing**, không cần thẩm định | scope *sensitive* ⇒ **OAuth verification** · scope *restricted* (Gmail) ⇒ **CASA hằng năm** ✅ |
| Chi phí | ~0 | vài trăm → vài nghìn USD **mỗi năm**, chưa kể thời gian |

⇒ **Làm connector cho Workizen dùng thật thì rẻ. Bán nó cho người dùng thì
không.** Mọi khuyến nghị dưới đây tách rõ hai cột đó.

---

## Bảng kết luận

| # | Nền tảng | Xác thực | Mô hình kết luận | Vì sao |
|---|---|---|---|---|
| 1 | **App Store Connect** | JWT ES256 ký bằng khoá `.p8`, token sống ≤20 phút ✅ | **Hybrid** | Báo cáo doanh thu tải được qua `/v1/salesReports` (TSV nén) ✅; nhưng `.p8` là khoá cấp tài khoản, Apple **chỉ hiện một lần**. File Bridge trước, device-direct sau với khoá chỉ quyền *Sales and Reports* ✅ |
| 2 | **Google Play Console** | OAuth2 / service account; báo cáo tiền nằm trong **GCS bucket riêng**, CSV theo tháng ✅ | **File Bridge** (dogfood) → Optional Runtime nếu cần tự động | Đặt JSON service account lên máy là đặt một credential Google Cloud vào tay app. Bucket export rẻ và đủ cho nhịp hằng tháng |
| 3 | **RevenueCat** | API v2 **bắt buộc secret key `sk_`**, tài liệu nói rõ *chỉ để trên server* ✅ | **⚠️ Optional Integration Runtime** | Đây là nền tảng **duy nhất** trong 10 cái mà device-direct đi ngược khuyến cáo chính hãng. Webhook cũng cần địa chỉ nhận ✅ |
| 4 | **GitHub** | OAuth **device flow** (không cần client secret) hoặc fine-grained PAT 🔶 | **Device-direct** | Device flow sinh ra đúng cho thiết bị không giữ được bí mật. Nhịp đọc release/issue không cần webhook |
| 5 | **Gmail** | OAuth2 restricted scope ⇒ **CASA hằng năm**, lab $500–$4.500+, phải tái thẩm định mỗi 12 tháng ✅ | **App-to-App (Share Sheet)** | Xem §Gmail — từ chối Gmail API cho sản phẩm là quyết định **kinh tế và định vị**, không phải kỹ thuật |
| 6 | **Google Analytics (GA4)** | OAuth2 scope *sensitive* (`analytics.readonly`), PKCE cho app cài đặt ✅ | **Device-direct** | Dogfood: chế độ Testing, không tốn gì. Sản phẩm: cần verification (thời gian, không phải CASA) |
| 7 | **Search Console** | như trên (`webmasters.readonly`) ✅ | **Device-direct** | Cùng hình dạng GA4 |
| 8 | **Website / WooCommerce / Shopify** | Woo: consumer key/secret do chủ site tự sinh 🔶 · Shopify custom app: Admin API token 🔶 | **Device-direct** | Đều là *"chủ tiệm tự cấp khoá cho chính mình"*. Chỉ Shopify **public app** mới cần OAuth callback ⇒ Optional Runtime |
| 9 | **Gumroad** | OAuth2 access token, API v2 còn sống; có **ping webhook** trên mỗi lượt bán ✅ | **Device-direct** (+ Runtime nếu cần realtime) | Đọc doanh số bằng token cá nhân là đủ; ping chỉ cần khi muốn biết **ngay lúc** có đơn |
| 10 | **Telegram** | Bot token; `getUpdates` **long-polling không cần địa chỉ công khai** 🔶 | **Device-direct** | Không cần webhook ⇒ không cần server. Đây là kênh thông báo rẻ nhất cho SME Việt Nam |

**MCP: 0/10.** Không nền tảng nào trong danh sách có MCP chính thức đủ chín để
thay API thường — và Founder đã cấm dùng MCP chỉ để thay một API bình thường.
Đánh giá lại ở Wave 2/4 nếu nền tảng công bố MCP.

---

## Gmail — vì sao từ chối API, và từ chối cái gì

Đây là mục duy nhất tôi khuyến nghị **không dùng API chính thức**, nên phải nói
rõ lý do.

`gmail.readonly` (và cả `gmail.metadata`) là **restricted scope**. Hệ quả đã tra
được ✅:

* bắt buộc qua **CASA** — kiểm định bảo mật do lab Google chỉ định;
* chi phí lab **$500–$4.500**, có ca lên $5.000–$75.000 tuỳ kiến trúc;
* **tái thẩm định mỗi 12 tháng**, không phải một lần;
* thẩm định soi **toàn bộ ứng dụng**, không riêng phần Gmail.

Ba lý do từ chối, xếp theo mức nặng:

1. **Định vị.** Trang quyền riêng tư của Tổng Tài nói dữ liệu ở lại trên máy.
   Xin quyền đọc **toàn bộ hộp thư** của người bán là thứ khó giải thích nhất
   có thể xin, và nó phá đúng thứ sản phẩm đang bán.
2. **Chi phí định kỳ** cho một app **chưa có doanh thu**, mỗi năm, không giảm.
3. **Không cần thiết.** Việc thật cần làm — *"email hỗ trợ này biến thành một
   việc trong hành trình"* — làm được bằng **Share Sheet**: người bán bấm chia
   sẻ email sang Tổng Tài. Một chạm, không quyền, không thẩm định, không token.

**Được phép dùng Gmail API ở đâu:** dogfood cá nhân của Founder trong chế độ
Testing (không cần thẩm định ✅). Nếu sau này có bằng chứng người dùng thật cần
đọc hộp thư tự động, mở lại bằng một ADR riêng.

---

## RevenueCat — nền tảng đầu tiên thật sự cần Optional Integration Runtime

API v2 **bắt buộc** `sk_` secret key và tài liệu chính hãng nói thẳng: *giữ trên
server của bạn, đừng để trong client-side code* ✅. Webhook (đổi gói, huỷ, hoàn
tiền) cần một địa chỉ HTTPS nhận ✅.

Hai đường, cả hai đều hợp lệ theo doctrine mới:

| | Cách làm | Đánh đổi |
|---|---|---|
| **A. Runtime tối thiểu** (khuyến nghị) | Một endpoint nhận webhook + giữ `sk_` trong secret vault, đẩy **sự kiện đã chuẩn hoá** về máy | Đúng định nghĩa **Optional Integration Runtime** của Founder: chỉ phục vụ connector người dùng chủ động bật, chỉ giữ credential + trạng thái sync tối thiểu, **không** lưu dữ liệu doanh nghiệp |
| **B. Device-direct chấp nhận rủi ro** | `sk_` nằm trong Keystore, app tự gọi | Đi ngược khuyến cáo chính hãng. Chỉ chấp nhận cho **dogfood một người**, tuyệt đối không cho sản phẩm |

Cả doanh thu subscription của Workizen đều đi qua đây, nên đây cũng là connector
**giá trị cao nhất** trong Wave 1 — và là lý do cụ thể để Founder cân nhắc dựng
Runtime, chứ không phải vì "hệ thống nào cũng cần backend".

---

## App Store Connect / Play Console — vì sao File Bridge trước

Cả hai đều **có** API thật, nhưng credential của cả hai đều là **khoá cấp tài
khoản**:

* Apple: `.p8` ký JWT ES256, **chỉ tải được một lần**, mất là phải thu hồi ✅.
  Có thể hạn chế bằng vai trò *Sales and Reports* ✅ — đây là điều làm
  device-direct **khả thi ở giai đoạn sau**.
* Google: service account JSON mở đường vào Google Cloud của Founder ✅.

Trong khi đó **báo cáo doanh thu của cả hai đều xuất ra file**: Apple TSV nén
qua `/v1/salesReports` ✅, Google CSV theo tháng trong GCS bucket ✅. Nhịp dữ
liệu là **hằng ngày/hằng tháng**, không phải realtime.

⇒ File Bridge cho đúng thứ người bán cần, với **không** một bí mật nào rời chỗ.
Đúng thứ tự ưu tiên Founder đặt: chọn cách rẻ và an toàn trước, leo thang chỉ
khi việc thật đòi.

⚠️ Lưu ý vận hành đã tra được: **từ tháng 7/2026 Google đổi cột "Fee
Description" và "Program"** trong báo cáo earnings ✅ — bất kỳ parser nào khớp
chuỗi chính xác sẽ vỡ. Đây là bằng chứng cụ thể cho luật *"file hỏng/sai định
dạng là lỗi có tên, không phải crash"* (ADR-TON-017).

---

## Điều Wave 1 KHÔNG kết luận

Không chọn connector nào để làm trước — đó là Connector Priority Roadmap, chấm
theo 12 tiêu chí của mục IX, làm sau khi W1-2 (khoảng trống canonical) và W1-3
(action model) xong. Không thiết kế schema. Không thêm dependency.

---

## Nguồn đã tra trong phiên này

- [Restricted scope verification — Google](https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification)
- [Sensitive scope verification — Google](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification)
- [Google CASA — chi phí kiểm định](https://deepstrike.io/blog/google-casa-security-assessment-2025)
- [App Store Connect API — get started](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/)
- [Play Console — download and export monthly reports](https://support.google.com/googleplay/android-developer/answer/6135870?hl=en)
- [Play Developer Reporting API](https://developers.google.com/play/developer/reporting)
- [RevenueCat API v2](https://www.revenuecat.com/docs/api-v2) · [API keys & authentication](https://www.revenuecat.com/docs/projects/authentication) · [Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [Gumroad API overview](https://gumroad.com/api)
