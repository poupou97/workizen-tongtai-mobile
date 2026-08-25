# 00 · Executive Summary — OSS Business-Agent Platform Study

> Epic **WTM-447** · 2026-08-25 · 5 repo, 6 clone, ~18 tài liệu, 10 diagram.
> Luật đã giữ: **code thắng README** (mọi kết luận FILE→SYMBOL→CALL PATH),
> license gate trước verdict, RESEARCH ONLY — không dòng production nào đổi.
> Đọc 5 phút: file này. Đọc 1 giờ: 02→07. Tự kiểm một trích dẫn: `SOURCE-MAP.md`.

## Câu hỏi cuối của Task Order — trả lời trước

> *"Nếu hôm nay bắt đầu lại Workizen với tri thức từ 5 repo này, chúng ta sẽ
> thiết kế khác đi điều gì — và điều gì hiện tại đã đúng nên tuyệt đối không
> cần thay?"*

**Sẽ làm khác — bốn điều, xếp theo độ đau nếu để muộn:**

1. **Tồn kho là sự kiện, không phải con số** — `products.totalStock` là miền
   duy nhất còn là scalar mutable không sự kiện nguồn: orders không trừ kho,
   tổng variant không ràng buộc tổng cha. ERPNext cho thấy giá của việc làm
   đúng từ đầu rất nhỏ so với retrofit.
2. **AI-WF một execution plane ngay từ đầu** — hai supervisor, hai khoá không
   thấy nhau là nợ tích luỹ của "bash trước, TS sau"; Trigger.dev cho thấy
   phiên bản đúng chỉ cần state-log + fencing + watchdog, không cần framework.
3. **Giá vốn chốt theo thời điểm giao dịch** ở mọi nơi tiền được dẫn xuất —
   `OrderItem` đã snapshot `unitPrice` (WTM-126) mà chưa snapshot `costPrice`.
4. **Một kỷ luật decode enum từ v1** — mã lạ ⇒ null. Enum mới đã đúng
   (ADR-TON-018), enum v1 còn rơi về default; nhất quán từ đầu thì không có
   lớp địa tầng.

**Tuyệt đối KHÔNG thay — năm điều, cả năm vừa được code người khác làm chứng:**

1. **Rule Twin authoritative + quyền từ chối trả số** (`ProfitInsufficient`) —
   không repo nào trong 5 có tương đương.
2. **Cửa ghi duy nhất BusinessAction** (WTM-300) — Relaticle xác nhận bằng
   PHẢN ví dụ: MCP của họ ghi thẳng không duyệt, đúng lỗ ta đã chặn trước.
3. **Provenance 5 nguồn** — không repo nào có; vì họ là hệ ghi sổ gốc còn
   Tổng Tài là hệ hợp nhất nguồn. Đầu tư đúng chỗ.
4. **Evidence-driven verdict** — Trigger.dev TIN task code; ta không tin agent
   report, và với agent LLM thì ta đúng.
5. **Jira-là-queue** — queue vô hình của Trigger.dev đẹp về kỹ thuật và phạm
   luật visibility của Founder; Plane không cho lý do nào đủ mạnh để rời Jira.

## Verdict một dòng mỗi repo (bảng đủ ở `14`)

| Repo | Một dòng |
|---|---|
| ERPNext (GPL) | **ADAPT domain** — mất nhiều nhất nếu không học; 3 lỗ Inventory/costing chỉ lộ nhờ nó |
| Relaticle (AGPL) | **LEARN** — giá trị lớn nhất là phản ví dụ xác nhận WTM-300 + luật Tool Runtime tương lai |
| Trigger.dev (Apache) | **ADOPT PATTERNS, không adopt hạ tầng** — "không cần tự xây framework" là câu trả lời đắt nhất |
| Plane (AGPL) | **NO MIGRATION** — pain JQL là pain tầng MCP, không phải Jira |
| Lago (AGPL) | **Chỉ học domain vào WAT-16** — Lago thiếu escrow, đúng thứ AI Teams cần nhất |

## 🚩 Một FLAG chờ Founder

Từ `07 §5`: giữ quyết định AI-WF TS runtime, nhưng đề xuất **hợp nhất MỘT
execution plane + execution-state log + watchdog + một khoá fencing** — ba cơ
chế xây bằng file JSON + cron, thuộc repo runtime (phiên khác giữ), cần Founder
duyệt trước khi thành vé. Chi tiết + căn cứ: `07-TRIGGERDEV-VS-AI-WF.md`.

## Discrepancy đã gặp (code thắng README/tài liệu, đủ 4 ca)

1. `getlago/lago` là repo vỏ submodule — implementation ở `lago-api` (01)
2. Relaticle README "22 custom field types" — app-level verify được 17 (04)
3. `Product.stockValue` docstring nói "tiền trong kho", công thức dùng **giá bán** (03)
4. SOURCE-MAP bản đầu đoán custom-fields ở `packages/` — thực tế composer vendor (đã sửa tại chỗ)

## Không làm gì cả cũng là kết quả

4/5 repo license cấm chép; 5/5 ở tầng khác Workizen. Study này mua được ba thứ:
**xác nhận độc lập** cho ba quyết định kiến trúc đã chọn, **ba lỗ có tên** thay
vì cảm giác mơ hồ, và **một danh sách ngắn việc rẻ-giá-trị-lớn** (`16`) — chứ
không phải một kế hoạch tích hợp. Đúng như Task Order dặn: không ghép
mega-platform, không khen repo vì nổi tiếng.
