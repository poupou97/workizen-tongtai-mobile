# Capability PASS Matrix

> **Founder Directive 2026-08-01 — Capability-Driven Backlog.**
> *"Capability PASS mới là Definition of Done cao nhất của sản phẩm."*
>
> Backlog **không** ưu tiên theo Story ID, ngày tạo, sprint hay Jira Priority.
> Mỗi vòng lặp tính lại điểm theo Capability Value.

**Cập nhật lần cuối:** 2026-08-02 · WTM-212 DTV eliminated (v13) · WTM-213 hết ô ⚠️ · WTM-214 hết ô `?` · WTM-215/216 Group C concept-1 xong

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

## Điều kiện PASS bắt buộc — Journey Reachability (Founder 2026-08-02)

> *"Đối với mọi Capability L2+, phải chứng minh có ít nhất một User Journey hợp
> lệ dẫn tới capability đó, hoặc được đánh dấu rõ là **Future Capability /
> Intentionally Hidden** cùng lý do."*

Một capability **không PASS** khi màn của nó không có đường đi từ điểm vào của
app. Khoá bằng `p0/journey_reachability_test.dart`: đồ thị điều hướng **suy từ
code** (bỏ comment trước khi suy — một dòng tài liệu nhắc tên màn từng đủ tạo
ra *cạnh ma*), BFS từ shell/Home, mọi màn L2+ phải tới được hoặc nằm trong
danh sách khai báo **kèm nhãn + lý do**; ngoại lệ hết hạn cũng làm CI đỏ.

Lý do luật này tồn tại: WTM-218 — một màn ~600 dòng được **sáu** lượt governance
đánh bóng mà không ai mở được. Mọi suite đều đo **chất lượng** màn hình; không
suite nào đo **đường vào**. Chất lượng của một màn không ai tới được bằng 0 dù
CI xanh.

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
| **Producer** | ✅ | ❌ | ✅ | ✅ | ⚠️ WTM-218 | ✅ | — | ✅ |
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
đếm đúng. Nay dẫn xuất bằng `deriveCustomerCounters` — màn Consumer và
`CustomerDirectoryController` cùng gọi **một hàm**, cross-check chốt trong
`p0/single_source_of_truth_test.dart`. Trường đã lưu **không bị ghi đè**,
giống `deriveGoalsProgress`.

- ✅ UI (audit WTM-214): `ScreenDataController` seam (ADR-TON-017, screen
  `'consumer'`) · L3 trong ma trận levels (WTM-26/75) · suite a11y + overflow
  phủ `consumer` · suite hành vi riêng của bug gốc.
- ✅ AI (audit WTM-214): `CustomerCapabilityContext` versioned (ADR-TON-016)
  → `customer_risk_rule` trả `RuleTwinResult` + `business_alerts_rule`
  (`customerRisk`) — Rule Twin authoritative, thang lifecycle có ngưỡng ghi
  lý do bằng nhịp mua của chính khách.

### Reports — ✅ hoàn thành

Dùng chung `isBillableOrder` và cùng cách tính `totalAmount` với
`BusinessMetrics` ⇒ không thể lệch định nghĩa "một lần bán". Doanh thu theo
kênh: đơn chưa ghi kênh nằm trong tổng, ngoài breakdown (WTM-209).

- ✅ IA (audit WTM-214): sau khi 5 tab kín (WTM-192), Reports mở từ KPI header
  Home (`home-open-reports`) — luật reachability chốt trong
  `p0/nav_availability_test.dart` + widget test mở màn thật.
- ✅ UI (audit WTM-214): L4 (WTM-95/96/97) · seam ADR-TON-017 · ~20 stable
  `reports-*` IDs · suite a11y + overflow phủ `reports`.

### Inventory — ✅ hoàn thành (WTM-213 đóng mối nối cuối)

