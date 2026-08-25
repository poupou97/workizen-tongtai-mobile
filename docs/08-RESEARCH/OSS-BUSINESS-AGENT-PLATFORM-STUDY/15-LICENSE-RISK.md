# 15 · License Risk — cổng đứng trước mọi verdict ADOPT

> WTM-453 (Epic WTM-447) · 2026-08-25 · License đọc từ **file tại studied SHA**
> (bảng SHA ở `01-SOURCE-BASELINE.md`), không đọc từ website hay README.
> Đây không phải tư vấn pháp lý — là phân loại rủi ro thực hành, đúng phạm vi
> evidence; câu hỏi vượt evidence đánh dấu `TBD-LEGAL`.

## Bảng phân loại

| Repo | License | Chép code vào Workizen | Học kiến trúc / thuật ngữ / invariant | Self-host làm service |
|---|---|:---:|:---:|---|
| ERPNext | GPL-3.0 | ⛔ | ✅ | được, nhưng KHÔNG trong phạm vi study (RESEARCH ONLY) |
| Relaticle | AGPL-3.0 | ⛔ | ✅ | ⚠️ network-service trigger |
| **Trigger.dev** | **Apache-2.0** | ✅ kèm NOTICE/attribution | ✅ | ✅ |
| Plane | AGPL-3.0 | ⛔ | ✅ | ⚠️ network-service trigger |
| lago-api | AGPL-3.0 | ⛔ | ✅ | ⚠️ network-service trigger |

## Vì sao AGPL nguy hiểm hơn GPL cho đúng Workizen

GPL kích hoạt nghĩa vụ khi **phân phối** binary. AGPL §13 kích hoạt cả khi
**người dùng tương tác qua mạng** — tức *self-host có chỉnh sửa rồi cho user
bên ngoài dùng* cũng phải mở source phần sửa. Workizen có hai kịch bản chạm:

1. **AI Teams self-host Lago có chỉnh sửa** → nghĩa vụ mở source phần sửa.
   Verdict `11-LAGO-VS-AI-TEAMS.md` đã loại self-host vì lý do khác (7 service,
   thiếu escrow) nên rủi ro này hiện **không kích hoạt**.
2. **Dựng bản Plane nội bộ có sửa** → tương tự. Verdict NO MIGRATION nên
   **không kích hoạt**.

Dùng **không chỉnh sửa** (vanilla self-host) thì nghĩa vụ nhẹ hơn nhiều —
nhưng vẫn ghi `TBD-LEGAL` nếu ngày nào đó thành kế hoạch thật, và theo luật
Epic: **mọi quyết định self-host AGPL phải qua Founder trước**.

## Trigger.dev — Apache-2.0, nhưng đọc kỹ một tầng nữa

Root `LICENSE` là Apache-2.0. Khác n8n (Sustainable Use) và khác mô hình
open-core có thư mục `ee/` tách license (Plane có `COPYRIGHT_CHECK.md`;
activepieces có `ee/` — đã gặp ở registry đợt 2). Trong clone Trigger.dev
**không thấy thư mục `ee/`**; các gói `internal-packages/*` và `packages/*`
không mang LICENSE riêng ở mức thư mục — tức theo root. Chi tiết per-package
do R3 kiểm tiếp trong `06-TRIGGERDEV-DURABLE-RUNTIME.md`; nếu R3 tìm thấy
ngoại lệ thì file này phải sửa theo (file nào nói sau, file đó thắng, kèm ngày).

Nghĩa vụ khi ADOPT code Apache-2.0: giữ NOTICE, ghi attribution, nêu thay đổi.
Rẻ, làm được, không phải rào.

## Kết luận thực hành (khớp registry đợt 2)

Đọc cả sáu để hiểu. Khi cần **dùng lại code**, chỉ một nguồn trong đợt này
cho phép: **Trigger.dev**. Mọi thứ học từ ERPNext/Relaticle/Plane/Lago phải
vào Workizen bằng **tri thức + thiết kế lại** (clean-room theo nghĩa thực
hành: viết từ invariant đã hiểu, không dịch code), và tài liệu study này chính
là bằng chứng đường đi của tri thức đó.

`TBD-LEGAL` đang mở: không có. Không kịch bản nào hiện tại kích hoạt nghĩa vụ
copyleft — vì mọi verdict đều dừng ở LEARN.
