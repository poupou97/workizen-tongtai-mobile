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
| Nội dung pháp lý (Founder) | **2** — địa chỉ liên hệ · Điều khoản dịch vụ |
| Tài khoản / khoá ký (Founder) | **2** — keystore release · tài khoản Apple |

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
| **Privacy policy** | 🟡 | Văn bản + màn trong app **đã có** (WTM-37). **Thiếu đúng một dòng: địa chỉ liên hệ** (`PRIVACY-POLICY.md:134`) — **Founder** |
| **Điều khoản dịch vụ** | 🔴 | **Chưa tồn tại** — `docs/05-OPERATIONS/` không có file nào. **Founder** |
| Backup / Restore | ✅ | **WTM-164 ADR-TON-018** `.ttbk` v2 lossless 6 repo + Restore=Replace; apply + hoàn tác **đã kiểm trên thiết bị** 2026-08-01 |
| Build release | ✅ | `flutter build apk --release` PASS |
| **Smoke-launch trên máy thật** | ✅ | Bắt buộc theo bài học 2026-07-30 (thiếu Crashlytics Gradle plugin → crash mà analyze/test không bắt được). Quy trình: `adb install -r` → mở → `adb logcat -b crash` rỗng |
| **Ký release / upload store** | 🔴 | `android/app/build.gradle.kts:44` vẫn `signingConfigs.getByName("debug")`. Keystore thật = **Founder gate** |
| **Build iOS** | 🔴 | `ios/` có nhưng **chưa verify** — cần tài khoản Apple Developer. **Founder / bên ngoài** |

---

## Còn lại trước Closed Beta — 5 mục, và ai gỡ được

| # | Mục | Ai | Chặn cứng? |
|---|---|---|:--:|
| 1 | **Địa chỉ liên hệ** cho privacy §10 | **Founder** | ✅ |
| 2 | **Điều khoản dịch vụ** | **Founder** | ✅ |
| 3 | **Keystore release** + upload Play Console | **Founder** | ✅ |
| 4 | **Tài khoản Apple Developer** → build + ký iOS | **Founder** | chỉ chặn iOS |
| 5 | Pass **TalkBack** + đo **scroll jank** trên máy thật | AI (cần thiết bị) | ❌ nên làm, không chặn |

Bốn trong năm mục là của Founder. Mục 5 là thứ duy nhất còn lại trong hàng đợi
kỹ thuật, và nó **không chặn** Beta Android.

⇒ **Android có thể lên closed beta ngay sau khi có mục 1–3.**

---

## Nguyên tắc giữ tài liệu này đúng

Bản trước sai vì nó được viết một lần rồi không ai đối chiếu lại, trong khi
6 story đã đóng đúng những dòng nó đánh dấu thiếu.

**Luật:** story nào đóng một dòng ở đây thì **cập nhật dòng đó trong cùng PR** —
đúng như luật đã áp cho `UI-IMPLEMENTATION-LEVELS.md`. Trạng thái ở đây là
**sự thật đo được**, không phải ý định.
