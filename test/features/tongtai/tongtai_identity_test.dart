import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:tongtai/features/tongtai/identity/tongtai_identity_service.dart';
import 'package:tongtai/features/tongtai/identity/tongtai_identity_store.dart';

/// Real tests for the Tổng Tài local identity (WTM-58), using an in-memory
/// store so no platform channels / secure storage are required.
void main() {
  late InMemoryTongtaiIdentityStore store;
  late TongtaiIdentityService service;

  setUp(() {
    store = InMemoryTongtaiIdentityStore();
    service = TongtaiIdentityService(store);
  });

  test('generates a valid v4 UUID on first call', () async {
    final id = await service.getOrCreateUserId();
    expect(id.length, 36);
    expect(Uuid.isValidUUID(fromString: id), isTrue);
    // v4 marker in the 15th character.
    expect(id[14], '4');
  });

  test('persists the id to the store', () async {
    final id = await service.getOrCreateUserId();
    expect(await store.read(), id);
  });

  test(
    'returns the same id across calls (idempotent, no regeneration)',
    () async {
      final first = await service.getOrCreateUserId();
      final second = await service.getOrCreateUserId();
      final third = await service.getOrCreateUserId();
      expect(second, first);
      expect(third, first);
    },
  );

  test('reuses an id already present in the store', () async {
    const existing = '11111111-1111-4111-8111-111111111111';
    await store.write(existing);
    final id = await service.getOrCreateUserId();
    expect(id, existing);
  });

  test('replaces a corrupt (invalid) stored value with a fresh UUID', () async {
    await store.write('not-a-uuid');
    final id = await service.getOrCreateUserId();
    expect(TongtaiIdentityService.isValid(id), isTrue);
    expect(id, isNot('not-a-uuid'));
    expect(await store.read(), id);
  });

  test('isValid rejects malformed ids', () {
    expect(TongtaiIdentityService.isValid('too-short'), isFalse);
    expect(TongtaiIdentityService.isValid(''), isFalse);
    expect(
      TongtaiIdentityService.isValid('11111111-1111-4111-8111-111111111111'),
      isTrue,
    );
  });
}
