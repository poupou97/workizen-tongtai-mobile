import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_history_store.dart';

/// Tests for the WTM-73 recent-search history: the pure fold rules
/// (order/dedup/cap/blank), the in-memory fake and the real SharedPreferences
/// implementation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('foldSearchHistory (pure)', () {
    test('a new query goes to the front, most-recent-first', () {
      expect(
        foldSearchHistory(['pho', 'coffee'], 'tea'),
        ['tea', 'pho', 'coffee'],
      );
    });

    test('a repeat is moved to the front, not duplicated', () {
      expect(
        foldSearchHistory(['pho', 'coffee', 'tea'], 'coffee'),
        ['coffee', 'pho', 'tea'],
      );
    });

    test('the repeat match is case-insensitive', () {
      expect(
        foldSearchHistory(['Coffee'], 'coffee'),
        ['coffee'],
      );
    });

    test('a blank query leaves history unchanged', () {
      expect(foldSearchHistory(['pho'], '   '), ['pho']);
    });

    test('the query is trimmed before storing', () {
      expect(foldSearchHistory(const [], '  pho  '), ['pho']);
    });

    test('history is capped at the limit', () {
      final current = ['a', 'b', 'c'];
      expect(
        foldSearchHistory(current, 'new', limit: 3),
        ['new', 'a', 'b'],
      );
    });
  });

  group('InMemoryTongtaiSearchHistoryStore', () {
    test('add returns the updated list and load reflects it', () async {
      final store = InMemoryTongtaiSearchHistoryStore();
      expect(await store.load(), isEmpty);

      final afterFirst = await store.add('coffee');
      expect(afterFirst, ['coffee']);

      final afterSecond = await store.add('tea');
      expect(afterSecond, ['tea', 'coffee']);
      expect(await store.load(), ['tea', 'coffee']);
    });

    test('clear empties the history', () async {
      final store = InMemoryTongtaiSearchHistoryStore(seed: ['a', 'b']);
      await store.clear();
      expect(await store.load(), isEmpty);
    });

    test('respects a custom limit', () async {
      final store = InMemoryTongtaiSearchHistoryStore(limit: 2);
      await store.add('a');
      await store.add('b');
      await store.add('c');
      expect(await store.load(), ['c', 'b']);
    });
  });

  group('SharedPrefsTongtaiSearchHistoryStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('persists across store instances (same SharedPreferences)', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsTongtaiSearchHistoryStore(prefs);

      await store.add('pho');
      await store.add('coffee');

      // A fresh store over the same prefs sees the persisted list.
      final reopened = SharedPrefsTongtaiSearchHistoryStore(prefs);
      expect(await reopened.load(), ['coffee', 'pho']);
    });

    test('clear removes the persisted key', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsTongtaiSearchHistoryStore(prefs);
      await store.add('pho');
      await store.clear();
      expect(await store.load(), isEmpty);
      expect(prefs.containsKey(TongtaiSearchHistoryStore.storageKey), isFalse);
    });
  });
}
