import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/opportunity_ai.dart';
import '../../core/tongtai_formatters.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_action_plan.dart';
import '../../opportunity/opportunity_signals.dart';
import '../../journey/business_goal.dart';
import '../../opportunity/opportunity_theme.dart';
import '../../providers/tongtai_ai_provider.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../widgets/tongtai_opportunity_signal_badges.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';

/// Opportunity Detail & Action Plan (WTM-92).
///
/// Full view of one opportunity surfaced by the feed (WTM-91): headline, AI
/// relevance score, ROI and expected impact, the reasoning, and a rule-based
/// [opportunityActionPlan] to pursue it. The reaction callbacks are wired to the
/// feed's controller so save / interested / dismiss stay in sync.
class TongtaiOpportunityDetailScreen extends ConsumerStatefulWidget {
  const TongtaiOpportunityDetailScreen({
    super.key,
    required this.opportunity,
    this.onToggleSaved,
    this.onInterested,
    this.onDismiss,
    this.clock,
    this.aiService,
  });

  final Opportunity opportunity;

  /// Injectable clock for the rule-based signals (WTM-130); defaults to
  /// [DateTime.now].
  final DateTime Function()? clock;

  final VoidCallback? onToggleSaved;
  final VoidCallback? onInterested;
  final VoidCallback? onDismiss;

  /// Injectable AI layer for tests (WTM-141); when null the screen uses
  /// [opportunityAiServiceProvider].
  final OpportunityAiService? aiService;

  @override
  ConsumerState<TongtaiOpportunityDetailScreen> createState() =>
      _TongtaiOpportunityDetailScreenState();
}

