import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/l10n/language_notifier.dart';
import 'package:tongtai/core/prefs.dart';

/// WTM-119 — the language notifier persists the locale choice.
void main() {
  Future<ProviderContainer> container(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a saved locale is restored on build', () async {
    final c = await container({'wz.locale': 'vi'});
    expect(c.read(languageProvider), 'vi');
  });

  test('with no saved locale, the default is a supported code', () async {
    final c = await container({});
    expect(kSupportedLocaleCodes.contains(c.read(languageProvider)), isTrue);
  });

  test('setLocale updates the state and persists it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);

    await c.read(languageProvider.notifier).setLocale('en');
    expect(c.read(languageProvider), 'en');
    expect(prefs.getString('wz.locale'), 'en');

    await c.read(languageProvider.notifier).setLocale('vi');
    expect(c.read(languageProvider), 'vi');
  });

  test('an unsupported code is ignored', () async {
    final c = await container({'wz.locale': 'en'});
    await c.read(languageProvider.notifier).setLocale('zz');
    expect(c.read(languageProvider), 'en'); // unchanged
  });

  test('localeDisplayName maps codes to names', () {
    expect(localeDisplayName('vi'), 'Tiếng Việt');
    expect(localeDisplayName('en'), 'English');
  });
}
