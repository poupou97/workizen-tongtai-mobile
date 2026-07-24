import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/l10n/language_notifier.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';

/// WTM-119 — picking a language from More re-renders the app in that locale.
class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageProvider);
    return MaterialApp(
      locale: appLocale(code),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: const TongtaiMoreScreen(),
    );
  }
}

void main() {
  testWidgets('choosing Tiếng Việt switches the app to Vietnamese', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'wz.locale': 'en'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const _App(),
      ),
    );
    await tester.pumpAndSettle();

    // Starts in English.
    expect(find.text('Language'), findsOneWidget);

    // Open the picker and choose Vietnamese.
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Tiếng Việt'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language-option-vi')));
    await tester.pumpAndSettle();

    // The whole app re-rendered in Vietnamese; the choice is persisted.
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
    expect(prefs.getString('wz.locale'), 'vi');
  });
}
