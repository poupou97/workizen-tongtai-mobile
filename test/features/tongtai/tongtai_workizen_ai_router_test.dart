import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_errors.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_models.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
import 'package:tongtai/features/tongtai/ai/workizen_ai_context.dart';
import 'package:tongtai/features/tongtai/ai/workizen_ai_router.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order_history_service.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/chat/chat_message.dart';

/// WTM-82 — Workizen AI Router (ADR-TON-006):
///  - AC1: rule-based query classification drives provider choice
///  - AC2: customer purchase history + segment injected into the system prompt
///  - AC3: product details injected for grounded recommendations
///  - AC4: tone instruction tailored to the customer's tier/segment
///  - AC5: rule-based offline fallback when no provider can answer
///
/// The router is exercised through the real [TongtaiAiService] with an
/// in-memory key store and a fake client factory — no HTTP anywhere.

/// Fake client honoring the WTM-61 injection seam. Records the request and
/// returns a canned reply (or throws) per provider.
class _FakeClient implements TongtaiAiClient {
  _FakeClient(this.provider, this.log, {required this.behavior});

  @override
  final TongtaiAiProviderKind provider;

  final List<_ChatCall> log;
  final Map<TongtaiAiProviderKind, Object> behavior; // String reply or error

  @override
  Future<String?> Function() get apiKey =>
      () async => 'unused';

