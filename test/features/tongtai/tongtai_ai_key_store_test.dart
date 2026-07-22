import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';

/// Unit tests for the BYOK key store (WTM-61): the in-memory store round-trips a
/// key per provider, keeps providers isolated, and reports presence correctly.
void main() {
  group('InMemoryTongtaiAiKeyStore', () {
    late InMemoryTongtaiAiKeyStore store;

    setUp(() => store = InMemoryTongtaiAiKeyStore());

    test('starts empty', () async {
      expect(await store.read(TongtaiAiProviderKind.xai), isNull);
      expect(await store.hasKey(TongtaiAiProviderKind.xai), isFalse);
    });

    test('write then read returns the stored key', () async {
      await store.write(TongtaiAiProviderKind.xai, 'xai-abc');
      expect(await store.read(TongtaiAiProviderKind.xai), 'xai-abc');
      expect(await store.hasKey(TongtaiAiProviderKind.xai), isTrue);
    });

    test('write overwrites the previous value', () async {
      await store.write(TongtaiAiProviderKind.xai, 'xai-old');
      await store.write(TongtaiAiProviderKind.xai, 'xai-new');
      expect(await store.read(TongtaiAiProviderKind.xai), 'xai-new');
    });

    test('delete removes the key', () async {
      await store.write(TongtaiAiProviderKind.xai, 'xai-abc');
      await store.delete(TongtaiAiProviderKind.xai);
      expect(await store.read(TongtaiAiProviderKind.xai), isNull);
      expect(await store.hasKey(TongtaiAiProviderKind.xai), isFalse);
    });

    test('keys are isolated per provider', () async {
      await store.write(TongtaiAiProviderKind.xai, 'xai-key');
      await store.write(TongtaiAiProviderKind.openAI, 'sk-key');

      expect(await store.read(TongtaiAiProviderKind.xai), 'xai-key');
      expect(await store.read(TongtaiAiProviderKind.openAI), 'sk-key');
      expect(await store.read(TongtaiAiProviderKind.openRouter), isNull);

      await store.delete(TongtaiAiProviderKind.xai);
      // Deleting one provider leaves the other untouched.
      expect(await store.read(TongtaiAiProviderKind.xai), isNull);
      expect(await store.read(TongtaiAiProviderKind.openAI), 'sk-key');
    });

    test('hasKey is false for a whitespace-only value', () async {
      await store.write(TongtaiAiProviderKind.xai, '   ');
      expect(await store.hasKey(TongtaiAiProviderKind.xai), isFalse);
    });

    test('storage keys are namespaced per provider', () {
      expect(TongtaiAiProviderKind.xai.storageKey, 'tongtai.ai.xai.api_key');
      expect(
        TongtaiAiProviderKind.openAI.storageKey,
        'tongtai.ai.openAI.api_key',
      );
      expect(
        TongtaiAiProviderKind.xai.storageKey,
        isNot(TongtaiAiProviderKind.openRouter.storageKey),
      );
    });
  });
}
