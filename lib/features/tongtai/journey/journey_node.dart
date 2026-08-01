/// Business Journey domain — the tree, not the four tables (WTM-185).
///
/// Implements ADR-TON-021. The Concept describes six layers
/// (`Intent → Plan → Milestone → Mission → Step → Task`); the product had the
/// first one and a progress bar, so it could answer *"how far along am I"* but
/// not the question that defines a Journey: ***"am I on track?"*** — there was
/// no plan to compare against.
///
/// ## One recursive node, four kinds
/// A new kind of node (`decision`, `review`, `gate`) is a new enum value, not a
/// migration. Depth is free: a milestone may contain a milestone.
///
/// ## Everything here is a code, never a label
/// Same rule as `.ttbk` v2 (ADR-TON-018) and `BusinessProfile` (WTM-177):
/// labels are localized, so a stored label changes meaning when the seller
/// switches language.
library;

/// Where a journey is in its life (ADR-TON-021 · Bible "Journey States").
enum JourneyState {
  draft('draft'),
  active('active'),
  paused('paused'),
  completed('completed'),
  archived('archived');

  const JourneyState(this.code);

  final String code;

  static JourneyState? fromCode(String? code) {
    if (code == null) return null;
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// What a node *is*. Adding a kind here is the whole cost of a new node type.
enum JourneyNodeKind {
  milestone('milestone'),
  mission('mission'),
  step('step'),
  task('task');

  const JourneyNodeKind(this.code);

  final String code;

  static JourneyNodeKind? fromCode(String? code) {
    if (code == null) return null;
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Where a node is in its own life.
///
/// `skipped` and `blocked` are not in the Bible's list, but the Bible requires
/// *"Failure Recovery — if a step fails, AI suggests alternatives"*. Without
/// `blocked` there is no way to say a step failed, and that rule cannot exist.
enum JourneyNodeState {
  pending('pending'),
  inProgress('in_progress'),
  done('done'),
  skipped('skipped'),
  blocked('blocked');

  const JourneyNodeState(this.code);

  final String code;

  static JourneyNodeState? fromCode(String? code) {
    if (code == null) return null;
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// **Who created this node.**
///
/// The most important field in this file. ADR-TON-016 says *Rule Twin
/// authoritative, AI only explains*. Without recording the author, six months
/// from now nobody can tell which steps a rule produced and which a model
/// said — and that boundary becomes a claim in a document rather than
/// something a test can check.
///
/// Two invariants enforced by [JourneyNode] and pinned by test:
/// - a node with `origin == ai` may **never** be `done` — AI proposes, a person
///   completes;
/// - a node with `origin == ai` may **never** be a root — an AI suggestion
///   hangs off something a rule or a person put there.
enum JourneyNodeOrigin {
  user('user'),
  ruleTwin('rule_twin'),
  ai('ai');

  const JourneyNodeOrigin(this.code);

  final String code;

  static JourneyNodeOrigin? fromCode(String? code) {
    if (code == null) return null;
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// How a node gets marked done.
///
/// `derived` ties completion to a real measurement. This is what makes the
/// later AI capabilities possible at all: *"you are behind"* and *"18 days to
/// goal"* need progress to be an **observation**, not a checkbox. A journey
/// made only of manual ticks lets an AI read back exactly what the seller just
/// typed, and nothing more.
enum JourneyCompletion {
  manual('manual'),
  derived('derived');

  const JourneyCompletion(this.code);

  final String code;

  static JourneyCompletion? fromCode(String? code) {
    if (code == null) return null;
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// One node in a journey tree.
class JourneyNode {
  JourneyNode({
    required this.id,
    required this.journeyId,
    required this.kind,
    required this.title,
    required this.origin,
    this.parentId,
    this.orderIndex = 0,
    this.state = JourneyNodeState.pending,
    this.completion = JourneyCompletion.manual,
    this.derivedMetric,
    this.derivedTarget,
    this.reasonCodes = const [],
    this.completedAt,
  }) : assert(
         !(origin == JourneyNodeOrigin.ai && state == JourneyNodeState.done),
         'ADR-TON-016: AI proposes, a person completes. An AI-authored node '
         'may never mark itself done.',
       ),
       assert(
         !(origin == JourneyNodeOrigin.ai && parentId == null),
         'ADR-TON-021: an AI suggestion may not be a root. It hangs off a node '
         'a rule or a person put there, so it can never grow an orphan branch.',
       );

  final String id;
  final String journeyId;

  /// `null` = root of the tree.
  final String? parentId;

  final JourneyNodeKind kind;
  final String title;
  final JourneyNodeOrigin origin;
  final int orderIndex;
  final JourneyNodeState state;
  final JourneyCompletion completion;

  /// Which real number decides completion when [completion] is `derived`
  /// (e.g. `revenue`, `orders`, `customers`). `null` for manual nodes.
  final String? derivedMetric;

  /// The value [derivedMetric] must reach.
  final double? derivedTarget;

  /// Why a rule produced this node. Fixed tokens, never built from data — the
  /// same discipline as `TongtaiFailure.code` and the Opportunity signals, so
  /// they stay safe for telemetry.
  final List<String> reasonCodes;

  final DateTime? completedAt;

  bool get isRoot => parentId == null;
  bool get isDone => state == JourneyNodeState.done;

  JourneyNode copyWith({
    String? parentId,
    JourneyNodeKind? kind,
    String? title,
    JourneyNodeOrigin? origin,
    int? orderIndex,
    JourneyNodeState? state,
    JourneyCompletion? completion,
    String? derivedMetric,
    double? derivedTarget,
    List<String>? reasonCodes,
    DateTime? completedAt,
  }) => JourneyNode(
    id: id,
    journeyId: journeyId,
    parentId: parentId ?? this.parentId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    origin: origin ?? this.origin,
    orderIndex: orderIndex ?? this.orderIndex,
    state: state ?? this.state,
    completion: completion ?? this.completion,
    derivedMetric: derivedMetric ?? this.derivedMetric,
    derivedTarget: derivedTarget ?? this.derivedTarget,
    reasonCodes: reasonCodes ?? this.reasonCodes,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'parentId': parentId,
    'kind': kind.code,
    'title': title,
    'origin': origin.code,
    'orderIndex': orderIndex,
    'state': state.code,
    'completion': completion.code,
    'derivedMetric': derivedMetric,
    'derivedTarget': derivedTarget,
    'reasonCodes': reasonCodes,
    'completedAt': completedAt?.toIso8601String(),
  };

  /// Returns `null` for a row this build cannot understand.
  ///
  /// A node with an unknown `kind`, `state` or `origin` is **dropped**, not
  /// coerced to a default — the same rule ADR-TON-018 sets for restoring an
  /// unknown enum. Guessing turns missing information into confident wrong
  /// information, and here it would put a step in someone's plan that the
  /// rules never produced.
  static JourneyNode? fromJson(Map<String, dynamic> json) {
    final kind = JourneyNodeKind.fromCode(json['kind'] as String?);
    final origin = JourneyNodeOrigin.fromCode(json['origin'] as String?);
    final state = JourneyNodeState.fromCode(json['state'] as String?);
    final id = json['id'];
    final journeyId = json['journeyId'];
    if (kind == null ||
        origin == null ||
        state == null ||
        id is! String ||
        journeyId is! String) {
      return null;
    }
    final parentId = json['parentId'] as String?;
    // The invariants are constructor asserts, which are compiled out in
    // release. A file that violates them is rejected here so a hand-edited or
    // corrupted backup cannot smuggle in an AI-authored completed node.
    if (origin == JourneyNodeOrigin.ai &&
        (state == JourneyNodeState.done || parentId == null)) {
      return null;
    }
    return JourneyNode(
      id: id,
      journeyId: journeyId,
      parentId: parentId,
      kind: kind,
      title: json['title'] as String? ?? '',
      origin: origin,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      state: state,
      completion:
          JourneyCompletion.fromCode(json['completion'] as String?) ??
          JourneyCompletion.manual,
      derivedMetric: json['derivedMetric'] as String?,
      derivedTarget: (json['derivedTarget'] as num?)?.toDouble(),
      reasonCodes: [
        for (final c in (json['reasonCodes'] as List? ?? const []))
          if (c is String) c,
      ],
      completedAt: json['completedAt'] is String
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
