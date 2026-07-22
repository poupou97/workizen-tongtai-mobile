# .claude — bộ nhớ vận hành của Tổng Tài

Thư mục này thuộc RIÊNG repo `workizen-tongtai-mobile`. Không phụ thuộc Hub.

## Mô hình bộ nhớ (đọc kỹ)

1. **Nguồn sự thật = `docs/`** (version-controlled, travel theo git). Mọi
   quyết định quan trọng phải nằm ở đó — `.claude`/memory chỉ là bối cảnh
   vận hành, KHÔNG phải nơi duy nhất giữ tri thức.
2. **Agent memory máy-local** (Claude Code tự quản ở
   `~/.claude/projects/<repo-path>/memory/`) — được seed lúc split từ tri thức
   Tổng Tài; máy mới/agent mới không có nó vẫn phải hiểu dự án chỉ từ repo
   (đã verify bằng Cold-Start Review).
3. `.claude` của **Hub** = historical reference ONLY — không symlink, không
   copy tự động; adopt gì phải qua `docs/upstream/HUB-UPSTREAM.md`.

## Entry point cho agent mới

Đọc theo thứ tự trong `CLAUDE.md` (bắt đầu từ
`docs/00-START-HERE/AGENT-ONBOARDING.md`).

## Provenance

Bộ nhớ khởi tạo từ Hub agent memory snapshot 2026-07-22, đã lọc Hub-only +
secret: xem `docs/migration/HUB-CLAUDE-MEMORY-INVENTORY.md` và
`docs/migration/HUB-CONTEXT-ADOPTION-MATRIX.md`.
