# Build & Release

## Hiện tại (Phase 2)

- **Android debug**: `flutter build apk --debug` — kênh verify chính.
- **iOS**: build bằng Xcode trên máy Founder (không build iOS trong agent
  session — SPM fetch bị chặn; ghi BLOCKED trung thực thay vì PASS giả).
- Chưa có store release — Tổng Tài chưa lên store.

## Khi tới lúc release (checklist khung, sẽ chi tiết hoá)

1. Version bump trong `pubspec.yaml` (`0.x.y+N`) + entry `docs/CHANGELOG.md`
   (tạo file khi release đầu — luật: không bump version thiếu changelog).
2. Android: keystore riêng Tổng Tài (Founder giữ, không commit) → AAB → Play
   internal testing trước.
3. iOS: bundle `com.workizen.tongtai`, provisioning riêng, Founder submit.
4. Store compliance học từ Hub (đã ăn 4 vòng Apple reject): privacy labels,
   BYOK data-sharing consent, region gates — xem upstream adoption khi làm.
5. Mọi release = Founder gate.
