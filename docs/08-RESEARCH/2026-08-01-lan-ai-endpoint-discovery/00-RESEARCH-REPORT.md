# LAN AI — Endpoint Discovery Architecture

*Nghiên cứu · WTM-176 · 2026-08-01*

> **Founder Decision 2026-08-01:**
>
> > *"Local AI của Workizen là **LAN AI**, không phải **localhost AI**. Đối
> > tượng là Workizen Compute · Ollama trên PC · Mac · NAS · Raspberry Pi ·
> > server trong LAN. Không phải Ollama chạy trên điện thoại.*
> > *Không cần backend. Không cần Managed AI. Không sửa ADR cho tới khi hoàn
> > thành nghiên cứu."*
>
> Tài liệu này là **nghiên cứu**, không phải ADR, không phải backlog.

---

## 1. Bài toán, phát biểu lại cho đúng

**Không phải:** *"làm sao chạy LLM trên điện thoại"* → Founder đã loại.

**Mà là:** *"điện thoại của người bán tìm và nói chuyện được với một endpoint
AI đặt trong mạng nội bộ của chính họ, mà không cần máy chủ nào của Workizen ở
giữa."*

Đây là bài toán **khám phá + tin cậy + kết nối**, không phải bài toán suy luận.

## 2. Bốn cách khám phá endpoint — và cái nào dùng được

### 2.1 Nhập tay (manual)

Người dùng gõ `http://192.168.1.10:11434`.

| | |
|---|---|
| ✅ | Luôn chạy. Không phụ thuộc nền tảng, không quyền, không thư viện |
| ✅ | **Bắt buộc phải có dù chọn hướng nào** — mọi cơ chế tự động đều cần đường lui |
| ❌ | Đòi người dùng biết IP nội bộ của máy mình |

**Kết luận: nền móng. Làm trước tiên, không tranh cãi.**

### 2.2 mDNS / DNS-SD (Bonjour)

Endpoint quảng bá `_ollama._tcp.local` (hoặc `_workizen-ai._tcp`), app lắng nghe.

| | |
|---|---|
| ✅ | Trải nghiệm tốt nhất: mở app, thấy *"Workizen Compute — phòng khách"* |
| ✅ | Đúng chuẩn, iOS/Android đều hỗ trợ ở tầng hệ điều hành |
| ⚠️ | **Ollama KHÔNG tự quảng bá mDNS.** Cần một lớp bọc (chính là chỗ **Workizen Compute** có lý do tồn tại) |
| ⚠️ | iOS cần `NSBonjourServices` khai **trước** từng service type, + `NSLocalNetworkUsageDescription` |
| ⚠️ | Android cần `NsdManager` (native) hoặc gói Dart; **nhiều router chặn multicast** hoặc bật *AP isolation* |
| ⚠️ | **Chưa có thư viện nào trong `pubspec.yaml`** — phụ thuộc mới |

**Kết luận: đúng hướng cho Workizen Compute, nhưng không dùng được cho một cài
đặt Ollama thuần cho tới khi có lớp bọc.**

### 2.3 Quét dải mạng (subnet scan)

Thử `http://192.168.1.{1..254}:11434/api/tags`.

| | |
|---|---|
| ✅ | Không cần endpoint hợp tác gì cả |
| ❌ | Chậm, tốn pin, và trên mạng lớn thì rất chậm |
| ❌ | **Rủi ro chính sách cửa hàng**: hành vi giống quét mạng. Google Play và Apple đều xét nét việc app dò thiết bị trong LAN |
| ❌ | iOS sẽ bật hộp thoại quyền mạng nội bộ ngay lần quét đầu — dễ làm người dùng sợ |

**Kết luận: KHÔNG nên làm.** Lợi ích nhỏ, rủi ro gỡ app lớn.

### 2.4 Ghép cặp bằng QR / mã ngắn

Workizen Compute (hoặc một script) hiện QR chứa `{endpoint, model, token}`;
người bán quét bằng app.

| | |
|---|---|
| ✅ | **Trải nghiệm tốt nhất cho người không rành kỹ thuật** — không cần biết IP là gì |
| ✅ | Không cần multicast ⇒ **không bị router chặn** |
| ✅ | Mang theo được **token xác thực** (xem §4) |
| ✅ | Không có hành vi dò mạng ⇒ không rủi ro chính sách |
| ⚠️ | Cần thư viện quét QR (phụ thuộc mới) và cần phía Compute hiện QR |

**Kết luận: ứng viên mạnh nhất cho trải nghiệm, đặc biệt khi Workizen Compute
là thứ ta kiểm soát được cả hai đầu.**

### Bảng chọn

| | Nhập tay | mDNS | Quét dải | QR |
|---|---|---|---|---|
| Chạy được ngay hôm nay | ✅ | ❌ | ⚠️ | ❌ |
| Cần phụ thuộc mới | ❌ | ✅ | ❌ | ✅ |
| Cần endpoint hợp tác | ❌ | ✅ | ❌ | ✅ |
| Router chặn được không | ❌ | ⚠️ **có** | ❌ | ❌ |
| Rủi ro chính sách store | ❌ | ⚠️ nhẹ | 🔴 **cao** | ❌ |
| Dễ cho người không rành | ❌ | ✅ | ✅ | ✅ |

