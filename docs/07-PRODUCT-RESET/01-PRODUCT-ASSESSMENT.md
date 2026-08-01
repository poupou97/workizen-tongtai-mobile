# Current Product Assessment · Vision Drift · Blueprint Drift · IA Review · Capability Gap

*(Báo cáo 2–6 trong 24)*

---

# 2. Current Product Assessment

## Chuỗi Vision → Sản phẩm, từng mắt một

| Mắt xích | Tài liệu / hiện vật | Trạng thái |
|---|---|---|
| **Vision** | `PRODUCT-VISION.md` — 8 capability, "AI ở trung tâm, tổ chức quanh mục tiêu người dùng, không quanh tính năng phần mềm" | ✅ có, rõ, có North Star |
| **Blueprint** | `PRODUCT-SCOPE.md` + `CAPABILITY-MAP.md` + `CAPABILITY-BIBLE.md` + `DOMAIN-MODEL.md` | ✅ có, và **có ranh giới rõ** |
| **IA** | `INFORMATION-ARCHITECTURE.md` (7 pattern điều hướng, 6 luồng xuyên module) + `NAVIGATION-MAP.md` | ✅ có, rất chi tiết |
| **Capability** | 8 capability + Dependency Matrix 8×8 | ✅ có |
| **Epic** | Jira WTM — sau audit hôm nay: 10 issue mở, phần còn lại Done có bằng chứng | ✅ đã đồng bộ với thực tế |
| **Implementation** | 35 màn · 1419 test · CI xanh · chạy trên 2 máy thật | ✅ |
| **Current Product** | 8/8 capability có màn hình + dữ liệu thật + chạy offline | ✅ |

**Chuỗi này không đứt ở đâu cả.** Đó là kết luận quan trọng nhất của Phase 1, và
nó ngược với giả định của directive.

## Điểm ĐÚNG (giữ nguyên, đừng đụng)

1. **Rule Twin authoritative, AI chỉ giải thích** (ADR-TON-016). Con số do quy
   tắc tất định tính; AI diễn giải. Chạy được khi không mạng, không khoá. Đây là
   thứ hiếm — phần lớn "AI-first app" để AI tự bịa số.
2. **Local-first thật, không phải khẩu hiệu.** Không tài khoản, không máy chủ.
   Đã kiểm chứng bằng chính sách quyền riêng tư viết theo hành vi thật.
3. **Seam kiến trúc chịu lực.** ADR-TON-015 (One Data Path) · 016 (Capability
   Context) · 017 (Error seam) · 018 (Snapshot Package). Chúng đã **bắt được lỗi
   thật** nhiều lần — không phải giấy tờ trang trí.
4. **Governance có răng.** 1419 test; các ratchet test đã chặn hồi quy thật
   (query counts, contrast, tap target, overflow).
5. **Backup lossless + đường lùi đã kiểm chứng trên máy.** Rất ít sản phẩm ở
   giai đoạn này làm được.

## Điểm SAI / còn yếu

| Vấn đề | Bằng chứng | Mức |
|---|---|---|
| **Opportunity chỉ là rule engine nội bộ** | `opportunity_rule_engine.dart` sinh cơ hội từ **dữ liệu của chính người dùng** (hết hàng, khách im lặng, hụt mục tiêu) | ⚠️ Vision hứa "arbitrage, market gap, cross-border" — thứ **cần dữ liệu ngoài**. Đây là khoảng cách thật, xem §4 |
| **Producer không có nguồn hàng thật** | `kSampleSuppliers` là fixture | ⚠️ capability "Nguồn Hàng" hiện là danh bạ tĩnh |
| **Chưa có Marketing capability** | Vision liệt kê Consumer gồm "omnichannel, community, affiliate" — chưa có | ⚠️ |
| **iOS chưa build/ký** | — | ⚠️ chặn phát hành nửa thị trường |
| **Không có kênh phản hồi người dùng** | "Gửi phản hồi" = Sắp có | ⚠️ sắp phát hành mà không có đường nghe người dùng |

## Điểm DRIFT (thật sự lệch)

Chỉ tìm được **một**, và nó nhỏ:

- **`ROADMAP.md` lệch thực tế vài tháng** — ghi *"Phase 1B đang chạy, 1–28/8"*
  trong khi Phase 2 đã thực thi xong. **Đã sửa hôm nay** (thêm bảng đối chiếu).

