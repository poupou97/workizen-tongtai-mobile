# Commerce Attribute Model — thiết kế, phân loại, và bốn va chạm phải loại

> **WTM-333 · Epic [WTM-324](https://workizen.atlassian.net/browse/WTM-324) · Addendum "Commerce Model Extensibility"**
> `IMPLEMENTATION_LEVEL=L0` — **tài liệu + ADR, không một dòng code.**
> Nguồn quy tắc: ba quyết định Founder 2026-08-09 + quy tắc phân loại §29.
> Nối tiếp: [ADR-TON-009](../03-DECISIONS/ADR-TON-009-persistence-snapshot-then-normalize.md)
> (Amendment 2), [ADR-TON-023](../03-DECISIONS/ADR-TON-023-business-input-and-product-type.md)
> (ProductKind), [WTM-334](https://workizen.atlassian.net/browse/WTM-334) (tầng thuộc tính động),
> [WTM-335](https://workizen.atlassian.net/browse/WTM-335) (dataset v2 + hiển thị theo nhóm).

---

## 0. Câu hỏi tài liệu này trả lời

Một sản phẩm thương mại có **rất nhiều trường**. Nếu mỗi trường mới đều thành một
cột thì schema phình mãi; nếu mỗi trường mới đều nhét vào `domainSnapshot` (JSON)
thì ta có một **nhà thứ ba** cho cùng một dữ liệu (cột · snapshot · và bây giờ là
attribute) — đúng hình dạng lỗi **P-27/P-28** đã bắt hụt bốn lần: *"trường đã lưu
vs. luật dẫn xuất"*, hai nguồn trả lời cùng một câu hỏi.

Tài liệu này chốt **mỗi trường ứng viên thuộc về đâu**:

| Tầng | Lưu ở | Ai sở hữu sự thật | Khi nào |
| --- | --- | --- | --- |
| **CORE** | cột typed trên `products_table` | cột là **Source of Truth** | trường **load-bearing**: chạm inventory · price · profit · order · settlement · identity · listing lifecycle · automation |
| **OPTIONAL STANDARD** | cột typed **nullable** | cột là SoT khi có giá trị; `null` = *chưa nhập*, không phải `0`/`false` | trường **chuẩn khắp mọi sàn** và vẫn chạm một trục §29, nhưng **không phải sản phẩm nào cũng có** |
| **DYNAMIC** | tầng thuộc tính động (WTM-334: `attribute_definitions/values/groups`) | `AttributeValue` là SoT, tải **on-demand ở màn chi tiết** | trường **phân loại · mô tả · thông số kỹ thuật · metadata** theo ngành, **thưa** (mỗi ngành một bộ khác) |

> ⛔ Một trường **chỉ được ở một nhà**. Không có trường nào vừa là cột vừa là
> attribute. Ranh giới di chuyển được (§6) nhưng tại một thời điểm chỉ một nơi giữ
> sự thật.

---

## 1. Ba quyết định Founder đã chốt (2026-08-09) — ghi lại nguyên văn ý

### ① Loại các optional field tạo Business Truth thứ hai (→ §5)

Bốn nhóm trường bị loại vì đã có nguồn sự thật khác trả lời đúng câu hỏi đó.

### ② Tầng thuộc tính thay `domainSnapshot` làm cơ chế mở rộng **chính** của Product

**Amend [ADR-TON-009](../03-DECISIONS/ADR-TON-009-persistence-snapshot-then-normalize.md)**
(xem Amendment 2 trong ADR đó). Từ nay:

- Cơ chế mở rộng **chính** của `Product` = **tầng thuộc tính động** (DYNAMIC), không
  phải `domainSnapshot`.
- `domainSnapshot` **chỉ còn hai việc**: (a) tương thích ngược cho dữ liệu đã lưu,
  (b) giữ `imagePaths` **cho tới khi** thực thể `Media` thay thế (§7).
- ⛔ **Không thêm extension field mới vào snapshot.** Trường mở rộng mới đi vào tầng
  thuộc tính (nếu là spec/metadata) hoặc thành cột (nếu load-bearing).

Lý do: hôm nay một trường ở được hai nhà (cột · snapshot); thêm attribute mà vẫn cho
snapshot nhận field mới là dựng **nhà thứ ba** — chính hình dạng P-27/P-28.

### ③ Location + InventoryLevel = **DESIGN ONLY**

Tồn theo kho biến `totalStock`/`variant.quantity` thành **derived projection** (tổng
tồn = tổng theo từng kho). Đó là thay đổi **inventory truth**, không phải thêm một
trường. Triển khai thật phải có **ADR riêng** (§7).

---

## 2. Nguồn của danh sách ứng viên (§3) — minh bạch

Founder Addendum "Commerce Model Extensibility" **không tồn tại thành một file trong
repo**; nó là task order truyền miệng/trên vé. Vì vậy danh sách ứng viên §3 dưới đây
được **tái dựng** từ các nguồn **có thật, kiểm chứng được**, và tài liệu ghi rõ mỗi
trường đến từ đâu để Founder soát:

1. **Bốn va chạm Founder nêu đích danh** trên vé WTM-333: `digitalProduct`,
   `requiresShipping`, `published`, `color`, `size`, `material`, `manufacturer`.
2. **Trường identity Founder nêu đích danh**: `barcode`, `gtin`, `upc`, `ean`, `mpn`.
3. **Thuộc tính theo ngành** liệt kê trên [WTM-335](https://workizen.atlassian.net/browse/WTM-335):
   chất liệu · form · mùa (thời trang) · công suất · điện áp · bảo hành (điện tử) ·
   kích thước · chất liệu (gia dụng) · hạn sử dụng · bảo quản (thực phẩm) · MOQ · lead time.
4. **Cột schema thật hiện có** (`products_table` @ schema **v26**) — xem §3.
5. **Đối chiếu nền tảng** (Magento/Shopify/eBay/Shopee, §11) — chỉ để xác định
   *nên core hay nên dynamic*, **không copy schema**.

> Nếu về sau Founder cấp danh sách §3 chính thức khác, chỉ cần **map** vào ba tầng
> này — quy tắc phân loại (§4) không đổi.

---

## 3. Điểm xuất phát: schema `products_table` thật (v26)

Các cột đã tồn tại (nguồn: `lib/database/tables/products.dart`, `kTongtaiSchemaVersion = 26`):

| Cột | Kiểu | Tầng đã phân loại | Ghi chú |
| --- | --- | --- | --- |
| `id`, `businessId` | TEXT | CORE (identity/tenancy) | PK / FK business |
| `sku` | TEXT | **CORE** | UNIQUE/business; **khoá khớp** khi import lại |
| `name` | TEXT | **CORE** | required |
| `kind` | TEXT | **CORE** | ProductKind (ADR-TON-023) |
| `listPrice` | REAL | **CORE** | doanh thu |
| `costPerUnit` | REAL | **CORE** | lợi nhuận thật; `null` ≠ miễn phí |
| `totalStock` | REAL? | **CORE** | `null` = *không áp dụng* (phi vật lý) |
| `stockAlertLevel` | REAL? | **CORE** | điểm đặt lại → automation |
| `category` | TEXT? | **CORE** | phân nhóm dùng khắp Reports/lọc (đã promote) |
| `supplierId` | TEXT? | **CORE** | FK Producer |
| `salesChannels` | TEXT? (JSON) | **CORE** | kênh bán → order/settlement/automation |
| `isActive` | BOOL | **CORE** | cờ bật/tắt duy nhất (nuốt `published`) |
| `brand` | TEXT? | **CORE** (v24) | nuốt `manufacturer` |
| `externalId` | TEXT? | **CORE** (v24) | khớp dòng vendor khi import |
| `provenanceCode` | TEXT? | **CORE** (v24) | nguồn gốc → audit/automation |
| `importJobId` | TEXT? | **CORE** (v24) | xoá đúng **một** lần import |
| `description` | TEXT? | **OPTIONAL STANDARD** | listing text, FTS-indexed |
| `imageUrl` | TEXT? | **OPTIONAL STANDARD** (v24) | ảnh URL nguồn ngoài |
| `domainSnapshot` | TEXT? (JSON) | *cơ chế*, không phải trường | chỉ giữ `imagePaths` + tương thích ngược (quyết định ②) |
| `createdAt`, `updatedAt` | DATETIME | CORE (audit) | |

Variant (`product_variants_table`, v24) mang `option1Name/Value`, `option2Name/Value` —
**đây là nơi `color`/`size` sống** (§5).

---

## 4. Quy tắc phân loại (§29 của Founder)

> **Chạm** inventory · price · profit · order · settlement · identity · listing
> lifecycle · automation ⇒ **typed core** (CORE hoặc OPTIONAL STANDARD).
> **Chỉ là** phân loại · mô tả · thông số kỹ thuật · metadata ⇒ **dynamic candidate**.

Áp dụng thành cây quyết định:

```
Trường ứng viên X
│
├─ Đã có nguồn sự thật khác trả lời đúng câu hỏi của X?
│     ├─ CÓ → LOẠI (va chạm, §5). X không được thành cột/attribute mới.
│     └─ KHÔNG ↓
│
├─ X chạm một trục §29 (inventory/price/profit/order/settlement/identity/
│  listing-lifecycle/automation)?
│     ├─ CÓ ↓ (typed — cột)
│     │    ├─ Gần như MỌI sản phẩm đều có, hoặc bắt buộc? → CORE
│     │    └─ Chuẩn khắp sàn nhưng THƯA (không phải ai cũng nhập)? → OPTIONAL STANDARD
│     └─ KHÔNG (chỉ phân loại/mô tả/spec/metadata) → DYNAMIC (tầng thuộc tính, WTM-334)
```

**Bẫy "cùng một từ, hai nghĩa"** (chính là hình dạng va chạm `color`): một số từ vừa
là trục core vừa là spec.

- `weight`, **shipping** dimensions (D×R×C để tính cước) → **chạm order/settlement**
  (cước ship) ⇒ **OPTIONAL STANDARD**, không phải DYNAMIC.
- `kích thước` **như thông số hiển thị** (đường chéo màn hình, dung tích) → **spec**
  ⇒ **DYNAMIC**.
  Cùng chữ "kích thước", hai nhà khác nhau — phải phân biệt theo *nó dùng để làm gì*.

---

## 5. Bốn va chạm phải loại — mỗi dòng ghi rõ **vì sao loại**

| Trường bị loại | Nguồn sự thật đã có | Vì sao loại (triệu chứng thật nếu giữ) |
| --- | --- | --- |
| `digitalProduct` · `requiresShipping` | **`ProductKind`** (ADR-TON-023: physical/digital/service; `tracksStock => physical`) | Hai nguồn trả lời *"món này có tồn kho / cần ship không"*. Đúng lỗi đã xảy ra: một phần mềm có `quantity:0` ⇒ Inventory kêu **"Hết hàng"** và Rule Engine **sinh cơ hội nhập hàng cho phần mềm**. `kind` đã là câu trả lời canonical. |
| `published` | **`isActive`** (cột BOOL, đang là cờ bật/tắt duy nhất) | Hai cờ bật/tắt ⇒ không ai biết cờ nào thắng khi lệch. Một listing "unpublished" nhưng `isActive=true` sẽ hiện/ẩn tuỳ màn đọc cờ nào. |
| `color` · `size` · `material` | **variant** `option1/option2` (màu·size là **chiều phiên bản**); `material` khi là spec → **DYNAMIC** | Màu vừa là phiên bản (Đen/S vs Đỏ/M) vừa là "thuộc tính" ⇒ một scalar `color` trên Product **cộng** `option1=Màu` trên variant = **hai kết quả lọc khác nhau** cho cùng câu hỏi *"có bao nhiêu hàng màu đen"*. `color`/`size` sống ở variant option; `material` nếu **biến thiên** → variant option, nếu **cố định** → attribute động; **không bao giờ** là scalar Product. |
| `manufacturer` | **`brand`** (cột v24) | Hai cột tên hãng ⇒ báo cáo *"theo hãng"* tách một hãng thành hai dòng. `brand` đã có. |

> Quy tắc rút ra (đặt tên để lần sau bắt được): **trước khi thêm một trường, hỏi
> "câu hỏi nghiệp vụ của nó đã có nguồn trả lời chưa?"** Nếu rồi ⇒ va chạm ⇒ loại.

---

## 6. Bảng phân loại đầy đủ — CORE / OPTIONAL STANDARD / DYNAMIC

### 6.1 CORE (cột typed, load-bearing) — đã ở §3, tóm tắt trục §29

| Trường | Trục §29 | Lý do là CORE |
| --- | --- | --- |
| `sku`, `externalId` | identity | khoá khớp/dedup khi import |
| `name`, `brand`, `category` | identity/listing | định danh + phân nhóm dùng khắp màn |
| `kind` | inventory/automation | quyết định tồn kho có nghĩa hay không |
| `listPrice`, `costPerUnit` | price/profit | cơ sở doanh thu + lợi nhuận thật |
| `totalStock`, `stockAlertLevel` | inventory/automation | tồn + điểm đặt lại (Rule Twin) |
| `supplierId`, `salesChannels` | order/sourcing/settlement | nhập ở đâu, bán kênh nào |
| `isActive` | listing lifecycle | bật/tắt bán |
| `provenanceCode`, `importJobId` | automation/audit | nguồn gốc + xoá-một-lần-import |

### 6.2 OPTIONAL STANDARD (cột typed **nullable**, chuẩn khắp sàn, vẫn chạm §29)

| Trường | Có cột chưa | Trục §29 | Lý do typed (không để dynamic) | `null` nghĩa là |
| --- | --- | --- | --- | --- |
| `gtin` (ô dù GTIN) | **chưa — đề xuất thêm** | identity | Khớp một dòng vendor với sản phẩm đã có lúc import. **GTIN là ô dù**; UPC/EAN chỉ là cách mã hoá của nó (12/13 số), MPN là mã hãng. ⇒ **một cột `gtin`** (+ tuỳ chọn `mpn` nếu cần), **không** năm cột. | chưa có mã, không phải "không có hàng" |
| `weight` | chưa | order/settlement | Cước ship phụ thuộc khối lượng ⇒ chạm settlement, không phải spec thuần. | chưa cân |
| `shippingLength/Width/Height` (hoặc gộp `shippingDims`) | chưa | order/settlement | Dimensional weight ⇒ cước. **Khác** "kích thước hiển thị" (spec, DYNAMIC). | chưa đo |
| `description` | ✅ | listing | text mô tả listing, đã FTS-index | chưa viết |
| `imageUrl` | ✅ (v24) | listing | ảnh URL nguồn ngoài | chưa có ảnh URL |
| `tags` | chưa | listing/automation | Nhãn tự do điều khiển lọc/nhóm listing + luật automation (chuẩn ở mọi sàn). **Chạm automation ⇒ typed**, dù trông giống metadata. | chưa gắn nhãn |
| `unit` / đơn vị tính (uom) | chưa | inventory/price | Đơn vị đếm tồn + đơn vị giá; nếu có, ảnh hưởng cách cộng tồn. *(cần Founder xác nhận có làm MVP không — §9)* | dùng "cái" mặc định |

> ⛔ **Không** biến GTIN thành năm cột `barcode/gtin/upc/ean/mpn`. Một sản phẩm một
> GTIN; các "chuẩn" kia là **encoding** của cùng một số.

### 6.3 DYNAMIC (tầng thuộc tính động — WTM-334)

Trường **phân loại/mô tả/spec/metadata theo ngành**, **thưa** (mỗi ngành một bộ). Lưu
bằng `attribute_definitions` + `attribute_values`, **chín kiểu** (`TEXT · INTEGER ·
DECIMAL · BOOLEAN · DATE · DATETIME · ENUM · MULTI_ENUM · URL`), namespace
`system.*`/`user.*`/`vendor.<tên>.*`, **tải on-demand ở màn chi tiết** (⛔ không join
vào danh sách/summary/Capability Context — luật hiệu năng ADR-TON-019).

| Trường (ví dụ §3) | Ngành | Kiểu MVP | Vì sao DYNAMIC (không typed) |
| --- | --- | --- | --- |
| `material` (chất liệu, khi cố định) | thời trang · gia dụng | ENUM/TEXT | spec/phân loại; không chạm price/order/inventory |
| `form` / kiểu dáng · `mùa` (season) | thời trang | ENUM | phân loại marketing |
| `công suất` (W) · `điện áp` (V) | điện tử | DECIMAL/INTEGER | thông số kỹ thuật |
| `bảo hành` (tháng) | điện tử | INTEGER | metadata, không chạm settlement của **người bán** |
| `dung tích` · `kích thước hiển thị` | gia dụng · điện tử | DECIMAL/TEXT | spec (khác **shipping** dims ở §6.2) |
| `hạn sử dụng` · `bảo quản` | thực phẩm | DATE / TEXT | metadata theo lô/loại |
| `vendor.<tên>.*` (Shopify metafield, eBay item specifics) | bất kỳ (từ import) | theo map | raw vendor → dynamic; **không** tự thành `system.*` |

**Ranh giới quan trọng — nhóm hiển thị ≠ nơi lưu.** WTM-335 §18 gom hiển thị theo
nhóm (General · Inventory · Shipping · Sourcing · Marketplace · Fashion · Electronics
· Custom). Ví dụ nhóm **"Nhập hàng"** hiện `MOQ` · `Lead time` — nhưng **hai trường
này KHÔNG phải attribute động**: chúng là cột typed trên `supplier_quotes_table`
(v24). Vậy: *màn chi tiết trộn hiển thị **trường typed** và **attribute động** dưới
cùng một nhóm cho người bán dễ đọc, nhưng **tầng thuộc tính chỉ lưu giá trị DYNAMIC***.
Nhóm là view; đừng để nhóm hiển thị kéo dữ liệu core vào EAV.

---

## 7. Thực thể §4 — phân loại đã chốt

| Thực thể | Quyết định | Lý do |
| --- | --- | --- |
| **Media** | Thực thể nhỏ, **làm sớm được** (WTM-334 nếu gọn) | Nó **retire** `imagePaths` khỏi `domainSnapshot` ⇒ hoàn tất nửa còn lại của quyết định ②. Ảnh cục bộ (người bán tự chụp) tách khỏi `imageUrl` (URL nguồn ngoài) — trộn hai nguồn sẽ làm một lần import lại **xoá mất ảnh tự thêm**. |
| **ChannelAccount** | ⚠️ **HỢP NHẤT với `Connection`** (`connections_table`, v18) — **không** tạo account model thứ hai | `Connection` đã mang `connectorId` + `label` (cho phép nhiều tài khoản/nền tảng) + `status` + `lastSyncAt`. "Tài khoản kênh bán" chính là một `Connection`. Tạo `ChannelAccount` riêng = nhà thứ hai cho *"tài khoản sàn nào"*. **Cấm cột token** — khoá tra credential suy từ `id` (luật credential Founder). |
| **Listing** | **DESIGN ONLY** tới khi có connector sync thật | Một Listing = sự hiện diện của một Product trên **một kênh** với giá/tồn/trạng thái **riêng theo kênh**. Chưa có sync thật thì Listing không có nguồn dữ liệu để đúng ⇒ chỉ thiết kế, chưa bảng. |
| **Location · InventoryLevel** | **DESIGN ONLY**, **ADR riêng** (quyết định ③) | Tồn theo kho biến `totalStock` thành **derived projection** (∑ theo kho) — đổi **inventory truth**, không phải thêm trường. Rủi ro cao (chạm Rule Twin tồn kho) ⇒ tách ADR. |

---

## 8. Quan hệ với WTM-334 và WTM-335 (bàn giao)

- **WTM-333 (đây)** chốt **trường nào ở tầng nào** + amend ADR-TON-009. Không code.
- **WTM-334 (B)** xây tầng DYNAMIC: `attribute_definitions/values/groups/group_items`,
  9 kiểu, namespace 3 nguồn, governance (trùng code, che khuất core field
  `price/sku/quantity/cost_price/status/kind`, orphan, restore mất thuộc tính…),
  tải on-demand. **Chỉ nhận trường đã phân loại DYNAMIC ở §6.3.**
- **WTM-335 (C)** làm giàu dataset + hiển thị nhóm (§6.3, ranh giới "nhóm hiển thị ≠
  nơi lưu"). Chỉ đọc; chưa có màn "Thêm thuộc tính".

> **⚠️ Ghi chú schema (bắt lệch vé-vs-thực-tế cho WTM-334/335):** vé WTM-334 viết
> *"schema v25, migration v24→v25"* và WTM-335 nhắc *"§15"* — nhưng head hiện tại đã
> là **v26**. Migration tầng thuộc tính thật sự sẽ là **từ v26 trở lên** (v26→v27…),
> cộng thêm, không phá v24/v25/v26 đã phát hành. Đây là lưu ý cho Developer khi nhận
> WTM-334, **không** đổi phân loại của tài liệu này.

---

## 9. Điểm cần Founder xác nhận (non-blocking — tài liệu additive, sửa được)

Phân loại dưới đây **đủ chắc để WTM-334 khởi động**; ba điểm ranh giới mềm, ghi ra để
Founder chỉnh nếu muốn — **không chặn**:

1. **`tags`** xếp OPTIONAL STANDARD (typed) vì chạm automation/listing. Nếu Founder coi
   tags thuần marketing ⇒ chuyển DYNAMIC (`MULTI_ENUM`). Khuyến nghị: **giữ typed** —
   automation cần query nhanh, EAV thì không.
2. **`unit`/đơn vị tính** có vào MVP không? Nếu doanh nghiệp hiện tại đều bán theo
   "cái", có thể hoãn. Khuyến nghị: **hoãn** tới khi có nhu cầu thật (bán theo kg/mét).
3. **GTIN**: thêm **một** cột `gtin` OPTIONAL STANDARD ngay (identity, giúp import khớp),
   hay chờ có connector? Khuyến nghị: **thêm cột `gtin` sớm** — nó là khoá khớp, rẻ,
   và tránh nhét mã vạch vào attribute động (che khuất identity).

---

## 10. Đối chiếu nền tảng (chỉ để phân loại — KHÔNG copy schema)

| Nền tảng | Core (typed) | Dynamic/spec |
| --- | --- | --- |
| **Shopify** | product/variant (option1-3), price, inventory, SKU, barcode(GTIN), status | **metafield** (namespace.key, typed) |
| **Magento** | SKU, price, qty, status, website | **custom attribute** + attribute set/group; configurable = variant |
| **eBay** | inventory item (SKU, qty), offer (price), condition | **item specifics** (aspect/value) |
| **Shopee/TikTok** | item, model (=variant), price, stock | **product attributes** theo category |

Bốn sàn đều tách **hai tầng y hệt**: một lõi giao dịch typed + một tầng thuộc tính
mở rộng (metafield/custom attribute/item specifics/product attributes). Mô hình
CORE/OPTIONAL-STANDARD/DYNAMIC ở trên **khớp mẫu ngành**, và variant tách khỏi
attribute đúng như cả bốn sàn.

---

## 11. Definition of Done (WTM-333)

- [x] `docs/05-DATA/COMMERCE-ATTRIBUTE-MODEL.md` (tài liệu này)
- [x] Amendment vào `ADR-TON-009` + cập nhật `ADR-INDEX.md`
- [x] Bảng phân loại đầy đủ, **mỗi dòng có lý do** (§5, §6)
- [x] Bốn va chạm ghi rõ **vì sao loại** (§5)
- [x] Thực thể §4 phân loại (§7)
- [x] Không một dòng code

---

### Phụ lục — nguồn dữ liệu (kiểm chứng)

- Schema v26: `lib/database/tables/products.dart`, `lib/database/tables/product_variants.dart`,
  `lib/database/tables/connections.dart`, `lib/database/migrations/tongtai_migrations.dart`.
- ProductKind: `lib/features/tongtai/inventory/product.dart` + ADR-TON-023.
- Snapshot: ADR-TON-009 (+ Amendment 2 kèm PR này).
- Dataset & nhóm: `docs/05-DATA/COMMERCE-DEMO-DATASET.md`, `docs/05-DATA/TRUE-PROFIT-AND-SOURCING.md`, WTM-335.
