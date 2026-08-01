import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finance_summary.dart';
import '../ai/predictive_ai.dart';
import '../analytics/cashflow_series.dart';
import '../predictive/business_alerts_rule.dart';
import '../predictive/customer_risk_rule.dart';
import '../predictive/revenue_forecast_rule.dart';
import '../predictive/rule_twin.dart';
import 'tongtai_ai_provider.dart';
import 'tongtai_orders_provider.dart';
import 'tongtai_capability_provider.dart';
import 'tongtai_finance_provider.dart';
import 'tongtai_inventory_provider.dart';

/// **Rule Twins** (WTM-156/157, ADR-TON-016) — the deterministic, AUTHORITATIVE
/// predictive layer, exposed over the on-demand capability providers.
///
/// Every provider here works with **no AI, no network and no BYOK key**: a twin
/// is pure arithmetic over a capability context, so these resolve identically in
/// airplane mode. AI may later *explain* what they return; it may never replace
/// the numbers (ADR-TON-013 invariant, extended to predictions by ADR-TON-016).
///
/// `FutureProvider` gives watchers loading/error/data for free and caches until
/// a dependency changes. Tests override the repository providers with in-memory
/// ones, or — better — call the rule directly with a hand-built context, since
/// the rules themselves are pure.

/// Next-month revenue forecast with its band, confidence, sufficiency and
/// reason codes (WTM-155, [RevenueForecastRule] version `revenue-forecast/1`).
///
/// The result may legitimately carry `result == null` — that is the rule
/// **refusing** to answer on thin history, and the UI must render it as "not
/// enough history yet", never as a zero forecast.
final revenueForecastProvider = FutureProvider<RuleTwinResult<RevenueForecast>>(
  (ref) async {
    final revenue = await ref.watch(revenueCapabilityProvider.future);
    return const RevenueForecastRule().forecast(revenue);
  },
);

/// Churn / win-back risk for every customer, ranked (WTM-156).
///
/// The assessment carries customer **ids only**; the screen joins them back to
/// names through `customerRepositoryProvider`, so no PII ever travels with the
/// twin (D-7 / ADR-TON-005 privacy red-line).
final customerRiskProvider =
    FutureProvider<RuleTwinResult<CustomerRiskAssessment>>((ref) async {
      final customers = await ref.watch(customerCapabilityProvider.future);
      return const CustomerRiskRule().assess(customers);
    });

/// Everything that needs attention today, most severe first (WTM-157).
///
/// Composes the revenue + customer capability contexts with the two sources
/// that have no capability context yet: the finance ledger (bucketed here into a
/// [CashflowSeries] — the same aggregation service Finance will use when its
/// capability context lands) and the product catalog (fed straight into the
/// existing `StockAlertService`).
///
/// The whole evaluation is pinned to **one** instant, `revenue.generatedAt`, so
/// the cashflow window and the revenue window can never straddle a month
/// boundary and disagree.
final businessAlertsProvider =
    FutureProvider<RuleTwinResult<List<BusinessAlert>>>((ref) async {
      final revenue = await ref.watch(revenueCapabilityProvider.future);
      final customers = await ref.watch(customerCapabilityProvider.future);
      final transactions = await ref.watch(financeRepositoryProvider).loadAll();
      final products = await ref.watch(productRepositoryProvider).loadAll();
      // WTM-205: the alert's cashflow comes from the SAME arithmetic Finance
      // shows — sales income included. `fromTransactions` counted only
      // hand-entered rows, so a seller with ten real orders was told their
      // cashflow was in deficit, and the Rule Twin would have had AI explain a
      // hole that did not exist.
      final orders = await ref.watch(orderRepositoryProvider).loadAll();

      return const BusinessAlertsRule().evaluate(
        revenue: revenue,
        customers: customers,
        cashflow: FinanceService(
          transactions,
          orders: orders,
        ).cashflowAsOf(revenue.generatedAt, months: revenue.windowMonths),
        products: products,
      );
    });

/// **Predictive AI explanations** (WTM-158, ADR-TON-016 Decision 4) — prose over
/// the twins above. The rule keeps the numbers; the AI only puts them in words.
///
/// Deliberately **on demand**: nothing here watches it, so opening a Forecast or
/// Risk screen costs zero provider calls. A screen calls
/// `ref.read(predictiveAiServiceProvider).explainForecast(...)` from a button,
/// passing the context and twin it is already showing — the service never loads
/// or recomputes anything (it holds no repository and no capability provider, so
/// it structurally cannot).
///
/// Built like every other AI service in the app (see
/// `businessSummaryServiceProvider`): the shared `tongtaiAiServiceProvider`
/// supplies BYOK/Local key handling and the provider chain, and the deterministic
/// twin explanation answers when no key is set, every provider fails, or the twin
/// itself reported insufficient data.
final predictiveAiServiceProvider = Provider<PredictiveAiService>(
  (ref) => PredictiveAiService(ref.watch(tongtaiAiServiceProvider)),
);
