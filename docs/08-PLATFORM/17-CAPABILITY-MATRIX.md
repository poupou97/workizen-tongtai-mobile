# Capability Matrix — tách "nền tảng làm được" khỏi "MÌNH làm được"

> **WTM-288 · N2 · Epic WTM-284 (Platform Wave 2).** Ngày **2026-08-07**.
> Nguồn **duy nhất** để AI biết nền tảng nào hỗ trợ chức năng gì.

---

## ⭐ Điểm thiết kế quyết định: ba trạng thái, không phải một ô ✅

Một dấu ✅ duy nhất trộn **ba sự thật khác nhau**, và trộn chúng là cách hứa
những thứ mình không làm được:

| Cột | Câu hỏi nó trả lời | Ai đổi được |
|---|---|---|
| `platformSupports` | Nền tảng **có API** cho việc này không? | nghiên cứu vendor |
| `connectorCovers` | **Connector của mình** đã làm chưa? | người viết connector |
| `verifiedOnDogfood` | Đã chạy thật trên dữ liệu Workizen chưa? | bằng chứng, không phải ý định |

Ba cột chênh nhau là **bình thường** và phải nhìn thấy được.

**Hôm nay, GitHub:** `platformSupports` rất nhiều thứ · `connectorCovers` đúng
**ba** endpoint (commits · pulls · releases) · `verifiedOnDogfood` đúng ba
endpoint đó, với số đo thật (211/155/0).

Nếu AI đọc nhầm cột đầu thành cột ba, nó sẽ nói với người bán rằng *"đồng bộ
tồn kho Shopee được"* trong khi **chưa ai viết dòng code nào**. Đó không phải
lỗi hiển thị — đó là AI nói dối một cách tự tin, đúng thứ ADR-TON-016 sinh ra
để chặn.

**Tiền lệ trong repo:** `UI-IMPLEMENTATION-LEVELS.md` khoá *"level khai trong
Jira PHẢI == level thật trong code"*, và một màn mới không khai mức ⇒ CI đỏ.
Ma trận này cần đúng loại khoá đó.

---

## Từ vựng capability

`orders` · `products` · `inventory` · `customers` · `chat` · `ads` · `live` ·
`warehouse` · `payments` · `settlement` · `shipping` · `analytics`

Mã canonical, dùng chung với `category` của Vendor Catalog.

---

## Ma trận (trích — bản đầy đủ trong module)

Ký hiệu: **P** = platformSupports · **C** = connectorCovers · **D** = verifiedOnDogfood

| Platform | orders | products | inventory | customers | chat | ads | settlement | analytics |
|---|---|---|---|---|---|---|---|---|
| **GitHub** | — | — | — | — | — | — | — | **P C D** *(delivery)* |
| **Shopee** | P | P | P | P (ẩn danh) | P | P | P | P |
| **TikTok Shop** | P | P | P | P (ẩn danh) | P | P | P | P |
| **Shopify** | P | P | P | P | — | — | P | P |
| **Facebook/Messenger** | — | P | — | P (PSID) | P | P | — | P |
| **Telegram** | — | — | — | P (chat id) | P | — | — | — |
| **Gmail** | — | — | — | P (email) | P | — | — | — |
| **Stripe** | — | — | — | P | — | — | P | P |
| **RevenueCat** | P *(sub)* | P | — | P | — | — | P | P |
| **GA4 / Search Console** | — | — | — | — | — | — | — | P |

**Không ô nào ngoài GitHub có `C` hay `D`.** Đó là sự thật hôm nay, và ma trận
tồn tại để nó không bị đọc nhầm thành khả năng.

⚠️ `customers` ở các sàn ghi **(ẩn danh)**: sàn trả một mã người mua, **không**
trả số điện thoại hay tên thật. Đó là lý do `IdentityConfidence` (WTM-285) tồn
tại — và lý do gộp khách tự động bị cấm.

---

## Luật giữ ma trận đúng

1. **Một ô đổi trạng thái ⇒ cập nhật trong CÙNG PR** — như `UI-IMPLEMENTATION-LEVELS.md`.
2. **`D` chỉ được bật kèm bằng chứng**: số đo thật, ngày, story. Không có bằng
   chứng thì không phải `D`.
3. **`C` không được vượt `P`.** Connector không thể phủ thứ nền tảng không có —
   nếu thấy vậy thì một trong hai ô sai, và đó là tín hiệu đáng dừng lại.
4. **AI chỉ được hứa ở mức `D`.** `P` là thông tin thị trường, `C` là trạng thái
   kỹ thuật, chỉ `D` là thứ nói được với người bán.

---

## Vì sao ma trận này không phải bảng trong tài liệu

Nó là **dữ liệu**, đọc qua repository, cùng lý do với Vendor Catalog: truy vấn
được, test được, và không nằm trong prompt AI. Tài liệu này là **đặc tả**;
nguồn thi hành nằm trong module.

---

## Đã cài đặt — WTM-293 (2026-08-07)

`lib/features/tongtai/platform/capability_matrix.dart`. **Không bảng** — cùng
lý do với Vendor Catalog.

### Luật "AI chỉ được hứa ở cột ba" là một KIỂU DỮ LIỆU

Bản thiết kế viết luật này thành câu. Một câu như vậy sẽ bị vi phạm ngày đầu
tiên có người viết `if (cell.platformSupports) return 'làm được'`.

Nên nó thành cấu trúc:

```dart
class CapabilityClaim {
  const CapabilityClaim._({...});   // ← constructor PRIVATE
  final String platform;
  final PlatformCapability capability;
  final String evidence;            // ← luôn có
  // KHÔNG có platformSupports, KHÔNG có connectorCovers
}

CapabilityClaim? CapabilityCell.toClaim() =>
    verifiedOnDogfood ? CapabilityClaim._(...) : null;   // ← cổng DUY NHẤT
```

Tầng AI nhận `List<CapabilityClaim>`, nên nó **không cầm** hai cột kia. Không
cầm thì không đọc nhầm được. Và constructor private nghĩa là không ai dựng được
một lời hứa từ hư không.

### Ba assert trong `CapabilityCell`

| Assert | Nói gì |
|---|---|
| `C ⟹ P` | connector không phủ được thứ nền tảng không có — thấy vậy nghĩa là một trong hai ô sai |
| `D ⟹ C` | chưa viết thì chạy thật bằng gì |
| `D ⟹ evidence != null` | không bằng chứng thì đó là **ý định**, và ý định không nói được với người bán |

### Sự thật hôm nay, đã khoá bằng test

```dart
expect(CapabilityMatrix.claims.map((c) => c.platform).toSet(), {'github'});
```

**Chỉ GitHub** có lời hứa. Shopee có `P` đầy đủ ở 5 capability và **không lời
hứa nào** — test khẳng định cả hai vế cùng lúc, nên ngày ai đó bật nhầm một ô,
test đỏ trước khi AI kịp nói.

### Khoá bằng governance

`catalog_is_data_governance_test`: `CapabilityClaim` không mang hai cột đầu ·
constructor private · **đúng một** chỗ trong module dựng được lời hứa, và chỗ
đó nằm **sau** phép kiểm `verifiedOnDogfood`.
