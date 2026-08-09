# 22 · Google Drive Connector — sao lưu `.ttbk` lên Drive

> **WTM-317 · C1 · Epic WTM-315** — Connector Implementation & Dogfood
> Trạng thái: **code xong, chờ một khoá từ Founder.** Xem §5.

---

## 1. Việc này giải quyết cái gì

Trước WTM-317, bản sao lưu `.ttbk` chỉ đi ra qua **share sheet** — người bán
phải tự chọn gửi đi đâu, và tự nhớ mình để nó ở đâu. Đó không phải sao lưu, đó
là xuất file.

Từ WTM-317, sao lưu là **một việc có nơi chốn**: bấm một nút, file nằm trong
Drive của chính người bán, và app đọc lại được danh sách để khôi phục.

Sáu bước (Founder Task Order §6), đủ cả sáu:

```
Export → Upload → List/Locate → Download → Preview → Restore
```

`Export` và `Restore` đã có từ WTM-164 (`.ttbk` v2, ADR-TON-018) và **không đổi
một dòng**. Drive chỉ thêm chỗ *cất* và chỗ *lấy về*.

---

## 2. Quyền: `drive.file`, không phải `drive`

| | `drive.file` (đang dùng) | `drive` (KHÔNG dùng) |
|---|---|---|
| Thấy được gì | **chỉ file do chính app tạo** | toàn bộ Drive của người dùng |
| Google xếp loại | không restricted | **restricted** |
| Điều kiện phát hành | không cần đánh giá bảo mật bên thứ ba | cần, hằng năm, tốn tiền |

Activepieces xin `auth/drive` (`google-drive/src/lib/auth.ts:5`, WTM-309) vì nó
là automation đa năng phải đọc file người dùng đã có. Tổng Tài chỉ cất một file
của chính mình, nên không có lý do gì xin rộng hơn.

**Hệ quả phải biết, và nó là đánh đổi có chủ ý:** app **không** thấy được bản
`.ttbk` mà người bán tự tải lên Drive từ máy khác. Muốn khôi phục bản đó thì
dùng đường "chọn file" đã có sẵn ở màn Sao lưu & khôi phục.

Khoá bằng test: `connection_layer_test.dart` → *"drive.file không phải
restricted scope `auth/drive`"*. Ai đó "sửa cho tiện" sẽ đỏ ở đây, chứ không đỏ
ở Google sáu tuần sau.

---

## 3. Bí mật nằm ở đâu — và **không** nằm ở đâu

```
Keychain / Keystore          SQLite nghiệp vụ            .ttbk
─────────────────────        ─────────────────────       ──────────────
access_token          ✅      connection id        ✅      connection id  ✅
refresh_token         ✅      connector id         ✅      connector id   ✅
expires_at            ✅      label, status        ✅      label, status  ✅
                             token                ❌      token          ❌
                             khoá tra credential  ❌      khoá tra       ❌
```

Khoá tra credential **suy ra** từ `connection.id`
(`CredentialReference.forConnection`), không có constructor nhận chuỗi. Nên
không có đường nào để một token lọt vào kiểu đó — kể cả do nhầm — và cũng không
có cột nào để nó lọt vào `.ttbk`.

Khoá bằng governance: `credential_boundary_governance_test.dart` quét **toàn bộ
mọi bảng** tìm chuỗi bí mật, kèm một test tự kiểm chứng rằng phép quét thật sự
bắt được (cố tình ghi token vào một cột rồi khẳng định nó kêu).

---

## 4. Sao lưu đi qua `BusinessAction` — vì sao

`BusinessActionType.storageBackupUpload`, `ActionVendor.google`,
`ActionRisk.low`.

Ba thứ mua được, cả ba là thứ một lời gọi `drive.upload()` trần không có:

1. **Chống lặp** — khoá gộp theo **phút**. Bấm hai lần liền nhau là một tai nạn
   ngón tay, không phải hai ý định. (Tên file cũng chính xác tới phút; hai độ
   phân giải khác nhau sẽ tạo ra "cùng khoá, khác payload" và bị executor từ
   chối — đúng, nhưng vô ích.)
2. **Nhìn thấy được** — bản sao lưu hiện ở màn Hoạt động cạnh mọi việc khác.
3. **Đường chạy thật** — `plan → approve → run` là đường đã chạy hàng nghìn lần
   trong test từ WTM-297. Đây là hành động **đầu tiên** đi hết đường đó ra tới
   một nền tảng thật, và `externalId` của nó là `drive:<fileId>` — **không**
   mang tiền tố `demo:`. Mở Drive ra sẽ thấy đúng file đó.

Dự đoán viết trong WTM-303 — *"ngày Telegram thật xuất hiện, thứ thay đổi là
**một handler**"* — đã được kiểm chứng: thứ phải đổi đúng là một dòng trong
`tongtaiActionHandlersProvider`.

**Một cái giá phải biết:** effect chạy **bên trong transaction** của executor,
nên `.ttbk` được dựng và đẩy đi trong khi không ghi nào khác chen vào. Các ghi
khác phải chờ hết lượt tải; đổi lại, file trên Drive khớp đúng trạng thái cơ sở
dữ liệu tại thời điểm tải, thay vì khớp một trạng thái đã trôi mất giữa lúc
xuất và lúc gửi.

---

## 5. ⛔ CÒN THIẾU MỘT THỨ: OAuth client ID (Founder)

Toàn bộ phần trên **đã xong và có test**. Thứ duy nhất còn thiếu là một khoá mà
chỉ Founder tạo được (§30 — "OAuth client Founder phải cung cấp").

