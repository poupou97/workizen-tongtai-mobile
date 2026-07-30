import 'package:flutter/material.dart';

import '../../navigation/tongtai_design_tokens.dart';
import '../../opportunity/opportunity_signals.dart';
import '../../opportunity/opportunity_theme.dart';
import '../../../../core/l10n/app_strings.dart';

/// A wrap of rule-based [OpportunitySignal] badges (WTM-130), in a stable
/// severity order. Shared by the Opportunity feed and detail screens so they
/// never drift. Renders nothing when [signals] is empty.
class TongtaiOpportunitySignalBadges extends StatelessWidget {
  const TongtaiOpportunitySignalBadges({super.key, required this.signals});

  final Set<OpportunitySignal> signals;

  static IconData _icon(OpportunitySignal s) => switch (s) {
    OpportunitySignal.highValue => Icons.star,
    OpportunitySignal.highRisk => Icons.warning_amber_rounded,
    OpportunitySignal.urgent => Icons.bolt,
    OpportunitySignal.stale => Icons.hourglass_bottom,
  };

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) return const SizedBox.shrink();
    final ordered = OpportunitySignal.values
        .where(signals.contains)
        .toList(growable: false);
    return Wrap(
      spacing: TongtaiDesignTokens.spacing2,
      runSpacing: TongtaiDesignTokens.spacing1,
      children: [
        for (final s in ordered)
          Container(
            key: Key('opportunity-signal-${s.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tongtaiOpportunitySignalColor(s).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.radiusFull,
              ),
              border: Border.all(color: tongtaiOpportunitySignalColor(s)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icon(s),
                  size: 11,
                  color: tongtaiOpportunitySignalColor(s),
                ),
                const SizedBox(width: 3),
                Text(
                  s.label(context.l10n.languageCode),
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: tongtaiOpportunitySignalColor(s),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
