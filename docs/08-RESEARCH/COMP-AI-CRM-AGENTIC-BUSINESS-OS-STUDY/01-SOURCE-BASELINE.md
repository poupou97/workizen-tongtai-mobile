# 01 · Source baseline

| | |
|---|---|
| Remote | `https://github.com/trycompai/crm.git` |
| Branch | **`release`** *(mặc định — không phải `main`)* |
| Commit | **`c26a08d63db7d22e86bcdfe76872c86c7f640ea1`** |
| Ngày commit | **2026-08-07** (một ngày trước khi đọc) |
| Tổng commit | **156** |
| Giấy phép | **MIT** — Copyright (c) 2026 Comp AI |
| Clone tại | `~/projects/_reference/trycompai-crm` — **ngoài** mọi repo Workizen |
| Quy mô | 771 file `.ts`/`.tsx`/`.sql` |

Upstream **không bị sửa**. Mọi ghi chú nằm trong chính bộ tài liệu này.

## ⭐ Giấy phép quyết định phạm vi ADOPT

**MIT** — dùng lại được, kể cả thương mại, chỉ cần giữ thông báo bản quyền.

Nhưng khuyến nghị của bộ nghiên cứu này gần như không có mục nào là *chép code*: TypeScript/Prisma/NestJS không dùng lại được trong Flutter/Drift. Cái ADOPT là **hình dạng kiến trúc**, và hình dạng thì không thuộc phạm vi bản quyền. Giấy phép ở đây gỡ rủi ro pháp lý chứ không mở thêm cơ hội kỹ thuật.

## Repo trẻ — đọc kết luận với đúng trọng lượng

156 commit, migration đầu `20260731`, tức **8 ngày tuổi** lúc đọc. Hệ quả trực tiếp lên cách đọc:

- Cái đã **ổn định** (fact ledger, task queue) đáng tin là thiết kế có chủ đích.
- Cái **mới nhất** (dynamic fields `20260806`, agent builder `20260803`) chưa kịp bị đời sống sửa — và §04/§12 cho thấy chúng có bảo đảm **yếu hơn** phần cũ.
- Không có bằng chứng nào ở đây là *"đã chạy 2 năm không sao"*. Đây là bằng chứng **thiết kế**, không phải bằng chứng **vận hành**.

## Cấu trúc

```
apps/agent     — durable agent runtime (eve framework), tools, skills, sandbox
apps/api       — NestJS: CRM domain, Google sync, agent trigger + runs
apps/app       — Next.js frontend
packages/db    — Prisma schema + 40 migration
packages/auth · env · telemetry · ui · typescript-config
.agents/skills — 33 skill kéo từ GitHub, khoá hash trong skills-lock.json
adrs/          — chỉ 2 file (README + comp-palette) — hầu như không có ADR
```

**Đáng chú ý:** repo có `AGENTS.md` + `CLAUDE.md` + `.claude/`, tức nó được viết **bởi và cho** agent. Nhưng `adrs/` gần như rỗng — quyết định kiến trúc nằm trong **skill file** và **doc comment**, không nằm trong ADR.
