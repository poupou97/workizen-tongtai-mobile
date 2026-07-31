# ADR-TON-018 — `.ttbk` v2 Backup Format & Replace Restore

- **Status:** ✅ ACCEPTED (Founder decision "WTM-164 restore mode", 2026-07-31)
  · **Amendment 1** (Founder Note "Business Snapshot Package", 2026-07-31 — §9)
  · **Amendment 2** (bản sao lưu an toàn phải mở lại được, 2026-07-31 — §10)
- **Jira:** WTM-164 · WTM-165 (amendment 1)
- **Extends:** ADR-TON-008/009 (persistence) · ADR-TON-010 (Orders ↔ Inventory
  reference) · ADR-TON-017 (error-handling seam) · ADR-TON-005/D-7 (telemetry)
- **Supersedes:** không. `.ttbk` **v1 vẫn tồn tại như một file CSV mã hoá** —
  nó chỉ **không còn được coi là backup**.

## Vấn đề

Audit `.ttbk` (2026-07-31) cho thấy **format v1 không khôi phục được một
doanh nghiệp**, và xây restore trên nó sẽ tạo ra một tính năng phục hồi **làm
mất dữ liệu trong im lặng** — tệ hơn là không có restore.

| | v1 |
|---|---|
| Nội dung | **một** file CSV của **một** tập dữ liệu, mã hoá (mã hoá là **tuỳ chọn**) |
| Phủ | 3/6 repository — **thiếu** goals · finance · favourites |
| Orders | **không có `order.id`**, **không có `OrderItem.productId`** ⇒ đứt liên kết Inventory↔Orders mà ADR-TON-010 bắt buộc |
| Enum | xuất bằng **nhãn tiếng Việt** (`labelVi`) — vô nghĩa với bản EN, vỡ khi đổi từ ngữ |
| Mất trường | customer `history` · product `description`/`imagePaths`/`history` · `sku`/`unit` của dòng đơn |
| Version | `TONGTAI-BACKUP-V1:` version hoá **container mã hoá**, không phải schema dữ liệu |
| Integrity | AES-GCM tag chỉ có khi mã hoá; file `.csv` trần **không có gì** |
| Import | **không tồn tại** |

## Quyết định

### 1. Hai định dạng, hai việc

**CSV export ở nguyên** — nó để mở bằng Excel và chia sẻ. **`.ttbk` v2 là thứ
để khôi phục.** Trộn hai mục đích vào một file là nguồn gốc của toàn bộ vấn đề
trên.

### 2. v2 = snapshot toàn miền, có version, lossless

```text
TONGTAI-BACKUP-V2:{"manifest":{…},"payload":"<base64>"}
```

**Manifest là plaintext; payload có thể mã hoá.** Tách như vậy có lý do:

- đọc được version + tính tương thích + integrity **trước khi** hỏi mật khẩu và
  **trước khi** chạm vào database;
- **số bản ghi nằm BÊN TRONG payload**, nên file mã hoá không rò rỉ *"tiệm này
  có 412 khách"* cho bất kỳ ai cầm được file.

Manifest mang: `formatVersion` · `contentSchemaVersion` · `appVersion` ·
`databaseSchemaVersion` · `backupId` · `createdAt` · `encryption` ·
`compression` · `checksumAlgorithm` · `payloadSha256` · `payloadBytes`.

Payload mang `counts` + `datasets` cho **cả 6 repository**: customers ·
products · orders (kèm order items) · goals · transactions · favourites.

### 3. Giá trị canonical, không bao giờ là nhãn hiển thị

Enum đi bằng `.name` (`delivered`, `income`, `customerGrowth`). Trường **dẫn
xuất** (customer tier, trạng thái tồn kho) **không** được lưu — chúng được tính
lại, lưu vào backup sẽ tạo ra hai nguồn sự thật ngay bên trong file.

Decoder trả `null` thay vì ném, nên validation chỉ ra **dòng nào của dataset
nào** hỏng. Đặc biệt: mã enum lạ là **bản ghi không hợp lệ**, KHÔNG phải giá trị
mặc định — `OrderStatus.fromStorage` mặc định về `pending`, và một đơn `delivered`
âm thầm thành `pending` là mất dữ liệu đội lốt default.

### 4. SHA-256 là chống hỏng, KHÔNG phải chống giả mạo

