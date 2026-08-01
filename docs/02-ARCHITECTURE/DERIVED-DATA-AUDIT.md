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
| **`subtotal`** | **Derived** | ⚠️ tệ hơn: đang được ghi bằng **chính `totalAmount`** (dòng 121) — hai cột khác tên, cùng giá trị, không cột nào là subtotal thật |
| **`totalQuantity`** | **Derived** | ⚠️ tổng `quantity` của `items` |
| `discount` · `shippingCost` | **Source** | người bán nhập |

### `journeys_table` (lưu `BusinessGoal`)

| Cột | Loại | Kết luận |
|---|---|---|
| `id` · `goal` · `status` · `budget` · `timelineDays` · `startedAt` | **Source** | |
| **`progressPercent`** | **Derived** | ❌ **VI PHẠM** — `deriveGoalsProgress` là luật thật (WTM-138/200a). Cột này chính là `achievedAmount` dưới một cái tên khác |
| **`completedSteps`** · **`totalSteps`** | **Derived** | ❌ đếm từ cây `JourneyNode` (ADR-TON-021) |
| **`spent`** · **`revenueImpact`** | **Derived** | ❌ suy từ giao dịch/đơn hàng |

### `products_table`

| Cột | Loại | Kết luận |
|---|---|---|
| `id` · `sku` · `name` · `description` · `category` · `costPerUnit` · `listPrice` · `supplierId` · `isActive` | **Source** | |
| **`profitPerUnit`** | **Derived** | ❌ `listPrice − costPerUnit` |
| **`totalStock`** | **Derived** | ❌ tổng của `stockByWarehouse` |
| **`currentPrice`** | ? | chưa rõ là giá đang bán (Source) hay dẫn xuất từ khuyến mãi |

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
| ❌ Vi phạm rõ (dẫn xuất, không lý do) | **11** |
| ⚠️ Bản sao ghi-một-chiều (chưa lệch, sẽ lệch) | **3** |
| ✅ Dẫn xuất **có** lý do (`domainSnapshot`) | 1 |

**Không cột nào trong nhóm ❌ có benchmark hay lý do nghiệp vụ.** Chúng tồn tại
vì schema được dựng trước khi các luật dẫn xuất ra đời, và không ai quay lại gỡ.

## Việc phải làm

| # | Việc | Loại | Điểm |
|---|---|---|---|
| 1 | Gỡ / vô hiệu hoá 6 cột dẫn xuất của `customers_table` — **`churnRisk` trước tiên**, vì nó là luật thứ hai đang chờ được đọc | Derived Truth Violation | **+100** |
| 2 | 5 cột dẫn xuất của `journeys_table` (`progressPercent` là `achievedAmount` đổi tên) | Derived Truth Violation | **+100** |
| 3 | `orders_table`: `subtotal` đang ghi bằng `totalAmount` — sửa hoặc gỡ | Derived Truth Violation | **+90** |
| 4 | `products_table`: `profitPerUnit` · `totalStock` | Derived Truth Violation | **+80** |
| 5 | Nối `costPerUnit` vào domain `Product` ⇒ mở khoá ROI thật + High Risk | P4 Data Model | **+50** |

### Ràng buộc khi gỡ

Cột đang nằm trong `.ttbk` v2. Gỡ khỏi schema là **migration phá huỷ**, và
ADR-TON-018 nói backup phải lossless. Vì vậy hướng an toàn cho **mỗi** cột:

1. **Ngừng đọc** (đã làm với `orderCount` ở WTM-201) + **governance test cấm
   đọc trong `ui/` và trong domain**;
2. đánh dấu trong doc comment: *"không phải sự thật, giữ vì hợp đồng backup"*;
3. chỉ gỡ khỏi schema khi có phiên bản `.ttbk` mới, không gỡ lẻ tẻ.

Bước 1 mới là bước chặn được lỗi — bước 3 chỉ là dọn dẹp.
