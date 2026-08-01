# Derived Data Audit

> **Founder Directive 2026-08-01.**
> *"Derived Data không được trở thành Single Source of Truth. Single Source of
> Truth phải luôn là dữ liệu gốc."*

**Cập nhật:** 2026-08-01 · WTM-202

---

## Vì sao audit này là gốc

Ba lỗi lớn nhất trong ngày là **cùng một khuyết tật**, và tất cả đều bắt đầu từ
một cột dẫn xuất nằm trong database:

| | Sự thật dẫn xuất | Trường đã lưu vẫn được đọc |
|---|---|---|
| WTM-196 | doanh thu từ đơn hàng | `FinanceTransaction` nhập tay |
| WTM-200a | `deriveGoalsProgress` | `BusinessGoal.achievedAmount` |
| WTM-201 | `CustomerRfmService` | `Customer.orderCount` · `totalSpent` |

Mẫu: **một trường từng là sự thật → một luật dẫn xuất ra đời → không ai gỡ
trường cũ → hai sự thật, không có gì đỏ.** Chừng nào còn cột dẫn xuất không có
lý do, lỗi thứ tư đang chờ sẵn.

## Lý do persist **hợp lệ** cho dữ liệu dẫn xuất

1. **Benchmark** chứng minh tính lại quá đắt (phải có số, không phải cảm giác).
2. **Ảnh chụp lịch sử có nghĩa nghiệp vụ** — giá tại thời điểm bán ≠ giá hôm
   nay; xoá nó là mất sự thật, không phải bỏ bản sao.
3. **Hợp đồng backup/restore** (ADR-TON-018 lossless) đòi.

Không thuộc ba nhóm trên ⇒ **vi phạm**.

---

## Bảng

### `customers_table`

| Cột | Loại | Kết luận |
|---|---|---|
| `id` · `name` · `phone` · `email` · `address` · `city` · `country` · `segments` | **Source** | người bán nhập |
| `businessId` · `externalId` · `externalSource` · `createdAt` · `updatedAt` | **Source** | hệ thống sinh |
| **`orderCount`** | **Derived** | ❌ **VI PHẠM** — suy ra từ đơn hàng. Ghi **và đọc lại** (`customer_repository` dòng 119/141). WTM-201 đã sửa *chỗ đọc để hiển thị*, cột vẫn còn |
| **`totalSpent`** | **Derived** | ❌ **VI PHẠM** — như trên |
| **`lastOrderDate`** | **Derived** | ❌ **VI PHẠM** — như trên |
| **`avgOrderValue`** | **Derived** | ❌ `totalSpent / orderCount` — dẫn xuất của hai thứ vốn đã dẫn xuất |
| **`lifetimeValue`** | **Derived** | ❌ không ai ghi, không ai đọc — **cột chết** |
| **`churnRisk`** | **Derived** | ❌ **nguy hiểm nhất**: rủi ro rời bỏ có luật thật (`customerLifecycleStage`, theo nhịp mua riêng). Một cột `churnRisk` đã lưu là **luật thứ hai đang chờ ai đó đọc** — đúng thứ vừa gây ra WTM-200b |
| `domainSnapshot` | Derived | ✅ hợp lệ — ADR-TON-009, ảnh chụp phục vụ migration |

### `orders_table`

| Cột | Loại | Kết luận |
|---|---|---|
| `id` · `customerId` · `orderNumber` · `orderDate` · `status` · `paymentStatus` · `items` | **Source** | `items` là gốc thật của đơn |
| **`totalAmount`** | **Derived** | ⚠️ `CustomerOrder.totalAmount` là **getter tính từ `items`**. Cột được **ghi** nhưng khi đọc thì domain **dựng lại từ `items`** ⇒ hôm nay chưa lệch, nhưng là **bản sao ghi-một-chiều**: bất kỳ truy vấn SQL nào sắp xếp/lọc theo cột này sẽ đọc một sự thật thứ hai |
| `subtotal` | **Derived, đúng** | ✅ **Sửa lại đánh giá lần ba.** Ghi bằng `totalAmount` là **đúng hôm nay**: domain chưa có giảm giá và phí ship, nên tổng dòng hàng **chính là** tổng đơn. Nhận định đầu *"cột nói dối tên của nó"* là nặng tay. Nó chỉ sai vào ngày `discount`/`shippingCost` được nối vào domain — khi đó `subtotal` phải giữ là tổng dòng hàng còn `totalAmount` cộng thêm điều chỉnh |
| **`totalQuantity`** | **Derived** | ⚠️ tổng `quantity` của `items` |
| `discount` · `shippingCost` | **Source** | người bán nhập |

### `journeys_table` (lưu `BusinessGoal`)

| Cột | Loại | Kết luận |
|---|---|---|
| `id` · `goal` · `status` · `budget` · `timelineDays` · `startedAt` | **Source** | |
| **`progressPercent`** | **Derived** | ❌ **VI PHẠM** — `deriveGoalsProgress` là luật thật (WTM-138/200a). Cột này chính là `achievedAmount` dưới một cái tên khác |
| **`completedSteps`** · **`totalSteps`** | **Derived** | ❌ đếm từ cây `JourneyNode` (ADR-TON-021) |
| **`spent`** | **Derived** | ❌ suy từ giao dịch |
| `revenueImpact` | **Source** | ✅ **Sửa lại phân loại lần hai.** Bất chấp cái tên, cột này lưu `BusinessGoal.targetAmount` — **mục tiêu do người bán đặt** (`business_goal_repository` dòng 102/136). Không phải dẫn xuất |

### `products_table`

