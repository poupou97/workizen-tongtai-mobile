import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';

/// WTM-119 — AppStrings resolves per the active locale (Hub pattern, no ARB).
void main() {
  Future<AppStrings> stringsFor(WidgetTester tester, Locale locale) async {
    late AppStrings resolved;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: Builder(
          builder: (context) {
            resolved = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return resolved;
  }

  testWidgets('Vietnamese locale resolves Vietnamese strings', (tester) async {
    final s = await stringsFor(tester, const Locale('vi'));
    expect(s, isA<AppStringsVi>());
    expect(s.actionViewAll, 'Xem tất cả');
    expect(s.actionAll, 'Tất cả');
    expect(s.settingsLanguage, 'Ngôn ngữ');
  });

  testWidgets('English locale resolves English strings', (tester) async {
    final s = await stringsFor(tester, const Locale('en'));
    expect(s, isA<AppStringsEn>());
    expect(s.actionViewAll, 'View all');
    expect(s.settingsLanguage, 'Language');
  });

  test('every key is implemented in both locales (no missing override)', () {
    // Accessing every getter throws if an implementation forgot one.
    for (final s in const [AppStringsVi(), AppStringsEn()]) {
      expect(
        [
          s.actionAll,
          s.actionViewAll,
          s.actionSearch,
          s.actionCancel,
          s.actionSave,
          s.actionRetry,
          s.settingsLanguage,
          s.languagePickerTitle,
        ].every((v) => v.isNotEmpty),
        isTrue,
      );
    }
  });
}