Ngoài ra: `INTEGRATION-MAP.md` mô tả 12+ hệ thống ngoài như thể sẽ có, trong khi
`PRODUCT-SCOPE.md` xếp chúng ngoài phạm vi. Hai tài liệu **nói khác nhau** — đây
là mâu thuẫn nội bộ cần Founder chốt (xem §3).

## Điểm CÒN THIẾU

1. Kết nối dữ liệu ngoài dưới **bất kỳ** hình thức nào (kể cả nhập file).
2. Marketing / omnichannel.
3. Logistics.
4. Nguồn dữ liệu thị trường cho Opportunity.
5. Kênh phản hồi + phân tích sử dụng (telemetry hiện chỉ 2 sự kiện).

## Điểm NÊN BỎ

| Bỏ gì | Vì sao |
|---|---|
| **`INTEGRATION-MAP.md` ở dạng hiện tại** | Nó mô tả một kiến trúc tích hợp chưa được duyệt và mâu thuẫn Scope. Nên **hạ cấp thành `research/`** hoặc viết lại theo hướng Founder chọn |
| **Màn `component_showcase`** | Dev-only, không có đường vào production |
| **Ngôn ngữ "12+ external systems"** trong docs | Tạo kỳ vọng sai cho người đọc mới |

---

# 3. Vision Drift Analysis

## Kết luận: **KHÔNG có vision drift theo hướng thường gặp**

Sản phẩm không "trôi" đi đâu cả. Nó **thực thi đúng lát cắt Phase 2 của Vision**.

Bằng chứng đối chiếu từng capability:

| Vision nói | Sản phẩm có | Khớp? |
|---|---|---|
| Producer — sourcing hub, AI scoring | màn Producer + supplier search + favourites (dữ liệu mẫu) | ⚠️ **một phần** — không có nguồn thật |
| Inventory — catalog, SKU, stock, pricing | đầy đủ, Drift-backed, phân trang, cảnh báo tồn | ✅ |
| Consumer — CRM/CDP, segment, journey | CRM + RFM segmentation + risk | ⚠️ thiếu omnichannel/affiliate |
| Finance — revenue, expense, cashflow | đầy đủ | ✅ |
| Reports — KPI, trend, forecast | đầy đủ + dự báo doanh thu | ✅ |
| Business Journey — goal → AI plan → tracking | đầy đủ, progress **auto-derive từ đơn thật** | ✅ |
| Opportunity Hub — AI phát hiện cơ hội | rule engine trên dữ liệu **nội bộ** | ⚠️ **một phần** |
| AI Copilot — chat, recommendation, alert | đầy đủ (G-3A→D) | ✅ |

**5/8 khớp trọn. 3/8 khớp một phần — và cả ba đều thiếu cùng một thứ: dữ liệu
từ bên ngoài.**

Đó là chẩn đoán chính xác hơn "drift": sản phẩm **đúng hướng nhưng đói dữ liệu
ngoài**, và Scope đã cố ý hoãn dữ liệu ngoài sang Phase 3.

## Drift thật nằm ở đâu

**Giữa hai tài liệu của chính chúng ta:**

| `PRODUCT-VISION.md` | `PRODUCT-SCOPE.md` |
|---|---|
| "arbitrage, cross-border sourcing, market gap" | "Tích hợp thật … chỉ adapter/stub" |
| "omnichannel" | (không nhắc) |
| "Continuous opportunity discovery" | Local-first, không backend |

Vision hứa một sản phẩm **có kết nối**; Scope xây một sản phẩm **đóng kín**.
Cả hai đều được viết bởi cùng một đội, cùng một Phase 1. **Đây là mâu thuẫn cần
Founder chốt**, và directive hôm nay chính là lúc chốt nó.

---

# 4. Blueprint Drift Analysis

**Blueprint (Capability Map + Domain Model + Capability Bible) không drift.**

- Dependency Matrix 8×8 vẫn đúng với code: Finance đọc Orders, Reports đọc tất
  cả, Journey suy tiến độ từ Orders. Kiểm chứng được bằng chính benchmark
  hydration (orders bị đọc bởi 5 consumer — đúng như matrix mô tả).
