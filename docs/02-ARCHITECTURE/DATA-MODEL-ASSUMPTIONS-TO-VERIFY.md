# 10 giả định mô hình dữ liệu — kiểm chứng bằng CODE

> **WTM-240 · Wave 0 của Epic WTM-238.** Founder liệt kê 10 câu hỏi. Mỗi câu trả
> lời dưới đây kèm **file + dòng**, không trả lời bằng trí nhớ.
>
> Lý do quy tắc này tồn tại: 2026-08-01 tôi viết mô tả hai story từ **tiền đề
> sai** ("Hub nằm trong cài đặt", "công thức 5 yếu tố") và chỉ phát hiện khi đọc
> code. Cùng ngày, Derived Data Audit phân loại sai **ba lần** vì tin **tên
> cột** thay vì đọc repository (P-28).

**Chốt tại** `main` @ `90a40ef`, schema **v16**.

Nhãn: **ĐÃ CÓ** · **THIẾU FIELD** · **CẦN MỞ RỘNG** · **CẦN OBJECT MỚI** · **KHÔNG NÊN LƯU**

---

## 1. Order model có đủ cho marketplace không? → **THIẾU FIELD** (nặng)

`orders/order.dart` — `CustomerOrder`: `id`(120) `customerId`(123)
`orderNumber`(126) `date`(129) `status`(132) `paymentStatus?`(142)
`channel?`(157) `items`(160). `OrderItem`: `productId`(46) `productName`(49)
`sku`(52) `category`(55) `unit`(59) `quantity`(62) `unitPrice`(66).

Một đơn Shopee/TikTok Shop mang theo những thứ **không có chỗ nào để đặt**:

| Khái niệm sàn | Chỗ trong Tổng Tài |
|---|---|
| mã đơn của sàn (khác `orderNumber` nội bộ) | ❌ |
| phí sàn / phí thanh toán / phí vận chuyển trên **từng đơn** | ❌ (Finance chỉ có giao dịch rời, không gắn đơn) |
| giảm giá, mã khuyến mãi | ❌ |
| thuế | ❌ |
| hoàn tiền một phần | ❌ (`paymentStatus` là chuỗi 3 giá trị) |
| payout (tiền sàn thực trả, sau khấu trừ) | ❌ |
| địa chỉ giao, đơn vị vận chuyển, mã vận đơn | ❌ |
| tiền tệ | ❌ (mọi con số ngầm định VNĐ) |
| **nguồn gốc bản ghi** | ❌ |

⚠️ **Hệ quả nghiêm trọng nhất, và nó không hiển nhiên:** hôm nay doanh thu được
**suy** từ đơn (WTM-196: `sales` không bao giờ là một giao dịch được ghi tay).
Nếu import đơn từ sàn mà không mang phí theo, người bán sẽ thấy **doanh thu
tăng đúng nhưng lợi nhuận sai** — và sai theo hướng **dễ chịu**, tức hướng
không ai đi kiểm tra.

## 2. Product model có hỗ trợ physical/digital/service không? → **ĐÃ CÓ**, thiếu variant

`inventory/product.dart:106` `final ProductKind kind` (ADR-TON-023, hôm nay
WTM-227/233). `quantity`(111) và `reorderLevel`(119) **nullable** = *"không áp
dụng"*, `stockStatus` trả `null` cho loại không có kho.

Thiếu cho marketplace: **variant/option** (màu·size là hai SKU riêng ở mọi sàn),
`barcode/GTIN`, nhiều ảnh theo variant, giá theo kênh (cùng một hàng bán hai giá
ở hai sàn là chuyện thường).

## 3. Customer có đủ identity đa kênh không? → **CẦN OBJECT MỚI**

`consumer/customer.dart`: `id`(73) `name`(76) `phone`(80) `location`(83)
`orderCount`(86) `totalSpent`(90) `lastPurchaseDate`(94) `email`(97)
`addresses`(100) `segments`(104) `tags`(107) `notes`(110) `history`(113).

