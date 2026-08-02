# Integration Roadmap · Priority Scoring · Risk Register · Founder Decisions

> **WTM-246 · Wave 1 của Epic WTM-238.** Founder: *"Không ưu tiên vì nền tảng
> nổi tiếng. Ưu tiên vì mở khoá use case thật."*

---

## 1. Chấm điểm connector (12 tiêu chí mục IX)

Thang 0–3 mỗi tiêu chí; rủi ro tính **điểm trừ**. Tối đa 27.

| Connector | Dogfood | SME phổ thông | Dễ nối | API chính thức | Không cần backend | File Bridge được | Mở khoá capability | Tạo Business Loop | Tạo doanh thu | −Pháp lý | −Token | −Vận hành | **Tổng** |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| **RevenueCat** | 3 | 1 | 2 | 3 | 0 | 1 | 3 | 3 | 3 | 0 | −2 | −1 | **19** |
| **App Store Connect** | 3 | 1 | 2 | 3 | 3 | 3 | 2 | 2 | 2 | 0 | −2 | 0 | **19** |
| **Google Play Console** | 3 | 1 | 2 | 3 | 3 | 3 | 2 | 2 | 2 | 0 | −2 | 0 | **19** |
| **Telegram** | 2 | 3 | 3 | 3 | 3 | 0 | 2 | 3 | 1 | 0 | −1 | 0 | **19** |
| **GitHub** | 3 | 0 | 3 | 3 | 3 | 1 | 1 | 1 | 0 | 0 | −1 | 0 | **14** |
| **GA4** | 2 | 2 | 2 | 3 | 3 | 1 | 2 | 1 | 0 | −1 | −1 | 0 | **14** |
| **Search Console** | 2 | 2 | 2 | 3 | 3 | 1 | 1 | 1 | 0 | −1 | −1 | 0 | **13** |
| **Gumroad** | 1 | 1 | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 0 | −1 | 0 | **18** |
| **WooCommerce/Shopify** | 0 | 3 | 2 | 3 | 3 | 2 | 3 | 3 | 3 | 0 | −1 | 0 | **21** |
| **Gmail** | 2 | 3 | 1 | 3 | 2 | 1 | 2 | 2 | 0 | **−3** | −2 | **−3** | **8** |

**Đọc bảng này:**

* **WooCommerce/Shopify điểm cao nhất (21)** dù Workizen chưa có cửa hàng — vì
  nó ghi điểm tối đa ở *"SME phổ thông"* và *"tạo doanh thu"*. Đây chính là điều
  Founder dặn: chấm theo use case mở khoá, không theo mức quen thuộc.
* **Gmail thấp nhất (8)** dù ai cũng dùng Gmail — chi phí CASA hằng năm và rủi
  ro định vị kéo tụt ba tiêu chí trừ.
* Bốn cái **19 điểm bằng nhau** nhưng khác bản chất: RevenueCat mở doanh thu
  (cần Runtime), hai Store rẻ và an toàn (File Bridge), Telegram là kênh chạm
  người dùng cuối rẻ nhất.

---

## 2. Roadmap đề xuất — bốn nhịp

| Nhịp | Làm gì | Vì sao thứ tự này |
|---|---|---|
| **N0 — Nền** (bắt buộc trước mọi connector) | `Provenance` · `Connection` + `CredentialReference` · `CustomerIdentity(confidence)` · `Fee/Refund/Payout` gắn Order | Thiếu bốn thứ này thì **mỗi connector tự chế một cách riêng** (P-27). Đây là việc **trong app**, không cần mạng, làm được ngay |
| **N1 — Rẻ và an toàn** | App Store Connect + Play Console qua **File Bridge** | Không bí mật nào rời chỗ, không backend, dữ liệu thật cho Founder ngay. Kiểm luôn N0 bằng dữ liệu thật |
| **N2 — Doanh thu** | RevenueCat qua **Optional Integration Runtime** tối thiểu | Việc backend **đầu tiên và duy nhất** của Wave 1. Làm sau N1 để N0 đã được kiểm bằng đường rẻ trước |
| **N3 — Người dùng cuối** | Telegram (device-direct) · Website/WooCommerce khi có | Telegram mở Business Loop cho SME Việt; Woo là điểm cao nhất bảng chấm |

**Cố ý để lại:** GitHub/GA4/Search Console (giá trị dogfood, không mở khoá
capability cho SME) · Gmail (thay bằng Share Sheet) · toàn bộ Wave 2–5.

---

## 3. MVP Spike Plan — hai connector đầu

### Spike A · App Store Connect + Play Console (File Bridge)

* **Mục tiêu:** một file báo cáo thật → `Order`/`Subscription` có `provenance`.
* **Xong khi:** người bán chọn file, thấy **preview** trước khi ghi, số khớp với
  cổng nhà phát hành, và **huỷ được cả mẻ** (`batchId`).
