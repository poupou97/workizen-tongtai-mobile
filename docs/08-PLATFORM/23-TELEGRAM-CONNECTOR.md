# 23 · Telegram Connector — Tổng Tài nhắn cho chính chủ shop

> **WTM-318 · C2 · Epic WTM-315** — Connector Implementation & Dogfood
> Trạng thái: **chạy được ngay.** Không chờ ai duyệt gì. Xem §5.

---

## 1. ⭐ Sự thật quyết định mọi thứ còn lại

**Bot Telegram không nhắn trước được cho ai cả.** Người ta phải mở chat với bot
và bấm `/start` thì bot mới có `chat_id` để trả lời.

Đây không phải hạn chế tạm thời — đó là thiết kế chống spam của Telegram, và nó
quyết định **Telegram dùng được vào việc gì**:

| Việc | Được không |
|---|---|
| Tổng Tài nhắn cho **chủ shop** | ✅ chủ shop tự bấm `/start` một lần |
| Tổng Tài nhắn cho **khách đã chat với bot** | ✅ |
| Tổng Tài nhắn cho một khách bất kỳ trong danh bạ | ❌ **không bao giờ** |

Nên hàng *"gửi tin nhắn chăm sóc khách"* (`customerSendMessage`) **vẫn ở diễn
tập** sau story này, và điều đó không phải thiếu sót — đó là sự thật của kênh.
Nó chỉ chạy thật khi có một kênh nhắn trước được: Zalo OA, SMS, hoặc email.

Viết ra ở đây vì nếu không, ai đó sẽ dựng xong đường gửi khách rồi mới phát
hiện — vào đúng ngày demo.

---

## 2. Vậy Telegram làm được việc gì đáng làm

**Bản tin sáng đi từ Tổng Tài tới người bán.**

Và đó không phải giải thưởng an ủi. Nó là thứ biến app từ *"mở ra thì thấy"*
thành *"nó tìm mình"* — đúng câu Founder viết ở Epic WTM-302: *"Tổng Tài đang
quan sát doanh nghiệp… và làm việc cùng tôi."*

Một trợ lý chỉ nói khi được mở ra không phải trợ lý; đó là một cái báo cáo.

`BusinessActionType.ownerNotify` · `ActionVendor.telegram` · `ActionRisk.low`
(thấp vì nó nhắn cho **người đã chủ động bật nó lên** — khác
`customerSendMessage` là `medium` vì chạm tới người thứ ba).

---

## 3. Ba bước thiết lập, và bước thứ hai mới là bước khó

```
1. Dán bot token          ← BotFather đưa sẵn, dễ
2. Biết gửi cho ai        ← chỗ mọi hướng dẫn trên mạng bảo người dùng tự mò
3. Gửi tin thử            ← nhìn thấy nó tới, không phải tin lời app
```

Bước 2 là chỗ các hướng dẫn khác bảo người dùng *"mở
`api.telegram.org/bot<token>/getUpdates` trên trình duyệt rồi tự tìm con số"*.
Ở đây máy làm việc đó: người bán bấm `/start` trong Telegram, bấm **Tìm cuộc
trò chuyện**, rồi chọn theo **tên**.

Một con số người dùng phải tự chép là một con số sẽ bị chép sai.

⚠️ Telegram chỉ giữ update **24 giờ**. Bấm `/start` hôm qua rồi hôm nay mới tìm
thì danh sách rỗng — và rỗng ở đây nghĩa là *"chưa thấy ai nhắn"*, không phải
*"hỏng"*. Màn hình nói đúng câu đó.

---

## 4. "Không fake connected" ở đây là CƠ CHẾ, không phải lời hứa

| Bước | Trạng thái sau bước đó | Vì sao |
|---|---|---|
| chưa gì | `SETUP_REQUIRED` | |
| dán token **sai** | `SETUP_REQUIRED`, **không lưu gì cả** | `getMe` hỏng ⇒ không có gì đáng lưu. Lưu một token sai rồi đánh dấu `error` để lại một bí mật vô dụng trong Keystore |
| dán token **đúng** | vẫn `SETUP_REQUIRED` | biết token thật mà chưa biết gửi cho ai thì chưa gửi được gì. Nói "đã kết nối" lúc này là nói một nửa sự thật, và nửa còn lại hiện ra dưới dạng một tin nhắn không bao giờ tới |
| chọn nơi nhận | `ACTIVE` | giờ mới thật sự gửi được |

