import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/domain_snapshot.dart';
import '../core/local_workspace.dart';
import 'business_goal.dart';

/// Decides the source of Business Journey / goal data (WTM-124) — Drift (real,
/// persistent), Sample (demo) or in-memory (tests). The controller depends on
/// this seam, not on Drift. Same pattern as `ProductRepository` (WTM-121) and
/// `CustomerRepository` (WTM-123).
abstract class BusinessGoalRepository {
  Future<List<BusinessGoal>> loadAll();

  /// Insert a new goal or replace the one with the same id.
  Future<void> upsert(BusinessGoal goal);

  /// [upsert] for a whole collection, as ONE write (WTM-149 device defect 2) —
  /// see `CustomerRepository.upsertAll` for why the seam exists.
  Future<void> upsertAll(Iterable<BusinessGoal> goals);

  /// Deletes every row whose id starts with [prefix] — the sample-data
  /// lifecycle hook (WTM-144/ADR-TON-014): sample records carry the
  /// `sample-` id prefix so they can be removed without touching user data.
  Future<void> deleteByIdPrefix(String prefix);

  /// Removes **every** record of this business (WTM-164 restore Replace).
  ///
  /// Separate from `deleteByIdPrefix('')` on purpose: "wipe the business" is a
  /// destructive operation that should be spelled out at the call site, not
  /// achieved by an empty-prefix trick nobody reading the code would notice.
  Future<void> deleteAll();
}

/// Real, persistent business goals for the local business (WTM-124).
///
/// **Divergent-schema case of ADR-TON-009 (option B):** the `journeys_table`
/// shape (goal/status/budget/steps/timeline) differs from the `BusinessGoal`
/// domain (type/target/achieved/growth/dates/notes). The Repository owns the
/// mapping. Structured columns are the **source of truth** for the promoted
/// fields — `goal`←name, `revenueImpact`←targetAmount, `startedAt`←startDate —
/// with `status`/`progressPercent`/`timelineDays` derived purely for
/// query/report; the remaining domain fields (type, achievedAmount, growth,
/// endDate, notes) ride the versioned snapshot losslessly.
///
/// **User Data First** (Founder, 2026-07-24): nothing is seeded — a new user
/// starts with no goals. Rows are scoped to [LocalWorkspace]'s business.
class DriftBusinessGoalRepository implements BusinessGoalRepository {
  DriftBusinessGoalRepository(
    this._db, {
    this._workspace = const LocalWorkspace(),
  });

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  /// Current snapshot version — bump + migrate the reader when the JSON shape
  /// changes.
  static const int _snapshotVersion = 1;

