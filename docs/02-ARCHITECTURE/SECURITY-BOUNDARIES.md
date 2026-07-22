# Security Boundaries

## BYOK (ranh giới cứng nhất)

- AI API key là **của user**, nhập trong app, lưu **duy nhất** ở
  `flutter_secure_storage` (`tongtai_ai_key_store.dart`).
- Key rời máy **chỉ** trong `Authorization` header của request trực tiếp
  device → AI provider (xAI). Không proxy, không server trung gian, không log.
- Không bao giờ: đưa key vào DB, SharedPreferences, log, error message, git.

## Identity

- Không account, không password. `local user id` = UUID v4 sinh 1 lần, lưu
  secure storage (`identity/`). Không gửi đi đâu (chưa có backend).

## Dữ liệu

- Business data 100% on-device (SQLite). Không telemetry/analytics SDK.
- Cloud sync tương lai = opt-in + user-controlled (nguyên tắc ecosystem);
  mọi thiết kế sync phải qua ADR.

## Git & repo

- Cấm commit: keystore, provisioning profile, google-services.json thật,
  .env thật, bất kỳ credential nào. Dùng `*.example` + guide trong
  [../05-OPERATIONS/CONFIGURATION.md](../05-OPERATIONS/CONFIGURATION.md).
- Red line kinh doanh: **monetize VALUE, không monetize DATA**. Feature nào
  biến dữ liệu user thành doanh thu → dừng, hỏi Founder.
