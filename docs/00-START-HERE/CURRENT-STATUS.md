# Current Status — 2026-08-01

## 🧭 Hướng sản phẩm đã chốt (Founder 2026-08-01 · ADR-TON-020)

```
Release → Local-first → File Bridge → Validate với người dùng thật
                                       └→ Managed Platform CHỈ KHI đủ bằng chứng
```

- **Không xây backend hoặc OAuth trước nhu cầu thực tế.** D-4 + D-5 giữ nguyên.
- **File Bridge = capability chính thức**, không phải giải pháp tạm thời (WTM-181).
- **Mục tiêu lớn nhất: đưa sản phẩm đến người dùng thật càng sớm càng tốt.**
  Ưu tiên giá trị sản phẩm hơn mở rộng tài liệu hoặc quy trình.
- **Product Reset 2026-08 đã hoàn tất** (`docs/07-PRODUCT-RESET/`, 24 báo cáo) và
  **không còn là backlog** — đề xuất còn lại chỉ hiện thực hoá qua Epic/ADR mới.
- **Không tạo thêm Product Reset / Audit / Governance** nếu không có chỉ đạo Founder.

### ⚠️⚠️ SHIFT PRIORITY — Founder 2026-08-01 (mới nhất, ghi đè thứ tự trong ADR-TON-020)

> *"Hiện tại **KHÔNG ưu tiên phát hành Store**. Privacy, Terms, Store metadata,
> Data Safety, iOS signing… chỉ cần **duy trì ở trạng thái đúng và không bị
> hỏng**. Không lấy Release Readiness làm mục tiêu chính."*

**Thứ tự mới:**

1. Hoàn thiện **Business Journey**
2. Hoàn thiện **Capability**
3. Hoàn thiện **UI/UX theo Product Concept đã chốt**
4. **Loại bỏ** mọi màn hình / luồng / trải nghiệm chưa nhất quán với Concept
5. **Dogfood** bằng Workizen Internal Digital Company
6. Chỉ quay lại Release Track **sau khi** sản phẩm đạt đúng Concept

**Definition of Done đổi câu hỏi.** Không còn *"code chạy chưa?"* mà là
**"đã đúng trải nghiệm người dùng trong Concept chưa?"** Chưa đúng ⇒ **sửa UX
trước**.

**Autonomous loop ưu tiên phát hiện:** UX chưa thống nhất · Business Journey
đứt đoạn · Capability chưa hoàn chỉnh · **data chưa xuyên suốt** · UI chưa đúng
Design Bible. **Thay vì** store metadata · giấy tờ phát hành · phân phối.

> **Mục tiêu giai đoạn:** một sản phẩm **Founder sẵn sàng dùng hằng ngày**.
> Store là bước sau, không phải đích đến hiện tại.

**Concept nằm ở đâu (đã xác minh, không suy đoán):**
`docs/01-PRODUCT/UI-UX-CONCEPT-INVENTORY.md` — 25 ảnh concept, bản đồ màn hình,
4 IA pattern, và một mục *"Missing or Gaps"* do chính tài liệu tự khai ·
`BUSINESS-JOURNEY-BIBLE.md` · `USER-JOURNEYS.md` · `SCREEN-INVENTORY.md` ·
ảnh gốc `docs/01-PRODUCT/concepts/sc-*.png`.

### Thứ tự delivery đang chạy

| | Epic | Jira | Trạng thái |
|---|---|---|---|
| 1 | **AI-first Onboarding** | WTM-178 | 🔄 Code Review |
| 2 | AI Weekly Review | WTM-179 | ⏳ |
| 3 | Opportunity Layer 1 | WTM-180 | ⏳ |
| 4 | **UI/UX đúng Concept + Journey + Capability** (Shift Priority) | — | ⏳ |
| 5 | Capability Context Performance | WTM-167 | ⏳ |
| 6 | File Bridge | WTM-181 | ⏳ |
| ✅ | AI Business Profile | WTM-177 | Done |
| ⏸ | Local AI / LAN AI | WTM-176 | nghiên cứu xong, chờ implement |
| ⏸ | Release Readiness | WTM-175 | **chỉ duy trì, không phải mục tiêu** |

**Chặn cứng ngoài tay đội phát triển:** nội dung pháp lý (địa chỉ liên hệ +
Điều khoản dịch vụ) — Founder; tài khoản Apple Developer — bên thứ ba.

---

## Where we are

- **Phase 1 (Product Design Bible):** ✅ DONE + Founder-approved. 60 docs.
- **Phase 2 (build):** 🔄 IN PROGRESS — developed autonomously by the
  Evidence-Driven Runtime. `flutter analyze` clean; **~966 tests passing (P0 §1 suites added)**.
- **This repo:** split from the Hub on 2026-07-22 (`split-baseline` tag);
  app runs standalone.
- **Data Foundation — persistence arc COMPLETE for user-authored capabilities**
  (Founder Post-P0 "Data Foundation before AI"): Finance (WTM-120), Inventory
  (WTM-121), Consumer (WTM-123) and Journey (WTM-124) all persist to Drift via
  the approved **Repository + structured-columns + versioned domain-snapshot**
  pattern (ADR-TON-008/009), **User Data First** (real DB starts empty; sample =
  Demo only). Readiness dashboard: `docs/02-ARCHITECTURE/PERSISTENCE-INVENTORY.md`
  (Capability Persistence Matrix). The shared corrupt-tolerant codec
  `lib/features/tongtai/core/domain_snapshot.dart` backs all four.
- **Business Data Foundation — metrics → context → dashboard chain COMPLETE**
  (Founder G-1/2/3 → ADR-TON-010/011/012): Orders as an independent capability
  (WTM-125/126), `BusinessMetricsService` = KPI single source of truth
  (WTM-127), Home = User Data First (WTM-128), and the `BusinessContext`
  **Aggregate Root** via **Progressive Aggregation** — Phase 1 metrics/Customers/
  Orders/Inventory/Opportunity (WTM-129/130/131), versioned Business Snapshot +
  `BusinessHealth` model (WTM-132), **Phase 2 Journey + Finance slices
  (WTM-133)**, **Phase 3 Timeline projection (WTM-134)** — the **non-AI Business
  Snapshot is now complete**. AI reads **only** BusinessContext, never a repository.
