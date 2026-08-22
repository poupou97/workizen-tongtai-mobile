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

## P-08 · Dự báo bịa khi chưa đủ dữ liệu

- **Root cause (lớp lỗi phòng ngừa):** một rule dự báo rất dễ trả `0` hoặc một
  con số "cho có" khi lịch sử quá ngắn — người dùng không phân biệt được *chưa
  đủ dữ liệu* với *dự báo bằng 0*. Cùng họ với P-03.
- **Regression:** test chỉ assert "có trả về số" sẽ xanh với cả hai trường hợp.
- **Test pattern:** envelope `RuleTwinResult` assert ngay trong constructor —
  `result == null` **⟺** `sufficiency == insufficient`, insufficient ⇒
  `confidence == none`. Test tại **mọi ngưỡng biên** (2↔3, 5↔6, 11↔12 tháng);
  UI phải assert **sự VẮNG MẶT** của headline ở trạng thái insufficient.
- **Prevention:** không rule nào được trả số khi thiếu dữ liệu; màn hình render
  lời từ chối + `reasonCodes`, không render 0.

---

## P-09 · Đường dữ liệu hỏng trông y hệt "không có dữ liệu"

- **Root cause (lớp lỗi phòng ngừa):** `initState → _load() → setState`. Nếu
  repository ném lỗi, future không ai bắt, `setState` không chạy, màn đứng
  nguyên ở giá trị khởi tạo rỗng **vĩnh viễn**. Người dùng không có tín hiệu
  nào. Nguy hiểm nhất ở màn tiền: `0 ₫` do đọc hỏng **đọc như một sự thật**.
  Đây là P-03 nhìn từ phía runtime thay vì phía thiết kế.
- **Regression:** test "màn rỗng hiện empty state" xanh với **cả hai** trường
  hợp — không có dữ liệu và không đọc được dữ liệu.
- **Test pattern:** repository **thật** (Drift trên file SQLite thật) bọc một
  decorator chỉ điều khiển **thời điểm** hỏng; assert màn hiện `<prefix>-error`
  **và assert sự VẮNG MẶT** của `<prefix>-empty` + của con số tổng. Rồi bấm
  `<prefix>-error-retry` và assert dữ liệu thật hiện ra. Mẫu:
  `p0/screen_data_seam_test.dart`.
- **Prevention:** mọi đường IO đi qua `ScreenDataController` / `runTongtaiAction`
  (ADR-TON-017); governance test cấm `catch` thủ công trong `ui/`.

---

## P-10 · Refresh hỏng xoá trắng màn đang chạy

- **Root cause:** `AsyncValue.when` và `FutureBuilder` chỉ có ba nhánh —
  không có *stale*. Một lần refresh hỏng biến màn đang có dữ liệu thành màn
  lỗi (hoặc rỗng), dù dữ liệu cũ vẫn dùng được.
- **Regression:** test chỉ kiểm tra "load lần đầu thành công" không bao giờ
  chạm nhánh này.
- **Test pattern:** load thành công → assert dữ liệu → **làm hỏng nguồn** →
  kích hoạt refresh **đúng cách người dùng làm** (mở màn con rồi quay lại) →
  assert dữ liệu **vẫn còn** + `<prefix>-stale` xuất hiện + `<prefix>-error`
  **không** xuất hiện.
- **Prevention:** `ScreenState.toFailed` giữ `value` theo thiết kế; governance
  test cấm `FutureBuilder`/`.when` trong `ui/`.

---

## P-11 · Spinner vô hạn làm `pumpAndSettle` treo

- **Root cause:** `CircularProgressIndicator` luôn lên lịch frame mới, nên
  `pumpAndSettle` không bao giờ "settle" khi màn còn ở trạng thái loading.
  Trước WTM-148 vài màn né bằng cách **không có** trạng thái loading — vô tình
  biến "chưa tải xong" thành "rỗng".
- **Regression:** 30 test treo cùng lúc ngay khi thêm spinner chuẩn.
- **Test pattern:** trạng thái loading của seam là **text tĩnh** (không
  animation). Hệ quả: `pumpAndSettle` cũng không *chờ* load nữa → dùng
  `pumpUntilFound` (`test/support/pump_until.dart`), nó `runAsync` để I/O
  SQLite thật có thời gian thực chạy và báo rõ seam đang ở trạng thái nào khi
  hết lượt pump.
- **Prevention:** governance test cấm indicator vô hạn tự chế trong `ui/`;
  thanh có `value:` (tiến độ mục tiêu, biên lợi nhuận) là **dữ liệu**, được phép.

---

## P-12 · Provider khai báo hai lần ⇒ test override chỉ trúng một nửa app

- **Root cause:** `tongtaiDatabaseProvider` được khai báo ở **hai** file. Production
  mở hai kết nối vào cùng một file `.db`; test override "database" chỉ trúng
  nửa app import đúng ký hiệu đó. Nửa còn lại lặng lẽ mở database thật.
- **Regression:** mọi assertion vẫn xanh — vì nửa được override trả đúng dữ
  liệu, còn nửa kia hỏng im lặng (P-09 che mất).
- **Test pattern:** scan tĩnh đếm số khai báo `final <name>Provider` cho các
  provider hạ tầng dùng chung; assert **đúng một**.
- **Prevention:** một provider hạ tầng = một khai báo, các file khác `export`
  lại. Khoá trong `p0/error_handling_governance_test.dart`.

---

## P-13 · Backup không round-trip được — "khôi phục" làm mất dữ liệu

- **Root cause (lớp lỗi phòng ngừa):** một file *export để đọc* bị dùng làm
  *backup để khôi phục*. CSV v1 tối ưu cho Excel: enum in ra **nhãn tiếng
  Việt**, tiền `.round()`, và **bỏ hẳn** `order.id` + `OrderItem.productId`.
  Khôi phục từ nó thì đứt toàn bộ liên kết Inventory↔Orders, mất goals/
  finance/favourites, mà **không có thông báo nào**.
- **Regression:** test chỉ kiểm "xuất ra có đủ dòng" xanh với cả file khôi
  phục được lẫn file không.
- **Test pattern:** round-trip **qua database thật**: seed đủ mọi trường →
  backup → **xoá sạch** → restore → assert **từng trường**, kể cả id, khoá
  ngoại và số lẻ tiền. Thêm một test **codec-only** để tách "format giữ được
  gì" khỏi "database giữ được gì". Và assert **payload không chứa nhãn hiển
  thị** (`isNot(contains('Đã giao'))`).
- **Prevention:** enum đi bằng `.name`; mã enum lạ là **bản ghi hỏng**, không
  phải giá trị mặc định; trường dẫn xuất không được lưu vào backup.

---

## P-14 · Thao tác phá huỷ không có đường lùi đã được kiểm chứng

- **Root cause:** "tạo bản sao lưu an toàn trước khi ghi đè" rất dễ trở thành
  một file **ghi ra rồi không ai đọc lại** — an tâm giả. Và một restore không
  atomic sẽ để lại doanh nghiệp **nửa vời** khi hỏng giữa chừng.
- **Regression:** test chỉ chạy đường thành công không bao giờ chạm hai lỗi này.
- **Test pattern:** ba test bắt buộc — (1) vault **ghi hỏng** ⇒ không xoá gì;
  (2) vault ghi ra thứ **đọc lại không restore được** ⇒ không xoá gì; (3)
  repository **ném lỗi giữa lúc ghi**, sau khi đã xoá ⇒ đếm lại phải bằng
  đúng trước đó. Kèm một test đọc lại chính bản an toàn **qua validator thật**.
- **Prevention:** verify bản an toàn bằng chính validator của người dùng; apply
  trong **một** transaction và verify **bên trong** nó.

---

## P-15 · Real I/O trong `testWidgets` treo vĩnh viễn

- **Root cause:** `testWidgets` chạy thân test trong **fake-async zone**.
  Future của SQLite, file và cả `cryptography`'s `Sha256().hash()` **không bao
  giờ hoàn tất** ở đó. Triệu chứng là test *treo*, không phải fail — nên rất
  dễ bị đổ cho "máy chậm".
- **Regression:** cả suite đứng im, không có dòng lỗi nào.
- **Test pattern:** mọi đọc/ghi thật trong widget test đi qua
  `tester.runAsync`; `pumpUntilFound` phải đẩy **cả hai đồng hồ** (`runAsync`
  cho I/O thật + `pump(step)` cho timer trong zone).
- **Prevention:** widget **không** tự chạm `dart:io` — nhận nội dung qua seam
  (`TongtaiPickedBackup`); thứ vốn không cần async thì đừng async (checksum
  chuyển sang `package:crypto` **đồng bộ**).

## P-16 · Test hiệu năng phải đo thứ **không đổi theo máy**

- **Root cause:** một test hiệu năng viết bằng mili-giây trên máy dev là một
  **benchmark desktop đội lốt tuyên bố về thiết bị**: nó vừa nói sai về trải
  nghiệm người dùng, vừa đỏ ngẫu nhiên trên CI. Nhưng bỏ hẳn test hiệu năng thì
  hồi quy chỉ lộ ra ở người bán có nhiều dữ liệu nhất — người ít có khả năng
  biết vì sao app chậm.
- **Regression:** WTM-166 — một lần cold start đọc `orders` **5 lần**,
  `customers`/`goals` **4 lần**. Ở máy test 20 dòng thì tốn ~5ms nên **không có
  phép đo nào trên thiết bị nhìn thấy nó**; ở 12 tháng dữ liệu thật (529 đơn)
  nó là **3.0× chi phí cần thiết**.
- **Test pattern:** khoá **số lần đọc** (giống nhau trên mọi máy) bằng
  repository decorator đếm, chạy qua **đúng wiring production**; nếu cần nói về
  chi phí thì khoá **tỉ lệ** đo trong cùng một lần chạy (`đọc-thật / đọc-một-lần`),
  không bao giờ khoá con số tuyệt đối.
- **Prevention:** mili-giây **của người dùng** chỉ được lấy từ **máy thật, bản
  release** (`am start -W` + mốc trong app sau `--dart-define`), và ghi kèm
  n / min / median / max. Nếu thay đổi nhỏ hơn biên độ dao động ⇒ báo cáo
  **"không đo được"**, không báo cáo hướng cải thiện.

## P-17 · Màn vắng mặt trong governance suite **không phải** màn đã pass

- **Root cause:** bộ overflow của P0 liệt kê 10 màn — và **thiếu ba tab chính**
  (Producer · Inventory · Consumer). Ba màn người dùng mở nhiều nhất là ba màn
  chưa ai đo. "Suite xanh" nói về **danh sách trong suite**, không nói về app.
