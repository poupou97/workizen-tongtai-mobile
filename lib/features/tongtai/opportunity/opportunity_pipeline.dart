import 'package:flutter/foundation.dart';

import 'opportunity.dart';

/// A summary of the open opportunity pipeline (WTM-98) — how many opportunities
/// are still open, their combined expected impact, and the strongest one.
@immutable
class OpportunityPipeline {
  const OpportunityPipeline({
    required this.activeCount,
    required this.pipelineValue,
    required this.top,
  });

  /// Opportunities not dismissed.
  final int activeCount;

  /// Combined expected impact (đồng) of the active opportunities.
  final double pipelineValue;

  /// The highest AI-scored active opportunity, or null when none are active.
  final Opportunity? top;

  bool get hasActive => activeCount > 0;

  static const OpportunityPipeline empty = OpportunityPipeline(
    activeCount: 0,
    pipelineValue: 0,
    top: null,
  );
}

/// Summarises the open pipeline from [opportunities] (WTM-98). Dismissed
/// opportunities are excluded. Pure — no widgets — so it is unit-testable.
OpportunityPipeline opportunityPipeline(List<Opportunity> opportunities) {
  final active = opportunities.where((o) => !o.isDismissed).toList();
  if (active.isEmpty) return OpportunityPipeline.empty;
  final value = active.fold<double>(0, (sum, o) => sum + o.expectedImpact);
  final top = active.reduce((a, b) => a.aiScore >= b.aiScore ? a : b);
  return OpportunityPipeline(
    activeCount: active.length,
    pipelineValue: value,
    top: top,
  );
}
