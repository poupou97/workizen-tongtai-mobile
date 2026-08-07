# ADR-TON-024 — Canonical Integration Platform Foundation

**Trạng thái:** **Accepted** (Founder, 2026-08-07)
**Mở rộng:** ADR-TON-016 (Rule Twin authoritative) · ADR-TON-018 (mã canonical)
**Không thay thế gì.** Contract envelope (WTM-270) giữ nguyên.

---

## Bối cảnh

Connector đầu tiên đã chạy thật (GitHub, WTM-268/274) và nền dữ liệu đã có hai
mảnh: `Provenance` (WTM-282) và `Connection` (WTM-283). Câu hỏi của Wave 2
không phải *"nối thêm sàn nào"* mà ***"nối thêm mười lăm sàn nữa mà không phải
đổi kiến trúc lần thứ hai"***.

Mười lăm nền tảng đó khác nhau ở gần như mọi thứ — trừ bốn chỗ, và chính bốn
chỗ đó là nơi một quyết định sai sẽ phải migrate dữ liệu người bán về sau.

---

## Quyết định

### 1. Tự động hoá dừng ở **liên kết danh tính**, không bao giờ tới **gộp khách**

Nhiều `ExternalIdentity` trỏ về một `BusinessCustomer` là *liên kết* — thêm một
dòng, gỡ được, sai thì sửa 5 giây. Nhập hai bản ghi khách làm một là *gộp* —
đơn hàng đổi chủ, hoàn tác rất khó.

| Mức tin cậy | Được làm |
|---|---|
| `exact` (khoá duy nhất nền tảng bảo đảm) | liên kết tự động |
| `strong` (số điện thoại/email trùng khớp) | **chỉ đề xuất** |
| `weak` · `none` | không đề xuất |
| **mọi mức** | **gộp bản ghi khách: KHÔNG BAO GIỜ tự động** |

`strong` vẫn phải hỏi vì hai người thật **có thể** dùng chung một số điện thoại
— vợ chồng, mẹ con, số cửa hàng. Ở Việt Nam đó là chuyện phổ biến, không phải
trường hợp biên. **Gộp nhầm hai khách tệ hơn không gộp.**

Lựa chọn thủ công của người bán **thắng** mọi luật tự động — cùng kỷ luật đã áp
ở FK 787 (user data thắng sample data).

### 2. Settlement: chiều tiền tường minh · `fundedBy` bắt buộc · cấm tự phân bổ

- `amount` **luôn dương**; chiều nằm ở `direction`. *Hoàn lại một khoản phí*
  đảo chiều so với *khoản phí*, mà cả hai cùng `kind` — để chiều nằm ngầm
  trong dấu số là mời hai connector viết ngược nhau cho cùng một sự việc.
- `fundedBy` (`platform` · `seller` · `shared` · `unknown`) **không có mặc
  định**. Voucher sàn tài trợ không phải chi phí người bán; nhầm chỗ này làm
  lợi nhuận sai đúng theo **hướng tâng bốc**.
- **Cấm tự động phân bổ** khoản cấp-đơn xuống từng món. Phân bổ là luật dẫn
  xuất ⇒ hàm thuần đọc lúc hiển thị, kết quả **không ghi xuống đĩa** (P-27/P-28).
- Thiếu dữ liệu ⇒ lợi nhuận là **chưa biết**, không phải "bằng doanh thu".
  Rule Twin trả `insufficient` kèm reason code.

### 3. Vendor Catalog và Capability Matrix là **dữ liệu**, không phải kiến thức của AI

- `recommended` là **hàm thuần** trên các trường khác, công thức viết ra, **không
  lưu**. Một cờ gán tay là ý kiến đội lốt dữ liệu.
