# Vendor Catalog — AI **đọc** catalog, và "nên dùng" là kết quả tính

> **WTM-287 · N1 · Epic WTM-284 (Platform Wave 2).** Ngày **2026-08-07**.
> Thiết kế + dữ liệu ban đầu. **Không** gọi API, **không** OAuth.

Luật của Founder: *"KHÔNG hardcode trong AI. AI phải đọc Catalog."*

---

## ⭐ Điểm thiết kế quyết định: `recommended` phải được SUY RA

Một cờ `recommended: true` gán bằng tay là **một ý kiến đội lốt dữ liệu**. Nó
làm AI nói *"nên dùng X"* mà không ai truy được vì sao, và nó là đúng họ lỗi
P-27/P-28 đã lặp bốn lần trong repo này: một trường được lưu, trong khi lẽ ra
nó phải được tính.

⇒ `recommended` là **hàm thuần** trên các trường còn lại, công thức viết ra ở
đây, và **không bao giờ được ghi xuống đĩa**.

```
recommended(v) =
    v.productionReady
    ∧ v.verification ≥ tried            // xem §Trạng thái xác minh
    ∧ (v.freeTier ∨ v.pricing = usage_based)
    ∧ (v.officialApi ∨ v.n8nNode)
    ∧ (v.region ∋ 'VN' ∨ v.vietnamSupport)
    ∧ ¬v.requiresAnnualAudit            // Gmail CASA là lý do dòng này tồn tại
```

Ai không đồng ý với gợi ý thì sửa **công thức**, không sửa từng dòng — và sửa
công thức là một thay đổi nhìn thấy được trong PR.

---

## Trường

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `name` · `category` · `region` | | `category` dùng chung từ vựng với Capability Matrix |
| `officialApi` · `oauth` · `apiKey` · `mcp` · `webhook` · `polling` · `sdk` | bool | cách kết nối |
| `n8nNode` · `communityNode` | bool | community node ≠ chính thức — rủi ro bảo trì |
| `pricing` | enum | `free` · `usage_based` · `subscription` · `enterprise` |
| `freeTier` | bool | |
| `popularity` | enum | `high` · `medium` · `low` — ở **thị trường Việt Nam**, không toàn cầu |
| `vietnamSupport` | bool | có hỗ trợ/tài liệu/thanh toán VN |
| `productionReady` | bool | API ổn định, có versioning |
| `requiresAnnualAudit` | bool | ⚠️ thẩm định hằng năm (Gmail CASA) |
| **`verification`** | enum | ⭐ xem dưới |
| `recommended` | *(dẫn xuất)* | **không lưu** |

---

## ⭐ `verification` — bài học đã trả giá

| Mức | Nghĩa |
|---|---|
| `documented` | đọc từ tài liệu nhà cung cấp |
| `tried` | đã dựng thử, thấy nó chạy |
| `production` | đã chạy thật trên dữ liệu Workizen |

**Vì sao trường này tồn tại:** bảng vendor cũ (WTM-252/271) ghi GitHub là
*"OAuth device flow · n8n có node sẵn"*. **Sai cả hai**, và chỉ lộ ra khi dựng
connector thật (WTM-268):

| Ghi trong catalog | Thực tế |
|---|---|
| OAuth device flow | **PAT chỉ-đọc** — hẹp hơn *và* đơn giản hơn |
| n8n có node sẵn ✅ | **không dùng được** — node có sẵn không phân trang theo cách cần |

Hai ô sai **đều lệch cùng một hướng**: lạc quan hơn thực tế. Đó không phải ngẫu
nhiên — tài liệu nhà cung cấp viết để bán, nó nói cái gì *có thể* làm được,
không nói cái gì *nên* làm.

⇒ Một dòng `documented` **không đủ** để `recommended`. Phải ít nhất `tried`.

---

## Dữ liệu ban đầu (rút gọn — bản đầy đủ trong module)

