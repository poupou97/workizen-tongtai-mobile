import 'package:flutter/foundation.dart';

import '../core/capability_context_provider.dart';
import 'customer.dart';
import 'customer_repository.dart';

/// Consumer-capability slice of the business snapshot (WTM-129/131).
@immutable
class CustomerSummary {
  const CustomerSummary({required this.total, required this.byTier});

  static const CustomerSummary empty = CustomerSummary(total: 0, byTier: {});

  final int total;

  /// Count of customers in each value tier (VIP/Gold/Silver/Bronze).
  final Map<CustomerTier, int> byTier;

  int tier(CustomerTier t) => byTier[t] ?? 0;

  factory CustomerSummary.from(List<Customer> customers) {
    final byTier = <CustomerTier, int>{};
    for (final c in customers) {
      byTier[c.tier] = (byTier[c.tier] ?? 0) + 1;
    }
    return CustomerSummary(total: customers.length, byTier: byTier);
  }
}

/// The Consumer capability's Context Provider (WTM-131) — loads customers from
/// the repository and produces the [CustomerSummary] slice for BusinessContext.
class CustomerContextProvider
    implements CapabilityContextProvider<CustomerSummary> {
  const CustomerContextProvider(this._repository);

  final CustomerRepository _repository;

  @override
  Future<CustomerSummary> load() async =>
      CustomerSummary.from(await _repository.loadAll());
}
