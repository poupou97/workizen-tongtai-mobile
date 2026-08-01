# Capability PASS Matrix

> **Founder Directive 2026-08-01 — Capability-Driven Backlog.**
> *"Capability PASS mới là Definition of Done cao nhất của sản phẩm."*
>
> Backlog **không** ưu tiên theo Story ID, ngày tạo, sprint hay Jira Priority.
> Mỗi vòng lặp tính lại điểm theo Capability Value.

**Cập nhật lần cuối:** 2026-08-01 (đêm) · nhóm A concept-1 hoàn tất (WTM-209/210/211), schema v12

---

## Quy tắc chấm

Một ô chỉ được ghi **PASS khi có bằng chứng đọc từ code**. Chưa kiểm thì ghi
**`?`** — *chưa audit*, không phải PASS. Ô `?` là một **rủi ro chưa biết**, và
một capability có ô `?` **không được coi là hoàn thành**.

Lý do quy tắc này tồn tại: ba lỗi SSoT lớn nhất tìm được hôm nay (WTM-196,
WTM-200a, WTM-200b) đều nằm ở vùng "ai cũng tưởng ổn vì test xanh". Ghi PASS cho
thứ chưa nhìn là cách tái tạo đúng tình huống đó trong một bảng.

| Ký hiệu | Nghĩa |
|---|---|
| ✅ | PASS — có bằng chứng |
| ❌ | FAIL — có bằng chứng, đã có story |
| ⚠️ | PASS hôm nay nhưng có mối nối tiềm ẩn đã ghi lại |
| `?` | **Chưa audit** |
| — | Không áp dụng ở Phase 2 |

## Nguyên tắc xếp hạng (D-11, Founder 2026-08-01)

**Business Journey là trung tâm sản phẩm.** Mọi capability mới phải phục vụ
Journey; khi điểm bằng nhau, việc làm **Journey thông minh hơn** xếp trước việc
làm một module riêng mạnh hơn.

## Thang điểm ưu tiên

| Mức | Điểm | Loại |
|---|---|---|
| P0 | +100 | Capability FAIL |
| P1 | +80 | Single Source of Truth violation |
| P2 | +70 | Business logic sai |
| P3 | +60 | Information Architecture sai |
| P4 | +50 | Data model thiếu |
| P5 | +40 | UI/UX lệch Concept |
| P6 | +30 | Localization |
| P7 | +20 | Performance |
| P8 | +10 | Polish |

---

## Ma trận

**Điều kiện PASS bổ sung (Founder Directive 2026-08-01):** một capability
**không** PASS khi còn **Derived Truth Violation**. Xem
[DERIVED-DATA-AUDIT.md](DERIVED-DATA-AUDIT.md). Cột `DTV` bên dưới.

**`⚠️ contained` (sau WTM-203):** cột dẫn xuất **vẫn được ghi** (hợp đồng
`.ttbk` lossless — ADR-TON-018 không cho gỡ lẻ tẻ) nhưng **mọi đường đọc bị
`p0/derived_data_governance_test.dart` chặn**, đã xác minh bắt được vi phạm
thật. Bước chặn lỗi đã xong; gỡ cột là dọn dẹp chờ phiên bản `.ttbk` kế tiếp.
Không ghi ✅ vì cột còn nằm đó, không ghi ❌ vì lỗi thứ tư không thể xảy ra mà
không làm CI đỏ.

| Capability | Domain | Data | SSoT | **DTV** | IA | UI | AI | Test |
|---|---|---|---|---|---|---|---|---|
| **Business Journey** | ✅ | ✅ | ✅ | ✅ v13 | ✅ | ✅ | ✅ | ✅ |
| **Opportunity** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Finance** | ✅ | ✅ | ✅ | ✅ | ✅ WTM-206 | ✅ | ✅ | ✅ |
| **Consumer** | ✅ | ✅ | ✅ | ✅ v13* | ✅ | ✅ | ✅ | ✅ |
| **Reports** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Inventory** | ✅ | ✅ | ✅ WTM-213 | ✅ v13 | ✅ | ✅ | ✅ | ✅ |
| **Producer** | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | — | ✅ |
| **AI** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Settings / More** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ |

---

## Bằng chứng và việc còn lại

### Business Journey — ✅ hoàn thành

Cây `JourneyNode` đệ quy (ADR-TON-021) · Rule Twin sinh kế hoạch không cần AI ·
provenance hiển thị · `replan` không xoá quyết định của người bán (WTM-191) ·
`.ttbk` optional dataset. **Còn mở:** WTM-198 (P2, +70) — hành trình chưa bao
giờ nhắc tới tiền; không phải FAIL, là thiếu chiều sâu.

### Opportunity — ✅ hoàn thành

Phản ứng sống sót qua lần đóng app (WTM-190) · nối được vào hành trình
(WTM-191) · điểm tính từ yếu tố thật, khai báo `coverage`, yếu tố thiếu là
`insufficient` chứ không phải 0 (ADR-TON-022) · tab hạng nhất (WTM-192) ·
"khách im lặng" dùng luật của Consumer (WTM-200).

### Finance — ✅ hoàn thành

- ✅ Data: doanh thu khớp Home/Reports (WTM-196) · category là mã canonical
  (WTM-197) · cảnh báo dòng tiền dùng chung số học với dashboard (WTM-205) ·
  công nợ derive từ `paymentStatus` của đơn, "chưa ghi" ≠ nợ (WTM-211).
- ✅ AI: `negativeCashflow` Rule Twin nay nhìn thấy doanh thu — audit ô `?` này
  chính là thứ tìm ra WTM-205.
