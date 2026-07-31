import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_privacy_policy_screen.dart';

/// WTM-37 — the privacy policy screen.
///
/// The interesting assertion is not that the page renders. It is that the page
/// **admits** to the two things the app really sends. A policy that quietly
/// omits crash reporting, or says "we collect nothing" while `app_open` fires
/// on every launch, is a false statement — and it is false in the direction
/// that benefits us, which is the direction regulators care about.
void main() {
  Widget host(String locale) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    home: const TongtaiPrivacyPolicyScreen(),
  );

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] every section renders', (tester) async {
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('privacy-updated')), findsOneWidget);
      // Eight sections; the list is scrollable, so check the first few are
      // built and the last one is reachable.
      expect(find.byKey(const Key('privacy-section-0')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('privacy-section-7')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('privacy-section-7')), findsOneWidget);
    });
  }

  for (final strings in <AppStrings>[AppStringsVi(), AppStringsEn()]) {
    final label = strings is AppStringsVi ? 'vi' : 'en';

    test('[$label] the policy names what actually leaves the device', () {
      final all = [
        strings.privacyTelemetryBody,
        strings.privacyCrashBody,
        strings.privacyAiBody,
      ].join(' ').toLowerCase();

      // Telemetry: app_open and screen_error both exist in the code today.
      expect(
        all,
        anyOf(contains('mở'), contains('opened')),
        reason: 'the policy must admit the app reports that it was opened',
      );
      expect(
        all,
        anyOf(contains('lỗi'), contains('fail')),
        reason: 'the policy must admit screen-load failures are reported',
      );
      // Crash reporting is real (Crashlytics + 5 recordError call sites).
      expect(
        all,
        anyOf(contains('stack trace')),
        reason: 'crash reporting is live; a policy that omits it is untrue',
      );
      // BYOK: the user's prompt genuinely leaves the device.
      expect(
        all,
        anyOf(contains('nhà cung cấp'), contains('provider')),
        reason:
            'the AI section must say the message goes to a third-party '
            'provider — that is the biggest thing that leaves the device',
      );
    });

    test('[$label] the policy never claims to collect nothing', () {
      final everything = [
        strings.privacyLocalBody,
        strings.privacyTelemetryBody,
        strings.privacyCrashBody,
        strings.privacyNoAdsBody,
      ].join(' ').toLowerCase();

      for (final forbidden in [
        'không thu thập bất kỳ',
        'we collect no data',
        'we do not collect any',
        'no data is collected',
      ]) {
        expect(
          everything.contains(forbidden),
          isFalse,
          reason:
              'The app sends app_open and crash reports. Saying otherwise is '
              'not a simplification, it is a false claim.',
        );
      }
    });

    test('[$label] the backup section does not oversell the checksum', () {
      final backup = strings.privacyBackupBody.toLowerCase();
      expect(
        backup,
        anyOf(contains('sha-256'), contains('checksum')),
        reason: 'users should know a backup is integrity-checked',
      );
      expect(
        backup,
        anyOf(contains('không phải chống giả mạo'), contains('not tamper')),
        reason:
            'SHA-256 detects corruption; anyone editing the payload can '
            'recompute it. Calling it tamper protection would be wrong '
            'in the direction that gets someone hurt (ADR-TON-018).',
      );
    });
  }
}
