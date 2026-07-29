import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_recommendation.dart';
import 'package:tongtai/features/tongtai/ai/business_summary.dart'
    show businessContextPromptText;
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
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
import 'package:tongtai/features/tongtai/inventory/product.dart';
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

/// G-3B (WTM-135) — AI Recommendation: suggestions only, no mutation, never
/// executed; same engine invariants as G-3A (context-only boundary, rule twin,
/// zero-spend on an empty business).
class _FakeClient implements TongtaiAiClient {
  _FakeClient(this.provider, this.log);

  @override
  final TongtaiAiProviderKind provider;

  final List<List<TongtaiAiMessage>> log;

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
    log.add(messages);
    return TongtaiAiResponse(
      text: 'AI gợi ý: đẩy combo cuối tuần.',
      provider: provider,
      model: model ?? provider.defaultModel,
    );
  }

  @override
  Future<TongtaiAiResponse> testConnection() =>
      chat(messages: const [TongtaiAiMessage.user('ping')]);
}

void main() {
  final now = DateTime(2026, 7, 29);
  DateTime clock() => now;

  CustomerOrder order(String id, {OrderStatus status = OrderStatus.pending}) =>
      CustomerOrder(
        id: id,
        customerId: 'c1',
        orderNumber: 'DH-$id',
        date: DateTime(2026, 7, 10),
        status: status,
        items: const [
          OrderItem(
            productName: 'X',
            category: 'Home',
            quantity: 1,
            unitPrice: 500000,
          ),
        ],
      );

  Product product(String id, {int qty = 0, int reorder = 3}) => Product(
    id: id,
    sku: 'SKU-$id',
    name: id,
    category: 'Home',
    quantity: qty,
    pricePerUnit: 10000,
    reorderLevel: reorder,
    updatedAt: DateTime(2026, 7, 1),
  );

  BusinessContextService contextService({
    List<CustomerOrder> orders = const [],
    List<Product> products = const [],
  }) {
    final orderRepo = InMemoryOrderRepository(orders);
    final customerRepo = InMemoryCustomerRepository([
      if (orders.isNotEmpty)
        Customer(
          id: 'c1',
          name: 'Thu Hà',
          phone: '',
          location: '',
          orderCount: 1,
          totalSpent: 500000,
          lastPurchaseDate: null,
        ),
    ]);
    final goalRepo = InMemoryBusinessGoalRepository();
    final financeRepo = InMemoryFinanceRepository();
    return BusinessContextService(
      BusinessMetricsService(orderRepo, customerRepo),
      CustomerContextProvider(customerRepo),
      OrderContextProvider(orderRepo),
      InventoryContextProvider(InMemoryProductRepository(products)),
      OpportunityContextProvider(clock: clock),
      JourneyContextProvider(goalRepo, clock: clock),
      FinanceContextProvider(financeRepo, clock: clock),
      TimelineContextProvider(financeRepo, orderRepo, goalRepo, clock: clock),
      clock: clock,
    );
  }

  late InMemoryTongtaiAiKeyStore keys;
  late List<List<TongtaiAiMessage>> calls;

  BusinessRecommendationService service(BusinessContextService context) =>
      BusinessRecommendationService(
        TongtaiAiService(
          keys,
          clientFactory: (provider, _) => _FakeClient(provider, calls),
        ),
        context,
        preference: const [TongtaiAiProviderKind.xai],
        clock: clock,
      );

  setUp(() {
    keys = InMemoryTongtaiAiKeyStore();
    calls = [];
  });

  group('ruleBasedBusinessRecommendations (AI-off twin)', () {
    test('brand-new business → onboarding text', () async {
      final ctx = await contextService().load();
      expect(
        ruleBasedBusinessRecommendations(ctx),
        contains('Chưa có dữ liệu'),
      );
    });

    test('signals become actionable bullets (open orders + stock)', () async {
      final ctx = await contextService(
        orders: [order('o1')], // pending → open
        products: [product('p-out', qty: 0), product('p-low', qty: 2)],
      ).load();
      final text = ruleBasedBusinessRecommendations(ctx);

      expect(text, contains('1 đơn đang mở'));
      expect(text, contains('1 sản phẩm đã hết hàng'));
      expect(text, contains('1 sản phẩm sắp hết'));
      expect(text, ruleBasedBusinessRecommendations(ctx)); // deterministic
    });
  });

  group('BusinessRecommendationService.recommend', () {
    test('no provider enabled → rule twin, suggestions only', () async {
      final r = await service(
        contextService(orders: [order('o1')]),
      ).recommend();
      expect(r.source, BusinessRecommendationSource.rule);
      expect(r.isAi, isFalse);
      expect(r.generatedAt, now);
      expect(calls, isEmpty);
    });

    test(
      'enabled provider answers — and sees ONLY the BusinessContext',
      () async {
        await keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
        final context = contextService(orders: [order('o1')]);

        final r = await service(context).recommend();

        expect(r.source, BusinessRecommendationSource.ai);
        expect(r.provider, TongtaiAiProviderKind.xai);
        expect(r.text, 'AI gợi ý: đẩy combo cuối tuần.');
        // Boundary: exactly one user message, byte-equal to the serialized
        // snapshot — nothing else ever reaches the provider.
        expect(calls.single, hasLength(1));
        expect(
          calls.single.single.content,
          businessContextPromptText(await context.load()),
        );
      },
    );

    test('a brand-new business never spends a provider call', () async {
      await keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
      final r = await service(contextService()).recommend();
      expect(r.source, BusinessRecommendationSource.rule);
      expect(calls, isEmpty);
    });
  });
}