  @override
  Future<List<BusinessGoal>> loadAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.journeysTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    return rows.map(_toGoal).toList();
  }

  @override
  Future<void> upsert(BusinessGoal g) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db
        .into(_db.journeysTable)
        .insertOnConflictUpdate(_companion(g, businessId));
  }

  @override
  Future<void> upsertAll(Iterable<BusinessGoal> goals) async {
    final rows = goals.toList(growable: false);
    if (rows.isEmpty) return;
    final businessId = await _workspace.ensureBusinessId(_db);
    // One batch = one transaction = one fsync, instead of one per row.
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.journeysTable, [
        for (final g in rows) _companion(g, businessId),
      ]),
    );
  }

  /// The single row mapping, shared by [upsert] and [upsertAll] so the bulk
  /// path can never drift from the single-row path.
  JourneysTableCompanion _companion(BusinessGoal g, String businessId) =>
      JourneysTableCompanion.insert(
        id: g.id,
        businessId: businessId,
        goal: g.name,
        status: g.progress >= 1.0 ? 'completed' : 'active',
        // Promoted (SoT) — read back from these columns.
        revenueImpact: Value(g.targetAmount),
        startedAt: Value(g.startDate),
        // Derived, query/report only — the domain recomputes these.
        progressPercent: Value((g.progress * 100).round()),
        timelineDays: Value(g.endDate.difference(g.startDate).inDays),
        createdAt: Value(g.createdAt),
        updatedAt: Value(g.updatedAt),
        // Lossless remainder of the divergent domain.
        domainSnapshot: Value(
          encodeDomainSnapshot({
            'type': g.type.name,
            'achievedAmount': g.achievedAmount,
            'growthTarget': g.growthTarget,
            'growthAchieved': g.growthAchieved,
            'endDate': g.endDate.millisecondsSinceEpoch,
            'notes': g.notes,
          }, version: _snapshotVersion),
        ),
      );

  BusinessGoal _toGoal(JourneysTableData row) {
    final snapshot = decodeDomainSnapshot(row.domainSnapshot);
    // Promoted fields come from their structured columns (SoT); a stale copy in
    // the snapshot is ignored. startedAt falls back to createdAt for a legacy
    // pre-v7 row that never carried a start date.
    final startDate = row.startedAt ?? row.createdAt;
    final endMs = snapshotInt(snapshot, 'endDate', fallback: -1);
    final endDate = endMs >= 0
        ? DateTime.fromMillisecondsSinceEpoch(endMs)
        : startDate.add(Duration(days: row.timelineDays ?? 0));
    return BusinessGoal(
      id: row.id,
      name: row.goal,
      type: _goalTypeFromName(snapshotString(snapshot, 'type')),
      targetAmount: row.revenueImpact ?? 0,
      achievedAmount: snapshotDouble(snapshot, 'achievedAmount'),
      growthTarget: snapshotInt(snapshot, 'growthTarget'),
      growthAchieved: snapshotInt(snapshot, 'growthAchieved'),
      startDate: startDate,
      endDate: endDate,
      notes: snapshotString(snapshot, 'notes'),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Tolerant enum parse — an unknown/missing type never breaks a load.
  GoalType _goalTypeFromName(String name) {
    for (final t in GoalType.values) {
      if (t.name == name) return t;
    }
    return GoalType.revenue;
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(_db.journeysTable)..where(
          (t) => t.businessId.equals(businessId) & t.id.like('$prefix%'),
        ))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.journeysTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }
}

/// Demo / Preview source (WTM-124): the built-in sample goals, **read-only** —
/// used only in Demo Mode, never written to the user's database.
class SampleBusinessGoalRepository implements BusinessGoalRepository {
  const SampleBusinessGoalRepository();

  @override
  Future<List<BusinessGoal>> loadAll() async => List.of(kSampleBusinessGoals);

  @override
  Future<void> upsert(BusinessGoal goal) async {
    // Demo data is read-only — do not persist.
  }

  @override
  Future<void> upsertAll(Iterable<BusinessGoal> goals) async {
    // Demo data is read-only — do not persist.
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async {
    // Demo fixtures are read-only — nothing to delete.
  }

  @override
  Future<void> deleteAll() async {
    // Demo fixtures are read-only — nothing to delete.
  }
}

/// In-memory source for tests (mutable, no database).
class InMemoryBusinessGoalRepository implements BusinessGoalRepository {
  InMemoryBusinessGoalRepository([Iterable<BusinessGoal> initial = const []])
    : _goals = [...initial];

  final List<BusinessGoal> _goals;

  @override
  Future<List<BusinessGoal>> loadAll() async => List.of(_goals);

  @override
  Future<void> upsert(BusinessGoal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _goals[index] = goal;
    } else {
      _goals.add(goal);
    }
  }

  @override
  Future<void> upsertAll(Iterable<BusinessGoal> goals) async {
    for (final g in goals) {
      await upsert(g);
    }
  }

  @override
  Future<void> deleteByIdPrefix(String prefix) async =>
      _goals.removeWhere((x) => x.id.startsWith(prefix));

  @override
  Future<void> deleteAll() async => _goals.clear();
}
