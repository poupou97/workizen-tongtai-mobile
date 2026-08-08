# SOURCE-MAP — mọi kết luận trỏ về đâu

Đường dẫn tương đối với `~/projects/_reference/trycompai-crm` @ `c26a08d`.

## Durable Agent

| Kết luận | File · Symbol |
|---|---|
| Lịch chạy **mỗi phút**, không phải browser | `apps/agent/agent/schedules/dispatch.ts:11` — `defineSchedule({cron: "* * * * *"})` |
| `FOR UPDATE SKIP LOCKED` **có thật** | `apps/agent/agent/lib/tasks.ts:54` |
| Claim + lease + `attempts++` trong **một** câu lệnh | `tasks.ts:40-59` — `claimDue()` |
| Lease mặc định 10' | `tasks.ts:23` — `LEASE_MS` |
| Hai làn: visible 2' / research 30' | `lib/dispatch.ts:17-22` |
| Hết lượt thử ⇒ nghỉ hưu | `tasks.ts:66` — `retireExhausted()` |
| Chống trùng **lúc đặt lịch** | `tasks.ts:128-144` — `scheduleTask()` tìm task chưa xong cùng kind+subject rồi *update* `dueAt` |
| Lần thử 2 được dặn **tiếp tục, không làm lại** | `lib/dispatch.ts:140-144` — `brief()` |
| Session tối đa **30 ngày** | `agent/agent.ts:23` — `sessionTimeoutMs` |
| `schedule_recheck` có thật, 1–730 ngày, **kèm lý do người đọc** | `tools/schedule_recheck.ts:15-35` |

## Evidence → Fact

| Kết luận | File · Symbol |
|---|---|
| Agent **không được** khai confidence | `tools/record_fact.ts:12-46` — inputSchema không có `score`/`band` |
| *"You never set a confidence… the ledger prices it"* | `agent/skills/evidence.md` |
| Định giá là **hàm thuần**, noisy-OR | `lib/evidence.ts:99` — `scoreEvidence()` |
| 11 `EvidenceKind`, 6 primary | `lib/evidence.ts:3-78` — `WEIGHTS` |
| `contradiction` **kẹp** điểm về 0.45 | `lib/evidence.ts:95,118` |
| Ngưỡng band | `lib/evidence.ts:97` — VERIFIED .85 / PROBABLE .55 / POSSIBLE .3 |
| VERIFIED **và có primary** mới được ghi record | `lib/evidence.ts:129`, `lib/facts.ts:137` |
| Dưới sàn ⇒ **không lưu gì** | `lib/facts.ts:58-66` |
| Người đã DISMISS ⇒ *"Do not offer it again"* | `lib/facts.ts:96-109` |
| Người đã điền ⇒ agent không ghi đè | `lib/facts.ts:126-135`, `humanOwns()` `:263` |
| Fact cũ ⇒ `SUPERSEDED`, không xoá | `lib/facts.ts:141-146` |
| Phát hiện đổi việc là **hệ quả miễn phí** | `lib/facts.ts:193` — `lastEmployerChange()` |

## Identity

| Kết luận | File · Symbol |
|---|---|
| Identity **không có hệ con riêng** — đi cùng `recordFact()` | `tools/identify_contact.ts:32` |
| Verdict tính **trong code**, agent chỉ đọc | `agent/skills/identity-matching.md` §3 |
| *"Both, or it is not them"* | `agent/skills/identity-matching.md` §4 |
| Không tìm được ⇒ **dừng**, giữ nguyên placeholder | `identity-matching.md` §5 |

## Tool boundary · Capability

| Kết luận | File · Symbol |
|---|---|
| Sandbox **deny-all network** cả 3 backend | `agent/sandbox/sandbox.ts:4-8` |
| Biên là **egress**, không phải read | `agent/skills/data-boundaries.md` |
| Capability bơm vào prompt **trước khi plan** | `lib/capabilities.ts:100` — `capabilitiesMarkdown()` |
| Phân biệt *chưa cấu hình* với *thất bại* | `lib/capabilities.ts:78` — `unavailable()` |
| Capability đọc từ **env var** — cấp cài đặt, không per-connection | `lib/capabilities.ts:37-69` |
| Approval: tự động ⇒ **từ chối**; người ⇒ hỏi | `lib/approval.ts:21` — `sensitiveWrite()` (29 dòng) |
| Chỉ **2 tool** dùng approval | `tools/archive_field.ts:13`, `tools/record_job_change.ts:22` |
| Budget đếm **lượt gọi vendor**, enforce ở tool | `lib/focus.ts:38` — `spend()` |

## Event · Action

| Kết luận | File · Symbol |
|---|---|
| **Không có** tầng canonical event | không tồn tại bảng event nghiệp vụ trong 40 migration |
| Trigger **hình dạng domain**, tạo task thẳng | `apps/api/src/agent/agent-trigger.service.ts:15-70` |
| Tiêm vào 7+ service domain | `calendar-sync` · `mailbox-match` · `contacts` · `workspace` · `backfill` · `conversations` · `agent-runs` |
| `agentAction` = Canonical Action thật | `packages/db/prisma/migrations/20260803210000_agent_builder_foundation/migration.sql` |
| Idempotency: key + **requestHash** | `lib/run-runtime.ts:207-221` — cùng key khác payload ⇒ ném lỗi |
| `SUCCEEDED` ⇒ `replayed: true`, không làm lại | `run-runtime.ts:249-255` |
| Claim bằng lease, giống task | `run-runtime.ts:258-273` |
| **Side effect + status trong MỘT transaction** | `run-runtime.ts:292-343` |
| `agentAction` **chỉ** dùng ở runtime custom agent | không có tham chiếu nào từ `tools/` của agent nghiên cứu |

## Bypass

| Kết luận | Bằng chứng |
|---|---|
| **Ba** kỷ luật ghi song song | `lib/facts.ts` (ledger) · `lib/fields.ts`+`portrait.ts`+`research_company.ts` (ghi thẳng) · `lib/run-runtime.ts` (agentAction) |
| **Không** cơ chế nào chặn ghi thẳng | `apps/agent/test/` 24 file, không có boundary test; `biome.jsonc` không có `no-restricted-imports` |

## Conversation · Policy · UX

| Kết luận | File · Symbol |
|---|---|
| `agentConversation` **là chat thread**, không phải trừu tượng nghiệp vụ | migration `20260801160000_agent_conversations` |
| "Câu chuyện bản ghi" dựng **lúc đọc** | `lib/crm.ts` — `readCrmHistory()` join contact/emailThread/calendarEvent/deal |
| `activity` là timeline hợp nhất, 7 loại | `CREATE TYPE "ActivityType"` |
| Con trỏ ngược từ activity về action | `run-runtime.ts:311` — `meta: {source:"agent", agentId, runId, actionId}` |
| Policy = manifest JSONB per agent version | `lib/builder-runtime.ts:205-222` |
| Mỗi policy mang **`summary` người đọc được** | `builder-runtime.ts:212,221` — `scopeSummary()`, `sandboxPolicy.summary` |
| Từ vựng trigger chỉ **4** | `CREATE TYPE "AgentTriggerType"` = MANUAL·SCHEDULE·EVENT·WEBHOOK |
| Agent được **tạo bằng cách nói chuyện** với agent khác | `agent/subagents/agent_builder/` |
