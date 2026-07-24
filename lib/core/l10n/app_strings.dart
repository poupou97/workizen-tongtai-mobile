import 'package:flutter/widgets.dart';

/// Locale-aware app strings for Tổng Tài (WTM-119) — the same custom-l10n
/// architecture as the Workizen AI Personal Hub: an abstract [AppStrings] with
/// per-locale implementations resolved from `Localizations.localeOf`, no ARB /
/// flutter gen-l10n and no external i18n package.
///
/// Migration is incremental (Boy-Scout): add a getter here + both
/// implementations, then replace the inline literal with `context.l10n.<key>`.
/// New features should use `context.l10n` from the start when the cost is low.
abstract class AppStrings {
  const AppStrings();

  /// Resolves the active locale's strings; falls back to English.
  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'vi' ? const AppStringsVi() : const AppStringsEn();
  }

  // ── common actions (shared across screens) ─────────────────────────────
  String get actionAll;
  String get actionViewAll;
  String get actionSearch;
  String get actionCancel;
  String get actionSave;
  String get actionRetry;

  // ── settings / language ────────────────────────────────────────────────
  String get settingsLanguage;
  String get languagePickerTitle;
}

class AppStringsVi extends AppStrings {
  const AppStringsVi();

  @override
  String get actionAll => 'Tất cả';
  @override
  String get actionViewAll => 'Xem tất cả';
  @override
  String get actionSearch => 'Tìm kiếm';
  @override
  String get actionCancel => 'Hủy';
  @override
  String get actionSave => 'Lưu';
  @override
  String get actionRetry => 'Thử lại';

  @override
  String get settingsLanguage => 'Ngôn ngữ';
  @override
  String get languagePickerTitle => 'Chọn ngôn ngữ';
}

class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get actionAll => 'All';
  @override
  String get actionViewAll => 'View all';
  @override
  String get actionSearch => 'Search';
  @override
  String get actionCancel => 'Cancel';
  @override
  String get actionSave => 'Save';
  @override
  String get actionRetry => 'Retry';

  @override
  String get settingsLanguage => 'Language';
  @override
  String get languagePickerTitle => 'Choose language';
}

/// `context.l10n.<key>` — the ergonomic accessor used throughout the UI.
extension AppStringsX on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
