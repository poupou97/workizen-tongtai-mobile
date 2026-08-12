# ADR-TON-025 — Capability Context Performance: Chấm điểm 5 hướng + Khuyến nghị (PROPOSED)

- **Status:** 📝 **PROPOSED — CHƯA PHÊ CHUẨN.** File này chấm điểm năm hướng của
  [ADR-TON-019](ADR-TON-019-capability-context-performance.md) trên tám trục và
  **đưa một khuyến nghị**. Khuyến nghị **không phải quyết định** — chọn hướng
  kiến trúc là **Founder Gate** ("multiple genuinely valid directions" +
  "ADR conflict", `CLAUDE.md`). ADR-TON-019 (phần khung vấn đề của Founder) giữ
  nguyên; file này **không** đổi runtime, **không** đổi đường đọc, **không** phê
  chuẩn gì.
- **Jira:** Story WTM-391 · Epic WTM-167 · bằng chứng từ WTM-166.
- **Liên quan / ràng buộc:** ADR-TON-015 (One Data Path) · ADR-TON-016
  (Capability Context · Rule Twin · AI Runtime Boundary) · ADR-TON-019 (khung
  vấn đề).

> EN: This is a **PROPOSED, non-binding** recommendation. It scores the five
> directions ADR-TON-019 laid out against the eight Founder-specified axes and
> recommends one, so the Founder has a decision-ready analysis rather than a bare
> question. Choosing the direction remains a **Founder Gate** — nothing here is
> ratified, and no runtime read-path is changed by this ticket.

---

## Bối cảnh

ADR-TON-019 ghi rõ vấn đề và **năm hướng phải khảo sát**, nhưng cố ý **không
chấm điểm và không khuyến nghị** — vì lúc đó chưa có baseline đo được và Founder
chỉ thị *"không quyết định trước giải pháp."* Vòng này (WTM-391) giao đúng phần
còn thiếu: **baseline đã có** (query counts + aggregation fan-out, khoá ở
`test/features/tongtai/perf/`), nên giờ có thể chấm điểm **trên số**, không phải
trên phỏng đoán — và, theo `NON_BLOCKING_POLICY`, **kèm một khuyến nghị** thay vì
đẩy câu hỏi trần cho Founder.

Khuyến nghị này chỉ để Founder có điểm bắt đầu. **Founder Gate vẫn mở.**

---

## Bằng chứng đo được (không phải phỏng đoán)

Hai con số định hình mọi lựa chọn bên dưới.

### 1. Đọc lặp là ~80% chi phí, tổng hợp ~20% (60 tháng)

Từ `CAPABILITY-HYDRATION-BASELINE.md`: ở 60 tháng (18.083 đơn), một lần hydration
tốn **4.5×** một lượt đọc; trung bình mỗi bảng bị đọc **3.6 lần**. Trong 1.332ms
có ~**1.070ms là đọc lặp** và ~**260ms là tổng hợp**. ⇒ **Một hướng chỉ tối ưu
tổng hợp mà không giảm số lần đọc chạm được nhiều nhất ~20% của vấn đề.**

### 2. Aggregation fan-out — ai đọc bảng nào, mấy lần, trong MỘT lần hydration

Khoá mới ở `capability_aggregation_baseline_test.dart` (bất biến ở 3/12/24/60
tháng — fan-out là **thuộc tính của cách nối dây, không phải của dữ liệu**). Đây
là bảng "ai đọc `orders`" của ADR-TON-019, nay bằng **số khoá được**, không phải
văn xuôi:

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

**`orders` bị đọc 6 lần trong một lần hydration** — bởi sáu người tiêu thụ khác
nhau, mỗi lần đều chính đáng (ADR-TON-019). Đây là con số một hướng thắng phải
hạ được. (Cold start toàn cục đọc `customers` ×4, `goals` ×4, `products` ×3 —
phần dôi so với bảng trên là các tab Inventory/Consumer/Home đọc thêm **ngoài**
hydration; xem `capability_hydration_benchmark_test`.)

---

## Chấm điểm — 5 hướng × 8 trục

Thang: **★★★ = tốt cho mục tiêu · ★★ = trung bình · ★ = yếu/rủi ro.** "Mục tiêu"
= *một lượt đọc phục vụ nhiều Context, không phá One Data Path / Capability
Context, không cache toàn cục, UI không biết cache.*

