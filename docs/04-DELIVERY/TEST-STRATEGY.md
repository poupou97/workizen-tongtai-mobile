# Test Strategy (Evidence-Driven)

## Luật cứng

1. **Test thật hay là chết**: `expect(true, true)` / test không assertion =
   placebo → tự động bị reject (bài học WTM-51: agent từng ship 7 test giả +
   báo cáo láo — không bao giờ lặp lại).
2. Mỗi story ship kèm test của nó. Suite hiện tại: **519 test** — giữ xanh.
3. Bằng chứng = output `flutter analyze` + `flutter test`, không phải lời kể.

## Tầng test

| Tầng | Mẫu chuẩn | Ghi chú |
|---|---|---|
| DB integration | `test/database_test.dart` | In-memory SQLite (`forExecutor`), test FK/cascade/round-trip thật |
| Unit (service/logic) | `tongtai_core_test.dart`, `tongtai_identity_test.dart` | Fake stores in-memory, không platform channel |
| Widget | `tongtai_navigation_test.dart`, showcase test | Pump thật, finder thật; ListView lazy → `scrollUntilVisible` |
| Controller/state | search/ranking/tab-state tests | Riverpod override providers |

## Quy ước

- Test file cạnh chuẩn `test/features/tongtai/<module>_test.dart`.
- Platform seams (prefs, secure storage, HTTP) luôn có fake/in-memory impl để
  test không cần device — mẫu: `InMemoryTongtaiIdentityStore`, mock http client.
- Lỗi hạ tầng (network/sqlite3 download) ≠ lỗi code — chạy lại trên môi trường
  mạng ổn trước khi kết luận FAIL.
- Chạy: `flutter test` (tất cả) · `flutter test test/features/tongtai/x_test.dart` (1 file).
