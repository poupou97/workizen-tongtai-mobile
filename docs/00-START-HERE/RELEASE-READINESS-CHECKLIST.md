# Release-Readiness Checklist — Closed Beta

**WTM-118 · re-audit WTM-142 (2026-07-30) · re-audit WTM-275 (2026-08-05)**

> Mỗi dòng dưới đây được **đo lại từ code** ngày 2026-08-05, không chép từ bản
> trước. Dòng nào đổi trạng thái đều kèm bằng chứng.

---

## ⭐ Kết luận đọc trước

**Việc kỹ thuật gần như đã xong. Cái còn chặn Beta hầu hết là thứ chỉ Founder
làm được.**

| Nhóm | Còn lại |
|---|---|
| Kỹ thuật (AI làm được) | **1** — pass TalkBack + jank trên máy thật |
| Nội dung pháp lý (Founder) | **0** — xong 2026-08-07 |
| Tài khoản / khoá ký (Founder) | **1** — tải AAB lên Play Console (khoá ký **đã xong**) |

> **Đính chính 2026-08-05:** bản đầu của lần re-audit này xếp **Điều khoản dịch
> vụ** vào nhóm chặn cứng. **Sai** — không cửa hàng nào bắt buộc nó với app này.
> Founder hỏi lại đúng chỗ đó. Chi tiết ở bảng §4.

WTM-175 tự nhận là **P0 #1** vì *"mọi ưu tiên khác đang được quyết bằng phỏng
đoán"*. Kết luận trên nói thẳng: **hàng đợi kỹ thuật không còn là thứ chặn.**

---

## ⚠️ Bản trước nói sai những gì

Ghi ra vì đây là lý do story WTM-275 tồn tại — một checklist sai làm đúng cái
việc nó sinh ra để ngăn.

| Dòng | Bản 2026-07-30 | Sự thật 2026-08-05 |
|---|---|---|
| Số test | `962` | **1818**, toàn bộ PASS |
| Privacy policy | 🔴 *"cần văn bản trước Beta"* | ✅ WTM-37 đã ship (doc + màn trong app) — **chỉ thiếu một dòng địa chỉ liên hệ** |
| Restore `.ttbk` | 🟡 *"thiếu UI"* | ✅ WTM-164 ADR-TON-018, **đã kiểm trên thiết bị** 2026-08-01 |
| Error states | 🟡 *"lỗi DB-level chưa có UI riêng"* | ✅ WTM-148 ADR-TON-017 — 6 trạng thái màn, governance khoá |
| Accessibility | 🟡 *"còn thiếu tap-target + contrast"* | ✅ WTM-168 — 28 vi phạm → sạch, `accessibility_test.dart` khoá |
| Performance | 🟡 *"chưa đo cold-start"* | ✅ WTM-166 — đo trên S24 Ultra **và** Nokia 6.1 |

Bốn dòng bị đánh giá **thấp hơn** thực tế. Hệ quả không phải là mất mặt — mà là
**Founder tưởng còn 5 khoảng trống kỹ thuật trong khi thật ra còn 1**, và có thể
đã hoãn những quyết định chỉ mình anh gỡ được.

---

## 1. Trạng thái màn hình

| Mục | Trạng thái | Bằng chứng |
|---|:--:|---|
| Empty states | ✅ | Fox empty state 11+ màn; User Data First toàn app |
| Loading states | ✅ | Progressive load, **không animation** (ADR-TON-017); idiom `pumpUntilFound` |
| Error states | ✅ | **WTM-148 · ADR-TON-017** — `ScreenState` 6 trạng thái · `TongtaiFailure(kind·code·detail)` · refresh lỗi **giữ dữ liệu cũ**; `error_handling_governance_test.dart` cấm catch thủ công / spinner tự chế / `FutureBuilder` trong `ui/` |

## 2. Hành vi nền tảng

| Mục | Trạng thái | Bằng chứng |
|---|:--:|---|
| Offline | ✅ | Local-first (D-5); AI off/offline → Rule Twin cho cả 5 tính năng AI |
| Responsive | 🟡 | `overflow_test.dart` khoá 3 tab chính + phân trang. **Chưa pass thủ công đa cỡ máy + text-scale** |
| Performance | 🟡 | **WTM-166 đã đo**: cold start S24 Ultra 249–316ms · Nokia 6.1 750–794ms; hydration 12 tháng 405ms. Benchmark 60 tháng chạy trong CI (`capability_hydration_benchmark_test`). **Chưa đo scroll jank trên máy thật** |

## 3. Cổng chất lượng

| Mục | Trạng thái | Bằng chứng |
|---|:--:|---|
| Accessibility | 🟡 | **WTM-168 đã ship** — 28 vi phạm → sạch (contrast ≥4.5:1 qua cặp `-700` + `readableText()`; tap target 48dp). `accessibility_test.dart` khoá. **Chưa pass TalkBack thủ công** |
| Localization | ✅ | Một locale, mọi chuỗi qua `AppStrings` (ADR-TON-007); `localization_test.dart` + `l10n_placeholder_test.dart` khoá chuỗi trần và trộn hai ngôn ngữ |
| Test tự động | ✅ | **1818 test PASS** (đo 2026-08-05, `flutter test`). 17 suite governance P0. Cấm placebo |
| Analyzer / format | ✅ | CI `format + analyze + test` xanh mỗi PR |
| Journey Reachability | ✅ | `journey_reachability_test.dart` — màn L2+ phải chứng minh được lối vào; màn mới không khai ⇒ CI đỏ (WTM-218) |

