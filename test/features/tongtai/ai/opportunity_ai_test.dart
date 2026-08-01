import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_summary.dart'
    show businessContextPromptText;
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/ai/opportunity_ai.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_models.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
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
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_context.dart';

/// WTM-141 — the Opportunity AI layer annotates a rule-generated opportunity
/// (explanation + optional AI score). The rule score stays authoritative; the
/// rule twin answers AI-off/offline.
class _FakeClient implements TongtaiAiClient {
  _FakeClient(this.provider, this.log, {required this.reply});

  @override
  final TongtaiAiProviderKind provider;

  final List<List<TongtaiAiMessage>> log;
  final String reply;

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
      text: reply,
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

  final opportunity = Opportunity(
    id: 'gen-restock-p1',
    type: OpportunityType.trend,
    title: 'Nhập lại Quạt mini (đã hết hàng)',
    description: 'Bán chạy nhưng đã hết hàng.',
    expectedImpact: 800000,
    score: OpportunityScore.fixed(85),
    discoveredAt: DateTime(2026, 7, 29),
  );

  BusinessContextService contextService({
    List<CustomerOrder> orders = const [],
  }) {
    final orderRepo = InMemoryOrderRepository(orders);
    final customerRepo = InMemoryCustomerRepository([]);
    final goalRepo = InMemoryBusinessGoalRepository();
    final financeRepo = InMemoryFinanceRepository();
    return BusinessContextService(
      BusinessMetricsService(orderRepo, customerRepo),
      CustomerContextProvider(customerRepo),
      OrderContextProvider(orderRepo),
      InventoryContextProvider(InMemoryProductRepository([])),
      OpportunityContextProvider(clock: clock),
      JourneyContextProvider(goalRepo, clock: clock),
      FinanceContextProvider(financeRepo, clock: clock),
      TimelineContextProvider(financeRepo, orderRepo, goalRepo, clock: clock),
      clock: clock,
    );
  }

  CustomerOrder order(String id) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: DateTime(2026, 7, 10),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productName: 'Quạt mini',
        category: 'Home',
        quantity: 1,
        unitPrice: 800000,
      ),
    ],
  );

  group('parseAiScore', () {
    test('parses and clamps the trailing score line', () {
      expect(parseAiScore('… phân tích …\nĐIỂM: 72'), 72);
      expect(parseAiScore('ĐIỂM: 999'), 100); // clamped
      expect(parseAiScore('không có dòng điểm'), isNull);
    });
  });

  group('OpportunityAiService.explain', () {
    OpportunityAiService service(
      BusinessContextService context, {
      bool withKey = false,
      String reply = 'Đáng làm.\nĐIỂM: 72',
      List<List<TongtaiAiMessage>>? log,
    }) {
      final keys = InMemoryTongtaiAiKeyStore();
      if (withKey) keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
      return OpportunityAiService(
        TongtaiAiService(
          keys,
          clientFactory: (p, _) => _FakeClient(p, log ?? [], reply: reply),
        ),
        context,
        preference: const [TongtaiAiProviderKind.xai],
        clock: clock,
      );
    }

    test('no provider → rule twin; AI score = the rule score', () async {
      final insight = await service(
        contextService(orders: [order('o1')]),
      ).explain(opportunity);

      expect(insight.source, OpportunityAiInsightSource.rule);
      expect(insight.aiScore, 85); // the authoritative rule score
      expect(insight.text, contains('85/100'));
      expect(insight.generatedAt, now);
    });

    test(
      'AI path: input = snapshot + opportunity block; score parsed',
      () async {
        final log = <List<TongtaiAiMessage>>[];
        final context = contextService(orders: [order('o1')]);
        final insight = await service(
          context,
          withKey: true,
          log: log,
        ).explain(opportunity);

        expect(insight.source, OpportunityAiInsightSource.ai);
        expect(insight.provider, TongtaiAiProviderKind.xai);
        expect(insight.aiScore, 72);
        // The provider sees exactly the snapshot + the rule-generated
        // opportunity block — no repository data beyond the context.
        final input = log.single.single.content;
        expect(
          input,
          startsWith(businessContextPromptText(await context.load())),
        );
        expect(input, contains(opportunityPromptBlock(opportunity)));
      },
    );

    test('unparsable AI answer → insight without an AI score', () async {
      final insight = await service(
        contextService(orders: [order('o1')]),
        withKey: true,
        reply: 'Phân tích nhưng quên dòng điểm.',
      ).explain(opportunity);

      expect(insight.source, OpportunityAiInsightSource.ai);
      expect(insight.aiScore, isNull);
    });
  });
}