`StockAlertService.minimumThreshold` (sàn toàn danh mục) từng có thể làm lệch
khỏi `Product.stockStatus` — hai quy tắc cho một khái niệm "sắp hết hàng",
dạng P-27, cùng họ `lapsedCustomerDays` (WTM-201). Production luôn truyền 0 và
không setting nào ghi sàn đó, nên WTM-213 **xoá tham số**:
`StockAlert.forProduct` nay đọc thẳng `stockStatus` — badge và màn cảnh báo
không thể lệch nhau vì cùng một dòng code. Sweep chốt trong
`p0/single_source_of_truth_test.dart`. Data ✅: `costPrice` đã nối (WTM-204),
ROI tính từ giá vốn thật (WTM-207).

### Producer — ❌ Data (có chủ đích) · ⚠️ IA (WTM-218)

**Sửa ô IA: trước ghi ✅ mà chưa ai kiểm lối vào của màn chính.**
`TongtaiSupplierSearchScreen` (~600 dòng, L3, có test/a11y/l10n) **chưa bao giờ
có caller production** — `git log -S` cho thấy nó vào repo từ commit bootstrap
và không commit nào từng thêm navigation tới nó. Tab Producer chỉ push được
*Nhà cung cấp yêu thích*. Capability mà động từ chính là *tìm nguồn hàng* đang
không có màn tìm.

**Cố ý không nối** (không phải bỏ sót nữa): danh bạ là
`SupplierSearchService.sample()` — nhà cung cấp bịa. Nối vào tab sẽ trưng danh
bạ bịa cho người bán thật, sai đúng thứ quyết định *Future Capability* bảo vệ.
Ghi vào `intentionallyUnreached` trong `p0/nav_availability_test.dart` kèm lý
do; CI đỏ nếu có màn mồ côi mới, hoặc nếu màn này được nối mà quên gỡ ngoại lệ.

**Root cause đáng nhớ:** sáu lượt governance (WTM-146/147/148/168/171/194) đã
sửa chính file đó — test, maturity model, error seam, a11y, hai lượt l10n —
mà không lượt nào hỏi *"người bán có mở được màn này không?"*. Governance đo
**chất lượng** màn hình, không đo **tính tới-được**.

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

## Backlog đã tính điểm (vòng hiện tại — sau WTM-214)

Các mục vòng trước đã đóng hết: WTM-203 (DTV contained → **eliminated** ở
WTM-212, schema v13) · WTM-197 (category canonical) · WTM-204 (`costPrice` nối
domain, mở khoá ROI WTM-207) · WTM-198 (hành trình có bước tiền + công nợ
WTM-211) · IA Finance (WTM-206) · audit ô `?` (WTM-214, bảng này).

| Hạng | Việc | Loại | Điểm | Trạng thái |
|---|---|---|---|---|
| 1 | **Producer Data** — danh bạ NCC là sample | P0 nhưng **Future Capability theo Founder** — *"Không cố xây AI bằng dữ liệu giả"* | (+100) treo | chờ nguồn dữ liệu thật |
| 2 | Group B concept-1 (6 mục scope sản phẩm) | P5 UI lệch Concept | +40 | **chờ Founder framing** |
| ~~3~~ | ~~Group C concept-1 (donut tồn kho · dải thẻ sắp hết · mascot header)~~ | P8 polish | ~~+10~~ | ✅ **xong** (WTM-215 · WTM-216) |
| 4 | Business Context Builder | kiến trúc | — | PROPOSED, điều kiện *all P0 PASS* đã đạt — chờ Founder duyệt ADR |

**Trạng thái sau vòng 2026-08-01/02 (WTM-213→216):** bảng chính **hết ô `?` và
hết ô ⚠️** — mọi ô hoặc ✅ có bằng chứng, hoặc ❌/— có chủ đích được Founder
quyết (Producer Data, AI Producer). Theo thứ tự capability của Founder
(Journey → Finance → Consumer → Inventory → Opportunity → Producer): 5/6 PASS,
Producer là Future Capability. **Group C concept-1 đã đóng** (WTM-215 donut +
dải thẻ; WTM-216 header mascot + phụ đề). Việc còn lại trên bàn **đều chờ
quyết định của Founder** — không còn hạng mục nào thuộc thẩm quyền tự quyết.