## 4. Sẵn sàng lên store

| Mục | Trạng thái | Bằng chứng |
|---|:--:|---|
| Icon + splash | ✅ | Origami fox native (WTM-110) |
| Định danh app | ✅ | `com.workizen.tongtai` · label **"Tổng Tài"** (WTM-142) |
| Quyền Android | ✅ | Verify bằng aapt2 trên APK release. **Đã strip theo red-line:** `AD_ID`, `ACCESS_ADSERVICES_*`, install-referrer |
| Quyền iOS | ✅ | Chỉ `NSCameraUsageDescription` (quét QR key) |
| Telemetry | ✅ | WTM-108, verified live trên S24. Catalogue `TELEMETRY-EVENTS.md`: chỉ `app_open` · `screen_view` · `flow_error` · `screen_error` |
| **Khai báo Data Safety** | ✅ | `docs/05-OPERATIONS/STORE-DATA-SAFETY.md` (107 dòng), khớp `TELEMETRY-EVENTS.md` + `PRIVACY-POLICY.md` |
| **Privacy policy** | ✅ | Văn bản + màn trong app (WTM-37) · liên hệ **workizen.labs@gmail.com** (Founder xác nhận 2026-08-07, đã công bố sẵn ở workizen.net/privacy) · trang publish dựng sẵn cho `workizen.net/privacy/tongtai`. ⚠️ **Không** dùng `workizen.net/privacy` — trang đó không khai Firebase/Crashlytics và mô tả app có tài khoản |
| **Điều khoản dịch vụ** | ⚪ | **KHÔNG bắt buộc để lên store** (đính chính 2026-08-05). Apple có EULA chuẩn tự áp dụng nếu không nộp bản riêng; Play chỉ bắt với vài nhóm đặc thù. **Thành bắt buộc khi bật thuê bao tự gia hạn** — Apple đòi link Terms of Use trong app. Hiện `pubspec.yaml` không có dependency mua bán nào |
| **Câu miễn trừ cho số AI dự báo** | ✅ | **WTM-280 đã ship** — `AppStrings.estimateDisclaimer` render **bên trong thẻ chứa con số** ở màn dự báo · màn rủi ro khách hàng · card AI trên Reports. Test khoá **luật đặt chỗ**: có số ⇒ có dòng (`find.descendant`); twin từ chối ⇒ **không** có dòng (absence) |
| Backup / Restore | ✅ | **WTM-164 ADR-TON-018** `.ttbk` v2 lossless 6 repo + Restore=Replace; apply + hoàn tác **đã kiểm trên thiết bị** 2026-08-01 |
| Build release | ✅ | `flutter build apk --release` PASS |
| **Smoke-launch trên máy thật** | ✅ | Bắt buộc theo bài học 2026-07-30 (thiếu Crashlytics Gradle plugin → crash mà analyze/test không bắt được). Quy trình: `adb install -r` → mở → `adb logcat -b crash` rỗng |
| **Ký release** | ✅ | Upload key RSA-4096 hạn **2053**, ngoài mọi repo, quyền 600. Gradle đọc `android/key.properties` (gitignore); **vắng khoá ⇒ rơi về debug** nên CI và máy chưa có khoá vẫn build được. AAB đã ký, **vân tay SHA256 khớp keystore**. Red-line vẫn sạch: `AD_ID` · `ACCESS_ADSERVICES_*` · install-referrer đều **vắng** trong bản ký thật |
| **Upload store** | 🟡 | Còn **một** việc của Founder: tải AAB lên Play Console (đăng ký Play App Signing) |
| **Build iOS** | 🟡 | `ios/` có nhưng **chưa build/ký lần nào**. Tài khoản Apple Developer **đã có** (Founder, 2026-08-07) ⇒ không còn chặn bởi tài khoản; chỉ còn là việc chưa làm |

---

## Còn lại trước Closed Beta — 4 mục, và ai gỡ được

| # | Mục | Ai | Chặn cứng? |
|---|---|---|:--:|
| 1 | ~~Địa chỉ liên hệ cho privacy §10~~ | — | ✅ **xong** (workizen.labs@gmail.com) |
| 2 | ~~Câu miễn trừ cho số AI dự báo~~ | — | ✅ **xong** (WTM-280) |
| 3 | ~~Keystore release~~ | — | ✅ **xong 2026-08-07** (upload key, đã ký AAB) |
| 3b | Tải AAB lên Play Console | **Founder** | ✅ |
| 4 | Tài khoản Apple Developer | — | ✅ **Founder đã có** (2026-08-07) |
| 5 | Pass **TalkBack** + đo **scroll jank** trên máy thật | AI (cần thiết bị) | ❌ nên làm, không chặn |

Ba trong năm mục **đã xong trong ngày 2026-08-07**. Còn lại đúng hai: một keystore
(Founder) và một pass thiết bị (không chặn).

⇒ **Android sẵn sàng nộp.** AAB đã ký nằm ở `build/app/outputs/bundle/release/app-release.aab`.

---

## Nguyên tắc giữ tài liệu này đúng

Bản trước sai vì nó được viết một lần rồi không ai đối chiếu lại, trong khi
6 story đã đóng đúng những dòng nó đánh dấu thiếu.

**Luật:** story nào đóng một dòng ở đây thì **cập nhật dòng đó trong cùng PR** —
đúng như luật đã áp cho `UI-IMPLEMENTATION-LEVELS.md`. Trạng thái ở đây là
**sự thật đo được**, không phải ý định.
