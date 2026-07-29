import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consumer/customer_context.dart';
import '../finance/finance_context.dart';
import '../inventory/inventory_context.dart';
import '../journey/journey_context.dart';
import '../metrics/business_context_service.dart';
import '../opportunity/opportunity_context.dart';
import '../orders/order_context.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_finance_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_journey_provider.dart';
import 'tongtai_metrics_provider.dart';
import 'tongtai_orders_provider.dart';

/// One Context Provider per capability (WTM-131). Each turns its repository into
/// a read-only summary slice; `BusinessContextService` composes them.
final customerContextProvider = Provider<CustomerContextProvider>(
  (ref) => CustomerContextProvider(ref.watch(customerRepositoryProvider)),
);
final orderContextProvider = Provider<OrderContextProvider>(
  (ref) => OrderContextProvider(ref.watch(orderRepositoryProvider)),
);
final inventoryContextProvider = Provider<InventoryContextProvider>(
  (ref) => InventoryContextProvider(ref.watch(productRepositoryProvider)),
);

/// Opportunity has no persisted/generated source yet, so the real business reads
/// an empty summary (User Data First); it fills in once a real source lands.
final opportunityContextProvider = Provider<OpportunityContextProvider>(
  (ref) => const OpportunityContextProvider(),
);

/// Business Journey (goals) + Finance slices (WTM-133) — Drift-backed, so a
/// brand-new business reads empty summaries (User Data First).
final journeyContextProvider = Provider<JourneyContextProvider>(
  (ref) => JourneyContextProvider(ref.watch(businessGoalRepositoryProvider)),
);
final financeContextProvider = Provider<FinanceContextProvider>(
  (ref) => FinanceContextProvider(ref.watch(financeRepositoryProvider)),
);

/// The business Aggregate Root builder (WTM-129/131) — composes every capability
/// Context Provider + the KPI source of truth. Home and (later) Workizen AI
/// consume the returned `BusinessContext`; **AI never reads a repository/provider
/// directly**. Tests inject in-memory repositories / summaries.
final businessContextServiceProvider = Provider<BusinessContextService>(
  (ref) => BusinessContextService(
    ref.watch(businessMetricsServiceProvider),
    ref.watch(customerContextProvider),
    ref.watch(orderContextProvider),
    ref.watch(inventoryContextProvider),
    ref.watch(opportunityContextProvider),
    ref.watch(journeyContextProvider),
    ref.watch(financeContextProvider),
  ),
);
