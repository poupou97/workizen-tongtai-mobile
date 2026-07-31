import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/export/backup_format.dart'
    show kTongtaiAppVersion;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_about_screen.dart';

/// WTM-170 — "About Tổng Tài".
void main() {
  Widget host(String locale) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    home: const TongtaiAboutScreen(),
  );

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] shows the version actually built', (tester) async {
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();

      final version = tester
          .widget<Text>(find.byKey(const Key('about-version')))
          .data!;
      expect(
        version,
        contains(kTongtaiAppVersion),
        reason:
            'the version on screen comes from the same constant a governance '
            'test pins to pubspec.yaml, so it cannot drift into claiming a '
            'build that never existed',
      );
    });
  }
}
