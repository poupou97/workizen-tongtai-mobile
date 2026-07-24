import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_controller.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';

/// WTM-120 — Finance persistence over Drift, User Data First.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  FinanceTransaction txn(
    String id, {
    double amount = 1000000,
    TransactionType type = TransactionType.income,
  }) => FinanceTransaction(
    id: id,
    type: type,
    category: 'Bán hàng',
    amount: amount,
    date: DateTime(2026, 7, 10),
    description: 'ghi chú',
    paymentMethod: 'cash',
  );

  group('LocalWorkspace', () {
    test(
      'ensureBusinessId is idempotent, seeds one user + one business',
      () async {
        const workspace = LocalWorkspace();
        final id1 = await workspace.ensureBusinessId(db);
        final id2 = await workspace.ensureBusinessId(db);

        expect(id1, LocalWorkspace.localBusinessId);
        expect(id2, id1);
        expect(await db.select(db.usersTable).get(), hasLength(1));
        expect(await db.select(db.businessesTable).get(), hasLength(1));
      },
    );
  });

  group('DriftFinanceRepository', () {
    test('a new user ledger starts EMPTY (no sample seeded)', () async {
      expect(await DriftFinanceRepository(db).loadAll(), isEmpty);
    });

    test('add persists and loadAll reads it back with fields intact', () async {
      final repo = DriftFinanceRepository(db);
      await repo.add(txn('t1', amount: 3000000));
      await repo.add(txn('t2', amount: 1500000, type: TransactionType.expense));

      final all = await repo.loadAll();
      expect(all.map((t) => t.id).toSet(), {'t1', 't2'});
      final t1 = all.firstWhere((t) => t.id == 't1');
      expect(t1.amount, 3000000);
      expect(t1.type, TransactionType.income);
      expect(t1.category, 'Bán hàng');
      expect(t1.description, 'ghi chú');
    });

    test('data survives across a fresh repository over the same db', () async {
      await DriftFinanceRepository(db).add(txn('t1'));
      final reloaded = await DriftFinanceRepository(db).loadAll();
      expect(reloaded.map((t) => t.id), ['t1']);
    });
  });

  group('SampleFinanceRepository (demo, read-only)', () {
    test('returns the sample ledger and never persists', () async {
      const repo = SampleFinanceRepository();
      expect((await repo.loadAll()).length, kSampleTransactions.length);
      await repo.add(txn('t1'));
      expect((await repo.loadAll()).length, kSampleTransactions.length);
    });
  });

  group('FinanceController over a repository', () {
    test('hydrate loads from the repo; add persists through it', () async {
      final repo = InMemoryFinanceRepository([txn('t0')]);
      final controller = FinanceController(repo);

      await controller.hydrate();
      expect(controller.isHydrated, isTrue);
      expect(controller.transactions.map((t) => t.id), ['t0']);

      await controller.add(txn('t1'));
      expect(controller.transactions.map((t) => t.id), ['t0', 't1']);
      // Written through to the repository, not just local.
      expect((await repo.loadAll()).map((t) => t.id).toSet(), {'t0', 't1'});
    });
  });
}
