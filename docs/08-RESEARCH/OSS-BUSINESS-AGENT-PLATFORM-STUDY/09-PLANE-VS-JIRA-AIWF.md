# 09 · Plane vs Jira cho AI-WF — câu migration

> WTM-452 (Epic WTM-447) · 2026-08-25 · dựa trên trace `08-PLANE-WORK-MANAGEMENT.md`
> (SHA `1d0ee24`). Mặc định vào study: **NO MIGRATION** — dưới đây kiểm bằng evidence
> xem có gì đủ mạnh để lật không.

## 1. Học được gì mà KHÔNG đổi Jira

Bốn pattern ở `08 §5` đều là **pattern thiết kế cho Tổng Tài (sản phẩm)**, không đòi
đổi workspace:

| Pattern Plane | Đích trong Tổng Tài | Ghi chú |
|---|---|---|
| Intake/triage (PENDING·SNOOZED·ACCEPTED·DUPLICATE·`duplicate_to`) | Opportunity Hub / hàng đợi ProposedChange (WTM-297): trạng thái duyệt + snooze + trỏ bản trùng | Hiện ProposedChange mới có approve/reject |
| Hai tầng history: `IssueActivity` field-level + `IssueVersion` snapshot | Audit/agent activity: đang có tầng "ai đổi gì", chưa có "lúc đó trông thế nào" | Họ hàng P-31 |
| State-group: state tuỳ biến map vào 6 nhóm ngữ nghĩa cố định | Trạng thái Business Journey / BusinessAction: hiển thị tự do, Rule Twin chỉ tính trên nhóm canonical | Trùng doctrine ADR-TON-018 "mã canonical, cấm nhãn hiển thị" |
| Saved view = filters JSON là dữ liệu | Cách nghĩ cho màn danh sách/báo cáo tuỳ biến sau này | Chưa cấp thiết |

## 2. Agent thao tác work item: Plane API vs Jira MCP

| | Plane external API (đọc từ code) | Jira qua MCP Atlassian (pain đã ghi) |
|---|---|---|
| Shape | REST + OpenAPI (Swagger/Redoc tự mô tả) | MCP tool, schema do Atlassian định |
| List/search | cursor pagination, `per_page` tầng base tới 1000 | `searchJiraIssuesUsingJql` **bị cắt ~5 issue/lần** |
| Identity agent | `APIToken.user_type=Bot` · `is_service` · rate limit per-token | agent đứng tên user OAuth |
| Reactive | Webhook per-entity + `WebhookLog` retry | runtime phải **poll** Jira |
| Rate | 60/min mặc định, chỉnh per-token | quota MCP không kiểm soát được |

**Trả lời thẳng: CÓ, shape của Plane hợp agent hơn** — bot identity là cột trong DB,
webhook thay poll, pagination không nghẹt. **NHƯNG** pain "JQL cắt 5 issue" là pain của
**tầng MCP tool**, không phải của Jira: Jira REST API thường (`/rest/api/3/search`) cũng
trả 100/trang và AI-WF runtime đã gọi REST trực tiếp được. Sửa pain này = **đổi đường gọi**
(REST trực tiếp / subagent quét board như memory đã ghi), rẻ hơn đổi platform khoảng
hai bậc.

## 3. Human + Agent shared work — Plane có gì đặc biệt?

Có **ba mảnh** liên quan, nhưng không có tầng agent thực thụ:
`User.is_bot` + `APIToken.user_type=Bot` (actor bot hiện danh trong activity) ·
comment `access INTERNAL/EXTERNAL` + actor system · Intake làm cổng duyệt đầu vào.
**Không có** model conversation/task-delegation/approval-flow cho agent — AI của Plane
(Plane AI/Pi) nằm ở bản thương mại, **không có trong repo AGPL này** (grep `mcp|agent`
trong `apps/api/plane/db/models/` chỉ ra `user_agent`/`is_bot`). Plane KHÔNG mang lại
năng lực human+agent nào mà Jira + AI-WF runtime hiện chưa có.

## 4. Migration Jira → Plane?

**KHÔNG.** Evidence không những không đủ mạnh để lật mặc định mà còn nghiêng thêm về NO:

1. **Pain thật nằm ở tầng tool, không phải platform** (§2) — sửa được tại chỗ, chi phí thấp.
2. **Chi phí migration là thật và đắt**: luật board WTM (4 cổng Jira visibility, transition
   ID, worklog) khắc trong CLAUDE.md + thói quen runtime; Confluence dính kèm Jira;
   Plane self-host = vận hành thêm một hệ Postgres/Redis/6-app — đi ngược quyết định
   Founder gỡ Grafana/Prometheus để giảm tải (2026-08-09).
3. **AGPL**: tự host Plane có chỉnh sửa = network service kích hoạt nghĩa vụ mở source —
   thêm một cân nhắc pháp lý thay vì bớt (License Gate ở `01-SOURCE-BASELINE.md`).
4. **Không có tính năng agent-native nào bù lại** (§3) — thứ đáng thèm nhất (webhook thay
   poll, bot token) không đủ trả giá cho 1–3.

## 5. Anti-overengineering — "không học Plane thì mất gì?"

Mất **ba pattern có địa chỉ dán sẵn** (§1: intake-triage cho ProposedChange, snapshot
history, state-group canonical) — đều là thứ Tổng Tài sẽ tự vấp rồi tự phát minh lại
kém hơn. Không mất gì mang tính sống còn; phần còn lại của Plane (cycle, gantt,
realtime editor) không chạm roadmap. Study nhẹ 1 buổi là **đúng liều** — đào sâu hơn
sẽ là overengineering vì verdict migration đã NO từ §4.

## Verdict 5 trục

| Trục | Verdict | Lý do một dòng |
|---|---|---|
| Concept / domain model | **LEARN** | State-group 2 tầng · Intake triage · quan hệ 6 loại có reverse-pairs |
| Kiến trúc | **LEARN (chọn lọc)** | Hai tầng history (Activity + Version) · provenance `external_source/id` là trường chuẩn |
| UX | **LEARN** | power-k command palette · inbox triage · saved view = dữ liệu |
| Agent operability | **THAM CHIẾU** | Bot token + webhook là chuẩn tốt để đo tooling Jira của mình, không phải lý do đổi nhà |
| Source code | ⛔ **AGPL-3.0 — CẤM chép**; self-host có sửa phải qua Founder | License Gate `01` |

**Migration Jira → Plane: NO.** Pain hiện tại sửa ở tầng gọi API (REST trực tiếp thay
JQL-qua-MCP), không phải ở platform; chi phí chuyển (luật board + Confluence + vận hành
self-host + AGPL) vượt xa mọi lợi ích đã tìm thấy trong code.
