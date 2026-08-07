# Identity Resolution — nhiều danh tính sàn, một người mua

> **WTM-285 · N0.3 · Epic WTM-284 (Platform Wave 2).** Ngày **2026-08-07**.
> Thiết kế, **không** code connector, **không** gọi API.

Shopee Buyer · TikTok Buyer · Messenger PSID · Telegram Chat · Email ·
Shopify Customer — tất cả có thể trỏ về **cùng một người mua**. Bài toán là
biết khi nào chúng thật sự là một người, và **khi nào thì không được đoán**.

---

## ⭐ Phân biệt quyết định tất cả: LIÊN KẾT ≠ GỘP

Đây là chỗ dễ trộn nhất, và trộn nó là cách nhanh nhất để một luật khớp tự
động phá dữ liệu khách hàng thật.

| | **Liên kết** (link) | **Gộp** (merge) |
|---|---|---|
| Việc gì | thêm một danh tính ngoài trỏ vào khách đã có | nhập hai **bản ghi khách** làm một |
| Thay đổi gì | thêm một dòng ở bảng danh tính | đơn hàng đổi chủ, một bản ghi biến mất |
| Gỡ ra | **được**, xoá dòng là xong | rất khó — phải nhớ đơn nào vốn của ai |
| Sai thì sao | một danh tính treo nhầm chỗ, sửa 5 giây | hai người thật bị nhập một, lịch sử mua hỏng |

**Gần như mọi nhu cầu thực tế chỉ cần *liên kết*.** Gộp chỉ cần khi chính người
bán đã lỡ tạo hai bản ghi cho cùng một người — một bài toán khác hẳn, và nó
không sinh ra từ connector.

⇒ **Tự động hoá dừng ở liên kết. Gộp bản ghi khách: không bao giờ tự động, ở
mọi mức tin cậy.**

---

## Mô hình

```
BusinessCustomer  (đã có — bản ghi khách của người bán)
      ▲
      │  0..n
ExternalIdentity {
    platform      : mã canonical  — 'shopee' | 'tiktok' | 'messenger' | …
    externalId    : mã do nền tảng cấp (KHÔNG phải nhãn hiển thị)
    connectionId  : → Connection (WTM-283); danh tính thuộc về một kết nối
    displayName?  : tên hiển thị lúc thấy — chỉ để người bán nhận ra, KHÔNG để khớp
    confidence    : IdentityConfidence
    linkKind      : manual | automatic | verified
    linkedAt      : khi nào gắn vào khách này
    verifiedAt?   : khi nào nền tảng xác nhận (nếu có)
}

IdentityLinkEvent {          ← lịch sử, không xoá bao giờ
    identityId · fromCustomerId? · toCustomerId? · action · confidence · at · actor
}
```

`connectionId` bắt buộc: cùng một `externalId` ở hai tài khoản Shopee khác nhau
là **hai người khác nhau**. Bỏ nó đi là mở đường cho một loại nhầm không sửa được.

---

## `IdentityConfidence` — bốn mức, không phải một số thực

Một số thực (0.87) nghe khoa học và **không quyết định được gì**: không ai biết
ngưỡng nào là đủ, và mỗi chỗ đọc sẽ tự chọn một ngưỡng khác.

| Mức | Nghĩa | Ví dụ |
|---|---|---|
| `exact` | nền tảng bảo đảm khoá **duy nhất** cho một người | Shopee buyer_id trong cùng một shop · Messenger PSID |
| `strong` | trùng khớp **chính xác** một định danh mạnh | số điện thoại giống hệt · email giống hệt |
| `weak` | giống nhau, không bằng chứng | tên gần giống · địa chỉ gần giống |
| `none` | không có cơ sở | chỉ trùng thành phố, trùng ngày mua |

### Luật tự động — và nó dừng sớm hơn người ta tưởng

| Mức | Được làm gì |
|---|---|
| `exact` | **liên kết tự động** |
| `strong` | **chỉ đề xuất** — người bán bấm mới liên kết |
| `weak` | không đề xuất; hiện ở màn "chưa gán" nếu người bán chủ động tìm |
| `none` | không làm gì cả |

Vì sao `strong` vẫn phải hỏi: hai người thật **có thể** dùng chung một số điện
thoại — vợ chồng, mẹ con, số cửa hàng. Ở Việt Nam chuyện đó phổ biến, không
phải trường hợp biên. Gộp nhầm hai khách tệ hơn không gộp: một bên là mất một
gợi ý, bên kia là nói với người bán những điều sai về khách của họ.

---

## `linkKind` — ai đã quyết định

| | Ai quyết | Gỡ được | Đè lên nhau |
|---|---|---|---|
| `manual` | người bán | được | **thắng tất cả** |
| `automatic` | luật khớp (`exact`) | được | nhường `manual` |
| `verified` | nền tảng xác nhận | được | nhường `manual` |

**Người bán luôn thắng.** Cùng kỷ luật đã áp ở FK 787 (dữ liệu người dùng thắng
dữ liệu mẫu) và ở Rule Twin (người quyết định, AI chỉ giải thích). Một luật tự
động đè lên lựa chọn của người bán là lỗi, không phải tính năng.

---

## Lịch sử — điều kiện để tự động hoá được phép tồn tại

`IdentityLinkEvent` ghi **mọi** lần gắn/gỡ, không bao giờ xoá.

Không có nó thì không có cách nào trả lời *"vì sao khách này có đơn từ TikTok?"*,
và cũng không có cách nào **hoàn tác an toàn**. Tự động hoá chỉ được phép khi
hoàn tác rẻ; lịch sử là thứ làm cho hoàn tác rẻ.

