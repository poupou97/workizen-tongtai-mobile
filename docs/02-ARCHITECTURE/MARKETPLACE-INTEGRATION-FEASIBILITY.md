# Tích hợp sàn — cái nào làm được, cái nào không

> WTM-441 (Epic WTM-440) · 2026-08-22 · trả lời yêu cầu cuối tuần của Founder.
> Mọi ô trong tài liệu này có bằng chứng: đường dẫn file, hoặc trang tài liệu
> của chính nền tảng. Chỗ nào không kiểm được thì ghi `TBD`, không đoán.

## 0. Kết luận trước, lý lẽ sau

**Đường File Bridge cho file xuất từ sàn ĐÃ ĐƯỢC DỰNG VÀ ĐÃ MERGE.** Không phải
kế hoạch — là code đang chạy trong bản Founder cầm trên tay.

```
lib/features/tongtai/commerce/import/
├── marketplace_export_source.dart   ← đọc file Seller Centre → CustomerOrder + SettlementLine
├── marketplace_profile.dart         ← hồ sơ nhận dạng cột: shopee · tiktok_shop
├── xlsx_reader.dart · xlsx_commerce_source.dart
├── commerce_source_resolver.dart    ← đoán file này là loại gì
└── commerce_importer.dart
lib/features/tongtai/ui/screens/tongtai_import_screen.dart   ← màn nhập
```

⇒ **Thêm một sàn = thêm một `MarketplaceProfile`** — thêm *dữ liệu*, không phải
dựng *kiến trúc*. Đó là việc cỡ cuối tuần.

**Đường API (điều Founder hỏi ở P1) thì không.** Cả ba sàn P1 đều đòi tài khoản
nhà phát triển Founder phải tự mở, cộng một **URL callback HTTPS** — tức là
chạm quyết định **D-1** đang treo từ 2026-08-02.

---

## 1. Bảng khả thi

| Nền tảng | Cần tài khoản gì | Ai mở được | Cần điểm HTTPS? | File Bridge |
|---|---|---|---|---|
| **Shopee** | `open.shopee.com` + xác minh nhà phát triển → Partner ID/Key | **Founder** | ✅ callback OAuth | ✅ **hồ sơ đã có** |
| **eBay** | eBay Developers Program → Application Keys → **RuName** | **Founder** | ✅ RuName gói accept/decline URL + **URL chính sách quyền riêng tư** | ❌ chưa có hồ sơ |
| **Amazon** | **Professional selling account** + primary user + developer profile + xác minh danh tính | **Founder** | ✅ và app công khai còn cần **website công khai** | ❌ chưa có hồ sơ |
| **Alibaba/1688** | `TBD` — chưa kiểm | `TBD` | `TBD` | ❌ chưa có hồ sơ |
| **Logistics** | tuỳ hãng | `TBD` | `TBD` | ❌ |
| **Shopify** | Partner account + app | **Founder** | ✅ | ❌ chưa có hồ sơ |

### Ba điều khiến P1 không thể xong cuối tuần

1. **Amazon duyệt vai trò tới 10 ngày làm việc**, và app công khai với
   restricted role còn phải qua *architecture review* của đội SP-API. Đây là
   đồng hồ bên ngoài — không rút ngắn được bằng cách code nhanh hơn.
2. **eBay đòi URL chính sách quyền riêng tư** trong RuName khi dùng User access
   token. `docs/05-OPERATIONS/PRIVACY-POLICY.md` có, nhưng **chưa được host công
   khai ở đâu** — nên đây là việc thật, không phải thủ tục.
3. **Cả ba đều cần một điểm cuối HTTPS nhận callback.** Tổng Tài **chưa có** —
   và dựng nó chính là quyết định **D-1** (*Optional Integration Runtime*) mà
   `INTEGRATION-ROADMAP-AND-DECISIONS.md §5` đang chờ Founder.

---

## 2. Nền N0 — đã xong nhiều hơn tài liệu cũ nói

`INTEGRATION-ARCHITECTURE-BASELINE.md` (2026-08-02) kết luận *"không bản ghi nào
biết mình từ đâu ra"*. **Điều đó đã hết đúng.**

| N0 | Roadmap nói | Kiểm 2026-08-22 |
|---|---|---|
| 1 · Provenance | chưa có | ✅ `ProvenanceSource{manual,sample,derived,connector,fileBridge}`; `provenanceCode` trên `orders`, `supplier_quotes`, `payouts`; bảng `import_jobs` |
| 2 · Connection + credentialRef | chưa có | ✅ `connections.dart` · `connection_credential_store.dart` · `connection_catalog.dart` |
| 3 · CustomerIdentity + confidence | chưa có | ✅ bảng `external_identities` |
| 4 · Fee/Refund/Payout gắn Order | chưa có | ✅ bảng `payouts` · `settlement.dart` · `SettlementLine` |
| — | `integrations_table` chết | ✅ **đã gỡ** ở schema **v18** (WTM-283) — xem đính chính bên dưới |

> ### ⚠️ Đính chính 2026-08-22 — bản đầu của tài liệu này ghi SAI
>
> Bản đầu viết *"`integrations_table` vẫn chết — D-2 chưa thi hành"*. **Sai.**
> `tongtai_migrations.dart:588` chạy `DROP TABLE IF EXISTS integrations_table`
> ở bước v18, và `tables/connections.dart:7` nói thẳng nó **thay** bảng ấy.
> ⇒ **Quyết định D-2 đã được thi hành**, không còn chờ Founder.
>
> Sai vì đâu: tôi `grep` `integrationsTable` trong `lib/`, thấy **rỗng**, rồi
> đọc kết quả rỗng ấy thành *"bảng còn đó mà không ai dùng"*. Sự thật là
> *"bảng không còn"*. Cùng một dấu hiệu, hai kết luận trái ngược — và tôi chọn
> cái khớp với thứ tài liệu cũ đã nói.
>
> Đây là **lần thứ tư trong ngày** cùng một hình dạng: một phép đo trả lời
> chính xác câu hỏi của nó, không phải câu tôi tưởng mình đang hỏi (P-45,
> P-46). Chữa nó không phải bằng grep cẩn thận hơn, mà bằng **đo lần thứ hai
> bằng thứ khác** — ở đây là đọc chuỗi migration thay vì đếm chỗ tham chiếu.

