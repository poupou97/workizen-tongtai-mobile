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

## Khi sửa bug mới — checklist

1. Reproduce trên **đúng môi trường người dùng gặp** (release/máy thật nếu cần).
2. Ghi lại **state thật** (DB dump, log) trước khi sửa.
3. Viết test **fail trên commit hiện tại**, pass sau fix, qua production wiring.
4. Hỏi: *lớp lỗi này còn ở đâu nữa?* → audit toàn bộ cặp/màn cùng loại.
5. Thêm mục Pattern vào file này (4 phần) + khoá bằng scan nếu có thể.