Không có khái niệm **"cùng một người, hai nền tảng"**. Sàn cho `buyer_id` ẩn
danh (Shopee thường **không** trả số điện thoại thật), Facebook cho `PSID` chỉ
có nghĩa trong phạm vi một Page. Gộp bằng tên là sai, gộp bằng điện thoại thì
sàn không đưa.

⇒ Cần `CustomerIdentity { customerId, platform, externalId, confidence }` —
**một khách nhiều danh tính**, và phải ghi **độ tin cậy của phép gộp**, vì gộp
nhầm hai người là lỗi tệ hơn không gộp.

## 4. Inventory có hỗ trợ nhiều warehouse/channel không? → **KHÔNG** (CẦN MỞ RỘNG)

`Product.quantity` là **một số nguyên duy nhất** (dòng 111). Không có kho, không
có tồn theo kênh. Người bán ba sàn có ba con số tồn khác nhau ở ba nơi và một
con số trong Tổng Tài — Tổng Tài sẽ luôn sai với ít nhất hai sàn.

**Chưa cần sửa ngay:** với người bán một kênh (đa số SME hôm nay) mô hình hiện
tại đúng. Nhưng đây là điều kiện chặn của bất kỳ connector nào **ghi ngược**.

## 5. Finance có hỗ trợ fee/tax/refund/payout/COGS không? → **MỘT PHẦN**

`finance/finance_transaction.dart`: `id`(24) `type`(27) `category`(34)
`categoryNote`(41) `amount`(44) `date`(47) `description`(50)
`paymentMethod`(53).

* **COGS** ✅ — `Product.costPrice` (199) nay là *chi phí biến đổi mỗi đơn vị
  bán* (WTM-231), dùng chung cho hàng hoá lẫn sản phẩm số.
* **Fee** ⚠️ — có `FinanceCategory.platformFee`, và hôm nay WTM-236 thêm
  `infrastructure`/`tooling`/`provider`. Nhưng phí là **giao dịch rời**, không
  gắn được vào đơn ⇒ không tính được lãi **trên một đơn**.
* **Tax / Refund / Payout** ❌ — không có mã, không có object.

⇒ Câu hỏi số 1 của người bán — *"tháng này tôi lãi bao nhiêu, thật, sau hết
phí?"* (chính là mục tiêu Epic File Bridge WTM-181) — **hôm nay chưa trả lời
được** kể cả khi có dữ liệu, vì mô hình không có chỗ đặt phí theo đơn.

## 6. SalesChannel có đủ canonical không? → **ĐÃ CÓ 10 mã, thiếu chiều "cửa hàng"**

`profile/business_profile.dart:78-94`: `shop` `market` `shopee` `tiktok`
`facebook` `zalo` `wholesale` + `website` `app_store` `direct` (WTM-232 hôm nay).

Thiếu: `lazada` · `amazon` · `ebay` · `etsy` · `shopify` · `woocommerce` —
nhưng **đừng thêm vội**. Vấn đề thật sâu hơn: `SalesChannel` là **enum một
tầng**, trong khi thực tế người bán có thể có **hai cửa hàng Shopee**. Cần tách
`Channel` (loại) khỏi `Store/Account` (một tài khoản cụ thể).

## 7. Opportunity có provenance/source không? → **THIẾU FIELD**

`opportunity/opportunity.dart`: `id`(55) `type`(58) `title`(61)
`description`(64) `expectedImpact`(67) `score`(80) `roi`(95)
`discoveredAt`(98) `reaction`(101).

