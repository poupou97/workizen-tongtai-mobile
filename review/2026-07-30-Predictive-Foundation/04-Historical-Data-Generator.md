# 04 — Historical Data Generator

`lib/features/tongtai/sample/historical_data_generator.dart` (1.562 dòng) ·
27 test · Jira WTM-150

## Tham số (không hard-code dataset)

```dart
HistoricalDataSpec({
  months = 12,              // 3 / 12 / 24 / 36 / 60 đều chạy
  seed = 20260730,          // deterministic: cùng spec ⇒ output giống hệt
  profile = BusinessProfile.retailShop,      // retailShop · wholesale · foodAndBeverage
  growth = GrowthPattern.moderateGrowth,     // flat · moderateGrowth · fastGrowth · decline
  seasonality = SeasonalityPattern.vietnamRetail,  // none · vietnamRetail
  customerMix = CustomerMix(),               // 6 nhóm hành vi, assert tổng = 1.0
  endMonth,                                  // tháng cuối (mặc định: tháng của clock)
})
```

**Mùa vụ `vietnamRetail`** (hệ số theo tháng): đỉnh **Tết** 1,45–1,55 · đáy sau
Tết 0,75–0,85 · **hè** 1,10–1,15 · **cuối năm** 1,20–1,35.

**`CustomerMix` mặc định:** newcomers .15 · loyal .20 · returning .30 ·
slowing .15 · atRisk .10 · churned .10.

## Sinh ra

Customers · Products · Orders (+ OrderItems tham chiếu sản phẩm thật, giá bán
bất biến) · Finance (thu phản chiếu doanh thu + chi: nhập hàng, mặt bằng,
lương, marketing) · Goals.

**Không bịa** Opportunities/Timeline — chúng là **projection** do engine sẵn có
dẫn xuất từ chính dữ liệu này (ghi rõ trong doc của thư viện).

## Bảo chứng

| Tính chất | Cách đảm bảo |
|---|---|
| Deterministic | chỉ `Random(seed)`; `clock` được **tiêm**, không đọc `DateTime.now()` bên trong |
| Hành vi khách **nhìn thấy được trong dữ liệu** | churned/atRisk có đơn cuối rất xa; loyal mua đều nhịp; slowing giãn dần; newcomer chỉ xuất hiện các tháng cuối |
| Nhất quán | `orderCount`/`totalSpent`/`lastPurchaseDate` của khách **khớp** đúng đơn đã sinh (billable) — có test |
| Không parallel state | ghi qua **chính production repository**, prefix `sample-`, `removeAll()` chỉ xoá prefix |

## Bài học kỹ thuật (ghi lại để không lặp)

- `round()` thường **triệt tiêu tín hiệu** mùa vụ/tăng trưởng khi số đơn nhỏ →
  dùng **stochastic rounding**.
- Khách không phải newcomer phải hoạt động **từ tháng 0**; cho họ khởi động
  so le sẽ tạo ra một "đà tăng" giả mà rule dự báo sẽ "phát hiện" nhầm.
- Nhịp mua cần jitter; nhịp cố định khiến mọi khách mua cùng các tháng chẵn/lẻ.

## Giới hạn đã biết

- `months: 3` quá ngắn để một khách "churned" đủ cũ (ngưỡng 180 ngày) — các
  assert recency chỉ áp cho `months >= 12`.
- Đơn huỷ mang tính xác suất (~6%) → cửa sổ rất ngắn có thể không có đơn nào.
- 60 tháng của `foodAndBeverage` sinh hàng chục nghìn bản ghi: `generate()`
  nhanh, `seed()` vào Drift chậm (xem `07-Changed-Files` — đã chuyển ghi theo lô).