| Vendor | Category | Kết nối | VN | Verification | Ghi chú |
|---|---|---|:--:|---|---|
| **GitHub** | dev | PAT chỉ-đọc · polling | — | **production** | connector đầu tiên chạy thật (WTM-268/274) |
| **Telegram** | chat | bot token · long-poll | ✅ | `documented` | rẻ nhất để thử: tự tạo bot, không ai duyệt |
| **Shopee** | commerce | Partner API · OAuth2 · webhook | ✅ | `documented` | cần hồ sơ doanh nghiệp — xem `19-INTEGRATION-SANDBOX` |
| **TikTok Shop** | commerce | Partner API · OAuth2 · webhook | ✅ | `documented` | như Shopee |
| **Shopify** | commerce | Admin API · custom app token | — | `documented` | dev store tự tạo được |
| **Stripe** | payment | secret key · webhook | — | `documented` | cần backend cho webhook |
| **RevenueCat** | payment | v2 API · webhook | — | `tried` | workflow đã dựng rồi **gỡ** — app chưa lên store |
| **Gmail** | comms | OAuth **restricted** | ✅ | `documented` | ⚠️ `requiresAnnualAudit` — CASA $500–4.500/năm ⇒ **khuyến nghị Share Sheet thay API** |
| **GA4 · Search Console** | analytics | OAuth2 | — | `documented` | tự đăng ký được |
| **Facebook / Messenger** | comms | Graph API · OAuth2 | ✅ | `documented` | cần App Review |

---

## Nơi ở — và vì sao không nằm trong prompt AI

Catalog là **tài sản có version**, ship kèm app và cập nhật được, đọc qua một
repository như mọi dữ liệu khác.

Nằm trong prompt AI thì: không truy vấn được · không test được · mỗi lần sửa
phải đổi mã · và AI sẽ "nhớ" phiên bản cũ khi nội dung đổi. Đúng ranh giới
ADR-TON-016: **Rule Twin có thẩm quyền, AI chỉ giải thích** — catalog là dữ
liệu của Rule Twin, không phải kiến thức của AI.

---

## Đã cài đặt — WTM-293 (2026-08-07)

`lib/features/tongtai/platform/vendor_catalog.dart`. **Không bảng, không
migration**: catalog là **kiến thức của app**, không phải dữ liệu người bán.
Lưu nó vào SQLite sẽ sinh ra một bản sao cũ trên máy mỗi người, và mỗi lần sửa
catalog lại thành một migration.

### `recommended` là getter, và nó nói cả LÝ DO

Ngoài `recommended` (đúng công thức ở trên), có thêm `notRecommendedBecause`
trả về danh sách mã lý do:

```
api_not_production_ready · never_tried · no_free_entry ·
no_official_integration_path · no_vietnam_support · requires_annual_audit
```

Đây là thứ một cờ gán tay không bao giờ cho được: một cờ nói *"không"*, còn cái
này nói *"không, vì ba lý do sau"* — và người đọc sửa được đúng chỗ.

Ví dụ thật: Gmail bị loại vì `requires_annual_audit`, **không** vì thiếu đường
tích hợp. Đường có; giá mới là vấn đề. Test khoá đúng phân biệt đó.

### Khoá bằng governance

`test/features/tongtai/p0/catalog_is_data_governance_test.dart`:

| Kiểm gì | Vì sao |
|---|---|
| `bool get recommended` tồn tại, **không** có `final bool recommended` hay `this.recommended` | một trường là ý kiến đội lốt dữ liệu |
| **không bảng nào** trong `lib/database/tables/` chứa chữ `recommended` | đường ghi xuống đĩa là chỗ giá trị dẫn xuất thành nguồn sự thật thứ hai |
| catalog không import drift/database/workspace | nó không được có tay để ghi |

Phép quét bảng có chống PASS GIẢ: `expect(scanned, greaterThan(10))` — thư mục
rỗng thì vòng lặp không chạy và test xanh oan.
