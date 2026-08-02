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

  /// Turns an opportunity into a piece of work in [journey] (WTM-191).
  ///
  /// Before this, deciding to pursue an opportunity was a dead end: the feed
  /// recorded the seller's interest and nothing downstream ever used it. The
  /// Concept treats an opportunity as an *input to the journey*, and this is
  /// the edge that makes that true.
  ///
  /// The node is authored by the **seller**, not the AI: a model may describe
  /// an opportunity, but only a person decides to chase one (ADR-TON-016). It
  /// starts `pending` — committing to work is not doing it.
  ///
  /// Returns the journey unchanged if [opportunityId] is already linked, so
  /// tapping twice cannot produce two copies of the same commitment.
  Future<Journey> addFromOpportunity(
    Journey journey, {
    required String opportunityId,
    required String title,
    required String nodeId,
  }) async {
    if (journey.nodes.any((n) => n.sourceOpportunityId == opportunityId)) {
      return journey;
    }
    final now = _clock();
    final node = JourneyNode(
      id: nodeId,
      journeyId: journey.id,
      // A root: the seller's own commitment sits beside the planned
      // milestones rather than buried inside one the rules invented. Allowed
      // because `origin == user` — only AI-authored nodes may not be roots.
      kind: JourneyNodeKind.mission,
      title: title,
      origin: JourneyNodeOrigin.user,
      orderIndex: _nextRootOrder(journey),
      reasonCodes: const [JourneyReason.fromOpportunity],
      sourceOpportunityId: opportunityId,
    );
    final updated = journey.copyWith(
      updatedAt: now,
      nodes: [...journey.nodes, node],
    );
    await _repository.save(updated);
    return updated;
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
    // What the seller put there is not the planner's to remove (WTM-191).
    // The rules own the plan; a commitment the seller made — an opportunity
    // they chose to chase — is a decision, and re-planning is not a licence to
    // delete decisions. Kept whole, including its state.
    final retainedIds = _sellerSubtreeIds(journey);
    final now = _clock();
    final updated = journey.copyWith(
      activePlanVersion: version,
      updatedAt: now,
      nodes: [
        for (final n in result.nodes)
          doneTitles.contains(n.title)
              ? n.copyWith(state: JourneyNodeState.done, completedAt: now)
              : n,
        for (final n in journey.nodes)
          if (retainedIds.contains(n.id)) n,
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
    var updated = journey.copyWith(nodes: nodes, updatedAt: now);
    // WTM-226: a journey that finishes has to be ABLE to finish.
    // `JourneyState.completed` existed from the start and nothing ever set it,
    // so a seller who did all the work was left staring at a 100% bar that
    // never became anything. State follows the tree — derived here, recorded
    // once, never a parallel flag.
    if (updated.isPlanComplete && updated.state == JourneyState.active) {
      updated = updated.copyWith(state: JourneyState.completed);
    }
    await _repository.save(updated);
    return updated;
  }

  /// The next free order index among roots, so a new commitment lands after
  /// what is already there rather than jumping the queue.
  static int _nextRootOrder(Journey journey) {
    var max = -1;
    for (final n in journey.nodes) {
      if (n.isRoot && n.orderIndex > max) max = n.orderIndex;
    }
    return max + 1;
  }

  /// Every seller-authored node **and everything hanging beneath it**, to any
  /// depth.
  ///
  /// One set rather than two lists: a node can be both seller-authored and the
  /// child of another seller-authored node, and emitting it from two places
  /// produced a duplicate id — caught by the table's unique constraint, which
  /// is exactly the kind of thing that constraint is for.
  ///
  /// Keeping a commitment while dropping its children would leave the header
  /// standing and quietly delete the work underneath it.
  static Set<String> _sellerSubtreeIds(Journey journey) {
    final keep = {
      for (final n in journey.nodes)
        if (n.origin == JourneyNodeOrigin.user) n.id,
    };
    var frontier = keep.toSet();
    while (frontier.isNotEmpty) {
      final next = <String>{};
      for (final n in journey.nodes) {
        if (n.parentId != null &&
            frontier.contains(n.parentId) &&
            keep.add(n.id)) {
          next.add(n.id);
        }
      }
      frontier = next;
    }
    return keep;
  }

  static int _nextVersion(Journey journey) {
    var max = 0;
    for (final p in journey.plans) {
      if (p.version > max) max = p.version;
    }
    return max + 1;
  }
}
