# ADR-TON-021 — Business Journey Domain Model

- **Trạng thái:** 📝 DRAFT — chờ Founder duyệt
- **Ngày:** 2026-08-01
- **Nguồn:** Founder Decision *"Business Journey trở thành P0"* + Capability
  Audit (`docs/01-PRODUCT/BUSINESS-JOURNEY-BIBLE.md` ↔ `lib/features/tongtai/journey/`)
- **Liên quan:** ADR-TON-009 (migration cộng thêm) · ADR-TON-016 (Rule Twin
  authoritative · AI Runtime Boundary) · ADR-TON-018 (`.ttbk` optional dataset)
- **Yêu cầu Founder:** *"ADR không chỉ mô hình hoá Goal/Milestone/Mission/Step/
  Task, mà cần thiết kế Business Journey đủ rộng cho các capability AI sau này.
  **Ưu tiên khả năng mở rộng** thay vì chỉ đáp ứng implementation hiện tại."*

---

## Bối cảnh

`BUSINESS-JOURNEY-BIBLE.md` mô tả 6 tầng:

```
Business Intent → Journey Plan (8 bước) → Milestone → Mission → Step → Task
```

Sản phẩm hôm nay có **tầng 1** (`BusinessGoal`: tên · loại · số tiền · ngày ·
ghi chú) và một thanh tiến độ suy ra từ đơn hàng thật.

Hệ quả đo được: Concept phân biệt Journey với Workflow ở chỗ người dùng hỏi
*"tôi có đang đi đúng hướng tới mục tiêu không?"*. Sản phẩm trả lời được
*"đã đạt bao nhiêu %"* — **không** trả lời được *"đúng hướng không"*, vì
**không có kế hoạch để so**.

## Quyết định

### 1. Một cây node, không phải bốn bảng cứng

**KHÔNG** tạo bốn bảng `Milestone` / `Mission` / `Step` / `Task`. Tạo **một**
`JourneyNode` đệ quy:

```
Journey (root — gắn với 1 BusinessGoal)
└── JourneyNode  (kind, parentId, orderIndex)
    └── JourneyNode
        └── …
```

`JourneyNodeKind` = `milestone` · `mission` · `step` · `task` (mở rộng sau).

**Vì sao — đây là chỗ "ưu tiên mở rộng" có nghĩa cụ thể:**

| Bốn bảng cứng | Một cây node |
|---|---|
| Thêm một loại (`decision`, `review`, `gate`) = **migration + bảng mới + repository mới** | = **thêm một giá trị enum** |
| Độ sâu bị khoá ở 4 | độ sâu tuỳ ý — một milestone có thể chứa milestone con |
| Bốn đường ghi, bốn chỗ có thể quên `.ttbk` | một đường ghi |
| Truy vấn "mọi việc chưa xong" = 4 join | một truy vấn |

Cái mất: mỗi kind không có cột riêng. Giải bằng **domain snapshot** đúng
ADR-TON-009 — cột có cấu trúc cho thứ dùng chung, snapshot cho phần riêng của
từng kind, promote khi có trigger nghiệp vụ thật.

### 2. Mỗi node ghi **nguồn gốc**, không chỉ nội dung

```dart
enum JourneyNodeOrigin { user, ruleTwin, ai }
```

**Đây là điều khoản quan trọng nhất của ADR này.** ADR-TON-016 quy định
*Rule Twin authoritative, AI chỉ giải thích*. Nếu node không ghi ai tạo ra nó
thì sáu tháng nữa **không ai phân biệt được** bước nào do luật sinh ra và bước
nào do model nói ra — và lúc đó ranh giới ADR-TON-016 chỉ còn là lời hứa.

Quy tắc kèm theo:
- `ai` **không được** đặt `isCompleted`. AI đề xuất; **người** hoàn thành.
- Một node `ai` phải **luôn** có node `ruleTwin` hoặc `user` làm cha, hoặc là
  đề xuất chờ người chấp nhận. AI không được tạo nhánh mồ côi.
- Test khoá cả hai.

### 3. Hoàn thành **suy ra được**, không chỉ tick tay

```dart
enum JourneyCompletion { manual, derived }
```

`derived` gắn với một chỉ số thật (doanh thu · số đơn · số khách · tồn kho).
Hôm nay `BusinessGoal.progress` đã suy từ đơn hàng thật chứ không để người dùng
tự khai — **giữ nguyên tinh thần đó xuống tầng node**.

Vì sao mở rộng: capability AI tương lai (*Alert khi lệch hướng*, *Forecast ngày
về đích*) chỉ chạy được nếu tiến độ là **dữ kiện đo được**, không phải ô tick.
Một hành trình toàn tick tay thì AI chỉ đọc lại được điều người dùng vừa gõ.

