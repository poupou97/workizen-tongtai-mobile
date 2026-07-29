import 'package:flutter/foundation.dart';

import '../core/capability_context_provider.dart';
import 'opportunity.dart';
import 'opportunity_signals.dart';

/// Opportunity-capability slice of the business snapshot (WTM-131). Counts the
/// **rule-based** signals (WTM-130) over the active opportunities — so it works
/// with AI off/offline. Keyed by [OpportunitySignal], so the backlog signals
/// (New / Won Recently / Lost Recently / Follow-up Today / No Activity / Near
/// Deadline) extend this summary just by extending the enum + classifier.
@immutable
class OpportunitySummary {
  const OpportunitySummary({required this.total, required this.bySignal});

  static const OpportunitySummary empty = OpportunitySummary(
    total: 0,
    bySignal: {},
  );

  /// Active (non-dismissed) opportunities.
  final int total;

  /// Count of active opportunities carrying each rule-based signal.
  final Map<OpportunitySignal, int> bySignal;

  int signal(OpportunitySignal s) => bySignal[s] ?? 0;

  factory OpportunitySummary.from(
    List<Opportunity> opportunities, {
    required DateTime now,
  }) {
    final active = opportunities.where((o) => !o.isDismissed).toList();
    final bySignal = <OpportunitySignal, int>{};
    for (final o in active) {
      for (final sig in opportunitySignals(o, now: now)) {
        bySignal[sig] = (bySignal[sig] ?? 0) + 1;
      }
    }
    return OpportunitySummary(total: active.length, bySignal: bySignal);
  }
}

/// The Opportunity capability's Context Provider (WTM-131). Produces the
/// [OpportunitySummary] slice from the current opportunities using the rule-based
/// classifier. Since WTM-139 the real app wires [source] to the
/// `OpportunityRuleEngine` over the live repositories — a real business reads a
/// real generated summary (empty until its data produces signals, User Data
/// First). Rule-based → no AI, no network.
class OpportunityContextProvider
    implements CapabilityContextProvider<OpportunitySummary> {
  const OpportunityContextProvider({
    this.opportunities = const [],
    this.source,
    this.clock,
  });

  /// Static opportunities to summarise (demo/tests).
  final List<Opportunity> opportunities;

  /// Async source of the current opportunities (WTM-139: the rule engine over
  /// live repositories). Takes precedence over [opportunities] when present.
  final Future<List<Opportunity>> Function()? source;

  /// Injectable clock for the rule-based signals; defaults to [DateTime.now].
  final DateTime Function()? clock;

  @override
  Future<OpportunitySummary> load() async => OpportunitySummary.from(
    source != null ? await source!() : opportunities,
    now: (clock ?? DateTime.now)(),
  );
}