- Mỗi dòng mang `verification`: `documented` · `tried` · `production`. Tài liệu
  vendor nói cái gì *có thể* làm được, không nói cái gì *nên* làm — và nó lệch
  theo hướng lạc quan (đã trả giá: catalog cũ ghi GitHub *"OAuth device flow ·
  n8n có node sẵn"*, **sai cả hai**).
- Capability Matrix có **ba** cột, không phải một ô ✅: `platformSupports` ·
  `connectorCovers` · `verifiedOnDogfood`. **AI chỉ được hứa ở cột thứ ba.**

### 4. Canonical event: từ vựng đóng, và cùng một sự việc ⇒ cùng một mã

- Connector chỉ emit mã canonical. Bảng ánh xạ *mã nền tảng → canonical* thuộc
  về **connector**, lõi nghiệp vụ không bao giờ thấy mã nền tảng.
- Mã lạ ⇒ `<miền>.unknown`, **không** ánh xạ về mã gần giống nhất.
- Phép thử cho một mã mới: *nếu ngày mai có sàn thứ tư làm cùng việc này, nó
  dùng được mã này không?* Không ⇒ mã đang mô tả **cách nền tảng nói**, không
  phải **việc đã xảy ra**.
- Không phải mọi thứ nền tảng có đều đáng thành sự kiện (GitHub tag **không**
  thành `delivery.released`).

---

## Hệ quả

**Được:** thêm một sàn = thêm một bảng ánh xạ + một dòng catalog + một cột ma
trận. Lõi nghiệp vụ, Rule Twin và schema **không đổi**.

**Mất:** ba chỗ chậm hơn có chủ ý — người bán phải xác nhận liên kết `strong`;
connector phải khai `fundedBy` dù nền tảng không nói rõ; một mã mới phải qua
phép thử "sàn thứ tư" trước khi được thêm.

**Rủi ro còn lại:** `fundedBy` là trường mà nhiều sàn **không trả**. Khi đó
`unknown` là câu trả lời trung thực, và hệ quả là Rule Twin từ chối trả lợi
nhuận — người bán sẽ hỏi *"vì sao không có số"*. Đó là câu hỏi đúng, và tốt hơn
một con số sai.

---

## Ảnh hưởng dữ liệu hiện có

**Không có.** Chỉ thêm bảng mới, rỗng. Không cột nào đang dùng đổi nghĩa. Giao
dịch phí sàn người bán đã tự nhập **giữ nguyên** trong Finance — không tự nhảy
sang Settlement, vì di chuyển chúng là đoán ý người bán.

Local-first (D-5) không bị chạm: mọi thứ ở đây nằm trên máy.

---

## Tài liệu

`docs/08-PLATFORM/` — `14-IDENTITY-RESOLUTION` · `15-SETTLEMENT-DOMAIN` ·
`16-VENDOR-CATALOG` · `17-CAPABILITY-MATRIX` · `18-CANONICAL-EVENTS` ·
`19-INTEGRATION-SANDBOX`.

Jira: Epic **WTM-284**, story thiết kế **WTM-285…290**, story cài đặt
**WTM-291** (N0.3) · **WTM-292** (N0.4).

---

## Tình trạng cài đặt (cập nhật 2026-08-07)

**Cả bốn luật đã được cài đặt.** 1964 test xanh; tất cả ở mức `L0` (domain +
persistence, chưa nối UI, chưa connector nào ghi vào các bảng mới).

| Luật | Cài ở đâu | Story | Cách khoá |
|---|---|---|---|
| 1 · liên kết ≠ gộp | `consumer/external_identity*.dart` · schema **v19** | WTM-291 | suite quét mã, 3 lớp — lớp quyết định: *"seam không chạm `customersTable`"* |
| 2 · settlement | `finance/settlement*.dart` · `true_profit.dart` · schema **v20** | WTM-292 | suite quét mã, 3 lớp — lớp tinh tế nhất: *"phân bổ không trả về `SettlementLine`"* |
| 3 · catalog/matrix là dữ liệu | `platform/vendor_catalog.dart` · `capability_matrix.dart` | WTM-293 | **kiểu dữ liệu** — `CapabilityClaim` không mang hai cột đầu, constructor private |
| 4 · canonical event | `platform/canonical_event.dart` | WTM-294 | **kiểu dữ liệu** — `type` là enum, nên mã nền tảng không dựng được envelope |

### Hai cách khoá, và khi nào dùng cái nào

Luật 1 và 2 cấm một **đường đi** (một hàm nào đó không được tồn tại) ⇒ phải quét
mã nguồn, vì không kiểu dữ liệu nào diễn đạt được *"không có hàm nào làm X"*.

Luật 3 và 4 cấm một **giá trị** đi tới sai chỗ ⇒ diễn đạt được bằng kiểu, và
kiểu mạnh hơn: nó chặn lúc biên dịch, không cần ai chạy test.

Chọn kiểu khi diễn đạt được; quét mã khi không.

### Bằng chứng luật có răng: nó đã cắn tác giả của chính nó

- **Luật 1** bắt được `IdentityResolver.resolve()` bản đầu nhận hai
  `customerId`. Đã **sửa API chứ không nới luật** — mọi ứng viên đi qua
  `IdentityCandidate`, và luật không cần ngoại lệ nào.
- **Luật 2** lộ ra hai chỗ bản thiết kế nói chưa đủ chặt: `shared` không kèm tỷ
  lệ thực chất là `unknown`; và đọc số tiền khi chưa biết ai trả phải **ném**
  chứ không trả `0`.
- **Luật 4** buộc bỏ `const` khỏi `CanonicalEvent` để giữ được assert cấm kết
  luận kinh doanh trong payload. Giữ assert quan trọng hơn giữ `const` — một
  lời khuyên bị bỏ qua đúng vào ngày ai đó vội.

Chi tiết trong §"Đã cài đặt" của bốn tài liệu `docs/08-PLATFORM/14`–`18`.
