# NON-BLOCKING SPONSOR APPROVAL — Policy / Chính sách phê duyệt không chặn

- **AI Workforce V1** · Bilingual EN/VI · 2026-07-10 · Founder-ordered.
- **Applies to every role:** PM · Developer · QA · Deploy · any future agent.
- Read this together with [AI_CONTEXT.md](AI_CONTEXT.md). The runtime dispatcher
  (`workizen-ai-workforce-runtime/runtime.sh`) enforces it in unattended mode.

## 0. Principle / Nguyên tắc

EN: The runtime must **never halt everything** just because one task needs the
Sponsor/Founder to approve, confirm, or choose an option. When a decision is above
an agent's authority, that agent parks **only that task** (non-blocking) and keeps
working on other **independent** tasks.
VI: Runtime **không được dừng toàn bộ** chỉ vì một task cần Sponsor/Founder phê duyệt,
xác nhận hay chọn phương án. Khi một quyết định vượt quyền agent, agent chỉ **treo
riêng task đó** (non-blocking) và tiếp tục các task **độc lập** khác.

> One blocked Story never blocks the Epic, the repo, or the other roles.
> Một Story bị chặn không kéo theo Epic, repo, hay các role khác.

## 1. Holding statuses & labels / Trạng thái chờ & nhãn

EN: Move the blocked item to a **holding status**, don't leave it "In Progress":
VI: Chuyển item bị chặn sang **trạng thái chờ**, đừng để nguyên "In Progress":

| Prefer / Ưu tiên | Fallback / Thay thế |
|---|---|
| `WAITING_FOR_SPONSOR` or `NEEDS_DECISION` | `IDEA` (if the board has no holding status) |

Add labels / Gắn nhãn: `sponsor-review` · `needs-decision` · `non-blocking` · the role (`pm` / `dev` / `qa` / `deploy`).

EN: The Jira `WH` board today has no `WAITING_FOR_SPONSOR` status → use **`IDEA`** +
the labels above until the Founder adds a status (MCP cannot create statuses).
VI: Board `WH` hiện chưa có status `WAITING_FOR_SPONSOR` → dùng **`IDEA`** + các nhãn
trên cho tới khi Founder thêm status (MCP không tạo được status).

## 2. The non-blocking process / Quy trình không chặn

**Step 1 — Stop only the blocked task / Chỉ dừng task bị chặn.**
EN: Don't build the part that depends on the pending decision. Never assume the
Sponsor's answer on a mandatory-approval matter.
VI: Không làm phần phụ thuộc quyết định chưa duyệt. Không tự giả định câu trả lời của
Sponsor với vấn đề thuộc mức phê duyệt bắt buộc.

**Step 2 — Move the task to a holding status + label it** (§1).

**Step 3 — Write ONE complete `[SPONSOR DECISION REQUIRED]` comment** (§3) so the
Founder can decide without re-reading the whole history.

**Step 4 — Preserve the work already done / Bảo toàn kết quả** (§4).

**Step 5 — Pick the next independent task and continue** (§5). Never conclude
"nothing to do" only because the top-priority task is waiting.

## 3. `[SPONSOR DECISION REQUIRED]` comment template / Mẫu comment

EN: Post this as a Jira comment on the parked issue. Bilingual summary line at top,
the structured body in English. **Always give a recommendation — never just forward
the question.**
VI: Đăng comment này lên issue bị treo. Dòng tóm tắt song ngữ ở đầu, thân có cấu trúc
bằng tiếng Anh. **Luôn kèm khuyến nghị — không đẩy câu hỏi trần cho Sponsor.**

```text
[SPONSOR DECISION REQUIRED]
EN: <one-line what's blocked>. · VI: <một dòng đang chặn gì>.

Context:
- Task:            <issue key + title>
- Role:            <pm | dev | qa | deploy>
- Work completed:  <what is already done>
- Current status:  <branch / PR / doc / build state>

Decision required:
- <the exact decision, phrased as a clear question>

Options:
  Option A:
    - Description:   <...>
    - Advantages:    <...>
    - Disadvantages: <...>
    - Risks:         <...>
  Option B:
    - Description:   <...>
    - Advantages:    <...>
    - Disadvantages: <...>
    - Risks:         <...>

Agent recommendation:
- Recommended:  <Option A | Option B>
- Reason:       <why>

Impact:
- Architecture:        <...>
- Source code:         <...>
- UX / Product:        <...>
- Security / Ops:      <...>
- Related tasks/repos: <...>

Risk of delaying:
- <what worsens if this waits>

Continuation condition (Founder replies with):
- APPROVE OPTION A
- APPROVE OPTION B
- REJECT
- REQUEST CHANGES: <text>

Artifacts:
- Branch:  <name>
- Commit:  <sha>
- PR:      <url or "none">
- Docs:    <path>
- Report:  <path>

Moved to WAITING_FOR_SPONSOR (or IDEA). The runtime continues other independent tasks.
```

## 4. Preserve results before switching / Bảo toàn trước khi chuyển task

EN: Before moving on, the agent must:
- Save every document produced · update the report · update the Jira/backlog status.
- Commit valid changes · push the feature branch to origin **if the repo allows**.
- Leave **no** working-tree changes in an unknown/broken state.
- **Never merge** the not-yet-approved part if the decision affects architecture,
  product, or production.
VI: Trước khi chuyển: lưu mọi tài liệu · cập nhật report · cập nhật trạng thái
Jira/backlog · commit thay đổi hợp lệ · push feature branch lên origin nếu repo cho
phép · không để working tree ở trạng thái hỏng/không rõ · **không merge** phần chưa
duyệt nếu quyết định ảnh hưởng kiến trúc/sản phẩm/production.

