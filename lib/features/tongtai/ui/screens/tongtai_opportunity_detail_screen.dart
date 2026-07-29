import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_action_plan.dart';
import '../../opportunity/opportunity_signals.dart';
import '../../opportunity/opportunity_theme.dart';
import '../widgets/tongtai_opportunity_signal_badges.dart';

/// Opportunity Detail & Action Plan (WTM-92).
///
/// Full view of one opportunity surfaced by the feed (WTM-91): headline, AI
/// relevance score, ROI and expected impact, the reasoning, and a rule-based
/// [opportunityActionPlan] to pursue it. The reaction callbacks are wired to the
/// feed's controller so save / interested / dismiss stay in sync.
class TongtaiOpportunityDetailScreen extends StatefulWidget {
  const TongtaiOpportunityDetailScreen({
    super.key,
    required this.opportunity,
    this.onToggleSaved,
    this.onInterested,
    this.onDismiss,
    this.clock,
  });

  final Opportunity opportunity;

  /// Injectable clock for the rule-based signals (WTM-130); defaults to
  /// [DateTime.now].
  final DateTime Function()? clock;

  final VoidCallback? onToggleSaved;
  final VoidCallback? onInterested;
  final VoidCallback? onDismiss;

  @override
  State<TongtaiOpportunityDetailScreen> createState() =>
      _TongtaiOpportunityDetailScreenState();
}

class _TongtaiOpportunityDetailScreenState
    extends State<TongtaiOpportunityDetailScreen> {
  late bool _saved = widget.opportunity.isSaved;

  Opportunity get _o => widget.opportunity;

  void _toggleSaved() {
    setState(() => _saved = !_saved);
    widget.onToggleSaved?.call();
  }

  void _interested() {
    widget.onInterested?.call();
    _closeWith('Đã đánh dấu quan tâm "${_o.title}"');
  }

  void _dismiss() {
    widget.onDismiss?.call();
    _closeWith('Đã bỏ qua "${_o.title}"');
  }

  void _closeWith(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = tongtaiOpportunityTypeColor(_o.type);
    final plan = opportunityActionPlan(_o);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Chi tiết cơ hội'),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('opportunity-detail-save'),
            tooltip: _saved ? 'Bỏ lưu' : 'Lưu lại',
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
              _TypeBadge(label: _o.type.labelVi, color: color),
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
                  label: 'ROI ước tính',
                  value: '${(_o.estimatedRoi * 100).round()}%',
                  accent: TongtaiDesignTokens.producerGreen,
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: _StatTile(
                  label: 'Tác động',
                  value: '+${TongtaiFormatters.vndShort(_o.expectedImpact)}',
                  accent: TongtaiDesignTokens.financePurple,
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: _StatTile(
                  label: 'Phát hiện',
                  value: TongtaiFormatters.isoDate(_o.discoveredAt),
                  accent: TongtaiDesignTokens.consumerBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Reasoning ────────────────────────────────────────────────
          Text(
            'Vì sao đáng làm',
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

          // ── Action plan ──────────────────────────────────────────────
          Text(
            'Kế hoạch hành động',
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

          // ── Reactions ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('opportunity-detail-dismiss'),
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close),
                  label: const Text('Bỏ qua'),
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
                  label: const Text('Quan tâm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TongtaiDesignTokens.producerGreen,
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.copilotViolet.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Column(
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
            'điểm AI',
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