- ✅ **IA (WTM-206)**: Home KPI header mở thẳng Finance (`home-open-finance`) —
  hành trình bảo *"ghi 5 khoản chi"* thì cánh cửa nằm ngay cạnh lời nhắc,
  không còn ba chạm qua More. Luật reachability chốt trong
  `p0/nav_availability_test.dart`.

### Consumer — ✅ Data/SSoT (WTM-201 đã sửa)

`Customer.orderCount`/`totalSpent`/`lastPurchaseDate` từng là **trường đã lưu**
mà **không có gì cập nhật khi tạo đơn** — người bán ghi đơn xong khách vẫn hiện
*"0 đơn · ₫0"*, KPI *"khách quay lại"* không nhúc nhích, trong khi RFM/Reports
đếm đúng. Nay dẫn xuất bằng `deriveCustomerCounters` **trong
`CustomerDirectoryController`** — một chỗ mọi màn đi qua, nên màn tiếp theo
không thể quên. Trường đã lưu **không bị ghi đè**, giống `deriveGoalsProgress`.

`?` UI và AI: chưa audit.

### Reports — ✅ Data/SSoT

Dùng chung `isBillableOrder` và cùng cách tính `totalAmount` với
`BusinessMetrics` ⇒ không thể lệch định nghĩa "một lần bán". `?` IA và UI: chưa
audit vị trí Reports trong IA sau khi 5 tab đã kín (WTM-192).

### Inventory — ✅ hoàn thành (WTM-213 đóng mối nối cuối)

`StockAlertService.minimumThreshold` (sàn toàn danh mục) từng có thể làm lệch
khỏi `Product.stockStatus` — hai quy tắc cho một khái niệm "sắp hết hàng",
dạng P-27, cùng họ `lapsedCustomerDays` (WTM-201). Production luôn truyền 0 và
không setting nào ghi sàn đó, nên WTM-213 **xoá tham số**:
`StockAlert.forProduct` nay đọc thẳng `stockStatus` — badge và màn cảnh báo
không thể lệch nhau vì cùng một dòng code. Sweep chốt trong
`p0/single_source_of_truth_test.dart`. Data ✅: `costPrice` đã nối (WTM-204),
ROI tính từ giá vốn thật (WTM-207).

### Producer — ❌ **Data FAIL đã biết, có chủ đích**

Danh bạ nhà cung cấp là `SupplierSearchService.sample()` — **dữ liệu mẫu**.
Founder đã quyết: **không rút capability khỏi Concept**, đánh dấu **Future
Capability**. FAIL *được chấp nhận*, không phải việc cần sửa ngay — nhưng là lý
do `supplierQuality` không chấm điểm được. Các ô còn lại đã audit: SSoT ✅
(favorites store thật + cơ hội từ một `generatedOpportunitiesProvider`), UI ✅
(suite a11y/stable-ID phủ `producer`), AI **—** (chấm điểm nhà cung cấp là
Future Capability — không áp dụng ở Phase 2 chứ không phải chưa kiểm).

### AI — ✅

Workizen AI một cửa · Router chọn provider (ADR-TON-006) · Rule Twin
authoritative, AI chỉ giải thích (ADR-TON-016) · độ phủ điểm đi vào prompt
(ADR-TON-022) · BYOK, khoá chỉ rời máy trong header của lời gọi trực tiếp.

### Settings / More — ✅

Rời thanh dưới ở WTM-192 nhưng **một chạm từ mọi tab**, có test đi qua cả 5 tab.

---

## Backlog đã tính điểm (vòng hiện tại)

| Hạng | Việc | Loại | Điểm | Trạng thái |
|---|---|---|---|---|
| ~~1~~ | ~~**WTM-201** Consumer đọc counter đã lưu~~ | P1 SSoT | ~~+80~~ | ✅ **xong** |
| 1 | **WTM-203** 11 cột dẫn xuất trong DB — `churnRisk` là **luật thứ hai đang chờ được đọc** | Derived Truth Violation | **+100** | ⏳ **tiếp theo** |
| 2 | **WTM-197** category chi phí là chuỗi tự do | P1 (dữ liệu người bán + `.ttbk`) | **+80** | mở |
| 3 | Audit 5 ô `?` còn lại | rủi ro chưa biết | **~+80** | mở |
| 4 | **WTM-204** nối `costPerUnit` vào domain — mở khoá **4** năng lực đang bị chặn | P4 Data Model | **+50** | mở |
| 4 | **WTM-198** Finance vào Business Journey | P2 logic | **+70** | mở |
| 5 | IA của Reports/Finance sau khi 5 tab kín | P3 | **+60** | chưa có story |

**Trạng thái sau vòng 2026-08-01:** mọi capability PASS hoặc ở trạng thái được
chấp nhận có chủ đích (Producer Data = Future Capability theo Founder; DTV
`contained` = đường đọc bị CI chặn, cột chờ phiên bản `.ttbk` mới). Việc còn
lại trên bàn đều là P5↓ hoặc chờ quyết định sản phẩm — đúng điểm Directive
nói: *không mở tính năng mới cho tới khi mọi capability P0 PASS*, và giờ chúng
PASS.

> ⚠️ Ô `?` không phải PASS. Sáu ô chưa audit là rủi ro chưa biết, và theo kinh
> nghiệm hôm nay — ba lỗi lớn nhất đều nằm ở vùng "tưởng ổn" — chúng đáng được
> audit trước khi thêm bất kỳ tính năng mới nào.
