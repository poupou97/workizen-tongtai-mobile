import 'package:flutter/foundation.dart';

import 'finance_repository.dart';
import 'finance_summary.dart';
import 'finance_transaction.dart';

/// Holds the seller's transaction ledger and notifies the Finance dashboard
/// when it changes (WTM-113/120). Reads and writes through a [FinanceRepository]
/// — Drift (real, persistent), Sample (demo) or in-memory (tests) — so the
/// dashboard never knows the source. Aggregation is delegated to a
/// [FinanceService] over the current list.
class FinanceController extends ChangeNotifier {
  FinanceController(this._repository);

  /// Demo/preview ledger (read-only sample data). Not persisted.
  factory FinanceController.sample() =>
      FinanceController(const SampleFinanceRepository());

  /// In-memory ledger for tests, optionally pre-filled.
  factory FinanceController.inMemory([
    Iterable<FinanceTransaction> initial = const [],
  ]) => FinanceController(InMemoryFinanceRepository(initial));

  final FinanceRepository _repository;
  final List<FinanceTransaction> _txns = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Every transaction, unsorted snapshot.
  List<FinanceTransaction> get transactions => List.unmodifiable(_txns);

  FinanceService get _service => FinanceService(_txns);

  /// Dashboard snapshot as of [now].
  FinanceSummary summaryAsOf(DateTime now) => _service.summaryAsOf(now);

  /// The most recent transactions, newest first.
  List<FinanceTransaction> recent({int limit = 6}) =>
      _service.recent(limit: limit);

  /// Loads the ledger from the repository (call once when the screen mounts).
  Future<void> hydrate() async {
    final loaded = await _repository.loadAll();
    _txns
      ..clear()
      ..addAll(loaded);
    _hydrated = true;
    notifyListeners();
  }

  /// Persists a new transaction and refreshes the dashboard.
  Future<void> add(FinanceTransaction transaction) async {
    await _repository.add(transaction);
    _txns.add(transaction);
    notifyListeners();
  }
}