Checksum **bắt buộc kể cả khi không mã hoá**. Nó phát hiện file hỏng/thiếu. Nó
**không** chứng minh file là thật — ai sửa payload cũng tính lại được hash.
Tính xác thực chỉ đến từ AES-GCM tag, tức **chỉ khi có mã hoá**. UI nói đúng
như vậy.

### 5. Restore = **Replace**, không Merge (Founder, 2026-07-31)

Restore nghĩa là khôi phục **một** ảnh chụp hoàn chỉnh và nhất quán. Merge là
một capability riêng cần luật đối chiếu miền (id trùng giữ bản nào? gộp đơn
hàng/tồn kho ra số liệu gì?) và **không được nhét lén** vào backup/restore.
UI **không** có lựa chọn Replace/Merge.

### 6. Thứ tự thao tác chính là thiết kế

```text
chọn file → validate TOÀN BỘ (read-only) → preview
  → xác nhận phá huỷ (nói rõ hậu quả)
  → tạo VÀ verify bản sao lưu an toàn
  → MỘT transaction { xoá theo thứ tự FK → ghi theo thứ tự phụ thuộc
                      → verify counts + FK } → commit
  → invalidate cache dữ liệu → báo thành công + đường dẫn bản an toàn
```

- **Không chạm database** cho tới khi file đã validate xong.
- **Không xoá gì** cho tới khi bản sao lưu an toàn đã ghi **và đọc lại được
  qua chính validator đó**. Không tạo/verify được ⇒ **dừng**.
- Verify **bên trong** transaction: lệch số hoặc mất FK ⇒ ném ⇒ rollback toàn bộ.
- Bất kỳ lỗi nào ⇒ database **y như cũ**, lỗi được phân loại qua ADR-TON-017.

Validate phủ: header/container · tương thích format + content schema · độ dài ·
checksum · giải mã · đủ 6 dataset · từng dòng · **id trùng** · **FK
order→customer** · mã enum · counts khai báo vs thực tế. **Không có
best-effort partial import**: file dùng được hoặc không.

### 7. Chính sách tương thích

| Trường hợp | Hành vi |
|---|---|
| cùng content schema | restore |
| schema cũ hơn còn hỗ trợ | **migrate payload tường minh** rồi restore |
| version mới hơn | **chặn** — schema mới có thể mang trường bản này sẽ âm thầm bỏ, và bỏ trường trong lúc *restore* đúng là thứ WTM-164 sinh ra để ngăn |
| hỏng / không nhận dạng được | chặn |

### 8. Riêng tư

Đường dẫn file, tên file, nội dung backup và số bản ghi **không bao giờ** lên
telemetry — chỉ `kind`/`code`/`screen` như mọi lỗi khác (ADR-TON-017). Có
governance test quét đúng điều này trên màn backup.

### 9. `.ttbk` là **Business Snapshot Package** — backup chỉ là một capability

*(Amendment 1 — Founder Note, 2026-07-31. WTM-165.)*

File này không phải "file backup". Nó là **một ảnh chụp doanh nghiệp đóng gói**;
*backup* là **capability đầu tiên** dùng nó, không phải bản chất của nó. Các
capability đã thấy trước: **Restore · Clone Business · Migration · Demo Dataset ·
AI Sandbox · Support Bundle · Analytics Exchange**.

**Vòng này KHÔNG triển khai các capability đó.** Việc duy nhất phải làm bây giờ
là **không khoá đường** — vì đổi format sau khi người dùng đã cầm file trong tay
là thứ đắt nhất, còn chừa chỗ lúc này gần như miễn phí.

Ba trường được thêm vào manifest, mỗi trường trả lời một câu mà một reader tương
lai **bắt buộc** phải hỏi trước khi làm gì với file:

| Trường | Câu hỏi | Mặc định khi vắng mặt |
|---|---|---|
| `packageKind` | *Đây là gói loại gì?* | `backup` |
| `datasets` | *Bên trong có những miền nào?* | cả 6 |
| `redaction` | *Dữ liệu có bị lược bỏ không?* | `none` |

**Vì sao đây là điều kiện cần, không phải trang trí:** thiếu `packageKind`, một
Demo Dataset và một backup thật là **hai file không phân biệt được** — và cái
giá của việc nhầm lẫn chính là restore đè dữ liệu thật bằng dữ liệu mẫu. Thiếu
`redaction`, một Support Bundle đã bôi tên khách sẽ **restore đè lên khách
thật**. Thiếu `datasets`, một gói bộ phận chỉ lộ ra là thiếu **sau khi** đã
parse hết payload.

