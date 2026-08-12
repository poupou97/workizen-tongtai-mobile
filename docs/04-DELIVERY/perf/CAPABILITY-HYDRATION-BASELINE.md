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

## Aggregation fan-out — ai đọc bảng nào, mấy lần, trong MỘT hydration

Khoá ở `capability_aggregation_baseline_test.dart` (WTM-391). Bổ sung cho query
counts ở trên: query counts nói *cả cold start đọc mỗi bảng mấy lần*; fan-out nói
*mỗi Capability Context góp bao nhiêu lần đọc vào MỘT hydration*. Bất biến ở
3/12/24/60 tháng — fan-out là thuộc tính của cách nối dây, không phải của dữ liệu.

| Capability | customers | products | orders | goals | finance |
|---|:-:|:-:|:-:|:-:|:-:|
| `metrics` (KPI SoT) | 1 | · | 1 | · | · |
| `customer` | 1 | · | · | · | · |
| `order` | · | · | 1 | · | · |
| `inventory` | · | 1 | · | · | · |
| `opportunity` | 1 | 1 | 1 | 1 | · |
| `journey` | · | · | 1 | 1 | · |
| `finance` | · | · | 1 | · | 1 |
| `timeline` | · | · | 1 | 1 | 1 |
| **Tổng / hydration** | **3** | **2** | **6** | **3** | **2** |

`orders` bị đọc **6 lần** trong một hydration, bởi sáu người tiêu thụ — đây là
bảng "ai đọc `orders`" của ADR-TON-019 bằng số khoá được. Con số cold start toàn
cục cao hơn ở `customers`/`goals`/`products` vì các tab Inventory/Consumer/Home
đọc thêm **ngoài** hydration. Test còn assert `hydrationTotal == Σ(per-capability)`
để không có lần đọc ẩn nào lọt khỏi bảng này.

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

## Đã đo trên THIẾT BỊ — 2026-08-01 (Nokia 6.1, bản release)

Câu hỏi treo ở phần dưới ("chưa có số trên thiết bị") nay đã có, ít nhất cho
mốc 12 tháng. Máy: **Nokia 6.1** (Android 10, Snapdragon 630) — máy tầm thấp,
gần với người bán mục tiêu hơn là máy đầu bảng.

| | DB rỗng | **12 tháng** (49 khách · 524 đơn · 538 thu chi) |
|---|---|---|
| `db-open` | 290ms | 290ms |
| `inventory-data` | 315ms | 380ms |
| `consumer-data` | 320ms | 385ms |
| `producer-data` | 325ms | 473ms |
| **`home-data`** | **330ms** | **695ms** |
| **`first-frame`** | **430ms** | **828ms** |
| tổng (Android tự báo) | 778ms | **1.348ms** |

**Hydration** (từ `db-open` tới `home-data`) đi từ **~40ms** lên **~405ms** khi
doanh nghiệp có một năm dữ liệu. Tổng cold start tăng **73%**.

Hai điều rút ra:

1. **Kết luận của WTM-166 vẫn đúng:** `home-data` (695ms) vẫn **trước**
   `first-frame` (828ms), nên người dùng vẫn không nhìn thấy trạng thái loading
   của Home — kể cả trên máy yếu với một năm dữ liệu.
2. **Nhưng hydration đã chiếm gần một nửa** thời gian trước khung hình đầu
   (405/828ms), và nó **lớn theo dữ liệu**. Đây là con số neo cho Epic WTM-167:
   không còn phải nói "3.0× trên máy tính", mà nói được "405ms trên máy thật của
   người bán, ở một năm buôn bán".

**Vẫn chưa đo:** 24 và 60 tháng **trên thiết bị** — giao diện chỉ có nút nạp 12
tháng, nên hai mốc kia cần một đường seed riêng. **Không nhân tỉ lệ host lên để
suy ra** (Testing Bible P-16).

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
| `capability_aggregation_baseline_test` | aggregation fan-out mỗi capability ở **cả 4 mốc** + `hydrationTotal == Σ(parts)` |
| `cold_start_read_amplification_test` | query counts ở đường cold start |
| `cold_start_scale_probe_test` | tỉ lệ ở 12 tháng < 6× |

Cả ba đều **ghi lại số đang có**, không phải số mong muốn. Chúng đỏ khi ai đó
thêm một lượt đọc toàn bảng vào đường khởi động — kể cả khi máy test của người
đó chỉ có hai mươi dòng và không thấy gì chậm.
