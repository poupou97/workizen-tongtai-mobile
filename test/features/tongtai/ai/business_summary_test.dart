import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_summary.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_errors.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_models.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_context.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_context.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_context.dart';
import 'package:tongtai/features/tongtai/metrics/business_context_service.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_context.dart';

/// G-3A (WTM-116) — AI Business Summary:
///  - the AI's entire world is the serialized BusinessContext (ADR-TON-012);
///  - read-only, no mutation, no workflow;
///  - deterministic rule-based fallback when AI is off/offline;
///  - a brand-new business never spends a provider call.
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
      text: outcome as String? ?? 'summary-from-${provider.name}',
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

void main() {
  final now = DateTime(2026, 7, 29);
  DateTime clock() => now;

  CustomerOrder order(String id, {double total = 500000}) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: DateTime(2026, 7, 10),
    status: OrderStatus.delivered,
    items: [
      OrderItem(
        productName: 'X',
        category: 'Home',
        quantity: 1,
        unitPrice: total,
      ),
    ],
  );

  Customer customer(String id) => Customer(
    id: id,
    name: id,
    phone: '',
    location: '',
    orderCount: 1,
    totalSpent: 500000,
    lastPurchaseDate: null,
  );

  /// In-memory BusinessContextService — the same composition the app wires.
  BusinessContextService contextService({
    List<CustomerOrder> orders = const [],
    List<Customer> customers = const [],
  }) {
    final orderRepo = InMemoryOrderRepository(orders);
    final customerRepo = InMemoryCustomerRepository(customers);
    final productRepo = InMemoryProductRepository([]);
    final goalRepo = InMemoryBusinessGoalRepository();
    final financeRepo = InMemoryFinanceRepository();
    return BusinessContextService(
      BusinessMetricsService(orderRepo, customerRepo),
      CustomerContextProvider(customerRepo),
      OrderContextProvider(orderRepo),
      InventoryContextProvider(productRepo),
      OpportunityContextProvider(clock: clock),
      JourneyContextProvider(goalRepo, clock: clock),
      FinanceContextProvider(financeRepo, clock: clock),
      TimelineContextProvider(financeRepo, orderRepo, goalRepo, clock: clock),
      clock: clock,
    );
  }

  late InMemoryTongtaiAiKeyStore keys;
  late List<_ChatCall> calls;
  late Map<TongtaiAiProviderKind, Object> behavior;

  TongtaiAiService aiService() => TongtaiAiService(
    keys,
    clientFactory: (provider, _) =>
        _FakeClient(provider, calls, behavior: behavior),
  );

  BusinessSummaryService summaryService(BusinessContextService context) =>
      BusinessSummaryService(
        aiService(),
        context,
        preference: const [
          TongtaiAiProviderKind.xai,
          TongtaiAiProviderKind.gemini,
        ],
        clock: clock,
      );

  setUp(() {
    keys = InMemoryTongtaiAiKeyStore();
    calls = [];
    behavior = {};
  });

  group('businessContextPromptText (the AI boundary, serialized)', () {
    test('carries the snapshot figures and health', () async {
      final ctx = await contextService(
        orders: [order('o1', total: 500000)],
        customers: [customer('c1')],
      ).load();
      final text = businessContextPromptText(ctx);

      expect(text, contains('Business Snapshot (v${ctx.version})'));
      expect(text, contains('500.000 ₫')); // revenue
      expect(text, contains('Đơn hàng: 1'));
      expect(text, contains('Khách hàng: 1'));
      expect(text, contains('Sức khỏe:')); // embedded health read
    });
  });

  group('ruleBasedBusinessSummary (AI-off/offline)', () {
    test('brand-new business → onboarding text, deterministic', () async {
      final ctx = await contextService().load();
      final text = ruleBasedBusinessSummary(ctx);
      expect(text, contains('Chưa đủ dữ liệu'));
      expect(text, ruleBasedBusinessSummary(ctx)); // pure
    });

    test('a business with sales → revenue headline', () async {
      final ctx = await contextService(
        orders: [order('o1', total: 500000)],
        customers: [customer('c1')],
      ).load();
      expect(ruleBasedBusinessSummary(ctx), contains('500.000 ₫'));
    });
  });

  group('BusinessSummaryService.summarize', () {
    test('no provider enabled → rule-based fallback', () async {
      final s = await summaryService(
        contextService(orders: [order('o1')], customers: [customer('c1')]),
      ).summarize();

      expect(s.source, BusinessSummarySource.rule);
      expect(s.isAi, isFalse);
      expect(s.generatedAt, now);
      expect(calls, isEmpty); // no key → the provider is never touched
    });

    test(
      'enabled provider answers — and sees ONLY the BusinessContext',
      () async {
        await keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
        behavior[TongtaiAiProviderKind.xai] = 'Tóm tắt AI đây.';

        final context = contextService(
          orders: [order('o1', total: 500000)],
          customers: [customer('c1')],
        );
        final s = await summaryService(context).summarize();

        expect(s.source, BusinessSummarySource.ai);
        expect(s.provider, TongtaiAiProviderKind.xai);
        expect(s.text, 'Tóm tắt AI đây.');

        // The AI boundary, proven: exactly one user message, and it is exactly
        // the serialized BusinessContext — nothing else reaches the provider.
        final call = calls.single;
        expect(call.messages, hasLength(1));
        expect(
          call.messages.single.content,
          businessContextPromptText(await context.load()),
        );
        expect(call.systemPrompt, contains('Workizen AI'));
      },
    );

    test('a failing provider falls through the chain', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
      await keys.write(TongtaiAiProviderKind.gemini, 'AIza-test-key');
      behavior[TongtaiAiProviderKind.xai] = TongtaiAiException.network;
      behavior[TongtaiAiProviderKind.gemini] = 'Gemini tóm tắt.';

      final s = await summaryService(
        contextService(orders: [order('o1')], customers: [customer('c1')]),
      ).summarize();

      expect(s.source, BusinessSummarySource.ai);
      expect(s.provider, TongtaiAiProviderKind.gemini);
      expect(s.text, 'Gemini tóm tắt.');
    });

    test('every provider failing → rule-based fallback', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
      behavior[TongtaiAiProviderKind.xai] = TongtaiAiException.network;

      final s = await summaryService(
        contextService(orders: [order('o1')], customers: [customer('c1')]),
      ).summarize();

      expect(s.source, BusinessSummarySource.rule);
    });

    test('a brand-new business never spends a provider call', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
      behavior[TongtaiAiProviderKind.xai] = 'should never be used';

      final s = await summaryService(contextService()).summarize();

      expect(s.source, BusinessSummarySource.rule);
      expect(s.text, contains('Chưa đủ dữ liệu'));
      expect(calls, isEmpty); // hasData=false → no paid call
    });
  });
}
