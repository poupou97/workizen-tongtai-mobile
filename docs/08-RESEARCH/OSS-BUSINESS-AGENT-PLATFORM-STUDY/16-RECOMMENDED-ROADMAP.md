# 16 · Recommended Roadmap — từ study ra việc, KHÔNG tự triển khai

> WTM-453 · 2026-08-25 · ⛔ Task Order: `IMPLEMENTATION NOT AUTHORIZED`.
> File này biến kết luận thành **đề xuất vé**, xếp theo giá/giá trị. Không vé
> nào được tạo/làm cho tới khi Founder duyệt danh sách này — trừ khi Founder
> nói khác.

## Nhịp 1 — rẻ, giá trị lớn, không đổi kiến trúc (Tổng Tài)

| # | Đề xuất vé | Từ bài học | Cỡ |
|---|---|---|---|
| 1 | **Snapshot `costPrice` vào `OrderItem` lúc chốt đơn** — lời thật của đơn cũ thôi đổi khi giá vốn đổi | ERPNext `get_incoming_rate` (giá vốn theo thời điểm); cùng họ WTM-126 | nhỏ |
| 2 | **`stockValue` đổi sang giá vốn** (hoặc đổi tên + docstring nói thật "định giá theo giá bán") — hiện docstring nói một đằng công thức một nẻo | Discrepancy tìm thấy ở 03 §4b | rất nhỏ, nhưng là **Business Truth** ⇒ cần Founder chọn 1 trong 2 |
| 3 | **Nối `leadTimeDays` + `minimumOrderQuantity` (có sẵn trong supplier_quotes) vào cảnh báo tồn kho** — reorder trả lời "khi nào đặt, đặt bao nhiêu" thay vì chỉ "sắp hết" | ERPNext reorder 4 câu; hình dạng P-31 (trường đã lưu, luật chưa dùng) | nhỏ |
| 4 | **Enum cũ về chuẩn ADR-TON-018** — `OrderStatus`/`TransactionType` mã lạ ⇒ null, không rơi về default | 03 §4c; P-47 cùng họ | nhỏ + cẩn trọng migration |

## Nhịp 2 — cần Founder duyệt trước (⛔ FLAG từ doc 07 §5)

**AI-WF: hợp nhất về MỘT execution plane.** Ba cơ chế, không framework nào:

1. Kết liễu tình trạng hai supervisor (bash + TS) hai khoá không thấy nhau —
   một khoá theo **work-order** + fencing token;
2. **Execution-state log** append-only (file JSON) — crash giữa attempt hết vô
   hình;
3. **Watchdog ngoài tiến trình** — một dòng cron đọc `status.json`, phát hiện
   supervisor chết im lặng.

Giữ nguyên: Jira-là-queue · evidence spine · device preflight · safe-git ·
retry-với-fix-brief (chỉ học thêm phân loại lỗi transient). ⚠️ Việc này thuộc
repo runtime — phiên khác đang giữ; đề xuất đi qua Founder rồi vào board của
repo ấy, không phải WTM.

## Nhịp 3 — khi có cớ nghiệp vụ (không làm trước)

| Đề xuất | Điều kiện kích hoạt |
|---|---|
| Sự kiện tồn kho (movement events cho `totalStock`) | Cần ADR riêng — đã đánh dấu DESIGN ONLY ở COMMERCE-ATTRIBUTE-MODEL §7; kích hoạt khi có kho thứ hai HOẶC khi File Bridge nhập tồn từ sàn (hai nguồn ghi cùng một số) |
| ProposedChange học triage SNOOZED/DUPLICATE (Plane) | Khi hàng đợi đề xuất dài tới mức approve/reject không đủ |
| Jira tooling REST-trực-tiếp thay JQL-qua-MCP | Lần tới pain "cắt 5 issue" cản việc thật |
| WAT-16 + 5 điểm Lago | Khi Founder duyệt WAT-16 (đang PROPOSED ở repo AI Teams) |
| Luật Tool Runtime: *mọi write tool compile xuống BusinessAction* | Viết sẵn NGAY khi mở AiToolRuntime (ADR-TON-016 đang tắt cứng) — một dòng trong ADR mở khoá, giá bằng 0 hôm nay, đắt vô cùng nếu quên |

## Điều roadmap này KHÔNG đề xuất — cũng quan trọng như điều nó đề xuất

- ❌ Migrate AI-WF sang Trigger.dev (container-per-run nghịch agent-trên-repo)
- ❌ Thay Jira bằng Plane (NO MIGRATION — evidence ở 09)
- ❌ Self-host Lago (7 service + AGPL + thiếu escrow)
- ❌ Dựng PO→Receipt→Invoice cho Tổng Tài (ERPNext tự chứng minh chuỗi này là
  tuỳ chọn; SME một-document là đúng)
- ❌ Bất kỳ đường copy code nào từ 4 repo GPL/AGPL
