# COMMANDS — Remote Slash Commands / Hệ lệnh remote

- **AI Workforce V1** · 2026-07-08 · Bilingual EN/VI.
- **EN:** The Founder drives every agent by writing a slash command in a **Jira comment, GitHub PR comment, or Confluence comment.** Each agent reads relevant comments, recognizes its commands, acts, and replies concisely with links.
- **VI:** Founder điều khiển mọi agent bằng cách viết slash command trong **comment Jira, comment GitHub PR, hoặc comment Confluence.** Mỗi agent đọc comment liên quan, nhận lệnh của mình, thực thi, và trả lời ngắn gọn kèm link.

> Reply style / Cách trả lời — always short + bilingual + linked. Ví dụ:
> `EN: Done. PR #12 ready for review. · VI: Đã xong. PR #12 sẵn sàng review.`

---

## 0. Talk to an agent in plain language / Hỏi agent bằng lời thường

EN: You don't need a slash command to ask an agent something. On **any** issue, in **any** status,
write a comment **addressed to a role** and that agent reads the issue (+ its linked ADR/Spec/PR) and
replies (concise + bilingual). Address a role by any of:
- `@pm` · `@dev` · `@qa` · `@deploy`
- `agent pm` · `agent dev` · `agent qa` · `agent deploy`
- a leading `pm:` · `dev:` · `qa:` · `deploy:`

