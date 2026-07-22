# WORK_ORDER_TEMPLATE / Mẫu Work Order

- **AI Workforce V1** · Bilingual EN/VI. Founder fills this (or just uses slash commands for small tasks).

```
# WORK ORDER — <title>
Status: DRAFT | APPROVED
Role: <Founder → PM | Developer | QA/Deploy>

## Objective / Mục tiêu
EN: <what outcome, in one or two lines>
VI: <kết quả mong muốn, 1–2 dòng>

## Scope / Phạm vi
EN: <what is in scope>
VI: <những gì trong phạm vi>

## Out of scope / Ngoài phạm vi
EN: <what NOT to do>
VI: <những gì KHÔNG làm>

## Deliverables / Sản phẩm
- <file / Jira issue / PR / build>

## Constraints / Ràng buộc
EN: no source-code change unless Developer role · no merge main/release/deploy · stop on real blocker only
VI: không đổi code trừ role Developer · không merge main/release/deploy · chỉ dừng khi blocker thật

## Definition of Done / Hoàn thành
EN: <verifiable done conditions>
VI: <điều kiện hoàn thành kiểm chứng được>

## Command entry / Lệnh khởi động
<e.g. /analyze  |  /start  |  /qa-start>
```

EN: Keep it short. A slash command in a Jira/PR comment is enough for most tasks; a full Work Order is for larger, multi-step efforts.
VI: Giữ ngắn gọn. Một slash command trong comment Jira/PR là đủ cho hầu hết task; Work Order đầy đủ dành cho việc lớn, nhiều bước.
