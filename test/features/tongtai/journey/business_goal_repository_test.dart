import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/domain_snapshot.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';

/// WTM-124 — Business Journey (goal) persistence over Drift, the divergent-schema
/// case of ADR-TON-009 (`journeys_table` goal/status/budget/steps vs the
/// `BusinessGoal` type/target/achieved/growth/dates/notes domain). Covers the
/// full Founder-required set: round-trip, backward compatibility, corrupt-JSON
/// fallback, version tolerance, structured precedence and business isolation.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  BusinessGoal goal(
    String id, {
    String name = 'Đạt 100 triệu ₫',
    GoalType type = GoalType.revenue,
    double target = 100000000,
    double achieved = 40000000,
    int growthTarget = 200,
    int growthAchieved = 80,
    DateTime? start,
    DateTime? end,
    String notes = '',
    DateTime? updatedAt,
  }) => BusinessGoal(
    id: id,
    name: name,
    type: type,
    targetAmount: target,
    achievedAmount: achieved,
    growthTarget: growthTarget,
    growthAchieved: growthAchieved,
    startDate: start ?? DateTime(2026, 7, 1),
    endDate: end ?? DateTime(2026, 9, 30),
    notes: notes,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: updatedAt ?? DateTime(2026, 7, 20),
  );

  /// Inserts a raw journey row (bypassing the repository's mapping) so tests can
  /// stage legacy / corrupt / stale-snapshot data. The local business is
  /// bootstrapped first so the FK holds.
  Future<void> insertRawJourney({
    required String id,
    required String goalText,
    String status = 'active',
    String? businessId,
    double? revenueImpact,
    int? timelineDays,
    DateTime? startedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? domainSnapshot,
  }) async {
    final localBusiness = await const LocalWorkspace().ensureBusinessId(db);
    await db
        .into(db.journeysTable)
        .insert(
          JourneysTableCompanion.insert(
            id: id,
            businessId: businessId ?? localBusiness,
            goal: goalText,
            status: status,
            revenueImpact: Value(revenueImpact),
            timelineDays: Value(timelineDays),
            startedAt: Value(startedAt),
            createdAt: Value(createdAt ?? DateTime(2026, 7, 1)),
            updatedAt: Value(updatedAt ?? DateTime(2026, 7, 1)),
            domainSnapshot: Value(domainSnapshot),
          ),
        );
  }

  test('a new journey list starts EMPTY (no sample seeded)', () async {
    expect(await DriftBusinessGoalRepository(db).loadAll(), isEmpty);
  });

  test('round-trip: every promoted + snapshot field survives', () async {
    final repo = DriftBusinessGoalRepository(db);
    await repo.upsert(
      goal(
        'g1',
        name: 'Mở kênh TikTok Shop',
        type: GoalType.newChannel,
        target: 30000000,
        achieved: 4500000,
        growthTarget: 50,
        growthAchieved: 6,
        start: DateTime(2026, 7, 15),
        end: DateTime(2026, 9, 15),
        notes: 'Chạy quảng cáo cuối tuần.',
      ),
    );

    final reloaded = await DriftBusinessGoalRepository(db).loadAll();
    expect(reloaded, hasLength(1));
    final g = reloaded.single;
    expect(g.id, 'g1');
    expect(g.name, 'Mở kênh TikTok Shop'); // ← goal column
    expect(g.type, GoalType.newChannel); // ← snapshot
    expect(g.targetAmount, 30000000); // ← revenueImpact column
    expect(g.achievedAmount, 4500000); // ← snapshot
    expect(g.growthTarget, 50); // ← snapshot
    expect(g.growthAchieved, 6); // ← snapshot
    expect(g.startDate, DateTime(2026, 7, 15)); // ← startedAt column
    expect(g.endDate, DateTime(2026, 9, 15)); // ← snapshot
    expect(g.notes, 'Chạy quảng cáo cuối tuần.');
    expect(g.createdAt, DateTime(2026, 7, 1));
    expect(g.updatedAt, DateTime(2026, 7, 20));
  });

  test('upsert replaces the goal with the same id (edit)', () async {
    final repo = DriftBusinessGoalRepository(db);
    await repo.upsert(goal('g1', name: 'Old', achieved: 1000000));
    await repo.upsert(goal('g1', name: 'New', achieved: 9000000));

    final all = await repo.loadAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'New');
    expect(all.single.achievedAmount, 9000000);
  });

  test('loadAll returns newest-updated first', () async {
    final repo = DriftBusinessGoalRepository(db);
    await repo.upsert(
      goal('g1', name: 'Older', updatedAt: DateTime(2026, 7, 1)),
    );
    await repo.upsert(
      goal('g2', name: 'Newer', updatedAt: DateTime(2026, 7, 25)),
    );
    await repo.upsert(
      goal('g3', name: 'Middle', updatedAt: DateTime(2026, 7, 10)),
    );
    expect((await repo.loadAll()).map((g) => g.name), [
      'Newer',
      'Middle',
      'Older',
    ]);
  });

  test(
    'backward compatibility: a legacy row with a NULL snapshot loads',
    () async {
      // Simulates a pre-v7 row — structured columns intact, no domain_snapshot.
      // The reader rebuilds endDate from startedAt + timelineDays, defaults the
      // snapshot-only fields, and never throws.
      await insertRawJourney(
        id: 'legacy',
        goalText: 'Legacy goal',
        revenueImpact: 50000000,
        timelineDays: 30,
        startedAt: DateTime(2026, 6, 1),
        domainSnapshot: null,
      );

      final g = (await DriftBusinessGoalRepository(db).loadAll()).single;
      expect(g.name, 'Legacy goal');
      expect(g.targetAmount, 50000000);
      expect(g.startDate, DateTime(2026, 6, 1));
      expect(g.endDate, DateTime(2026, 6, 1).add(const Duration(days: 30)));
      // Snapshot-only fields default; type falls back to revenue.
      expect(g.type, GoalType.revenue);
      expect(g.achievedAmount, 0);
      expect(g.growthTarget, 0);
      expect(g.growthAchieved, 0);
      expect(g.notes, '');
    },
  );

  test(
    'corrupt-JSON fallback: a garbage snapshot never breaks a load',
    () async {
      await insertRawJourney(
        id: 'corrupt',
        goalText: 'Corrupt goal',
        revenueImpact: 12000000,
        timelineDays: 10,
        startedAt: DateTime(2026, 7, 5),
        domainSnapshot: 'not json at all }{',
      );

      final g = (await DriftBusinessGoalRepository(db).loadAll()).single;
      // Structured columns still read; corrupt blob degrades to defaults.
      expect(g.name, 'Corrupt goal');
      expect(g.targetAmount, 12000000);
      expect(g.startDate, DateTime(2026, 7, 5));
      expect(g.type, GoalType.revenue);
      expect(g.achievedAmount, 0);
      expect(g.notes, '');
    },
  );

  test(
    'version tolerance: an unknown snapshot version still reads its fields',
    () async {
      await insertRawJourney(
        id: 'future',
        goalText: 'Future goal',
        revenueImpact: 20000000,
        startedAt: DateTime(2026, 7, 1),
        domainSnapshot: encodeDomainSnapshot({
          'type': 'customerGrowth',
          'achievedAmount': 5000000,
          'growthTarget': 300,
          'growthAchieved': 120,
          'endDate': DateTime(2026, 12, 31).millisecondsSinceEpoch,
          'notes': 'from v99',
        }, version: 99),
      );

      final g = (await DriftBusinessGoalRepository(db).loadAll()).single;
      expect(g.type, GoalType.customerGrowth);
      expect(g.achievedAmount, 5000000);
      expect(g.growthTarget, 300);
      expect(g.growthAchieved, 120);
      expect(g.endDate, DateTime(2026, 12, 31));
      expect(g.notes, 'from v99');
    },
  );

  test(
    'structured precedence: the column wins over a stale snapshot copy',
    () async {
      // The snapshot carries stale copies of promoted fields; the reader must take
      // the structured columns as the source of truth (ADR-TON-009).
      await insertRawJourney(
        id: 'stale',
        goalText: 'Tên Cột', // ← structured truth (name)
        revenueImpact: 88000000, // ← structured truth (targetAmount)
        startedAt: DateTime(2026, 3, 1), // ← structured truth (startDate)
        domainSnapshot: encodeDomainSnapshot({
          'name': 'Tên Cũ Trong Snapshot', // stale — ignored (not read)
          'targetAmount': 1, // stale — ignored (not read)
          'startDate': DateTime(2020, 1, 1).millisecondsSinceEpoch, // ignored
          'type': 'productLaunch', // genuinely snapshot-owned
          'achievedAmount': 10000000,
          'endDate': DateTime(2026, 6, 30).millisecondsSinceEpoch,
          'notes': 'real',
        }, version: 1),
      );

      final g = (await DriftBusinessGoalRepository(db).loadAll()).single;
      expect(g.name, 'Tên Cột'); // column, not the snapshot copy
      expect(g.targetAmount, 88000000); // column, not the snapshot copy
      expect(
        g.startDate,
        DateTime(2026, 3, 1),
      ); // column, not the snapshot copy
      expect(g.type, GoalType.productLaunch); // snapshot-owned field
      expect(g.achievedAmount, 10000000);
      expect(g.notes, 'real');
    },
  );

  test(
    'business isolation: loadAll only returns the local business rows',
    () async {
      final localBusiness = await const LocalWorkspace().ensureBusinessId(db);
      await db
          .into(db.usersTable)
          .insert(
            UsersTableCompanion.insert(
              id: 'other-owner',
              email: 'other@x.app',
              name: 'Khác',
            ),
          );
      await db
          .into(db.businessesTable)
          .insert(
            BusinessesTableCompanion.insert(
              id: 'other-business',
              ownerId: 'other-owner',
              name: 'Doanh nghiệp khác',
            ),
          );

      await insertRawJourney(
        id: 'mine',
        goalText: 'Của tôi',
        businessId: localBusiness,
      );
      await insertRawJourney(
        id: 'theirs',
        goalText: 'Của họ',
        businessId: 'other-business',
      );

      final mine = await DriftBusinessGoalRepository(db).loadAll();
      expect(mine.map((g) => g.id), ['mine']);
    },
  );

  group('SampleBusinessGoalRepository (demo, read-only)', () {
    test('returns the sample goals and never persists', () async {
      const repo = SampleBusinessGoalRepository();
      final before = (await repo.loadAll()).length;
      expect(before, greaterThan(0));
      await repo.upsert(goal('g1'));
      expect((await repo.loadAll()).length, before);
    });

    test('the Drift list is NOT seeded with the sample goals', () async {
      // User Data First: a real repo stays empty even though a sample exists.
      expect(await DriftBusinessGoalRepository(db).loadAll(), isEmpty);
      expect(
        (await const SampleBusinessGoalRepository().loadAll()).length,
        greaterThan(0),
      );
    });
  });

  group('InMemoryBusinessGoalRepository (tests)', () {
    test('upserts and replaces in memory', () async {
      final repo = InMemoryBusinessGoalRepository([goal('g1', name: 'A')]);
      expect((await repo.loadAll()).single.name, 'A');
      await repo.upsert(goal('g1', name: 'B'));
      await repo.upsert(goal('g2', name: 'C'));
      final all = await repo.loadAll();
      expect(all, hasLength(2));
      expect(all.firstWhere((g) => g.id == 'g1').name, 'B');
    });
  });
}
