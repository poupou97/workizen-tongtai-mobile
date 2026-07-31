# WTM-166 — Cold start: đo trước, rồi mới nói

**Ngày:** 2026-07-31 · **Máy:** Samsung S24 Ultra (SM-S928B), Android 15 ·
**Bản dựng:** `flutter build apk --release` · **Nhánh:** `feat/wtm-166-cold-start`

> Founder: *"Đo trước khi tối ưu. Không dùng benchmark desktop để tuyên bố hiệu
> năng thiết bị."* Báo cáo này giữ đúng ranh giới đó: mọi con số **mili-giây
> thiết bị** đến từ máy thật với bản release; mọi con số từ máy tính chỉ được
> dùng dưới dạng **tỉ lệ** hoặc **số lần đọc**, không bao giờ dưới dạng thời
> gian của người dùng.

## Kết luận ngắn

**Ở khối lượng dữ liệu hiện tại, Tổng Tài không có vấn đề cold start.** Toàn bộ
phần app kiểm soát được là ~50–105ms; phần còn lại của ~250ms là Android tạo
tiến trình và khởi động engine.

**Nhưng phép đo tìm ra một thứ khác, quan trọng hơn:** một lần khởi động đọc
bảng `orders` **5 lần**, `customers` **4 lần**, `goals` **4 lần**. Ở máy test
gần như trống thì vô hình (~5ms). Ở một cửa hàng có một năm buôn bán thì đó là
**3.0× chi phí cần thiết** — và người chịu là người bán có nhiều dữ liệu nhất.

## 1. Baseline — Android tự báo, không phải ta tự chấm

`am start -W` + `ActivityTaskManager: Displayed`, cold thật sự
(`force-stop` + `sync` giữa mỗi lần).

| | n | min | median | max |
|---|---|---|---|---|
| Trước thay đổi | 5 | 249ms | 255ms | 316ms |
| Sau thay đổi | 9 | 184ms | 243ms | 365ms |

**Không được đọc bảng này thành "nhanh hơn 12ms".** Biên độ dao động giữa các
lần chạy (±80ms) lớn hơn nhiều so với thứ ta sửa (~8ms). Sự thật trung thực là:
**thay đổi này không đo được ở mức tổng thể** — lý do giữ nó nằm ở §3.

## 2. Bên trong app — mốc thời gian thật (`--dart-define=TT_STARTUP_TRACE=true`)

Một lần chạy tiêu biểu, tính từ đầu `main()`:

```
bindings            0ms
prefs              13ms   SharedPreferences
telemetry-init     31ms   Firebase.initializeApp + Crashlytics
app-open-logged    39ms   ← await logEvent('app_open')
run-app            39ms
db-open            51ms   ← LazyDatabase: mở ở TRUY VẤN ĐẦU, không phải lúc launch
inventory-data     55ms
consumer-data      55ms
producer-data      56ms
home-data          56ms   ← Home đã có số liệu
first-frame        69ms   ← người dùng mới nhìn thấy khung hình đầu
```

**Điều đáng chú ý nhất nằm ở hai dòng cuối: Home có dữ liệu ở 56ms, trước khi
khung hình đầu tiên xuất hiện ở 69ms.** Nghĩa là ở khối lượng này, người dùng
**không bao giờ nhìn thấy** trạng thái loading của Home. Ba giả thuyết ban đầu
đọc từ code — `IndexedStack` dựng cả 5 tab, các `await` nối đuôi, các bảng bị
đọc lại — **cộng lại chỉ tốn ~5ms**. Nếu tối ưu theo chúng mà không đo trước,
ta đã bỏ công refactor kiến trúc để lấy về 5ms.

## 3. Thay đổi duy nhất được thực hiện

```dart
unawaited(telemetry.logEvent('app_open'));   // trước: await
```

Đo được ~8ms trên thiết bị, **không** phân biệt được ở tổng thời gian. Vẫn giữ,
vì lý do đúng không phải là 8ms: **không ai cần biết app đã mở trước khi app
mở được**, và ở dạng `await` thì một backend telemetry chậm có quyền giữ khung
hình đầu tiên lại. Đây là bỏ một phụ thuộc sai, không phải một tối ưu.

**Cố tình KHÔNG đụng tới:**

- `Firebase.initializeApp()` (18–26ms) — Crashlytics phải được cài **trước** khi
  có gì để nó bỏ sót. Đổi correctness lấy startup là đúng thứ Founder cấm.