- **⭐ 2026-08-01 — KIỂM CHỨNG RESTORE TRÊN THIẾT BỊ + 2 việc dọn nền:**
  · **Bước apply của restore CHẠY ĐƯỢC trên máy thật lần đầu** (Nokia 6.1).
  WTM-164 chưa bao giờ chạy được bước này vì lúc đó không có đường lùi; WTM-173
  mở đường nên giờ thử được an toàn. Tránh share sheet bằng cách `adb push` file
  `.ttbk` sinh sẵn thay vì tạo backup trong app. Kết quả: preview đúng số, thay
  thế đúng, **hoàn tác đưa lại đúng 49 khách · 18 SP · 524 đơn · 538 thu chi**
  — và bản an toàn quay về dưới dạng **preview**, vẫn phải xác nhận lần nữa.
  · **WTM-174 — lỗi thật tìm được nhờ chạy trên máy:** sau khi khôi phục, các
  tab **vẫn hiện doanh nghiệp đã bị thay thế** cho tới khi khởi động lại app.
  DB đúng suốt; chỉ màn hình nói dối — tệ hơn báo lỗi, vì người bán đọc "42" sau
  khi khôi phục sẽ tưởng khôi phục hỏng. Nguyên nhân nằm ngay trong tài liệu của
  hàm invalidate: *"Home looked right only because it re-reads its repositories
  in initState"* — **đúng lúc WTM-149, và bị WTM-148 làm sai** khi chuyển sang
  `ScreenDataController` + `IndexedStack` giữ tab sống. Sửa ở seam:
  `businessDataRevisionProvider`. Ảnh hưởng rộng hơn restore (cả nạp/xoá mẫu).
  merged `15d89c1`, **1419 tests**.
  · **Số hydration TRÊN THIẾT BỊ ở 12 tháng** (câu hỏi treo của Epic WTM-167):
  Nokia 6.1, DB rỗng `home-data 330ms · first-frame 430ms · tổng 778ms`;
  12 tháng `home-data 695ms · first-frame 828ms · tổng 1.348ms`. Hydration
  **40ms → 405ms**. Kết luận WTM-166 **vẫn đúng** (Home có dữ liệu trước khung
  hình đầu), nhưng hydration nay chiếm **gần nửa** thời gian trước first-frame.
  · **Audit backlog Jira:** 62 issue mở → **10**; 51 đóng có bằng chứng, WTM-85
  gộp vào Epic WTM-167 (AC của nó **mâu thuẫn** ràng buộc "không cache toàn
  cục"), WTM-86 thu hẹp. ROADMAP thêm bảng đối chiếu thực tế — dự án ở **cuối
  Phase 3**, không phải giữa Phase 1B. `docs/06-GOVERNANCE/JIRA-BACKLOG-AUDIT-2026-08-01.md`
- **⭐ ĐÊM 2026-07-31 — SĂN LỖI SẢN PHẨM (Founder Autonomous Overnight Mode).**
  Bốn lỗi thật, mỗi lỗi tìm ra bằng cách **quét có hệ thống** chứ không phải đọc lướt:
  · **WTM-169 — 11 nút bấm không ra gì ở màn Cài đặt**, gồm **"Đăng xuất" trong
  một app không có tài khoản** (D-4). Xử theo ba nhóm: **gỡ hẳn** 4 dòng mô tả
  hệ thống tài khoản mà sản phẩm cố ý không có (Hồ sơ · Đội ngũ · Phân quyền ·
  Đăng xuất) — không phải chưa làm mà **không thể có**; **"Sắp có"** cho 6 dòng
  thật sự trên lộ trình (`ListTile(enabled: false)`); **làm luôn** màn *Về Tổng
  Tài* (phiên bản lấy từ `kTongtaiAppVersion` đã ghim vào pubspec ⇒ không thể
  khai sai). `_SettingsItem` có `assert(comingSoon || onTap != null)` — constructor
  từ chối một dòng chết, không cần thêm scan.
  · **WTM-170 — 13 chuỗi tiếng Anh hardcode**, gồm **"Today's Missions" là tiêu
  đề đầu tiên trên Home**. Lọt lưới vì scan l10n cũ kiểm tra **key tồn tại**,
  không kiểm tra UI có dùng chuỗi trần.
  · **WTM-171 — hai future đọc dữ liệu không ai bắt lỗi.** Màn Rủi ro khách hàng
  `await loadAll()` trần: đọc hỏng ⇒ map tên rỗng, mà **map tên rỗng không trông
  giống lỗi** — nó trông giống danh sách khách không có tên, còn phần đánh giá
  rủi ro bên cạnh vẫn render như sự thật. Màn Tìm kiếm: `ensureSeeded` fire-and-
  forget biến mất vào unhandled future. Cả hai qua `runTongtaiAction`; test
  **fail-before/pass-after** đã chứng minh.
  · **WTM-172 — bản sao lưu an toàn không mở lại được (ADR-TON-018 am.2).**
  WTM-164 tạo + verify nó rồi ghi vào thư mục riêng của app, **nơi trình chọn
  file không với tới** ⇒ file duy nhất để cứu một lần restore nhầm là file duy
  nhất người bán không mở được. Đây chính là lý do bước apply không chạy được
  trên máy Founder — lúc đó ghi là *hạn chế của phép thử*, thực ra là **lỗ hổng
  an toàn dữ liệu**. Giờ đọc lại qua chính vault đã ghi, **dừng ở preview** vì
  hoàn tác một-chạm mà ghi đè là cùng sai lầm chĩa ngược lại.
  **1404 → 1415 tests.**
- **⭐ QUYỀN RIÊNG TƯ (WTM-37, 2026-07-31):** nút "Chính sách quyền riêng tư"
  trong Cài đặt là `onTap: () {}` — **bấm không ra gì**. Viết policy song ngữ
  **theo hành vi thật** (đối chiếu code trước khi viết chữ nào): chỉ `app_open`
  + `screen_error` lên telemetry · Crashlytics thật · prompt BYOK **thật sự rời
  máy** tới nhà cung cấp người dùng chọn · khoá ở Keystore, không nằm trong
  backup · quyền AD_ID **bị gỡ** khỏi manifest · `google-services.json` gitignore
  ⇒ bản dựng từ mã nguồn công khai không gửi gì. **Không ở đâu nói "không thu
  thập dữ liệu"** — sẽ là khai sai. Test khoá: policy phải **thừa nhận**
  app_open/screen_error/crash/bên thứ ba · cấm câu "không thu thập" · cấm bán
  SHA-256 như chống giả mạo. `TELEMETRY-EVENTS.md`: nối sự kiện ⇒ sửa policy
  **cùng PR**. ⚠️ **Thiếu địa chỉ liên hệ** — Founder cấp trước khi lên store.
  **1412 tests.**
- **⭐ ACCESSIBILITY (WTM-168, 2026-07-31):** đo bằng **guideline của Android**
  (`androidTapTargetGuideline` · `labeledTapTargetGuideline` ·
  `textContrastGuideline`), 20 màn × 2 locale × có dữ liệu. **28 vi phạm** →
  sạch. Contrast: màu thương hiệu bị dùng làm **màu chữ** (2.15–4.49 so với
  chuẩn 4.5) ⇒ mỗi màu có **cặp song sinh đọc được** (bước -700) +
  `readableText()`; màu -500 **giữ nguyên** cho nền/viền/icon nên bảng màu không
  đổi. Tap target: `buttonHeight` 44→48 · bỏ `visualDensity.compact` (40dp) ·
  trái tim yêu thích 20×20 → 48dp (nới ô lưới 176→204). **Ba tab chính chưa từng
  có trong suite overflow của P0** ⇒ thêm vào là lộ **5 lỗi tràn thật**, trong
  đó pagination bar clip 11px **nuốt luôn nút "trang sau"**. Kèm **7 chuỗi tiếng
  Anh hardcode** mà bản tiếng Việt vẫn hiện tiếng Anh. Testing Bible **P-17·P-18**.
  ⚠️ Nút chính **đậm màu hơn** — hệ quả bắt buộc của 4.5:1. Chưa smoke test máy
  thật. **1404 tests.**
- **⭐ COLD START ĐÃ ĐO (WTM-166, 2026-07-31) — S24 Ultra, bản release:**
  **Không có vấn đề cold start ở khối lượng dữ liệu hiện tại.** Mốc trong app:
  `prefs 13ms · telemetry-init 31ms · run-app 39ms · db-open 51ms · 4 tab có
  dữ liệu 55–56ms · first-frame 69ms`; tổng Android tự báo 249–316ms (n=5),
  phần còn lại là tạo tiến trình + khởi động engine. **Home có dữ liệu TRƯỚC
  khung hình đầu tiên** ⇒ người dùng không bao giờ thấy loading của Home. Ba
  giả thuyết đọc từ code (IndexedStack dựng 5 tab · await nối đuôi · đọc lặp)
  cộng lại **~5ms**.
  · **Phát hiện thật:** một lần khởi động đọc `orders` **×5**, `customers`
  **×4**, `goals` **×4**, `products` ×3, `finance` ×2 — mỗi consumer đều chính
  đáng (hệ quả của Capability Context tự tải on-demand, ADR-TON-016). Ở **12
  tháng buôn bán thật** (529 đơn · 42 khách · 544 giao dịch) = **3.0× chi phí
  cần thiết**; hai phần ba công đọc lúc khởi động là đọc lại thứ vừa đọc.
  · **Sửa duy nhất:** `unawaited(logEvent('app_open'))` — lý do không phải 8ms
  mà là một backend telemetry chậm không được quyền giữ khung hình đầu tiên.
  **KHÔNG đụng** Firebase init (Crashlytics phải cài trước khi có gì để bỏ
  sót) · SharedPreferences · IndexedStack (giữ state tab là có chủ ý).
  · **⛔ Founder Gate mở:** sửa đọc lặp = để **một** lượt đọc nuôi mọi
  Capability Context, nhưng ADR-TON-016 nói chúng **độc lập, tải on-demand**.
  ADR conflict + nhiều hướng hợp lệ ⇒ **chưa tự quyết**.
  · Ratchet: khoá **số lần đọc** (không đổi theo máy) + khoá **tỉ lệ** ở một
  năm dữ liệu. `StartupTrace` sau `--dart-define`, bản người dùng không tốn gì.
  Testing Bible **P-16**. **1394 → 1396 tests.** Báo cáo:
  `docs/04-DELIVERY/reports/WTM-166-cold-start.md`
- **⭐⭐ BACKUP `.ttbk` v2 + RESTORE (WTM-164, 2026-07-31) — ADR-TON-018:**
  Audit phát hiện **`.ttbk` v1 không khôi phục được doanh nghiệp**: nó là **một
  CSV mã hoá của MỘT dataset**, phủ 3/6 repository, **bỏ hẳn `order.id` và
  `OrderItem.productId`** (đứt liên kết Inventory↔Orders mà ADR-TON-010 bắt
  buộc), lưu enum bằng **nhãn tiếng Việt**, và version hoá container mã hoá chứ
  không phải schema dữ liệu. Xây restore trên đó = tính năng phục hồi **làm mất
  dữ liệu trong im lặng**.
  · **v2** = snapshot **toàn miền, lossless, có version** cho cả 6 repository;
  manifest plaintext (format/content/app/db version · backupId · createdAt ·
  encryption · SHA-256 + độ dài), **record counts nằm TRONG payload** nên file
  mã hoá không rò rỉ quy mô kinh doanh; enum bằng **mã canonical**; mã enum lạ
  là **bản ghi hỏng**, không phải default. **SHA-256 = chống hỏng, KHÔNG phải
  chống giả mạo.**
  · **Restore = Replace only** (Founder quyết 2026-07-31; Merge là capability
  riêng, cấm nhét lén): validate toàn bộ **read-only** → preview → xác nhận phá
  huỷ → **tạo + verify** bản sao lưu an toàn → **một transaction** {xoá theo
  FK → ghi theo phụ thuộc → verify counts + FK} → commit → invalidate cache.
  **Không verify được bản an toàn ⇒ không xoá gì.** Version mới hơn/file hỏng
  ⇒ **chặn**, không partial import.
  · **Bug production sửa kèm:** màn Export mặc định dùng **InMemory** history
  store ngay ở bản production ⇒ lịch sử xuất mất sau mỗi lần khởi động lại
  (trái AC5 của WTM-99). Governance mới: production **cấm** default sang
  InMemory · `kTongtaiAppVersion` phải khớp pubspec · telemetry của backup
  không được mang path/tên file/số bản ghi.
  · Dep mới: `file_picker`, `crypto` (SHA-256 **đồng bộ** — bản async của
  `cryptography` không hoàn tất trong fake-async zone của `testWidgets`).
  · Testing Bible **P-13…P-15**. **1347 → 1387 tests.**
  · **Device smoke test (S24 Ultra, release build) — MỘT PHẦN:** cài + mở app
  (có plugin native mới) không crash · màn Backup & restore render đúng · **tạo
  backup** sinh `.ttbk` và mở share sheet · **chọn file** qua `file_selector`
  (SAF picker) · **đọc + validate + preview** hiển thị đúng created/app+db
  version/không mã hoá/SHA-256/**tương thích** và **counts khớp chính xác** file
  kiểm thử (5·3·2·1·4·1) · cảnh báo phá huỷ + nút đỏ "Replace current data" ·
  `adb logcat -b crash` **rỗng**. ⚠️ **Bước apply (bấm Replace) KHÔNG chạy trên
  thiết bị**: bản release không `run-as` được và SAF không thấy thư mục riêng
  của app, nên bản sao lưu an toàn **không khôi phục lại được qua UI** — chạy
  thử sẽ phá dữ liệu thật của Founder mà không có đường lùi. Apply + rollback
  được chứng minh bằng test trên **file SQLite thật** (rollback đầy đủ khi hỏng
  giữa chừng · vault ghi hỏng hoặc đọc lại hỏng ⇒ **không xoá gì** · verify
  counts + FK **bên trong** transaction).
  · **Amendment 1 (WTM-165, Founder Note 2026-07-31):** `.ttbk` từ nay là
  **Business Snapshot Package** — backup chỉ là **một** capability của nó.
  Manifest chừa sẵn `packageKind` · `datasets` · `redaction` cho Restore ·
  Clone Business · Migration · Demo Dataset · AI Sandbox · Support Bundle ·
  Analytics Exchange (**không** triển khai vòng này). **Mã lạ ⇒ `unknown`,
  không bao giờ ⇒ `backup`** (đoán nhầm = restore đè dữ liệu thật bằng dữ liệu
  mẫu); **vắng mặt ⇒ mặc định**, nên hai file v2 đã phát hành vẫn restore được.
  Lệnh cấm nằm ở **restore contract** chứ không ở format: gói bộ phận hoặc đã
  lược bỏ vẫn là gói **hợp lệ**, chỉ **không restore được** —
  `notRestorableKind` · `redactedPackage` · `missingDataset`. **1387 → 1394
  tests.**
- **⭐⭐ ERROR-HANDLING SEAM (WTM-148, 2026-07-31) — ADR-TON-017:** đóng gap hệ
  thống mà audit ADR-TON-015 phát hiện (**1/34 màn** có xử lý lỗi thật). Trước
  đó `initState → _load() → setState` để future lỗi không ai bắt, nên **"không
  có dữ liệu" và "không đọc được dữ liệu" hiển thị y hệt nhau** — lớp lỗi sinh
  ra bug "Home Consumer = 1, tab trống", và nguy hiểm nhất ở màn tiền (`0 ₫` do
  đọc hỏng đọc như một sự thật). Seam dùng chung: **`ScreenState` sáu trạng
  thái** (loading·ready·empty·insufficient·refreshing·failed — `empty`/
  `insufficient` là câu trả lời, `failed` là **không** có câu trả lời) ·
  **`TongtaiFailure`** phân loại + code cố định, `permission`/`configuration`
  không mời retry vì retry vô nghĩa · **`ScreenDataController`** giữ dữ liệu cũ
  khi refresh hỏng (**stale**, có banner nói rõ cũ từ lúc nào) và bỏ response
  lạc thế hệ · **`runTongtaiAction`** để ghi không thể im lặng ·
  **`TongtaiScreenData`/`TongtaiAsyncScreenData`** một cách render với stable
  key. **Loading không animation** (local-first + để `pumpAndSettle` không
  treo; idiom kèm theo: `pumpUntilFound`). **Riêng tư:** `detail` nguyên văn
  chỉ hiện trên máy người dùng, telemetry `screen_error` chỉ mang
  `kind`+`code`+`screen`, `toString()` bỏ `detail` vì crash reporter ghi nó —
  có negative control. **21 màn → L3, 2 màn → L4.** Governance test cấm trong
  `ui/`: catch thủ công · spinner tự chế · `FutureBuilder`/`.when` · nhiều
  `tongtaiDatabaseProvider`. **2 lỗi thật seam phát hiện ngay:** (1)
  `tongtaiDatabaseProvider` khai báo **hai lần** → app mở hai kết nối vào cùng
  file `.db` và test override chỉ trúng nửa app (One Data Path violation);
  (2) export `try/finally` **không có catch** → xuất hỏng trông như xong.
  **1347 tests.**
  · ✅ **Device smoke test PASS — Founder nghiệm thu 2026-07-31** (Galaxy S24 Ultra,
  release build từ `main` `a974b7e`): `ready` (Home · Consumer badge khớp · Customer
  risk) · **`insufficient`** (Dự báo: "Not enough data to forecast" + reason chips,
  **không render `0 ₫`**) · **lỗi phân loại + hồi phục** (ngắt mạng → "Could not reach
  the AI service" kind `network`; bật lại → "Connection OK — grok-4.3 responded") ·
  **dữ liệu người dùng và khoá API giữ nguyên** · `adb logcat -b crash` **rỗng**.
  ⚠️ Màn lỗi toàn trang + banner stale **không** ép trên máy thật vì sẽ phải xoá dữ
  liệu thật của Founder — chứng minh bằng 8 test trên **file SQLite thật** (lỗi mặc
  định = `SqliteException` FOREIGN KEY 787 thật).
- **⭐⭐ PREDICTIVE FOUNDATION (Founder Decision APPROVED 2026-07-30) — ADR-TON-016, Epic WTM-149:**
  Trả lời được câu hỏi "AI dự báo doanh thu / khách rời bỏ chưa?" bằng **kiến trúc**, không phải prompt:
  **Capability Context** độc lập tải on-demand (Revenue · Customer) giữ BusinessContext **không phình God Object**;
  **Aggregation Services** thuần (revenue series · RFM · cashflow · month bucket, timezone = tháng lịch địa phương);
  **Historical Data Generator** tham số hoá (months 3/12/24/36/60 · seed deterministic · profile · mùa vụ Tết/hè/cuối năm ·
  growth/decline · 6 nhóm hành vi khách) seed vào **production repository** prefix `sample-`, có nút "Nạp dữ liệu mẫu 12 tháng" trong More;
  **3 Rule Twin authoritative** chạy không cần AI/mạng/key — `revenue-forecast/1` (WMA+trend+seasonality, có guard chống nhầm mùa-vụ với xu hướng),
  `customer-risk/1` (recency vs nhịp mua riêng + RFM), `business-alerts/1`; envelope `RuleTwinResult` assert **result==null ⟺ insufficient**
  nên "chưa đủ dữ liệu" không thể giả dạng dự báo; **AI chỉ giải thích** (đọc Capability Context + Rule Twin output, KHÔNG còn snapshot phẳng),
  hostile-AI test chứng minh AI không đổi được số; **AI Runtime Boundary** thiết kế sẵn nhưng KHÔNG bật (ratchet cấu trúc: không file nào trong lib/ chạm tool runtime).
  UI mới: **Dự báo doanh thu** + **Rủi ro khách hàng** (stable keys, count==visible, l10n, trạng thái insufficient hiện lý do — không render số 0 giả).
  **2 bug thật fix trong quá trình:** (1) reset dữ liệu mẫu crash FK 787 khi user ghi đơn của mình cho khách mẫu → giữ lại khách bị ghim;
  (2) billable predicate bị chép tay 6 chỗ → gom về một nguồn. Docs: `CAPABILITY-BIBLE.md` (công thức 6 bước thêm capability) +
  `AI-CAPABILITY-MATRIX.md` phần B (8 năng lực AI đang chạy + bất biến đang được test khoá). **1303 tests.**
- **⭐ P0 Process Hardening (Founder 2026-07-30, sau audit) — ADR-TON-015:**
  **UI Implementation Maturity Model L0–L4** (level trong Jira PHẢI == level
  thật trong code; ma trận sống `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`)
  · **One Data Path** `Repository → Context Provider → BusinessContext → Screen`
  (cấm parallel demo state/cache, hardcode business data, mỗi màn tự tính summary)
  · **Cross-screen Contract** `Summary Count == Domain Visible Records` với helper
  tái dùng `test/support/count_list_contract.dart` (domain mới kế thừa, không viết lại)
  · **Stable Test IDs** `<screen>-<role>` bắt buộc cho mọi màn L2+ (test hành vi
  tìm bằng Key, không bằng text) · **Testing Bible**
  `docs/04-DELIVERY/TESTING-BIBLE.md` (P-01…P-07: mỗi bug để lại Root-Cause /
  Regression / Test / Prevention pattern) · DoD thêm cổng U1–U9 cho story có UI.
  **Phát hiện hệ thống khi audit 32 màn: chỉ 1 màn có error handling thật**
  (`ai_key`) → phần lớn màn dừng ở **L2 (+CRUD)**, chưa phải L3; gap này là
  backlog hiện (WTM-148), không phải nợ ẩn.
- **⭐ P0 Regression Audit (Founder 2026-07-30, ĐANG CHẠY):** §1 XONG — **ADR-TON-014 sample-seeding**: demo song song bị loại; "Xem thử Demo" seed `sample-` vào repos THẬT; Export/Chat-AI/Timeline hết đọc fixture (bug thật đã fix + regression-lock); `test/features/tongtai/p0/` (lifecycle · consistency · e2e · acceptance). §2 XONG (WTM-145, 2 PR) — **một locale active, mọi UI string qua key**: quét sạch label song ngữ " · " và " | " + migrate TOÀN BỘ chuỗi user-facing trong `lib/features/tongtai/ui/` (19 màn, ~150 key VI/EN + method có tham số); UI cấm đọc `labelVi/labelEn` trực tiếp — luôn `label(context.l10n.languageCode)`; đổi ngôn ngữ runtime update toàn app + persist; 7 lock test trong `test/features/tongtai/p0/localization_test.dart` (scan " · "/" | "/chuỗi-VN-trong-ui/labelVi-labelEn + unused-key + vi≠en + switch-persist). Ranh giới: domain-generated content (rule summary, timeline event title, sample fixtures) là DATA — giữ tiếng Việt theo thiết kế. §3 XONG (WTM-146) — **test governance**: quét sạch nốt ~180 EN-literal chrome (20 màn + bottom-nav + More entries → key; tổng AppStrings ≈ 290 key VI/EN); diệt 2 fallback `.sample()` tiềm ẩn trong UI (Reports/Customer-history); suite mới `test/features/tongtai/p0/`: scan cấm literal trong MỌI vị trí text của ui/ + cấm `.sample()` (allowlist supplier catalog) · placeholder-consistency VI/EN · nav/action availability qua app-shell thật (5 tab + More entries + create paths mọi data state) · overflow 320px/1.3x vi+en empty+seeded + 2.0x proxy · restart/persistence trên FILE SQLite thật (3 session). **2 bug thật do suite §3 tìm ra & fix:** (1) `SampleDataSeeder.removeAll` xoá customers trước orders → FOREIGN KEY 787 trên DB thật (in-memory không enforce — đúng bug-class §1); (2) Home overflow ở 320px/1.3x (badge + module tiles + section header). §4-6 XONG (Review Package `review/2026-07-30-P0-Regression-Audit/` + zip). **P0 Founder Correction (cùng ngày, chiều):** repro trên S24 Ultra "Home Consumer=1 nhưng tab Customer Intelligence trống" → root cause: tab Consumer (và Producer) là **static design shell WTM-26/24 không đọc provider nào** — không phải fixture-fallback nên các scan trước không bắt được. Fix: 2 tab wire vào ĐÚNG nguồn Home đọc (customerRepository · favorites store + generated opportunities), có view-all sang list thật; contract suite mới `p0/count_list_contract_test.dart` — **Summary Count == Domain Visible Records** cho 6 cặp count/list (consumer · producer · inventory · journey · orders-KPI billable · opportunity), chạy trên SQLite FILE thật + production providers + RESTART (tab-persistence WTM-56 giữ), cả record mẫu lẫn record user. DB device đã soi trực tiếp: 1 customer thật (UUID); catalog FTS `prod-*/sup-*` nằm business demo riêng (`tongtai-demo-business`) — không lọt counts/lists, chỉ phục vụ search (ghi chú audit).
- **Founder-gate blocking the next tier**: Workizen AI activation (BYOK/router,
  privacy red-line — **G-3, deferred**; Founder sequenced the full Business Data
  Foundation first). AI Phase-2 (Opportunity Win Probability / Recommendation /
  Summary, `BusinessHealth` AI assessor) all read the same BusinessContext.

## Shipped stories (all at Jira "Code Review", code on this repo's main)

| Area | Stories |
|---|---|
| Data | WTM-51 schema (17 tables) · 52 migrations · 53 relationships · 54 sync-queue outbox |
| Shell/Nav | WTM-55 bottom nav · 56 tab persistence · 57 deep links · 59 onboarding (6 màn) |
| Identity/Core | WTM-58 UUID identity · 60 core utils (formatters/enums) · 62 design tokens+showcase |
| Producer | WTM-63 supplier search · 64 supplier detail · 65 favorites |
| Inventory | WTM-68 product list · 69 add/edit product · 70 stock alerts · WTM-121 **Drift persistence (ADR-TON-009)**: `ProductCatalogController → ProductRepository → Drift` (schema v5 + `products.domain_snapshot`); app thật bắt đầu RỖNG, sản phẩm user persist (imagePaths trong versioned snapshot); sample = Demo Mode |
| Search | WTM-72 FTS5 (đ-aware) · 73 unified search · 74 ranking + A/B |
| Consumer | WTM-75 customer list · 76 add/edit customer (form, multi-address, audit trail, duplicate check) · 77 purchase history (orders, filters, AOV/repurchase) · WTM-123 **Drift persistence (ADR-TON-009)**: `CustomerDirectoryController → CustomerRepository → Drift` (schema v6 + `customers.domain_snapshot`); structured cols for name/phone/city/email/orders/spend + `segments` JSON col; addresses/tags/notes in snapshot; app thật RỖNG, sample = Demo |
| AI | WTM-61 xAI Grok BYOK client + key screen · **WTM-83 (Founder-approved 2026-07-29)**: **key rotation an toàn** — `TongtaiAiService.rotateKey` validate→ghi→live-test→**rollback về khóa cũ nếu key mới chết** (không bao giờ brick setup đang chạy; nút "Đổi khóa" trên key screen) + **quét QR** nhập key (`mobile_scanner`, dep đã duyệt; `TongtaiKeyScanScreen` on-device, key quét CHỈ điền vào ô — vẫn qua đúng validate/save path; seam `scanLauncher` cho test; iOS NSCameraUsageDescription) · **WTM-116 G-3A AI Business Summary (ADR-TON-013)**: `BusinessSummaryService` — AI **chỉ thấy** `businessContextPromptText(BusinessContext)` (test chứng minh boundary), BYOK/Local theo preference chain, twin rule-based khi AI off/offline, business rỗng KHÔNG tốn provider call; card on-demand trên Reports + provenance chip (provider vs Rule-based). Read-only: không mutate/workflow/action · **WTM-135 G-3B AI Recommendation**: `BusinessAiEngine` (runner chung ADR-TON-013: load context → guard → serialize → provider chain → rule fallback; Summary delegate) + `BusinessRecommendationService` — gợi ý hành động CHỈ để chủ shop tự quyết (không mutate/execute/side-effect), twin `ruleBasedBusinessRecommendations` từ tín hiệu snapshot; nút "Gợi ý hành động" cùng card AI trên Reports · **WTM-136 G-3C AI Planner**: `BusinessPlanService` — kế hoạch tuần đánh số ưu tiên (chặn lỗ trước: hết hàng → đơn mở → goal chậm → cơ hội → khách cũ) + KPI theo dõi, twin `ruleBasedBusinessPlan`; **không bước nào tự chạy**; nút "Kế hoạch tuần" cùng card · **WTM-137 G-3D BusinessHealth AI**: `BusinessHealthAiService` — **assessment only**, `ruleHealth` luôn = health rule-based từ snapshot (test chứng minh AI "nói xấu" cũng KHÔNG đổi được status); nút "Sức khỏe" cùng card. → **G-3A→G-3D staged AI activation HOÀN TẤT (ADR-TON-013)** |
| Chat | WTM-80 chat UI · 81 persistence SQLite v4 (local-only ADR-TON-004) · 82 Workizen AI Router (đa provider, context injection, fallback offline — ADR-TON-006) · WTM-84 **search & history**: nút search → tìm theo nội dung (đ-aware, dùng `ChatMessageStore.search` sẵn có) + lọc kỳ (Tất cả/Hôm nay/7 ngày), kết quả nhóm theo ngày + highlight từ khóa |
| Journey | WTM-87 business goals (templates + multi-step form + progress/pace + khuyến nghị) · WTM-88 goal detail: bấm goal mở chi tiết — tiến độ/pace/còn lại, **kế hoạch hành động** rule-based theo loại + pace, gợi ý (guidance), nút Sửa → form (AI plan thật kế thừa seam này sau) · WTM-124 **Drift persistence (ADR-TON-009, divergent-schema)**: `BusinessGoalController → BusinessGoalRepository → Drift` (schema v7 + `journeys.domain_snapshot`); promoted cols goal/revenueImpact/startedAt + derived status/progress/timeline; type/achieved/growth/endDate/notes trong snapshot; app thật RỖNG, sample = Demo · **WTM-89 Progress Tracking**: `JourneyProgressService` (thuần) tính **doanh thu thực tế trong kỳ mục tiêu** từ đơn hàng billable (User Data First); goal detail thêm card "Doanh thu thực tế" (additive — KHÔNG đụng progress/edit thủ công). **WTM-138 auto-derive (Founder default ADR-TON-013)**: progress goal doanh thu **tự suy từ đơn thật** (`deriveGoalProgress`, list/detail/JourneySummary đều dùng); form ẩn field nhập tay doanh thu (note "tự tính từ đơn"), KPI không suy được (growth) vẫn nhập tay; KHÔNG migrate dữ liệu |
| Opportunity | **WTM-139 Rule Engine (Founder default ADR-TON-013)**: `OpportunityRuleEngine.generate` — cơ hội THẬT từ dữ liệu (Restock hết/sắp-hết-hàng-có-bán · Win-back khách quen im lặng >30d · Goal catch-up theo gap · Category momentum); deterministic id `gen-*`, business rỗng → 0 cơ hội; wired vào `OpportunityContextProvider` (BusinessContext slice thật) + Reports pipeline real-mode + **WTM-140 feed real-mode** (feed load cơ hội generated; business rỗng → empty state; sample chỉ còn demo/tests) + **WTM-141 AI layer**: `OpportunityAiService.explain` — đánh giá/giải thích + `ĐIỂM: NN` parse (clamp 0-100, null nếu không parse được); input = snapshot + opportunity block (không đụng repo); **điểm rule vẫn authoritative**, AI chỉ annotation; nút "Đánh giá AI" trên detail; twin rule-based. → **Chuỗi Founder default Rule Engine → Opportunity → AI Scoring/Ranking/Explanation HOÀN TẤT** · **WTM-94 Opportunity Action**: nút "Tạo mục tiêu từ cơ hội" trên detail — 1 chạm tạo Journey goal (id idempotent `goal-from-<oppId>`, target = expectedImpact, 45 ngày, notes ghi nguồn cơ hội). AI chỉ layer scoring/ranking/explanation lên trên (chưa làm). · WTM-91 feed (type filter, sort relevance/recency/ROI, bookmark + saved view, swipe interested/dismiss + undo) · WTM-92 detail: bấm card mở chi tiết — điểm AI, ROI/tác động, lý do, **kế hoạch hành động** rule-based theo loại, nút quan tâm/bỏ qua/lưu đồng bộ về feed (AI scoring chờ WTM-93) |
| Timeline | WTM-114 Business Timeline (event-driven): `BusinessEvent` + `BusinessEventSource` (finance/order/opportunity/journey adapters) → `TimelineService` merge+sort desc, group-by-day; screen lọc theo loại, icon/màu theo domain, empty-state; modules EMIT events (timeline không query module) — mở từ More → Business |
| Home | WTM-14 dashboard front-door đọc data thật: đếm module, KPI doanh thu năm/đơn/AOV, Top cơ hội, mission = mục tiêu + tiến độ · WTM-128 **Home = User Data First** (G-1): KPI từ `BusinessMetrics` (0 hợp lệ, không "No Data"), `BusinessHealth` badge, onboarding CTAs (customer→product→order→goal→Demo), Demo Mode = hành động chủ động (không preload sample); giờ consume `BusinessContext` (WTM-129/132) · **WTM-143 nhãn Demo**: màn demo TỰ XƯNG — title "Demo — Dữ liệu mẫu" + banner cảnh báo (`home-demo-banner`); Home thật không bao giờ hiện nhãn (test 2 chiều). Bắt nguồn: Founder nhầm demo là dashboard thật · **WTM-144 quick actions**: business CÓ data vẫn giữ lối tắt trên Home (`home-quick-customer/product/order/goal` ActionChips) + **"Xem thử Demo" cố định trong More** (`more-demo-mode`) — field feedback: Founder tưởng mất chức năng khi Get-started tự ẩn sau bản ghi đầu tiên |
| Reports | WTM-95/96 dashboard: KPI doanh thu MTD/YTD + số đơn + AOV, biểu đồ doanh thu 6 tháng (CustomPaint, không thêm lib), top categories · WTM-97 **Top sản phẩm** (doanh thu + số bán) + **Top khách hàng** (chi tiêu + số đơn, tên resolve từ customer directory) · WTM-98 **Pipeline cơ hội** (số đang mở + tổng giá trị kỳ vọng + cơ hội điểm cao nhất, `opportunityPipeline` thuần); headline KPI giờ đọc từ `BusinessMetricsService` (WTM-127) · **WTM-115 lọc theo kỳ**: `ReportPeriod` (Tháng/Quý/Năm/Tất cả) + `PeriodBreakdown` — selector scope các breakdown (categories/products/customers) theo kỳ; **4 KPI card giữ nguyên all-business** (không đụng KPI-SoT, ADR-TON-011); mở từ More → Business |
| Orders | WTM-125 **capability độc lập** tách khỏi `consumer/` + `OrderRepository`/Controller + Drift (ADR-TON-010) · WTM-126 **Create Order**: line PHẢI reference Inventory Product (Inventory Picker); `OrderItem` = snapshot bất biến productId/name/sku/unit/qty/**soldPrice** (override được; order lịch sử KHÔNG đổi khi giá kho đổi); model chừa chỗ Invoice/Payment/Shipment/Return |
| Metrics / BusinessContext | WTM-127 **`BusinessMetricsService` = KPI SoT** (revenue·orders·customers·AOV; Reports/Home reuse, không recompute — ADR-TON-011) · WTM-129/131 **`BusinessContext` = Aggregate Root** — one Context Provider per capability, `BusinessContextService` composes (ADR-TON-012) · WTM-130 Opportunity Phase-1 rule-based signals (AI-off/offline) · WTM-132 versioned Business Snapshot + `BusinessHealth` model · WTM-133 Phase 2: Journey + Finance slices · **WTM-134 Phase 3: Timeline projection (activity-stream, live repos, loại khỏi `hasData`)** → **snapshot phi-AI HOÀN CHỈNH**. **AI reads ONLY BusinessContext**, never repos |
| Finance | WTM-27 dashboard (KPI thu/chi/lợi nhuận/biên, biểu đồ dòng tiền, chi phí theo nhóm, feed) · WTM-113 nhập giao dịch (FAB → form) · WTM-120 **Drift persistence (ADR-TON-008, User Data First)**: `FinanceController → FinanceRepository → Drift`; app thật **bắt đầu RỖNG**, entry user persist qua `TransactionsTable` (scoped `LocalWorkspace` business); sample = Demo Mode (`SampleFinanceRepository`), không ghi vào DB thật. Mở từ More → Business |
| Backup | WTM-99 CSV export (customers/products/orders, UTF-8 BOM, date range, share/email, history — D-10 Phase 2) · **WTM-100 mã hoá backup (Founder-approved 2026-07-29)**: `BackupCrypto` — AES-256-GCM + PBKDF2 (150k, iteration count nhúng trong container `TONGTAI-BACKUP-V1:` armored base64), toggle "Mã hoá bằng mật khẩu" + passphrase ≥6 ký tự trên Export screen → file `.ttbk` qua CÙNG delivery seam; passphrase không rời máy/không lưu; dep mới `cryptography` (pure Dart) |
| Brand | WTM-109 Business Fox mascot (Origami all) · 110 app icon + splash native · 111 mascot trong app (avatar chat, empty states) + đổi nhãn hiển thị "Workizen AI" |
| i18n | WTM-119 **localization foundation** (ADR-TON-007, mirror Hub — KHÔNG ARB): `AppStrings` (VI/EN) + `LanguageNotifier` (persist 'wz.locale') + `context.l10n`; `MaterialApp` wired locale + delegates; picker ở More → Ngôn ngữ đổi ngôn ngữ runtime. Migrate chuỗi UI dần Boy-Scout |
| Telemetry | **WTM-108 (D-7/ADR-TON-005, Founder-approved)**: seam `TongtaiTelemetry` (Noop mặc định · Firebase Analytics+Crashlytics khi Founder cấp config) — gradle apply Google Services CHỈ khi có `google-services.json` (build không vỡ khi thiếu); `initTongtaiTelemetry()` không bao giờ throw; event catalogue v1 (`app_open`/`screen_view`/`flow_error`) tại `docs/05-OPERATIONS/TELEMETRY-EVENTS.md`; config thật bị chặn commit qua `.gitignore`; CẤM ad/marketing/profiling |
| Fixes | WTM-105 wire `TongtaiRootGate` vào `main.dart` (onboarding lần đầu) + ADR-TON-003 |

## NOT built yet (honest gaps)

- Finance dashboard built (WTM-27, read-only over the sample ledger); a
  **transaction entry form** + Drift-backed ledger are still open. Journey:
  goals UI (87) + goal detail & rule-based plan (88); **AI-generated** plan
  còn chờ (WTM-88 seam để sẵn). Opportunity: feed (91) + detail & rule-based
  plan (92); **AI scoring** chờ WTM-93. Chat: đủ UI + persistence + Workizen
  AI Router (80/81/82); Claude adapter + per-provider key UX = follow-up
  (WTM-83).
- Backlog còn lại (WTM-78/79, 84–86, 88–90, 92–94, 97–98, 102, 108) trong Jira
  với AC đầy đủ.
- App icon/splash = Origami Business Fox trên nền navy (WTM-110, native qua
  flutter_launcher_icons + flutter_native_splash).
- iOS build unverified in-session (signing/SPM); Android debug build is the
  verified path. See [../migration/KNOWN-GAPS.md](../migration/KNOWN-GAPS.md).

## Next approved work

Run remaining Phase-2 backlog (Sprint 3+) via the Evidence-Driven Runtime —
same gates. Founder reviews/merges PRs into `main` of THIS repo now (the old
"merge feat/tongtai into Hub main" plan is obsolete — replaced by this split).

Pre-Beta gate: [RELEASE-READINESS-CHECKLIST.md](RELEASE-READINESS-CHECKLIST.md)
(WTM-118) — top gaps: accessibility, localization (WTM-119), privacy policy +
telemetry disclosure (WTM-37), iOS build + release signing (Founder).

## History

Batch reports: [../04-DELIVERY/reports/](../04-DELIVERY/reports/) —
pilot (5 stories) → batch-01 (8, incl. the placebo-catch) → WTM-57 self-heal →
batch-02 (7 + WTM-69 network false-negative, later PASS). Pre-split git history:
Hub repo `feat/tongtai`.
