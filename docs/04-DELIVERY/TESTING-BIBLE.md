# Testing Bible — Tổng Tài

Tri thức lâu dài, không phải danh sách test case. Mỗi bug thật đã sửa để lại
**4 thứ**: Root-Cause Pattern · Regression Pattern · Reusable Test Pattern ·
Prevention Rule. Bug mới phải bổ sung một mục vào đây, không chỉ thêm test.

Bổ trợ: [TEST-STRATEGY.md](TEST-STRATEGY.md) (tầng test, luật cứng) ·
[ADR-TON-015](../03-DECISIONS/ADR-TON-015-ui-maturity-and-one-data-path.md)
(maturity + one-data-path) · [DEFINITION-OF-DONE.md](DEFINITION-OF-DONE.md).

---

## P-01 · Fallback fixture ngầm (silent sample fallback)

- **Root cause:** widget có 2 đường dữ liệu — inject và `?? Something.sample()`.
  Production rơi vào fallback, người dùng thấy dữ liệu giả (Export xuất fixture,
  Chat AI trả lời từ sample, Timeline sự kiện giả).
- **Regression:** test cũ pump màn *không inject* → rơi vào **đúng** fallback mà
  production dùng → test xanh, xác nhận fixture render đẹp, không xác nhận
  **nguồn** đúng.
- **Test pattern:** production wiring — dựng cùng provider graph app dùng; test
  phải inject **tường minh** khi muốn fixture, không bao giờ dựa vào default.
  Khoá vĩnh viễn bằng scan: `p0/sample_fallback_scan_test.dart`.
- **Prevention:** cấm `.sample()` trong `lib/features/tongtai/ui/`
  (allowlist duy nhất: catalog nhà cung cấp Phase-2). Không inject = rỗng,
  không bao giờ là fixture.

## P-02 · Parallel demo state

- **Root cause:** demo là một cây widget riêng đọc fixtures (`TongtaiHomeScreen.demo`)
  → hai dashboard cùng tồn tại, số liệu lệch nhau.
- **Regression:** mỗi bên có test riêng, cả hai xanh; không test nào so **hai
  bên với nhau**.
- **Test pattern:** một nguồn — sample là row thường trong production DB
  (prefix `sample-`, ADR-TON-014); test lifecycle seed→sửa→xoá→user data còn.
- **Prevention:** cấm mọi parallel state (ADR-TON-014 + ADR-TON-015 §2).
  "Xem thử Demo" = seed vào repository thật, không phải một chế độ UI.

## P-03 · Màn tĩnh không có đường dữ liệu (static shell)

- **Root cause:** màn thiết kế L1 (`Consumer`/`Producer` tab) không đọc
  provider nào, số hardcode 0 — nhưng Jira coi story là Done, ai cũng tưởng đã
  nối dữ liệu. Home đếm 1, tab hiện trống.
- **Regression:** **mọi scan trước đó truy tìm đường dữ liệu SAI**
  (fallback/literal/parallel state). Không scan nào bắt được màn **không có
  đường dữ liệu nào**. Lỗi vô hình với chính bộ governance.
- **Test pattern:** **Cross-screen contract** —
  `Summary Count == Domain Visible Records`, so **màn tóm tắt với màn danh
  sách** qua cùng container, trên SQLite file thật, cả record mẫu lẫn record
  user, và **sau restart**. Helper tái dùng:
  `test/support/count_list_contract.dart`.
- **Prevention:** UI Implementation Level (ADR-TON-015) — Jira phải ghi level
  thật; contract test bắt buộc cho mọi domain L2+.

## P-04 · Test double dễ dãi hơn production (in-memory ≠ SQLite)

- **Root cause:** `SampleDataSeeder.removeAll` xoá customers trước orders. DB
  thật bật `PRAGMA foreign_keys` → `SqliteException(787)`. Repo in-memory
  không enforce FK → không ai thấy.
- **Regression:** toàn bộ lifecycle test chạy in-memory → xanh; lỗi chỉ nổ
  trên máy người dùng.
- **Test pattern:** ít nhất **một** suite chạy trên **file SQLite thật**, qua
  nhiều "session" (`AppDatabase` mới trên cùng file) — `p0/drift_restart_test.dart`.
- **Prevention:** mọi thao tác ghi/xoá đa bảng phải có test trên DB thật.
  Test double chỉ dùng cho tốc độ, không dùng để **chứng minh** persistence.

## P-05 · Lỗi tầng build/native chỉ xuất hiện ở release

- **Root cause:** `firebase_crashlytics` có trong dependency nhưng thiếu
  Crashlytics Gradle plugin → thiếu build ID → app chết trong
  `FirebaseInitProvider` trước khi Flutter chạy. Chỉ xảy ra khi **release +
  có `google-services.json`**.
- **Regression:** analyze + 990 test + aapt2 đều ở tầng Dart/manifest — không
  tầng nào chạm gradle-runtime.
- **Test pattern:** smoke-launch bản **release** trên máy thật:
  `adb install -r` → mở app → `adb logcat -b crash` phải RỖNG + có `app_open`.
