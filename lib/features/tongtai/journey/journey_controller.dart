import 'journey.dart';
import 'journey_node.dart';
import 'journey_planner.dart';
import 'journey_repository.dart';

/// Turns a goal into a saved journey, and keeps derived steps honest
/// (WTM-186, ADR-TON-021).
///
/// The planner is a pure function; this is the thin layer that gives it ids and
/// a clock, writes the result, and re-evaluates measured steps against the real
/// numbers. Kept separate so the planner stays testable without a database.
class JourneyController {
  JourneyController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final JourneyRepository _repository;
  final DateTime Function() _clock;

  /// Creates a journey for [input] and stores it.
  ///
  /// Returns `null` when the planner refuses — a brand-new business with no
  /// catalog and no customers cannot be planned for, and an empty journey on
  /// screen would be worse than an honest empty state (ADR-TON-017).
  Future<Journey?> startJourney(
    JourneyPlanInput input, {
    required String journeyId,
  }) async {
    final result = planJourney(input, journeyId: journeyId);
    if (!result.isSufficient) return null;

    final now = _clock();
    final journey = Journey(
      id: journeyId,
      goalId: input.goal.id,
      state: JourneyState.active,
      activePlanVersion: 1,
      createdAt: now,
      updatedAt: now,
      nodes: result.nodes,
      plans: [
        JourneyPlan(
          version: 1,
          // Phase 2 plans are always rule-authored. When AI explanation lands
          // it still will be: ADR-TON-016 lets a model describe a plan, never
          // write one.
          generatedBy: JourneyNodeOrigin.ruleTwin,
          generatedAt: now,
          reasonCodes: result.reasonCodes,
        ),
      ],
    );
    await _repository.save(journey);
    return journey;
  }

  /// Re-plans [journey] and stores the result as a **new version**.
  ///
  /// The old version stays. The Concept requires the plan to adapt when
  /// circumstances change; overwriting would let it change under the seller
  /// with nothing to compare against and no way to ask why.
  ///
  /// Node state is carried over by title: a step the seller already finished
  /// must not reappear as pending just because the plan was regenerated.
  Future<Journey?> replan(Journey journey, JourneyPlanInput input) async {
    final version = _nextVersion(journey);
    final result = planJourney(
      input,
      journeyId: journey.id,
      idPrefix: 'n$version',
    );
    if (!result.isSufficient) return null;

    final doneTitles = {
      for (final n in journey.nodes)
        if (n.isDone) n.title,
    };
    final now = _clock();
    final updated = journey.copyWith(
      activePlanVersion: version,
      updatedAt: now,
      nodes: [
        for (final n in result.nodes)
          doneTitles.contains(n.title)
              ? n.copyWith(state: JourneyNodeState.done, completedAt: now)
              : n,
      ],
      plans: [
        ...journey.plans,
        JourneyPlan(
          version: version,
          generatedBy: JourneyNodeOrigin.ruleTwin,
          generatedAt: now,
          reasonCodes: result.reasonCodes,
        ),
      ],
    );
    await _repository.save(updated);
    return updated;
  }

  /// Marks a node done by hand and stores it.
  ///
  /// Refuses for an AI-authored node: ADR-TON-016 says a model proposes and a
  /// person completes, and this is the write path where that could be broken.
  Future<Journey> complete(Journey journey, String nodeId) async {
    final now = _clock();
    final updated = journey.copyWith(
      updatedAt: now,
      nodes: [
        for (final n in journey.nodes)
          if (n.id == nodeId && n.origin != JourneyNodeOrigin.ai)
            n.copyWith(state: JourneyNodeState.done, completedAt: now)
          else
            n,
      ],
    );
    await _repository.save(updated);
    return updated;
  }

  /// Re-evaluates every `derived` step against the real numbers in [metrics].
  ///
  /// This is what makes the journey answer *"am I on track"* rather than
  /// *"what did I tick"*: a step tied to `orders >= 50` becomes done because
  /// fifty orders exist, not because anyone remembered to say so.
  ///
  /// Only moves steps **forward**. A metric that dips — a refund, a corrected
  /// entry — must not silently un-finish work the seller already did.
  Future<Journey> refreshDerived(
    Journey journey,
    Map<String, double> metrics,
  ) async {
    final now = _clock();
    var changed = false;
    final nodes = [
      for (final n in journey.nodes)
        if (n.completion == JourneyCompletion.derived &&
            !n.isDone &&
            n.derivedMetric != null &&
            n.derivedTarget != null &&
            (metrics[n.derivedMetric] ?? 0) >= n.derivedTarget!)
          () {
            changed = true;
            return n.copyWith(state: JourneyNodeState.done, completedAt: now);
          }()
        else
          n,
    ];
    if (!changed) return journey;
    final updated = journey.copyWith(nodes: nodes, updatedAt: now);
    await _repository.save(updated);
    return updated;
  }

  static int _nextVersion(Journey journey) {
    var max = 0;
    for (final p in journey.plans) {
      if (p.version > max) max = p.version;
    }
    return max + 1;
  }
}
