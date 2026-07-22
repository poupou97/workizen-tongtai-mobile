# Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| `experiment_not_enabled: private-named-parameters` | SDK constraint < 3.12 | `environment: sdk: ^3.12.2` trong pubspec (đừng hạ) |
| Test fail: `SocketException ... github.com` + `Building assets for package:sqlite3 failed` | Máy mất mạng lúc tải sqlite3 dylib (hay gặp khi máy vừa sleep) | Nối mạng, chạy lại — đây là lỗi hạ tầng, KHÔNG phải lỗi code |
| `database.g.dart` lệch schema | Sửa tables mà chưa regen | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Widget test không thấy element ở dưới màn | ListView lazy | `tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable))` |
| `sharedPreferencesProvider must be overridden` | Quên override trong test/main | Override với `SharedPreferences.setMockInitialValues({})` + instance (mẫu trong test hiện có) |
| Agent/batch "đứng im" nhiều giờ, CPU ~0% | Máy sleep (gập nắp) → mọi process bị suspend, timer đóng băng | Chạy máy always-on / `caffeinate`; kill + chạy lại story |
| FK constraint fail khi seed test | Thiếu parent row (Business cần User trước) | Xem `seedOwner()` trong `test/database_test.dart` |
