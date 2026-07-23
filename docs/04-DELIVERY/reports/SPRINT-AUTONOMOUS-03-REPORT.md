# SPRINT-AUTONOMOUS-03 — Autonomous Product Build (Founder offline)

**Thời gian:** 2026-07-22 → 2026-07-23 · **Chế độ:** Autonomous Product Build
Mode (Founder kích hoạt rồi offline) · **Agent:** Claude (Opus 4.8) trong vai
Developer + Tech Lead · **Evidence:** mỗi story chạy `dart format` +
`flutter analyze` + **full** `flutter test` trước khi mở PR; số test ghi ở
từng PR/Jira comment.

## Kết quả: 9 story PASS, 9 PR chờ Founder merge

| # | Story | PR | Base | Test | Ghi chú |
|---|---|---|---|---|---|
| 1 | WTM-105 RootGate split-bug + **ADR-TON-003** | #2 | main | 524/524 | Bug do split; tutorial lần đầu hoạt động lại |
| 2 | WTM-76 Add/Edit Customer | #3 | main | 552/552 | Audit trail + duplicate detection (chuẩn hoá phone VN) |
| 3 | WTM-77 Purchase History | #4 | **#3** | 570/570 | Stacked; AOV + repurchase (loại cancelled) |
| 4 | WTM-80 Chat UI | #5 | main | 534/534 | Local-first; seam `ChatResponder` cho WTM-82 |
| 5 | WTM-106 handover.sh chết hậu split | #6 | main | bash -n + demo + `--check` | **Runtime không thể khởi động trước fix này** |
| 6 | WTM-107 CI (GitHub Actions) | #7 | main | YAML ok | format+analyze+test mỗi PR; Flutter pin `f68aaca9b0` |
| 7 | WTM-81 Chat persistence + **ADR-TON-004** | #8 | **#5** | 550/550 | Schema v4; local-only, KHÔNG outbox (chờ D-5) |
| 8 | WTM-87 Business Goals (Journey epic) | #9 | main | 546/546 | Templates + form đa bước + progress/pace |
| 9 | WTM-91 Opportunity Feed | #10 | main | 532/532 | Filter/sort/bookmark/swipe + undo |

## Thứ tự merge đề xuất

```
#2 → #6 → #7 → #9 → #10 → #3 → #4 → #5 → #8   (→ báo cáo này)
```

- **Stack:** #4 cần #3 (consumer) · #8 cần #5 (chat). Merge base trước, PR
  stacked sẽ tự thu về 1 commit.
- **Conflict dự kiến:** các PR đều cập nhật docs sống (CURRENT-STATUS,
  SCREEN-INVENTORY, CURRENT-STATE-ARCHITECTURE) ở các dòng cạnh nhau — từ PR
  thứ 2 trở đi có thể conflict **chỉ trong docs**, không đụng code. Founder
  có thể yêu cầu agent rebase từng PR sau mỗi merge (một lệnh là đủ).
- Sau khi merge #7 (CI), các PR còn lại update sẽ tự chạy CI — evidence tái
  lập độc lập trên GitHub.

## Quyết định kỹ thuật đã ghi (chờ Founder phê chuẩn)

1. **ADR-TON-003** (trong PR #2, đã duyệt trước qua C-3): repo độc lập
   supersede phần "single-app + flavors" của ADR-TON-001.
2. **ADR-TON-004** (trong PR #8, PROPOSED): chat persistence **local-only** —
   AC "cloud backend sync" của WTM-81 defer theo D-5; chat KHÔNG vào sync
   outbox (test assert); SQLCipher = option cấp platform chờ Founder.

## Blocker chiến lược & câu hỏi tồn đọng (không tự xử)

- **WTM-81 sync AC / D-5:** đã defer bằng ADR-TON-004 — Founder phê chuẩn
  hoặc đổi hướng khi review PR #8.
- **WTM-83** trùng phần lớn WTM-61 (thiếu QR input — dependency mới L2 — và
  key rotation UX). Chờ Founder chốt scope.
- **WTM-101** ("Onboarding Tutorial Screens") có vẻ trùng WTM-59 đã ship —
  đề nghị Founder đóng hoặc làm rõ.
- **WTM-85/86** (cache/offline) giả định repo DB-backed cho
  customers/products — hiện các module chạy in-memory theo thiết kế; nối
  Drift vào services là quyết định kiến trúc dữ liệu (L3).
- **Tự-merge:** không thực hiện — WORKING-RULES ghi main là Founder-only
  (gate version-controlled); repo chưa có branch protection và CI chưa nằm
  trên main, nên điều kiện "CI và branch policy cho phép" chưa thoả.

## Backlog còn khả thi cho phiên kế

Stacked tiếp: WTM-92 (Opportunity detail, trên #10) · WTM-84 (chat search UI,
trên #8) · WTM-82 (AI routing, trên #8 — BYOK client đã có trên main) ·
WTM-88 (AI action plan, trên #9). Độc lập sau khi merge đợt này: WTM-95–98
(Reports/Dashboard) · WTM-99 (CSV export — D-10 khuyến nghị defer Phase 3) ·
WTM-102 (demo data).

## Sự cố & bài học

- **Suýt commit WTM-76 lên branch WTM-105** — gỡ bằng cherry-pick + reset
  branch (main không bị đụng). Bài học: story phụ thuộc nhau thì stack branch
  ngay từ đầu và ghi rõ trong PR.
- **`Dismissible` giữ state dismissed khi key không đổi** (WTM-91) — key phải
  chứa reaction. Ghi vào commit message làm reference.
- **SQLite LIKE chỉ case-insensitive với ASCII** (WTM-81) — keyword search
  chạy ở Dart để đúng với tiếng Việt.
