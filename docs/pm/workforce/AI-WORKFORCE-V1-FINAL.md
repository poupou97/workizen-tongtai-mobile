# AI WORKFORCE V1 — FINAL / Bản chốt

- **Status:** ✅ FINALIZED · 2026-07-08 · Bilingual EN/VI · Remote-ready · Ecosystem template.
- **Files:** [FOUNDER](FOUNDER.md) · [PM_AGENT](PM_AGENT.md) · [DEVELOPER_AGENT](DEVELOPER_AGENT.md) · [QA_DEPLOY_AGENT](QA_DEPLOY_AGENT.md) · [AI_CONTEXT](AI_CONTEXT.md) · [NON_BLOCKING_POLICY](NON_BLOCKING_POLICY.md) · [PROJECT_CONTEXT](PROJECT_CONTEXT.md) · [PROJECT_TEMPLATE](PROJECT_TEMPLATE.md) · [WORK_ORDER_TEMPLATE](WORK_ORDER_TEMPLATE.md) · [CYCLE_REPORT_TEMPLATE](CYCLE_REPORT_TEMPLATE.md) · [COMMANDS](COMMANDS.md).
- Supersedes the scattered V0 docs (AI-WORKFORCE-SPEC, RBAC, PERMISSION-MODEL, DEVELOPER-AGENT-ACTIVATION, AI_CONTEXT_PM/DEV) — those remain as history.

## 1. Role model / Mô hình vai trò
EN: Exactly **4 roles, 4 conversations per project**. No new roles (no separate Tech Lead / Release / Security / Docs). **One project = one AI team.**
VI: Đúng **4 role, 4 hội thoại mỗi project**. Không role mới (không tách Tech Lead / Release / Security / Docs). **Một project = một đội AI.**

| Role | Owns / Sở hữu |
|---|---|
| **Founder** | vision · roadmap · ADR approval · PR merge · release approval |
| **PM / Tech Lead** | analyze · challenge · ADR/Spec · Epic/Story · Jira+Confluence (no code) |
| **Developer** | Jira Story → feature branch → PR → Code Review (no merge/release/deploy) |
| **QA / Deploy** | verify PR · QA · bugs · build/deploy to test channels (no product code, no prod deploy) |

## 2. Kanban workflow / Luồng Kanban
```
Ideas → Analysis → Ready → In Progress → Code Review → QA → Done
```
EN: Deploy is **not** a column — QA/Deploy handles it after QA pass / release approval. ⚠️ **Founder UI action:** the Jira `WH` board currently has To Do / In Progress / In Review / Done; the new columns (Ideas, Analysis, Ready, Code Review, QA) must be added in **Jira project settings** (the MCP cannot create statuses/columns).
VI: Deploy **không** phải cột — QA/Deploy làm sau QA pass / duyệt phát hành. ⚠️ **Việc Founder làm trên UI:** board Jira `WH` hiện có To Do / In Progress / In Review / Done; các cột mới (Ideas, Analysis, Ready, Code Review, QA) phải thêm trong **Jira project settings** (MCP không tạo được status/cột).

## 3. Remote command system / Hệ lệnh remote
EN: Founder drives everything by slash commands in Jira/GitHub/Confluence comments — full list in [COMMANDS.md](COMMANDS.md). Agents recognize commands, act, reply short + bilingual + linked.
VI: Founder điều khiển mọi thứ bằng slash command trong comment Jira/GitHub/Confluence — danh sách đầy đủ ở [COMMANDS.md](COMMANDS.md). Agent nhận lệnh, làm, trả lời ngắn + song ngữ + kèm link.

## 4. Bilingual documentation rule / Quy tắc tài liệu song ngữ
EN: Headings may be English; body is **EN: / VI:** per section; concise. Applies to all workforce docs.
VI: Heading có thể tiếng Anh; nội dung **EN: / VI:** theo từng section; ngắn gọn. Áp dụng cho mọi tài liệu workforce.

## 5. Per-agent allowed / forbidden / Được phép — Cấm
| Role | Allowed / Được phép | Forbidden / Cấm |
|---|---|---|
| **PM** | ADR/Spec, Epic/Story, Jira/Confluence, move to Ready | product code · merge · release/deploy · self-ratify ADR |
| **Developer** | push branch · open PR · move to Code Review | merge main · release/deploy/tag · close Epic · self-create work |
| **QA/Deploy** | verify · test · bugs · build · deploy to test channels | product code · prod deploy without Founder · merge main |
| **Founder** | everything + exclusive gates | — |