## 3. Ràng buộc nền tảng — kiểm trong repo, không suy đoán

### Android

- Manifest hiện có **duy nhất** `INTERNET`. **Không có** `ACCESS_NETWORK_STATE`,
  **không có** `CHANGE_WIFI_MULTICAST_STATE` (mDNS cần cái sau).
- **Không có** `network_security_config.xml`; `targetSdkVersion="36"` ⇒
  cleartext HTTP **bị chặn**.

⚠️ **Điểm phải nghiên cứu kỹ, đây là chỗ dễ sai nhất:** Android network security
config nhận **tên miền**, không nhận **dải CIDR**. Không có cách khai *"cho phép
cleartext với mọi IP 192.168.x.x"*. Ba lối đi, phải thử tay trước khi chọn:

1. `cleartextTrafficPermitted="true"` **toàn cục** — đơn giản nhưng **nới hàng
   rào bảo mật cho mọi kết nối**. Tôi không khuyến nghị.
2. Khai từng **IP literal** người dùng nhập → cần sinh config động, mà config
   này là **tài nguyên biên dịch tĩnh**. Có thể không khả thi.
3. **Cho endpoint dùng HTTPS** với chứng chỉ do Workizen Compute tự cấp + trust
   anchor riêng của app. Sạch nhất về bảo mật, **nặng nhất về triển khai**, và
   chỉ áp dụng được cho Workizen Compute chứ không cho Ollama thuần.

#### Đã phân tích thêm — và câu trả lời nghiêng về lối 1, vì một lý do cụ thể

Tôi liệt kê **mọi URL trong `lib/`** để xem mở cleartext toàn cục thì thực sự
nới lỏng cái gì:

```
https://api.x.ai/v1                                    https://console.x.ai
https://generativelanguage.googleapis.com/v1beta/openai https://aistudio.google.com/apikey
https://openrouter.ai/api/v1                           https://openrouter.ai/keys
https://api.cerebras.ai/v1                             https://cloud.cerebras.ai
https://api.openai.com/v1                              https://platform.openai.com/api-keys
http://localhost:11434/v1   ← chỉ MỘT, chính là Ollama  https://ollama.com/download
```

**Toàn bộ URL còn lại là hằng `https://` biên dịch cứng trong code.** App không
nhận URL từ máy chủ, không xây URL từ dữ liệu, không có deep link nào mở URL
tuỳ ý.

⇒ Bật `cleartextTrafficPermitted` toàn cục **không mở thêm bề mặt tấn công thực
tế nào**, vì không có đường nào để một URL `http://` khác lọt vào app. Rào cản
này bảo vệ chống *lập trình viên vô ý dùng HTTP*, và ở đây điều đó được khoá
bằng **hằng số + test**, không cần khoá bằng cấu hình mạng.

**Đề xuất:** `network_security_config.xml` với `base-config
cleartextTrafficPermitted="true"` + **một test governance** khẳng định
`TongtaiAiProviderKind.baseUrl` chỉ có **đúng một** giá trị `http://` và nó là
endpoint LAN. Test đó thay thế đúng thứ mà cấu hình mạng đang bảo vệ.

⚠️ **Vẫn phải thử trên máy Android thật** trước khi coi là xong. Phân tích trên
giải thích *vì sao chấp nhận được*, không chứng minh *nó chạy*.

### iOS

- `Info.plist` **không có** `NSAppTransportSecurity`, `NSLocalNetworkUsageDescription`,
  `NSBonjourServices`.
- Tin tốt: **`NSAllowsLocalNetworking`** được Apple thiết kế **đúng cho ca này**
  — cho phép cleartext tới địa chỉ mạng nội bộ **mà không tắt ATS toàn cục**.
  Đây là đường sạch, và iOS ở tình thế tốt hơn Android.

### Code

`tongtai_ai_client.dart:79` dùng thẳng `provider.baseUrl`, và `baseUrl` là
getter hằng trên enum. Muốn có endpoint tuỳ chỉnh thì phải **tách địa chỉ ra
khỏi enum** — nhưng chỉ ở mức *"enum cho giá trị mặc định, cấu hình có thể ghi
đè"*. Không phá kiến trúc.

## 4. Bảo mật — phần tôi lo nhất, và nó không nhỏ

Một endpoint Ollama trong LAN **không có xác thực**. Hệ quả:

| Rủi ro | Nói cụ thể |
|---|---|
| **Wi-Fi công cộng** | Người bán ngồi quán cà phê, app "khám phá" ra một endpoint lạ và **gửi bối cảnh kinh doanh** tới máy của người khác |
| **Endpoint giả mạo** | Ai đó trong mạng dựng một endpoint trả lời sai lệch có chủ đích |
| **Không có TLS** | Bối cảnh kinh doanh đi qua LAN dưới dạng **plaintext** |

**Ba quy tắc tôi đề nghị đặt ra ngay từ đầu, trước khi viết dòng code nào:**

