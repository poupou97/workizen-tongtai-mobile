import 'package:flutter/material.dart';
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
  // AC2 used to assert the six slide pages carried real EN+VI copy. WTM-178
  // deleted the slides; the equivalent guard now lives in
  // `tongtai_onboarding_conversation_test.dart`, which checks every option
  // code maps to a real enum value and every enum value has a chip.

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

  // AC1 + AC3 used to be covered by a six-slide tutorial widget. WTM-178
  // replaced it with a conversation; those tests now live in
  // `tongtai_onboarding_conversation_screen_test.dart`, and the slide screen
  // and its content file were deleted rather than left as dead code someone
  // could wire back by accident.

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

    Finder onboarding() => find.byKey(const Key('onboarding-v2-welcome'));
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

        // Đi đường ngắn nhất qua V2 → cổng lật sang shell và lưu cờ.
        await tester.tap(find.byKey(const Key('onboarding-v2-start')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('onboarding-v2-profile-skip-all')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('onboarding-v2-data-none')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('onboarding-v2-goal-next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('onboarding-v2-finish')));
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
