# ADR-TON-005: Analytics — Firebase Operational Telemetry (Closed Beta)

**Status:** ✅ ACCEPTED (Founder, 2026-07-23 — D-7 APPROVED (Updated),
superseding the earlier "no analytics" recommendation)
**Decides:** OPEN-DECISIONS D-7
**Amends:** the absolute "no telemetry SDKs" wording in PRODUCT-PRINCIPLES #3
and CLAUDE.md (Founder-only change, exercised by the Founder)

## Decision / Quyết định

Phase 2 (closed beta) **cho phép** đúng hai SDK, cho đúng một mục đích —
giám sát chất lượng beta:

- **Firebase Analytics** — operational events cơ bản (app open, screen view,
  lỗi luồng chính). Không event nào chứa dữ liệu kinh doanh của user.
- **Firebase Crashlytics** — crash reporting.

**Cấm tuyệt đối (red line không đổi):** advertising SDK, marketing tracking,
user profiling, personalized advertising. Monetize VALUE, không monetize DATA.

## Consequences / Hệ quả

- 📏 PRODUCT-PRINCIPLES #3 đọc là: "không account bắt buộc; không ad/marketing
  tracking/profiling; telemetry vận hành (Firebase Analytics + Crashlytics)
  được phép trong phạm vi D-7".
- 🔜 Story tích hợp mới (Jira): thêm `firebase_core`, `firebase_analytics`,
  `firebase_crashlytics` + `google-services.json` (KHÔNG commit file thật —
  WORKING-RULES secret gate), event catalogue tối thiểu, và tài liệu hoá
  từng event trong docs.
- 📏 Mọi event mới phải qua review "operational-only" — event chạm dữ liệu
  kinh doanh (tên khách, doanh thu…) bị reject.
- 🔁 Khi hết closed beta, Founder quyết giữ/tắt theo D-7 Phase 3.
