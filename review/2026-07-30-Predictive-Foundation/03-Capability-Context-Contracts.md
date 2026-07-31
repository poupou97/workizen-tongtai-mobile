# 03 — Capability Context Contracts

Hợp đồng ổn định để Hub / AI Teams / Compute và các vertical khác tái dùng.

## Contract nền

```dart
abstract class CapabilityContext {
  String get capability;    // 'revenue' | 'customer' | …
  int get version;          // schema version của RIÊNG capability này
  DateTime get generatedAt;
  bool get hasData;         // TRUNG THỰC: rỗng ⇒ false, promptBlock nói rõ
  String promptBlock();     // PII-free — dành cho tầng AI
}
```
`lib/features/tongtai/capability/capability_context.dart`

**Luật PII:** `promptBlock()` chỉ mang số tổng hợp và dải (band) — không tên,
SĐT, email, địa chỉ, tên sản phẩm, số tiền thô của từng bản ghi. Được kiểm bằng
`predictive_privacy_test.dart` (có negative control).

## Revenue Capability (`revenue`, version 1)

`RevenueCapabilityContext.from({orders, now, windowMonths = 12, comparisonMonths = 3})`

| Nhóm | Trường |
|---|---|
| Chuỗi | `series` (`RevenueSeries`: điểm theo tháng, **tháng rỗng vẫn có điểm = 0**) |
| Tổng | `totalRevenue` · `billableOrders` · `averageOrderValue` · `monthsWithRevenue` |
| Động lực | `monthOverMonthGrowth` · `trendSlopePerMonth` · `volatility` · `seasonalIndex` (null nếu < 12 tháng) |
| So sánh | `comparison` (`RevenueWindowComparison`: kỳ gần vs kỳ trước) |
| Metadata | `windowMonths` · `comparisonMonths` · `currentMonthExcluded` · `latestMonth` |

Provider: `RevenueCapabilityProvider(OrderRepository, {clock, windowMonths, comparisonMonths})`
→ Riverpod `revenueCapabilityProvider`.

## Customer Capability (`customer`, version 1)

`CustomerCapabilityContext.from({customers, orders, now, windowMonths = 12})`

| Nhóm | Trường |
|---|---|
| Hồ sơ | `profiles` (`List<CustomerRfm>`: recency/frequency/monetary/`medianGapDays`) |
| Vòng đời | `stageCounts` (`CustomerLifecycleStage`: neverPurchased · active · cooling · atRisk · churned) |
| Phân bố | `recencyDistribution` (`CustomerRecencyBand`) · `monetaryBandCounts` · `frequencyBandCounts` |
| Dẫn xuất | `newCount` · `returningCount` · `winBackCandidateCount` · `lapsedCount` |
| Cut-off | `monetaryCutoffs` · `frequencyCutoffs` (p50/p80 từ chính dữ liệu) |

**Ngưỡng phân loại — thang nhịp mua riêng của từng khách:**
`recency / max(medianGapDays, 14 ngày)` → ≤1.0× *active* · ≤1.5× *cooling* ·
≤3.0× *at risk* · >3.0× *churned*. Sàn 14 ngày để khách mua 2 lần/tuần không bị
gọi là "rời bỏ" sau một tuần im lặng. Khách mới mua 1 lần (chưa có nhịp) dùng
cửa sổ cố định 30/60/90 ngày. Chưa mua bao giờ ⇒ `neverPurchased`, **không bao
giờ** bị gọi là churned.

Provider: `CustomerCapabilityProvider(CustomerRepository, OrderRepository, {clock, windowMonths})`
→ `customerCapabilityProvider`.

## Quy tắc mở rộng

Capability thứ N+1 (Inventory · Finance · Goal · Opportunity · Forecast · Risk):
theo **6 bước** trong CAPABILITY-BIBLE. Tuyệt đối không thêm mảng nặng vào
BusinessContext; không tính toán trong màn hình; nếu thiếu số → thêm vào
`analytics/` kèm test, không tính tay.
