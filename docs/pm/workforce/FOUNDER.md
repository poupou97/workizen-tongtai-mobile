# FOUNDER — Role / Vai trò

- **AI Workforce V1** · Bilingual EN/VI · 2026-07-08.

## Who / Là ai
EN: The Founder owns vision, roadmap, and every irreversible gate. The Founder drives the team remotely by comments + slash commands ([COMMANDS.md](COMMANDS.md)).
VI: Founder sở hữu tầm nhìn, roadmap, và mọi cổng không thể đảo ngược. Founder điều khiển đội từ xa bằng comment + slash command ([COMMANDS.md](COMMANDS.md)).

## Owns / Sở hữu
EN: Vision · roadmap priority · **ADR approval** · **PR merge to main** · **release approval** (internal/beta/production).
VI: Tầm nhìn · ưu tiên roadmap · **duyệt ADR** · **merge PR vào main** · **duyệt phát hành** (nội bộ/beta/production).

## Exclusive gates (never delegated) / Cổng độc quyền (không uỷ quyền)
EN: `/merge` · `/close-story` · `/release-internal` · `/release-beta` · `/release-production` · approve/reject analysis · ratify ADR.
VI: `/merge` · `/close-story` · `/release-internal` · `/release-beta` · `/release-production` · duyệt/từ chối phân tích · ratify ADR.

## Typical remote flow / Luồng remote điển hình
EN:
1. Comment an idea in **Ideas** → `/analyze` (PM).
2. Review PM analysis → `/approve-analysis` or `/reject-analysis`.
3. `/create-adr` → `/create-backlog` → `/import-jira` (PM).
4. `/start` / `/run` (Developer) → PR opens → `/approve-pr` + `/merge`.
5. `/qa-start` (QA) → `/qa-pass` → `/close-story`.
6. Deploy: `/build-*` + `/deploy-*` (QA/Deploy) when approved.

VI:
1. Comment ý tưởng ở cột **Ideas** → `/analyze` (PM).
2. Xem phân tích PM → `/approve-analysis` hoặc `/reject-analysis`.
3. `/create-adr` → `/create-backlog` → `/import-jira` (PM).
4. `/start` / `/run` (Developer) → PR mở → `/approve-pr` + `/merge`.
5. `/qa-start` (QA) → `/qa-pass` → `/close-story`.
6. Deploy: `/build-*` + `/deploy-*` (QA/Deploy) khi được duyệt.

## Non-blocking decisions / Quyết định không chặn
EN: Agents never wait idle. When a task needs your decision they park **only that task**
(`WAITING_FOR_SPONSOR`/`IDEA`, label `sponsor-review`) with a full
`[SPONSOR DECISION REQUIRED]` comment — context, options, a recommendation, impact, risk —
and keep working other tasks. You unblock it by replying with one line:
`APPROVE OPTION A` · `APPROVE OPTION B` · `REJECT` · `REQUEST CHANGES: <text>`.
The next cycle the PM/runtime re-queues it. Full policy: [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md).
VI: Agent không bao giờ ngồi chờ. Khi một task cần bạn quyết định, chúng chỉ treo **task đó**
(`WAITING_FOR_SPONSOR`/`IDEA`, nhãn `sponsor-review`) kèm comment `[SPONSOR DECISION REQUIRED]`
đầy đủ — bối cảnh, phương án, khuyến nghị, ảnh hưởng, rủi ro — và làm tiếp task khác. Bạn mở
chặn bằng một dòng: `APPROVE OPTION A` · `APPROVE OPTION B` · `REJECT` ·
`REQUEST CHANGES: <text>`. Vòng sau PM/runtime đưa lại hàng đợi. Chính sách đầy đủ:
[NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md).

## Rule / Nguyên tắc
EN: One project = one AI team of exactly 4 roles. The Founder never has to write long approvals — a slash command is enough.
VI: Một project = một đội AI đúng 4 role. Founder không cần viết duyệt dài dòng — một slash command là đủ.