Cho tới lúc có nó:

- `googleAuthenticatorProvider` trả về `UnconfiguredGoogleAuthenticator`
- nút *Kết nối* bấm được, và **nói ra** vì sao chưa chạy — không im lặng
- kết nối ở `SETUP_REQUIRED`, **không fake connected** (§8)

### 5.1 Vì sao chưa có sẵn

Firebase project `workizen-hub` đã có `com.workizen.tongtai`, nhưng chỉ với
OAuth client **type 3 (web)**. Client web có `client_secret` ⇒ theo luật
WTM-309 nó **không phải mobile-direct** và không được nhét vào app.

Thứ cần là OAuth client **type 1 (Android)** — loại không có secret, dùng chữ
ký APK để xác thực, và AppAuth bật PKCE sẵn
(`AuthorizationRequest.java:648`).

### 5.2 Founder làm gì (≈5 phút)

**Firebase Console** → project `workizen-hub` → ⚙️ *Project settings* → tab
*General* → app `com.workizen.tongtai` → **Add fingerprint**, dán:

```
SHA-1  45:10:C4:FF:F1:5F:4E:4B:AA:4A:B5:5A:BA:DC:51:CF:D5:16:62:E5
```

> Đây là vân tay của khoá **upload** (`tongtai-upload`, tạo 2026-08-07). Vân
> tay công khai, không phải bí mật — nó sinh ra để dán vào console.
>
> ⚠️ Nếu app phát hành qua **Play App Signing** thì Play ký lại bằng khoá
> khác. Vào Play Console → *Test and release* → *Setup* → *App signing*, lấy
> **SHA-1 của app signing key** và dán **thêm** một fingerprint nữa. Thiếu
> bước này thì bản tải từ Play đăng nhập không được, dù bản cài tay chạy tốt.

Sau đó tải lại `google-services.json` và thay vào `android/app/`. File mới sẽ
có `oauth_client` với `client_type: 1` cho `com.workizen.tongtai`.

### 5.3 Rồi tôi làm nốt gì

Một story tiếp theo, vì nó chạm native (⇒ bắt buộc smoke-launch bản release
trên máy thật, `adb logcat -b crash` rỗng):

1. thêm `flutter_appauth` + intent-filter cho custom scheme
   `com.googleusercontent.apps.<số>` vào `AndroidManifest.xml`
2. viết `AppAuthGoogleAuthenticator implements GoogleAuthenticator`
3. đổi **đúng một dòng**: `googleAuthenticatorProvider`

Không màn hình nào, không bảng nào, không luật nào đổi. Đó là cả điểm của việc
dựng seam trước khi có khoá: nếu đợi khoá rồi mới viết, thì lúc có khoá sẽ
không ai biết chỗ nào hỏng.

---

## 6. Bản đồ file

| File | Việc |
|---|---|
| `connection/connection_capability.dart` | một kết nối ↔ nhiều khả năng; scope đi theo **khả năng**, không theo nền tảng |
| `connection/connection_credential_store.dart` | bí mật → Keychain/Keystore; giá trị là `Map` vì Atlassian cần ba trường |
| `connection/connection_repository.dart` | metadata → SQLite; mã trạng thái lạ ⇒ **bỏ dòng**, không rơi về `active` |
| `connection/connection_service.dart` | vòng đời chung cho cả ba connector; ngắt kết nối xoá **cả hai** nửa |
| `connection/google/google_oauth.dart` | seam OAuth + bản chưa cấu hình (ném, không im lặng) |
| `connection/google/google_connection.dart` | vòng đời token; **giữ lại** refresh token khi Google trả `null` |
| `connection/google/drive_backup_service.dart` | REST v3: upload multipart · list · download |
| `connection/google/drive_backup_coordinator.dart` | nối vào cửa ghi duy nhất; 401 ⇒ làm mới quyền, thử lại **một** lần |
| `ui/screens/tongtai_connections_screen.dart` | màn Kết nối (L3) |
| `providers/tongtai_connection_provider.dart` | dây nối Riverpod; **chỗ duy nhất** phải đổi khi có client ID |

---

## 7. Những chỗ dễ sai, đã khoá bằng test

| Cái bẫy | Hậu quả nếu sập | Test giữ |
|---|---|---|
| Ghi đè refresh token bằng `null` | người bán phải đăng nhập lại **mỗi giờ**, không hiểu vì sao | *"refresh trả về null refresh_token KHÔNG xoá mất cái đang có"* |
| Mã trạng thái lạ rơi về `active` | kết nối hỏng trông như đang chạy | *"mã trạng thái lạ ⇒ bỏ dòng"* |
| Bản ghi `active` nhưng mất khoá | màn hình nói "đã kết nối" trong khi mọi lời gọi 401 | *"bản ghi ACTIVE nhưng mất credential ⇒ SETUP_REQUIRED"* |
| Xoá metadata mà quên xoá bí mật | bí mật **mồ côi** trong Keystore, không màn nào xoá được nữa | *"ngắt kết nối xoá CẢ HAI nửa"* |
| Revoke hỏng chặn luôn việc xoá | bấm "ngắt" mà khoá vẫn nằm trên máy | *"ngắt kết nối xoá khoá kể cả khi revoke hỏng"* |
| Danh sách Drive hỏng che mất nút sao lưu | không đọc được bản cũ ⇒ tưởng không tạo được bản mới | dựng trong màn: `AsyncError` rơi về nhánh rỗng, nút vẫn còn |
| `demo:` lẫn vào việc thật | không phân biệt được diễn tập và thật | *"externalId là drive:, không phải demo:"* |