Example: `@pm I don't understand this task, please explain it.` → the PM answers on the card.
Also `/ask <question>` and `/explain` (answered by the role owning the issue's column, or the role named).
Only **addressed** or **slash** comments trigger a reply — plain discussion is ignored (anti-noise).
The runtime must be running (`ai-wf`) to reply unattended; in interactive mode you drive the role directly.

VI: Không cần slash command để hỏi agent. Trên **mọi** issue, **mọi** status, viết comment **gọi đích
danh role** thì agent đó đọc issue (+ ADR/Spec/PR liên kết) và trả lời (ngắn + song ngữ). Gọi role bằng:
`@pm`/`@dev`/`@qa`/`@deploy`, `agent pm|dev|qa|deploy`, hoặc tiền tố `pm:`/`dev:`/`qa:`/`deploy:`.
Ví dụ: `@pm tôi không hiểu task này, giải thích giúp.` → PM trả lời ngay trên card. Kèm `/ask <câu hỏi>`
và `/explain`. Chỉ comment **gọi role** hoặc **slash** mới kích hoạt — thảo luận thường bị bỏ qua (chống
nhiễu). Runtime phải đang chạy (`ai-wf`) mới tự trả lời; interactive mode thì bạn điều khiển trực tiếp.
(Chi tiết engine: ADR-003 trong repo `workizen-ai-workforce-runtime`.)

## 1. Common commands (all agents) / Lệnh chung (mọi agent)

| Command | EN | VI |
|---|---|---|
| `/status` | Report current status. | Báo cáo trạng thái hiện tại. |
| `/pause` | Pause current work safely. | Tạm dừng công việc hiện tại an toàn. |
| `/resume` | Resume paused work. | Tiếp tục công việc đã tạm dừng. |
| `/block` | Mark current item blocked (technical) + explain why. | Đánh dấu bị chặn (kỹ thuật) + giải thích lý do. |
| `/needs-decision` | Park current task for a Sponsor decision (non-blocking) + post `[SPONSOR DECISION REQUIRED]`, then continue other tasks. | Treo task hiện tại chờ Sponsor quyết định (non-blocking) + đăng `[SPONSOR DECISION REQUIRED]`, rồi làm tiếp task khác. |
| `/continue` | Skip anything waiting on the Sponsor and pick the next independent task. | Bỏ qua thứ đang chờ Sponsor và nhận task độc lập tiếp theo. |
| `/note <text>` | Add a note to the current task/report. | Ghi chú vào task/report hiện tại. |
| `/ask <question>` | Ask the role owning this issue's column a question; it answers (no status change). | Hỏi role phụ trách cột của issue; agent trả lời (không đổi status). |
| `/explain` | Explain this task/issue in plain language. | Giải thích task/issue bằng lời thường. |
| `/help` | Show supported commands for this agent. | Hiển thị danh sách lệnh agent hỗ trợ. |

> **Non-blocking / Không chặn:** `/needs-decision` parks **only that task** (`WAITING_FOR_SPONSOR`/`IDEA` + labels `sponsor-review`,`needs-decision`,`non-blocking`,role) — the runtime keeps working. `/block` is for a **technical** dependency (not a Sponsor decision). See [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md). / `/needs-decision` chỉ treo **task đó**; runtime vẫn chạy. `/block` dùng cho phụ thuộc **kỹ thuật** (không phải quyết định Sponsor).

## 2. Founder → PM / Tech Lead

| Command | EN | VI |
|---|---|---|
| `/analyze` | Analyze the idea/task and propose options. | Phân tích ý tưởng/task và đề xuất phương án. |
| `/challenge` | Critique the idea, find risks + alternatives. | Phản biện ý tưởng, tìm rủi ro và phương án thay thế. |
| `/approve-analysis` | Approve analysis; PM may create ADR/Spec. | Duyệt phân tích; PM được tạo ADR/Spec. |
| `/reject-analysis <reason>` | Reject analysis with reason. | Từ chối phân tích kèm lý do. |
| `/create-adr` | Create ADR for the approved decision. | Tạo ADR cho quyết định đã duyệt. |
| `/create-backlog` | Convert approved ADR/Spec → Epic/Story/Task. | Chuyển ADR/Spec đã duyệt thành Epic/Story/Task. |
| `/import-jira` | Import approved backlog into Jira. | Import backlog đã duyệt vào Jira. |
| `/sync-docs` | Sync Git/Jira/Confluence references. | Đồng bộ liên kết Git/Jira/Confluence. |
| `/next` | Continue to the next PM task if no blocker. | Tiếp tục task PM tiếp theo nếu không blocker. |

## 3. Founder → Developer

| Command | EN | VI |
|---|---|---|
| `/start` | Start the first ready Story by Kanban rank. | Bắt đầu Story đầu tiên sẵn sàng theo rank Kanban. |
| `/run` | Continue the autonomous development loop. | Tiếp tục vòng lặp phát triển tự động. |
| `/hold` | Stop before making more code changes. | Dừng trước khi sửa code tiếp. |
| `/approve-pr` | *(Founder)* Approve the PR for merge. | *(Founder)* Duyệt PR để merge. |
| `/request-changes <reason>` | Request changes on the current PR. | Yêu cầu sửa PR hiện tại kèm lý do. |
| `/fix-review` | Apply requested review changes. | Sửa theo review đã yêu cầu. |
| `/retest` | Run tests again and update the report. | Chạy lại test và cập nhật báo cáo. |
| `/next-story` | Take the next ready Story after current PR done. | Nhận Story tiếp theo sau khi PR hiện tại xong. |

## 4. Founder → QA / Deploy

| Command | EN | VI |
|---|---|---|
| `/qa-start` | Start QA for the current PR/Story. | Bắt đầu QA cho PR/Story hiện tại. |
| `/qa-auto` | Run automated QA only. | Chỉ chạy QA tự động. |
| `/qa-manual` | Generate manual device test checklist. | Sinh checklist test thủ công trên thiết bị. |
| `/qa-pass` | Mark QA as passed. | Đánh dấu QA pass. |
| `/qa-fail <reason>` | Mark QA failed; create bug if needed. | Đánh dấu QA fail; tạo bug nếu cần. |
| `/build-android` | Build Android package. | Build gói Android. |
| `/build-ios` | Build iOS package. | Build gói iOS. |
| `/deploy-firebase` | Upload Android → Firebase App Distribution. | Upload Android lên Firebase App Distribution. |
| `/deploy-testflight` | Upload iOS → TestFlight. | Upload iOS lên TestFlight. |
| `/deploy-internal` | Upload Android → Play Internal Testing. | Upload Android lên Play Internal Testing. |
| `/release-note` | Generate release notes. | Tạo release notes. |
| `/deploy-report` | Generate deployment report. | Tạo báo cáo deploy. |

## 5. Founder release commands / Lệnh phát hành (chỉ Founder)

| Command | EN | VI |
|---|---|---|
| `/merge` | Merge approved PR into main. | Merge PR đã duyệt vào main. |
| `/close-story` | Move Story to Done after merge/QA pass. | Chuyển Story sang Done sau merge/QA pass. |
| `/release-internal` | Approve internal test release. | Duyệt phát hành nội bộ. |
| `/release-beta` | Approve beta release. | Duyệt phát hành beta. |
| `/release-production` | Approve production release. | Duyệt phát hành production. |

> **EN:** Only the Founder may authorize a **production** release (`/merge`, `/release-production`). Agents never merge main or release production.
> **VI:** Chỉ Founder được duyệt phát hành **production** (`/merge`, `/release-production`). Agent không bao giờ merge main hay release production.

## 6. Founder → unblock a parked decision / Mở chặn task đang chờ

EN: Reply on the parked issue's `[SPONSOR DECISION REQUIRED]` comment with **one line**. Next cycle the PM/runtime re-queues the task.
VI: Trả lời ngay comment `[SPONSOR DECISION REQUIRED]` của issue đang treo bằng **một dòng**. Vòng sau PM/runtime đưa lại hàng đợi.

| Command | EN | VI |
|---|---|---|
| `APPROVE OPTION A` | Approve option A; agent proceeds with A. | Duyệt phương án A; agent làm theo A. |
| `APPROVE OPTION B` | Approve option B; agent proceeds with B. | Duyệt phương án B; agent làm theo B. |
| `REJECT` | Reject; agent drops/closes the parked approach. | Từ chối; agent bỏ/đóng hướng đã treo. |
| `REQUEST CHANGES: <text>` | Ask for a revised proposal before proceeding. | Yêu cầu đề xuất lại trước khi làm tiếp. |

> **EN:** These aren't `/slash` commands — they're the exact reply keywords the `[SPONSOR DECISION REQUIRED]` comment lists under "Continuation condition." A holding status (`WAITING_FOR_SPONSOR`/`NEEDS_DECISION`) is added by the Founder in Jira settings; until then agents use `IDEA` + label `sponsor-review`.
> **VI:** Đây không phải lệnh `/slash` — là đúng các từ khoá trả lời mà comment `[SPONSOR DECISION REQUIRED]` liệt kê ở "Continuation condition." Status chờ (`WAITING_FOR_SPONSOR`/`NEEDS_DECISION`) do Founder thêm trong Jira settings; trước đó agent dùng `IDEA` + nhãn `sponsor-review`.