Quy tắc đọc:

- **Mã lạ ⇒ `unknown`, không bao giờ ⇒ `backup`.** Một app mới hơn có thể ghi
  loại mà bản này chưa biết; đoán nó là backup nghĩa là restore một thứ không
  hiểu — đúng cái ADR này sinh ra để chặn.
- **Vắng mặt ⇒ mặc định như bảng trên.** Hai file v2 đã tồn tại ngoài đời được
  ghi trước khi có ba trường này; với format lúc đó chúng **chỉ có thể** là
  backup đầy đủ, không lược bỏ. Đây là **sự thật của format**, không phải phỏng
  đoán — nên đọc chúng vẫn restore được.
- **Khoá manifest lạ ⇒ bỏ qua.** Reader tương lai thêm trường không được biến
  gói của nó thành "hỏng" ở bản này; tương thích do các trường version quyết
  định, không do sự có mặt của từng khoá.

**Chỗ đặt lệnh cấm nằm ở restore contract, không ở format.** Một gói bộ phận
hoặc đã lược bỏ là **một gói hợp lệ** — nó chỉ không phải thứ để restore. Vì
vậy `notRestorableKind` / `redactedPackage` / `missingDataset` là lý do **từ
chối restore**, và manifest vẫn parse được để preview nói ra **file này là gì**
thay vì chỉ nói "không dùng được". Phân biệt này là thứ cho phép Clone Business
hay Support Bundle sau này dùng chung đúng validator mà không phải nới lỏng
một dòng nào của restore.

### 10. Bản sao lưu an toàn phải **mở lại được** từ trong app

*(Amendment 2 — WTM-173.)*

§6 bắt buộc tạo **và verify** một bản sao lưu an toàn trước khi xoá bất cứ thứ
gì. Nhưng nó ghi vào thư mục documents **riêng của app** — nơi trình chọn file
của hệ thống **không với tới**. Kết quả: **file duy nhất tồn tại để cứu một lần
restore nhầm lại là file duy nhất người bán không mở được.** Một bản cứu hộ
không dùng được thì không cứu ai; nó chỉ làm ta yên tâm.

Màn Backup vì vậy đọc lại nó qua **chính cái vault đã ghi nó** và đưa vào
preview.

**Nó dừng ở preview, cố ý.** Áp dụng bản an toàn vẫn là một lệnh Replace phá
huỷ, và một nút "hoàn tác" chỉ-một-chạm mà âm thầm ghi đè chính là cùng một sai
lầm chĩa theo hướng ngược lại. Người dùng vẫn phải xác nhận lần nữa.

## Hệ quả

- Thêm `deleteAll()` cho 6 repository — **viết rõ ra** thay vì dùng mẹo
  `deleteByIdPrefix('')` mà không ai đọc code sẽ nhận ra là "xoá sạch".
- Thêm dependency: `file_picker` (chọn file hệ thống) · `crypto` (SHA-256
  **đồng bộ** — bản async của `cryptography` không bao giờ hoàn tất trong
  fake-async zone của `testWidgets`, tức là màn có checksum sẽ không thể
  widget-test được).
- Màn hình **không** tự đọc file: `pickFile` trả `TongtaiPickedBackup`
  (path + content). I/O thật khởi phát từ callback của widget làm treo widget
  test — và tách ra cũng là seam sạch hơn.
- Edit history (`CustomerRevision`/`ProductRevision`) **được format hỗ trợ đầy
  đủ** nhưng repository hiện **không persist** nó (ghi rõ là "regenerable
  session state"), nên nó không nằm trong đảm bảo round-trip qua database.

## Phương án đã cân nhắc

- **Xây restore trên v1.** Bị loại: mất goals/finance/favourites hoàn toàn, và
  đứt mọi liên kết order→product. Một restore như vậy nguy hiểm hơn là không có.
- **Cho người dùng chọn Replace/Merge.** Founder giữ lại: merge cần luật đối
  chiếu miền chưa tồn tại, và một UI "gộp" mà người bán không lường được hậu quả
  sẽ tạo ra số liệu kinh doanh sai.
- **Manifest chứa luôn record counts.** Bị loại: làm rò rỉ quy mô kinh doanh từ
  một file đã mã hoá.
- **Best-effort partial import.** Bị loại: một snapshot thiếu một phần không
  còn là snapshot, và "khôi phục được chừng nào hay chừng đó" là cách chắc chắn
  nhất để tạo ra một doanh nghiệp không nhất quán.
