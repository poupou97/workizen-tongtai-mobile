# 08 — Final Checklist | AC PASS/FAIL (trung thực)

## §1 Data consistency / Demo refactor (WTM-144)

| AC | Kết quả |
|---|---|
| Không còn parallel demo state | **PASS** — `.demo()`/`isDemo` xoá; scan `.sample()` ban trong ui/ |
| Sample seed vào production repositories/DB (prefix `sample-`) | **PASS** — SampleDataSeeder + drift_restart trên file thật |
| Mọi màn + BusinessContext đọc MỘT nguồn | **PASS** — one_source_consistency (context ≡ repos ≡ screens) |
| Home counts khớp tuyệt đối domain screens | **PASS** — cross-screen qua CÙNG container |
| Create actions luôn truy cập được | **PASS** — nav_availability "create paths never disappear" |
| Opportunity từ persisted data qua Rule Engine | **PASS** — e2e persisted→`gen-*`→feed/context |
| Sample sửa/xoá được như dữ liệu thường | **PASS** — lifecycle + drift edit-then-remove |
| "Xóa toàn bộ mẫu" giữ nguyên user data | **PASS** — kể cả sau restart trên DB file thật |

## §2 Localization (WTM-145)

| AC | Kết quả |
|---|---|
| CẤM label 2 ngôn ngữ | **PASS** — locks " · " và " \| ", fail trên code cũ |
| 1 locale active | **PASS** — empty-state 2 dòng song ngữ cũng đã xoá |
| Mọi user-facing string qua key | **PASS cho UI chrome** (~290 keys; lock #8 cấm literal trong MỌI vị trí text của ui/). **Ranh giới ghi nhận:** domain-generated content (rule summaries, timeline titles, AI text, fixtures) giữ VI theo thiết kế — là data; mở rộng sang content layer cần quyết định Founder riêng |
| Sẵn sàng 14 ngôn ngữ không sửa widget | **PASS** — thêm locale = 1 class AppStringsXx + 1 dòng resolver |
| Switch runtime update toàn app ngay + persist | **PASS** — test qua languageProvider + SharedPreferences thật |

## §3 Test governance (WTM-146)

| AC | Kết quả |
|---|---|
| Mỗi bug = regression test fail-cũ/pass-mới, production wiring | **PASS** — mapping đầy đủ ở 03 |
| Repository integration | **PASS** (suite có sẵn + drift_restart file thật) |
| BusinessContext composition + cross-screen | **PASS** |
| Sample lifecycle | **PASS** (in-memory + SQLite file, 3 session) |
| Opportunity e2e | **PASS** |
| Nav/action availability | **PASS** (app shell thật, 5 tab + More + create paths) |
| Localization switching + scans + missing/unused key + placeholder | **PASS** (8 locks + placeholder suite) |
| Golden/overflow EN/VI + 1 locale dài | **PARTIAL-BY-DESIGN** — overflow-exception tests @320px/1.3× (vi+en, empty+seeded) + 2.0× proxy thay cho golden PNG (ổn định CI hơn) và thay locale dài (app mới ship vi+en). Khi thêm ngôn ngữ thứ 3: thêm 1 dòng vào ma trận locale của overflow suite |
| Restart/persistence | **PASS** — file SQLite thật, 3 session |
| Acceptance scenario xuyên suốt | **PASS** |

## §4 Jira audit — **PASS** (04-Jira-Audit: comments 11182–11188, WTM-102/119 đóng, backlog sạch)
## §5 Root-cause report — **PASS** (05-Architecture-Impact)
## §6 Review Package — **PASS** (8 artifacts + zip, tự chứa)

## Tổng evidence

- `flutter analyze`: No issues found (07/flutter-analyze.txt)
- `flutter test`: **990/990** (07/flutter-test.txt) · P0 suites 27/27 (07/p0-suites.txt)
- CI GitHub runners: **8/8 success** (07/ci-runs.txt) — main tip `3c851d2`
- Jira: WTM-144 Done · WTM-145 Done · WTM-146 Done khi package này merge

## Tồn đọng minh bạch (không chặn P0)

1. Content-layer l10n (rule/AI/timeline output) — Founder decision riêng.
2. Locale dài thứ 3 chưa tồn tại — proxy 2.0× đang gác.
3. `tongtai_component_showcase_screen.dart` dev-only, unreachable — ứng viên xoá ở dọn dẹp sau.
4. GitHub pull_request event delay — `workflow_dispatch` fallback đã thêm vào ci.yml.
