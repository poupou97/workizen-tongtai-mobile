import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/customer_rfm.dart';
import '../consumer/customer.dart';
import '../inventory/product.dart';
import '../onboarding/analysis_pipeline.dart';
import '../onboarding/first_insight_input.dart';
import '../orders/order.dart';
import 'tongtai_commerce_provider.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_orders_provider.dart';
import 'tongtai_predictive_provider.dart';

/// Nguồn dữ liệu thật cho pipeline phân tích của onboarding — WTM-353.
///
/// Đây là **chỗ duy nhất** biết "đọc gì từ đâu". Pipeline và engine đều nhận
/// giá trị, nên chúng test được bằng dữ liệu dựng tay và không kéo theo cả cây
/// provider vào một test đơn vị.
class RiverpodAnalysisSource implements AnalysisSource {
  const RiverpodAnalysisSource(this.ref);

  final Ref ref;

  @override
  Future<List<Product>> loadProducts() =>
      ref.read(productRepositoryProvider).loadAll();

  @override
  Future<List<CustomerOrder>> loadOrders() =>
      ref.read(orderRepositoryProvider).loadAll();

  @override
  Future<List<Customer>> loadCustomers() =>
      ref.read(customerRepositoryProvider).loadAll();

  @override
  Future<FirstInsightInput> assemble({
    required DateTime now,
    required List<Product> products,
    required List<CustomerOrder> orders,
    required List<Customer> customers,
  }) async {
    final risk = await ref.read(customerRiskProvider.future);
    final alerts = await ref.read(businessAlertsProvider.future);
    final settlements = ref.read(settlementRepositoryProvider);
    final lines = await settlements.loadAll();
    final payouts = await settlements.loadPayouts();

    return FirstInsightInput(
      now: now,
      products: products,
      orders: orders,
      customers: customers,
      profiles: CustomerRfmService.compute(customers, orders, now: now),
      // `result` là `null` khi Rule Twin **từ chối** vì thiếu dữ liệu — và từ
      // chối là một câu trả lời, khác hẳn "không khách nào rủi ro".
      risk: risk.result,
      alerts: alerts.result ?? const [],
      settlementLines: lines,
      payouts: payouts,
      marketplaceOrdersWithoutFees: countMarketplaceOrdersWithoutFees(
        orders: orders,
        settledOrderIds: {for (final l in lines) l.orderId},
      ),
    );
  }
}

/// Đơn bán qua kênh có phí mà **chưa có dòng đối soát nào**.
///
/// Hàm riêng, không phải một biểu thức nằm giữa `assemble`, vì nó là cái chốt
/// giữ cho "lời thật" khỏi trông như đã tính xong: phí sàn về sau đơn hàng vài
/// ngày tới vài tuần, nên khoảng thời gian giữa hai mốc đó là đúng lúc một con
/// số lợi nhuận đẹp-hơn-sự-thật dễ lọt ra nhất.
int countMarketplaceOrdersWithoutFees({
  required List<CustomerOrder> orders,
  required Set<String> settledOrderIds,
}) {
  var count = 0;
  for (final o in orders) {
    // `channel == null` là **chưa ghi kênh**, không phải "bán tại cửa hàng".
    // Không đoán: một đơn chưa ghi kênh không đủ căn cứ để gọi là đơn sàn.
    if (o.channel?.chargesPlatformFee != true) continue;
    if (settledOrderIds.contains(o.id)) continue;
    count++;
  }
  return count;
}

/// Pipeline dựng sẵn trên nguồn thật.
final onboardingAnalysisPipelineProvider = Provider<AnalysisPipeline>(
  (ref) => AnalysisPipeline(source: RiverpodAnalysisSource(ref)),
);
