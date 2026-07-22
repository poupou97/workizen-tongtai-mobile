# Jira & Confluence Mapping

| Hệ thống | Giá trị | Ghi chú |
|---|---|---|
| Jira project | **WTM** (workizen-tongtai-mobile) | Toàn bộ story Tổng Tài ở đây — KHÔNG tạo task Tổng Tài trong project WH (Hub) |
| Confluence space | **workizento** | Mirror cho người đọc; git là source of truth |
| Cloud | workizen.atlassian.net | `.workforce.json` ở root repo |

## Trạng thái board lúc split (2026-07-22)

- 17+ story ở **Code Review** (code đã nằm trên main repo này) — chờ Founder
  xác nhận để chuyển Done.
- Backlog Sprint 3+ (WTM-76…102) đầy đủ AC, chưa chạy.
- WTM-11 = tracker quyết định nền tảng (D-1 ✅, DI ✅, còn: mascot, auth…).
- Không có issue Tổng Tài nào "nằm nhầm" bên project WH — WTM sinh ra đã dành
  riêng cho sản phẩm này.

## Quy ước

- Mỗi story: bilingual title/desc + AC checklist (mẫu = các story hiện có).
- Agent cập nhật Jira kèm evidence (commit hash, analyze/test result).
- Epic/milestone đóng = Founder.