- `DOMAIN-MODEL.md` khớp schema Drift 17 bảng.
- **ADR-TON-016 mở rộng Blueprint đúng cách**: Capability Context + Rule Twin là
  thứ Blueprint gốc không có, được thêm qua ADR, không phá cấu trúc cũ.

**Chỗ Blueprint chưa trả lời:** không có khái niệm **Connection / Account /
Credential / Sync** trong Domain Model. Nếu đi hướng B hoặc C, Domain Model phải
mở rộng — đó là công việc thật, không phải sửa lệch.

---

# 5. Information Architecture Review

## IA hiện tại

- **Primary:** 5 bottom tab — Trang chủ · Nguồn hàng · Kho · Khách hàng · Thêm
- **Secondary:** module tabs
- **Tertiary:** detail screens + modal
- 7 navigation pattern, 6 luồng xuyên module, deep link có xử lý link hỏng

## Đánh giá

**Điểm mạnh:** IA được đặc tả kỹ hơn phần lớn sản phẩm ở giai đoạn này; các
luồng xuyên module (Opportunity → Goal, Customer → Order → Inventory) **có thật
trong code**, không chỉ trên giấy.

**Vấn đề 1 — "Thêm" đang là bãi rác.** Màn Thêm chứa: Tài chính · Báo cáo · Dự
báo · Rủi ro khách hàng · Mục tiêu · Xuất CSV · Sao lưu · Cài đặt · Pháp lý.
Tức là **4 trong 8 capability** (Finance, Reports, Journey, và phần lớn AI) nằm
sau một tab tên "Thêm". Một capability ngang hàng trong Vision mà phải đi qua
"Thêm" thì IA đang nói sai về tầm quan trọng của nó.

**Vấn đề 2 — Opportunity Hub không có mặt ở primary nav.** Vision gọi nó là
"Sàn Cơ Hội", một trong 8 capability, và là *"đơn vị trung tâm"* theo
`OPPORTUNITY-ENGINE.md`. Nhưng nó không có tab riêng.

**Vấn đề 3 — AI Copilot chỉ là một icon ở góc.** Với sản phẩm tự gọi mình là
AI-first, đây là mâu thuẫn giữa định vị và IA.

**Vấn đề 4 — không có chỗ cho Connection.** Nếu đi hướng B/C, IA hiện tại không
có nơi tự nhiên để đặt "nguồn dữ liệu đang kết nối".

→ Đề xuất IA mới: [`vNext-INFORMATION-ARCHITECTURE.md`](vNext-INFORMATION-ARCHITECTURE.md)

---

# 6. Capability Gap Analysis

Thang: **L0** không có · **L1** có mô hình · **L2** có UI + CRUD · **L3** có dữ
liệu thật + trạng thái đầy đủ · **L4** có AI/thông minh trên dữ liệu thật ·
**L5** có dữ liệu ngoài.

| Capability | Hiện tại | Trần bị chặn bởi | Khoảng cách thật |
|---|---|---|---|
| Inventory | **L4** | — | nhỏ |
| Consumer | **L4** | — | omnichannel (cần L5) |
| Finance | **L4** | — | nhỏ |
| Reports | **L4** | — | nhỏ |
| Business Journey | **L4** | — | nhỏ |
| AI Copilot | **L4** | — | nhỏ |
| **Producer** | **L2** | **không có nguồn hàng thật** | **lớn — cần L5** |
| **Opportunity** | **L3** | **chỉ dữ liệu nội bộ** | **lớn — cần L5** |
| *Marketing* | **L0** | chưa tồn tại | — |
| *Logistics* | **L0** | chưa tồn tại | — |
| *Connection* | **L0** | chưa tồn tại | — |

## Điều quan trọng nhất trong bảng này

**Sáu capability đã ở L4 và không bị chặn bởi gì cả.** Hai capability bị chặn
(Producer, Opportunity) bị chặn bởi **cùng một thứ**: không có dữ liệu ngoài.

Nghĩa là: **giá trị lớn nhất còn lại của sản phẩm nằm sau đúng một cánh cửa** —
đưa dữ liệu ngoài vào. Không phải mười cánh cửa.

Và cánh cửa đó có **ba cách mở** với chi phí chênh nhau hàng chục lần (hướng
A/B/C ở Executive Summary). Đây là lý do quyết định hướng quan trọng hơn mọi
việc còn lại trong directive này.
