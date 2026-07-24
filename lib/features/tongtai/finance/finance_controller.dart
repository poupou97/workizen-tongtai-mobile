import 'package:flutter/foundation.dart';

import 'finance_summary.dart';
import 'finance_transaction.dart';

/// Holds the seller's transaction ledger and notifies the Finance dashboard
/// when it changes (WTM-113). Aggregation is delegated to a [FinanceService]
/// rebuilt from the current list, so every figure stays consistent with the
/// unit-tested service. Local-first and in-memory in Phase 2 (Drift persistence
/// arrives later); the list is the seam a Drift-backed store will replace.
class FinanceController extends ChangeNotifier {
  FinanceController(Iterable<FinanceTransaction> initial)
    : _txns = [...initial];

  /// Seeded with the built-in sample transactions.
  factory FinanceController.sample() => FinanceController(kSampleTransactions);

  final List<FinanceTransaction> _txns;

  /// Every transaction, unsorted snapshot.
  List<FinanceTransaction> get transactions => List.unmodifiable(_txns);

  FinanceService get _service => FinanceService(_txns);

  /// Dashboard snapshot as of [now].
  FinanceSummary summaryAsOf(DateTime now) => _service.summaryAsOf(now);

  /// The most recent transactions, newest first.
  List<FinanceTransaction> recent({int limit = 6}) =>
      _service.recent(limit: limit);

  /// Records a new transaction and refreshes the dashboard.
  void add(FinanceTransaction transaction) {
    _txns.add(transaction);
    notifyListeners();
  }
}