## 5. Pick the next independent task / Chọn task độc lập tiếp theo

EN: After parking, the agent scans for the next task it can do **without** the pending
decision. Priority order:
VI: Sau khi treo, agent quét task tiếp theo làm được **không cần** quyết định đang chờ.
Thứ tự ưu tiên:

1. Ready/TODO task with no dependency on the pending decision.
2. Same-Epic task with no dependency.
3. Bug / tech-debt with clear scope.
4. Docs / test / QA / automation that isn't blocked.
5. Analysis prep for upcoming items.
6. Any other backlog task fitting the current role.

EN: Sources to check (don't stop at the first): Jira backlog · TODO list · Work-Order
queue · dependency graph · unfinished Epic items · latest reports · handovers from the
previous role.
VI: Nguồn phải kiểm (đừng dừng ở nguồn đầu): backlog Jira · TODO · hàng đợi Work-Order ·
đồ thị phụ thuộc · item Epic chưa xong · report gần nhất · bàn giao từ role trước.

## 6. Dependency rules / Quy tắc phụ thuộc

EN: A task **directly** depending on the pending decision stays `blocked`. A task **not**
directly depending keeps running. Agents must **not**:
- block a whole Epic because one Story is blocked ·
- block a whole repo because one module needs a decision ·
- stop PM because Dev needs an approval ·
- stop QA because another feature is undecided ·
- stop the whole runtime because one PR is unmerged.
VI: Task phụ thuộc **trực tiếp** vào quyết định → giữ `blocked`. Task **không** phụ thuộc
trực tiếp → vẫn chạy. Không được: chặn cả Epic vì một Story · chặn cả repo vì một module ·
dừng PM vì Dev chờ duyệt · dừng QA vì feature khác chưa quyết · dừng cả runtime vì một PR
chưa merge.

## 7. Partially-doable tasks / Task làm được một phần

EN: If a task has an independent part **and** a part needing approval:
1. Split into subtasks / Work Orders. 2. Do the independent part. 3. Move the
approval part to `WAITING_FOR_SPONSOR`/`IDEA`. 4. Record the dependency between them.
5. **Never mix** un-approved code into the safely-mergeable part.
VI: Nếu task có phần độc lập **và** phần cần duyệt: 1. tách subtask/Work Order · 2. làm
phần độc lập · 3. chuyển phần cần duyệt sang `WAITING_FOR_SPONSOR`/`IDEA` · 4. ghi rõ
phụ thuộc · 5. **không trộn** code chưa duyệt vào phần merge an toàn được.

## 8. When stopping the whole runtime IS allowed / Khi được dừng toàn bộ

EN: Halt everything **only** when one of these is true — and still write a full report
before stopping:
VI: Chỉ dừng toàn bộ khi một trong các điều sau đúng — và vẫn phải viết report đầy đủ
trước khi dừng:

- No independent task is left to do.
- The repo/environment risks data loss.
- A credential or secret is exposed.
- Build/repo is severely broken and every task depends on the fix.
- The Founder ordered `STOP ALL`.
- Risk of a wrong production deploy.
- A foundational architecture conflict would make all further work likely to be redone.

## 9. Returning to parked tasks / Quay lại task đã treo

EN: Every dispatch cycle, the PM Agent / runtime orchestrator re-checks issues in
`WAITING_FOR_SPONSOR` / `NEEDS_DECISION` / `IDEA`+`sponsor-review` for a Founder reply.
On a reply:
1. Read the full decision + related comments.
2. Update the Decision Log / ADR if needed.
3. Move the task back to `READY` / `TODO` (or the right status).
4. Re-queue it by priority.
5. Keep the earlier context + artifacts intact.
VI: Mỗi vòng dispatch, PM Agent / orchestrator kiểm lại các issue
`WAITING_FOR_SPONSOR` / `NEEDS_DECISION` / `IDEA`+`sponsor-review` xem Founder đã trả lời
chưa. Khi có trả lời: đọc quyết định + comment liên quan · cập nhật Decision Log/ADR nếu
cần · chuyển task về `READY`/`TODO` · đưa lại hàng đợi theo ưu tiên · giữ nguyên context
và artifact đã có.

## 10. Founder decision syntax / Cú pháp Founder quyết định

EN: The Founder unblocks a parked task by replying with one of:
`APPROVE OPTION A` · `APPROVE OPTION B` · `REJECT` · `REQUEST CHANGES: <text>`.
A slash command is enough — no long free-text approval needed.
VI: Founder mở chặn bằng một trong: `APPROVE OPTION A` · `APPROVE OPTION B` · `REJECT` ·
`REQUEST CHANGES: <text>`. Một dòng là đủ — không cần duyệt dài dòng.

## 11. End-of-cycle report / Báo cáo cuối chu kỳ

EN: Every cycle report ([CYCLE_REPORT_TEMPLATE.md](CYCLE_REPORT_TEMPLATE.md)) must
separate: **Completed · In progress · Waiting for Sponsor · Blocked by technical
dependency · Selected next · Sponsor decisions required · Commits/branches · Risks.**
VI: Mỗi report cuối chu kỳ phải tách rõ: **Đã xong · Đang làm · Chờ Sponsor · Bị chặn bởi
phụ thuộc kỹ thuật · Chọn làm tiếp · Quyết định Sponsor cần · Commit/branch · Rủi ro.**

---

> Governance / Quản trị: Founder-ordered 2026-07-10. Record in
> `workizen-knowledge-base/decisions/DECISIONS.md` + `canonical/05_DECISIONS.md` per
> `KNOWLEDGE_UPDATE_PROTOCOL.md`. This policy **adds** to AI Workforce V1; it does not
> change the 4 roles, the Kanban flow, or the Founder-only gates.
