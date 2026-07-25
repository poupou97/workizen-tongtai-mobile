import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/domain_snapshot.dart';

/// Direct unit tests for the shared, corrupt-tolerant persistence codec
/// (ADR-TON-009). This codec is now core infrastructure behind every Drift
/// repository (Inventory WTM-121, Consumer WTM-123, Journey WTM-124), so it is
/// tested here in isolation — not just indirectly through each repository.
void main() {
  group('encode/decode round-trip', () {
    test('encodes the version tag alongside the payload', () {
      final json = encodeDomainSnapshot({'a': 1, 'b': 'x'}, version: 3);
      final map = decodeDomainSnapshot(json);
      expect(snapshotVersion(map), 3);
      expect(snapshotInt(map, 'a'), 1);
      expect(snapshotString(map, 'b'), 'x');
    });

    test('defaults to version 1 when unspecified', () {
      expect(
        snapshotVersion(decodeDomainSnapshot(encodeDomainSnapshot({}))),
        1,
      );
    });
  });

  group('decodeDomainSnapshot tolerance', () {
    test('null / empty → {}', () {
      expect(decodeDomainSnapshot(null), isEmpty);
      expect(decodeDomainSnapshot(''), isEmpty);
    });

    test('corrupt JSON → {} (never throws)', () {
      expect(decodeDomainSnapshot('}{ not json'), isEmpty);
      expect(decodeDomainSnapshot('{"unterminated":'), isEmpty);
    });

    test('a non-object JSON value (array / scalar) → {}', () {
      expect(decodeDomainSnapshot('[1,2,3]'), isEmpty);
      expect(decodeDomainSnapshot('42'), isEmpty);
      expect(decodeDomainSnapshot('"a string"'), isEmpty);
    });
  });

  group('snapshotVersion', () {
    test('0 when absent or non-int', () {
      expect(snapshotVersion(const {}), 0);
      expect(snapshotVersion(const {'v': 'not-an-int'}), 0);
      expect(snapshotVersion(const {'v': 2}), 2);
    });
  });

  group('snapshotString', () {
    test('reads a string, defaults to empty', () {
      expect(snapshotString(const {'k': 'hi'}, 'k'), 'hi');
      expect(snapshotString(const {}, 'k'), '');
      expect(snapshotString(const {'k': 5}, 'k'), ''); // wrong type
    });
  });

  group('snapshotStringList', () {
    test('filters to strings, tolerant of missing / wrong types', () {
      expect(
        snapshotStringList(const {
          'k': ['a', 'b'],
        }, 'k'),
        ['a', 'b'],
      );
      expect(
        snapshotStringList(const {
          'k': ['a', 1, null, 'b'],
        }, 'k'),
        ['a', 'b'],
      );
      expect(snapshotStringList(const {}, 'k'), isEmpty);
      expect(snapshotStringList(const {'k': 'not-a-list'}, 'k'), isEmpty);
    });
  });

  group('snapshotInt', () {
    test('reads ints, rounds doubles, honours the fallback', () {
      expect(snapshotInt(const {'k': 7}, 'k'), 7);
      expect(snapshotInt(const {'k': 2.6}, 'k'), 3); // rounds
      expect(snapshotInt(const {}, 'k'), 0);
      expect(snapshotInt(const {}, 'k', fallback: -1), -1);
      expect(snapshotInt(const {'k': 'x'}, 'k', fallback: 9), 9);
    });
  });

  group('snapshotDouble', () {
    test('reads nums as double, honours the fallback', () {
      expect(snapshotDouble(const {'k': 2}, 'k'), 2.0);
      expect(snapshotDouble(const {'k': 3.5}, 'k'), 3.5);
      expect(snapshotDouble(const {}, 'k'), 0);
      expect(snapshotDouble(const {}, 'k', fallback: 1.5), 1.5);
      expect(snapshotDouble(const {'k': 'x'}, 'k', fallback: 9.0), 9.0);
    });
  });

  group('structured JSON-array column codec', () {
    test('encode/decode round-trips a string list', () {
      expect(decodeJsonStringList(encodeJsonStringList(['x', 'y'])), [
        'x',
        'y',
      ]);
    });

    test('decode is tolerant of null / empty / corrupt / non-array', () {
      expect(decodeJsonStringList(null), isEmpty);
      expect(decodeJsonStringList(''), isEmpty);
      expect(decodeJsonStringList('}{ nope'), isEmpty);
      expect(decodeJsonStringList('{"not":"an array"}'), isEmpty);
      expect(decodeJsonStringList('"scalar"'), isEmpty);
    });

    test('decode filters non-string elements', () {
      expect(decodeJsonStringList('["a", 1, null, "b"]'), ['a', 'b']);
    });
  });

  test('a v1 blob written today still reads under a future reader', () {
    // Forward-compatibility guard: fields are addressed by key, not position,
    // so adding keys later never invalidates an older blob.
    final json = encodeDomainSnapshot({
      'tags': ['a'],
      'notes': 'n',
      'count': 3,
    }, version: 1);
    final map = decodeDomainSnapshot(json);
    expect(snapshotStringList(map, 'tags'), ['a']);
    expect(snapshotString(map, 'notes'), 'n');
    expect(snapshotInt(map, 'count'), 3);
    // A key the writer never set simply reads as its default.
    expect(snapshotString(map, 'never_written'), '');
  });
}
