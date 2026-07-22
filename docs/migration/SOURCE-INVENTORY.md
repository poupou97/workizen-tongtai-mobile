# Source Inventory (Discovery từ Hub)

Nguồn: Hub `feat/tongtai` @ `145a5c5`. Chi tiết cái-gì-đi-đâu:
[../upstream/BASELINE-MANIFEST.md](../upstream/BASELINE-MANIFEST.md).
Phân loại ownership đầy đủ:
[../02-ARCHITECTURE/MODULE-OWNERSHIP.md](../02-ARCHITECTURE/MODULE-OWNERSHIP.md).

## Tóm tắt inventory Hub (tại thời điểm split)

| Nhóm | Phân loại | Về repo này? |
|---|---|---|
| `mobile/app/lib/features/tongtai/**` (13 modules) | Tổng Tài Only | ✅ toàn bộ |
| `mobile/app/lib/database/**` (Drift 17 bảng + FTS5 + migrations) | Tổng Tài Only (Hub không import) | ✅ toàn bộ |
| Tests tongtai + database | Tổng Tài Only | ✅ toàn bộ |
| `docs/tongtai/**` (60 docs) | Tổng Tài Only | ✅ (tái tổ chức) |
| `mascot_state.sharedPreferencesProvider` | Shared Foundation (1 symbol) | 🔄 ADAPT → `core/prefs.dart` |
| Hub features (scan/chat/knowledge/studio/academy/rss/memory/…) | Hub Only | ❌ |
| Hub foundations (ai_gateway, auth, analytics, billing) | Shared Foundation — chưa có consumer | ❌ (adopt sau qua upstream) |
| Firebase/RevenueCat/signing/CI của Hub | Hub Only + secret | ❌ |
| Entry points/routes/l10n/assets Hub | Hub Only | ❌ (Tổng Tài có main.dart + tokens riêng) |
| Unknown | — | (không còn mục Unknown sau phân loại) |