  @override
  Future<TongtaiAiResponse> chat({
    required List<TongtaiAiMessage> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    log.add(_ChatCall(provider, messages, systemPrompt));
    final outcome = behavior[provider];
    if (outcome is TongtaiAiException) throw outcome;
    return TongtaiAiResponse(
      text: outcome as String? ?? 'reply-from-${provider.name}',
      provider: provider,
      model: model ?? provider.defaultModel,
    );
  }

  @override
  Future<TongtaiAiResponse> testConnection() =>
      chat(messages: const [TongtaiAiMessage.user('ping')]);
}

class _ChatCall {
  _ChatCall(this.provider, this.messages, this.systemPrompt);
  final TongtaiAiProviderKind provider;
  final List<TongtaiAiMessage> messages;
  final String? systemPrompt;
}

WorkizenAiContextBuilder sampleContext() => WorkizenAiContextBuilder(
  customers: kSampleCustomers,
  products: kSampleProducts,
  orderHistory: CustomerOrderHistoryService.sample(),
);

void main() {
  late InMemoryTongtaiAiKeyStore keys;
  late List<_ChatCall> calls;
  late Map<TongtaiAiProviderKind, Object> behavior;
  late WorkizenAiRouter router;

  WorkizenAiRouter makeRouter() {
    final service = TongtaiAiService(
      keys,
      clientFactory: (provider, _) =>
          _FakeClient(provider, calls, behavior: behavior),
    );
    // One-source (WTM-144): the builder no longer defaults to samples — tests
    // pass their fixtures explicitly.
    return WorkizenAiRouter(service: service, context: sampleContext());
  }

  setUp(() {
    keys = InMemoryTongtaiAiKeyStore();
    calls = [];
    behavior = {};
    router = makeRouter();
  });

  group('classifier (AC1)', () {
    test('analysis vocabulary (VI + EN) → complex', () {
      expect(
        classifyWorkizenQuery('Phân tích doanh thu tháng này'),
        WorkizenQueryClass.complex,
      );
      expect(
        classifyWorkizenQuery('Compare my two suppliers'),
        WorkizenQueryClass.complex,
      );
      expect(
        classifyWorkizenQuery('Nên làm gì để tăng đơn?'),
        WorkizenQueryClass.complex,
      );
    });

    test('long prompts → complex, short factual → simple', () {
      expect(classifyWorkizenQuery('x' * 250), WorkizenQueryClass.complex);
      expect(
        classifyWorkizenQuery('Tồn kho quạt còn bao nhiêu?'),
        WorkizenQueryClass.simple,
      );
    });
  });

  group('routing (AC1)', () {
    test(
      'complex query goes to the strongest enabled provider (xAI)',
      () async {
        await keys.write(TongtaiAiProviderKind.xai, 'xai-key');
        await keys.write(TongtaiAiProviderKind.cerebras, 'csk-key');

        final reply = await router.reply(
          const [],
          'Phân tích khách hàng giúp tôi',
        );

        expect(reply, 'reply-from-xai');
        expect(router.lastProvider, TongtaiAiProviderKind.xai);
      },
    );

    test('simple query prefers the fast/cheap provider (Cerebras)', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-key');
      await keys.write(TongtaiAiProviderKind.cerebras, 'csk-key');

      final reply = await router.reply(const [], 'Giá bán hiện tại?');

      expect(reply, 'reply-from-cerebras');
      expect(router.lastProvider, TongtaiAiProviderKind.cerebras);
    });

    test('providers without keys are skipped', () async {
      await keys.write(TongtaiAiProviderKind.openRouter, 'sk-or-key');

      await router.reply(const [], 'Phân tích nguồn hàng');

      expect(router.lastProvider, TongtaiAiProviderKind.openRouter);
      expect(calls.map((c) => c.provider), [TongtaiAiProviderKind.openRouter]);
    });

    test('a failing provider falls through to the next in the chain', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-key');
      await keys.write(TongtaiAiProviderKind.gemini, 'AIza-key');
      behavior[TongtaiAiProviderKind.xai] = TongtaiAiException.serverError;

      final reply = await router.reply(const [], 'So sánh hai nhà cung cấp');

      expect(reply, 'reply-from-gemini');
      expect(calls.map((c) => c.provider), [
        TongtaiAiProviderKind.xai,
        TongtaiAiProviderKind.gemini,
      ]);
    });

    test('Ollama needs no real key — an opt-in marker enables it', () async {
      expect(TongtaiAiProviderKind.ollama.requiresKey, isFalse);
      await keys.write(TongtaiAiProviderKind.ollama, 'local');

      final reply = await router.reply(const [], 'Tồn kho còn gì?');

      expect(reply, 'reply-from-ollama');
      expect(router.lastProvider, TongtaiAiProviderKind.ollama);
    });
  });

  group('fallback (AC5)', () {
    test('no enabled provider → deterministic rule-based reply', () async {
      final reply = await router.reply(const [], 'Xin chào');

      expect(router.lastProvider, isNull);
      expect(calls, isEmpty); // no network path was even attempted
      expect(reply, contains('Workizen AI'));
      expect(reply, contains('More → AI Assistant'));
    });

    test('every enabled provider failing → rule-based reply', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-key');
      behavior[TongtaiAiProviderKind.xai] = TongtaiAiException.network;

      final reply = await router.reply(const [], 'Phân tích đơn hàng');

      expect(router.lastProvider, isNull);
      expect(reply, contains('Workizen AI'));
    });

    test(
      'rule-based reply cites local data for a mentioned customer',
      () async {
        final fallback = RuleBasedChatResponder(context: sampleContext());
        final reply = await fallback.reply(const [], 'Phương Nguyễn mua gì?');
        expect(reply, contains('Phương Nguyễn'));
        expect(reply, contains('hạng'));
      },
    );
  });

  group('context injection (AC2/AC3/AC4)', () {
    // One-source (WTM-144): explicit sample fixtures — no sample defaults.
    final builder = sampleContext();

    test('always includes identity + business snapshot', () {
      final prompt = builder.build('Xin chào');
      expect(prompt, contains('Workizen AI'));
      expect(prompt, contains('Toàn cảnh kinh doanh'));
      expect(prompt, contains('Khách hàng:'));
      expect(prompt, contains('Sản phẩm:'));
    });

    test('AC2: mentioning a customer injects history + tier/segment', () {
      final prompt = builder.build('Phương Nguyễn dạo này thế nào?');
      expect(prompt, contains('Khách hàng được nhắc tới: Phương Nguyễn'));
      expect(prompt, contains('Hạng: VIP'));
      expect(prompt, contains('Đơn gần nhất'));
      expect(prompt, contains('DH-2026-0101')); // from sample order history
    });

    test('AC4: tone instruction follows the customer tier', () {
      final vip = builder.build('Tư vấn cho Phương Nguyễn'); // VIP sample
      expect(vip, contains('Giọng điệu: trang trọng'));

      final bronze = builder.build('Khách Hải Nam cần gì?'); // bronze sample
      expect(bronze, contains('Giọng điệu: chào mừng khách mới'));
    });

    test('AC3: mentioning a product injects price + stock', () {
      // kSampleProducts contains "Quạt mini cầm tay".
      final prompt = builder.build('Quạt mini cầm tay còn hàng không?');
      expect(prompt, contains('Sản phẩm được nhắc tới: Quạt mini cầm tay'));
      expect(prompt, contains('Giá bán:'));
      expect(prompt, contains('Tồn kho:'));
    });

    test('WTM-335 §14: a mentioned product injects its GROUPED attributes', () {
      // The grouped attribute context is injected as already-grouped text
      // (never a raw key/value dump), keyed by product id ('p01' = the fan).
      final grouped = WorkizenAiContextBuilder(
        products: kSampleProducts,
        productAttributeContext: const {
          'p01': '## Điện tử\n- Công suất: 350 W\n- Điện áp: 220 V',
        },
      );
      final prompt = grouped.build('Quạt mini cầm tay dùng điện áp nào?');
      expect(prompt, contains('## Điện tử'));
      expect(prompt, contains('- Công suất: 350 W'));
      expect(prompt, contains('- Điện áp: 220 V'));
      // No internal metadata leaks into the prompt.
      expect(prompt, isNot(contains('system.')));
      expect(prompt, isNot(contains('definitionId')));
    });

    test(
      'WTM-335 §14: no attribute context ⇒ no grouped block in the prompt',
      () {
        // The default (whole-business chat) leaves the map empty, so nothing is
        // appended — no dangling "## " heading.
        final prompt = builder.build('Quạt mini cầm tay còn hàng không?');
        expect(prompt, isNot(contains('## Điện tử')));
      },
    );

    test('router forwards the built system prompt to the provider', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-key');

      await router.reply(const [], 'Phân tích Phương Nguyễn');

      expect(calls.single.systemPrompt, contains('Phương Nguyễn'));
      expect(calls.single.systemPrompt, contains('Giọng điệu'));
    });
  });

  group('history mapping', () {
    ChatMessage turn(String id, ChatSender sender, String text) => ChatMessage(
      id: id,
      sender: sender,
      text: text,
      timestamp: DateTime(2026, 7, 23),
    );

    test('maps seller/assistant turns and keeps the prompt last', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-key');
      final history = [
        turn('1', ChatSender.seller, 'câu hỏi cũ'),
        turn('2', ChatSender.assistant, 'trả lời cũ'),
        turn('3', ChatSender.seller, 'phân tích tiếp'),
      ];

      await router.reply(history, 'phân tích tiếp');

      final sent = calls.single.messages;
      expect(sent.map((m) => m.role.name), ['user', 'assistant', 'user']);
      expect(sent.last.content, 'phân tích tiếp');
      // The final prompt is not duplicated.
      expect(sent.where((m) => m.content == 'phân tích tiếp'), hasLength(1));
    });

    test('only the last historyWindow turns are forwarded', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-key');
      final history = [
        for (var i = 0; i < 30; i++)
          turn('$i', ChatSender.seller, 'tin nhắn số $i — phân tích'),
      ];

      await router.reply(history, 'tin nhắn số 29 — phân tích');

      expect(calls.single.messages.length, router.historyWindow);
      expect(calls.single.messages.first.content, contains('số 18'));
    });
  });
}
