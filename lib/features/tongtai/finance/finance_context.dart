import '../core/capability_context_provider.dart';
import 'finance_repository.dart';
import 'finance_summary.dart';

export 'finance_summary.dart' show FinanceSummary;

/// The Finance capability's Context Provider (WTM-133, Progressive Aggregation
/// Phase 2). Reuses the capability's own [FinanceSummary] — the existing Finance
/// snapshot (income/expense/profit YTD·MTD, margin, [FinanceSummary.hasActivity])
/// — as its slice of BusinessContext, rather than inventing a parallel type.
///
/// The provider loads transactions from the repository and folds them through
/// [FinanceService] as of a `now` it supplies (mirrors the other time-relative
/// providers) — pure Dart, no AI, no network.
///
/// **User Data First:** the real app wires a Drift repository that starts with an
/// empty ledger, so a brand-new business reads [FinanceSummary.empty]
/// ([FinanceSummary.hasActivity] == false); demo/tests inject transactions.
class FinanceContextProvider
    implements CapabilityContextProvider<FinanceSummary> {
  const FinanceContextProvider(
    this._repository, {
    this.clock,
    this.monthsBack = 6,
  });

  final FinanceRepository _repository;

  /// Injectable clock for the as-of date; defaults to [DateTime.now].
  final DateTime Function()? clock;

  /// Trailing months the cashflow window spans (passed to [FinanceService]).
  final int monthsBack;

  @override
  Future<FinanceSummary> load() async {
    final txns = await _repository.loadAll();
    return FinanceService(
      txns,
      monthsBack: monthsBack,
    ).summaryAsOf((clock ?? DateTime.now)());
  }
}
