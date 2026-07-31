# ADR-TON-019 — Capability Context Performance (một lượt đọc, nhiều Context)

- **Status:** 📝 **DRAFT — CHƯA QUYẾT ĐỊNH.** Founder mở Epic ngày 2026-07-31 với
  chỉ thị rõ: *"Không quyết định trước giải pháp."* File này ghi **vấn đề, ràng
  buộc, các hướng phải khảo sát và cách chấm điểm** — nó **không** chọn hướng nào.
- **Jira:** Epic WTM-167 · bằng chứng từ WTM-166
- **Liên quan:** ADR-TON-015 (One Data Path) · ADR-TON-016 (Capability Context ·
  Rule Twin · AI Runtime Boundary)

## Vấn đề

WTM-166 đo trên máy thật và tìm ra thứ không ai nhắm tới: **một lần khởi động
đọc `orders` 5 lần, `customers` 4 lần, `goals` 4 lần** (`products` ×3,
`finance` ×2).

Điều quan trọng nhất về con số đó: **không có lần đọc nào là sai.**

| ai đọc `orders` | vì sao chính đáng |
|---|---|
| `BusinessMetricsService` | KPI là nguồn sự thật riêng |
| `OrderContextProvider` | slice đơn hàng của snapshot |
| `JourneyContextProvider` | suy ra tiến độ mục tiêu doanh thu (WTM-138) |
| `TimelineContextProvider` | projection dòng hoạt động (WTM-134) |
| `OpportunityRuleEngine` | sinh cơ hội từ dữ liệu thật (WTM-139) |

Đây là **hệ quả trực tiếp của một quyết định đúng**: ADR-TON-016 quy định
Capability Context **độc lập, tải on-demand** — chính tính độc lập đó là thứ cho
phép thêm một capability mà không sửa cái nào khác. Chi phí của nó là đọc lặp.

**Nó không phải bài toán cold-start.** Ở khối lượng hiện tại toàn bộ hydration
tốn ~5ms và xong **trước** khung hình đầu tiên. Nó là bài toán **Architecture
Efficiency**, và nó lớn dần theo doanh nghiệp: ở 12 tháng buôn bán thật
(529 đơn · 42 khách · 544 giao dịch) chi phí đọc là **3.0×** mức cần thiết.
Người trả giá là người bán có nhiều dữ liệu nhất — người ít có khả năng đoán ra
vì sao app chậm dần.

## Mục tiêu

> **Một lượt đọc dữ liệu phục vụ nhiều Capability Context.**

**Không phải** "giảm vài mili-giây". Nếu kết quả chỉ là vài ms mà kiến trúc rối
thêm, đó là thua.

## Ràng buộc (Founder, không thương lượng)

1. **Không phá One Data Path** — ADR-TON-015. Vẫn là
   `Repository → Context Provider → BusinessContext → Screen`.
2. **Không phá Capability Context** — thêm một capability vẫn phải là thêm một
   provider, không phải sửa bảy chỗ.
3. **Không tạo cache toàn cục khó kiểm soát.** Một cache sống lâu hơn phạm vi nó
   phục vụ sẽ trở thành nguồn sự thật thứ hai — đúng thứ ADR-TON-015 cấm.
4. **UI không được biết tới cache.** Màn hình đọc `BusinessContext`, hết.

## Năm hướng phải khảo sát (chưa hướng nào được chọn)

### 1. Per-load scoped cache
Một "lượt tải" mang theo bộ nhớ đệm sống đúng bằng lượt đó. Contract của Context
không đổi.
*Câu hỏi mở:* ai sở hữu phạm vi, và điều gì bảo đảm nó không rò ra ngoài để
thành cache toàn cục?

### 2. Shared aggregation pipeline
Một tầng đọc + tổng hợp chung, các Context tiêu thụ kết quả của nó.
*Câu hỏi mở:* tầng này có trở thành God Object mà ADR-TON-016 cấm không?

### 3. `summarise(rows)` contract
Context nhận **rows đã đọc sẵn** thay vì tự đọc.
*Câu hỏi mở:* mất tính "on-demand độc lập" — một Context muốn chạy riêng
(ví dụ màn chuyên sâu) thì lấy rows ở đâu?

### 4. Drift query optimization
Không đổi kiến trúc; đẩy việc tổng hợp xuống SQL để mỗi Context đọc **ít hơn**
thay vì đọc **ít lần hơn**.
*Câu hỏi mở:* logic miền chuyển vào SQL thì test và Rule Twin còn kiểm được không?

### 5. Hybrid
Ví dụ: (4) cho các summary đếm được bằng SQL + (1) cho phần cần rows thật.
*Câu hỏi mở:* hai cơ chế cùng tồn tại có làm người đọc code khó đoán hơn không?

## Cách chấm điểm (tám trục, Founder chỉ định)

complexity · maintainability · memory · query count · startup latency ·
steady-state performance · testability · architecture impact.

**Quy tắc trung thực khi chấm:** query count là **số**, đo được và không đổi
theo máy ⇒ dùng được để so sánh. Startup latency chỉ được lấy từ **máy thật,
bản release** (Testing Bible P-16). Memory phải đo ở mốc dữ liệu lớn nhất
(60 tháng), vì đó là nơi "giữ rows trong bộ nhớ" có thể thua "đọc lại".

## Acceptance (sau khi chọn hướng)

- mỗi repository chỉ đọc **đúng mức cần thiết**;
- nhiều Capability Context **tái sử dụng** kết quả hợp lệ;
- **không** duplicate query · **không** duplicate aggregation;
- **không** phá contract hiện tại;
- **UI không biết tới cache**.

## Performance Governance (bắt buộc kèm theo)

Benchmark **cố định**, chạy ở **3 · 12 · 24 · 60 tháng**, lưu baseline:

| Số đo | Lấy ở đâu | Loại |
|---|---|---|
| repository query counts | test qua wiring production | **số** — không đổi theo máy |
| aggregation time | benchmark host | **tỉ lệ** — không tuyên bố là số của thiết bị |
| app startup · DB open · first frame · Home ready · capability hydration | `StartupTrace` trên **máy thật, bản release** | **mili-giây thiết bị** |

Baseline nằm trong repo và được so sánh mỗi lần chạy; hồi quy phải **đỏ**, không
phải được phát hiện bởi người dùng.

## Vì sao ADR này chưa quyết

Có ít nhất năm hướng hợp lệ, chúng đánh đổi khác nhau ở **kiến trúc** chứ không
chỉ ở hiệu năng, và hướng nào cũng chạm vào một quyết định đang có hiệu lực
(ADR-TON-015 hoặc ADR-TON-016). Theo `CLAUDE.md` đó là **Founder Gate**
("ADR conflict" + "multiple genuinely valid directions").

Vòng hiện tại vì vậy chỉ giao: **Epic · ADR draft này · benchmark baseline.**
