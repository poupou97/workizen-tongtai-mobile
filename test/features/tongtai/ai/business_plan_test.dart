import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_plan.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
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

/// G-3C (WTM-136) — AI Planner: generates plan/tasks/roadmap text; NEVER
/// executed. Engine invariants (context-only boundary, chain, zero-spend) are
/// covered by the G-3A/G-3B suites over the same BusinessAiEngine; this suite
/// pins the planner's rule twin ordering + the service's provenance.
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

  Product product(String id, {int qty = 0}) => Product(
    id: id,
    sku: 'SKU-$id',
    name: id,
    category: 'Home',
    quantity: qty,
    pricePerUnit: 10000,
    reorderLevel: 3,
    updatedAt: DateTime(2026, 7, 1),
  );

  BusinessContextService contextService({
    List<CustomerOrder> orders = const [],
    List<Product> products = const [],
  }) {
    final orderRepo = InMemoryOrderRepository(orders);
    final customerRepo = InMemoryCustomerRepository([]);
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

  group('ruleBasedBusinessPlan (AI-off twin)', () {
    test('brand-new business → onboarding text', () async {
      final ctx = await contextService().load();
      expect(ruleBasedBusinessPlan(ctx), contains('Chưa có dữ liệu'));
    });

    test('steps are numbered, prioritized losses-first, with KPIs', () async {
      final ctx = await contextService(
        orders: [order('o1')], // pending → open
        products: [product('p-out', qty: 0)],
      ).load();
      final text = ruleBasedBusinessPlan(ctx);

      // Stock-out (stop losses) outranks open orders in the ordering.
      expect(text, contains('1. Nhập lại 1 sản phẩm đã hết hàng'));
      expect(text, contains('2. Chốt 1 đơn đang mở'));
      expect(text, contains('KPI theo dõi'));
      expect(text, contains('Không bước nào tự chạy'));
      expect(text, ruleBasedBusinessPlan(ctx)); // deterministic
    });
  });

  group('BusinessPlanService.plan', () {
    test('no provider enabled → rule twin with provenance', () async {
      final service = BusinessPlanService(
        TongtaiAiService(InMemoryTongtaiAiKeyStore()), // no keys
        contextService(orders: [order('o1')]),
        clock: clock,
      );
      final p = await service.plan();

      expect(p.source, BusinessPlanSource.rule);
      expect(p.isAi, isFalse);
      expect(p.generatedAt, now);
      expect(p.text, contains('Kế hoạch tuần này'));
    });
  });
}