class _TongtaiOpportunityDetailScreenState
    extends ConsumerState<TongtaiOpportunityDetailScreen> {
  late bool _saved = widget.opportunity.isSaved;

  /// WTM-141: the on-demand AI insight. Null until requested.
  OpportunityAiInsight? _insight;
  bool _explaining = false;

  Future<void> _runExplain() async {
    if (_explaining) return;
    setState(() => _explaining = true);
    final OpportunityAiService service =
        widget.aiService ?? ref.read(opportunityAiServiceProvider);
    final insight = await service.explain(_o);
    if (!mounted) return;
    setState(() {
      _insight = insight;
      _explaining = false;
    });
  }

  Opportunity get _o => widget.opportunity;

  /// WTM-94 — Opportunity Action: one tap turns this opportunity into a
  /// Business Journey goal (idempotent id, so repeat taps never duplicate).
  Future<void> _createGoal() async {
    final l10n = context.l10n;
    final now = (widget.clock ?? DateTime.now)();
    final goal = BusinessGoal(
      id: 'goal-from-${_o.id}',
      name: _o.title,
      type: GoalType.revenue,
      targetAmount: _o.expectedImpact,
      achievedAmount: 0,
      growthTarget: 0,
      growthAchieved: 0,
      startDate: now,
      endDate: now.add(const Duration(days: 45)),
      notes: l10n.oppCreatedFromNote(_o.description),
      createdAt: now,
      updatedAt: now,
    );
    final failure = await runTongtaiAction(
      () => ref.read(businessGoalRepositoryProvider).upsert(goal),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'opportunity',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: _createGoal);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.oppGoalCreatedSnack(_o.title))));
  }

  void _toggleSaved() {
    setState(() => _saved = !_saved);
    widget.onToggleSaved?.call();
  }

  void _interested() {
    widget.onInterested?.call();
    _closeWith(context.l10n.oppInterestedSnack(_o.title));
  }

  void _dismiss() {
    widget.onDismiss?.call();
    _closeWith(context.l10n.oppDismissedSnack(_o.title));
  }

  void _closeWith(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = tongtaiOpportunityTypeColor(_o.type);
    final plan = opportunityActionPlan(_o);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleOpportunityDetail),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('opportunity-detail-save'),
            tooltip: _saved ? l10n.oppUnsaveTooltip : l10n.oppSaveTooltip,
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_outline,
              color: _saved
                  ? TongtaiDesignTokens.inventoryOrange
                  : TongtaiDesignTokens.lightTextSecondary,
            ),
            onPressed: _toggleSaved,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        children: [
          // ── Type + AI score + title ──────────────────────────────────
          Row(
            children: [
              _TypeBadge(
                label: _o.type.label(context.l10n.languageCode),
                color: color,
              ),
              const Spacer(),
              _ScoreBadge(score: _o.aiScore),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            _o.title,
            key: const Key('opportunity-detail-title'),
            style: TongtaiDesignTokens.heading2Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          Builder(
            builder: (context) {
              final signals = opportunitySignals(
                _o,
                now: (widget.clock ?? DateTime.now)(),
              );
              if (signals.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(
                  top: TongtaiDesignTokens.spacing3,
                ),
                child: TongtaiOpportunitySignalBadges(signals: signals),
              );
            },
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing4),

          // ── Key numbers ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: l10n.oppRoi,
                  value: '${(_o.estimatedRoi * 100).round()}%',
                  accent: TongtaiDesignTokens.producerGreen,
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: _StatTile(
                  label: l10n.oppImpact,
                  value: '+${TongtaiFormatters.vndShort(_o.expectedImpact)}',
                  accent: TongtaiDesignTokens.financePurple,
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: _StatTile(
                  label: l10n.oppDetected,
                  value: TongtaiFormatters.isoDate(_o.discoveredAt),
                  accent: TongtaiDesignTokens.consumerBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Reasoning ────────────────────────────────────────────────
          Text(
            l10n.oppWhyWorth,
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Text(
            _o.description,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Workizen AI insight (WTM-141) — annotation only; the rule
          //    score stays authoritative. ─────────────────────────────────
          Container(
            key: const Key('opportunity-ai-section'),
            padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
            decoration: BoxDecoration(
              color: TongtaiDesignTokens.copilotViolet.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.componentBorderRadius,
              ),
              border: Border.all(
                color: TongtaiDesignTokens.copilotViolet.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: TongtaiDesignTokens.copilotViolet,
                    ),
                    const SizedBox(width: TongtaiDesignTokens.spacing2),
                    Expanded(
                      child: Text(
                        _insight == null
                            ? 'Workizen AI'
                            : 'Workizen AI — '
                                  '${_insight!.isAi ? (_insight!.provider?.displayName ?? 'AI') : 'Rule-based'}'
                                  '${_insight!.aiScore != null ? ' · ${l10n.aiScoreLabel} ${_insight!.aiScore!.round()}' : ''}',
                        style: TongtaiDesignTokens.captionStyle.copyWith(
                          color: TongtaiDesignTokens.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TongtaiDesignTokens.spacing2),
                if (_explaining)
                  const TongtaiInlineBusy()
                else if (_insight == null)
                  OutlinedButton.icon(
                    key: const Key('opportunity-ai-explain'),
                    onPressed: _runExplain,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(context.l10n.aiInsight),
                  )
                else
                  Text(
                    _insight!.text,
                    key: const Key('opportunity-ai-insight-text'),
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Action plan ──────────────────────────────────────────────
          Text(
            l10n.sectionActionPlan,
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Column(
            key: const Key('opportunity-detail-plan'),
            children: [
              for (var i = 0; i < plan.length; i++)
                _PlanStep(index: i + 1, step: plan[i], accent: color),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing6),

          // ── Opportunity Action (WTM-94): opportunity → Journey goal ──
          OutlinedButton.icon(
            key: const Key('opportunity-create-goal'),
            onPressed: _createGoal,
            icon: const Icon(Icons.flag_outlined),
            label: Text(context.l10n.opportunityCreateGoal),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),

          // ── Reactions ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('opportunity-detail-dismiss'),
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.oppDismiss),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TongtaiDesignTokens.error,
                    side: const BorderSide(color: TongtaiDesignTokens.error),
                    padding: const EdgeInsets.symmetric(
                      vertical: TongtaiDesignTokens.spacing3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('opportunity-detail-interested'),
                  onPressed: _interested,
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: Text(l10n.oppInterested),
                  style: FilledButton.styleFrom(
                    backgroundColor: TongtaiDesignTokens.producerGreenText,
                    padding: const EdgeInsets.symmetric(
                      vertical: TongtaiDesignTokens.spacing3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TongtaiDesignTokens.smallStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Was a hard 52 px; at a 2.0x system font its own text no longer fits
      // and the badge clipped by 132 px (WTM-168). A minimum keeps the shape
      // without capping what has to be readable.
      // Was a hard 52x52 circle; at a 2.0x system font its own two lines no
      // longer fit and it clipped (WTM-168). A minimum keeps the shape at
      // normal sizes and lets it grow rather than swallow the score.
      constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing1),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.copilotViolet.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${score.round()}',
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.financePurple,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            context.l10n.aiScoreLabel,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.financePurple,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.index,
    required this.step,
    required this.accent,
  });

  final int index;
  final OpportunityActionStep step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.titleVi,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detailVi,
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
