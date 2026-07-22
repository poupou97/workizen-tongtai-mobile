# Source of Truth — khi tài liệu mâu thuẫn, cái nào thắng?

Thứ tự ưu tiên (trên thắng dưới):

1. **Live code + test của repo này** — cho câu hỏi *factual* ("X có tồn tại
   không, chạy thế nào"). Code thắng docs; sau đó cập nhật docs theo code.
2. **ADR trong `docs/03-DECISIONS/`** — cho quyết định kiến trúc đang hiệu lực.
   Không bao giờ mâu thuẫn ngầm với ADR; muốn khác → ADR mới supersede.
3. **`docs/00-START-HERE/` + `CLAUDE.md`** — trạng thái & luật làm việc.
4. **Phần còn lại của `docs/`** — spec sản phẩm (Design Bible). Nếu spec ≠
   code: code thắng về hiện trạng, spec thắng về *ý định* — ghi gap vào
   `docs/migration/KNOWN-GAPS.md` và/hoặc tạo Jira task.
5. **Jira WTM** — trạng thái công việc (backlog/AC). Confluence `workizento`
   = bản mirror cho người đọc, không phải nguồn gốc.
6. **`.claude/` + memory** — bối cảnh vận hành của agent, KHÔNG phải nguồn sự
   thật; quyết định quan trọng phải nằm trong `docs/` (version-controlled).

Quy tắc ecosystem: `workizen-knowledge-base/canonical/` (repo riêng của
Founder) là SSoT cấp hệ sinh thái. Mâu thuẫn repo ↔ canonical → **báo Founder,
không tự sửa hai bên**.

Hub repo (`workizen-ai-personal-wallet`) chỉ là **upstream reference** —
không phải nguồn sự thật cho Tổng Tài. Xem `docs/upstream/HUB-UPSTREAM.md`.
