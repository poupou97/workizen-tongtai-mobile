# CYCLE_REPORT_TEMPLATE / Mẫu báo cáo chu kỳ

- **AI Workforce V1** · Bilingual EN/VI · 2026-07-10.
- EN: Every dispatch cycle (unattended runtime) or work session (interactive) ends with
  this report. It exists so the Founder sees, at a glance, what moved and what needs a
  decision — enforcing [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md) §11.
- VI: Mỗi vòng dispatch (runtime tự động) hay phiên làm việc (thủ công) kết thúc bằng
  report này. Mục đích: Founder thấy ngay việc gì đã chạy và việc gì cần quyết định —
  thực thi [NON_BLOCKING_POLICY.md](NON_BLOCKING_POLICY.md) §11.

```text
# WORKFORCE CYCLE REPORT — <role> — <ISO-8601 timestamp>
EN: <one-line summary of the cycle>. · VI: <một dòng tóm tắt vòng này>.

## Completed / Đã xong
- <issue key — what was done — PR/commit>

## In progress / Đang làm
- <issue key — where it stands now>

## Waiting for Sponsor / Chờ Sponsor
- <issue key — decision required — link to the [SPONSOR DECISION REQUIRED] comment>

## Blocked by technical dependency / Bị chặn bởi phụ thuộc kỹ thuật
- <issue key — what it depends on (NOT a sponsor decision)>

## Selected next / Chọn làm tiếp
- <issue key — the next independent task picked, per NON_BLOCKING_POLICY §5>

## Sponsor decisions required / Quyết định Sponsor cần
- <issue key — reply APPROVE OPTION A|B / REJECT / REQUEST CHANGES: ...>

## Commits & branches / Commit & nhánh
- <repo — branch — commit sha — pushed? — PR url>

## Risks & warnings / Rủi ro & cảnh báo
- <risk if a decision is delayed · any half-done state · secrets/data notes>
```

EN: Rules —
- Keep it short; one line per item; link everything (Jira / PR / doc).
- Every item MUST fall in exactly one section — never hide a blocker.
- If **Waiting for Sponsor** is non-empty, **Selected next** must show the runtime kept
  working (or state why no independent task remained — a valid stop-all reason, §8).
- Interactive sessions may post the report as a Jira/PR comment; the unattended runtime
  prints it to its log each cycle.
VI: Quy tắc —
- Ngắn gọn; mỗi item một dòng; kèm link (Jira/PR/doc).
- Mỗi item nằm đúng một mục — không giấu blocker.
- Nếu **Chờ Sponsor** khác rỗng, **Chọn làm tiếp** phải cho thấy runtime vẫn chạy tiếp
  (hoặc nêu lý do hết task độc lập — một lý do stop-all hợp lệ, §8).
- Phiên thủ công có thể đăng report thành comment Jira/PR; runtime tự động in ra log mỗi vòng.
