# 05 — Rule Twin (authoritative)

Ba twin, cùng một envelope, **chạy được khi không có AI, không có mạng, không
có key**. `lib/features/tongtai/predictive/`

## Envelope chung

```dart
RuleTwinResult<T>(result, confidence, sufficiency, reasonCodes, version, generatedAt)
```
Hai assert trong constructor:
1. `result == null` **⟺** `sufficiency == insufficient`
2. `insufficient` ⟹ `confidence == none`

⇒ **không thể** trả một con số "cho có" khi thiếu dữ liệu (Testing Bible P-08).

## 1. `revenue-forecast/1`

`basis` = cửa sổ đã **cắt các tháng rỗng ở đầu** (tháng trước lần bán đầu tiên
không phải "tháng tệ"); tháng rỗng ở giữa/cuối **giữ nguyên** để một doanh
nghiệp đã ngừng bán không bị tô hồng.

```
level  = weightedTrailingAverage(3)         # trọng số 1:2:3, mới nhất nặng nhất
slope  = leastSquaresSlope(basis)           # đồng/tháng
base   = level + 0.7 × slope × 5/3
value  = max(0, base × hệ_số_mùa_vụ_tương_đối?)
band   = ± clamp(0.10 + 0.5·volatility + phạt_lịch_sử, 0.10, 0.75) × max(value, mean(basis))
         phạt_lịch_sử = 0.15 (3–5 tháng) · 0.05 (6–11) · 0 (≥12); cận dưới sàn 0
hướng  = |slope / mean(basis)| so với dải nhiễu clamp(0.02 + 0.05·volatility, 0.02, 0.10)
```

**`5/3` là số học, không phải số ma thuật:** trung bình trọng số 1:2:3 mô tả
doanh nghiệp tại **trọng tâm** của bộ trọng số — sớm hơn tháng quan sát cuối
`2/3` tháng. Mục tiêu dự báo là **1 tháng sau** tháng cuối ⇒ phải mang xu hướng
đi `1 + 2/3` tháng. Hệ số `0.7` là **giảm chấn cố ý** (70% xu hướng / 30% mức
gần đây): một đà tăng rõ ràng chỉ bị cắt 30%, nhưng một slope nhiễu không thể
chạy hoang.

**Mùa vụ dùng hệ số *tương đối*** `index[đích] / mean(index[3 tháng của level])`
— không dùng thẳng chỉ số tuyệt đối, vì `level` đã mang sẵn mùa vụ của chính
các tháng đó.

### Ba chốt chặn không cho bịa kết luận

1. **Chốt trôi xu hướng (`maxSeasonalTrendDrift = 0.5`) — quan trọng nhất.** Với
   đúng 12 điểm, mỗi tháng dương lịch xuất hiện một lần nên `seasonalIndex()`
   **chính là** chuỗi đã chuẩn hoá — nó **không tách được** mùa vụ khỏi xu
   hướng. Không có chốt này, một doanh nghiệp chỉ đơn giản tăng từ 100k → 1,2M
   trong năm sẽ nhận `index[7/2025] = 0,15×` áp cho tháng 7 năm sau → **dự báo
   một doanh nghiệp đang phát đạt xuống còn 1/9 mức gần đây**. Chốt từ chối
   bước mùa vụ khi đường hồi quy đã dịch chuyển hơn nửa tháng-trung-bình.
2. Từ chối mùa vụ khi biên độ đỉnh–đáy < 0,25 (năm phẳng) hoặc hệ số ≤ 0.
3. Volatility **không đo được** ⇒ nới dải, nhưng **không** gắn `highVolatility`
   và **không** hạ độ tin cậy — *không biết* khác *bằng chứng bất ổn*.

### Sufficiency / confidence
| Tháng có doanh thu | Sufficiency | Confidence |
|---|---|---|
| < 3 | **insufficient** (`result == null`) | none |
| 3–5 | partial | low |
| 6–11 | sufficient | medium (low nếu volatility cao) |
| ≥ 12 | sufficient | high (medium nếu volatility cao) |

`highVolatilityThreshold = 1.0` lấy từ thang của chính `RevenueSeries.volatility`
(dispersion của thay đổi MoM so với độ lớn trung bình của chúng) — ngưỡng thấp
hơn sẽ gắn cờ cả doanh nghiệp chỉ dao động ±5%.

## 2. `customer-risk/1`

`score = 100 × (0.60·lateness + 0.25·loyaltyRisk + 0.15·valueWeight)`

- **lateness (0.60)** — tuyến tính từng khúc theo *tỉ lệ trễ tương đương*, neo
  đúng thang mà `customerLifecycleStage` dùng: 0→0.00 · 1.0×→0.20 · 1.5×→0.50 ·
  3.0×→0.85 · ≥6.0×→1.00. **Đơn điệu** ⇒ 3× luôn xếp trên 1.5×, và điểm không
  bao giờ mâu thuẫn với nhãn giai đoạn.
- **loyaltyRisk (0.25)** — `1 − ordersInWindow / kỳ_vọng`, với kỳ vọng bị chặn
  bởi **thâm niên thực tế** ⇒ khách mới mua đều không bị phạt oan.
- **valueWeight (0.15)** — dải chi tiêu từ p50/p80 của **chính** danh bạ; chi
  tiêu 0 luôn cho 0.
- Sắp xếp: score ↓ → giá trị vòng đời ↓ → id ↑ (toàn phần, tái lập được).
- **PII:** entry chỉ mang `customerId`. Test quét **cấu trúc** class: tập
  trường đúng bằng `{customerId, stage, recencyDays, lifetimeOrders,
  lifetimeValue, riskScore, reasonCodes, winBackCandidate}` — thêm trường định
  danh sẽ **fail** với thông báo "cần review quyền riêng tư".

## 3. `business-alerts/1`

Dải nhiễu ±10% trên so sánh 3-tháng-vs-3-tháng.

| Cảnh báo | Ngưỡng |
|---|---|
| revenueDrop / ordersDrop | ≥10% → warning · ≥30% → critical |
| stockBelowReorder | uỷ quyền cho `StockAlertService`; hết hàng → critical |
| negativeCashflow | tổng lợi nhuận cửa sổ < 0 → critical; tỉ lệ tháng âm > 1/3 → warning |
| customerRisk | tỉ lệ khách lapsed ≥20% → warning · ≥35% → critical |

**Danh sách cảnh báo rỗng + `sufficient` là một câu trả lời thật** ("không có
gì bất thường") — không bao giờ báo `insufficient` chỉ vì không có cảnh báo.
