import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_errors.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_models.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';

/// Tests for the xAI Grok BYOK client (WTM-61): it sends the right request,
/// parses a valid response, and maps every failure onto a friendly, bilingual
/// [TongtaiAiException] — invalid key (401 and xAI's 400), rate limit, quota,
/// server error, network, timeout, empty body and missing key.
http.Response _okCompletion(String text, {String? model}) =>
    http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'model': ?model,
          'choices': [
            {
              'message': {'role': 'assistant', 'content': text},
            },
          ],
          'usage': {'prompt_tokens': 7, 'completion_tokens': 3},
        }),
      ),
      200,
    );

http.Response _errBody(int status, Map<String, dynamic> body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  TongtaiAiClient clientWith(
    http.Client mock, {
    Future<String?> Function()? key,
  }) => TongtaiAiClient.xai(
    apiKey: key ?? () async => 'xai-SECRET-KEY-1234567890',
    client: mock,
  );

  group('chat — happy path', () {
    test(
      'posts to the xAI endpoint with bearer auth and correct body',
      () async {
        late http.Request captured;
        final mock = MockClient((req) async {
          captured = req;
          return _okCompletion('Xin chào', model: 'grok-3');
        });

        final res = await clientWith(mock).chat(
          messages: const [TongtaiAiMessage.user('hi')],
          systemPrompt: 'be helpful',
          temperature: 0.4,
          maxTokens: 128,
        );

        expect(captured.url.toString(), 'https://api.x.ai/v1/chat/completions');
        expect(
          captured.headers['Authorization'],
          'Bearer xai-SECRET-KEY-1234567890',
        );
        expect(captured.headers['Content-Type'], contains('application/json'));

        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['model'], 'grok-3');
        expect(body['temperature'], 0.4);
        expect(body['max_tokens'], 128);
        final messages = body['messages'] as List;
        expect((messages.first as Map)['role'], 'system');
        expect((messages.first as Map)['content'], 'be helpful');
        expect((messages.last as Map)['role'], 'user');
        expect((messages.last as Map)['content'], 'hi');

        expect(res.text, 'Xin chào');
        expect(res.model, 'grok-3');
        expect(res.provider, TongtaiAiProviderKind.xai);
        expect(res.inputTokens, 7);
        expect(res.outputTokens, 3);
      },
    );

    test(
      'omits system message, temperature and max_tokens when not given',
      () async {
        late http.Request captured;
        final mock = MockClient((req) async {
          captured = req;
          return _okCompletion('ok');
        });
        await clientWith(
          mock,
        ).chat(messages: const [TongtaiAiMessage.user('hi')]);
        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body.containsKey('temperature'), isFalse);
        expect(body.containsKey('max_tokens'), isFalse);
        expect((body['messages'] as List).single['role'], 'user');
        // Falls back to the provider default model.
        expect(body['model'], 'grok-3');
      },
    );

    test('an explicit model overrides the default', () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return _okCompletion('ok');
      });
      await clientWith(
        mock,
      ).chat(messages: const [TongtaiAiMessage.user('hi')], model: 'grok-4');
      expect((jsonDecode(captured.body) as Map)['model'], 'grok-4');
    });
  });

  group('testConnection', () {
    test('sends a tiny capped probe and returns the response', () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return _okCompletion('OK', model: 'grok-3');
      });
      final res = await clientWith(mock).testConnection();
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['max_tokens'], 5);
      expect(body['temperature'], 0);
      expect(res.text, 'OK');
      expect(res.model, 'grok-3');
    });
  });

  group('error mapping', () {
    Future<TongtaiAiException> caughtFrom(
      http.Client mock, {
      Future<String?> Function()? key,
    }) async {
      try {
        await clientWith(
          mock,
          key: key,
        ).chat(messages: const [TongtaiAiMessage.user('hi')]);
      } on TongtaiAiException catch (e) {
        return e;
      }
      fail('expected a TongtaiAiException');
    }

    test('missing key → missingKey (no HTTP call made)', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return _okCompletion('nope');
      });
      final e = await caughtFrom(mock, key: () async => '   ');
      expect(e.kind, TongtaiAiErrorKind.missingKey);
      expect(called, isFalse);
    });

    test('401 → invalidKey', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('', 401)),
      );
      expect(e.kind, TongtaiAiErrorKind.invalidKey);
    });

    test('403 → invalidKey', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('', 403)),
      );
      expect(e.kind, TongtaiAiErrorKind.invalidKey);
    });

    test('xAI 400 with a bad-key body → invalidKey', () async {
      final e = await caughtFrom(
        MockClient(
          (_) async => _errBody(400, {
            'code': 'invalid-argument',
            'error': 'Incorrect API key provided.',
          }),
        ),
      );
      expect(e.kind, TongtaiAiErrorKind.invalidKey);
    });

    test('400 without a key signal → badResponse', () async {
      final e = await caughtFrom(
        MockClient(
          (_) async =>
              _errBody(400, {'error': 'some other validation problem'}),
        ),
      );
      expect(e.kind, TongtaiAiErrorKind.badResponse);
    });

    test('429 → rateLimit', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('', 429)),
      );
      expect(e.kind, TongtaiAiErrorKind.rateLimit);
    });

    test('402 → quota', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('', 402)),
      );
      expect(e.kind, TongtaiAiErrorKind.quota);
    });

    test('500 → serverError', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('', 500)),
      );
      expect(e.kind, TongtaiAiErrorKind.serverError);
    });

    test('unexpected status → unknown', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('', 418)),
      );
      expect(e.kind, TongtaiAiErrorKind.unknown);
    });

    test('SocketException → network', () async {
      final e = await caughtFrom(
        MockClient((_) async => throw const SocketException('offline')),
      );
      expect(e.kind, TongtaiAiErrorKind.network);
    });

    test('ClientException → network', () async {
      final e = await caughtFrom(
        MockClient((_) async => throw http.ClientException('boom')),
      );
      expect(e.kind, TongtaiAiErrorKind.network);
    });

    test('TimeoutException → timeout', () async {
      final e = await caughtFrom(
        MockClient((_) async => throw TimeoutException('slow')),
      );
      expect(e.kind, TongtaiAiErrorKind.timeout);
    });

    test('a 200 with an empty answer → badResponse', () async {
      final e = await caughtFrom(MockClient((_) async => _okCompletion('   ')));
      expect(e.kind, TongtaiAiErrorKind.badResponse);
    });

    test('a 200 with an unparseable body → badResponse', () async {
      final e = await caughtFrom(
        MockClient((_) async => http.Response('not json', 200)),
      );
      expect(e.kind, TongtaiAiErrorKind.badResponse);
    });

    test('never echoes the provider body into the message', () async {
      final e = await caughtFrom(
        MockClient(
          (_) async =>
              http.Response('xai-LEAKED-KEY-IN-BODY should not surface', 401),
        ),
      );
      expect(e.messageEn, isNot(contains('LEAKED')));
    });
  });

  group('exception messages', () {
    test('every error kind has a bilingual, non-empty message', () {
      const all = [
        TongtaiAiException.missingKey,
        TongtaiAiException.invalidKey,
        TongtaiAiException.network,
        TongtaiAiException.timeout,
        TongtaiAiException.rateLimit,
        TongtaiAiException.quota,
        TongtaiAiException.serverError,
        TongtaiAiException.badResponse,
        TongtaiAiException.unknown,
      ];
      for (final e in all) {
        expect(e.messageEn, isNotEmpty);
        expect(e.messageVi, isNotEmpty);
        expect(e.message('vi'), e.messageVi);
        expect(e.message('en'), e.messageEn);
      }
    });
  });
}
