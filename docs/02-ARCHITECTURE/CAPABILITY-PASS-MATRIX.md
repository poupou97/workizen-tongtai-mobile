# Capability PASS Matrix

> **Founder Directive 2026-08-01 — Capability-Driven Backlog.**
> *"Capability PASS mới là Definition of Done cao nhất của sản phẩm."*
>
> Backlog **không** ưu tiên theo Story ID, ngày tạo, sprint hay Jira Priority.
> Mỗi vòng lặp tính lại điểm theo Capability Value.

**Cập nhật lần cuối:** 2026-08-01 · sau WTM-197/198/203/204

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
| **Business Journey** | ✅ | ✅ | ✅ | ⚠️ contained | ✅ | ✅ | ✅ | ✅ |
| **Opportunity** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Finance** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `?` | ✅ |
| **Consumer** | ✅ | ✅ | ✅ | ⚠️ contained | ✅ | `?` | `?` | ✅ |
| **Reports** | ✅ | ✅ | ✅ | ✅ | `?` | `?` | ✅ | ✅ |
| **Inventory** | ✅ | ✅ | ⚠️ | ⚠️ contained | ✅ | `?` | `?` | ✅ |
| **Producer** | ✅ | ❌ | `?` | ✅ | ✅ | `?` | `?` | ✅ |
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

### Finance — ❌ **Data FAIL**

- ✅ Doanh thu bán hàng đã vào Finance và **khớp Home/Reports** (WTM-196).
- ❌ **WTM-197 (P1 SSoT-ish, +80)** — `category` chi phí là **chuỗi tiếng Việt
  tự do**, ghi nguyên văn vào `.ttbk`. Đúng khuyết tật WTM-164 đã sửa cho enum
  v1 nhưng **sống sót vào v2** vì category không phải enum. Gõ khác hoa thường
  ⇒ hai nhóm; đổi ngôn ngữ ⇒ nhóm cũ kẹt lại.
- `?` **AI** — chưa audit khả năng AI của Finance (Concept đòi dự báo dòng
  tiền, cảnh báo tiền mặt < 15 ngày chi phí, ước tính thuế).

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

### Inventory — ⚠️ mối nối tiềm ẩn

`StockAlertService.minimumThreshold` (sàn toàn danh mục) có thể làm lệch khỏi
`Product.stockStatus`. Production **luôn truyền 0** nên hai bên trùng nhau hôm
nay. Không phải FAIL; ghi lại để ai bật sàn đó biết đây là chỗ sẽ gãy. `?` Data:
chưa audit giá vốn (thiếu `costPrice` là lý do ROI không tính được — xem
ADR-TON-022).

### Producer — ❌ **Data FAIL đã biết**

Danh bạ nhà cung cấp là `SupplierSearchService.sample()` — **dữ liệu mẫu**.
Founder đã quyết: **không rút capability khỏi Concept**, đánh dấu **Future
Capability**. Vì vậy đây là FAIL *có chủ đích và đã được chấp nhận*, không phải
việc cần sửa ngay — nhưng nó là lý do `supplierQuality` không chấm điểm được.

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

**Chọn vòng tới: WTM-203 (+100).** Audit WTM-202 cho thấy ba lỗi SSoT hôm nay
đều **bắt đầu từ một cột dẫn xuất trong schema**. Sửa từng chỗ đọc là chữa
triệu chứng; đây là nguồn. Và `churnRisk` là luật thứ hai **nằm trong schema**,
nơi không ai nghĩ tới khi đi tìm "luật" — khác với WTM-200b, chỗ luật thứ hai
nằm trong code nên grep ra được.

> ⚠️ Ô `?` không phải PASS. Sáu ô chưa audit là rủi ro chưa biết, và theo kinh
> nghiệm hôm nay — ba lỗi lớn nhất đều nằm ở vùng "tưởng ổn" — chúng đáng được
> audit trước khi thêm bất kỳ tính năng mới nào.
