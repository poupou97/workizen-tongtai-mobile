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
| `screen_error` | `screen` (prefix test-ID của màn), `kind` (`storage`/`network`/`permission`/`configuration`/`unexpected`), `code` (token cố định, ví dụ `storage.sqlite_787`) | Một màn không đọc/ghi được dữ liệu (WTM-148 · ADR-TON-017) |

**Rule:** thêm event mới = sửa file này TRƯỚC, kèm ghi chú "operational-only
review" trong PR. Event không có trong bảng = không được log.

### `screen_error` — ranh giới riêng tư (WTM-148)

Ba tham số trên là **toàn bộ** những gì rời khỏi máy. `TongtaiFailure` cố tình
tách đôi:

- `detail` (nguyên văn exception, có thể chứa giá trị dòng dữ liệu) — **chỉ
  hiển thị trên màn hình của chính người dùng**, không bao giờ gửi đi;
- `kind` + `code` — token do lập trình viên đặt, số lượng hữu hạn, không sinh
  ra từ dữ liệu → an toàn cho telemetry.

`TongtaiFailure.toString()` **cố ý bỏ `detail`**, vì crash reporter ghi lại
`toString()`. `test/features/tongtai/p0/error_handling_governance_test.dart`
khoá cả hai điều này, và `screen_state_test.dart` có **negative control**: nhét
tên + số điện thoại + doanh thu vào exception rồi assert chúng không lọt ra
`toString()` hay `telemetryParams`.

## Crash reporting

`FlutterError.onError → Crashlytics.recordFlutterFatalError` (chỉ ngoài debug).
Non-fatal: `TongtaiTelemetry.recordError`. Với lỗi màn hình, thứ được ghi là
**`TongtaiFailure`**, không phải exception gốc — đúng vì lý do trên.

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
