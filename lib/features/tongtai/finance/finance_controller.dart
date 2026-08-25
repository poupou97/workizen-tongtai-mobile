import 'package:flutter/foundation.dart';

import '../orders/order.dart';
import '../orders/order_repository.dart';
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
///
/// ⭐ WTM-462 — it reads the **orders** repository too, for the same reason the
/// [FinanceContextProvider] does (WTM-196). Sales revenue and receivables are
/// derived from orders, never stored as transactions; without an
/// [OrderRepository] here the dashboard's [FinanceService] had `orders: const
/// []`, so `salesIncome` and `receivables` were **always 0** — while the Home
/// "Tài chính" tile computed receivables from `FinanceService(txns, orders:
/// orders)` and showed a real number. Tapping the tile then opened a screen
/// that read a *different source* for the same figure and silently answered 0:
/// the exact WTM-461 shape ([[P-50]]). Passing orders makes the screen and the
/// tile one data path. Nullable so test call sites that inject a controller keep
/// compiling — the production Finance screen **must** pass it, and
/// `home_tiles_one_path_test` fails if it does not.
class FinanceController extends ChangeNotifier {
  // Named params cannot be private, so the private `_settlements` / `_orders`
  // fields are assigned by hand rather than via initializing formals.
  FinanceController(
    this._repository, {
    SettlementRepository? settlements,
    OrderRepository? orders,
  }) : _settlements = settlements, // ignore: prefer_initializing_formals
       _orders = orders; // ignore: prefer_initializing_formals

  /// Demo/preview ledger (read-only sample data). Not persisted.
  factory FinanceController.sample() =>
      FinanceController(const SampleFinanceRepository());

  /// In-memory ledger for tests, optionally pre-filled — transactions, the
  /// settlement book that WTM-460 reads alongside them, and the orders WTM-462
  /// derives sales + receivables from.
  factory FinanceController.inMemory([
    Iterable<FinanceTransaction> initial = const [],
    Iterable<SettlementLine> settlements = const [],
    Iterable<CustomerOrder> orders = const [],
  ]) => FinanceController(
    InMemoryFinanceRepository(initial),
    settlements: InMemorySettlementRepository(settlements),
    orders: InMemoryOrderRepository(orders.toList()),
  );

  final FinanceRepository _repository;
  final SettlementRepository? _settlements;
  final OrderRepository? _orders;
  final List<FinanceTransaction> _txns = [];
  final List<SettlementLine> _settlementLines = [];

  /// Billable-and-unbillable sales orders read alongside the ledger (WTM-462).
  /// [FinanceService] applies the billable filter itself; this holds the raw
  /// snapshot so the same orders drive income, the cashflow chart and
  /// receivables through one owner.
  final List<CustomerOrder> _sales = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Every transaction, unsorted snapshot.
  List<FinanceTransaction> get transactions => List.unmodifiable(_txns);

  /// The settlement lines read alongside the ledger, unsorted snapshot.
  List<SettlementLine> get settlementLines =>
      List.unmodifiable(_settlementLines);

  FinanceService get _service => FinanceService(_txns, orders: _sales);

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
    // WTM-462: sales income + receivables are derived from orders on every read
    // (never copied into a transaction) — the same live-read discipline
    // [FinanceContextProvider] uses. Without this the dashboard's receivables
    // stayed 0 while Home's tile, reading orders, showed the real figure.
    if (_orders != null) {
      final orders = await _orders.loadAll();
      _sales
        ..clear()
        ..addAll(orders);
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
