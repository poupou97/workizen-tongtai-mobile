import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_health_ai.dart';
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
import 'package:tongtai/features/tongtai/metrics/business_health.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_context.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_context.dart';

/// G-3D (WTM-137) — BusinessHealth AI is ASSESSMENT ONLY: the rule-based
/// health from the snapshot is attached verbatim on BOTH paths; the AI can
/// only annotate it, never change it. Rule-based stays the default fallback.
class _FakeClient implements TongtaiAiClient {
  _FakeClient(this.provider);

  @override
  final TongtaiAiProviderKind provider;

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
  }) async => TongtaiAiResponse(
    // A hostile answer claiming a different status — must NOT leak into
    // ruleHealth.
    text: 'AI nhận định: doanh nghiệp KHÔNG khỏe.',
    provider: provider,
    model: model ?? provider.defaultModel,
  );

  @override
  Future<TongtaiAiResponse> testConnection() =>
      chat(messages: const [TongtaiAiMessage.user('ping')]);
}

void main() {
  final now = DateTime(2026, 7, 29);
  DateTime clock() => now;

  CustomerOrder order(String id) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: DateTime(2026, 7, 10),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productName: 'X',
        category: 'Home',
        quantity: 1,
        unitPrice: 500000,
      ),
    ],
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

  BusinessHealthAiService service(
    BusinessContextService context, {
    bool withKey = false,
  }) {
    final keys = InMemoryTongtaiAiKeyStore();
    if (withKey) keys.write(TongtaiAiProviderKind.xai, 'xai-test-key');
    return BusinessHealthAiService(
      TongtaiAiService(keys, clientFactory: (p, _) => _FakeClient(p)),
      context,
      preference: const [TongtaiAiProviderKind.xai],
      clock: clock,
    );
  }

  group('ruleBasedHealthAssessment (twin)', () {
    test('explains the status with the snapshot signals', () async {
      final ctx = await contextService(orders: [order('o1')]).load();
      final text = ruleBasedHealthAssessment(ctx);
      expect(text, contains('Trạng thái: Khỏe mạnh'));
      expect(text, contains('500.000 ₫'));
      expect(text, contains('trạng thái hiển thị luôn do rule engine'));
      expect(text, ruleBasedHealthAssessment(ctx)); // deterministic
    });

    test('brand-new business → not-enough-data guidance', () async {
      final ctx = await contextService().load();
      expect(ruleBasedHealthAssessment(ctx), contains('Chưa đủ dữ liệu'));
    });
  });

  group('BusinessHealthAiService.assess (assessment only)', () {
    test('rule path: ruleHealth == the snapshot health', () async {
      final context = contextService(orders: [order('o1')]);
      final a = await service(context).assess(); // no key → rule twin

      expect(a.source, BusinessHealthAssessmentSource.rule);
      expect(a.ruleHealth, (await context.load()).health);
      expect(a.ruleHealth.status, BusinessHealthStatus.healthy);
    });

    test('AI path: the AI annotates but can NEVER change the status', () async {
      final context = contextService(orders: [order('o1')]);
      final a = await service(context, withKey: true).assess();

      expect(a.source, BusinessHealthAssessmentSource.ai);
      expect(a.provider, TongtaiAiProviderKind.xai);
      // The fake AI claimed "KHÔNG khỏe" — the authoritative status is still
      // the rule-based healthy read from the same snapshot.
      expect(a.text, contains('KHÔNG khỏe'));
      expect(a.ruleHealth.status, BusinessHealthStatus.healthy);
      expect(a.ruleHealth, (await context.load()).health);
    });
  });
}
