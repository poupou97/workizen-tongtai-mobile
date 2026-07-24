import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/goal_action_plan.dart';
import '../../journey/goal_theme.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Goal Detail & Action Plan (WTM-88) — the tap target from the goals list.
///
/// Shows a goal's progress and pace (WTM-89), a rule-based [goalActionPlan] to
/// reach it, and short guidance tips (WTM-90, inline). The pencil action calls
/// [onEdit] to open the goal form. `clock` is injectable so pace and the plan
/// are deterministic under test.
class TongtaiGoalDetailScreen extends StatelessWidget {
  const TongtaiGoalDetailScreen({
    super.key,
    required this.goal,
    this.clock,
    this.onEdit,
  });

  final BusinessGoal goal;
  final DateTime Function()? clock;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final now = (clock ?? DateTime.now)();
    final pace = goal.pace(now);
    final paceColor = tongtaiGoalPaceColor(pace);
    final plan = goalActionPlan(goal, now);
    final tips = goalGuidanceTips(goal.type);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Chi tiết mục tiêu'),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
        actions: [
          if (onEdit != null)
            IconButton(
              key: const Key('goal-detail-edit'),
              tooltip: 'Sửa mục tiêu',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        children: [
          // ── Type + pace + name ───────────────────────────────────────
          Row(
            children: [
              _Badge(
                label: goal.type.labelVi,
                color: TongtaiDesignTokens.financePurple,
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing2),
              _Badge(label: pace.labelVi, color: paceColor),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            goal.name,
            key: const Key('goal-detail-title'),
            style: TongtaiDesignTokens.heading2Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing4),

          // ── Progress ─────────────────────────────────────────────────
          _ProgressCard(goal: goal, now: now, paceColor: paceColor),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Recommendation ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
            decoration: BoxDecoration(
              color: paceColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.componentBorderRadius,
              ),
              border: Border.all(color: paceColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: paceColor,
                ),
                const SizedBox(width: TongtaiDesignTokens.spacing2),
                Expanded(
                  child: Text(
                    goal.recommendation(now),
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Action plan ──────────────────────────────────────────────
          _SectionTitle('Kế hoạch hành động'),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Column(
            key: const Key('goal-detail-plan'),
            children: [
              for (var i = 0; i < plan.length; i++)
                _PlanStep(index: i + 1, step: plan[i]),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Guidance tips ────────────────────────────────────────────
          _SectionTitle('Gợi ý'),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          for (final tip in tips) _Tip(text: tip),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.goal,
    required this.now,
    required this.paceColor,
  });

  final BusinessGoal goal;
  final DateTime now;
  final Color paceColor;

  /// "achieved / target" — đồng for revenue goals, units for growth goals.
  String get _progressLabel {
    if (goal.targetAmount > 0) {
      return '${TongtaiFormatters.vndShort(goal.achievedAmount)}'
          ' / ${TongtaiFormatters.vndShort(goal.targetAmount)}';
    }
    if (goal.growthTarget > 0) {
      return '${goal.growthAchieved} / ${goal.growthTarget}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: TongtaiDesignTokens.displayStyle.copyWith(
                  color: paceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _progressLabel,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          ClipRRect(
            borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: TongtaiDesignTokens.lightHover,
              valueColor: AlwaysStoppedAnimation<Color>(paceColor),
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Còn lại',
                  value: '${goal.daysRemaining(now)} ngày',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Thời gian đã trôi',
                  value: '${(goal.timelineElapsed(now) * 100).round()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TongtaiDesignTokens.captionStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TongtaiDesignTokens.heading3Style.copyWith(
        color: TongtaiDesignTokens.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.index, required this.step});

  final int index;
  final GoalActionStep step;

  @override
  Widget build(BuildContext context) {
    const accent = TongtaiDesignTokens.financePurple;
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

class _Tip extends StatelessWidget {
  const _Tip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