- **Prevention:** bước bắt buộc trong
  [RELEASE-READINESS-CHECKLIST](../00-START-HERE/RELEASE-READINESS-CHECKLIST.md)
  trước khi giao bản build cho Founder; bắt buộc khi story chạm native/gradle.

## P-06 · Kiến trúc song ngữ khoá chặt bởi test

- **Root cause:** nhãn nối 2 ngôn ngữ (`Timeline · Dòng thời gian`) → không
  thể đổi ngôn ngữ.
- **Regression:** test assert đúng chuỗi song ngữ đó → **test bảo vệ kiến trúc
  sai**.
- **Test pattern:** scan tĩnh cấm literal trong mọi vị trí text của `ui/`
  + test đổi locale runtime qua `languageProvider` thật + persist.
  `p0/localization_test.dart` (8 lock).
- **Prevention:** test **không được** assert text hiển thị cho hành vi —
  dùng stable Key (ADR-TON-015 §3). Text chỉ được assert trong test l10n.

## P-07 · Layout vỡ ở màn hẹp / cỡ chữ lớn

- **Root cause:** `Row`/grid tỉ lệ cố định không co được khi text scale tăng.
- **Regression:** test chạy ở kích thước mặc định (800×600, scale 1.0) — không
  ai chạm 320px/1.3×.
- **Test pattern:** bắt `FlutterError.onError` chứa `overflowed` khi pump ở
  320px + scale 1.3 (và 2.0 làm proxy locale dài), cho **cả** trạng thái rỗng
  và có dữ liệu, cả 2 locale — `p0/overflow_test.dart`.
- **Prevention:** màn mới thêm vào ma trận `screens` của overflow suite trong
  cùng PR.

---

## Quy ước Stable Test IDs (bắt buộc cho L2+)

`<screen>-<role>[-<qualifier>]`, kebab-case:

| Role | Mẫu | Ví dụ |
|---|---|---|
| summary/KPI tile | `<screen>-summary-<metric>` / `<screen>-kpi-<metric>` | `home-kpi-revenue` |
| count badge | `<screen>-count-badge` | `consumer-count-badge` |
| module tile | `<screen>-tile-<domain>` | `home-tile-consumer` |
| list item | `<screen>-item-<recordId>` | `customer-item-${c.id}` |
| primary action | `<screen>-action-<verb>` | `inventory-action-add` |
| empty state | `<screen>-empty` | `search-empty` |
| navigation | `<screen>-open-<target>` | `home-open-reports` |
| search input | `<screen>-search-field` | `customer-search-field` |

**Luật de-stutter:** nếu prefix màn đã kết thúc bằng chính từ đầu của role thì
không lặp lại — unified search (prefix `search`) dùng `search-field`, supplier
search (prefix `supplier-search`) dùng `supplier-search-field`.

**Khoá tự động:** `p0/stable_test_ids_test.dart` — registry màn L2+ phải khớp
ma trận Implementation Levels; màn có danh sách phải có `<prefix>-item-<id>`;
mọi Key trong `ui/` phải kebab-case. Màn L2+ mới **phải** thêm vào registry
trong cùng PR.

**Luật:** test hành vi tìm bằng Key. Tìm bằng `find.text` chỉ hợp lệ trong
test l10n hoặc khi chính nội dung là thứ đang kiểm.

## Bộ suite governance hiện có (`test/features/tongtai/p0/`)

| Suite | Khoá điều gì |
|---|---|
| `count_list_contract_test.dart` | **Summary Count == Visible Records** cho 6 domain, SQLite file thật + restart |
| `sample_data_seeder_test.dart` | lifecycle seed/sửa/xoá mẫu, user data sống sót |
| `one_source_consistency_test.dart` | cross-screen ≡ BusinessContext ≡ repo; acceptance xuyên suốt |
| `drift_restart_test.dart` | persistence + FK trên file SQLite thật, 3 session |
| `sample_fallback_scan_test.dart` | cấm `.sample()` trong ui/ |
| `localization_test.dart` | 8 lock ngôn ngữ (song ngữ, literal, labelVi/En, unused key, switch+persist) |
| `l10n_placeholder_test.dart` | mọi tham số được nội suy ở cả 2 locale |
| `nav_availability_test.dart` | 5 tab + toàn bộ More + create paths ở mọi data state |
| `overflow_test.dart` | không overflow 320px/1.3×/2.0×, 2 locale, rỗng + có dữ liệu |
| `stable_test_ids_test.dart` | màn L2+ phải có Key theo quy ước |

## Khi sửa bug mới — checklist

1. Reproduce trên **đúng môi trường người dùng gặp** (release/máy thật nếu cần).
2. Ghi lại **state thật** (DB dump, log) trước khi sửa.
3. Viết test **fail trên commit hiện tại**, pass sau fix, qua production wiring.
4. Hỏi: *lớp lỗi này còn ở đâu nữa?* → audit toàn bộ cặp/màn cùng loại.
5. Thêm mục Pattern vào file này (4 phần) + khoá bằng scan nếu có thể.
