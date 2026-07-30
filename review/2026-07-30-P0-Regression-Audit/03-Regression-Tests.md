# 03 — Regression Tests | Bug → Test mapping (fail-cũ / pass-mới)

Nguyên tắc governance: mỗi bug tìm thấy có regression test đi qua **production
wiring** — fail trên code cũ, pass sau fix. Suite P0 = 27 tests trong
`test/features/tongtai/p0/` + các suite viết lại.

## Bug thật → test khoá

| # | Bug (phát hiện) | Fix | Test khoá (fail-cũ/pass-mới) |
|---|---|---|---|
| 1 | 2 dashboard song song lệch số (Founder, device) | #66/#67 xoá `.demo()`, một Home | `tongtai_home_screen_test.dart` (viết lại production-wiring; "Explore Demo Mode seeds the PRODUCTION repositories in place") |
| 2 | Export xuất fixture thay vì dữ liệu user | #67 Export đọc repos | `p0/one_source_consistency_test.dart` (Export ≡ repos) + `tongtai_csv_export_test.dart` explicit injection |
| 3 | Chat AI trả lời từ sample defaults | #67 builder rỗng + `_RealDataChatResponder` | `tongtai_workizen_ai_router_test.dart` (không còn default ngầm) + p0 one-source |
| 4 | Timeline hiện sự kiện mẫu | #67 `_loadReal` từ repos | timeline tests + p0 acceptance |
| 5 | Create actions "biến mất" sau bản ghi đầu | #66 quick actions | home suite + `p0/nav_availability_test.dart` ("create paths never disappear") |
| 6 | Label song ngữ " · ", " \| ", empty-state 2 dòng | #68/#70 | `p0/localization_test.dart` locks 1–2 (regex scans, FAIL trên code cũ) |
| 7 | Chuỗi VI hard-code / labelVi-labelEn trực tiếp trong ui/ | #70/#71 | locks 3–4 + lock 8 (NO literal trong text positions) |
| 8 | Đổi ngôn ngữ không update/persist | (foundation WTM-119, verify §2) | `p0/localization_test.dart` switch+persist qua `languageProvider` + SharedPreferences thật |
| 9 | **removeAll FK 787 trên SQLite thật** (suite §3 tìm ra) | #71 orders-first | `p0/drift_restart_test.dart` — 3 session trên 1 file .db thật |
| 10 | **Home overflow @320px/1.3×** (suite §3 tìm ra) | #71 Flexible+FittedBox | `p0/overflow_test.dart` (vi+en, empty+seeded, +2.0× proxy) |
| 11 | Fallback `.sample()` tiềm ẩn (reports/history) | #71 → rỗng | `p0/sample_fallback_scan_test.dart` (ban vĩnh viễn) |

## Suite bắt buộc theo directive — trạng thái

| Suite | File | Ghi chú |
|---|---|---|
| Repository integration | `test/features/tongtai/*/…repository_test.dart` (có sẵn) + `p0/drift_restart_test.dart` | file-backed thật |
| BusinessContext composition | `p0/one_source_consistency_test.dart` (mirror wiring provider thật) | |
| Cross-screen consistency | như trên (context ≡ repos ≡ fixtures qua CÙNG container) | |
| Sample lifecycle | `p0/sample_data_seeder_test.dart` (5) + drift_restart (edit→remove→restart) | |
| Opportunity e2e | p0 one-source (persisted → RuleEngine `gen-*` → context slice) | |
| Nav/action availability | `p0/nav_availability_test.dart` (3, app-shell thật) | |
| Localization switching + scans + key checks | `p0/localization_test.dart` (8 locks) + `p0/l10n_placeholder_test.dart` (2) | |
| Golden/overflow EN/VI + locale dài | `p0/overflow_test.dart` — overflow-exception thay golden-png (CI-ổn định hơn); locale dài = 2.0× proxy (app mới có vi+en) | gap ghi ở 08 |
| Restart/persistence | `p0/drift_restart_test.dart` (file thật) + acceptance in-memory | |
| Acceptance scenario | `p0/one_source_consistency_test.dart` test 3 (fresh→seed→create→update→delete-sample→restart→verify) | |

**Tổng:** 990 tests (885 trước audit → 990), analyze clean, evidence trong `07-Test-Evidence/`.
