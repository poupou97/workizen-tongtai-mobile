import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_errors.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_validator.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_models.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';

/// Tests for the app-facing AI service (WTM-61): validate-before-store, retrieve,
/// presence, delete, and the live test/chat paths (with an injected HTTP mock so
/// no real network is touched).
http.Response _okCompletion(String text) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'model': 'grok-3',
      'choices': [
        {
          'message': {'role': 'assistant', 'content': text},
        },
      ],
    }),
  ),
  200,
);

void main() {
  final validKey = 'xai-${'k1L2m3N4' * 10}';
  late InMemoryTongtaiAiKeyStore store;

  setUp(() => store = InMemoryTongtaiAiKeyStore());

  TongtaiAiService serviceWith(http.Client mock) =>
      TongtaiAiService(store, httpClient: mock);

  group('saveKey', () {
    test('validates then stores the normalized key', () async {
      final service = TongtaiAiService(store);
      final result = await service.saveKey('  $validKey ');
      expect(result.ok, isTrue);
      // The trimmed value is what gets persisted.
      expect(await store.read(TongtaiAiProviderKind.xai), validKey);
      expect(await service.hasKey(), isTrue);
    });

    test('does NOT store an invalid key and returns the reason', () async {
      final service = TongtaiAiService(store);
      final result = await service.saveKey('too-short');
      expect(result.ok, isFalse);
      expect(result.issue, isNot(TongtaiAiKeyIssue.none));
      expect(await store.read(TongtaiAiProviderKind.xai), isNull);
      expect(await service.hasKey(), isFalse);
    });
  });

  group('loadKey / hasKey / deleteKey', () {
    test('loadKey returns the stored key or null', () async {
      final service = TongtaiAiService(store);
      expect(await service.loadKey(), isNull);
      await service.saveKey(validKey);
      expect(await service.loadKey(), validKey);
    });

    test('deleteKey clears the stored key', () async {
      final service = TongtaiAiService(store);
      await service.saveKey(validKey);
      await service.deleteKey();
      expect(await service.hasKey(), isFalse);
      expect(await service.loadKey(), isNull);
    });
  });

  group('testConnection', () {
    test('throws missingKey when no key is stored', () async {
      final service = serviceWith(MockClient((_) async => _okCompletion('OK')));
      expect(
        () => service.testConnection(),
        throwsA(
          isA<TongtaiAiException>().having(
            (e) => e.kind,
            'kind',
            TongtaiAiErrorKind.missingKey,
          ),
        ),
      );
    });

    test('uses the stored key and returns the response', () async {
      late String sentAuth;
      final service = serviceWith(
        MockClient((req) async {
          sentAuth = req.headers['Authorization'] ?? '';
          return _okCompletion('OK');
        }),
      );
      await service.saveKey(validKey);

      final res = await service.testConnection();
      expect(res.text, 'OK');
      expect(res.provider, TongtaiAiProviderKind.xai);
      expect(sentAuth, 'Bearer $validKey');
    });

    test('surfaces a friendly error from the provider', () async {
      final service = serviceWith(
        MockClient((_) async => http.Response('', 429)),
      );
      await service.saveKey(validKey);
      expect(
        () => service.testConnection(),
        throwsA(
          isA<TongtaiAiException>().having(
            (e) => e.kind,
            'kind',
            TongtaiAiErrorKind.rateLimit,
          ),
        ),
      );
    });
  });

  group('chat', () {
    test('throws missingKey when no key is stored', () async {
      final service = serviceWith(MockClient((_) async => _okCompletion('hi')));
      expect(
        () => service.chat(messages: const [TongtaiAiMessage.user('hi')]),
        throwsA(
          isA<TongtaiAiException>().having(
            (e) => e.kind,
            'kind',
            TongtaiAiErrorKind.missingKey,
          ),
        ),
      );
    });

    test('sends the conversation and returns the reply', () async {
      final service = serviceWith(
        MockClient((_) async => _okCompletion('Chào')),
      );
      await service.saveKey(validKey);
      final res = await service.chat(
        messages: const [TongtaiAiMessage.user('Hi')],
      );
      expect(res.text, 'Chào');
    });
  });

  group('clientFactory injection', () {
    test(
      'service routes through the custom client factory when provided',
      () async {
        var factoryCalls = 0;
        final service = TongtaiAiService(
          store,
          clientFactory: (provider, apiKey) {
            factoryCalls++;
            return TongtaiAiClient(
              provider: provider,
              apiKey: apiKey,
              client: MockClient((_) async => _okCompletion('via-factory')),
            );
          },
        );
        await service.saveKey(validKey);
        final res = await service.testConnection();
        expect(factoryCalls, 1);
        expect(res.text, 'via-factory');
      },
    );
  });
}