- **Regression:** WTM-169 thêm ba màn vào danh sách và lập tức có **năm** lỗi
  tràn thật: Inventory clip 103px ở font 2.0x · empty state clip 55px ·
  pagination bar clip 11px (nuốt luôn nút "trang sau") · Consumer clip 69px và
  23px ở 320px tiếng Việt. Không lỗi nào mới — chúng đã ở đó suốt.
- **Test pattern:** danh sách màn trong governance suite phải là **toàn bộ màn
  L2+**, không phải các màn ai đó nhớ ra. Khi thêm màn mới, thêm vào suite
  **cùng PR**. Guideline chạy được thì để guideline chạy: `androidTapTargetGuideline`
  · `labeledTapTargetGuideline` · `textContrastGuideline` là **bar của Android**,
  không phải ý kiến của mình.
- **Prevention:** harness phải **bắt overflow và gọi tên màn**. Handler mặc định
  in ra khi widget đã `DEFUNCT` — thông báo không nói được màn nào, và một lỗi
  không truy được nguồn là một lỗi không sửa được.

---

## P-18 · Màu thương hiệu là màu **nền**, không mặc nhiên là màu **chữ**

- **Root cause:** cùng một hằng số được dùng cho nền 10%, viền **và** chữ. Trên
  nền sáng, `#10B981` đọc ở **2.31:1** và `#F59E0B` ở **2.15:1** — WCAG AA cần
  **4.5:1**. Không ai thấy sai khi nhìn màn hình trong phòng.
- **Regression:** WTM-169 — 16 vi phạm trên 13 màn, gồm nhãn nút chính.
- **Test pattern:** chạy `textContrastGuideline` trên **mọi** màn, **cả hai
  locale**, **có dữ liệu**. Trước khi sửa, tính tỉ lệ ra số — đừng chọn màu bằng
  mắt.
- **Prevention:** mỗi màu năng lực có **một cặp song sinh đọc được** (bước -700)
  và `readableText(base)` để component dùng chung tự lấy đúng. Màu -500 **giữ
  nguyên** cho nền/viền/icon/biểu đồ — thương hiệu không đổi, chỉ chữ mới phải
  đọc được. `lightTextSecondary` chuyển gray-500 → **gray-600**: gray-500 pass
  trên nền trắng (4.83) và **fail trên mọi thẻ có nền nhạt** (4.39).

---

## P-19 · Nút bấm được nhưng **không ghi xuống đĩa**

- **Root cause:** trạng thái người dùng tạo ra chỉ sống trong controller.
  `OpportunityFeedController` giữ `reaction` hoàn hảo suốt vòng đời tiến trình
  và mất sạch khi app đóng — mọi lần "Lưu" / "Gạt bỏ" là vô nghĩa. Không có
  test nào bắt được vì **mọi test đều chạy trong một tiến trình**: state trong
  RAM luôn đúng khi bạn chưa bao giờ tắt máy.
- **Regression:** WTM-190 — vòng đời cơ hội trong Concept (`NEW → SAVED →
  IN_PROGRESS → DONE`) không thể đi quá `SAVED`, vì `SAVED` không sống qua lần
  mở app kế tiếp.
- **Test pattern:** dùng **SQLite thật trong file**, ghi → `db.close()` → **mở
  lại** → đọc. In-memory database *cũng* pass với code hỏng, nên nó không phải
  bằng chứng. Với UI: bấm đúng nút người dùng bấm rồi đọc thẳng repository —
  test "controller đã đổi state" chỉ chứng minh lại thứ đã đúng sẵn.
- **Prevention:** mỗi khi thêm một quyết định của người dùng, hỏi *"cái này ai
  ghi?"* trước khi hỏi *"cái này hiện thế nào?"*. Và **chỉ lưu thứ không tính
  lại được**: cơ hội là dữ liệu dẫn xuất (rule engine sinh lại mỗi lần đọc),
  chỉ *phán đoán của người bán* mới là sự thật cần lưu. Bảng
  `opportunities_table` rỗng nằm trong schema từ v1 chính là thứ khiến ai đọc
  schema cũng tưởng cơ hội đã được lưu — v10 **xoá** nó.

---

## P-20 · Slot nullable trong bundle ⇒ quên nối là **không** lỗi biên dịch

- **Root cause:** `TongtaiBackupRepositories` khai các repository mới là
  nullable "để call site cũ còn biên dịch được". Cái giá: quên điền một slot ở
  provider production **không** báo lỗi, và **toàn bộ test vẫn xanh** vì test
  tự dựng bundle của riêng nó — một bundle nhỏ hơn bundle thật.
- **Regression:** WTM-190 phát hiện điều này đã xảy ra **hai lần**: AI Business
  Profile (WTM-177) và Business Journey (WTM-185) đều có dataset `.ttbk`, đều
  có test round-trip xanh, và **cả hai chưa bao giờ được nối vào**
  `tongtaiBackupRepositoriesProvider`. Trên máy thật: backup không mang theo
  hồ sơ và hành trình; tệ hơn, restore gọi `businessProfile?.deleteAll()` —
  repository `null` thì **không xoá gì**, nên doanh nghiệp vừa khôi phục vẫn
  âm thầm giữ ngành hàng và kênh bán của **chủ cũ**, đúng thứ ADR-TON-018 cấm.
- **Test pattern:** hai lớp. (1) đọc bundle production qua `ProviderContainer`
  và `expect(..., isNotNull)` từng slot; (2) **quét source**: mọi field
  nullable trong bundle phải xuất hiện trong file provider — slot mới thêm mà
  quên nối sẽ fail ngay hôm viết, không đợi tới ngày người bán khôi phục.
  Xem `test/features/tongtai/export/backup_wiring_test.dart`.
- **Prevention:** **harness test phải bằng đúng production.** `reposFor()`
  trong suite restore nay điền đủ mọi slot. Một bundle test nhỏ hơn bundle thật
  là đang test một sản phẩm không ai chạy.

---

## P-21 · `scrollUntilVisible` dừng khi widget **được dựng**, không phải khi **nhìn thấy**

- **Root cause:** `scrollUntilVisible` trả về ngay lúc finder khớp. Danh sách
  lười dựng thêm một khoảng ngoài viewport, nên widget có thể **đã tồn tại mà
  vẫn nằm dưới mép màn hình**. `tester.tap` sau đó tính ra offset ngoài
  viewport, **chỉ cảnh báo**, và mọi assert phía sau chạy trên màn không ai
  chạm vào — đúng cái bẫy `test/support/tap_by_key.dart` sinh ra để chặn, chỉ
  là ở một nhánh khác.
- **Regression:** WTM-191 — nút "Đưa vào hành trình" nằm cuối màn chi tiết cơ
  hội; test bấm hụt, `expect` trên snackbar fail mà nguyên nhân thật lại là cú
  bấm.
- **Test pattern:** `tapByKey` nay gọi thêm `ensureVisible` sau
  `scrollUntilVisible` (có guard: màn không cuộn thì `ensureVisible` ném lỗi
  chứ không im lặng). Khi nội dung quá cao để cuộn tới trong test, dùng
  **viewport cao** như suite feed (`tester.view.physicalSize`) — khả năng với
  tới trên máy nhỏ là việc của `p0/accessibility_test.dart`, không phải của
  test hành vi.
- **Prevention:** không bao giờ `tester.tap` trực tiếp cho control có thể nằm
  ngoài màn. Và khi một test fail ở assert *sau* cú bấm, nghi cú bấm **trước**,
  đừng sửa assert.

---

## P-22 · SnackBar xếp hàng ⇒ câu trả lời của cú bấm thứ hai bị giấu

- **Root cause:** `showSnackBar` **xếp hàng**. Bấm lần hai, ứng dụng trả lời
  đúng, nhưng người dùng vẫn đang đọc thông báo của lần một — và kết luận là
  không có gì xảy ra.
- **Regression:** WTM-191 — "Đã có trong hành trình" không bao giờ hiện vì
  "Đã đưa vào hành trình" còn trên màn.
- **Test pattern:** test hai lần bấm liên tiếp và assert **thông báo thứ hai**,
  không chỉ assert dữ liệu không nhân đôi.
- **Prevention:** mọi thông báo phản hồi một hành động phải
  `hideCurrentSnackBar()` trước `showSnackBar()` — như màn feed đã làm từ đầu.
## P-23 · Suite governance viết cho một ngôn ngữ ⇒ mù với ngôn ngữ kia

- **Root cause:** `p0/localization_test.dart` quét **dấu tiếng Việt** vì nó
  được viết sau WTM-145 để dọn chuỗi Việt cứng. Một chuỗi **tiếng Anh** cứng
  trượt qua sạch sẽ — trong khi sản phẩm lấy **tiếng Việt làm chính** (D-8),
  nên chuỗi tiếng Anh mới đúng là thứ người bán thật nhìn thấy.
- **Regression:** WTM-194 — **~35 chuỗi trên 12 màn thật**: form mục tiêu, form
  khách hàng, form sản phẩm, trạng thái rỗng của Home và của feed cơ hội, tooltip
  sắp xếp. Đúng lỗi WTM-173 đã sửa, rộng gấp 35 lần, và **không có gì đỏ**.
- **Test pattern:** quét literal có **≥2 từ Latin** dưới `ui/`, **cộng thêm**
  các nhãn một từ đi thẳng vào `Text(...)`/nhãn hàng. Loại trừ phải **liệt kê
  tường minh và giải thích được**: `Workizen AI` là tên thương hiệu
  (ADR-TON-006), màn showcase là màn dev, và **nội dung `assert(...)` bị xoá
  trắng trước khi quét** — thông điệp assert là chữ cho lập trình viên.
- **Hệ quả bắt được luôn:** 6 test đang assert bằng **chữ hiển thị**
  (`find.text('Edit Goal')`) — đúng thứ quy ước repo cấm — và chúng đỏ ngay khi
  chuỗi được dịch. Sửa bằng cách **đổi sang Key mang theo *mode***
  (`goal-form-title-edit` / `goal-form-title-new`), không phải bằng cách cập
  nhật chữ trong test. Một test đọc nhãn sẽ hỏng mỗi lần nhãn đổi, và nó không
  kiểm tra hành vi — nó kiểm tra bản dịch.
- **Prevention:** hai điểm mù còn lại, biết trước còn hơn bị bất ngờ:
  **(1)** chuỗi có nội suy (`'Restock $n+ to clear'`) không khớp regex prose —
  WTM-194 phải tìm bằng tay; **(2)** nhãn **một từ** chỉ bị bắt khi đi thẳng
  vào `Text(`. Khi thêm chuỗi mới, hỏi *"cái này người bán đọc chứ?"* trước khi
  tin vào việc CI xanh.
## P-24 · Test ghim một **hằng số bịa** thì nó bảo vệ chính chỗ hỏng

