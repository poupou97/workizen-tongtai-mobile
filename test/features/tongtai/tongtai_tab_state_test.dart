import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/features/tongtai/tongtai.dart';

/// Real tests for Tab State Persistence & Scroll Memory (WTM-56).
///
/// Every acceptance criterion is exercised end-to-end:
///  - scroll offset restored across tab switches            (model + widget)
///  - form input preserved when navigating away & back      (model + widget)
///  - state cached in memory AND persisted to local storage (store + restart)
///  - manual refresh clears cache / resets tab to fresh data (controller)
///  - state cleaned up on logout / user-context switch       (controller)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TongtaiTabState model', () {
    test('default state is empty', () {
      const s = TongtaiTabState();
      expect(s.scrollOffset, 0.0);
      expect(s.formValues, isEmpty);
      expect(s.isEmpty, isTrue);
    });

    test('withFormValue adds/overwrites a field immutably', () {
      const s = TongtaiTabState();
      final a = s.withFormValue('note', 'hello');
      final b = a.withFormValue('note', 'world');
      expect(s.formValues, isEmpty); // original untouched
      expect(a.formValues['note'], 'hello');
      expect(b.formValues['note'], 'world');
      expect(b.isEmpty, isFalse);
    });

    test('withoutFormValue removes a field (no-op when absent)', () {
      final s = const TongtaiTabState().withFormValue('note', 'x');
      final removed = s.withoutFormValue('note');
      expect(removed.formValues.containsKey('note'), isFalse);
      // Removing an absent key returns an equal state.
      expect(removed.withoutFormValue('note'), removed);
    });

    test('copyWith updates scrollOffset only', () {
      final s = const TongtaiTabState().withFormValue('a', '1');
      final moved = s.copyWith(scrollOffset: 42.0);
      expect(moved.scrollOffset, 42.0);
      expect(moved.formValues['a'], '1');
    });

    test('toJson/fromJson round-trips', () {
      final s = const TongtaiTabState(
        scrollOffset: 120.5,
      ).withFormValue('name', 'Anh Tổng').withFormValue('qty', '7');
      final restored = TongtaiTabState.fromJson(s.toJson());
      expect(restored, s);
      expect(restored.scrollOffset, 120.5);
      expect(restored.formValues['name'], 'Anh Tổng');
    });

    test('fromJson tolerates malformed payloads', () {
      final s = TongtaiTabState.fromJson({
        'scrollOffset': 'not-a-number',
        'formValues': 'not-a-map',
      });
      expect(s.scrollOffset, 0.0);
      expect(s.formValues, isEmpty);
    });

    test('equality and hashCode are value-based', () {
      final a = const TongtaiTabState(scrollOffset: 10).withFormValue('k', 'v');
      final b = const TongtaiTabState(scrollOffset: 10).withFormValue('k', 'v');
      final c = const TongtaiTabState(scrollOffset: 11).withFormValue('k', 'v');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('InMemoryTongtaiTabStateStore', () {
    test('readAll is empty on a fresh store', () {
      expect(InMemoryTongtaiTabStateStore().readAll(), isEmpty);
    });

    test('writeAll then readAll round-trips', () async {
      final store = InMemoryTongtaiTabStateStore();
      final data = {
        TongtaiTabs.home: const TongtaiTabState(scrollOffset: 15),
        TongtaiTabs.producer: const TongtaiTabState().withFormValue('q', 'gao'),
      };
      await store.writeAll(data);
      expect(store.readAll(), data);
    });

    test('clear empties the store', () async {
      final store = InMemoryTongtaiTabStateStore({
        TongtaiTabs.home: const TongtaiTabState(scrollOffset: 5),
      });
      await store.clear();
      expect(store.readAll(), isEmpty);
    });
  });

  group('SharedPrefsTongtaiTabStateStore (local storage)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('persists across store instances (app-restart scenario)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final writer = SharedPrefsTongtaiTabStateStore(prefs);
      await writer.writeAll({
        TongtaiTabs.inventory: const TongtaiTabState(
          scrollOffset: 88.0,
        ).withFormValue('sku', 'ABC-123'),
      });

      // A brand-new store over the same prefs = a fresh app launch.
      final reader = SharedPrefsTongtaiTabStateStore(prefs);
      final restored = reader.readAll();
      expect(restored[TongtaiTabs.inventory]?.scrollOffset, 88.0);
      expect(restored[TongtaiTabs.inventory]?.formValues['sku'], 'ABC-123');
    });

    test('writeAll with empty map removes the persisted key', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsTongtaiTabStateStore(prefs);
      await store.writeAll({
        TongtaiTabs.home: const TongtaiTabState(scrollOffset: 3),
      });
      await store.writeAll({});
      expect(prefs.getString(TongtaiTabStateStore.storageKey), isNull);
      expect(store.readAll(), isEmpty);
    });

    test('corrupt payload is treated as empty, not a crash', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TongtaiTabStateStore.storageKey, 'not json {{{');
      final store = SharedPrefsTongtaiTabStateStore(prefs);
      expect(store.readAll(), isEmpty);
    });
  });

  group('TongtaiTabStateController', () {
    ProviderContainer makeContainer(TongtaiTabStateStore store) {
      final container = ProviderContainer(
        overrides: [tongtaiTabStateStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('AC1: scroll offset is remembered per tab', () async {
      final store = InMemoryTongtaiTabStateStore();
      final container = makeContainer(store);
      final ctrl = container.read(tongtaiTabStateProvider.notifier);

      await ctrl.saveScrollOffset(TongtaiTabs.producer, 250.0);

      expect(ctrl.stateFor(TongtaiTabs.producer).scrollOffset, 250.0);
      // Untouched tabs stay fresh.
      expect(ctrl.stateFor(TongtaiTabs.home).scrollOffset, 0.0);
    });

    test('AC1: negative offsets are clamped to zero', () async {
      final container = makeContainer(InMemoryTongtaiTabStateStore());
      final ctrl = container.read(tongtaiTabStateProvider.notifier);
      await ctrl.saveScrollOffset(TongtaiTabs.home, -30.0);
      expect(ctrl.stateFor(TongtaiTabs.home).scrollOffset, 0.0);
    });

    test('AC2: form values are preserved per tab + field', () async {
      final container = makeContainer(InMemoryTongtaiTabStateStore());
      final ctrl = container.read(tongtaiTabStateProvider.notifier);

      await ctrl.saveFormValue(TongtaiTabs.consumer, 'name', 'Chị Lan');
      await ctrl.saveFormValue(TongtaiTabs.consumer, 'phone', '0900');

      final s = ctrl.stateFor(TongtaiTabs.consumer);
      expect(s.formValues['name'], 'Chị Lan');
      expect(s.formValues['phone'], '0900');

      await ctrl.clearFormValue(TongtaiTabs.consumer, 'phone');
      expect(
        ctrl.stateFor(TongtaiTabs.consumer).formValues.containsKey('phone'),
        isFalse,
      );
      expect(ctrl.stateFor(TongtaiTabs.consumer).formValues['name'], 'Chị Lan');
    });

    test('AC3: state is written through to local storage', () async {
      final store = InMemoryTongtaiTabStateStore();
      final container = makeContainer(store);
      final ctrl = container.read(tongtaiTabStateProvider.notifier);

      await ctrl.saveScrollOffset(TongtaiTabs.inventory, 60.0);
      await ctrl.saveFormValue(TongtaiTabs.inventory, 'sku', 'X1');

      // Storage mirrors memory.
      expect(store.readAll()[TongtaiTabs.inventory]?.scrollOffset, 60.0);
      expect(store.readAll()[TongtaiTabs.inventory]?.formValues['sku'], 'X1');
    });

    test(
      'AC3: a fresh controller hydrates from persisted storage (restart)',
      () async {
        final store = InMemoryTongtaiTabStateStore();

        // Session 1: save some state.
        final c1 = makeContainer(store);
        await c1
            .read(tongtaiTabStateProvider.notifier)
            .saveScrollOffset(TongtaiTabs.home, 199.0);
        c1.dispose();

        // Session 2: brand new container over the same store = app restart.
        final c2 = makeContainer(store);
        final hydrated = c2.read(tongtaiTabStateProvider);
        expect(hydrated[TongtaiTabs.home]?.scrollOffset, 199.0);
      },
    );

    test('AC4: refreshTab clears that tab and resets to fresh data', () async {
      final store = InMemoryTongtaiTabStateStore();
      final container = makeContainer(store);
      final ctrl = container.read(tongtaiTabStateProvider.notifier);

      await ctrl.saveScrollOffset(TongtaiTabs.producer, 300.0);
      await ctrl.saveFormValue(TongtaiTabs.producer, 'q', 'draft');
      await ctrl.saveScrollOffset(TongtaiTabs.home, 10.0); // other tab

      await ctrl.refreshTab(TongtaiTabs.producer);

      // Refreshed tab is back to a fresh, empty state — in memory and storage.
      expect(ctrl.stateFor(TongtaiTabs.producer), const TongtaiTabState());
      expect(store.readAll().containsKey(TongtaiTabs.producer), isFalse);
      // Other tabs are unaffected.
      expect(ctrl.stateFor(TongtaiTabs.home).scrollOffset, 10.0);
    });

    test(
      'AC5: clearAll wipes memory + storage (logout / user switch)',
      () async {
        final store = InMemoryTongtaiTabStateStore();
        final container = makeContainer(store);
        final ctrl = container.read(tongtaiTabStateProvider.notifier);

        await ctrl.saveScrollOffset(TongtaiTabs.home, 40.0);
        await ctrl.saveFormValue(TongtaiTabs.consumer, 'name', 'A');

        await ctrl.clearAll();

        expect(container.read(tongtaiTabStateProvider), isEmpty);
        expect(store.readAll(), isEmpty);
      },
    );

    test(
      'empty states are pruned so storage does not grow unbounded',
      () async {
        final store = InMemoryTongtaiTabStateStore();
        final container = makeContainer(store);
        final ctrl = container.read(tongtaiTabStateProvider.notifier);

        // Set then reset a field back to nothing.
        await ctrl.saveFormValue(TongtaiTabs.home, 'note', 'x');
        await ctrl.clearFormValue(TongtaiTabs.home, 'note');

        expect(
          container.read(tongtaiTabStateProvider).containsKey(TongtaiTabs.home),
          isFalse,
        );
        expect(store.readAll(), isEmpty);
      },
    );
  });

  group('TongtaiPersistentScrollView widget', () {
    Widget host(ProviderContainer container, Widget child) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    ProviderContainer container(TongtaiTabStateStore store) {
      final c = ProviderContainer(
        overrides: [tongtaiTabStateStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      return c;
    }

    double offsetOf(WidgetTester tester) {
      final sv = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      return sv.controller!.offset;
    }

    testWidgets('restores a previously saved scroll offset on build', (
      tester,
    ) async {
      final store = InMemoryTongtaiTabStateStore({
        TongtaiTabs.home: const TongtaiTabState(scrollOffset: 250.0),
      });
      final c = container(store);

      await tester.pumpWidget(
        host(
          c,
          const SizedBox(
            height: 300,
            child: TongtaiPersistentScrollView(
              tabIndex: TongtaiTabs.home,
              child: SizedBox(height: 1000, child: Text('tall')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(offsetOf(tester), 250.0);
    });

    testWidgets('saves the offset back to the cache when scrolling settles', (
      tester,
    ) async {
      final store = InMemoryTongtaiTabStateStore();
      final c = container(store);

      await tester.pumpWidget(
        host(
          c,
          const SizedBox(
            height: 300,
            child: TongtaiPersistentScrollView(
              tabIndex: TongtaiTabs.producer,
              child: SizedBox(height: 1000, child: Text('tall')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      final saved = c
          .read(tongtaiTabStateProvider.notifier)
          .stateFor(TongtaiTabs.producer)
          .scrollOffset;
      expect(saved, greaterThan(0));
      expect(saved, offsetOf(tester));
    });

    testWidgets('scrolls back to top when the tab is refreshed', (
      tester,
    ) async {
      final store = InMemoryTongtaiTabStateStore({
        TongtaiTabs.home: const TongtaiTabState(scrollOffset: 250.0),
      });
      final c = container(store);

      await tester.pumpWidget(
        host(
          c,
          const SizedBox(
            height: 300,
            child: TongtaiPersistentScrollView(
              tabIndex: TongtaiTabs.home,
              child: SizedBox(height: 1000, child: Text('tall')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(offsetOf(tester), 250.0);

      await c
          .read(tongtaiTabStateProvider.notifier)
          .refreshTab(TongtaiTabs.home);
      await tester.pumpAndSettle();

      expect(offsetOf(tester), 0.0);
    });
  });

  group('TongtaiPersistentTextField widget', () {
    Widget host(ProviderContainer container, Widget child) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    ProviderContainer container(TongtaiTabStateStore store) {
      final c = ProviderContainer(
        overrides: [tongtaiTabStateStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('restores a previously entered value on build', (tester) async {
      final store = InMemoryTongtaiTabStateStore({
        TongtaiTabs.consumer: const TongtaiTabState().withFormValue(
          'name',
          'Chị Mai',
        ),
      });
      final c = container(store);

      await tester.pumpWidget(
        host(
          c,
          const TongtaiPersistentTextField(
            tabIndex: TongtaiTabs.consumer,
            fieldKey: 'name',
          ),
        ),
      );

      expect(find.text('Chị Mai'), findsOneWidget);
    });

    testWidgets('writes typed input back to the cache', (tester) async {
      final store = InMemoryTongtaiTabStateStore();
      final c = container(store);

      await tester.pumpWidget(
        host(
          c,
          const TongtaiPersistentTextField(
            tabIndex: TongtaiTabs.consumer,
            fieldKey: 'note',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'khách quen');
      await tester.pump();

      expect(
        c
            .read(tongtaiTabStateProvider.notifier)
            .stateFor(TongtaiTabs.consumer)
            .formValues['note'],
        'khách quen',
      );
    });

    testWidgets('clears the field when the tab is refreshed', (tester) async {
      final store = InMemoryTongtaiTabStateStore({
        TongtaiTabs.consumer: const TongtaiTabState().withFormValue(
          'note',
          'draft',
        ),
      });
      final c = container(store);

      await tester.pumpWidget(
        host(
          c,
          const TongtaiPersistentTextField(
            tabIndex: TongtaiTabs.consumer,
            fieldKey: 'note',
          ),
        ),
      );
      expect(find.text('draft'), findsOneWidget);

      await c
          .read(tongtaiTabStateProvider.notifier)
          .refreshTab(TongtaiTabs.consumer);
      await tester.pump();

      expect(find.text('draft'), findsNothing);
    });
  });
}
