# Definition of Done — 1 story

Một story chỉ được coi là DONE khi có ĐỦ:

1. ✅ Code thật implement đúng AC trong Jira (đọc AC trước khi code).
2. ✅ Test thật đi kèm (không placebo), suite toàn repo vẫn xanh.
3. ✅ `flutter analyze` sạch (0 error, 0 warning mới).
4. ✅ Codegen (nếu có) do build_runner sinh trong phiên làm việc.
5. ✅ Chuỗi hướng người dùng đi qua `AppStrings` key (ADR-TON-007) — **không**
   nhãn song ngữ, không literal trong `lib/features/tongtai/ui/`.
6. ✅ Commit message có mã `WTM-xx`, push feature branch, PR mở.
7. ✅ Jira → Code Review, comment kèm commit hash + kết quả analyze/test.
8. ✅ Merge vào `main` khi CI xanh (grant tự merge 2026-07-29) → chuyển Done.

## Cổng bổ sung cho story có UI (ADR-TON-015, bắt buộc từ 2026-07-30)

Một UI chỉ được coi là DONE ở **Level đã khai báo** khi:

| # | Điều kiện | Áp dụng từ level |
|---|---|---|
| U1 | Đọc **production repository** (hoặc BusinessContext/provider dùng chung) | L2 |
| U2 | Đúng **BusinessContext** khi cần dữ liệu tổng hợp — không tự tính công thức riêng | L2 |
| U3 | **Không hardcode** business data | L2 |
| U4 | **Không parallel state** (demo state / cache song song) | L2 |
| U5 | Có **integration/contract test** qua production wiring (không mock riêng từng màn) | L2 |
| U6 | Có **stable test keys** theo quy ước `<screen>-<role>` | L2 |
| U7 | CRUD · refresh · navigation · persistence · empty state · **error handling** | L3 |
| U8 | AI đọc BusinessContext + có twin rule-based (ADR-TON-012/013) | L4 |
| U9 | Đã **smoke test trên release build, máy thật** (nếu chạm native/gradle/Firebase) | mọi level |

**Nếu chưa đạt:** story vẫn có thể đóng, nhưng **phải** ghi đúng
`IMPLEMENTATION_LEVEL` thực tế trong Jira và cập nhật
[UI-IMPLEMENTATION-LEVELS.md](../02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md).
**Cấm** đóng story ở level cao hơn thực tế — đây chính là cách bug
"Home Consumer = 1, tab trống" tồn tại nhiều tháng (WTM-26 được coi là
Production Screen trong khi mới là Static UI).

## Định nghĩa DONE cho doc

Doc là DONE khi: một kỹ sư Flutter đủ năng lực build được từ doc mà không phải
hỏi thêm câu hỏi sản phẩm. Code task là DONE khi build chạy và feature hoạt
động **trên thiết bị thật**.
