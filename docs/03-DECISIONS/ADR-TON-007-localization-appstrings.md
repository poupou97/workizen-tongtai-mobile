# ADR-TON-007: Localization Architecture — custom AppStrings (mirror Hub, no ARB)

**Status:** ✅ ACCEPTED (Founder-directed, 2026-07-24 — "Localization First",
WTM-119 P0.2)
**Implements:** D-8 (Ngôn ngữ: VI primary, EN secondary)
**Related:** ADR-TON-001 (module extractable), ADR-TON-002 (Riverpod)

## Decision / Quyết định

Tổng Tài dùng **cùng kiến trúc đa ngôn ngữ với Workizen AI Personal Hub** —
một hệ `AppStrings` tùy biến, **KHÔNG** dùng ARB / `flutter gen-l10n` / gói i18n
ngoài. (Founder: "sử dụng cùng kiến trúc đa ngôn ngữ với Hub. Không tạo hệ thống
localization riêng.")

```
languageProvider (Riverpod, persisted 'wz.locale')
    ↓  drives MaterialApp.locale
Localizations.localeOf(context).languageCode
    ↓
AppStrings.of(context)  →  AppStringsVi | AppStringsEn
    ↓
context.l10n.<key>   (ergonomic accessor)
```

Thành phần (mirror Hub `mobile/app/lib/core/l10n/`):
- **`core/l10n/language_notifier.dart`** — `LanguageNotifier` (Notifier<String>)
  + `languageProvider`, persist 'wz.locale' trong SharedPreferences, default theo
  device (fallback VI). `appLocale(code)`, `kSupportedLocaleCodes = {en, vi}`.
- **`core/l10n/app_strings.dart`** — abstract `AppStrings` + `AppStringsVi` /
  `AppStringsEn`, `AppStrings.of(context)`, extension `context.l10n`.
- **`main.dart`** wires `MaterialApp.locale` + `localizationsDelegates`
  (flutter_localizations, đã có) + `supportedLocales`.
- **Enum bilingual** (`labelVi`/`labelEn`) giữ nguyên cho domain enums.

## Why / Vì sao

- Hub đã dùng pattern này (không ARB); đồng bộ cho phép **tái sử dụng capability
  cross-repo** (Hub/Compute/AI Teams) — mục tiêu ecosystem.
- Không thêm build-step gen-l10n; pure Dart, dễ test (resolve theo locale).
- Cố tình để cửa "migrate to ARB when ready" (như comment trong Hub) nếu sau này
  cần số nhiều/định dạng phức tạp.

## Migration policy / Cách áp dụng (Founder)

- **KHÔNG refactor toàn bộ một lần.** Boy-Scout: module nào chỉnh sửa thì chuẩn
  hóa localization luôn. Feature mới tuân thủ `context.l10n` ngay nếu chi phí thấp.
- Hard-code chuỗi VI còn lại = tech-debt, migrate dần (WTM-119).

## Consequences

- ✅ Đổi ngôn ngữ runtime (picker ở More → Ngôn ngữ), persist, EN+VI.
- ⚠️ Còn nhiều chuỗi UI inline chưa migrate — tracked WTM-119, làm dần Boy-Scout.
- Widget test: ưu tiên Widget Key/Semantics; assert text qua `AppStrings` khi cần.
