import '../consumer/customer_context.dart';
import '../inventory/inventory_context.dart';
import '../opportunity/opportunity_context.dart';
import '../orders/order_context.dart';
import 'business_context.dart';
import 'business_metrics_service.dart';

/// Composes the [BusinessContext] Aggregate Root (WTM-129/131) from **one
/// Context Provider per capability** plus the KPI source of truth
/// ([BusinessMetricsService]). Adding a capability to the business snapshot is
/// just wiring one more provider here — no other change to what Home or AI
/// consume.
///
/// This is the seam **Workizen AI** consumes — AI reads the returned
/// [BusinessContext], never a provider or repository.
class BusinessContextService {
  const BusinessContextService(
    this._metrics,
    this._customers,
    this._orders,
    this._inventory,
    this._opportunity,
  );

  final BusinessMetricsService _metrics;
  final CustomerContextProvider _customers;
  final OrderContextProvider _orders;
  final InventoryContextProvider _inventory;
  final OpportunityContextProvider _opportunity;

  /// Loads the current business snapshot by composing every capability provider.
  /// A brand-new business (no data) yields [BusinessContext.empty]'s shape.
  Future<BusinessContext> load() async {
    return BusinessContext(
      metrics: await _metrics.load(),
      customers: await _customers.load(),
      orders: await _orders.load(),
      inventory: await _inventory.load(),
      opportunity: await _opportunity.load(),
    );
  }
}