| Cột | Loại | Kết luận |
|---|---|---|
| `id` · `sku` · `name` · `description` · `category` · `costPerUnit` · `listPrice` · `supplierId` · `isActive` | **Source** | |
| **`profitPerUnit`** | **Derived** | ❌ `listPrice − costPerUnit`; không ai ghi, không ai đọc — **cột chết** |
| `totalStock` | **Source** | ✅ **Sửa lại phân loại.** Đọc kỹ `product_repository` (dòng 94/109): đây **chính là chỗ lưu `Product.quantity`**, chỉ mang cái tên của một thiết kế nhiều kho chưa bao giờ tồn tại. Search đọc nó (`tongtai_search_models` dòng 124) là đọc **đúng nguồn**, không phải bản sao. Tên gây hiểu nhầm ⇒ P8 Polish, không phải vi phạm |
| `stockByWarehouse` | — | ❌ **cột chết**: không ai ghi, không ai đọc |
| **`currentPrice`** | — | ⚠️ **cột chết mà một màn ĐANG ĐỌC**: `product_repository` chỉ ghi `listPrice`, nhưng search đọc `currentPrice ?? listPrice`. Hôm nay luôn `null` nên hai bên trùng; **ngày ai đó ghi `currentPrice`, Search và Inventory sẽ hiện hai giá khác nhau**. Cùng loại mối nối với `minimumThreshold` |

⚠️ **Hai lần tôi phân loại sai, cùng một nguyên nhân: tin vào tên cột.**

- `totalStock` — nghe như tổng của `stockByWarehouse`; thực ra là chỗ lưu
  `Product.quantity`. `stockByWarehouse` **không ai dùng**.
- `revenueImpact` — nghe như tác động doanh thu tính ra được; thực ra lưu
  `BusinessGoal.targetAmount`, tức **mục tiêu người bán đặt**.

- `subtotal` — nghe như một bản sao thừa của `totalAmount`; thực ra bằng nhau
  **vì domain chưa có giảm giá/phí ship**, nên nó đúng, chỉ là chưa khác.

**Bài học cho ai audit tiếp: schema này ra đời trước domain, nên tên cột không
đáng tin. Phải đọc repository ghi/đọc gì.** Và ba lần tôi đánh giá nặng tay đều
theo cùng một hướng — vội gọi là vi phạm. Một audit hay dọa nạt cũng mất tin cậy
như một audit bỏ sót. Ghi lại chỗ sai thay vì lặng lẽ đổi
— một audit phân loại sai còn tệ hơn không có audit, vì nó sinh ra story sai và
người sau sẽ tin nó.

⚠️ **Phát hiện kèm:** bảng có `costPerUnit`, nhưng **domain `Product` không có
giá vốn** — đó chính là lý do ROI cơ hội không tính được (ADR-TON-022) và bước
"ghi giá vốn" trong hành trình tồn tại. **Dữ liệu có chỗ để ở, chỉ là chưa ai
nối.** Đây là P4 Data Model (+50) chứ không phải thiếu vĩnh viễn.

### `transactions_table` · `business_journey_*` · `opportunity_reactions_table`

Không có cột dẫn xuất. ✅

---

## Tổng kết

| Mức | Số cột |
|---|---|
| ❌ Vi phạm rõ (dẫn xuất, không lý do) | **8** |
| ⚠️ Bản sao ghi-một-chiều (chưa lệch, sẽ lệch) | **3** |
| ⚠️ **Cột chết mà một màn đang đọc** (`currentPrice`) | **1** |
| ❌ Cột chết hoàn toàn (`lifetimeValue` · `stockByWarehouse` · `profitPerUnit`) | **3** |
| ✅ Dẫn xuất **có** lý do (`domainSnapshot`) | 1 |
| ✅ Bị nghi oan (`totalStock` · `revenueImpact` · `subtotal`) | **3** |

**Không cột nào trong nhóm ❌ có benchmark hay lý do nghiệp vụ.** Chúng tồn tại
vì schema được dựng trước khi các luật dẫn xuất ra đời, và không ai quay lại gỡ.

## Việc phải làm

| # | Việc | Loại | Điểm |
|---|---|---|---|
| 1 | Gỡ / vô hiệu hoá 6 cột dẫn xuất của `customers_table` — **`churnRisk` trước tiên**, vì nó là luật thứ hai đang chờ được đọc | Derived Truth Violation | **+100** |
| 2 | 5 cột dẫn xuất của `journeys_table` (`progressPercent` là `achievedAmount` đổi tên) | Derived Truth Violation | **+100** |
| ~~3~~ | ~~`orders_table`: `subtotal`~~ — **không phải vi phạm**, xem trên | — | — |
| 4 | `products_table`: `profitPerUnit` (chết) · `currentPrice` (chết nhưng search đọc) | Derived Truth Violation | **+80** |
| 5 | Nối `costPerUnit` vào domain `Product` ⇒ mở khoá ROI thật + High Risk | P4 Data Model | **+50** |

### Ràng buộc khi gỡ

Cột đang nằm trong `.ttbk` v2. Gỡ khỏi schema là **migration phá huỷ**, và
ADR-TON-018 nói backup phải lossless. Vì vậy hướng an toàn cho **mỗi** cột:

1. **Ngừng đọc** (đã làm với `orderCount` ở WTM-201) + **governance test cấm
   đọc trong `ui/` và trong domain**;
2. đánh dấu trong doc comment: *"không phải sự thật, giữ vì hợp đồng backup"*;
3. chỉ gỡ khỏi schema khi có phiên bản `.ttbk` mới, không gỡ lẻ tẻ.

Bước 1 mới là bước chặn được lỗi — bước 3 chỉ là dọn dẹp.