Allowed commands per role → [COMMANDS.md](COMMANDS.md) §2–5.

### 5b. Non-blocking sponsor approval / Phê duyệt không chặn
EN: The runtime **never halts everything** for one approval. When a task needs a Founder decision, the agent parks **only that task** (`WAITING_FOR_SPONSOR`/`IDEA` + `sponsor-review`), posts a full `[SPONSOR DECISION REQUIRED]` comment **with a recommendation**, preserves the work (commit + push), and continues **independent** tasks. The Founder unblocks with one line (`APPROVE OPTION A/B` · `REJECT` · `REQUEST CHANGES: …`); each cycle the PM/runtime re-queues answered items. Full policy: [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md); cycle report: [CYCLE_REPORT_TEMPLATE.md](CYCLE_REPORT_TEMPLATE.md).
VI: Runtime **không dừng toàn bộ** vì một lần duyệt. Khi một task cần Founder quyết định, agent chỉ treo **task đó** (`WAITING_FOR_SPONSOR`/`IDEA` + `sponsor-review`), đăng comment `[SPONSOR DECISION REQUIRED]` đầy đủ **kèm khuyến nghị**, bảo toàn kết quả (commit + push), và làm tiếp task **độc lập**. Founder mở chặn bằng một dòng (`APPROVE OPTION A/B` · `REJECT` · `REQUEST CHANGES: …`); mỗi vòng PM/runtime đưa lại hàng đợi item đã trả lời. Chính sách: [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md); báo cáo: [CYCLE_REPORT_TEMPLATE.md](CYCLE_REPORT_TEMPLATE.md).

## 6. Copy to another repo / Sao chép sang repo khác
EN: Copy `docs/pm/workforce/` → edit **PROJECT_CONTEXT.md** only → Founder creates the Jira project (with the 7 columns) + Confluence space → set 4 conversations + branch protection. Keep roles/workflow/COMMANDS unchanged. (Full steps: [PROJECT_TEMPLATE.md](PROJECT_TEMPLATE.md).)
VI: Sao chép `docs/pm/workforce/` → chỉ sửa **PROJECT_CONTEXT.md** → Founder tạo Jira project (với 7 cột) + Confluence space → lập 4 hội thoại + branch protection. Giữ nguyên role/workflow/COMMANDS. (Chi tiết: [PROJECT_TEMPLATE.md](PROJECT_TEMPLATE.md).)

## 7. Open questions / Câu hỏi mở
EN:
- Jira workflow columns are added by the Founder in UI (MCP limit) — do it now, or keep the current 4-column board and map (Analysis≈In Progress, Code Review≈In Review)?
- Deploy channels (`/deploy-firebase|testflight|internal`) need credentials configured before QA/Deploy can run them.
- Per-agent service accounts (RBAC hardening) stay deferred — V1 runs on one account + role logic.

VI:
- Cột workflow Jira do Founder thêm trong UI (giới hạn MCP) — làm ngay, hay giữ board 4 cột hiện tại và ánh xạ (Analysis≈In Progress, Code Review≈In Review)?
- Kênh deploy (`/deploy-firebase|testflight|internal`) cần cấu hình credential trước khi QA/Deploy chạy được.
- Service account riêng mỗi agent (siết RBAC) vẫn hoãn — V1 chạy trên một account + logic role.

## 8. Next recommended action / Hành động tiếp theo đề xuất
EN: (1) Founder adds the 5 new Kanban columns to Jira `WH`. (2) Merge this workforce set to main. (3) Try one remote cycle: comment an idea in **Ideas** → `/analyze`. (4) Copy the folder to each product repo — Compute (`WC`) · Portal (`WP`) · CodeCanyon (`CH`) now exist (Hub PC dropped, ADR-059 amendment 2026-07-11).
VI: (1) Founder thêm 5 cột Kanban mới vào Jira `WH`. (2) Merge bộ workforce này vào main. (3) Thử một vòng remote: comment ý tưởng ở **Ideas** → `/analyze`. (4) Sao chép folder sang từng repo sản phẩm — Compute (`WC`) · Portal (`WP`) · CodeCanyon (`CH`) đã có (bỏ Hub PC, ADR-059 sửa 2026-07-11).
