import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';

/// Locale codes Tổng Tài ships strings for (WTM-119). EN + VI in Phase 2; the
/// [AppStrings] scaffold extends to more languages without touching this — the
/// same custom-l10n architecture as the Workizen AI Personal Hub (no ARB /
/// external i18n package).
const Set<String> kSupportedLocaleCodes = {'en', 'vi'};

/// Maps an app locale code to a Flutter [Locale].
Locale appLocale(String code) => Locale(code);

/// Holds the active locale code, persisted in SharedPreferences ('wz.locale').
/// Mirrors the Hub's `LanguageNotifier`; VN-first default when the device
/// language is not one we ship.
class LanguageNotifier extends Notifier<String> {
  static const String _key = 'wz.locale';

  @override
  String build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    if (saved != null && kSupportedLocaleCodes.contains(saved)) return saved;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return kSupportedLocaleCodes.contains(device) ? device : 'vi';
  }

  Future<void> setLocale(String code) async {
    if (!kSupportedLocaleCodes.contains(code)) return;
    await ref.read(sharedPreferencesProvider).setString(_key, code);
    state = code;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

/// Human-readable name for a locale code (shown in the language picker).
String localeDisplayName(String code) => switch (code) {
  'vi' => 'Tiếng Việt',
  _ => 'English',
};
