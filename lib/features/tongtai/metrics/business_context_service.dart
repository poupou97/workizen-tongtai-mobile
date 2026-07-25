import '../consumer/customer_repository.dart';
import '../inventory/product_repository.dart';
import '../orders/order_repository.dart';
import 'business_context.dart';
import 'business_metrics.dart';

/// Builds the [BusinessContext] Aggregate Root (WTM-129, Founder) by
/// **Progressive Aggregation** over the persisted capabilities. Phase 1 reads
/// Orders + Customers + Inventory through their repositories and assembles the
/// KPIs ([BusinessMetrics]) + per-capability summaries.
///
/// This is the seam **Workizen AI** consumes — AI reads the returned
/// [BusinessContext], never the repositories. New capabilities (Opportunity,
/// Journey, Timeline, Goals, Finance) are folded in here without changing what
/// AI or Home consume.
class BusinessContextService {
  const BusinessContextService(this._orders, this._customers, this._products);

  final OrderRepository _orders;
  final CustomerRepository _customers;
  final ProductRepository _products;

  /// Loads the current business snapshot. A brand-new business (no data) yields
  /// [BusinessContext.empty].
  Future<BusinessContext> load() async {
    final orders = await _orders.loadAll();
    final customers = await _customers.loadAll();
    final products = await _products.loadAll();
    return BusinessContext(
      metrics: BusinessMetrics.from(
        orders: orders,
        customersCount: customers.length,
      ),
      customers: CustomerSummary.from(customers),
      orders: OrderSummary.from(orders),
      inventory: InventorySummary.from(products),
    );
  }
}
