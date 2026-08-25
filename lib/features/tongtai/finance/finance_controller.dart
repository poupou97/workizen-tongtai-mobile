import 'package:flutter/foundation.dart';

import 'fee_coexistence.dart';
import 'finance_repository.dart';
import 'finance_summary.dart';
import 'finance_transaction.dart';
import 'settlement.dart';
import 'settlement_repository.dart';

/// Holds the seller's transaction ledger and notifies the Finance dashboard
/// when it changes (WTM-113/120). Reads and writes through a [FinanceRepository]
/// — Drift (real, persistent), Sample (demo) or in-memory (tests) — so the
/// dashboard never knows the source. Aggregation is delegated to a
/// [FinanceService] over the current list.
///
/// It also reads (never writes) the settlement book through an optional
/// [SettlementRepository] so the dashboard can *say* when platform fees sit in
/// both books at once (WTM-460 / ADR-TON-024 §2). Without one, the settlement
/// side is empty and the coexistence note stays silent.
class FinanceController extends ChangeNotifier {
  FinanceController(this._repository, {SettlementRepository? settlements})
    // ignore: prefer_initializing_formals — the field is nullable on purpose
    : _settlements = settlements;

  /// Demo/preview ledger (read-only sample data). Not persisted.
  factory FinanceController.sample() =>
      FinanceController(const SampleFinanceRepository());

  /// In-memory ledger for tests, optionally pre-filled — transactions and the
  /// settlement book that WTM-460 reads alongside them.
  factory FinanceController.inMemory([
    Iterable<FinanceTransaction> initial = const [],
    Iterable<SettlementLine> settlements = const [],
  ]) => FinanceController(
    InMemoryFinanceRepository(initial),
    settlements: InMemorySettlementRepository(settlements),
  );

  final FinanceRepository _repository;
  final SettlementRepository? _settlements;
  final List<FinanceTransaction> _txns = [];
  final List<SettlementLine> _settlementLines = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Every transaction, unsorted snapshot.
  List<FinanceTransaction> get transactions => List.unmodifiable(_txns);

  /// The settlement lines read alongside the ledger, unsorted snapshot.
  List<SettlementLine> get settlementLines =>
      List.unmodifiable(_settlementLines);

  FinanceService get _service => FinanceService(_txns);

  /// Dashboard snapshot as of [now].
  FinanceSummary summaryAsOf(DateTime now) => _service.summaryAsOf(now);

  /// Whether platform fees sit in **both** books for [now]'s year — the YTD
  /// window the dashboard already reports.
  ///
  /// Gathers the two books and the period and hands off to the pure
  /// [detectFeeCoexistence], exactly as [summaryAsOf] defers to
  /// [FinanceService]: the concept lives in one place, and the screen never
  /// computes it itself (P-27/P-28).
  FeeCoexistence feeCoexistenceAsOf(DateTime now) => detectFeeCoexistence(
    settlementLines: _settlementLines,
    transactions: _txns,
    periodStart: DateTime(now.year),
    periodEndExclusive: DateTime(now.year + 1),
  );

  /// The most recent transactions, newest first.
  List<FinanceTransaction> recent({int limit = 6}) =>
      _service.recent(limit: limit);

  /// Loads the ledger from the repository (call once when the screen mounts).
  Future<void> hydrate() async {
    final loaded = await _repository.loadAll();
    _txns
      ..clear()
      ..addAll(loaded);
    if (_settlements != null) {
      final lines = await _settlements.loadAll();
      _settlementLines
        ..clear()
        ..addAll(lines);
    }
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