* **Không làm:** không tự động tải, không lưu credential, không ghi ngược.
* **Rủi ro đã biết:** Google **đổi cột báo cáo từ 7/2026** ⇒ parser khớp chuỗi
  chính xác sẽ vỡ ⇒ phải là `TongtaiFailure` có tên, không phải crash.

### Spike B · RevenueCat (Optional Integration Runtime)

* **Mục tiêu:** một service Cloud Run nhận webhook, đẩy **sự kiện đã chuẩn hoá**
  về app.
* **Xong khi:** app **tắt runtime vẫn đủ chức năng lõi** — kiểm bằng **test**,
  không bằng lời hứa.
* **Không làm:** không lưu dữ liệu doanh nghiệp trên mây, không tài khoản người
  dùng, không đồng bộ nhiều thiết bị.

---

## 4. Risk Register

| # | Rủi ro | Mức | Giảm thiểu |
|---|---|---|---|
| R1 | Token nền tảng lọt vào `.ttbk` (bảng `integrations_table` có sẵn 4 cột token; `.ttbk` **mặc định không mã hoá**; đã có sự cố gửi nhầm lên Zalo 31/7) | **Cao** | Luật Founder: bí mật ở Keystore, DB chỉ giữ tham chiếu. **Thêm test governance chặn** — không dựa vào trí nhớ |
| R2 | Import đơn thiếu phí ⇒ **doanh thu đúng, lợi nhuận sai** theo hướng dễ chịu | **Cao** | N0 làm `Fee/Refund/Payout` trước N1 |
| R3 | Gộp nhầm hai khách thành một khi nối đa kênh | **Cao** | `CustomerIdentity.confidence`; dưới ngưỡng thì **hỏi người bán**, không tự gộp |
| R4 | Dữ liệu cũ trông như dữ liệu mới ⇒ AI nói sai một cách tự tin | Trung bình | `freshness` per-source, hiện trên màn |
| R5 | Optional Runtime lặng lẽ phình thành Core Backend | Trung bình | Bốn ràng buộc trong [MANAGED-STACK-EVALUATION](MANAGED-STACK-EVALUATION.md); test "tắt runtime app vẫn chạy" |
| R6 | Nền tảng đổi định dạng/điều khoản (Play đã đổi 7/2026) | Trung bình | Parser không khớp chuỗi cứng; lỗi có tên |
| R7 | Chi phí CASA hằng năm nếu chạm restricted scope | Trung bình | Không dùng Gmail API cho sản phẩm |
| R8 | Rate limit / khoá tài khoản khi polling | Thấp | Nhịp hằng ngày là đủ; tôn trọng `Retry-After` |
| R9 | ToS cấm cách lấy dữ liệu | Thấp–TB | **Không scraping.** Nền tảng không có API ⇒ File Bridge hoặc bỏ |

---

## 5. Founder Decisions Needed

| # | Quyết định | Tôi đề xuất | Vì sao cần anh |
|---|---|---|---|
| **D-1** | Có dựng **Optional Integration Runtime** cho RevenueCat không? | **Có** — 1 service Cloud Run, trong hạn mức miễn phí | Đây là lần đầu Tổng Tài có thành phần chạy ngoài máy người dùng |
| **D-2** | Xử lý `integrations_table` chết | **Xoá**, viết lại thành `Connection` không cột token | Đụng schema (v17) và một bảng có từ bootstrap |
| **D-3** | Làm **N0 (bốn thứ nền)** trước, hay làm connector trước cho nhanh thấy kết quả? | **N0 trước** | Đi ngược lại cảm giác "muốn thấy dữ liệu ngay"; là đánh đổi tốc độ, anh nên biết |
| **D-4** | Gmail: chốt **Share Sheet**, không dùng Gmail API cho sản phẩm? | **Chốt** | Đóng một hướng sản phẩm; nếu sau này cần thì mở lại bằng ADR |
| **D-5** | Có thêm `lazada/amazon/ebay/etsy/shopify/woocommerce` vào `SalesChannel` ngay không? | **Chưa** — sửa cấu trúc (tách Channel/Store) trước, thêm mã sau | Thêm mã bây giờ thì sau này phải migrate lần hai |
| **D-6** | Ghi ngược lên nền tảng (pause campaign, đổi giá) — có nằm trong tầm nhìn không? | Có, nhưng **sau** N3 | Quyết định phạm vi sản phẩm, không phải kỹ thuật |

---

## 6. Điều KHÔNG có trong tài liệu này

Không code, không dependency, không connector — đúng ràng buộc Epic. Wave 2–5
(Commerce · Marketing · Communication · Supply) chưa nghiên cứu; chúng cần
object model thật của từng sàn và nên làm **sau** khi N0 chứng minh được bằng
dữ liệu thật ở N1.
