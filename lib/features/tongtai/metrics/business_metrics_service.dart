import '../consumer/customer_repository.dart';
import '../orders/order_repository.dart';
import 'business_metrics.dart';

/// The single source of truth for business KPIs (WTM-127, Founder). It sits
/// between the repositories and the presentation layer:
///
/// ```
/// Repositories → BusinessMetricsService → Reports → Home → BusinessContext → AI
/// ```
///
/// It reads the persisted capabilities through their repositories and produces a
/// read-only [BusinessMetrics] aggregate. Reports and Home **consume** this —
/// they never recompute KPIs. New KPIs are added here (and on [BusinessMetrics]),
/// never duplicated in a screen. This service is also a primary future input to
/// BusinessContext + AI, which likewise consume the aggregate, not the repos.
class BusinessMetricsService {
  const BusinessMetricsService(this._orders, this._customers);

  final OrderRepository _orders;
  final CustomerRepository _customers;

  /// Loads the current [BusinessMetrics] from persisted orders + customers.
  /// A brand-new business (no orders/customers) yields [BusinessMetrics.empty].
  Future<BusinessMetrics> load() async {
    final orders = await _orders.loadAll();
    final customers = await _customers.loadAll();
    return BusinessMetrics.from(
      orders: orders,
      customersCount: customers.length,
    );
  }
}