| Trục (★ cao = tốt) | 1. Per-load scoped cache | 2. Shared aggregation pipeline | 3. `summarise(rows)` | 4. Drift query opt | 5. Hybrid (4+1) |
|---|:-:|:-:|:-:|:-:|:-:|
| **Complexity** (thấp = ★★★) | ★★ | ★ | ★★ | ★★ | ★ |
| **Maintainability** | ★★★ | ★ | ★★ | ★★ | ★★ |
| **Memory** (60 tháng) | ★★ | ★★ | ★★ | ★★★ | ★★★ |
| **Query count** (mục tiêu chính) | ★★★ | ★★★ | ★★★ | ★ | ★★★ |
| **Startup latency** | ★★★ | ★★★ | ★★★ | ★★ | ★★★ |
| **Steady-state** | ★★★ | ★★★ | ★★★ | ★★ | ★★★ |
| **Testability** | ★★★ | ★★ | ★★ | ★ | ★★ |
| **Architecture impact** (ít phá = ★★★) | ★★★ | ★ | ★ | ★★★ | ★★ |

### Vì sao từng ô như vậy

**1. Per-load scoped cache** — một "lượt tải" mang bộ nhớ đệm sống đúng bằng lượt
đó; lần đọc đầu mỗi bảng thật, các lần sau trong cùng lượt trả lại kết quả.
- **Query count ★★★:** `orders` 6→1 mỗi hydration — đánh trúng 80% chi phí.
- **Architecture ★★★:** contract Context **không đổi**, capability vẫn độc lập,
  UI không biết gì. Câu hỏi mở của 019 ("scope rò ra thành cache toàn cục?") có
  câu trả lời cơ học: **vòng đời cache = vòng đời object lượt-tải**, hết lượt là
  mất; không có tham chiếu sống lâu hơn ⇒ không thành nguồn sự thật thứ hai.
- **Testability ★★★:** scope inject được; `capability_aggregation_baseline_test`
  vẫn khoá được số (đọc lần đầu vẫn đếm 1); Rule Twin không đổi.
- **Complexity ★★:** phải luồn một object scope qua một lượt tải — việc thật
  nhưng khu trú.

**2. Shared aggregation pipeline** — một tầng đọc+tổng hợp chung, các Context
tiêu thụ.
- **Query count ★★★** nhưng **Architecture ★ / Maintainability ★:** tập trung hoá
  đúng thứ ADR-TON-016 cố ý phân tán. Nguy cơ **God Object** mà 019 nêu là thật;
  thêm một capability không còn là "thêm một provider" mà là "sửa pipeline".
  Capability mất khả năng chạy **on-demand độc lập**.

**3. `summarise(rows)` contract** — Context nhận rows đã đọc sẵn.
- **Query count ★★★** nhưng **Architecture ★:** đổi **chữ ký của mọi Context**
  (thay đổi rộng, phá vỡ) và làm mất tính "tự chạy được" — một màn chuyên sâu
  muốn chạy riêng một Context giờ phải tự đi đọc rows (câu hỏi mở của 019 không
  có lời giải sạch). Trái tinh thần ADR-TON-016.

**4. Drift query optimization** — đẩy tổng hợp xuống SQL; mỗi lần đọc **rẻ đi**
chứ không **ít lần đi**.
- **Query count ★:** **không** giảm số lần đọc — `orders` vẫn 6 round-trip. Theo
  bằng chứng #1, tự nó chạm tối đa ~20% + phần per-read.
- **Memory ★★★:** không giữ 18k dòng trong RAM — DB trả về vài con số. Đây là
  điểm mạnh thật ở đúng mốc Epic quan tâm (60 tháng).
- **Testability ★ / Maintainability ★★:** logic miền chạy vào SQL, xa Dart và xa
  Rule Twin authoritative (câu hỏi mở của 019: "Rule Twin còn kiểm được không?").
- **Architecture ★★★:** không đổi cấu trúc tầng.

**5. Hybrid (4 cho summary đếm-được-bằng-SQL + 1 cho phần cần rows thật)** — mạnh
nhất về hiệu năng/bộ nhớ nhưng **Complexity ★:** hai cơ chế cùng tồn tại, người
đọc code phải biết capability nào đi đường nào (câu hỏi mở của 019).

---

## Khuyến nghị (PROPOSED — chưa phê chuẩn)

> **Khuyến nghị: Hướng 1 (Per-load scoped cache) làm hướng chính; giữ Hướng 4
> (Drift query optimization) làm phần bổ sung có mục tiêu về sau — tức tiến tới
> Hướng 5 (Hybrid) CHỈ ở nơi bằng chứng cho thấy điểm nóng per-read/bộ nhớ ở 60
> tháng. Loại Hướng 2 (God Object — ADR-TON-016) và Hướng 3 (phá on-demand độc
> lập + đổi chữ ký rộng — ADR-TON-016).**

