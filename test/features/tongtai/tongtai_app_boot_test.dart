import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import 'package:tongtai/features/tongtai/tongtai.dart';
import 'package:tongtai/main.dart' show TongtaiApp;

/// App-level boot tests (WTM-105).
///
/// The repo split rewired `main.dart` straight to [TongtaiAppShell], bypassing
/// [TongtaiRootGate] — so a fresh install never saw the WTM-59 tutorial even
/// though the gate itself was fully unit-tested. These tests pump the real app
/// widget ([TongtaiApp], exactly what `main()` runs) over the production
/// SharedPreferences-backed store, so the wiring itself is what's under test:
///  - AC2: first launch (no flag) boots into the tutorial
///  - AC3: finishing or skipping the tutorial reveals the shell + persists
///  - AC4: a later launch with the flag set boots straight to the shell
///  - end-to-end: the More screen "Replay Tutorial" action shows the tutorial
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> bootPrefs(Map<String, Object> seed) {
    SharedPreferences.setMockInitialValues(seed);
    return SharedPreferences.getInstance();
  }

  // Mirrors main(): the only override the real app installs is the prefs one,
  // so everything downstream (store, controller, gate) is the production path.
  Widget app(SharedPreferences prefs) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TongtaiApp(),
  );

  Finder tutorial() => find.byKey(const ValueKey('tongtai_onboarding_skip'));
  Finder nextButton() => find.byKey(const ValueKey('tongtai_onboarding_next'));
  Finder appShell() => find.byType(TongtaiBottomNav);

  testWidgets('AC2: first launch (no flag) boots into the tutorial', (
    tester,
  ) async {
    final prefs = await bootPrefs({});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    expect(tutorial(), findsOneWidget);
    expect(appShell(), findsNothing);
  });

  testWidgets('AC3: finishing the tutorial reveals the shell and persists', (
    tester,
  ) async {
    final prefs = await bootPrefs({});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    // Walk every page, then tap Get Started on the last one.
    for (var i = 1; i < kTongtaiOnboardingPages.length; i++) {
      await tester.tap(nextButton());
      await tester.pumpAndSettle();
    }
    await tester.tap(nextButton());
    await tester.pumpAndSettle();

    expect(tutorial(), findsNothing);
    expect(appShell(), findsOneWidget);
    expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isTrue);
  });

  testWidgets('AC3: skipping the tutorial reveals the shell and persists', (
    tester,
  ) async {
    final prefs = await bootPrefs({});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    await tester.tap(tutorial());
    await tester.pumpAndSettle();

    expect(tutorial(), findsNothing);
    expect(appShell(), findsOneWidget);
    expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isTrue);
  });

  testWidgets('AC4: a later launch with the flag set skips the tutorial', (
    tester,
  ) async {
    final prefs = await bootPrefs({TongtaiOnboardingStore.storageKey: true});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    expect(tutorial(), findsNothing);
    expect(appShell(), findsOneWidget);
  });

  testWidgets('end-to-end: More → "Replay Tutorial" brings the tutorial back', (
    tester,
  ) async {
    final prefs = await bootPrefs({TongtaiOnboardingStore.storageKey: true});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();
    expect(appShell(), findsOneWidget);

    // Navigate to the More tab and trigger the replay action that was a
    // no-op for users while the gate was unwired.
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Replay Tutorial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay Tutorial'));
    await tester.pumpAndSettle();

    expect(tutorial(), findsOneWidget);
    expect(appShell(), findsNothing);
    expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isNull);
  });
}
