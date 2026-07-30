import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/language_notifier.dart';
import 'core/prefs.dart';
import 'core/telemetry/tongtai_telemetry.dart';
import 'features/tongtai/navigation/tongtai_design_tokens.dart';
import 'features/tongtai/ui/tongtai_root_gate.dart';

/// Tổng Tài — AI-First Business OS (Workizen).
///
/// Standalone entrypoint created by the repo split (ADR-TON-001): the product
/// now ships from its own repository with applicationId com.workizen.tongtai.
/// Local-first · BYOK · privacy by default.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // WTM-108 (D-7/ADR-TON-005): operational telemetry — Firebase only when the
  // Founder-provided config exists; the privacy-safe no-op otherwise.
  final telemetry = await initTongtaiTelemetry();
  // Operational catalogue only (docs/05-OPERATIONS/TELEMETRY-EVENTS.md) —
  // events carry counts/flags, never business content.
  await telemetry.logEvent('app_open');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tongtaiTelemetryProvider.overrideWithValue(telemetry),
      ],
      child: const TongtaiApp(),
    ),
  );
}

class TongtaiApp extends ConsumerWidget {
  const TongtaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active locale (WTM-119) — drives Material localizations + AppStrings.
    final localeCode = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Tổng Tài',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TongtaiDesignTokens.producerGreen,
        ),
      ),
      locale: appLocale(localeCode),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: const TongtaiRootGate(),
    );
  }
}
