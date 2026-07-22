# Hub Cleanup Guide (CHƯA thực hiện — chỉ là hướng dẫn)

Sau khi Founder xác nhận repo này ổn định, việc dọn code Tổng Tài khỏi Hub là
**task riêng, cần Founder ra lệnh**. Khi đó:

## Phạm vi xoá bên Hub (branch riêng + PR, không đụng main trực tiếp)

- `mobile/app/lib/features/tongtai/**`
- `mobile/app/lib/database/**` ⚠️ **kiểm tra trước**: đây là DB do Tổng Tài tạo
  (17 bảng tongtai.db) — xác nhận không code Hub nào import (`grep -r
  "lib/database" mobile/app/lib --include="*.dart"` ngoài chính nó).
- `mobile/app/test/features/tongtai/**` + `mobile/app/test/database_test.dart`
- `docs/tongtai/**` (đã có bản chính ở repo này) — có thể giữ 1 README pointer.
- `handover.sh` (bản Hub-root trỏ tongtai)

## Giữ lại bên Hub

- Branch `feat/tongtai` (frozen archive — lịch sử 22 story).
- Tag/nhánh khác của Hub không liên quan.

## Điều kiện an toàn

1. Repo này build+test xanh ≥1 sprint sau split.
2. `flutter analyze` + `flutter test` của Hub vẫn xanh SAU khi xoá (Tổng Tài
   code vốn dormant trong Hub nên kỳ vọng không ảnh hưởng — vẫn phải verify).
3. PR cleanup do Founder merge.

⛔ Nhiệm vụ split này KHÔNG được phép làm cleanup — đừng làm nếu chưa có lệnh.
