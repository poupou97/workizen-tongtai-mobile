# 07 — Changed Files

3 commit trên `feat/wtm-149-predictive-foundation`; **54 file, +15.559 dòng**.
Diff đầy đủ trong `diff/`.

## Code sản phẩm — tầng mới

| File | Vai trò |
|---|---|
| `predictive/rule_twin.dart` | Envelope chung + `ForecastConfidence` · `DataSufficiency` · `ReasonCode` (có label VI/EN). **Assert** khiến "thiếu dữ liệu" không thể giả dạng dự báo |
| `predictive/revenue_forecast_rule.dart` | `revenue-forecast/1` — WMA+trend+mùa vụ, 3 chốt chống bịa |
| `predictive/customer_risk_rule.dart` | `customer-risk/1` — lateness theo nhịp riêng + RFM; entry chỉ mang id |
| `predictive/business_alerts_rule.dart` | `business-alerts/1` — doanh thu/đơn/tồn kho/dòng tiền/rủi ro khách |
| `analytics/month_bucket.dart` | Lưới tháng dùng chung (**tháng lịch địa phương**, có lý do) |
| `analytics/series_math.dart` | mean · stddev · quantile · median · least-squares · weighted average |
| `analytics/revenue_series.dart` | Chuỗi doanh thu tháng + MoM/trailing/trend/volatility/seasonalIndex/compareWindows |
| `analytics/customer_rfm.dart` | RFM + `medianGapDays` (nhịp mua riêng) + quantile bands |
| `analytics/cashflow_series.dart` | Thu/chi/lợi nhuận theo tháng |
| `capability/capability_context.dart` | Contract nền + luật PII cho `promptBlock()` |
| `capability/revenue_capability.dart` | Revenue Capability Context + provider |
| `capability/customer_capability.dart` | Customer Capability Context + vòng đời/phân khúc + provider |
| `ai/predictive_ai.dart` | Tầng giải thích: prompt = capability block + rule block; số copy từ twin |
| `ai/ai_runtime_boundary.dart` | `AiToolRuntime` + `DisabledAiToolRuntime` — **thiết kế sẵn, chưa nối** |
| `sample/historical_data_generator.dart` | Generator tham số hoá 1.562 dòng |
| `providers/tongtai_capability_provider.dart` | `revenueCapabilityProvider` · `customerCapabilityProvider` |
| `providers/tongtai_predictive_provider.dart` | `revenueForecastProvider` · `customerRiskProvider` · `businessAlertsProvider` · `predictiveAiServiceProvider` |
| `providers/tongtai_data_invalidation.dart` | `invalidateBusinessDataProviders(ref)` — một danh sách duy nhất, dùng sau mọi thao tác đổi dữ liệu |
| `ui/screens/tongtai_forecast_screen.dart` | Màn Dự báo doanh thu (stable keys, insufficient state) |
| `ui/screens/tongtai_customer_risk_screen.dart` | Màn Rủi ro khách hàng (join id→tên tại UI) |

## Code sản phẩm — sửa file có sẵn

| File | Vì sao |
|---|---|
| `metrics/business_metrics.dart` | **Gom** `isBillableOrder` + extension `.billable` — trước đó bị chép tay ở 6 chỗ |
| `business_report.dart` · `journey_progress.dart` · `opportunity_rule_engine.dart` · `customer_order_history_service.dart` | Dùng predicate gom ở trên |
| `sample/sample_data_seeder.dart` | **Bug FK 787**: giữ lại khách mẫu bị "ghim" bởi đơn của người dùng; chuyển sang ghi theo lô |
| `consumer/customer_repository.dart` | `deleteByIdPrefix(prefix, {keep})` + `upsertAll` |
| `product/order/goal/finance` repositories | `upsertAll` / `addAll` (Drift `batch`) — seed nhanh hơn ~9,4× (desktop), **20 giây thay vì 4–5 phút trên máy thật** |
| `ui/screens/tongtai_more_screen.dart` | Mục "Nạp dữ liệu mẫu 12 tháng" + 2 entry màn mới + gọi invalidate sau mọi thao tác |
| `ui/screens/tongtai_home_screen.dart` | Gọi invalidate sau khi seed (cùng lớp lỗi, phát hiện khi sửa) |
| `core/l10n/app_strings.dart` | +~40 key VI/EN cho 2 màn mới + mục seed 12 tháng |

## Test (+307 → 1313)

`predictive/` (generator 27 · forecast 92 · risk 16 · alerts 22 · AI 19 · edge 19 · privacy 14 · invalidation 7 · file-seed 3 · 2 màn 10) ·
`analytics/` 55 · `capability/` 35 · cập nhật `p0/` (nav · overflow · stable-ids · localization).

## Tài liệu

`ADR-TON-016` · `ADR-INDEX` · `CAPABILITY-BIBLE` (mới) · `AI-CAPABILITY-MATRIX` phần B ·
`TESTING-BIBLE` P-08 + suite mới · `UI-IMPLEMENTATION-LEVELS` (+2 màn) ·
`CURRENT-STATUS` · `CLAUDE.md`.