- **Root cause:** `expect(restock.aiScore, 85)` · `expect(pipeline.top!.aiScore,
  92)` · `expect(plan.last.detailVi, contains('240%'))` · `High Risk when ROI <
  2.0`. Bốn test **xanh suốt nhiều tháng**, và cả bốn đều ghim một con số mà
  **không ai tính** — `aiScore` và `estimatedRoi` là hằng số theo loại luật.
  Test không phát hiện được khuyết tật vì nó **là** bản sao của khuyết tật.
- **Regression:** WTM-193 — hai trong ba kiểu sắp xếp của feed cho ra **cùng
  một thứ tự**, nhãn "High Risk" chỉ nói lại luật nào bắn, và bước cuối của
  action plan trích một tỉ lệ ROI cụ thể mà không ai tính.
- **Test pattern:** với số **dẫn xuất**, đừng ghim giá trị — ghim **quan hệ**:
  *hai cơ hội khác nhau phải cho điểm khác nhau* (fail nếu công thức trả hằng
  số) · *thiếu dữ liệu ⇒ `insufficient`, không phải 0* · *top của pipeline là
  cái được **hàm thật** chấm cao nhất*, tính ngay trong test thay vì viết tay.
  Test kiểu này **di chuyển theo công thức**, đó mới là điều mình muốn.
- **Prevention:** khi viết `expect(x, <một con số>)`, hỏi **ai tính ra con số
  đó**. Nếu câu trả lời là *"nó nằm sẵn trong code"*, test đang chép lại code
  chứ không kiểm tra code. Fixture cần một số cố định thì dùng constructor gắn
  **`@visibleForTesting`**, để cùng lối tắt đó không lọt vào `lib/`.

---

## P-25 · `GestureDetector` mặc định `deferToChild` ⇒ giữa nút là vùng chết

- **Root cause:** tab dưới cùng là `Icon` trên `Text` có khoảng cách ở giữa.
  `GestureDetector` mặc định `HitTestBehavior.deferToChild`, nên khoảng trống
  đó — **kể cả tâm của tab** — không nhận chạm. Người bán nhắm vào giữa tab thì
  bấm trúng hư không.
- **Regression:** WTM-192 — lộ ra khi test bấm tab bằng Key: `tester.tap` tính
  ra tâm widget, và tâm chính là chỗ chết. Suốt thời gian trước đó không ai
  thấy, vì người thật hay bấm trúng icon.
- **Test pattern:** bấm bằng **Key** (tức bấm vào **tâm**) chứ đừng bấm vào
  `find.text(...)` của nhãn — bấm nhãn luôn trúng, nên nó **giấu** vùng chết đi.
- **Prevention:** mọi vùng chạm ghép từ nhiều widget rời phải khai
  `behavior: HitTestBehavior.opaque`. Cùng họ với P-17: thứ không nằm trong
  suite thì không phải thứ đã pass.

---

## P-26 · Đổi nhãn dài hơn làm vỡ layout mà không ai đổi layout

- **Root cause:** 5 tab trong một `Row` **không có `Expanded`**, mỗi tab tự lấy
  kích thước tự nhiên. Đổi `More` → `Cơ hội`/`Opportunity` là **tràn 50 px**
  trên máy hẹp. Không dòng layout nào bị sửa; chỉ một chuỗi dài hơn.
- **Regression:** WTM-192. `p0/nav_availability_test.dart` bắt được vì nó dựng
  shell ở **kích thước máy thật**, không phải viewport mặc định 800×600 của
  test.
- **Test pattern:** governance suite phải dựng ở **kích thước thiết bị thật**
  (và ở cỡ chữ 2.0×). Viewport mặc định của `flutter_test` rộng hơn điện thoại
  nên nó **giấu** tràn ngang.
- **Prevention:** hàng ngang chia đều thì phải `Expanded`; nhãn trong ô hẹp
  phải `maxLines: 1` + `TextOverflow.ellipsis`. Và: **đổi chuỗi cũng là đổi
  layout** — l10n không phải thao tác an toàn.

---

## P-27 · Hai bên cùng tự nhất quán vẫn nói hai sự thật — test từng bên **không bao giờ** thấy

- **Root cause:** một khái niệm được tính ở hai nơi bằng hai luật. Mỗi nơi có
  test riêng, mỗi nơi đều **đúng với chính nó**, và không ai hỏi câu duy nhất
  quan trọng: *hai bên có nói cùng một điều không?*
- **Regression:** ba lần trong một ngày.
  · **WTM-196** doanh thu: Home đếm **đơn hàng**, Finance đếm **giao dịch nhập
  tay** ⇒ người bán có 10 đơn mở Finance thấy **₫0**.
  · **WTM-200a** tiến độ mục tiêu: Goals **tính lại từ đơn**, Home đọc
  **`achievedAmount` đã lưu** ⇒ 60% và 40% cho cùng một mục tiêu cùng một ngày.
  · **WTM-200b** "khách im lặng": Consumer xét theo **nhịp mua riêng** của khách,
  Opportunity dùng **phẳng 30 ngày** ⇒ báo động giả với khách mua thưa và bỏ sót
  khách mua dày.
- **Test pattern:** một suite riêng **so hai bên với nhau**, không kiểm từng bên.
  Xem `p0/single_source_of_truth_test.dart`. Với luật có tham số (nhịp mua),
  quét **một dải** giá trị chứ đừng chọn hai ca đẹp — hai ca đẹp là cách bỏ sót
  chỗ hai bên bắt đầu lệch.
- **Prevention:** khi thêm một khái niệm nghiệp vụ, hỏi **ai sở hữu nó**. Nếu
  câu trả lời là *"chỗ nào cần thì tự tính"*, đó là hai sự thật đang được tạo ra.
  Một hằng số cấu hình được (`lapsedCustomerDays = 30`) cho một khái niệm **đã
  có chủ** là dấu hiệu sớm nhất — nó trông như một tuỳ chọn, thực chất là một
  luật thứ hai.

---

## P-28 · Tên cột trong schema **không đáng tin** — phải đọc repository

- **Root cause:** schema ra đời **trước** domain, nên nhiều cột mang tên của một
  thiết kế chưa bao giờ tồn tại. Audit theo tên cột ⇒ phân loại sai.
- **Regression:** WTM-202, tôi phân loại sai **hai lần trong một audit**:
  · `totalStock` — nghe như tổng của `stockByWarehouse`; thực ra là chỗ lưu
  `Product.quantity`, còn `stockByWarehouse` **không ai dùng**;
  · `revenueImpact` — nghe như tác động doanh thu tính ra được; thực ra lưu
  `BusinessGoal.targetAmount`, tức **mục tiêu do người bán đặt**.
  Cả hai suýt sinh ra story gỡ nhầm một cột Source.
- **Test pattern:** governance test liệt kê cột dẫn xuất **kèm lý do nêu tên
  luật sở hữu nó** (`p0/derived_data_governance_test.dart`), và bản thân danh
  sách cũng được test — một suite có thể vô hiệu hoá bằng cách xoá một dòng
  trong danh sách thì không phải governance.
- **Prevention:** với mỗi cột, đọc **repository ghi gì vào đó và đọc ra làm
  gì**. `grep 'columnName:'` ở chỗ ghi và `row.columnName` ở chỗ đọc — hai dòng
  đó nói sự thật, tên cột thì không.

---

## P-29 · Governance đo **chất lượng** màn hình, không đo **tính tới-được**

- **Root cause:** mọi suite governance đều nhận đầu vào là *danh sách file* rồi
  kiểm chất lượng từng file — l10n, a11y, overflow, error seam, stable ID.
  Không suite nào hỏi câu đứng trước tất cả: *"người bán có mở được màn này
  không?"*. Một màn mồ côi vì thế **vượt qua mọi cổng** và còn được đánh bóng
  liên tục.
- **Regression:** WTM-218 — `TongtaiSupplierSearchScreen` (~600 dòng, L3) chưa
  bao giờ có caller production kể từ commit bootstrap, trong khi **sáu** lượt
  governance (WTM-146/147/148/168/171/194) đã sửa chính file đó. Cùng phiên,
  WTM-217 tìm ra màn showcase tương tự — nó còn *mua hai ngoại lệ file* trong
  lưới l10n để tồn tại. Hai màn, cùng một chỗ mù.
