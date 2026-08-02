# Canonical Data Model Gap — đối chiếu bằng object THẬT của nền tảng

> **WTM-242 · Wave 1 của Epic WTM-238.** Founder: *"Không để mỗi connector tạo
> model riêng."* Bảng dưới đối chiếu 30 canonical domain của Task Order §V với
> code hiện tại.

Nhãn: **✅ đã có** · **🟡 có nhưng thiếu field** · **🟠 cần mở rộng** · **🔵 cần object mới** · **⛔ không nên lưu**

---

## Bảng canonical

| # | Domain | Trạng thái | Chỗ trong code / lý do |
|---|---|---|---|
| 1 | Business | ✅ | `businesses_table`, một dòng, `LocalWorkspace.ensureBusinessId` |
| 2 | **External Account** | 🔵 | Chưa có. Không phải "tài khoản người dùng" (D-4 cấm) mà là *"tài khoản của tôi ở Shopee/Play"* |
| 3 | **Connection** | 🔵 | `integrations_table` có sẵn nhưng **chết** và mang giả định sai (token trong SQLite). Viết lại: `{id, platform, externalAccountId, status, lastSyncAt, cursor}` — **không cột token nào** |
| 4 | **Credential Reference** | 🔵 | Chỉ giữ *khoá tra cứu* trong Keystore, ví dụ `ai_key_revenuecat`. Bí mật không bao giờ vào DB (luật Founder) |
| 5 | Store / Channel | 🟠 | `SalesChannel` là enum **một tầng**, 10 mã. Không biểu diễn được *"hai cửa hàng Shopee"*. Tách `Channel` (loại) khỏi `Store` (tài khoản cụ thể) |
| 6 | Product | 🟡 | `inventory/product.dart` — có `kind`, thiếu `barcode/GTIN`, giá theo kênh |
| 7 | **Product Variant** | 🔵 | Màu·size là **hai SKU riêng ở mọi sàn**. Không có variant thì mọi import từ sàn sẽ tạo N sản phẩm rời rạc |
| 8 | Digital Product | ✅ | `ProductKind.digital` (ADR-TON-023) |
| 9 | Service | ✅ | `ProductKind.service` |
| 10 | Customer | 🟡 | Có `phone`/`email`, thiếu định danh nền tảng |
| 11 | **Customer Identity** | 🔵 | `{customerId, platform, externalId, confidence}`. **Bắt buộc có `confidence`** — sàn thường không trả số điện thoại thật, và **gộp nhầm hai người tệ hơn không gộp** |
| 12 | Supplier | 🟠 | Nay là `BusinessInput` (ADR-TON-023) — nhà cung cấp chỉ là một loại đầu vào. Đủ cho chi phí, thiếu cho *mua hàng* (PO, báo giá) |
| 13 | Order | 🟡 **nặng** | Thiếu: mã đơn của sàn · phí · giảm giá · thuế · vận đơn · tiền tệ · provenance |
| 14 | Payment | 🟡 | `paymentStatus` là **chuỗi 3 giá trị**, không phải object. Không có "trả một phần" |
| 15 | **Refund** | 🔵 | Không có mã lẫn object. Sàn nào cũng có hoàn tiền |
| 16 | **Fee** | 🔵 | Có `FinanceCategory.platformFee` nhưng phí là **giao dịch rời**, không gắn vào đơn ⇒ **không tính được lãi trên một đơn** |
| 17 | **Payout** | 🔵 | Tiền sàn thực trả sau khấu trừ — con số người bán thật sự nhận. Không có |
| 18 | Inventory | 🟠 | Một số nguyên duy nhất. Không kho, không theo kênh |
| 19 | **Warehouse** | 🔵 | Chưa cần cho SME một kênh; **chặn cứng** mọi connector ghi ngược |
| 20 | **Campaign** | 🔵 | Wave 3 |
| 21 | **Ad** | 🔵 | Wave 3 |
| 22 | **Conversation** | 🔵 | Wave 4 |
| 23 | **Message** | ⛔ toàn văn / 🔵 metadata | Xem §"Không nên lưu" |
| 24 | **Review** | 🔵 | Đánh giá app/sản phẩm — dữ liệu **công khai**, lưu được |
| 25 | **Subscription** | 🔵 | Doanh thu định kỳ. Workizen **chính là** doanh nghiệp kiểu này |
| 26 | Finance Transaction | ✅ | `finance/finance_transaction.dart` + vựng từ mở rộng hôm nay (WTM-236) |
| 27 | **Business Signal** | 🔵 | Tín hiệu ngoài chưa thành cơ hội: *"CPA tăng 40%"*, *"crash tăng đột biến"* |
| 28 | Business Goal | ✅ | `journey/business_goal.dart` |
| 29 | Journey | ✅ | `journey/journey.dart` + `journey_node.dart` |
| 30 | Task | ✅ | `JourneyNodeKind.task` |
| 31 | **Evidence** | 🔵 | *"đã gửi 10 email lúc 14:20"* — bằng chứng một bước đã làm. Điều kiện tiên quyết của bất kỳ automation nào |
| 32 | **External Action** | 🔵 | Hành động ghi ngược lên nền tảng. `sync_queue_items` đã có hình dạng outbox |

**Tổng: 8 ✅ · 5 🟡 · 4 🟠 · 15 🔵 · 1 ⛔**

---

## ⛔ Cái KHÔNG nên lưu — và vì sao

| Dữ liệu | Vì sao không |
|---|---|
| **Toàn văn email / tin nhắn** | Là dữ liệu **của người khác** (khách hàng), không phải của người bán. Lưu = biến app local-first thành kho dữ liệu cá nhân bên thứ ba, và kéo theo nghĩa vụ pháp lý mà một app SME không gánh nổi. Chỉ lưu **metadata + tóm tắt do người bán chấp nhận** |
| **Token / secret nền tảng** | Luật Founder. Keystore giữ, DB giữ tham chiếu, `.ttbk` không bao giờ |
| **Danh sách khách của sàn chưa mua gì** | Không phải khách của người bán. Nhập về = profiling |
| **Dữ liệu quảng cáo cấp người dùng** (ai click) | Red-line D-7: không profiling, không quảng cáo cá nhân hoá. Chỉ lưu **tổng hợp cấp campaign** |
| **Ảnh/tệp đính kèm của khách** | Dung lượng + riêng tư. Giữ **đường dẫn**, không giữ nội dung |

---

## Bốn thứ phải làm TRƯỚC connector đầu tiên

Không phải vì hoàn hảo, mà vì **thiếu chúng thì mỗi connector sẽ tự chế một
cách riêng** — đúng thứ P-27 cảnh báo (hai bên cùng tự nhất quán vẫn nói hai sự
thật).

1. **`Provenance` trên mọi bản ghi nghiệp vụ** — `{source: manual|import|connector, connectionId?, batchId?, externalId?, importedAt?}`.
   Rẻ nhất, chặn nhiều lỗi nhất. Không có nó, người bán không biết tin con số nào.
2. **`Connection` + `CredentialReference`** — không có thì token sẽ rơi vào chỗ sai ngay connector đầu tiên.
3. **`CustomerIdentity` kèm `confidence`** — không có thì mọi việc gộp khách đều là đoán.
4. **`Fee`/`Refund`/`Payout` gắn vào Order** — không có thì import đơn làm **doanh thu đúng, lợi nhuận sai**, và sai theo hướng dễ chịu.

**Ba thứ CHƯA cần vội:** Warehouse · Campaign/Ad · Conversation. Chúng chỉ chặn
khi tới Wave 3/4, và làm sớm là đoán mò về hình dạng dữ liệu chưa thấy.
