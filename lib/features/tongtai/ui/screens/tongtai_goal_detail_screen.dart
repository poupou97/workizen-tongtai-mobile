import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/goal_action_plan.dart';
import '../../journey/goal_theme.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Goal Detail & Action Plan (WTM-88) — the tap target from the goals list.
///
/// Shows a goal's progress and pace, a rule-based [goalActionPlan] to reach it,
/// and short guidance tips (WTM-90, inline). The pencil action calls [onEdit] to
/// open the goal form. `clock` is injectable so pace and the plan are
/// deterministic under test.
///
/// When [realizedRevenue] is supplied (WTM-89), the screen adds a data-first
/// card showing the sales actually booked during the goal's window — real order
/// data alongside the seller's own (manual) progress. It is purely additive and
/// leaves the goal's manual progress/edit flow untouched.
class TongtaiGoalDetailScreen extends StatelessWidget {
  const TongtaiGoalDetailScreen({
    super.key,
    required this.goal,
    this.clock,
    this.onEdit,
    this.realizedRevenue,
  });

  final BusinessGoal goal;
  final DateTime Function()? clock;
  final VoidCallback? onEdit;

  /// Sales booked during the goal window, from real orders (WTM-89). Null when
  /// the caller has no order source; shown only for revenue-denominated goals.
  final double? realizedRevenue;

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
          const SizedBox(height: TongtaiDesignTokens.spacing4),

          // ── Real sales booked in the goal window (WTM-89) ────────────
          if (realizedRevenue != null && goal.targetAmount > 0) ...[
            _RealizedSalesCard(goal: goal, realized: realizedRevenue!),
            const SizedBox(height: TongtaiDesignTokens.spacing5),
          ] else
            const SizedBox(height: TongtaiDesignTokens.spacing1),

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

/// Data-first companion to [_ProgressCard] (WTM-89): the revenue actually booked
/// from real orders during the goal window, next to its share of the target.
/// Purely informational — it never overrides the goal's own manual progress.
class _RealizedSalesCard extends StatelessWidget {
  const _RealizedSalesCard({required this.goal, required this.realized});

  final BusinessGoal goal;
  final double realized;

  @override
  Widget build(BuildContext context) {
    final share = goal.targetAmount <= 0
        ? 0
        : (realized / goal.targetAmount * 100).round();
    const accent = TongtaiDesignTokens.producerGreen;
    return Container(
      key: const Key('goal-detail-realized'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.point_of_sale_outlined, size: 20, color: accent),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doanh thu thực tế trong kỳ · Booked sales this period',
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TongtaiFormatters.vndShort(realized)} · $share% mục tiêu',
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Từ đơn hàng đã ghi nhận · from recorded orders',
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
