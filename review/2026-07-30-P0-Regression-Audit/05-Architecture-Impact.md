# 05 — Architecture Impact | Tác động kiến trúc + Root cause đầy đủ (§5)

## Vì sao test cũ vẫn xanh mà bug thật lọt lưới (root cause report)

1. **Parallel demo state (bug class #1).** Trước ADR-TON-014, mỗi màn có 2
   đường dữ liệu: injected/real và `kSample*`/`.sample()` fallback ngầm.
   Widget test cũ pump màn KHÔNG inject → rơi đúng vào fallback fixture →
   test và production cùng nhìn dữ liệu giả. Test "pass" vì nó xác nhận
   fixture render đúng — không xác nhận NGUỒN dữ liệu đúng.
2. **Bilingual labels (bug class #2).** Convention WTM-60 cũ (label "VI · EN")
   khiến không thể chuyển ngôn ngữ; test cũ assert đúng chuỗi song ngữ đó →
   khoá chặt kiến trúc sai.
3. **Mock-only wiring (bug class #3).** Test cũ pump widget với service/mock
   riêng — không dựng cùng provider graph như app → sai wiring vô hình.
4. **In-memory ≠ SQLite (bug class #4, §3 mới phát hiện).** Test double
   in-memory không enforce FOREIGN KEY → thứ tự xoá sai của seeder chỉ nổ
   trên DB thật (SqliteException 787). Đây chính là bug-class #1 lặp lại ở
   tầng persistence.

## Kiến trúc sau audit

- **ADR-TON-014 (Accepted):** sample data = ordinary rows trong production DB
  (id prefix `sample-`). Không còn demo state. G-1 giữ: không preload, chỉ
  seed khi user bấm; xoá mẫu giữ user data; **orders xoá trước** (FK).
- **ADR-TON-007 mở rộng:** `AppStrings` là API l10n DUY NHẤT cho UI chrome
  (~290 keys VI/EN + methods có tham số); enum domain expose
  `label(languageCode)`; UI bị CẤM đọc `labelVi/labelEn` trực tiếp (scan
  lock). Thêm locale = 1 class + 1 dòng resolver — widget không đổi.
- **Ranh giới content vs chrome:** domain-generated content (rule summaries,
  timeline event titles, AI output, sample fixtures) là DATA — giữ tiếng
  Việt. Mở rộng l10n xuống content layer = quyết định Founder riêng
  (chưa thuộc P0 này).
- **Producer/supplier:** catalog = curated static directory (Phase 2, chưa có
  supplier repository); favorites là phần persist được. KHÔNG phải bug class
  #1 vì không có dữ liệu user tương ứng bị che.
- **Governance ratchets (vĩnh viễn, chạy trong mọi CI):** 8 localization
  locks + `.sample()` ban + placeholder consistency + nav availability +
  overflow + real-file restart = 27 P0 tests. Vi phạm mới fail CI ngay.

## Không thay đổi

- BusinessContext Aggregate Root (ADR-TON-012) + BusinessAiEngine
  (ADR-TON-013): AI vẫn chỉ đọc snapshot; rule-based twins vẫn authoritative.
- Riverpod-only (ADR-TON-002), local-first (D-5), BYOK/privacy red-line G-3.
- Không migration dữ liệu (WTM-122 vẫn CLOSED theo lệnh Founder).

## Sự cố hạ tầng ghi nhận (07-Test-Evidence/ci-runs.txt)

2026-07-30 ~14:30–15:00 ICT: GitHub trễ deliver `pull_request` events cho
branch mới (#69/#70). Xử lý: thêm `workflow_dispatch` vào ci.yml + dispatch
tay cho đúng ref cần merge → evidence CI thật trên GitHub runners; các
pull_request runs sau đó cũng tự chạy và đều xanh (8/8 success). PR #69 đóng,
thay bằng #70 (cùng commits).