- **Test pattern:** scan ở mức **file**, không phải class — hỏi *"có file nào
  khác trong `lib/` import file màn này không?"* (`p0/nav_availability_test
  .dart` → `intentionallyUnreached`). Hỏi ở mức class sẽ báo nhầm mẫu
  *route/host wrapper nằm cùng file* (Unified Search). Danh sách ngoại lệ phải
  **kèm lý do đọc được** và có test thứ hai bắt ngoại lệ đã hết hạn — một màn
  được nối lại mà quên gỡ ngoại lệ là lời nói dối tiếp theo.
- **Prevention:** thêm màn mới ⇒ câu hỏi đầu tiên là *đường vào từ đâu*, trước
  cả l10n/a11y. Một màn không ai tới được thì mọi chỉ số chất lượng của nó đều
  bằng 0 dù suite có xanh.

---

## P-30 · Tới-được phải chứng minh từ **gốc**, không phải một bước

- **Root cause:** P-29 hỏi *"có file nào import file màn này không?"* — một
  bước, không có gốc. Hai màn mồ côi import lẫn nhau vẫn qua được, và một màn
  chỉ tới được qua chuỗi mà không ai đi nổi cũng vậy. Câu hỏi đúng là câu người
  bán hỏi: **từ chỗ tôi mở app, tôi tới đó bằng cách nào?**
- **Regression:** luật Founder 2026-08-02 sau WTM-218 — *mọi capability L2+
  phải chứng minh một User Journey dẫn tới nó, hoặc mang nhãn Future Capability
  / Intentionally Hidden kèm lý do*.
- **Test pattern:** `p0/journey_reachability_test.dart` — đồ thị điều hướng
  **suy từ code**, BFS từ shell/Home. Ba điều đáng nhớ khi viết:
  · **Bỏ comment trước khi suy cạnh.** Một dòng doc *"mở TongtaiFooScreen."*
  tạo **cạnh ma** — đồ thị nói tới được, trong khi thứ duy nhất dẫn tới đó là
  một câu văn. Suite chống nói dối thì phải nhìn code, không nhìn lời kể.
  · **Loại file barrel** (`tongtai.dart`): nó re-export tất cả, nối mọi thứ
  với mọi thứ và biến bài kiểm thành vô nghĩa.
  · **Suy, đừng khai tay.** 37 đường đi khai tay sẽ mục ở lần đổi điều hướng
  đầu tiên, mà một bảng khai mục **tệ hơn không có** — nó nói dối người đọc
  sau. Chỉ ngoại lệ mới khai, và ngoại lệ phải có nhãn + lý do đủ dài để hiểu.
- **Prevention:** màn mới buộc phải khai mức L trong suite ⇒ việc khai buộc
  phải trả lời "đường vào từ đâu" **trước** khi bàn tới l10n/a11y.

---

## P-31 · Thêm một trường vào model mới xong **nửa dưới** — đường GHI vẫn viết bằng mô hình cũ

- **Root cause:** thêm một khái niệm mới (`ProductKind`, `paymentStatus`,
  `quantity` nullable) thường được đo bằng *"miền đã hiểu chưa"*: enum có, luật
  dẫn xuất có, màn đọc đúng, test xanh. Nhưng khái niệm chỉ **thật sự tồn tại**
  khi đường **ghi** cũng mang nó — form, codec, `withId`, mọi chỗ dựng lại một
  bản ghi. Nơi đó thường có sẵn một giá trị mặc định (`?? 0`, tham số bỏ trống)
  đủ hợp lý để không ai nhìn lại, và nó **dựng lại nguyên vẹn lời nói dối** vừa
  gỡ.
- **Regression:** WTM-233 — WTM-227 nới `quantity` thành nullable và dạy cả
  Inventory/Rule Engine im lặng với hàng không tồn kho, nhưng
  `ProductFormData.toProduct()` không truyền `kind` và vẫn ép
  `_tryParseInt(...) ?? 0`. Chỉ cần **mở một sản phẩm số ra sửa tên rồi lưu**
  là nó thành hàng vật lý còn 0 cái ⇒ "Hết hàng" ⇒ Rule Engine sinh **cơ hội
  nhập hàng cho một phần mềm** — đúng cảnh ADR-TON-023 sinh ra để xoá. Cùng lần
  đó: `Product.withId` (móc gieo dữ liệu mẫu) quên `kind`, và
  `int?.toString()` in bốn chữ `null` vào ô nhập lẫn lịch sử sửa đổi vĩnh viễn.
  Họ hàng: WTM-211 (`paymentStatus` ship không kèm codec ⇒ restore XOÁ công
  nợ), WTM-230 (suýt lặp với `BusinessInput`).
- **Test pattern:** với **mỗi** trường mới, một test đi **trọn vòng ghi**:
  `fromProduct → copyWith(đổi một thứ khác) → applyEdit` rồi khẳng định trường
  mới **không đổi**. Đây là bài kiểm mà mọi test "miền hiểu đúng" đều bỏ sót,
  vì chúng dựng object bằng constructor chứ không đi qua form. Kèm một test
  cho mỗi **đường sao chép** (`withId`, codec `.ttbk`, CSV).
- **Prevention:** thêm trường ⇒ liệt kê **mọi** hàm dựng lại một bản ghi
  (`grep` tên class + `(`), không chỉ chỗ đọc. Trường nullable mới ⇒ soát luôn
  `.toString()` trên nó: `null` in ra là chữ, và chữ đó đi thẳng vào ô nhập
  của người bán và vào lịch sử không xoá được.

---

## P-34 · Hai taxonomy cho một khái niệm — nhãn hiển thị đi thẳng xuống ổ đĩa

- **Root cause:** một trường phân loại tự do (`Product.category`, trước đó
  `Customer.segments`) có **nhiều nguồn ghi**, mỗi nguồn dùng một hệ đặt tên:
  bộ nhập XLSX ghi nhãn tiếng Việt (`"Điện tử"`), bộ sinh lịch sử ghi nhãn
  tiếng Anh (`"Electronics"`), catalog mẫu ghi nhãn Anh khác (`"Home Goods"`).
  Màn hình in **nguyên văn** thứ nó nhận, nên chip lọc hiện `"Accessories"`
  đứng cạnh `"Điện tử"` — hai hệ danh mục song song, một cái lọt UI. Đây đúng
  hình dạng [[P-27]]/[[P-28]] (một khái niệm, hai chủ) cộng vi phạm ADR-TON-007
  (UI một locale) — và nó **không** nằm ở cái nhãn hiện trên màn, mà ở **dữ liệu
  ghi xuống**.
- **Regression:** WTM-393 — audit thiết bị WTM-392 (Nokia 6.1, seed sạch) thấy
  chip `"Electronics"/"Accessories"` và sản phẩm `SKU-HO-108 • Home` trong màn
  Kho. `historical_data_generator` gieo ~14 sản phẩm danh mục tiếng Anh cạnh 100
  sản phẩm XLSX danh mục tiếng Việt; `kSampleProducts` và `kSampleCustomerOrders`
  cũng mang nhãn Anh. 2690 test xanh **không thấy** vì mọi test khẳng định đúng
  cái chuỗi thô đang hỏng — *"UI hiện đúng chữ"* không phải *"chữ đúng"*. Cùng
  họ: WTM-381 (`CustomerSegment`) — cùng bệnh, cùng thuốc.
- **Test pattern:** governance ở **tầng dữ liệu**, không ở tầng UI. Với mọi
  nguồn seed (`HistoricalDataGenerator` mọi `BusinessProfile`, `kSampleProducts`,
  `kSampleCustomerOrders`) khẳng định `category` là **mã canonical chính xác**
  (`ProductCategory.values.any((c) => c.code == raw)`). Seed lại một **nhãn**
  (`"Electronics"`) ⇒ đỏ. Khẳng định `parse()` chữa mọi biến thể cũ đã thật sự
  nằm trên máy (`"Home"`, `"Home Goods"`, `"Smart Home"`, nhãn VI) và chuỗi tự
  đặt của người bán vẫn giữ nguyên văn. Xem
  `test/features/tongtai/commerce/product_category_governance_test.dart`.
- **Prevention:** một khái niệm phân loại = **một enum canonical** (mã lưu, nhãn
  sinh lúc hiển thị, `parse` chữa dữ liệu cũ) — đúng khuôn `CustomerSegment`
  (WTM-381). Ghi = `normalise(raw)`, hiện = `display(raw, lang)`, gom/lọc =
  `normalise` cả hai vế. Cấm test khoá bằng chuỗi nhãn thô; hỏi *"nếu ai seed
  lại nhãn tiếng Anh, test còn xanh không?"* — nếu còn, test đang canh sai chỗ.

---

## P-35 · Đo jank Flutter bằng công cụ Android mặc định — số 0 giả và trung bình giả

- **Root cause:** công cụ đo jank "hiển nhiên" là `dumpsys gfxinfo <pkg>`, nhưng
  Flutter vẽ qua engine riêng vào một `SurfaceView` và **không** đi qua
  `HardwareRenderer` mà gfxinfo đọc ⇒ nó luôn báo `Total frames rendered: 0`.
  *"0 khung ⇒ 0 jank"* là một **PASS giả** — cùng họ với PASS giả TalkBack (đo
  overlay của screen-reader chứ không đo app). Cạm bẫy thứ hai đến ngay sau khi
  chuyển sang `dumpsys SurfaceFlinger --latency`: bộ đệm ~128 khung gồm cả
  **khoảng nghỉ** giữa các cú vuốt; Flutter **đúng** khi không vẽ lúc màn tĩnh,
  nên mỗi khoảng nghỉ 100–900ms bị tính thành "khung rớt" ⇒ **JANK giả**
  (mean 45ms, worst 933ms) — ngược dấu với PASS giả nhưng cùng gốc: đo nhầm thứ.
- **Regression:** WTM-277 — đo scroll jank trên Nokia 6.1 (máy tầm thấp mốc
  tham chiếu). gfxinfo báo 0 khung (suýt kết luận "không đo được"); fling rời rạc
  báo 5.6% "dropped", worst 933ms (jank giả từ khoảng nghỉ + một mẫu biên âm sau
  `--latency-clear` làm hỏng cả trung bình). Sự thật sau khi tách chuyển-động
  khỏi nghỉ: Kho (114 sp) và Khách hàng (82 kh) đều **0 khung rớt, worst ~17ms,
  60fps bền**. Không có bug sản phẩm — bug nằm ở **phép đo**.
- **Test / method pattern:** (1) layer đúng là `SurfaceView - <pkg>/<Activity>#0`
  — xác nhận bằng cột 2 (actualPresentTime) khác 0; layer `AppWindowToken{…}` và
  `<pkg>/<Activity>` trả toàn số 0. (2) `--latency-clear` → **một cú kéo liên tục**
  (finger-down, `input swipe x y x y 1500`) chứ không fling rời rạc → `--latency`.
  (3) parse cột 2: bỏ `d<=0` (mẫu biên sau clear) và `d>100ms` (khoảng nghỉ,
  không phải jank); chỉ đếm jank `>25ms` / rớt `>33ms` trên khung **đang chuyển
  động**. (4) báo cáo **đếm khung rớt + worst interval**, không assert mili-giây
  (P-16). Bằng chứng mẫu: `~/Desktop/WTM-277-Device-Evidence-2026-08-13/`.
- **Prevention:** đo hiệu năng thiết bị của app Flutter ⇒ **không** dùng gfxinfo
  cho jank (chỉ đúng với app View thuần); dùng SurfaceFlinger latency trên layer
  `SurfaceView` + lọc khoảng nghỉ. Hỏi *"0 khung / mean 45ms là app mượt, app
  đứng hình, hay tôi đo nhầm layer?"* trước khi ghi PASS/FAIL. Cùng bài học
  [[P-16]] và họ TalkBack: một phép đo có thể **xanh mà vô nghĩa** nếu đo nhầm
  bề mặt (overlay thay vì app · nghỉ thay vì kéo).

---

## P-36 · Đọc cây semantics Flutter bằng `flutter run`+`S` (hoặc uiautomator) — cây rỗng giả

- **Root cause:** cách "hiển nhiên" để kiểm thứ tự đọc / nhãn của TalkBack là
  `flutter run [--profile]` rồi bấm `S` (`debugDumpSemanticsTreeInTraversalOrder`).
  Nhưng Flutter **chỉ dựng cây semantics khi nền tảng yêu cầu** — tức khi một
  screen-reader (TalkBack/VoiceOver) đang chạy. Không bật thì `S` trả thẳng
  *"Semantics not generated… try turning on an assistive technology"* ⇒ trông y
  như *"màn không có gì để đọc"*, một **cây rỗng giả**. Mà bật TalkBack để lấp
  chỗ đó thì lại **cướp tiền cảnh + phá chính phép đo** (đúng PASS giả 2026-08-07).
  Cùng họ [[P-35]] (gfxinfo=0) và [[P-34]]: Flutter **không đi qua đường Android
  tiêu chuẩn**, nên dụng cụ Android tiêu chuẩn nói dối **im lặng** — `uiautomator
  dump` một app Flutter trả `text=""` ở **mọi** node (chữ nằm trong
  `content-desc`), grep `text=` ra rỗng = một FAIL giả sạch sẽ.
- **Regression:** WTM-277 Option C — live `S` dump trên Nokia 6.1 trả "Semantics
  not generated for _ReusableRenderView"; `uiautomator` cũng mù. Cả hai đường
  trên thiết bị đều là ngõ cụt **nếu không** bật TalkBack — và bật thì hỏng đo.
- **Test / method pattern:** đọc cây semantics **trong tiến trình** bằng
  `tester.ensureSemantics()` (widget test) — nó dựng đúng cây TalkBack sẽ đọc,
  **không** cần bật dịch vụ trợ năng nào, **không** cướp tiền cảnh. Duyệt theo
  `DebugSemanticsDumpOrder.traversalOrder` (thứ tự TalkBack đọc), hoặc đọc
  `flagsCollection` trên từng `SemanticsData`. Pump ở đúng kích thước máy
  (Nokia 411×823dp) nếu cần trung thực với thiết bị. Guard đã khoá **vai trò máy
  chứng minh được** mà bộ guideline WTM-168 không kiểm:
  `p0/semantics_route_header_test.dart` — mọi màn nội dung có node
  `isHeader`+`namesRoute` (thông báo tên màn + nhảy theo tiêu đề), màn tìm kiếm
  có `isTextField`. Nhãn không-rỗng đã khoá bởi `labeledTapTargetGuideline`
  (WTM-168). Bằng chứng dump: `~/Desktop/WTM-277-Semantics-Audit-2026-08-13/`.
- **Prevention:** audit thứ tự đọc / nhãn của app Flutter ⇒ dùng
  `ensureSemantics()` trong test, **không** `flutter run`+`S` (cần TalkBack) và
  **không** `uiautomator` (đọc rỗng). Ranh giới phải giữ đúng tên (bài học
  [[P-35]] họ TalkBack + WTM-384 "bản ghi tự xưng là thứ nó không phải"): máy
  chứng minh được **vai trò · thứ tự duyệt · nhãn có/rỗng · focus/48dp**;
  **đọc lên nghe có xuôi không · rườm rà · đủ ngữ cảnh khi không nhìn** vẫn là
  **tai người** (Founder/device gate). Đừng gọi audit cây semantics là "nghiệm
  thu TalkBack hoàn chỉnh".

---

## P-37 · Dựng lại một màn ⇒ **cánh cửa đổi khoá**, và guard chết theo — im lặng

- **Root cause:** governance của repo này neo vào **khoá widget** (`home-open-finance`,
  `home-tile-journey`). Khi một màn được dựng lại, phần tử mang khoá ấy có thể
  **biến mất trong khi lời hứa vẫn còn** — Tài chính vẫn cách Home một cú chạm,
  chỉ là qua thẻ năng lực thay vì nút chữ. Lúc ấy suite đỏ, và phản xạ sai là
  **xoá mục khỏi danh sách guard cho xanh**. Làm thế là bỏ đúng phép kiểm đang
  canh *"đừng chôn năng lực vào hộp More"* — mất một cách âm thầm, vì sau đó
  không có gì đỏ nữa.
  Chiều ngược lại cũng có: bỏ ô đếm **Hành trình** khỏi Home làm gãy cặp
  *Summary Count == Visible Records* của mục tiêu — và cách sửa đúng là **trả ô
  đếm về**, không phải bỏ cặp khỏi hợp đồng ADR-TON-015.
- **Regression:** WTM-404 (dựng Home theo concept-1). Ba guard đỏ cùng lúc:
  `nav_availability_test` (`home-open-finance` mất), `count_list_contract_test`
  (`home-tile-journey` mất), `localization_test` (4 khoá chuỗi thành mồ côi).
  Cả ba **đều đúng** — không cái nào là nhiễu.
- **Test / method pattern:** khi guard đỏ vì dựng lại giao diện, hỏi đúng **hai**
  câu, theo thứ tự:
  1. *Lời hứa còn không?* — còn ⇒ **đổi khoá trong test**, giữ nguyên câu hỏi,
     ghi chú vì sao cửa đổi chỗ (xem chú thích `home-tile-finance` trong
     `nav_availability_test.dart`).
  2. *Lời hứa mất rồi?* — thì **trả nó về**, đừng gỡ guard. Ô "Hành trình" quay
     lại làm thẻ thứ năm của hàng cuộn (concept vẽ bốn) chính vì lý do này.
  ⛔ Không có câu thứ ba. "Xoá dòng ấy khỏi danh sách" chỉ đúng khi năng lực
  thật sự rời sản phẩm — và khi đó phải có ADR, không phải một dòng diff.
  Chuỗi mồ côi thì ngược lại: `localization_test` bắt **key không ai dùng**, và
  cách sửa đúng là **xoá key** (cả 3 chỗ), không phải nhét lại một `Text` chết.
- **Prevention:** trước khi dựng lại một màn, `grep` khoá của nó trong `test/`
  để biết mình sắp đụng bao nhiêu guard. Sau khi dựng xong, chạy **`p0/` trước
  tiên** — nó là bộ hỏi *"lời hứa còn không"*, và trả lời nó khi còn nhớ vì sao
  vừa đổi rẻ hơn nhiều so với ba tuần sau.

## P-38 · `git checkout <file>` giữa lúc đột biến — bản vá chưa `git add` biến mất im lặng

- **Root cause:** vòng kiểm đột biến chạy `sửa lib/ → test → git checkout lib/…`
  để khôi phục. `git checkout <path>` khôi phục từ **INDEX**, không phải từ bản
  làm việc. Nếu sau lần `git add` cuối ta còn sửa thêm, lần khôi phục ấy **xoá
  luôn phần sửa thật** — và nó xoá *lặng*: analyzer xanh, suite xanh, vì bản cũ
  vốn cũng xanh. Cùng họ [[P-33]] (đổi keystore ⇒ mất dữ liệu) — một thao tác
  dọn dẹp nuốt mất thứ không ai đang nhìn.
- **Regression:** WTM-404. Bản vá "nhãn mức đổi cho phép **hai dòng**" (do máy
  thật bắt: *"+17% so với tháng tr…"* nuốt mất cái mốc) bị hai lần đột biến sau
  đó khôi phục đè. Không test nào đỏ — chính vì cái nó sửa là thứ **chỉ nhìn
  thấy trên thiết bị**.
- **Test / method pattern:** đột biến phải **stash-an-toàn**, không `checkout`:
  chép file ra `$TMPDIR` trước khi sửa và chép ngược lại, hoặc `git stash` toàn
  bộ trước vòng đột biến. Và sau mỗi vòng, **grep lại dấu hiệu của từng bản vá
  do máy thật bắt** — chúng là loại duy nhất suite không canh hộ:
  `grep -n "maxLines: 2," lib/…/tt_metric_card.dart`.
- **Prevention:** `git add -A` **ngay trước** vòng đột biến, để index == bản làm
  việc và `checkout` trở nên vô hại. Nếu quên: coi mọi bản vá "sửa sau lần add
  cuối" là đã mất cho tới khi grep chứng minh ngược lại.

## P-39 · `assert` canh đường GHI, còn giá trị hỏng đi vào từ đường ĐỌC

- **Root cause:** một giá trị **sống lâu hơn bản cài đặt** (SharedPreferences,
  DB, file cấu hình) được ghi hợp lệ hôm nay và đọc lại ở một bản có **luật
  khác**. `assert` đặt ở hàm ghi không canh được gì: nó không chạy khi đọc, và
  ở bản **release** nó bị gỡ bỏ hoàn toàn. Đảo chiều của [[P-31]] (*"thêm trường
  xong nửa dưới — đường GHI vẫn viết bằng mô hình cũ"*).
- **Regression:** WTM-405/406, Nokia 6.1, 2026-08-13. Cài bản **6 tab**, chạm
  "Thêm" (index 5), rồi cài đè một bản dựng **cũ hơn chỉ có 5 tab**. App mở lên
  là **màn đỏ**:
  `indexed_stack.dart: Failed assertion: 'index >= 0 && index < children.length'`.
  `run-as … cat shared_prefs/FlutterSharedPreferences.xml` xác nhận
  `tongtai_selected_tab" value="5"`. Sập **trước khi** người dùng chạm được gì —
  không cú chạm nào cứu được. Người gặp: **người đã dùng app từ trước**, tức
  nhóm ít bị test chạm tới nhất và là nhóm duy nhất có giá trị cũ trong máy.
- **Test / method pattern:** kiểm ở **đường đọc**, với giá trị bền nằm sẵn:
  `SharedPreferences.setMockInitialValues({...})` rồi đọc provider —
  `tongtai_tab_persistence_test.dart`. Bắt buộc **hai chiều**, vì mỗi chiều bắt
  một cách hỏng khác nhau: (a) giá trị ngoài khoảng ⇒ về mặc định; (b) **mọi**
  giá trị hợp lệ ⇒ giữ nguyên. Thiếu (b) thì `return _defaultTab;` vô điều kiện
  cũng xanh — và app **quên** tab đang xem ở mọi lần mở, một lỗi im lặng thay
  cho một lỗi ồn ào. Cả hai chiều đã chứng minh bằng đột biến.
- **Prevention:** với mọi giá trị bền dùng làm **chỉ số / khoá / enum**, kẹp
  hoặc `parse` ở **đường đọc** và trả về mặc định khi lạ — cùng luật ADR-TON-018
  đặt cho decoder `.ttbk` (*"từ chối thay vì đoán"*). Coi `assert` là ghi chú cho
  lập trình viên, **không** phải một cổng: nó không tồn tại ở bản người dùng chạy.


### ⚠️ Tái phát 2026-08-15 — WTM-418, ảnh sản phẩm

Cùng hình dạng, khác miền. WTM-414 gỡ **đường ghi** URL ảnh demo (xoá tệp sinh
URL, xoá đoạn seeder ghi vào `Product.imageUrl`) và coi thế là xong.

Nhưng bộ dữ liệu mẫu XLSX có sẵn cột `image_url` điền `picsum.photos/seed/…`,
máy Founder đã nạp từ 2026-08-09, nên giá trị hỏng **nằm sẵn trong cơ sở dữ
liệu** và đi vào bằng **đường đọc**. Danh sách Kho hiện ảnh phong cảnh cho từng
món hàng — **2845 test xanh, analyzer sạch, không gì kêu**.

Bài học thêm vào P-39: *"đã gỡ chỗ sinh ra nó"* **không** đồng nghĩa với *"nó
không còn"*. Câu hỏi đúng là **"giá trị này đã kịp nằm ở đâu chưa"** — và nếu
rồi, phải chặn ở đường đọc (hoặc di trú dữ liệu), vì đường ghi không chạm được
vào quá khứ.

## P-40 · `SafeArea` trả lời câu "thanh nav ở đâu", KHÔNG trả lời "vuốt ở đâu thì tới app"

- **Root cause:** Android đời mới có **hai** vùng inset ở đáy. `viewPadding` (=
  `navigationBars`) là chiều cao **thanh điều hướng**; `systemGestureInsets` (=
  `mandatorySystemGestures`) là dải hệ điều hành **cướp thao tác vuốt**. Ở chế độ
  **ba nút** hai con số trùng nhau nên `SafeArea` che đủ; ở chế độ **cử chỉ**
  chúng lệch, và phần lệch vẫn nhận widget. Trong dải ấy **chạm vẫn tới app**,
  chỉ **vuốt** bị nuốt — nên mọi phép kiểm tap-target vẫn xanh.
  Cùng họ [[P-35]] / [[P-36]]: một API đứng cạnh thứ mình cần, trả về dữ liệu
  **trông giống** thứ mình cần, và sai **im lặng**.
- **Regression:** WTM-403. Đo trên S24 Ultra (`R5CX62RCBNB`):

  | chế độ | `navigationBars` | `mandatorySystemGestures` | hở |
  |---|---|---|---|
  | ba nút (2026-08-14) | 135px | 135px | 0 |
  | cử chỉ (2026-08-13) | 42px | 135px | **93px** |

  Màn Cơ hội dùng `Dismissible` làm thao tác chính và chỉ bọc `SafeArea`. Đo
  trong test: hàng cuối kéo xuống tới **y=722** trong khi dải cử chỉ bắt đầu ở
  **645** ⇒ **77dp chồng lấn**.
  ⚠️ Vé gốc chép số 42px vào mô tả **không kèm điều kiện**, nên nó đọc như *"S24
  luôn có khoảng hở"* — sai. Rủi ro không thuộc về **máy**, nó thuộc về **chế độ
  điều hướng người dùng bật**.
- **Test / method pattern:** `p0/swipe_gesture_inset_test.dart` — đặt
  `tester.view.systemGestureInsets` **lớn hơn** `viewPadding`, dựng màn, cuộn tới
  đáy, rồi khẳng định **mép DƯỚI** của mọi `Dismissible` nằm trên dải.
  ⛔ **Đo mép dưới, không đo mép trên.** Bản đầu của phép kiểm này so mép trên và
  **xanh cả trên mã chưa sửa**: hàng cao ~100dp có mép trên ngoài dải trong khi
  nửa dưới đã nằm trong — và ngón tay đặt vào nửa dưới ấy mới là cú vuốt bị nuốt.
  Đột biến (trả đệm về `TtSpace.x4`) chứng minh đỏ.
  Mặc định của widget test là `systemGestureInsets = 0`, nên **không màn nào từng
  được dựng ở cấu hình lộ lỗi** — phải đặt tay.
- **⚠️ Cơ chế không có cổng thì hết hạn lặng lẽ.** Phiên Hub (2026-08-14) báo về:
  ở đó cách xử lý vùng cử chỉ **đã có sẵn và đúng**, lý lẽ ghi rõ trong tài liệu,
  mà **13 ca test không ca nào chạm `systemGestureInsets`** — không gì chứng minh
  nó còn chạy. Nên `swipe_gesture_inset_test.dart` có **hai** phần: một ca **đo**
  màn đang có, và một **scan** bắt mọi bề mặt vuốt mới chưa được canh.
  ⚠️ Scan phải loại `barrierDismissible:` / `isDismissible:` — đó là **tham số hộp
  thoại**, không phải widget. Chính phép grep lẫn hai thứ ấy khiến phiên Hub báo
  *"7 bề mặt vuốt"* khi thực tế là **0**.
- **Prevention:** danh sách có **vuốt** (`Dismissible`, swipe-to-action) phải
  chừa đáy theo `systemGestureInsets`, không theo `SafeArea` là xong. Danh sách
  chỉ chạm thì `SafeArea` đủ — thêm 93px đệm vô cớ là một khoảng trống không ai
  giải thích được. Và đừng đổi `navigation_mode` trên máy Founder để đo: chính
  thao tác ấy đã làm hỏng một đợt đo trước (cửa sổ không tin được ghi trong
  WTM-403).

## P-41 · Một ngưỡng khai ở BỐN chỗ, chỉ một chỗ có thật

- **Root cause:** cùng một ngưỡng nghiệp vụ được viết ra nhiều lần bằng nhiều
  hình thức — một hằng cấu hình, một tham số ở lớp khác, một điều kiện lọc, và
  một con số **viết cứng trong câu chữ**. Chỉ một trong số đó thật sự điều khiển
  hành vi; những cái còn lại vẫn **đọc như luật** với bất kỳ ai mở tệp ra xem.
  Nguy hiểm hơn P-27/P-28 (*hai chủ*) ở chỗ: các bản sao đây **không chạy**, nên
  không có gì lệch để ai phát hiện — chúng chỉ dạy sai người đọc.
- **Regression:** WTM-411, `commerce_opportunity_service.dart`:

  | Nơi | Nói gì | Thực tế |
  |---|---|---|
  | `deadStockDays = 90` + doc *"bao lâu không bán được coi là hàng nằm"* | 90 ngày | **không dòng mã nào đọc** |
  | `CommerceProfitContext.window` | 30 ngày | ✅ ngưỡng thật |
  | `if (now.difference(p.updatedAt).inDays.abs() >= 0)` | trông như lọc ngày | `.abs()` luôn ≥ 0 ⇒ **lọc rỗng** |
  | chuỗi `'30 ngày qua không bán được'` (và 2 câu khác) | 30 | số cứng, khớp **do may** |

  Chính `docs/01-PRODUCT/concept-1/ANALYSIS.md` cũng đọc nhầm: nó ghi
  `deadStockDays` như một ngưỡng đang dùng. Một hằng số không ai đọc còn tệ hơn
  không có — nó **trông như chỗ để chỉnh**, và người chỉnh sẽ không thấy gì đổi.
- **Test / method pattern:** đừng kiểm "hằng số có đúng giá trị không" — kiểm
  **hành vi ở ranh giới**, và **nối câu chữ vào chính con số điều khiển hành vi**
  (`'$windowDays ngày'`, không phải `'30 ngày'`). Khi câu chữ nội suy từ nguồn
  thật, một bản sao chết sẽ lộ ra ngay lần đầu ai đổi ngưỡng.
  `SlowMovingCapital` nhận `windowDays` **từ phía gọi** và mang nó theo, cố tình
  **không** tự đặt ngưỡng — một lớp mới tự đặt ngưỡng là chủ thứ năm.
- **Prevention:** trước khi thêm một hằng cấu hình, `grep` xem có ai đọc nó
  không. Trước khi tin một hằng, `grep` xem nó có được đọc không — kể cả khi nó
  có tên đẹp và một dòng tài liệu. Và điều kiện lọc phải **đọc được thành câu**:
  `.abs() >= 0` không đọc thành câu nào cả, đó là dấu hiệu.

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
| loading | `<screen>-loading` | `consumer-loading` |
| lỗi tải dữ liệu | `<screen>-error` (+ `-retry`, `-code`, `-detail`) | `consumer-error-retry` |
| dữ liệu cũ (refresh hỏng) | `<screen>-stale` | `consumer-stale` |
| domain từ chối kết luận | `<screen>-insufficient` | `forecast-insufficient` |
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
| `predictive/predictive_edge_cases_test.dart` | biên tháng · timezone · restart trên file SQLite thật · reset sample · user data cùng tồn tại · ngưỡng sufficiency |
| `predictive/predictive_privacy_test.dart` | prompt/twin/telemetry không mang PII |
| `predictive/predictive_ai_test.dart` | hostile AI không đổi được số · zero-spend · không tool runtime |
| `error_handling_governance_test.dart` | seam bắt buộc cho mọi IO trong `ui/` · cấm catch thủ công · cấm spinner tự chế · cấm FutureBuilder/`.when` · **đúng một** `tongtaiDatabaseProvider` · telemetry chỉ kind+code+screen |
| `screen_data_seam_test.dart` | lỗi ≠ rỗng · retry hồi phục · refresh hỏng giữ dữ liệu + banner stale · 320px/1.3× · live region + tap target 44px · negative control telemetry |
| `export/backup_restore_test.dart` | round-trip 6 dataset trên file SQLite thật · v1 bị từ chối · version mới hơn · checksum hỏng · file cụt · thiếu dataset · id trùng · FK gãy · enum lạ · lệch counts · vault hỏng · rollback giữa chừng · privacy negative control |
| `export/backup_codec_test.dart` | format giữ **mọi trường** (kể cả history) · mã canonical · decoder từ chối thay vì đoán |
| `export/backup_screen_test.dart` | preview không chạm DB · xác nhận phá huỷ · file hỏng không có nút phá huỷ · file mã hoá xin mật khẩu |
| `../core/screen_state_test.dart` | phân loại lỗi SQLite **thật** (787) · bất biến `ScreenState` · race response lạc thế hệ · `toString()` không mang `detail` |
| `../commerce/product_category_governance_test.dart` | **một taxonomy canonical** (WTM-393/P-34): mọi nguồn seed lưu **mã**, không nhãn; `parse` chữa nhãn Anh/VI cũ; chuỗi tự đặt giữ nguyên |
| `inventory/slow_moving_capital_test.dart` | **vốn chôn trong hàng chậm bán** (WTM-411/P-41): thiếu giá vốn ⇒ KHÔNG cộng thành 0, đếm riêng · hết hàng ≠ hàng nằm · cửa sổ đi vào từ phía gọi. 3 đột biến đã chứng minh đỏ |
| `ui/supplier_comparison_widget_test.dart` | **so sánh nhà cung cấp** (WTM-409): `null` = *chưa biết* (KHÔNG in dòng so sánh, phải hiện "chưa biết") · nêu **cả hai mặt** đánh đổi · một báo giá ⇒ không dựng khung rỗng · có câu nhắc người bán quyết. 3 đột biến đã chứng minh đỏ |
| `ui/score_breakdown_test.dart` | **bung điểm cơ hội** (WTM-408): yếu tố vắng hiện `—` + LÝ DO (không hiện `0`) · trọng số hiện cả khi vắng · độ phủ hiện khi `isPartial` · nhãn nhu cầu nói *"khách của bạn"* không nói *"thị trường"*. 3 đột biến đã chứng minh đỏ |
| `swipe_gesture_inset_test.dart` | **vùng cử chỉ hệ thống** (WTM-403/P-40): mọi `Dismissible` phải nằm trên dải `mandatorySystemGestures`; đo **mép dưới**. **+ scan**: bề mặt vuốt MỚI chưa được canh ⇒ đỏ (grep loại `barrierDismissible`/`isDismissible` — chính chỗ phiên Hub đếm nhầm 7 thành 0). 2 đột biến đã chứng minh đỏ |
| `value_colour_governance_test.dart` | **màu định vị không tô lên con số** (A2 · WTM-389 · WTM-407): widget hiện số **không được nhận tham số `Color`** · màn Khách hàng không còn hằng `_blue`. 2 đột biến đã chứng minh đỏ |
| `tongtai_tab_persistence_test.dart` | **giá trị bền vào từ đường ĐỌC** (WTM-405/P-39): chỉ số tab ngoài khoảng ⇒ về Trang chủ · mọi chỉ số hợp lệ giữ nguyên. 2 đột biến ngược chiều đã chứng minh đỏ |
| `ui/home_concept_cards_test.dart` | **luật đứng sau thẻ concept-1** (WTM-404): thiếu mốc ⇒ không phần trăm (mốc = 0 cũng vậy) · dưới 3 điểm ⇒ không vẽ đường · màu định vị không chạm con số/mũi tên · mức ưu tiên là **thứ hạng**, không phải ngưỡng điểm. 5 đột biến đã chứng minh đỏ |
| `semantics_route_header_test.dart` | **vai trò semantics** (WTM-277/P-36): mọi màn nội dung có `isHeader`+`namesRoute`, màn tìm kiếm có `isTextField` — đọc cây bằng `ensureSemantics()` (không `flutter run`+`S`/uiautomator); nhãn/48dp/contrast đã ở `accessibility_test.dart` |

## P-42 · Giấy phép "cho dùng thương mại" ≠ "cho sửa" — ND lọt vào bundle

**Root-Cause.** Lọc ảnh Openverse bằng `license_type=commercial`. Bộ lọc ấy
đúng nghĩa **được dùng**, nhưng **by-nd** (NoDerivatives) cũng nằm trong nhóm
đó: nó cho dùng thương mại và **cấm tác phẩm phái sinh**. Công cụ thì cắt vuông
400×400 **mọi** tấm — nên tấm nào cũng là phái sinh. Bốn ảnh ND đã vào
`assets/demo/products/`.

**Regression.** Không có triệu chứng nào trong app: ảnh hiển thị bình thường,
test xanh, analyzer sạch. Chỉ lộ ra khi đọc `ATTRIBUTION.json` bằng mắt.

**Test Pattern.** `demo_media_governance_test.dart` §1 — quét manifest, đỏ nếu
có giấy phép bắt đầu bằng `by-nd`. Kèm §2 (manifest Dart == đúng tập tệp) và §3
(mọi ảnh có nguồn + giấy phép + trang gốc).

**Prevention Rule.** Với tài nguyên bên thứ ba, **liệt kê giấy phép được phép**
(`license=cc0,pdm,by,by-sa`), đừng lọc theo *mục đích sử dụng*. Và nếu công cụ
biến đổi tài nguyên (cắt · đổi màu · ghép), thì quyền **sửa** mới là quyền cần
kiểm, không phải quyền dùng.

## P-43 · Icon không phạm luật nào mà vẫn sai — vùng an toàn không nói "trông cân"

**Root-Cause.** Adaptive icon dựng ở 58% khung 108dp: nằm gọn trong vùng an toàn
66dp, không nét nào bị cắt, cổng hình học xanh. Nhưng đo trên ảnh chụp S24 thì
logo chiếm **88% phần nhìn thấy** — chật, chữ CRM sát đáy — trong khi ô icon bản
vẽ Founder chỉ ~72%. Vùng an toàn trả lời *"cái gì KHÔNG bị cắt"*; nó không trả
lời *"cái gì trông cân"*, và tôi đã dùng câu trả lời thứ nhất cho câu hỏi thứ hai.

**Regression.** Ba phép nhân chồng nhau và không phép nào báo gì: generator tự
chèn `inset="16%"` · launcher chỉ cho thấy 72/108 khung · hãng máy tự chọn hình
mặt nạ. Trước đó còn hai lần trượt cùng họ — ghi chú cũ chép **66dp** thành
**66%** (mặt nạ tròn cắt cụt chấm chữ "i"), và quầng alpha = 1 vô hình trong ảnh
gốc làm `getbbox()` rộng hơn logo thật 10%.

**Test Pattern.** `launcher_icon_geometry_test.dart` — đo phần **nhìn thấy được
thật** (alpha > 8, không phải > 0) trong tệp đã sinh, rồi nhân đúng những gì
Android nhân. Ba khẳng định: ≤ vùng an toàn · **khớp con số script tự khai**
(bắt mọi co ngót âm thầm, bất kể ý định là bao nhiêu) · ≤ 80% phần nhìn thấy
(trần lấy từ phép đo trên máy thật).

**Prevention Rule.** Với thứ chỉ tồn tại sau khi hệ điều hành biến đổi (icon ·
splash · widget), **đo trên ảnh chụp máy thật rồi mới chốt con số**, và cho cổng
so với *ý định đã khai* thay vì một ngưỡng viết tay. Một hằng số viết tay chỉ
kiểm được điều mình đã nghĩ tới; so với ý định thì kiểm được cả điều mình quên.

## P-44 · Test kiểm MỘT con số không bao giờ bắt được HAI con số nói ngược nhau

**Root-Cause.** Màn Khách hàng hiện `VIP: 0` ở ô tóm tắt và `Khách VIP (8)` ở
chip **cách đó 600px trên cùng một màn hình**; `Mới: 4` đứng cạnh
`Khách mới (14)`. Ba nguồn khác nhau đội chung một cái nhãn: `c.tier` (trường
xếp hạng không đường ghi nào set ⇒ luôn 0) · `orderCount == 0` gắn nhãn *"Mới"*
(thật ra là **chưa mua**, gần như ngược nghĩa) · và nhãn lưu sẵn từ file nhập.

**Regression.** **2863 test xanh.** Mỗi con số đều có test, và mỗi test đều
xanh — vì mỗi cái đúng với **nguồn của riêng nó**. Không test nào hỏi câu duy
nhất bị phá: *"hai con số này có nói cùng một chuyện không?"* Founder nhìn một
giây là thấy; suite chạy 2 phút thì không.

**Test Pattern.** `tongtai_consumer_segment_consistency_test.dart` — dựng màn
thật với dữ liệu thật, rồi **đọc lại chính hai chỗ ấy trên cây widget** và bắt
chúng khớp. Không assert một giá trị cụ thể (giá trị đổi theo dữ liệu), mà
assert **quan hệ**. Kèm bất biến đếm: `segmented + notPurchased == total`.

**Prevention Rule.** Khi một khái niệm xuất hiện **hai lần trở lên trên cùng
một màn**, viết test cho **quan hệ giữa chúng**, không chỉ cho từng cái. Câu hỏi
để tự vấn: *"nếu hai chỗ này lấy số từ hai nguồn khác nhau thì có test nào đỏ
không?"* — nếu không, chưa có cổng nào cả.

⚠️ Hệ quả kèm theo: khi gộp về một nguồn, **đừng gộp quá tay**. Bản sửa đầu ở
đây xoá luôn nhãn người bán tự đặt ("bán sỉ") vì tưởng chúng cùng loại; cổng
`count_list_contract_test` bắt được. Hai thứ **trùng chỗ hiển thị** chưa chắc
**trùng khái niệm** — cùng họ với luật DS *"cùng hình dáng không phải cùng vai"*.

## P-45 · Cổng chỉ bắt **thứ nó được viết để tìm** — `Colors.orange` đi qua cổng cấm mã hex

**Root-Cause.** Cổng ratchet DS §3b cấm `Color(0xFF...)` trong tệp màn: màu phải
có tên ngữ nghĩa để đổi được từ một chỗ. Nhưng `Colors.orange` **không phải một
mã hex** — nó là một cái tên mượn từ bảng màu Material. Nó đi lọt §3b (regex hex)
lẫn §3 (chỉ bắt component *nhận* `Color`, không bắt màn *chọn* màu tại chỗ),
trong khi hậu quả hiển thị y hệt: một sắc độ không ai đổi được từ một chỗ.

**Regression.** Màn Nhập liệu tô khối **cảnh báo** bằng `Colors.orange`. Theo
luật màu Founder, **cam = Brand/Primary Action** — nên chỗ đang báo có vấn đề
lại đọc ra *"bấm vào đây"*. Nặng hơn: **đây là tái phát**. Chú thích trong
`tongtai_connections_screen.dart` đã ghi đúng lỗi này khi DS-2 dọn màn Kết nối
và gọi nó là *"nặng nhất"*. Bài học được viết ra, được lưu lại, và **vẫn tái
phát** — vì nó nằm trong một chú thích, mà chú thích không chặn được gì.

**Test Pattern.** §3c trong `design_system_ratchet_test.dart`: cấm
`Colors.<tên>` trong toàn `lib/features/tongtai/ui/`, **không baseline** (đo
thật chỉ 7 lần dùng ⇒ đóng hẳn thay vì ratchet). Hai chi tiết đáng chép lại:

* **Bỏ chú thích trước khi soi mã.** Cổng suýt tự bắn vào chân mình: mọi chú
  thích *giải thích* một luật đều phải **trích dẫn thứ luật ấy cấm**. Một cổng
  đọc văn xuôi như đọc mã sẽ phạt đúng những người ghi lại bài học. Đột biến
  thứ hai kiểm chính điều này: để `Colors.orange` **chỉ trong chú thích** ⇒ cổng
  phải vẫn xanh.
* **`white`/`black`/`transparent` được miễn** — chúng không mang vai ngữ nghĩa
  nào (nền, lớp phủ, chỗ trống). Ép chúng vào `TtStatus` là lỗi ngược lại.

**Prevention Rule.** Khi viết một cổng, đừng hỏi *"luật là gì"* — hỏi **"còn
CÁCH VIẾT nào khác cho ra đúng hậu quả ấy?"** Một luật thường có nhiều cú pháp:
màu có `Color(0xFF..)` · `Colors.<tên>` · `theme.colorScheme.<x>` ·
`.withOpacity` trên hằng số. Cổng bắt một cú pháp là **lời hứa sai** — nó khiến
người ta tin vùng ấy đã sạch. Và hệ quả trực tiếp: **một bài học chỉ nằm trong
chú thích thì không phải là cổng.** Ghi xong thì phải khoá lại bằng test, nếu
không lần sau nó tái phát ở màn khác — đúng như đã xảy ra ở đây.

⚠️ **Và §3c cũng không đủ — đã đo.** Cổng cú pháp cấm một *cách viết*; nó không
biết giá trị viết ra có đúng vai không. Gieo `tone: TtStatus.ai` cho khối cảnh
báo (tím — sai vai, nhưng sạch cú pháp): **§3c vẫn xanh**, chỉ test hành vi
`import_screen_test.dart` đỏ. Nên phải có **cả hai**:

| Cổng | Bắt được | Mù với |
|---|---|---|
| §3c (cú pháp, quét `lib/`) | mọi màu Material ở mọi màn, kể cả màn chưa ai viết test | **giá trị sai vai** viết đúng cú pháp |
| test hành vi (dựng màn thật, đọc `style.color`) | đúng màu mắt người nhìn thấy | **chỉ màn nào có test** |

Một cổng quét rộng mà nông, một cổng sâu mà hẹp. Bỏ cái nào cũng để lọt một
nửa — và mỗi nửa đều đủ để đưa màu Brand vào chỗ báo lỗi.

Cùng họ P-44 (*test kiểm một con số không bắt được hai con số nói ngược nhau*):
cả hai đều là **cổng nhìn đúng chỗ nó được chỉ, và mù với phần còn lại**.

### Ba lần trong một phiên — và lần thứ ba lộ ra kiểu nguy hiểm nhất

Cùng ngày 2026-08-15, đúng hình dạng này xuất hiện **ba lần**, mỗi lần một tầng:

1. **Cú pháp khác** — `Colors.orange` lọt cổng cấm `Color(0xFF..)` (WTM-424).
2. **Giá trị sai, cú pháp đúng** — `tone: TtStatus.ai` cho khối cảnh báo lọt cổng
   cú pháp (WTM-424, đo bằng đột biến).
3. **Phạm vi quét quá hẹp** — cổng `§3` chỉ nhìn `/ui/screens/`, chỉ nhận
   `final Color color;`. Thật ra có **17 tệp**, cổng thấy **9** (WTM-427). Ba
   giả định ngầm: component chỉ ở `screens/` · trường không nullable · trường
   luôn tên `color`. Tám tệp vô hình — trong đó có đúng tệp mà **mắt người tìm
   ra trên máy thật** (WTM-426) chứ cổng thì không.

**Kiểu thứ tư, tệ nhất: cổng hứa mà không kiểm.** Test ấy tên là *"§2+§3 KHÔNG
tự dựng huy hiệu trạng thái, KHÔNG tiêm `Color` thô"* — nhưng trong thân **chỉ
có một bộ dò**. Phần §2 không có mã nào kiểm cả. Một cổng mang tên hứa nhiều
hơn nó làm thì **tệ hơn không có cổng**: người đọc danh sách test tin rằng vùng
ấy đã được canh, nên **thôi không canh nữa**. Không có cổng thì người ta còn
biết là mình đang không có gì.

**Prevention Rule bổ sung.** Khi viết hoặc sửa một cổng, chạy đủ ba câu hỏi:

1. *Còn CÁCH VIẾT nào khác cho ra cùng hậu quả?* (kiểu 1)
2. *Một giá trị hợp lệ về cú pháp nhưng sai vai thì cổng có đỏ không?* (kiểu 2)
3. *Bộ lọc phạm vi của tôi dựa trên giả định gì về vị trí / kiểu / tên?*
   Mỗi giả định là một vùng mù — **đo** số tệp trước và sau khi bỏ giả định,
   đừng ước lượng. (kiểu 3)

Và luật cuối, rẻ nhất: **tên test phải bằng đúng thứ nó kiểm.** Thiếu cổng thì
đi viết; chưa viết được thì nói thẳng trong test là chưa dò được và tại sao —
đừng để cái tên đứng canh thay cho mã.

## P-46 · Máy thật nói đúng sự thật — về **bản bạn dựng**, không về `main`

**Root-Cause.** Founder chốt gỡ băng-rôn `DEMO` (WTM-430). Merge xong, dựng bản
demo, cài lên Nokia — **băng-rôn vẫn còn nguyên**. Suýt đi tìm lỗi trong một
bản sửa không hề hỏng.

Nguyên nhân: nhánh đang làm dở (`refactor/wtm-425-…`) được tách từ commit
**trước** khi WTM-430 merge. APK dựng từ nhánh ấy đơn giản là chưa chứa bản
sửa. Ảnh chụp màn hình đúng 100% — nó chỉ đang trả lời một câu hỏi khác câu
tôi tưởng mình đang hỏi.

**Regression.** Đây là **lỗ ngược** của [P-33] và của toàn bộ doctrine *"máy
thật thấy thứ suite không thấy"*: ta tin ảnh chụp hơn mọi thứ, nên khi ảnh chụp
mâu thuẫn với mã, phản xạ đầu tiên là nghi mã. Suite thì xanh (nó chạy trên cây
làm việc, có bản sửa), CI cũng xanh — **không cổng nào mâu thuẫn**, vì không
cổng nào biết cái APK trên tay có gì.

**Test Pattern.** Không phải một test — một **câu lệnh trước khi kết luận**:

```bash
git merge-base --is-ancestor <commit-của-bản-sửa> HEAD && echo "✓ có" || echo "✗ THIẾU"
```

Rẻ hơn nhiều so với nửa giờ tìm một lỗi không tồn tại. Cùng họ với luật *"kiểm
trạng thái hệ bên ngoài trước khi khẳng định"*.

**Prevention Rule.** Trước khi cài bản dựng để **xác minh một bản sửa cụ thể**,
trả lời hai câu:

1. *Bản dựng này có chứa commit ấy không?* — kiểm bằng lệnh trên, đừng suy từ
   trí nhớ về thứ tự merge.
2. *Nếu thấy lỗi cũ còn nguyên, giả thuyết ĐẦU TIÊN là gì?* Phải là **"tôi dựng
   nhầm bản"**, không phải "bản sửa hỏng" — vì giả thuyết đầu tiên quyết định
   nửa giờ tiếp theo đi đâu.

⚠️ Kèm theo, hai luật thiết bị rút ra cùng lượt ấy:

* **Kiểm hướng màn hình trước khi tap.** Máy đang nằm ngang thì mọi toạ độ nhớ
  sẵn đều sai, và tap rơi ra ngoài app — lần này mở nhầm **ứng dụng cá nhân của
  Founder**. Chụp một ảnh và nhìn trước, đừng tap theo trí nhớ.
* **Cổng tiền cảnh trước VÀ sau mỗi tap**, không chỉ lúc mở app. Rơi khỏi app
  giữa chừng thì mọi ảnh chụp sau đó là ảnh của máy người khác đang dùng.

## P-47 · Nhánh `_ =>` mặc định luôn ngã về **hướng dễ chịu**

**Root-Cause.** WTM-442 thêm bốn kênh bán (`ebay` · `amazon` · `shopify` ·
`lazada`). Luật *"kênh nào giữ lại tiền trước khi trả người bán"* viết:

```dart
bool get chargesPlatformFee => switch (this) {
  SalesChannel.shopee || SalesChannel.tiktok || SalesChannel.appStore => true,
  _ => false,          // ⬅️ bốn kênh mới rơi vào đây
};
```

Quên phân loại một kênh ⇒ app kết luận đơn kênh ấy **không có phí sàn** ⇒ lấy
doanh thu trừ giá vốn và in ra một con số **luôn đẹp hơn sự thật**.

**Regression.** Cùng họ với [P-31] và [P-27]/[P-28], nhưng nguy hiểm hơn vì
**hướng sai không đối xứng**. Một mặc định sai theo hướng bi quan sẽ bị người
dùng phàn nàn trong ngày (*"sao lời của tôi thấp thế"*). Một mặc định sai theo
hướng **tâng bốc** thì không ai đi kiểm — nó cho đúng thứ người đọc muốn thấy.

Ba dấu hiệu của cùng khuyết tật này, cả ba đều gặp thật trong repo:

| Chỗ | Mặc định cũ | Hậu quả khi quên |
|---|---|---|
| `chargesPlatformFee` | `_ => false` | lợi nhuận tính thừa |
| `profileChannel` (l10n) | `_ => 'Bán sỉ'` (WTM-232) | kênh mới **mượn tên** kênh có thật |
| `ProvenanceSource.fromCode` | *(đã đúng)* `null` | — |

`fromCode` làm đúng từ đầu và ghi rõ lý do: *"rơi về `manual` sẽ biến một bản
ghi từ sàn thành 'người bán tự nhập' — tức là nói dối đúng theo hướng nguy hiểm
nhất."* Đó là chuẩn để so.

**Test Pattern.** Có hai mức, dùng mức mạnh khi kiểu dữ liệu cho phép.

*Mức 1 — cổng cơ học (ưu tiên).* Bỏ nhánh `_` khỏi switch trên enum. Dart bắt
buộc vét cạn, nên thêm một giá trị mà không phân loại là **lỗi biên dịch**:

```dart
bool get chargesPlatformFee => switch (this) {
  SalesChannel.shopee || … || SalesChannel.lazada => true,
  SalesChannel.shop || … || SalesChannel.direct => false,
  // không có `_` — quên một giá trị là analyzer đỏ
};
```

*Mức 2 — test đứng thay khi kiểu không chặn được.* `profileChannel(String code)`
nhận chuỗi, nên trình biên dịch bó tay. Test phải duyệt **toàn bộ enum** và
khẳng định không giá trị nào rơi vào nhánh mặc định:

```dart
for (final channel in SalesChannel.values) {
  expect(AppStringsVi().profileChannel(channel.code), isNot('Kênh khác'));
  expect(AppStringsEn().profileChannel(channel.code), isNot('Other channel'));
}
```

⚠️ **Test "hai bên đồng ý với nhau" KHÔNG thay được test "phân loại đúng".**
Khi hai chỗ cùng uỷ quyền về một nguồn, đột biến ở nguồn làm **cả hai** đổi
theo, nên cổng đồng-thuận vẫn xanh. Cần cả hai:

* *đồng thuận* — bắt hai bản chép lệch nhau;
* *phân loại* — bắt nguồn duy nhất khai sai.

Đã kiểm bằng đột biến: sửa `shopify => false` thì cổng **phân loại** đỏ còn
cổng **đồng thuận** vẫn xanh.

**Prevention Rule.** Trước khi viết `_ =>` trong một switch trên enum, hỏi:

1. *Giá trị chưa tồn tại rơi vào đây sẽ sai về hướng nào?* Sai về hướng tâng
   bốc ⇒ **cấm dùng `_`**, vét cạn hoặc trả `null`.
2. *Kiểu dữ liệu có ép được vét cạn không?* Có ⇒ dùng mức 1. Không (tham số là
   `String`) ⇒ **bắt buộc** có test mức 2 duyệt toàn enum.
3. Thêm một giá trị vào enum ⇒ `grep` mọi `switch` chạm enum ấy, đừng tin vào
   việc analyzer sẽ nhắc — nó chỉ nhắc ở nơi không có `_`.


## Khi sửa bug mới — checklist

1. Reproduce trên **đúng môi trường người dùng gặp** (release/máy thật nếu cần).
2. Ghi lại **state thật** (DB dump, log) trước khi sửa.
3. Viết test **fail trên commit hiện tại**, pass sau fix, qua production wiring.
4. Hỏi: *lớp lỗi này còn ở đâu nữa?* → audit toàn bộ cặp/màn cùng loại.
5. Thêm mục Pattern vào file này (4 phần) + khoá bằng scan nếu có thể.