### 4. Kế hoạch **có phiên bản**, không ghi đè

```
JourneyPlan { version, generatedBy, generatedAt, reasonCodes[] }
```

Lập lại kế hoạch = **version mới**, giữ version cũ. Concept quy định
*"AI Adaptation — Journey can adjust if circumstances change"*; nếu ghi đè thì
người dùng thấy kế hoạch tự đổi mà không biết vì sao, và **không có gì để so**.

`reasonCodes` là mã cố định do Rule Twin đặt (`goal.behind_pace`,
`profile.seasonal_tet`, …) — cùng khuôn với `TongtaiFailure` và Opportunity
signals: hữu hạn, không sinh từ dữ liệu, **an toàn cho telemetry**.

### 5. Trạng thái ở **hai cấp**

- `JourneyState` (root): `draft · active · paused · completed · archived` —
  đúng 5 trạng thái Bible.
- `JourneyNodeState`: `pending · inProgress · done · skipped · blocked`.

`skipped` và `blocked` không có trong Bible nhưng **Bible đòi** *"Failure
Recovery — nếu một bước thất bại, AI gợi ý thay thế"*. Không có `blocked` thì
không biểu diễn được "thất bại", và quy tắc đó không thể hiện thực hoá.

### 6. Template tách khỏi instance

`JourneyTemplate` sinh ra `Journey`. Bible gọi là **Playbook**
(*"hành trình tham chiếu từ thành công của người khác"*).

Phase 2 **chỉ có template do Rule Twin sinh tại chỗ** — không tải về, không
chia sẻ, không cần mạng (D-5). Nhưng **tách khái niệm ngay từ đầu**, vì gộp
template vào instance là thứ sau này không gỡ ra được mà không migration đau.

### 7. Nhiều Journey được lưu, một Journey **active**

Bible: *"One Active Journey at a Time"*. Đó là **quy tắc nghiệp vụ**, không
phải ràng buộc lưu trữ. Model cho phép nhiều journey (`paused`, `archived`);
tầng domain enforce đúng một `active`.

Gộp hai thứ này lại sẽ khiến "tạm dừng mục tiêu A để chạy mục tiêu B" trở thành
xoá dữ liệu.

## Ràng buộc bắt buộc khi hiện thực hoá

1. **Migration cộng thêm** (ADR-TON-009) — không đụng 18 bảng đang có.
2. **`.ttbk` v2: dataset OPTIONAL**, KHÔNG thêm vào `BackupDatasets.all` —
   thêm vào `all` sẽ khiến **mọi file backup đã tồn tại không khôi phục được**
   (bài học WTM-177, có test khoá).
3. **Rule Twin chạy không cần AI/mạng/khoá** — sinh kế hoạch là luật, không phải
   model. Thiếu dữ liệu ⇒ trả `insufficient`, **cấm bịa bước**.
4. **Không Tool Runtime** — node không tự thực thi gì. ADR-TON-016 vẫn khoá.
5. **One Data Path** (ADR-TON-015) — Journey đọc qua Capability Context, không
   để màn tự query.
6. **Provider mới phải vào `kBusinessDataProviders`** — quên là sau restore, AI
   đọc hành trình của doanh nghiệp cũ (bài học WTM-177).

## Cái ADR này **không** quyết

- **Không** quyết 8 bước cụ thể cho từng `GoalType` — đó là nội dung, thuộc J2.
- **Không** mở Tool Runtime.
- **Không** quyết UI. J3 làm sau, và IA phải theo Concept (Journey là P0, không
  nằm trong danh sách cài đặt).
- **Không** làm Playbook chia sẻ giữa người dùng — cần backend, đang hoãn
  (ADR-TON-020).

## Đánh đổi, nói thẳng

**Cây node đắt hơn bốn bảng cứng ở lần đầu.** Truy vấn đệ quy khó viết hơn,
test khó hơn, và với đúng 4 kind hôm nay thì bốn bảng đơn giản hơn thật.

Tôi vẫn chọn cây node vì Founder yêu cầu ưu tiên mở rộng, và vì **mọi capability
AI trong Bible đều sinh ra node mới**: Planner sinh step, Adapter sinh nhánh
thay thế, Opportunity gắn vào step, Playbook sinh cả cây. Với bốn bảng cứng,
mỗi capability đó là một migration.

Nếu Founder muốn rẻ trước, phương án thay thế là bốn bảng cứng + chấp nhận
migration cho mỗi loại node mới. **Tôi không khuyến nghị**, nhưng nó là lựa chọn
hợp lệ và tôi nêu ra thay vì giấu.
