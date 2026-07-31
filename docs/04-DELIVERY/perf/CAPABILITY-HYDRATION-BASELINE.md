# Capability Hydration — Baseline cố định (Epic WTM-167 · ADR-TON-019 draft)

**Ngày lập:** 2026-07-31 · **Commit:** WTM-166 (`cbe0b38`) — trạng thái **trước**
mọi thay đổi của Epic WTM-167.

Baseline này tồn tại để hai việc: (1) làm mốc so sánh cho năm hướng trong
ADR-TON-019, (2) làm hàng rào chống hồi quy. Chạy lại bằng:

```bash
flutter test test/features/tongtai/perf/capability_hydration_benchmark_test.dart
```

## Ranh giới trung thực của từng con số

| Số đo | Nguồn | Được dùng để |
|---|---|---|
| **repository query counts** | test qua wiring production | **so sánh và khoá** — giống nhau trên mọi máy |
| **oneReadOfEach / hydration** | benchmark host (máy dev) | **so sánh tỉ lệ** giữa các hướng — KHÔNG bao giờ là tuyên bố về thiết bị |
| **app startup · DB open · first frame · Home ready** | `StartupTrace`, **máy thật, bản release** | tuyên bố về trải nghiệm người dùng |

Quy tắc: Testing Bible **P-16**. Một mili-giây đo trên máy tính không được phép
biến thành một câu về điện thoại của người bán.

## Query counts — không đổi theo khối lượng dữ liệu

Đo ở cả 4 mốc, kết quả **giống hệt nhau**:

| bảng | lần đọc / một lần cold-start hydration |
|---|---|
| `orders` | **5** |
| `customers` | **4** |
| `goals` | **4** |
| `products` | 3 |
| `finance` | 2 |

Việc con số này **không** đổi giữa 3 và 60 tháng là một kết quả có ý nghĩa: nó
xác nhận đọc lặp là **thuộc tính của cách nối dây**, không phải hệ quả của dữ
liệu. Nghĩa là nó sửa được ở tầng kiến trúc, và mọi hướng trong ADR-TON-019 đều
phải hạ được đúng bộ số này.

## Baseline theo khối lượng (host — dùng làm tỉ lệ)

| tháng | orders | customers | finance | products | 1 lượt đọc | hydration | **tỉ lệ** |
|---|---|---|---|---|---|---|---|
| 3 | 61 | 20 | 73 | 14 | 7ms | 55ms | 7.9× ¹ |
| 12 | 529 | 42 | 544 | 14 | 15ms | 52ms | 3.5× |
| 24 | 2.115 | 72 | 2.113 | 14 | 31ms | 144ms | 4.6× |
| **60** | **18.083** | 162 | **17.325** | 14 | **298ms** | **1.332ms** | **4.5×** |

¹ Ở 3 tháng, chi phí cố định (mở DB, dựng provider) lớn hơn chính công việc, nên
tỉ lệ ở đây không nói lên điều gì. Chỉ đọc các mốc từ 12 tháng trở lên.

## Kết luận quan trọng nhất từ baseline

**Ở khối lượng lớn, đọc lặp là phần chính của chi phí — không phải tổng hợp.**

Tỉ lệ hội tụ về **~4.5×** trong khi trung bình mỗi bảng bị đọc **3.6 lần**.
Nghĩa là ở 60 tháng, trong 1.332ms có khoảng **1.070ms là đọc** (3.6 × 298ms) và
khoảng **260ms là tổng hợp**. Đọc lặp chiếm **~80%**.

Điều này định hướng cho ADR-TON-019: **một hướng chỉ tối ưu tổng hợp mà không
giảm số lần đọc sẽ chạm được nhiều nhất ~20% của vấn đề.** Nhưng nó *không*
chọn hướng thay Founder — hướng 4 (Drift query optimization) vẫn có thể thắng
nếu nó khiến mỗi lần đọc **rẻ đi** thay vì **ít lần đi**.

## Điều chưa đo — và không được đoán

Chưa có số **trên thiết bị** ở 24 và 60 tháng. Baseline host cho thấy hydration
ở 60 tháng gấp **~25 lần** ở 12 tháng, và trên máy thật ở 12 tháng con số đó nằm
trong ~5ms. Nhưng **nhân lên để đoán ra số của điện thoại là đúng thứ P-16
cấm** — điện thoại có CPU, I/O và bộ nhớ khác hẳn.

**Việc phải làm trước khi Epic WTM-167 tuyên bố bất cứ điều gì về trải nghiệm:**
seed 24 và 60 tháng trên máy thật, chạy bản release có
`--dart-define=TT_STARTUP_TRACE=true`, đọc `home-data` và `first-frame`.

## Hàng rào đang có hiệu lực

| test | khoá cái gì |
|---|---|
| `capability_hydration_benchmark_test` | query counts ở **cả 4 mốc** |
| `cold_start_read_amplification_test` | query counts ở đường cold start |
| `cold_start_scale_probe_test` | tỉ lệ ở 12 tháng < 6× |

Cả ba đều **ghi lại số đang có**, không phải số mong muốn. Chúng đỏ khi ai đó
thêm một lượt đọc toàn bảng vào đường khởi động — kể cả khi máy test của người
đó chỉ có hai mươi dòng và không thấy gì chậm.
