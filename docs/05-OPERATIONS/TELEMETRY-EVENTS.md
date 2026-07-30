# Telemetry Events — Operational Catalogue (WTM-108, D-7 → ADR-TON-005)

**EN** · Closed-beta quality monitoring ONLY. Every event carries counts/flags —
**never business content** (no customer names, revenue, goals, chat content).
Forbidden forever: ad SDKs, marketing tracking, user profiling, personalized ads.

**VI** · Chỉ giám sát chất lượng closed beta. Event chỉ mang số đếm/cờ —
**không bao giờ chứa dữ liệu kinh doanh** (tên khách, doanh thu, mục tiêu, nội
dung chat). Cấm vĩnh viễn: ad SDK, marketing tracking, profiling, personalized ads.

## Event catalogue (v1 — the ONLY approved events)

| Event | Params | Khi nào |
|---|---|---|
| `app_open` | — | App khởi động (main) |
| `screen_view` | `screen` (tên màn hình, KHÔNG kèm dữ liệu) | Điều hướng chính (chưa wire — thêm dần khi cần beta triage) |
| `flow_error` | `flow` (tên luồng), `kind` (loại lỗi) | Lỗi non-fatal đã bắt được |

**Rule:** thêm event mới = sửa file này TRƯỚC, kèm ghi chú "operational-only
review" trong PR. Event không có trong bảng = không được log.

## Crash reporting

`FlutterError.onError → Crashlytics.recordFlutterFatalError` (chỉ ngoài debug).
Non-fatal: `TongtaiTelemetry.recordError`.

## Local setup (Founder-only — secret gate)

Config thật KHÔNG commit (đã chặn trong `.gitignore`):
1. Tạo Firebase project → thêm Android app `com.workizen.tongtai`.
2. Tải `google-services.json` → đặt vào `android/app/` (build tự nhận —
   gradle chỉ apply Google Services plugin khi file tồn tại).
3. iOS: `GoogleService-Info.plist` → `ios/Runner/`.
4. Không có file config → app vẫn build/chạy bình thường, telemetry **no-op**
   (privacy-safe default, có test).

## Seam

`lib/core/telemetry/tongtai_telemetry.dart` — `TongtaiTelemetry` (Noop mặc định
· Firebase khi có config) · Riverpod `tongtaiTelemetryProvider` · init
`initTongtaiTelemetry()` không bao giờ throw.
