import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_ai_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_ai_key_screen.dart';

/// Widget tests for the WTM-61 AI key screen: pasting an invalid key shows an
/// error and stores nothing; a valid key is saved and flips the screen to the
/// "key set" state with Test/Remove enabled; Test connection surfaces success
/// and friendly failure banners; Remove clears the key.
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
  final validKey = 'xai-${'A1b2C3d4' * 10}';

  /// Pumps the screen with a service backed by an in-memory store and the given
  /// HTTP mock, so nothing hits real secure storage or the network.
  Future<InMemoryTongtaiAiKeyStore> pumpScreen(
    WidgetTester tester, {
    required http.Client httpClient,
    InMemoryTongtaiAiKeyStore? store,
  }) async {
    final backing = store ?? InMemoryTongtaiAiKeyStore();
    final service = TongtaiAiService(backing, httpClient: httpClient);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tongtaiAiServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: TongtaiAiKeyScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return backing;
  }

  testWidgets('renders the key field and Save button', (tester) async {
    await pumpScreen(
      tester,
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    expect(find.byKey(const Key('ai-key-field')), findsOneWidget);
    expect(find.byKey(const Key('ai-key-action-save')), findsOneWidget);
    expect(find.text('AI Assistant'), findsOneWidget);
  });

  testWidgets('an invalid key shows an inline error and is not stored', (
    tester,
  ) async {
    final store = await pumpScreen(
      tester,
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    await tester.enterText(find.byKey(const Key('ai-key-field')), 'too-short');
    await tester.tap(find.byKey(const Key('ai-key-action-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('too short'), findsOneWidget);
    expect(await store.hasKey(TongtaiAiProviderKind.xai), isFalse);
  });

  testWidgets('a valid key is saved and flips to the key-set state', (
    tester,
  ) async {
    final store = await pumpScreen(
      tester,
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    await tester.enterText(find.byKey(const Key('ai-key-field')), validKey);
    await tester.tap(find.byKey(const Key('ai-key-action-save')));
    await tester.pumpAndSettle();

    // Persisted, and the confirmation + set-state UI is shown.
    expect(await store.read(TongtaiAiProviderKind.xai), validKey);
    expect(find.text('API key saved securely.'), findsOneWidget);
    expect(find.textContaining('An API key is stored'), findsOneWidget);
    expect(find.byKey(const Key('ai-key-action-delete')), findsOneWidget);

    // Test connection is enabled now that a key is stored.
    final testBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('ai-key-action-test')),
    );
    expect(testBtn.onPressed, isNotNull);
  });

  testWidgets('Test connection shows a success banner on a good key', (
    tester,
  ) async {
    final store = InMemoryTongtaiAiKeyStore()
      ..write(TongtaiAiProviderKind.xai, validKey);
    await pumpScreen(
      tester,
      store: store,
      httpClient: MockClient((_) async => _okCompletion('OK')),
    );

    await tester.tap(find.byKey(const Key('ai-key-action-test')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Connection OK'), findsOneWidget);
  });

  testWidgets('Test connection shows a friendly error on a bad key', (
    tester,
  ) async {
    final store = InMemoryTongtaiAiKeyStore()
      ..write(TongtaiAiProviderKind.xai, validKey);
    await pumpScreen(
      tester,
      store: store,
      httpClient: MockClient((_) async => http.Response('', 401)),
    );

    await tester.tap(find.byKey(const Key('ai-key-action-test')));
    await tester.pumpAndSettle();

    expect(find.textContaining('key seems invalid'), findsOneWidget);
  });

  testWidgets('Remove key clears the stored key', (tester) async {
    final store = InMemoryTongtaiAiKeyStore()
      ..write(TongtaiAiProviderKind.xai, validKey);
    await pumpScreen(
      tester,
      store: store,
      httpClient: MockClient((_) async => http.Response('', 404)),
    );

    expect(find.byKey(const Key('ai-key-action-delete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-key-action-delete')));
    await tester.pumpAndSettle();

    expect(await store.hasKey(TongtaiAiProviderKind.xai), isFalse);
    expect(find.text('API key removed.'), findsOneWidget);
    // Delete button is gone once there is no key.
    expect(find.byKey(const Key('ai-key-action-delete')), findsNothing);
  });

  testWidgets('visibility toggle unmasks the field', (tester) async {
    await pumpScreen(
      tester,
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    TextField field() =>
        tester.widget<TextField>(find.byKey(const Key('ai-key-field')));
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('ai-key-action-visibility')));
    await tester.pumpAndSettle();
    expect(field().obscureText, isFalse);
  });

  group('WTM-83 — rotate + QR scan', () {
    final newKey = 'xai-${'Q9w8E7r6' * 10}';

    testWidgets('rotate: verified new key replaces the old one', (
      tester,
    ) async {
      final store = InMemoryTongtaiAiKeyStore();
      await store.write(TongtaiAiProviderKind.xai, validKey);
      await pumpScreen(
        tester,
        httpClient: MockClient((_) async => _okCompletion('grok-3')),
        store: store,
      );

      await tester.enterText(find.byKey(const Key('ai-key-field')), newKey);
      await tester.tap(find.byKey(const Key('ai-key-action-rotate')));
      await tester.pumpAndSettle();

      expect(await store.read(TongtaiAiProviderKind.xai), newKey);
      expect(find.textContaining('Key rotated'), findsOneWidget);
    });

    testWidgets('rotate: a dead new key rolls back to the working key', (
      tester,
    ) async {
      final store = InMemoryTongtaiAiKeyStore();
      await store.write(TongtaiAiProviderKind.xai, validKey);
      await pumpScreen(
        tester,
        httpClient: MockClient((_) async => http.Response('unauthorized', 401)),
        store: store,
      );

      await tester.enterText(find.byKey(const Key('ai-key-field')), newKey);
      await tester.tap(find.byKey(const Key('ai-key-action-rotate')));
      await tester.pumpAndSettle();

      // The broken key never sticks — the working key is restored.
      expect(await store.read(TongtaiAiProviderKind.xai), validKey);
      expect(find.textContaining('The old key was restored'), findsOneWidget);
    });

    testWidgets('QR scan fills the field through the launcher seam', (
      tester,
    ) async {
      final service = TongtaiAiService(
        InMemoryTongtaiAiKeyStore(),
        httpClient: MockClient((_) async => http.Response('', 404)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tongtaiAiServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            home: TongtaiAiKeyScreen(
              scanLauncher: (_) async => '  $newKey  ', // untrimmed on purpose
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai-key-action-scan')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('ai-key-field')),
      );
      expect(field.controller!.text, newKey); // trimmed
      expect(find.textContaining('scanned'), findsOneWidget);
    });
  });
}
