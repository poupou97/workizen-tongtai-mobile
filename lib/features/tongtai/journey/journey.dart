/// A journey and its plan (WTM-185, ADR-TON-021).
library;

import 'journey_node.dart';

/// A generated plan, identified by version. Re-planning adds a version rather
/// than overwriting, so a seller can always see that the plan changed.
class JourneyPlan {
  const JourneyPlan({
    required this.version,
    required this.generatedBy,
    required this.generatedAt,
    this.reasonCodes = const [],
  });

  final int version;

  /// Who generated it. Phase 2 is always [JourneyNodeOrigin.ruleTwin] —
  /// planning is a rule, not a model (ADR-TON-016).
  final JourneyNodeOrigin generatedBy;

  final DateTime generatedAt;

  /// Fixed tokens explaining the shape of the plan.
  final List<String> reasonCodes;
}

/// One goal, one plan, one tree.
class Journey {
  const Journey({
    required this.id,
    required this.goalId,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.activePlanVersion,
    this.nodes = const [],
    this.plans = const [],
  });

  final String id;

  /// The `BusinessGoal` this journey pursues.
  final String goalId;

  final JourneyState state;
  final int? activePlanVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Every node, flat. Callers that need the shape use [rootNodes] and
  /// [childrenOf] — the tree is assembled on read rather than stored nested,
  /// so a single query loads it and no node can be orphaned by a partial write.
  final List<JourneyNode> nodes;

  final List<JourneyPlan> plans;

  /// Nodes with no parent, in display order.
  List<JourneyNode> get rootNodes =>
      _sorted(nodes.where((n) => n.parentId == null));

  /// Direct children of [nodeId], in display order.
  List<JourneyNode> childrenOf(String nodeId) =>
      _sorted(nodes.where((n) => n.parentId == nodeId));

  static List<JourneyNode> _sorted(Iterable<JourneyNode> input) {
    final list = input.toList()
      ..sort((a, b) {
        final byOrder = a.orderIndex.compareTo(b.orderIndex);
        // Stable tiebreak on id: two nodes at the same index must not swap
        // places between reads, or the plan would appear to reorder itself.
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return List.unmodifiable(list);
  }

  /// Nodes whose parent is missing from [nodes].
  ///
  /// Should always be empty. Exposed rather than silently dropped because an
  /// orphan means a write went wrong, and hiding it would turn a data bug into
  /// a plan that quietly lost a branch.
  List<JourneyNode> get orphanNodes {
    final ids = {for (final n in nodes) n.id};
    return [
      for (final n in nodes)
        if (n.parentId != null && !ids.contains(n.parentId)) n,
    ];
  }

  /// How much of the plan is done, 0…1. `null` when there is nothing to
  /// measure — **not** `0`, because "no plan yet" and "no progress yet" are
  /// different answers and a seller deserves to be told which one they are in
  /// (the same `empty` vs `insufficient` distinction as ADR-TON-017).
  double? get completion {
    final leaves = nodes.where((n) => !nodes.any((c) => c.parentId == n.id));
    final total = leaves.length;
    if (total == 0) return null;
    final done = leaves.where((n) => n.isDone).length;
    return done / total;
  }

  Journey copyWith({
    JourneyState? state,
    int? activePlanVersion,
    DateTime? updatedAt,
    List<JourneyNode>? nodes,
    List<JourneyPlan>? plans,
  }) => Journey(
    id: id,
    goalId: goalId,
    state: state ?? this.state,
    activePlanVersion: activePlanVersion ?? this.activePlanVersion,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    nodes: nodes ?? this.nodes,
    plans: plans ?? this.plans,
  );
}