Nguồn gốc **ẩn trong quy ước id** (`gen-restock-<id>`, `gen-winback-<id>`) —
không phải một trường. Cơ hội sinh từ tín hiệu ngoài (*"quảng cáo Facebook tiêu
2tr mà không ra đơn"*) sẽ **không phân biệt được** với cơ hội suy từ dữ liệu
trong máy. Người bán hỏi *"sao anh biết?"* thì hôm nay Rule Twin trả lời được
bằng `reasonCodes`; với dữ liệu ngoài thì chưa.

## 8. Journey có external action/evidence không? → **CÓ MỘT NỬA**

`journey/journey_node.dart`: `origin`(176 — `user`/`ruleTwin`/`ai`),
`derivedMetric`(183), `derivedTarget`(186), `reasonCodes`(191),
`sourceOpportunityId`(202).

Đã có: **ai tạo ra bước này**, **đo bằng số nào**, **vì sao**. Thiếu: **bằng
chứng bên ngoài** (*"đã gửi email cho 10 khách lúc 14:20"*) và **hành động
ngoài** (bước có thể được hoàn thành bằng một lệnh gọi API thay vì người bấm).
`JourneyCompletion` chỉ có manual/derived.

## 9. BusinessContext chứa được external signal không? → **CẦN MỞ RỘNG** (có kỷ luật)

`metrics/business_context.dart:66-90`: `version` `generatedAt` + 8 slice
(`metrics` `customers` `orders` `inventory` `opportunity` `journey` `finance`
`timeline`) + `health`.

Về cấu trúc thì **thêm slice là chuyện thường** (đã làm 3 lần: WTM-133/134).
Nhưng ADR-TON-016 cấm biến nó thành God Object: phân tích nặng phải nằm ở
**Capability Context** on-demand.

⇒ Đúng hình dạng: `ExternalSignalSummary` **nhẹ** (mỗi nền tảng: kết nối chưa,
dữ liệu tươi tới đâu, vài con số đầu). Chi tiết nằm ở Capability Context. Và
**bắt buộc** có `freshness` + `confidence` per-source — xem §4 của
[baseline](INTEGRATION-ARCHITECTURE-BASELINE.md).

## 10. Backup có phù hợp dữ liệu connector không? → **CÓ, nếu tuân luật**; và có **một hố an toàn**

`export/backup_format.dart` — `BackupDatasets.all` (6 dataset bắt buộc) vs
`optional` (journeys · businessProfile · opportunityReactions ·
businessInputs). Luật đã ghi rõ trong file: thêm vào `all` = **từ chối mọi
`.ttbk` đã phát hành**.

**Hố an toàn — đây là phát hiện phải báo Founder:** `integrations_table` có sẵn
bốn cột `*Encrypted` cho token. Nếu connector dùng bảng đó và ai đó thêm nó vào
`.ttbk` (một dòng), thì **token nền tảng đi vào file sao lưu**, mà file `.ttbk`
**mặc định không mã hoá** (mã hoá là tuỳ chọn, WTM-100). Ngày 2026-07-31 đã có
sự cố hai file `.ttbk` không mã hoá bị gửi nhầm lên Zalo.

⇒ Luật đề xuất, **không tự áp**: *bí mật nằm ở Keystore; DB chỉ giữ tham chiếu;
`.ttbk` không bao giờ chứa credential.*

---

## Tổng kết — ba thứ chặn MỌI connector, không riêng nền tảng nào

| # | Thiếu | Vì sao chặn |
|---|---|---|
| 1 | **Provenance** trên mọi bản ghi | Không phân biệt được số tự nhập vs số nhập về ⇒ lệch thì không biết tin bên nào |
| 2 | **External identity** cho Customer | Không gộp được một khách từ nhiều kênh; gộp nhầm còn tệ hơn không gộp |
| 3 | **Freshness + confidence** per-source | AI đọc dữ liệu cũ 3 ngày lẫn dữ liệu hôm nay mà không biết ⇒ nói sai một cách tự tin |

Và **một khoảng trống tài chính** làm hỏng đúng câu hỏi số 1 của người bán: phí
là giao dịch rời, không gắn được vào đơn ⇒ không có lãi-trên-một-đơn.

Bốn thứ này **phải xong trước connector đầu tiên**, nếu không mỗi connector sẽ
tự chế một cách riêng — đúng thứ P-27 cảnh báo (hai bên cùng tự nhất quán vẫn
nói hai sự thật).
