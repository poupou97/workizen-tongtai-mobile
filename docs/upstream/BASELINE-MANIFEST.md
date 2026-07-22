# Baseline Manifest — gốc split

| Trường | Giá trị |
|---|---|
| Source repo | `workizen-ai-personal-wallet` (github poupou97/workizen-mobile-north-star-2026-06-12) |
| Source branch | `feat/tongtai` |
| **Source commit** | **`145a5c5`** (test(tongtai): harden Add/Edit Product… WTM-69) |
| Split date | 2026-07-22 |
| Target bootstrap commit | `66c8ae0` (main) — tag **`split-baseline`** |
| Evidence at split | `flutter analyze` clean · **519/519 tests pass** |
| App identity | `com.workizen.tongtai` · Dart SDK `^3.12.2` |

## Nội dung mang theo từ source commit

- `mobile/app/lib/features/tongtai/**` → `lib/features/tongtai/**` (nguyên cấu trúc)
- `mobile/app/lib/database/**` → `lib/database/**`
- `mobile/app/test/features/tongtai/**` + `test/database_test.dart` → `test/`
- `docs/tongtai/**` (60 docs) → `docs/**` (tái tổ chức ở commit `4e11f0b`)
- `handover.sh` (chỉnh path cho repo này)
- Import rewrite: `package:wallet/` → `package:tongtai/` (133 file, 0 sót)
- Dây Hub duy nhất (`mascot_state.sharedPreferencesProvider`) → cắt, thay bằng
  `lib/core/prefs.dart`

## Không mang theo (chủ ý)

Hub foundations chưa dùng (AI Gateway/auth/chat/analytics/billing) — xem
[../02-ARCHITECTURE/MODULE-OWNERSHIP.md](../02-ARCHITECTURE/MODULE-OWNERSHIP.md);
mọi Hub-only feature; secret/keystore/google-services (không tồn tại trong
phần copy).

Lịch sử git đầy đủ trước split: xem source repo @ `feat/tongtai`.
