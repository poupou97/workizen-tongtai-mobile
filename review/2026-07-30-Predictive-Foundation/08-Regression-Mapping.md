# 08 — Regression Mapping (bug → test, fail-trước / pass-sau)

## Ba bug thật phát hiện trong capability này

### B-1 · Reset dữ liệu mẫu crash `FOREIGN KEY 787`
- **Kịch bản:** người dùng ghi **đơn của chính họ** (id UUID) cho một **khách
  mẫu** — hợp lệ theo ADR-TON-014 (sample là bản ghi thường). `removeAll()` xoá
  đơn mẫu trước, rồi xoá khách mẫu → khách đó vẫn bị đơn của người dùng trỏ tới
  → `SqliteException(787)`. "Xóa dữ liệu mẫu" **crash và xoá dở dang**.
- **Vì sao test cũ không bắt:** dữ liệu user trong các test cũ không có **đơn**
  trỏ tới khách mẫu.
- **Fix:** `deleteByIdPrefix(prefix, {keep})`; `removeAll()` đọc `customerId`
  của các đơn **còn sống sót** rồi giữ lại đúng những khách đó. **Dữ liệu người
  dùng thắng.**
- **Test:** `predictive_edge_cases_test.dart` → *"REGRESSION (WTM-162): resetting
  samples after the user recorded a real order for a SAMPLE customer must not
  crash"* — fail trước fix, pass sau.
- **Ghi chú sản phẩm (chưa quyết):** khách bị giữ lại vẫn mang id `sample-`, nên
  `hasSamples()` vẫn true và banner "dữ liệu mẫu" chưa tắt trong tình huống đó.
  Xoá triệt để đòi hỏi nhận nuôi bản ghi sang id UUID mới + viết lại FK của đơn
  → **quyết định sản phẩm**, cố ý không tự làm.

### B-2 · Định nghĩa "billable" bị chép tay 6 chỗ
- **Rủi ro:** sửa quy tắc ở một chỗ, năm chỗ còn lại lệch âm thầm — đúng lớp lỗi
  One Data Path cấm.
- **Fix:** `isBillableOrder` + extension `.billable` trong
  `metrics/business_metrics.dart`; 6 nơi tiêu thụ đổi sang dùng chung.
- **Test:** toàn bộ suite hiện có phải giữ nguyên kết quả (1303 xanh sau khi gom).

### B-3 · Màn predictive hiện dữ liệu cũ sau khi seed/xoá mẫu
- **Phát hiện:** **trên máy thật**, không test nào bắt được. Nạp 12 tháng → mở
  Dự báo (đúng) → Xoá mẫu → mở lại **vẫn thấy nguyên 12 tháng**. Home thì đúng
  (nó đọc lại repo trong `initState`), predictive thì không: các `FutureProvider`
  cache giá trị đầu tiên suốt vòng đời process (Riverpod 3: `isAutoDispose`
  vẫn mặc định `false`).
- **Vì sao nguy hiểm:** vi phạm hợp đồng `Summary Count == Domain Visible
  Records` và làm người dùng tin vào một dự báo của dữ liệu **đã bị xoá**.
- **Fix:** `invalidateBusinessDataProviders(ref)` — **một danh sách duy nhất**
  (6 provider), gọi sau mọi thao tác seed/remove ở More **và** Home.
- **Test:** `predictive_invalidation_test.dart` (7) — ghim đúng khiếm khuyết
  (khẳng định giá trị **vẫn cũ** khi không gọi helper, và đúng khi có gọi) +
  **governance**: quét `ui/` bắt buộc mọi lệnh gọi seeder phải kèm helper trong
  vòng 6 dòng, và mọi `FutureProvider` khai báo trong `providers/` phải nằm
  trong danh sách hoặc trong allowlist có ghi lý do.
- **Xác minh lại trên máy:** ảnh `17-insufficient-after-remove-no-restart.png`.

## Lớp lỗi phòng ngừa (chưa từng ship) — Testing Bible **P-08**

Dự báo bịa số khi thiếu dữ liệu. Chặn bằng assert trong constructor
`RuleTwinResult` + test tại **mọi ngưỡng biên** (2↔3, 5↔6, 11↔12 tháng) + UI
assert **sự VẮNG MẶT** của headline ở trạng thái insufficient.

## Ma trận bất biến ↔ test

| Bất biến | Test |
|---|---|
| Thiếu dữ liệu ⇒ không có số | `revenue_forecast_rule_test` (biên) · `forecast_screen_test` (vắng mặt headline) |
| AI không đổi được số | `predictive_ai_test` — hostile "999.999.999 ₫" |
| Zero provider spend | `predictive_ai_test` — insufficient + có key ⇒ 0 call |
| Không PII | `predictive_privacy_test` (14) + **negative control** chứng minh bộ dò không phải bù nhìn |
| Tool runtime chưa nối | ratchet quét `lib/` |
| Determinism | generator · forecast · restart trên file SQLite thật |
| Reset an toàn | `predictive_edge_cases_test` · `historical_seed_file_test` |
| Batch ghi = per-row ghi | `historical_seed_file_test` — đối chiếu số dòng/id/tổng tiền với `HistoricalDataSet` |
