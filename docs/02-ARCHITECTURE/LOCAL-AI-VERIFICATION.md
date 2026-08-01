# Local AI — kết quả kiểm chứng

*WTM-176 · 2026-08-01*

> ## ⚠️ Đọc phần này trước — khái niệm đã được Founder làm rõ
>
> Bản đầu của tài liệu này kết luận *"chế độ Local không chạy được"*. Kết luận
> đó **quá mạnh, vì tôi hiểu sai khái niệm**.
>
> **Founder Decision 2026-08-01:**
>
> > *"Local AI của Workizen là **LAN AI**, không phải **localhost AI**. Đối
> > tượng là Workizen Compute · Ollama trên PC · Mac · NAS · Raspberry Pi ·
> > server trong LAN. **Không phải Ollama chạy trên điện thoại.**"*
>
> Với khái niệm đúng đó:
>
> - Phần **chẩn đoán** dưới đây **vẫn đúng nguyên vẹn** — ba rào cản kỹ thuật
>   là thật và phải gỡ.
> - Phần **kết luận** thì **sai** — chúng chặn *cấu hình hiện tại*, không chặn
>   *ý tưởng*. Ba rào cản đều gỡ được mà **không cần backend, không cần Managed
>   AI**.
> - Lựa chọn **B (bỏ chế độ Local)** đã bị Founder **loại**. Không sửa
>   ADR-TON-006.
>
> **Việc tiếp theo:** nghiên cứu kiến trúc **LAN Endpoint Discovery** —
> `docs/08-RESEARCH/2026-08-01-lan-ai-endpoint-discovery/`.

---

## Chẩn đoán: vì sao cấu hình hôm nay không chạy


`ADR-TON-006` (ACCEPTED, Founder 2026-07-23):

> *"3 chế độ Managed/BYOK/Local — Phase 2 = **BYOK + Local**"*

`CLAUDE.md` nhắc lại:

> *"Phase 2 modes: BYOK (…) + **Local (Ollama)**; Managed waits for Phase 3."*

Nghĩa là: người dùng **không có khoá API** vẫn dùng được AI. Đó là lời hứa.

## Ba lý do nó không chạy được

### Lý do 1 — `baseUrl` trỏ vào chính chiếc điện thoại, và không sửa được

`lib/features/tongtai/ai/tongtai_ai_provider_kind.dart:38`

```dart
TongtaiAiProviderKind.ollama => 'http://localhost:11434/v1',
```

Trên điện thoại, **`localhost` là chính chiếc điện thoại đó**. Không có Ollama
nào chạy ở đấy — Ollama không có bản Android/iOS.

Và địa chỉ này **không sửa được**: `baseUrl` là một getter hằng trên enum.
`tongtai_ai_client.dart:79` dùng thẳng `provider.baseUrl`. Tìm toàn bộ `lib/`:
**không có** trường nhập URL, không có override, không có cấu hình.

⇒ Người dùng **không có cách nào** trỏ app sang máy tính của họ trong cùng mạng.

### Lý do 2 — Android chặn HTTP cleartext

- Manifest **không có** `android:usesCleartextTraffic`
- **Không có** `network_security_config.xml` (đã tìm toàn bộ `android/`)
- Manifest release đã build: **`targetSdkVersion="36"`**

Từ **API 28 (Android 9)**, cleartext HTTP **bị chặn mặc định**. `http://…`
(không phải `https`) sẽ ném lỗi mạng ngay, kể cả khi có Ollama đang chạy ở đầu
bên kia.

### Lý do 3 — iOS chặn, và cũng chưa xin quyền mạng nội bộ

`ios/Runner/Info.plist` **không có**:

- `NSAppTransportSecurity` ⇒ ATS chặn HTTP cleartext theo mặc định
- `NSLocalNetworkUsageDescription` ⇒ từ **iOS 14**, truy cập thiết bị trong
  mạng LAN cần quyền này, kèm hộp thoại xin phép

## Điều này có nghĩa gì cho người dùng

| Người dùng | Hôm nay họ gặp gì |
|---|---|
| Có khoá API (BYOK) | ✅ AI chạy bình thường |
| **Không có khoá**, chọn "Ollama (local)" | ❌ **Lỗi mạng.** Không có gì lắng nghe ở `localhost:11434` |
| Có Ollama trên máy tính cùng mạng | ❌ **Không trỏ tới được** — URL không sửa được |

⇒ **Với người dùng không có khoá API, sản phẩm hôm nay không có AI.** Không phải
"AI chậm" hay "AI hạn chế" — là **không có**.

Và đó là phần lớn chân dung người dùng mục tiêu: chủ SME Việt Nam sẽ không tự
tạo khoá xAI/Gemini.

## Ba rào cản đều gỡ được — không cần backend

Với khái niệm **LAN AI**, cả ba đều là hạng mục kỹ thuật nhỏ:

| Rào cản | Cách gỡ | Quy mô |
|---|---|---|
| `baseUrl` cố định | Trường nhập endpoint + lưu cấu hình; `baseUrl` thành **giá trị mặc định**, không phải hằng | nhỏ |
| Android chặn cleartext | `network_security_config.xml` cho phép cleartext **chỉ với endpoint người dùng khai** | nhỏ, cần cẩn thận |
| iOS chặn | `NSAllowsLocalNetworking` (đúng thiết kế cho ca này — **không** phải tắt ATS toàn cục) + `NSLocalNetworkUsageDescription` + `NSBonjourServices` nếu dùng mDNS | nhỏ |

**Không hạng mục nào cần backend, cần tài khoản, hay cần Managed AI.** D-4 và
D-5 không bị đụng: endpoint là **máy của chính người dùng**, không phải máy chủ
của Workizen.

## Hướng KHÔNG theo đuổi: chạy model trên điện thoại

Ghi lại để không ai quay lại hỏi. Cần plugin suy luận trên thiết bị (llama.cpp
qua FFI · MediaPipe LLM Inference · Gemini Nano/AICore) — **không có cái nào
trong `pubspec.yaml`**. Máy tham chiếu tầm thấp của dự án là Nokia 6.1; một
model 1B–3B lượng tử hoá cần ~1–2 GB RAM và chạy rất chậm ở đó. Gemini Nano
chỉ có trên vài dòng Pixel/Samsung cao cấp.

⚠️ Con số RAM/tốc độ ở đoạn trên là **suy luận từ cấu hình máy, không phải đo
đạc**. Nếu có ngày quay lại hướng này, phải đo trước khi hứa.

**Founder đã xác định rõ hướng này nằm ngoài phạm vi:** *"Không phải Ollama
chạy trên điện thoại."*

## Việc tiếp theo

Nghiên cứu kiến trúc **LAN Endpoint Discovery**:
`docs/08-RESEARCH/2026-08-01-lan-ai-endpoint-discovery/`

**Không sửa ADR-TON-006 cho tới khi nghiên cứu hoàn tất** (Founder Decision).