Nút **Gửi tin thử** chỉ hiện khi đã `ACTIVE`. Mời người bán bấm vào một thứ
chắc chắn hỏng là cách nhanh nhất dạy họ rằng nút của app không đáng tin.

---

## 5. Founder cần làm gì (≈2 phút, không cần console nào)

1. Mở Telegram, tìm **@BotFather**
2. `/newbot` → đặt tên → BotFather đưa một chuỗi dạng `123456:ABC-DEF...`
3. Trong Tổng Tài: **Kết nối** → *Nhận bản tin qua Telegram* → dán token → **Lưu token**
4. Trong Telegram, nhắn `/start` cho bot vừa tạo
5. Quay lại app → **Tìm cuộc trò chuyện** → chọn tên mình
6. **Gửi tin thử** → mở Telegram xem

Khác Google Drive ở đúng chỗ này: **không** OAuth, **không** client ID,
**không** SHA-1, **không** xét duyệt, **không** Play App Signing. Đó là lý do
Telegram là connector thật chạy được **sớm nhất** trong cả danh sách, dù nó
không phải cái đứng đầu thứ tự ưu tiên.

---

## 6. Bản tin sáng: một ngày một lần, năm việc

| Luật | Vì sao |
|---|---|
| khoá chống lặp gộp theo **ngày** | một vòng lặp lỗi gộp theo phút sẽ bắn hàng chục tin, người bán chặn bot, mất luôn kênh |
| **không có việc nào ⇒ không nhắn** | trợ lý nhắn mỗi sáng để nói "không có gì" sẽ bị tắt thông báo trong tuần đầu — và lúc đó tin **thật sự** quan trọng chết theo |
| chưa nối Telegram ⇒ **không dựng hành động** | người bán chưa bật thông báo thì không có gì để ghi là "đã thử và hỏng" |
| cắt ở **năm** việc nặng nhất + "còn N việc nữa" | Rule Twin có thể tìm ra ba mươi việc trong một buổi sáng dữ liệu xấu; tin ba mươi dòng không được đọc, nó được vuốt qua |
| không mã, không tên bảng, không id | người bán đọc lúc 7 giờ sáng giữa lúc mở cửa hàng (cùng luật màn Hoạt động, WTM-305) |

---

## 7. Những chỗ dễ sai, đã khoá bằng test

| Cái bẫy | Hậu quả nếu sập | Test giữ |
|---|---|---|
| Telegram trả **200 kèm `ok:false`** | chỉ nhìn mã HTTP ⇒ báo "đã gửi" cho một tin không bao giờ tới | *"lỗi 200 + ok:false vẫn là LỖI"* |
| Đọc `403` thành "token hỏng" | bắt người bán tạo lại bot trong khi vấn đề là họ chưa `/start` | *"403 = bị chặn / chưa /start, KHÁC token hỏng"* |
| Lưu token lần hai xoá mất nơi nhận | đổi bot xong thì bản tin im lặng, không ai biết vì sao | *"lưu token lần hai KHÔNG xoá mất nơi nhận đã chọn"* |
| Token sai vẫn ghi vào Keystore | một bí mật vô dụng nằm lại, không màn nào xoá | *"token sai ⇒ KHÔNG lưu gì cả"* |
| Nhiều tin của một người thành nhiều "cuộc trò chuyện" | danh sách chọn đầy trùng lặp | *"gộp nhiều tin của cùng một người thành MỘT"* |
| `demo:` lẫn vào việc thật | không phân biệt được diễn tập và thật | *"externalId là telegram:, không phải demo:"* |

⚠️ **Token nằm trong URL, không nằm trong body** (Telegram đặt nó trong đường
dẫn). Điều đó quyết định chỗ token có thể rò: **một log ghi lại URL là một log
ghi lại bí mật.** Có test chốt điều này để nó không bị quên khi ai đó thêm
logging.

---

## 8. Bản đồ file

| File | Việc |
|---|---|
| `connection/telegram/telegram_client.dart` | Bot API: `getMe` · `sendMessage` · `getUpdates`; dịch `ok:false` thành lý do phân biệt được |
| `connection/telegram/telegram_connection.dart` | vòng đời: token → nơi nhận → `ACTIVE`; phân loại lỗi ở đây để `ui/` không catch (ADR-TON-017) |
| `connection/telegram/owner_notifier.dart` | bản tin sáng + tin thử qua cửa ghi duy nhất; `composeMorningBrief` |
| `ui/screens/tongtai_connections_screen.dart` | ba bước hiện **cùng lúc**, không phải wizard ba màn |
