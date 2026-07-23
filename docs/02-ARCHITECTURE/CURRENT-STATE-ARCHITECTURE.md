# Current-State Architecture — code như nó ĐANG là (2026-07-22)

## Cây thư mục thật

```
lib/
  main.dart                     # entry → ProviderScope(+prefs override) → TongtaaiApp → TongtaiAppShell
  core/
    prefs.dart                  # sharedPreferencesProvider (platform seam, tách từ Hub khi split)
  database/                     # Drift/SQLite — LOCAL-FIRST heart
    database.dart               # AppDatabase, 17 bảng, schemaVersion=3, forExecutor() cho test
    database.g.dart             # generated (build_runner — không sửa tay)
    tables/*.dart               # 15 business entities + SyncQueueItem + SupplierFavorite
    migrations/                 # v1→v3 (v3: products.description + FTS5)
    search/                     # FTS5: suppliers_fts/products_fts, đ-aware tokenizer, search service
  features/tongtai/
    navigation/tongtai_design_tokens.dart   # màu domain, typography, spacing, elevation, TongtaiTabs
    providers/                  # Riverpod: navigation, tab-state, identity, onboarding, search, AI
    state/                      # tab state models + store (SharedPreferences)
    identity/                   # UUID local identity (secure storage, no accounts)
    core/                       # formatters (vnd/compact/date) + domain enums (EN/VI labels)
    sync/                       # offline-first outbox (SyncOperation + repository)
    deeplink/                   # tongtai:// parse/validate/route + cold-start restore
    onboarding/                 # 6-screen tutorial + first-launch gate
    producer/                   # supplier search service, profile, favorites (store+controller)
    inventory/                  # product model/service, form, history, image source, stock alerts
    consumer/                   # customer model + directory service
    search/                     # unified search controller, ranking (+A/B), history store
    opportunity/                # opportunity feed (WTM-91): model, reactions,
                                # filter/sort controller — AI scoring chờ WTM-93
    ai/                         # xAI Grok BYOK: key store/validator, models, client, service, errors
    ui/
      tongtai_app_shell.dart    # IndexedStack + bottom nav (5 tab)
      tongtai_bottom_nav.dart
      widgets/                  # persistent scroll/text-field
      screens/                  # home, producer, inventory, consumer, more, showcase,
                                # supplier search/detail/favorites, product form,
                                # stock alerts, unified search, customer list, AI key,
                                # opportunity feed (WTM-91)
test/                           # 519 tests: DB integration (in-memory), widget, unit
```

## Nguyên tắc phân lớp (ADR-TON-001)

- `lib/core/` + `lib/database/` = **Platform layer** (seams, storage).
- `lib/features/tongtai/` = **Product layer** — không import ngược platform-của-Hub
  (đã cắt 100% khi split); mỗi module giữ dạng extractable.
- DI/state: **Riverpod** xuyên suốt (ADR-TON-002); provider throw-if-not-overridden
  cho platform resources (xem `core/prefs.dart`).

## Dòng chảy chính

1. `main()` → nạp SharedPreferences → override provider → `TongtaiAppShell`.
2. Shell = IndexedStack 5 tab; tab state persist (WTM-56); deep link `tongtai://`
   parse → route (WTM-57); onboarding gate lần đầu (WTM-59).
3. Data: screens → services/controllers → Drift (`AppDatabase`) hoặc stores
   (secure storage / prefs). Search đi qua FTS5 + ranking.
4. AI: `tongtai_ai_service` → `tongtai_ai_client` (OpenAI-compatible, xAI Grok)
   với key từ `tongtai_ai_key_store` (BYOK — key không bao giờ rời máy trừ
   Authorization header gọi thẳng provider).

## Điểm cần biết

- SQLite FK enforcement bật qua `beforeOpen` (PRAGMA foreign_keys=ON); cascade
  business-owned. Test dùng `AppDatabase.forExecutor(NativeDatabase.memory())`.
- Dart SDK `^3.12.2` (dùng private named parameters — đừng hạ SDK).
- `sqlite3_flutter_libs` cho device; test host tự tải sqlite3 dylib (cần mạng
  lần đầu).
