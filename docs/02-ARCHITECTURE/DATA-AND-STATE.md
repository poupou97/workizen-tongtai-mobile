# Data & State — quy ước

## 3 tầng lưu trữ (chọn đúng chỗ)

| Loại dữ liệu | Nơi lưu | Ví dụ |
|---|---|---|
| Business data | **SQLite/Drift** (`lib/database/`) | products, customers, orders, journeys |
| Bí mật | **flutter_secure_storage** | BYOK AI keys, local user UUID |
| UI state nhẹ | **SharedPreferences** (qua `core/prefs.dart` provider) | selected tab, onboarding-done, search history |

## Drift quy ước

- Schema version hiện tại: **3** (`migrations/tongtai_migrations.dart` — mọi
  thay đổi schema = bump version + migration step + test).
- PK = UUID string. FK enforcement ON; cascade theo ownership (Business → con).
- JSON columns cho nested data. Index qua `@TableIndex`.
- Codegen: `flutter pub run build_runner build` — KHÔNG sửa `*.g.dart` tay.
- Test DB: `AppDatabase.forExecutor(NativeDatabase.memory())` (xem `test/database_test.dart`).

## Riverpod quy ước (ADR-TON-002)

- Plain providers (không codegen): `Provider` / `NotifierProvider` /
  `FutureProvider` — theo mẫu `providers/tongtai_navigation_provider.dart`.
- Platform resource = provider throw-if-not-overridden, override ở `main()`
  và trong test (mẫu: `core/prefs.dart`).
- Không GetIt, không singleton tự chế, không setState cho app-state.

## Offline-first

Ghi local trước, `sync/` outbox (SyncQueueItem, FIFO, last-write-wins đã
document trong [SYNC-QUEUE-CONFLICT-RESOLUTION.md](SYNC-QUEUE-CONFLICT-RESOLUTION.md))
chờ Phase-3 sync worker. Không thêm network dependency vào luồng dữ liệu.
