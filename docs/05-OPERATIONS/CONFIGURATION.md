# Configuration

## Nguyên tắc: KHÔNG có secret trong repo

| Loại | Cách cấu hình |
|---|---|
| AI key (xAI Grok) | **BYOK runtime** — user nhập trong app (màn AI key, WTM-61), lưu secure storage. KHÔNG có key build-time. |
| Firebase | **Chưa dùng** (privacy-first, không analytics). Nếu tương lai cần: đặt `google-services.json`/`GoogleService-Info.plist` LOCAL, thêm vào .gitignore, ghi guide tại đây — không commit bản thật. |
| RevenueCat/billing | **Chưa dùng**. Khi monetize: key qua `--dart-define`, không hardcode. |
| Signing Android | Debug tự động. Release: keystore LOCAL của Founder (không commit); guide sẽ thêm ở BUILD-AND-RELEASE khi tới lúc. |
| Signing iOS | Founder build bằng Xcode máy riêng (Team PC6TLRQV8Q bên Hub — Tổng Tài sẽ có provisioning riêng khi lên store). |
| Env vars runtime (autonomous) | `WORKFORCE_REPO`, `WORKFORCE_PROJECT=WTM`, `WORKFORCE_FLUTTER_DIR=.`, `WORKFORCE_MODEL/HARD_MODEL`, `WORKFORCE_MAX_RETRIES`, timeouts — xem `handover.sh`. |

## App identity

- Android applicationId / iOS bundle id: **`com.workizen.tongtai`** (Founder-approved).
- App name: Tổng Tài. Icon/splash: Flutter default — chờ chốt mascot (open decision).
