# Local Development

## Yêu cầu

- Flutter stable (Dart SDK **≥3.12.2** — repo dùng private named parameters).
- Android SDK (API 31+). iOS: Xcode (build do Founder làm trên máy riêng).
- Mạng cho lần chạy test đầu (tải sqlite3 host dylib).

## Chạy

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # khi đổi schema Drift
flutter analyze          # phải sạch
flutter test             # 519+ xanh
flutter run              # emulator/device → Tổng Tài shell
```

## Nhịp làm việc

- Branch từ main: `feat/wtm-xx-<slug>` → code + test → PR. Main = Founder-only.
- Autonomous runtime: `./handover.sh WTM-XX ...` (root repo) — chạy story qua
  Evidence-Driven Runtime (cần repo `workizen-ai-workforce-runtime` bên cạnh
  + `claude` CLI đã login; xem file script cho env overrides).
- Máy chạy dài (batch/NUC): không để máy sleep (sleep = suspend toàn bộ agent).

## Sự cố hay gặp

Xem [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