⇒ Điều kiện *"bốn thứ phải xong trước connector đầu tiên"* **đã thoả**. Cản trở
còn lại không phải kiến trúc, mà là **tài khoản và một điểm HTTPS**.

---

## 3. Rủi ro lớn nhất, và nó rẻ đến bất ngờ

`marketplace_profile.dart:7`, tác giả tự khai:

> ⚠️ **Tôi KHÔNG có file thật của Shopee/TikTok.** Tên cột dưới đây đến từ tài
> liệu và từ các bản xuất công khai, **chưa đối chiếu với một file thật.**

Hai hồ sơ đang có là **giả định chưa kiểm**. Thiết kế đã lường trước — nhận dạng
theo điểm số trên nhiều bí danh, và khi trượt thì **báo đúng những cột nó nhìn
thấy** thay vì nói *"không đọc được"*. Nhưng lường trước không thay được kiểm.

**Một file xuất thật từ Shopee biến hai hồ sơ đoán thành hồ sơ đã kiểm.** Đó là
hành động rẻ nhất và có sức nặng nhất trong cả tài liệu này — và nó không cần
tài khoản nhà phát triển nào, chỉ cần một người bán bấm *Xuất Excel*.

### Cảnh báo đi kèm: hai file, không phải một

| File | Cho gì |
|---|---|
| Đơn hàng | doanh thu · khách · sản phẩm |
| **Báo cáo thu nhập** | **phí sàn · hoa hồng · vận chuyển · voucher · payout** |

Chỉ nhập file đơn ⇒ **doanh thu đúng mà lợi nhuận sai theo hướng tâng bốc**
(R2 trong Risk Register). Đó là con số nguy hiểm nhất app có thể in ra, vì nó
sai theo hướng không ai đi kiểm.

---

## 4. Đề xuất thứ tự — KHÁC thứ tự Founder nêu, và đây là lý do

Founder xếp: `P1 sàn bán (API) → P2 nguồn hàng → P3 logistics → P4 storefront`.

Thứ tự ấy đúng về **giá trị kinh doanh**. Nó chỉ vướng ở chỗ P1 có một đồng hồ
bên ngoài mà ta không điều khiển được. Nên đề xuất **giữ nguyên ưu tiên, đổi
đường đi**:

| Nhịp | Làm gì | Chặn bởi |
|---|---|---|
| **W1 — cuối tuần này** | Thêm hồ sơ File Bridge: **eBay · Amazon · Shopify · Lazada**; củng cố báo lỗi khi cột lệch | không gì |
| **W2 — cuối tuần này, nếu có file** | Đối chiếu hồ sơ Shopee với **file xuất thật** | Founder gửi 1 file |
| **W3 — song song, việc của Founder** | Mở tài khoản nhà phát triển 3 sàn; host chính sách quyền riêng tư | Founder |
| **W4 — tuần sau** | Connector API sàn đầu tiên | D-1 + tài khoản W3 |

**W3 nên bắt đầu NGAY hôm nay**, không phải vì gấp về code, mà vì đồng hồ duyệt
của Amazon chạy bằng ngày làm việc — mở tài khoản chiều nay hay chiều mai chênh
nhau cả một tuần ở đầu kia.

---

## 5. Quyết định đang chờ Founder — và cái nào giờ đã cấp bách

Từ `INTEGRATION-ROADMAP-AND-DECISIONS.md §5`, treo từ 2026-08-02:

| # | Quyết định | Giờ ra sao |
|---|---|---|
| **D-1** | Dựng Optional Integration Runtime? | 🔴 **CHẶN P1** — không có nó thì không có callback OAuth |
| **D-5** | Thêm `amazon/ebay/shopify/…` vào `SalesChannel` ngay? | 🔴 **CHẶN W1** — yêu cầu cuối tuần chạm thẳng vào đây |
| D-2 | Xoá `integrations_table` chết | 🟡 nên làm cùng W1 |
| D-3 · D-4 · D-6 | — | 🟢 không chặn cuối tuần |

`SalesChannel` hiện có: `shop · market · shopee · tiktok · facebook · zalo ·
wholesale · website · app_store · direct`. **Không có** `ebay` · `amazon` ·
`shopify` · `lazada`.

Đề xuất cũ của D-5 là *"chưa thêm — tách Channel/Store trước, thêm mã sau, kẻo
migrate hai lần"*. Yêu cầu của Founder khiến nó thành câu hỏi phải trả lời ngay:
**thêm mã bây giờ và chấp nhận migrate lần hai, hay tách cấu trúc trước rồi mới
thêm?**

---

## 6. Điều tài liệu này KHÔNG kết luận

* Không kiểm Alibaba/1688 và logistics — `TBD`, chưa đủ dữ liệu.
* Không đăng ký tài khoản nào, không tạo app trên cổng nhà phát triển nào,
  không đụng khoá — đúng ràng buộc G-3.
* Không khẳng định điều khoản dịch vụ của sàn cho phép hay cấm cách lấy dữ liệu
  nào ngoài file người bán tự xuất. **Không scraping** (R9).
