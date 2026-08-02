import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consumer/customer_context.dart';
import '../finance/finance_context.dart';
import '../inventory/inventory_context.dart';
import '../journey/journey_context.dart';
import '../metrics/business_context_service.dart';
import '../opportunity/opportunity.dart';
import '../opportunity/opportunity_reaction_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;
import '../opportunity/opportunity_context.dart';
import '../opportunity/opportunity_rule_engine.dart';
import '../orders/order_context.dart';
import '../timeline/timeline_context.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_finance_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_journey_provider.dart';
import 'tongtai_metrics_provider.dart';
import 'tongtai_orders_provider.dart';
import '../producer/business_input_repository.dart';

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

/// The Opportunity Rule Engine's current generated opportunities (WTM-139,
/// Founder default): real business data in → rule-based opportunities out.
/// Deterministic per data snapshot; empty for a brand-new business.
final generatedOpportunitiesProvider = FutureProvider<List<Opportunity>>((
  ref,
) async {
  const engine = OpportunityRuleEngine();
  return engine.generate(
    products: await ref.watch(productRepositoryProvider).loadAll(),
    customers: await ref.watch(customerRepositoryProvider).loadAll(),
    orders: await ref.watch(orderRepositoryProvider).loadAll(),
    goals: await ref.watch(businessGoalRepositoryProvider).loadAll(),
    now: DateTime.now(),
  );
});

/// Opportunity slice — real generated opportunities via the Rule Engine
/// (WTM-139); AI later only layers scoring/ranking/explanation on top.
final opportunityContextProvider = Provider<OpportunityContextProvider>(
  (ref) => OpportunityContextProvider(
    source: () => ref.read(generatedOpportunitiesProvider.future),
  ),
);

/// Business Journey (goals) + Finance slices (WTM-133) — Drift-backed, so a
/// brand-new business reads empty summaries (User Data First). Journey derives
/// revenue-goal progress from real orders (WTM-138, Founder auto-derive).
final journeyContextProvider = Provider<JourneyContextProvider>(
  (ref) => JourneyContextProvider(
    ref.watch(businessGoalRepositoryProvider),
    orders: () => ref.read(orderRepositoryProvider).loadAll(),
  ),
);
final financeContextProvider = Provider<FinanceContextProvider>(
  (ref) => FinanceContextProvider(
    ref.watch(financeRepositoryProvider),
    // WTM-196: without this, Finance reads ₫0 income for a seller who has
    // recorded orders — while Home and Reports show real revenue.
    orders: ref.watch(orderRepositoryProvider),
  ),
);

/// Timeline is a **derived projection** (WTM-134) — no repository of its own; it
/// merges the real Finance/Order/Journey records into an activity stream. It
/// reads empty for a brand-new business (User Data First). Opportunity has no
/// persisted source yet, so it contributes no events in the real app.
final timelineContextProvider = Provider<TimelineContextProvider>(
  (ref) => TimelineContextProvider(
    ref.watch(financeRepositoryProvider),
    ref.watch(orderRepositoryProvider),
    ref.watch(businessGoalRepositoryProvider),
  ),
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
    ref.watch(timelineContextProvider),
  ),
);

/// Where the seller's opportunity decisions live (WTM-190).
///
/// Before this, "save" and "dismiss" existed only in memory: the seller pressed
/// a button and the app forgot by the next launch.
final opportunityReactionRepositoryProvider =
    Provider<OpportunityReactionRepository>(
      (ref) =>
          OpportunityReactionRepository(ref.watch(tongtaiDatabaseProvider)),
    );

/// Generated opportunities with the seller's stored decisions applied.
///
/// This is what screens should read — [generatedOpportunitiesProvider] alone
/// returns a feed that has forgotten everything the seller ever told it.
final opportunitiesWithReactionsProvider = FutureProvider<List<Opportunity>>((
  ref,
) async {
  final generated = await ref.watch(generatedOpportunitiesProvider.future);
  final reactions = await ref
      .watch(opportunityReactionRepositoryProvider)
      .loadAll();
  return applyReactions(generated, reactions);
});

/// Nguồn đầu vào của doanh nghiệp (WTM-229/230).
final businessInputRepositoryProvider = Provider<BusinessInputRepository>(
  (ref) => DriftBusinessInputRepository(ref.watch(tongtaiDatabaseProvider)),
);
