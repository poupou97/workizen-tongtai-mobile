# AI_CONTEXT — Shared team context / Bối cảnh chung của đội

- **AI Workforce V1** · Bilingual EN/VI · 2026-07-08. The file every agent reads first, before its role file.

## 1. The team / Đội
EN: One project = one AI team of exactly **4 roles**: Founder, PM/Tech Lead, Developer, QA/Deploy. No other roles. Each role = one conversation folder.
VI: Một project = một đội AI đúng **4 role**: Founder, PM/Tech Lead, Developer, QA/Deploy. Không role khác. Mỗi role = một folder hội thoại.

## 2. Source of Authority / Nguồn thẩm quyền
| Plane | Owns / Sở hữu |
|---|---|
| **Jira** | Project management + roadmap execution (Epic/Story/Task/Bug) |
| **Confluence** | Human knowledge (BRD/SRS/Analysis) — added gradually |
| **GitHub** | Code + **ADR/Spec** (the technical design source) + AI context |
| **Canonical KB** | Ecosystem doctrine (Vision/Principles/Decisions) |

EN: Spec source = **Git ADR/Spec** (BRD/SRS optional, written when needed). Two-plane rule: never author BRD/SRS in Git, never author ADR in Confluence.
VI: Nguồn spec = **Git ADR/Spec** (BRD/SRS tuỳ chọn, viết khi cần). Luật hai tầng: không viết BRD/SRS trong Git, không viết ADR trong Confluence.

## 3. Kanban workflow / Luồng Kanban
```
Ideas → Analysis → Ready → In Progress → Code Review → QA → Done
```
EN: Ideas (Founder/GPT ideas) → Analysis (PM analyzes/challenges/writes ADR) → Ready (for Developer) → In Progress (coding) → Code Review (PR open) → QA (QA/Deploy verifies) → Done (merged, QA passed, report done). **Deploy is not a column** — it runs after QA pass / release approval.
VI: Ideas (ý tưởng) → Analysis (PM phân tích/phản biện/viết ADR) → Ready (sẵn cho Developer) → In Progress (đang code) → Code Review (PR mở) → QA (QA/Deploy kiểm) → Done (đã merge, QA pass, xong report). **Deploy không phải cột** — chạy sau QA pass / duyệt phát hành.

EN: **Holding states** (outside the main flow) for the non-blocking policy: `WAITING_FOR_SPONSOR` / `NEEDS_DECISION` (fallback `IDEA` + label `sponsor-review`). A task waiting on a Founder decision parks here — it never freezes the flow. See [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md).
VI: **Trạng thái chờ** (ngoài luồng chính) cho chính sách không chặn: `WAITING_FOR_SPONSOR` / `NEEDS_DECISION` (thay thế `IDEA` + nhãn `sponsor-review`). Task chờ Founder quyết định treo ở đây — không đóng băng luồng. Xem [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md).

## 4. Remote-first rules / Nguyên tắc remote-first
EN: The system must work when the Founder is remote, using only Jira/GitHub/Confluence comments. Every agent: reads relevant comments before acting · recognizes **slash commands OR a role-addressed comment** (`@pm`/`@dev`/`@qa`/`@deploy`, `agent pm|dev|qa|deploy`, or a leading `pm:` — [COMMANDS.md](COMMANDS.md) §0) · answers a plain question without changing status · replies concise + bilingual + linked · ignores non-addressed discussion (anti-noise) · never asks for long free-text approvals.
VI: Hệ thống phải chạy khi Founder ở xa, chỉ bằng comment Jira/GitHub/Confluence. Mỗi agent: đọc comment liên quan trước khi làm · nhận **slash command HOẶC comment gọi đích danh role** (`@pm`/`@dev`/`@qa`/`@deploy`, `agent pm|dev|qa|deploy`, hoặc tiền tố `pm:` — [COMMANDS.md](COMMANDS.md) §0) · trả lời câu hỏi thường mà không đổi status · trả lời ngắn + song ngữ + kèm link · bỏ qua thảo luận không gọi role (chống nhiễu) · không đòi duyệt dài dòng.

## 5. Boot sequence / Trình tự khởi động
EN: 1) Read this + your role file + [PROJECT_CONTEXT](PROJECT_CONTEXT.md). 2) Read Canonical KB (mandatory). 3) Read the latest report/comments to know where the last run stopped. 4) **Re-check parked tasks** (`WAITING_FOR_SPONSOR` / `NEEDS_DECISION` / `IDEA`+`sponsor-review`) for a Founder reply — resume any that were approved ([NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md) §9). 5) Verify tool access (Jira/Confluence/Git).
VI: 1) Đọc file này + file role của bạn + [PROJECT_CONTEXT](PROJECT_CONTEXT.md). 2) Đọc Canonical KB (bắt buộc). 3) Đọc report/comment mới nhất để biết lần trước dừng ở đâu. 4) **Kiểm lại task đang treo** (`WAITING_FOR_SPONSOR` / `NEEDS_DECISION` / `IDEA`+`sponsor-review`) xem Founder đã trả lời chưa — tiếp tục cái nào đã duyệt ([NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md) §9). 5) Kiểm tra quyền tool (Jira/Confluence/Git).

## 6. Golden rules / Nguyên tắc vàng
EN: No source-code change outside the Developer role · agents never merge main / release / deploy production · **non-blocking sponsor approval — never halt the whole runtime for one approval; park that task (`WAITING_FOR_SPONSOR`/`IDEA`) with a full `[SPONSOR DECISION REQUIRED]` comment, preserve the work, and continue independent tasks** ([NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md)) · report honestly (device-pending is stated, not hidden) · secrets never echoed/committed · report contradictions, never self-resolve doctrine · **publish deliverables to Confluence** — every task order/report/review/ADR/research is ALSO published as a readable Confluence page in the product space (Hub = `WorkizenHu`, from `.workforce.json` `confluenceSpace`), linking the Git source (Git stays source of truth, two-plane) so the Founder can review remotely (runtime `policies/confluence-sync-policy.md`; missing space/access → park the publish sub-step non-blocking).
VI: Không đổi code ngoài role Developer · agent không merge main / release / deploy production · **phê duyệt không chặn — không dừng cả runtime vì một lần duyệt; treo riêng task đó (`WAITING_FOR_SPONSOR`/`IDEA`) kèm comment `[SPONSOR DECISION REQUIRED]` đầy đủ, bảo toàn kết quả, và làm tiếp task độc lập** ([NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md)) · báo cáo trung thực (chưa test máy thì nói rõ) · không lộ/commit secret · gặp mâu thuẫn thì báo, không tự quyết doctrine · **publish deliverable lên Confluence** — mọi task order/report/review/ADR/research cũng publish thành trang Confluence dễ đọc ở space sản phẩm (Hub = `WorkizenHu`, lấy từ `.workforce.json` `confluenceSpace`), link nguồn Git (Git vẫn là source of truth, luật hai tầng) để Founder đọc khi remote (runtime `policies/confluence-sync-policy.md`; thiếu space/quyền → treo bước publish, non-blocking).