- `SharedPreferences` (13–23ms) — quyết định locale + override provider; hoãn nó
  sẽ tạo ra một khoảnh khắc app hiển thị sai ngôn ngữ.
- `IndexedStack` dựng 5 tab — **có chủ ý**: nó giữ state của từng tab. Ở khối
  lượng đo được nó tốn ~5ms; đổi lấy việc mất state là lỗ.

## 4. Phát hiện thật — đọc lặp, và nó lớn dần theo doanh nghiệp

Đo bằng **số lần đọc**, không phải mili-giây, vì số lần đọc giống nhau trên mọi
máy (`test/features/tongtai/perf/cold_start_read_amplification_test.dart`):

| bảng | số lần đọc / một lần khởi động | ai đọc |
|---|---|---|
| `orders` | **5** | metrics · order context · journey (suy ra tiến độ mục tiêu doanh thu) · timeline · rule engine |
| `customers` | **4** | metrics · customer context · rule engine · tab Consumer |
| `goals` | **4** | journey · timeline · rule engine · Home đọc thẳng |
| `products` | **3** | inventory context · rule engine · tab Inventory |
| `finance` | **2** | finance context · timeline |

Từng consumer đều **chính đáng** — đây không phải code cẩu thả, mà là hệ quả tự
nhiên của việc mỗi Capability Context tự tải on-demand (ADR-TON-016).
`generatedOpportunitiesProvider` là `FutureProvider` nên Riverpod đã cache nó;
những lần đọc còn lại là những người dùng khác nhau đọc thật.

**Giá của nó ở một năm buôn bán** (12 tháng bán lẻ do chính generator của app
sinh ra: **529 đơn · 42 khách · 544 giao dịch tài chính**) —
`cold_start_scale_probe_test.dart`, đo **tỉ lệ**, ổn định qua 3 lần chạy:

```
đọc mỗi bảng đúng 1 lần   → 16ms
số lần đọc thật của cold start → 49ms      ratio = 3.0×
```

Tức **hai phần ba** công đọc lúc khởi động là đọc lại thứ vừa đọc. Trên điện
thoại con số tuyệt đối sẽ lớn hơn máy tính, nhưng **tỉ lệ 3.0× thì không đổi** —
đó là lý do bảng này báo cáo tỉ lệ chứ không báo cáo mili-giây.

## 5. Thứ KHÔNG làm trong story này, và vì sao

Sửa đọc lặp nghĩa là để **một** lượt đọc nuôi tất cả Capability Context trong
cùng một `BusinessContext.load()`. Nhưng ADR-TON-016 nói rõ Capability Context
là **độc lập, tải on-demand** — đó là tính chất có chủ ý, không phải sơ suất.
Biến chúng thành "được cho ăn dữ liệu" là **sửa một quyết định kiến trúc đang
có hiệu lực**, và nó có nhiều hướng hợp lệ khác nhau (cache trong phạm vi một
lượt load · đổi contract sang `summarise(rows)` · gộp truy vấn ở tầng Drift).

Theo CLAUDE.md, đó là Founder Gate — **"ADR conflict"** và **"multiple genuinely
valid directions"**. Nên story này **đo, khoá, và báo cáo**, không tự quyết.

**Hai ratchet test đã cài** để hình dạng cold start không xấu đi trong im lặng:

- `cold_start_read_amplification_test` — khoá đúng bộ số 4/3/5/4/2. Thêm một
  lượt đọc toàn bảng vào đường khởi động ⇒ **đỏ ngay**.
- `cold_start_scale_probe_test` — dựng một năm dữ liệu thật, khoá tỉ lệ < 6×.

Cả hai đều là **hàng rào**, không phải mục tiêu: chúng ghi lại số đang có, không
phải số mong muốn.

## 6. Cách đo lại

```bash
flutter build apk --release --dart-define=TT_STARTUP_TRACE=true
adb install -r build/app/outputs/flutter-apk/app-release.apk
# force-stop + sync giữa mỗi lần, nếu không lần thứ hai là warm start
adb shell am start -W -n com.workizen.tongtai/.MainActivity
adb logcat -d | grep TT-STARTUP
```

Không có `--dart-define`, `StartupTrace` bị tree-shake khỏi bản release: bản
người dùng cầm **không đo, không in, không tốn gì**. Mốc thời gian chỉ là tên +
số mili-giây — không nội dung kinh doanh, không đường dẫn, và **không lên
telemetry** (ADR-TON-005/D-7).