1. **Không bao giờ tự động dùng một endpoint được khám phá.** Khám phá chỉ *gợi
   ý*; người dùng phải **xác nhận một lần** cho mỗi endpoint.
2. **Ghim endpoint theo mạng.** Endpoint đã tin ở mạng nhà **không** tự dùng lại
   khi đang ở mạng khác.
3. **Nói rõ điều gì rời khỏi máy.** Đúng như đã làm với màn phản hồi hôm nay:
   người dùng phải thấy trước.

> Đây chính là chỗ **Workizen Compute có giá trị thật** so với Ollama thuần: nó
> có thể mang **token ghép cặp** và **TLS**, trong khi Ollama trần thì không.

## 5. Ba kiến trúc đề xuất

### Phương án 1 — "Nhập tay trước" (nhỏ nhất chạy được)

```
Người dùng gõ endpoint → app kiểm tra /api/tags → lưu + ghim theo mạng → dùng
```

- Cần: trường nhập + cấu hình endpoint · Android cleartext (§3, chưa giải
  quyết) · iOS `NSAllowsLocalNetworking`
- **Không** phụ thuộc mới. **Không** quyền mới trên Android.
- Phục vụ: người dùng kỹ thuật, Workizen Compute, mọi thứ trong danh sách của
  Founder — miễn là họ biết IP.

### Phương án 2 — "Nhập tay + QR"

Phương án 1, cộng thêm: Workizen Compute hiện QR `{endpoint, model, token}`,
app quét.

- Cần thêm: thư viện quét QR (phụ thuộc mới) + phía Compute hiện QR
- Phục vụ: **người không rành kỹ thuật**, không cần biết IP là gì
- **Không** bị router chặn, **không** rủi ro chính sách store

### Phương án 3 — "Nhập tay + QR + mDNS"

Cộng thêm khám phá tự động cho các endpoint có quảng bá.

- Cần thêm: thư viện mDNS · `CHANGE_WIFI_MULTICAST_STATE` (Android) ·
  `NSBonjourServices` (iOS) · **Workizen Compute phải quảng bá**
- Đẹp nhất, và **dễ vỡ nhất** — nhiều router chặn multicast

### So sánh

| | P1 nhập tay | P2 + QR | P3 + mDNS |
|---|---|---|---|
| Phụ thuộc mới | 0 | 1 | 2 |
| Quyền mới (Android) | 0 | camera | camera + multicast |
| Cần Compute hợp tác | ❌ | ✅ | ✅ |
| Dùng được cho Ollama thuần | ✅ | ⚠️ | ❌ |
| Người không rành dùng được | ❌ | ✅ | ✅ |
| Rủi ro vỡ do router | ❌ | ❌ | ⚠️ **có** |

## 6. Đề xuất

**Đi P1 → P2, và coi P3 là tuỳ chọn về sau.**

Lý do:

1. **P1 mở khoá toàn bộ danh sách của Founder** — PC, Mac, NAS, Raspberry Pi,
   server LAN, Workizen Compute — chỉ cần người dùng biết IP. Nó là **nền móng
   bắt buộc** của cả P2 lẫn P3, nên làm nó không bao giờ là công phí.
2. **P2 là bước biến nó thành thứ người bán bình thường dùng được**, và nó ăn
   khớp tự nhiên với Workizen Compute — thứ ta kiểm soát cả hai đầu.
3. **P3 đẹp nhưng dễ vỡ** vì router, và chỉ thêm tiện lợi chứ không thêm năng
   lực nào mới.

**Nhưng có một chốt chặn phải gỡ trước khi hứa bất cứ điều gì:**

> ⚠️ **Cleartext HTTP trên Android: đã có đường đi, chưa có bằng chứng chạy.**
> §3 giải thích vì sao `cleartextTrafficPermitted` toàn cục chấp nhận được với
> **app cụ thể này** (mọi URL khác là hằng `https://` biên dịch cứng), kèm một
> test governance thay thế đúng thứ cấu hình mạng đang bảo vệ.
>
> Nhưng đó là **lập luận**, không phải **bằng chứng**. Việc đầu tiên của story
> đầu tiên phải là: dựng Ollama trên một máy trong LAN, gọi từ một Android
> thật, và **xem nó chạy**. Không ước lượng gì trước khi có bước đó.

## 7. Cái tôi chưa làm và không giả vờ đã làm

- **Chưa thử cleartext trên máy Android thật.** Toàn bộ §3 dựa trên đọc code +
  manifest đã build, chưa dựng thử.
- **Chưa thử Ollama trên LAN.** Không có máy Ollama nào trong tầm tay phiên này.
- **Chưa khảo sát thư viện mDNS/QR cho Flutter** — chưa đánh giá cái nào còn
  được bảo trì.
- **Workizen Compute:** tôi chỉ biết cái tên từ chỉ thị của Founder. Không tìm
  thấy nó trong repo nào của workspace. Mọi câu ở trên về nó là **giả định dựa
  trên tên gọi**, không phải sự thật đã kiểm.

**Cần Founder xác nhận Workizen Compute là gì** trước khi P2/P3 được coi là
khả thi — cả hai đều giả định nó hợp tác được.