Trường `actor` phân biệt `seller` với `rule:<tên luật>` — để khi một luật khớp
hoá ra sai, tìm được **tất cả** thứ nó đã gắn và gỡ hàng loạt.

---

## Riêng tư

- `ExternalIdentity` là **dữ liệu người bán**, nằm trên máy như mọi thứ khác
  (D-5 local-first). Không có bước nào gửi nó đi đâu.
- Vào `.ttbk` như một dataset **tuỳ chọn** (ADR-TON-018) — không vào `all`, vì
  nó chứa định danh của **bên thứ ba** (người mua), không chỉ của người bán.
- `displayName` chỉ để người bán nhận ra mặt, **không dùng để khớp**. Khớp theo
  tên là nguồn của `weak`, và `weak` không tự động hoá gì.

---

## Điều thiết kế này CHƯA giải quyết

- **Gộp hai bản ghi khách do người bán tự tạo trùng** — bài toán khác, cần luồng
  UI riêng với xem trước và hoàn tác. Không nằm trong N0.3.
- **Người mua ẩn danh** — nhiều sàn không trả gì ngoài một mã đơn. Khi đó không
  có `ExternalIdentity` nào cả, và đơn gắn vào một khách "chưa định danh".
  Đó là trạng thái hợp lệ, **không** phải lỗi cần vá bằng cách đoán.

---

## Đã cài đặt — WTM-291, schema v19 (2026-08-07)

Thiết kế trên đã thành code. Ba chỗ **khác** bản thiết kế, và cả ba là do viết
test mới lộ ra:

### 1. `resolve()` không nhận `customerId` nào

Bản thiết kế hình dung `resolve(…, matchedCustomerIdByPhone, matchedCustomerIdByEmail)`.
Viết xong thì bộ quét governance báo vi phạm luật 4 — **và nó đúng**: một hàm
nhận hai `customerId` chính là hình dạng cần cấm, kể cả khi thân hàm vô hại.

Sửa API chứ không nới luật. Mọi ứng viên đi qua một kiểu:

```dart
IdentityDecision resolve({
  required String platform,
  required String externalId,
  required String connectionId,
  required List<ExternalIdentity> existing,
  List<IdentityCandidate> candidates = const [],   // ← không còn customerId rời
});
```

`IdentityCandidate {customerId, signal, confidence}` — `signal` là enum
(`phone` · `email`), không phải chuỗi mô tả: chuỗi mô tả sẽ là tiếng Việt nằm
trong tầng domain, trái ADR-TON-007.

### 2. Ứng viên tự nhận `exact` vẫn bị hạ về `strong`

Tự động liên kết **chỉ** dành cho khoá do chính nền tảng cấp (nhánh "đã gắn
rồi"). Một luật khớp tự gán cho mình mức `exact` không được mở đường tắt —
nếu không thì luật 2 vô hiệu chỉ bằng cách đổi một hằng số trong luật khớp.

### 3. `moveToCustomer` đổi `linkKind` sang `manual`

Người bán sửa tay thì liên kết trở thành thủ công. Giữ `automatic` sẽ để lần
chạy sau của luật ghi đè đúng chỗ người bán vừa sửa — cùng kỷ luật với FK 787
(dữ liệu người dùng thắng dữ liệu mẫu).

### Luật 4 được khoá bằng ba lớp, mạnh dần

`test/features/tongtai/p0/identity_no_auto_merge_governance_test.dart`:

| Lớp | Kiểm gì | Bắt được gì |
|---|---|---|
| 1 | không hàm nào nhận hai `customerId` **và trả về một** | đúng câu chữ tiêu chí WTM-291 |
| 2 | không tên hàm nào hình dạng `merge*`/`absorb*`/`consolidate*` | ý định, kể cả khi thân hàm còn vô hại |
| 3 | **seam không chạm `customersTable`**, và không import `CustomerRepository` | quyết định — không đặt tên khéo nào lách được |

Lớp 3 là lớp thật sự bảo đảm: một seam không với tới bảng khách thì không xoá
hay nhập bản ghi khách nào được.

Suite còn có bốn test tự kiểm **chống PASS GIẢ** — chứng minh bộ quét đọc được
code, bắt được vi phạm khi vi phạm có mặt, và **không** báo nhầm hai thứ hợp lệ
(lời gọi `customerId: row.customerId`, và hàm ghi nhật ký nhận
`fromCustomerId` + `toCustomerId` trả `Future<void>`). Lớp 3 từng xanh oan vì
biểu thức viết `\bdb\.` trong khi trường tên `_db` — tập rỗng thoả mãn mọi ràng
buộc; `expect(all, allowedTables)` là thứ bắt được.

### Schema v19

`external_identities_table` · `identity_link_events_table`. Thuần thêm mới.

- Khoá duy nhất `(business, connection, platform, external_id)`.
- Lịch sử **không** có khoá ngoại tới bảng danh tính: gỡ liên kết là xoá dòng
  danh tính, mà bằng chứng phải sống sót qua chính việc nó ghi lại.
- Danh tính có FK cascade tới `customers_table`: khách bị xoá thì danh tính mồ
  côi không còn nghĩa.
- `customers_table.external_id` / `external_source` **để nguyên, không migrate**
  — chúng đang rỗng, và chép một suy đoán sang bảng mới là lặp lại sai lầm v17
  đã tránh.

**Chưa nối vào UI** (L0). Chưa connector nào ghi vào hai bảng này; chúng là nền
để connector đầu tiên có chỗ đặt chân.
