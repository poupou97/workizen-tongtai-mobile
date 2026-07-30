# Release-Readiness Checklist — Closed Beta (WTM-118 · re-audit WTM-142)

**Assessed:** 2026-07-30 (re-audit; bản gốc 2026-07-24 @757 test) · **Priority:** P1
· **Related:** WTM-37 (Privacy), WTM-119 (Localization), D-7/ADR-TON-005 (telemetry),
ADR-TON-013 (AI tier).

> Checklist chuẩn bị phát hành, không phải feature. Trạng thái phản ánh codebase
> tại thời điểm đánh giá. / Release-readiness, statuses reflect the code as assessed.

Legend: ✅ done · 🟡 partial / gap noted · 🔴 not started · N/A không áp dụng Phase 2.

## 1. States

| Item | Status | Note |
|---|---|---|
| Empty states | ✅ | Fox empty state trên 11+ màn; User Data First toàn app (Home/Reports/Feed/Goals… đều có zero-state + CTA). |
| Loading states | ✅ | Progressive load (empty→real, không spinner chặn) trên Home/Reports/Feed sau khi lên Drift async (WTM-128+); chat có typing indicator. |
| Error states | 🟡 | Form validation đầy đủ; AI có fallback rule-based + provenance chip; BackupCrypto có lỗi thân thiện. Lỗi DB-level chưa có UI riêng (local-first nên hiếm; sync Phase 3). |

## 2. Platform behaviour

| Item | Status | Note |
|---|---|---|
| Offline behaviour | ✅ | Local-first (D-5); AI off/offline → twin rule-based cho cả 5 AI feature (test chứng minh). |
| Responsive layouts | 🟡 | Expanded/Wrap/ListView + vndShort chống tràn. Chưa pass thủ công đa cỡ máy + text-scale (Phase 3 Product Quality). |
| Performance | 🟡 | CustomPaint charts, lazy lists. Chưa đo cold-start/jank có số liệu (candidate Phase 1 tiếp). |

## 3. Quality gates

| Item | Status | Note |
|---|---|---|
| Accessibility | 🟡 | Re-audit: 27 tooltip trên IconButton (~26/27 phủ) + 35 điểm Semantics — khá hơn đánh giá cũ ("~2 chỗ"). Còn thiếu: pass tap-target ≥48dp + contrast + TalkBack (story riêng, Phase 3). |
| Localization | 🟡 | Bilingual enums/labels; UI string còn hard-code VI (WTM-119 Boy-Scout theo chỉ đạo Founder — không mở PR refactor riêng). |
| Automated tests | ✅ | **962 test** (unit+widget), evidence-driven, CI format+analyze+test xanh mỗi PR, cấm placebo. |
| Analyzer / format | ✅ | `flutter analyze` sạch; `dart format` enforced. |

## 4. Store readiness

| Item | Status | Note |
|---|---|---|
| App icon + splash | ✅ | Origami fox native (WTM-110). |
| App identity | ✅ | `com.workizen.tongtai` · version 0.1.0+1 · **label "Tổng Tài"** (WTM-142 — trước là "tongtai"). |
| **Permissions (Android, đã verify trên APK release bằng aapt2)** | ✅ | **INTERNET** (BYOK AI + telemetry — WTM-142 fix: template chỉ khai ở debug, release từng THIẾU) · **CAMERA** (mobile_scanner, quét QR key WTM-83) · ACCESS_NETWORK_STATE + WAKE_LOCK (Firebase measurement, vô hại) · DYNAMIC_RECEIVER_NOT_EXPORTED (nội bộ Android 13+). **Đã STRIP theo red-line:** `AD_ID`, `ACCESS_ADSERVICES_*` (attribution/topics), `BIND_GET_INSTALL_REFERRER_SERVICE` — Firebase Analytics kéo mặc định, đã remove bằng `tools:node="remove"` + tắt `google_analytics_adid_collection_enabled` + `ad_personalization_signals` (meta-data). |
| Permissions (iOS) | ✅ | `NSCameraUsageDescription` (QR key scan, WTM-83). Không quyền nào khác. |
| Telemetry | ✅ | WTM-108 shipped + **verified live trên S24** (app_open trong logcat/DebugView). Operational-only catalogue: `docs/05-OPERATIONS/TELEMETRY-EVENTS.md`; config thật bị `.gitignore` chặn. |
| Privacy policy | 🔴 | **Cần văn bản privacy policy + telemetry disclosure trước Beta** (WTM-37) — candidate kế tiếp Phase 1. |
| Release build | ✅ | `flutter build apk --release` PASS (85.5MB, debug-signed) với Firebase config — verify aapt2. |
| **Smoke-launch release APK trên máy thật (BẮT BUỘC)** | ✅ | Bài học 2026-07-30: release + google-services.json + `firebase_crashlytics` nhưng THIẾU Crashlytics Gradle plugin → crash ngay khi mở ("Crashlytics build ID is missing") — aapt2/analyze/990 test KHÔNG bắt được lỗi tầng gradle-runtime này. Quy trình: `adb install -r` → mở app → `adb logcat -b crash` phải RỖNG + thấy `app_open`. Fix: apply `com.google.firebase.crashlytics` cùng điều kiện với google-services (settings.gradle.kts + app/build.gradle.kts). |
| Release signing / store upload | 🔴 | Keystore thật + upload = **Founder gate** (release production). |
| iOS build | 🔴 | Chưa verify (cần máy có Xcode signing — Founder/external). |
| Backup/Restore | 🟡 | Export CSV + **mã hoá passphrase (WTM-100)** ✅; **chưa có luồng RESTORE/import trong app** (decrypt đã có API + test) — candidate Phase 1. |

## Top gaps còn lại trước Closed Beta (đã cập nhật 2026-07-30)

1. **Privacy policy + telemetry disclosure** (WTM-37) — tài liệu bắt buộc trước Beta.
2. **Restore/import flow** cho backup `.ttbk` (decrypt API sẵn, thiếu UI).
3. **Accessibility pass** (tap targets, contrast, TalkBack) + **responsive/text-scale pass**.
4. **Performance số liệu** (cold start, scroll jank) trên máy thật.
5. **iOS build + release signing** — Founder/external.
