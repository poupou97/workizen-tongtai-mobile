import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import 'package:tongtai/features/tongtai/tongtai.dart';

/// Real tests for the Onboarding Flow Tutorial (WTM-59).
///
/// Every acceptance criterion is exercised:
///  - AC1: 5-6 screens display sequentially with fade/slide transitions
///  - AC2: each screen has a headline + illustration + body in EN + VI
///  - AC3: a Skip button appears on every screen and dismisses the tutorial
///  - AC4: completion is stored locally; the tutorial shows only once
///  - AC5: the tutorial can be re-triggered from Settings
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── AC2: content model (headline + illustration + bilingual body) ─────────
  group('TongtaiOnboardingPage content (AC2)', () {
    test('has 5-6 screens (satisfies the "5-6 screens" requirement)', () {
      expect(kTongtaiOnboardingPages.length, inInclusiveRange(5, 6));
    });

    test('covers welcome + the five core features', () {
      final ids = kTongtaiOnboardingPages.map((p) => p.id).toList();
      expect(
        ids,
        containsAll(<String>[
          'welcome',
          'suppliers', // scanning suppliers
          'inventory', // managing inventory
          'customers', // tracking customers
          'ai_chat', // using AI chat
          'journeys', // creating business journeys
        ]),
      );
    });

    test('page ids are unique', () {
      final ids = kTongtaiOnboardingPages.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every page has a non-empty headline + body in EN and VI', () {
      for (final page in kTongtaiOnboardingPages) {
        expect(
          page.headlineEn.trim(),
          isNotEmpty,
          reason: '${page.id} headlineEn',
        );
        expect(
          page.headlineVi.trim(),
          isNotEmpty,
          reason: '${page.id} headlineVi',
        );
        expect(page.bodyEn.trim(), isNotEmpty, reason: '${page.id} bodyEn');
        expect(page.bodyVi.trim(), isNotEmpty, reason: '${page.id} bodyVi');
      }
    });

    test('VI copy actually differs from EN (real translation, not a copy)', () {
      for (final page in kTongtaiOnboardingPages) {
        expect(page.headlineVi, isNot(page.headlineEn), reason: page.id);
        expect(page.bodyVi, isNot(page.bodyEn), reason: page.id);
      }
    });

    test('headlineFor/bodyFor resolve vi vs everything-else', () {
      final page = kTongtaiOnboardingPages.first;
      expect(page.headlineFor('vi'), page.headlineVi);
      expect(page.bodyFor('vi'), page.bodyVi);
      expect(page.headlineFor('en'), page.headlineEn);
      expect(page.bodyFor('fr'), page.bodyEn); // unknown → English
    });
  });

  // ── AC4: local persistence store ──────────────────────────────────────────
  group('InMemoryTongtaiOnboardingStore', () {
    test('a fresh store reports not-completed (first launch)', () {
      expect(InMemoryTongtaiOnboardingStore().isCompleted(), isFalse);
    });

    test('markCompleted then reset toggle the flag', () async {
      final store = InMemoryTongtaiOnboardingStore();
      await store.markCompleted();
      expect(store.isCompleted(), isTrue);
      await store.reset();
      expect(store.isCompleted(), isFalse);
    });

    test('can be seeded as already completed', () {
      expect(InMemoryTongtaiOnboardingStore(true).isCompleted(), isTrue);
    });
  });

  group('SharedPrefsTongtaiOnboardingStore (local storage)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to not-completed on a fresh install', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(SharedPrefsTongtaiOnboardingStore(prefs).isCompleted(), isFalse);
    });

    test(
      'completion persists across store instances (app-restart scenario)',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await SharedPrefsTongtaiOnboardingStore(prefs).markCompleted();

        // A brand-new store over the same prefs = a fresh app launch.
        final reader = SharedPrefsTongtaiOnboardingStore(prefs);
        expect(reader.isCompleted(), isTrue);
      },
    );

    test('reset removes the persisted flag', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsTongtaiOnboardingStore(prefs);
      await store.markCompleted();
      await store.reset();
      expect(store.isCompleted(), isFalse);
      expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isNull);
    });
  });

  // ── AC4: controller hydrates from + writes through to storage ─────────────
  group('TongtaiOnboardingController', () {
    ProviderContainer makeContainer(TongtaiOnboardingStore store) {
      final container = ProviderContainer(
        overrides: [tongtaiOnboardingStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('hydrates as not-completed from a fresh store', () {
      final container = makeContainer(InMemoryTongtaiOnboardingStore());
      expect(container.read(tongtaiOnboardingProvider), isFalse);
    });

    test(
      'a fresh controller over a completed store stays completed (restart)',
      () {
        final container = makeContainer(InMemoryTongtaiOnboardingStore(true));
        expect(container.read(tongtaiOnboardingProvider), isTrue);
      },
    );

    test('complete() flips state and writes through to storage', () async {
      final store = InMemoryTongtaiOnboardingStore();
      final container = makeContainer(store);

      await container.read(tongtaiOnboardingProvider.notifier).complete();

      expect(container.read(tongtaiOnboardingProvider), isTrue);
      expect(store.isCompleted(), isTrue);
    });

    test(
      'reset() flips state back and clears storage (Settings replay)',
      () async {
        final store = InMemoryTongtaiOnboardingStore(true);
        final container = makeContainer(store);
        expect(container.read(tongtaiOnboardingProvider), isTrue);

        await container.read(tongtaiOnboardingProvider.notifier).reset();

        expect(container.read(tongtaiOnboardingProvider), isFalse);
        expect(store.isCompleted(), isFalse);
      },
    );
  });

  // ── AC1 + AC3: the onboarding screen widget ───────────────────────────────
  group('TongtaiOnboardingScreen widget', () {
    Widget host(VoidCallback onFinished, {Locale? locale}) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: TongtaiOnboardingScreen(onFinished: onFinished),
      );
    }

    Finder skipButton() =>
        find.byKey(const ValueKey('tongtai_onboarding_skip'));
    Finder primaryButton() =>
        find.byKey(const ValueKey('tongtai_onboarding_next'));

    testWidgets('shows the first screen: illustration + headline + body', (
      tester,
    ) async {
      await tester.pumpWidget(host(() {}));
      await tester.pumpAndSettle();

      // Illustration (icon) present.
      expect(find.byIcon(kTongtaiOnboardingPages.first.icon), findsOneWidget);
      // Headline + body present.
      expect(
        find.text(kTongtaiOnboardingPages.first.headlineEn),
        findsOneWidget,
      );
      expect(find.text(kTongtaiOnboardingPages.first.bodyEn), findsOneWidget);
    });

    testWidgets('AC1: Next advances through every screen with animation', (
      tester,
    ) async {
      await tester.pumpWidget(host(() {}));
      await tester.pumpAndSettle();

      for (var i = 1; i < kTongtaiOnboardingPages.length; i++) {
        await tester.tap(primaryButton());
        await tester.pumpAndSettle(); // let the slide/fade transition finish
        expect(
          find.text(kTongtaiOnboardingPages[i].headlineEn),
          findsOneWidget,
          reason: 'page $i headline should be visible after advancing',
        );
      }
    });

    testWidgets('AC1: page content is wrapped in a fade+slide transition', (
      tester,
    ) async {
      await tester.pumpWidget(host(() {}));
      await tester.pumpAndSettle();
      // The transition primitives are present in the tree (Opacity + Transform
      // driven by the PageController).
      expect(find.byType(Opacity), findsWidgets);
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets(
      'AC3: Skip appears on every screen and dismisses the tutorial',
      (tester) async {
        var finished = 0;
        await tester.pumpWidget(host(() => finished++));
        await tester.pumpAndSettle();

        // Skip is present on each screen as we advance.
        for (var i = 0; i < kTongtaiOnboardingPages.length; i++) {
          expect(
            skipButton(),
            findsOneWidget,
            reason: 'skip missing on page $i',
          );
          if (i < kTongtaiOnboardingPages.length - 1) {
            await tester.tap(primaryButton());
            await tester.pumpAndSettle();
          }
        }

        // Tapping Skip fires onFinished.
        await tester.tap(skipButton());
        await tester.pump();
        expect(finished, 1);
      },
    );

    testWidgets('the last screen shows Get Started and it finishes', (
      tester,
    ) async {
      var finished = 0;
      await tester.pumpWidget(host(() => finished++));
      await tester.pumpAndSettle();

      // Advance to the last screen.
      for (var i = 1; i < kTongtaiOnboardingPages.length; i++) {
        await tester.tap(primaryButton());
        await tester.pumpAndSettle();
      }

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);

      await tester.tap(primaryButton());
      await tester.pump();
      expect(finished, 1);
    });

    testWidgets('AC2: renders Vietnamese copy under the vi locale', (
      tester,
    ) async {
      await tester.pumpWidget(host(() {}, locale: const Locale('vi')));
      await tester.pumpAndSettle();

      expect(
        find.text(kTongtaiOnboardingPages.first.headlineVi),
        findsOneWidget,
      );
      expect(find.text('Bỏ qua'), findsOneWidget); // Skip
      expect(find.text('Tiếp tục'), findsOneWidget); // Next
    });
  });

  // ── AC4 + AC5: root gate shows onboarding once, replayable ────────────────
  group('TongtaiRootGate (AC4/AC5)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer makeContainer(TongtaiOnboardingStore store) {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tongtaiOnboardingStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Widget host(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TongtaiRootGate()),
      );
    }

    Finder onboarding() =>
        find.byKey(const ValueKey('tongtai_onboarding_skip'));
    Finder appShell() => find.byType(TongtaiBottomNav);

    testWidgets('AC4: shows the tutorial on first launch (not completed)', (
      tester,
    ) async {
      final c = makeContainer(InMemoryTongtaiOnboardingStore());
      await tester.pumpWidget(host(c));
      await tester.pumpAndSettle();

      expect(onboarding(), findsOneWidget);
      expect(appShell(), findsNothing);
    });

    testWidgets(
      'AC4: skips the tutorial when already completed (later launch)',
      (tester) async {
        final c = makeContainer(InMemoryTongtaiOnboardingStore(true));
        await tester.pumpWidget(host(c));
        await tester.pumpAndSettle();

        expect(onboarding(), findsNothing);
        expect(appShell(), findsOneWidget);
      },
    );

    testWidgets(
      'AC4: finishing the tutorial persists + reveals the app shell',
      (tester) async {
        final store = InMemoryTongtaiOnboardingStore();
        final c = makeContainer(store);
        await tester.pumpWidget(host(c));
        await tester.pumpAndSettle();
        expect(onboarding(), findsOneWidget);

        // Tap Skip → gate should flip to the app shell and persist completion.
        await tester.tap(onboarding());
        await tester.pumpAndSettle();

        expect(onboarding(), findsNothing);
        expect(appShell(), findsOneWidget);
        expect(store.isCompleted(), isTrue); // stored locally
      },
    );

    testWidgets('AC5: resetting the flag re-triggers the tutorial', (
      tester,
    ) async {
      final store = InMemoryTongtaiOnboardingStore(true);
      final c = makeContainer(store);
      await tester.pumpWidget(host(c));
      await tester.pumpAndSettle();
      expect(appShell(), findsOneWidget); // starts on the app shell

      // Simulate the Settings "Replay Tutorial" action.
      await c.read(tongtaiOnboardingProvider.notifier).reset();
      await tester.pumpAndSettle();

      expect(onboarding(), findsOneWidget);
      expect(appShell(), findsNothing);
    });
  });

  // ── AC5: Settings "Replay Tutorial" entry point ───────────────────────────
  group('TongtaiMoreScreen replay entry (AC5)', () {
    testWidgets('tapping "Replay Tutorial" clears the completed flag', (
      tester,
    ) async {
      final store = InMemoryTongtaiOnboardingStore(true);
      final c = ProviderContainer(
        overrides: [tongtaiOnboardingStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: TongtaiMoreScreen()),
        ),
      );
      expect(c.read(tongtaiOnboardingProvider), isTrue);

      await tester.ensureVisible(find.text('Replay Tutorial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replay Tutorial'));
      await tester.pump();

      expect(c.read(tongtaiOnboardingProvider), isFalse);
      expect(store.isCompleted(), isFalse);
    });
  });
}
