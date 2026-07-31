import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import '../core/tongtai_enums.dart';
import 'finance_transaction.dart';

/// Decides the source of finance data (WTM-120) — Drift (real, persistent),
/// Sample (demo) or in-memory (tests). The controller depends on this seam, not
/// on Drift; the UI never knows which source is behind it.
abstract class FinanceRepository {
  Future<List<FinanceTransaction>> loadAll();
  Future<void> add(FinanceTransaction transaction);

  /// [add] for a whole collection, as ONE write (WTM-149 device defect 2).
  ///
  /// Semantically identical to calling [add] in iteration order — the ledger
  /// stays insert-only, so a duplicate id still fails — but the Drift
  /// implementation issues a single batched transaction instead of one
  /// statement (plus a workspace bootstrap) per row. 12 months of generated
  /// history is ~550 transactions; row-at-a-time that froze the UI for minutes
  /// on a real device. See `CustomerRepository.upsertAll`.
  Future<void> addAll(Iterable<FinanceTransaction> transactions);

  /// Deletes every row whose id starts with [prefix] — the sample-data
  /// lifecycle hook (WTM-144/ADR-TON-014): sample records carry the
  /// `sample-` id prefix so they can be removed without touching user data.
  Future<void> deleteByIdPrefix(String prefix);
}

/// Real, persistent transactions for the local business (WTM-120).
///
/// **User Data First** (Founder, 2026-07-24): nothing is seeded — a new user
/// starts with an empty ledger. Rows are scoped to [LocalWorkspace]'s business.
class DriftFinanceRepository implements FinanceRepository {
  DriftFinanceRepository(this._db, {this._workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  @override
  Future<List<FinanceTransaction>> loadAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.transactionsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return rows.map(_toTransaction).toList();
  }

  @override
  Future<void> add(FinanceTransaction t) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.into(_db.transactionsTable).insert(_companion(t, businessId));
  }

  @override
  Future<void> addAll(Iterable<FinanceTransaction> transactions) async {
    final rows = transactions.toList(growable: false);
    if (rows.isEmpty) return;
    final businessId = await _workspace.ensureBusinessId(_db);
    // One batch = one transaction = one fsync, instead of one per row. The
    // insert mode matches [add]'s exactly — the ledger stays insert-only, so a
    // duplicate id still throws rather than silently overwriting.
    await _db.batch(
      (b) => b.insertAll(_db.transactionsTable, [
        for (final t in rows) _companion(t, businessId),
      ]),
    );
  }

  /// The single row mapping, shared by [add] and [addAll] so the bulk path can
  /// never drift from the single-row path.
  TransactionsTableCompanion _companion(
    FinanceTransaction t,
    String businessId,
  ) => TransactionsTableCompanion.insert(
    id: t.id,
    businessId: businessId,
    type: t.type.name,
    amount: t.amount,
    date: t.date,
    category: Value(t.category),
    description: Value(t.description),
    paymentMethod: Value(t.paymentMethod),
  );

  FinanceTransaction _toTransaction(TransactionsTableData row) =>
      FinanceTransaction(
        id: row.id,
        type: TransactionType.fromStorage(row.type),
        category: row.category ?? '',
        amount: row.amount,
        date: row.date,
        description: row.description ?? '',
        paymentMethod: row.paymentMethod ?? '',
      );
  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(_db.transactionsTable)..where(
          (t) => t.businessId.equals(businessId) & t.id.like('$prefix%'),
        ))
        .go();
  }
}

/// Demo / Preview source (WTM-120): the built-in sample ledger, **read-only** —
/// used only in Demo Mode and never written to the user's database.
class SampleFinanceRepository implements FinanceRepository {
  const SampleFinanceRepository();

  @override
  Future<List<FinanceTransaction>> loadAll() async =>
      List.of(kSampleTransactions);

  @override
  Future<void> add(FinanceTransaction transaction) async {
    // Demo data is read-only — do not persist.
  }

  @override
  Future<void> addAll(Iterable<FinanceTransaction> transactions) async {
    // Demo data is read-only — do not persist.
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    // Demo fixtures are read-only — nothing to delete.
  }
}

/// In-memory source for tests (mutable, no database).
class InMemoryFinanceRepository implements FinanceRepository {
  InMemoryFinanceRepository([Iterable<FinanceTransaction> initial = const []])
    : _txns = [...initial];

  final List<FinanceTransaction> _txns;

  @override
  Future<List<FinanceTransaction>> loadAll() async => List.of(_txns);

  @override
  Future<void> add(FinanceTransaction transaction) async =>
      _txns.add(transaction);

  @override
  Future<void> addAll(Iterable<FinanceTransaction> transactions) async {
    for (final t in transactions) {
      await add(t);
    }
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async =>
      _txns.removeWhere((x) => x.id.startsWith(prefix));
}