**Lý do, theo bằng chứng:**

1. Chi phí chính là **đọc lặp (~80%)** ⇒ hướng thắng **bắt buộc phải giảm số lần
   đọc**. Điều này loại ngay Hướng 4 khỏi vị trí *hướng chính* (nó không giảm số
   lần đọc), dù Hướng 4 có điểm mạnh bộ nhớ thật.
2. Trong các hướng giảm-số-lần-đọc, **ràng buộc cứng của Founder** loại Hướng 2
   (God Object) và Hướng 3 (phá "thêm capability = thêm một provider", đổi chữ ký
   mọi Context).
3. Còn lại **Hướng 1**: giảm đọc về 1×/bảng/lượt, **giữ nguyên** contract Context
   (UI không biết cache, capability độc lập), và rủi ro mở duy nhất của nó
   (scope rò thành cache toàn cục) **quản được bằng vòng đời** — trói cache vào
   object lượt-tải. Nó thoả **cả bốn** ràng buộc cứng.
4. Điểm mạnh thật của Hướng 4 (per-read cost + bộ nhớ ở 60 tháng) **bổ sung, không
   cạnh tranh**: có thể chồng lên sau, đúng chỗ một capability đọc bảng lớn mà
   chỉ cần một con số (ví dụ `COUNT`/`SUM`). Bắt đầu bằng Hướng 1 giữ complexity
   thấp và lấy ~80% phần thắng ngay; nâng lên Hybrid chỉ khi đo thấy cần.

**Độ tin cậy của khuyến nghị:** trung bình-cao cho phần *loại* Hướng 2/3 (ràng
buộc kiến trúc là cứng) và cho phần *chọn* Hướng 1 làm hướng chính (bằng chứng
80/20 rõ). Điểm còn phải xác nhận trên **thiết bị thật** trước khi refactor:
per-read cost ở 60 tháng — nếu nó lớn bất ngờ, trọng số Hướng 4/Hybrid tăng.

---

## Vì sao đây là khuyến nghị, không phải quyết định

Chọn hướng chạm vào ADR-TON-015 **hoặc** ADR-TON-016 đang hiệu lực, và có nhiều
hướng hợp lệ — đúng hai điều `CLAUDE.md` liệt kê là **Founder Gate** ("ADR
conflict" + "multiple genuinely valid directions"). Vé WTM-391 vì vậy **không**
triển khai giải pháp và **không** phê chuẩn ADR này. Một *khuyến nghị PROPOSED*
khác một *doctrine ACCEPTED*: nó cho Founder điểm bắt đầu, không thay Founder
quyết.

## Hệ quả

- **Nếu Founder duyệt (APPROVE):** ADR này chuyển ✅ ACCEPTED; ADR-TON-019 được
  đánh dấu subsumed-by-025; mở **story refactor riêng** (hướng đã duyệt) với DoD:
  hạ đúng bộ query counts đã khoá, không phá contract, `UI không biết cache`,
  các baseline test hiện có vẫn xanh (chúng sẽ là bằng chứng refactor thành công).
- **Nếu Founder từ chối/đổi (REJECT / REQUEST CHANGES):** ADR giữ PROPOSED hoặc
  ghi hướng Founder chọn; không có thay đổi code nào phải hoàn tác (vé này chỉ
  giao baseline + phân tích).
- **Dù thế nào:** baseline harness + fan-out test ở lại làm hàng rào chống hồi
  quy — chúng độc lập với việc chọn hướng nào.

## Continuation condition (Founder trả lời)

- **APPROVE OPTION 1** — nhận Per-load scoped cache là hướng chính (khuyến nghị).
- **APPROVE OPTION 4** / **OPTION 5** / **OPTION 2** / **OPTION 3** — chọn hướng khác.
- **REQUEST CHANGES: `<text>`** — muốn phân tích lại/thêm số thiết bị trước khi chọn.
- **DEFER** — để lại, tiếp tục roadmap (baseline vẫn canh hồi quy).

---

## Artifacts

- Baseline (khoá, chống hồi quy):
  `test/features/tongtai/perf/capability_hydration_benchmark_test.dart` (query
  counts, 4 mốc) · `test/features/tongtai/perf/capability_aggregation_baseline_test.dart`
  (aggregation fan-out, **mới**) · `cold_start_read_amplification_test.dart` ·
  `cold_start_scale_probe_test.dart`.
- Số liệu host + thiết bị: `docs/04-DELIVERY/perf/CAPABILITY-HYDRATION-BASELINE.md`.
- Khung vấn đề: `docs/03-DECISIONS/ADR-TON-019-capability-context-performance.md`.
