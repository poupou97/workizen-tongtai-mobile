# Test Strategy (Evidence-Driven)

## Luật cứng

1. **Test thật hay là chết**: `expect(true, true)` / test không assertion =
   placebo → tự động bị reject (bài học WTM-51: agent từng ship 7 test giả +
   báo cáo láo — không bao giờ lặp lại).
2. Mỗi story ship kèm test của nó. Suite hiện tại: **~992 test** — giữ xanh.
3. Bằng chứng = output `flutter analyze` + `flutter test`, không phải lời kể.

> **Tri thức lâu dài về lỗi + pattern phòng ngừa: [TESTING-BIBLE.md](TESTING-BIBLE.md)**
> (P-01…P-07, quy ước Stable Test IDs, danh sách suite governance). Mỗi bug mới
> phải bổ sung một Pattern vào đó, không chỉ thêm test case.

## Tầng test

| Tầng | Mẫu chuẩn | Ghi chú |
|---|---|---|
| DB integration | `test/database_test.dart` | In-memory SQLite (`forExecutor`), test FK/cascade/round-trip thật |
| Unit (service/logic) | `tongtai_core_test.dart`, `tongtai_identity_test.dart` | Fake stores in-memory, không platform channel |
| Widget | `tongtai_navigation_test.dart`, showcase test | Pump thật, finder thật; ListView lazy → `scrollUntilVisible` |
| Controller/state | search/ranking/tab-state tests | Riverpod override providers |
| **Governance (P0)** | `test/features/tongtai/p0/*` | Production wiring + SQLite file thật; contract/scan/overflow/restart — xem Testing Bible |
| **Cross-screen contract** | `test/support/count_list_contract.dart` | `Summary Count == Visible Records`; domain mới **kế thừa** helper, không viết lại |

## Quy ước

- Test file cạnh chuẩn `test/features/tongtai/<module>_test.dart`.
- Platform seams (prefs, secure storage, HTTP) luôn có fake/in-memory impl để
  test không cần device — mẫu: `InMemoryTongtaiIdentityStore`, mock http client.
- Lỗi hạ tầng (network/sqlite3 download) ≠ lỗi code — chạy lại trên môi trường
  mạng ổn trước khi kết luận FAIL.
- Chạy: `flutter test` (tất cả) · `flutter test test/features/tongtai/x_test.dart` (1 file).

## Kịch bản chưa tự động được

Thứ hôm nay còn phải có người ngồi kiểm — file sàn thật, thiết bị thật, đối
chiếu concept — nằm ở [TEST-CASE-REGISTRY.md](TEST-CASE-REGISTRY.md), kèm
**điều kiện cụ thể để tự động hoá** từng mục.

Sổ ấy **không** chép lại test đã có trong `test/`. Một bản sao của suite sẽ hết
hạn ngay ngày hôm sau.
