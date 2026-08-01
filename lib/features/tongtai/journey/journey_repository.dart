import 'package:drift/drift.dart';

import '../../../database/database.dart';
import 'journey.dart';
import 'journey_node.dart';

/// Reads and writes journeys, their trees and their plan versions (WTM-185).
///
/// One query per table, tree assembled in Dart. A recursive SQL walk would be
/// cleverer and would also make "load the plan" depend on SQLite's recursive
/// CTE support at every call site; three flat reads of a small table are
/// cheaper to reason about and trivially testable.
class JourneyRepository {
  JourneyRepository(this._db);

  final AppDatabase _db;

  /// Every journey with its tree and plan versions.
  Future<List<Journey>> loadAll() async {
    final journeyRows = await _db.select(_db.businessJourneysTable).get();
    if (journeyRows.isEmpty) return const [];

    final nodeRows = await _db.select(_db.businessJourneyNodesTable).get();
    final planRows = await _db.select(_db.businessJourneyPlansTable).get();

    return [
      for (final j in journeyRows)
        if (JourneyState.fromCode(j.state) case final state?)
          Journey(
            id: j.id,
            goalId: j.goalId,
            state: state,
            activePlanVersion: j.activePlanVersion,
            createdAt: j.createdAt,
            updatedAt: j.updatedAt,
            nodes: [
              for (final n in nodeRows)
                if (n.journeyId == j.id) ?_node(n),
            ],
            plans: [
              for (final p in planRows)
                if (p.journeyId == j.id)
                  if (JourneyNodeOrigin.fromCode(p.generatedBy) case final by?)
                    JourneyPlan(
                      version: p.version,
                      generatedBy: by,
                      generatedAt: p.generatedAt,
                      reasonCodes: _splitCodes(p.reasonCodes),
                    ),
            ],
          ),
    ];
  }

  /// The one journey a seller is working on, or `null`.
  ///
  /// The Concept's *"One Active Journey at a Time"* is a business rule, not a
  /// storage constraint — several journeys may sit `paused` or `archived`, so
  /// pausing goal A to run goal B never deletes anything.
  Future<Journey?> loadActive() async {
    final all = await loadAll();
    for (final j in all) {
      if (j.state == JourneyState.active) return j;
    }
    return null;
  }

  /// Writes a journey and replaces its whole tree in one transaction.
  ///
  /// Replace rather than diff: a plan is regenerated as a unit, and a partial
  /// update is how a tree ends up with orphans.
  Future<void> save(Journey journey) async {
    await _db.transaction(() async {
      await _db
          .into(_db.businessJourneysTable)
          .insertOnConflictUpdate(
            BusinessJourneysTableCompanion.insert(
              id: journey.id,
              goalId: journey.goalId,
              state: journey.state.code,
              activePlanVersion: Value(journey.activePlanVersion),
              createdAt: journey.createdAt,
              updatedAt: journey.updatedAt,
            ),
          );

      await (_db.delete(
        _db.businessJourneyNodesTable,
      )..where((t) => t.journeyId.equals(journey.id))).go();

      for (final n in journey.nodes) {
        await _db
            .into(_db.businessJourneyNodesTable)
            .insert(
              BusinessJourneyNodesTableCompanion.insert(
                id: n.id,
                journeyId: journey.id,
                parentId: Value(n.parentId),
                kind: n.kind.code,
                title: n.title,
                origin: n.origin.code,
                orderIndex: Value(n.orderIndex),
                state: n.state.code,
                completion: n.completion.code,
                derivedMetric: Value(n.derivedMetric),
                derivedTarget: Value(n.derivedTarget),
                reasonCodes: Value(_joinCodes(n.reasonCodes)),
                completedAt: Value(n.completedAt),
              ),
            );
      }

      // Plans are append-only: a new version is added, old ones are left
      // alone. Deleting them would remove the only evidence that the plan
      // changed, which is the whole reason versions exist.
      for (final p in journey.plans) {
        await _db
            .into(_db.businessJourneyPlansTable)
            .insertOnConflictUpdate(
              BusinessJourneyPlansTableCompanion.insert(
                journeyId: journey.id,
                version: p.version,
                generatedBy: p.generatedBy.code,
                generatedAt: p.generatedAt,
                reasonCodes: Value(_joinCodes(p.reasonCodes)),
              ),
            );
      }
    });
  }

  /// Removes everything. Used by restore (Replace semantics, ADR-TON-018).
  Future<void> deleteAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.businessJourneyPlansTable).go();
      await _db.delete(_db.businessJourneyNodesTable).go();
      await _db.delete(_db.businessJourneysTable).go();
    });
  }

  /// Maps a row, or `null` if this build cannot understand it.
  ///
  /// Unknown `kind`/`origin`/`state` drops the node rather than defaulting it
  /// (ADR-TON-018 rule for unknown enums). The AI invariants are re-checked
  /// here because constructor asserts are compiled out in release, so a
  /// hand-edited database must not be able to smuggle one past.
  JourneyNode? _node(BusinessJourneyNodesTableData n) {
    final kind = JourneyNodeKind.fromCode(n.kind);
    final origin = JourneyNodeOrigin.fromCode(n.origin);
    final state = JourneyNodeState.fromCode(n.state);
    if (kind == null || origin == null || state == null) return null;
    if (origin == JourneyNodeOrigin.ai &&
        (state == JourneyNodeState.done || n.parentId == null)) {
      return null;
    }
    return JourneyNode(
      id: n.id,
      journeyId: n.journeyId,
      parentId: n.parentId,
      kind: kind,
      title: n.title,
      origin: origin,
      orderIndex: n.orderIndex,
      state: state,
      completion:
          JourneyCompletion.fromCode(n.completion) ?? JourneyCompletion.manual,
      derivedMetric: n.derivedMetric,
      derivedTarget: n.derivedTarget,
      reasonCodes: _splitCodes(n.reasonCodes),
      completedAt: n.completedAt,
    );
  }

  static String? _joinCodes(List<String> codes) =>
      codes.isEmpty ? null : codes.join(',');

  static List<String> _splitCodes(String? raw) =>
      (raw == null || raw.isEmpty) ? const [] : raw.split(',');
}
