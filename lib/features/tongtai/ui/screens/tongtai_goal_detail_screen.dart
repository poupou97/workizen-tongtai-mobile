import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/goal_action_plan.dart';
import '../../journey/goal_theme.dart';
import '../../../../core/l10n/app_strings.dart';

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
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(context.l10n.titleGoalDetail),
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
        elevation: 0,
        actions: [
          if (onEdit != null)
            IconButton(
              key: const Key('goal-detail-edit'),
              tooltip: context.l10n.goalEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TtSpace.x4),
        children: [
          // ── Type + pace + name ───────────────────────────────────────
          // Wrap, not Row: two Vietnamese badges side by side ran past a
          // 320 px screen at a 2.0x font (WTM-168). Wrapping to a second line
          // is the right answer for labels — truncating a goal's type is not.
          Wrap(
            spacing: TtSpace.x2,
            runSpacing: TtSpace.x2,
            children: [
              _Badge(
                label: goal.type.label(context.l10n.languageCode),
                tone: TtStatus.ai,
              ),
              _Badge(
                label: pace.label(context.l10n.languageCode),
                tone: tongtaiGoalPaceTone(pace),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x3),
          Text(
            goal.name,
            key: const Key('goal-detail-title'),
            style: TtType.h1.copyWith(color: TtColors.textPrimary),
          ),
          const SizedBox(height: TtSpace.x4),

          // ── Progress ─────────────────────────────────────────────────
          _ProgressCard(goal: goal, now: now, paceColor: paceColor),
          const SizedBox(height: TtSpace.x4),

          // ── Real sales booked in the goal window (WTM-89) ────────────
          if (realizedRevenue != null && goal.targetAmount > 0) ...[
            _RealizedSalesCard(goal: goal, realized: realizedRevenue!),
            const SizedBox(height: TtSpace.x5),
          ] else
            const SizedBox(height: TtSpace.x1),

          // ── Recommendation ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(TtSpace.x3),
            decoration: BoxDecoration(
              color: paceColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(TtRadius.sm),
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
                const SizedBox(width: TtSpace.x2),
                Expanded(
                  child: Text(
                    goal.recommendation(now),
                    style: TtType.body.copyWith(color: TtColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TtSpace.x5),

          // ── Action plan ──────────────────────────────────────────────
          _SectionTitle(context.l10n.sectionActionPlan),
          const SizedBox(height: TtSpace.x3),
          Column(
            key: const Key('goal-detail-plan'),
            children: [
              for (var i = 0; i < plan.length; i++)
                _PlanStep(index: i + 1, step: plan[i]),
            ],
          ),
          const SizedBox(height: TtSpace.x5),

          // ── Guidance tips ────────────────────────────────────────────
          _SectionTitle(context.l10n.sectionSuggestions),
          const SizedBox(height: TtSpace.x2),
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
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: TtType.display.copyWith(
                  color: paceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // The percentage is the headline; the label beside it is what
              // has to give way at a 2.0x font (WTM-168).
              Flexible(
                child: Text(
                  _progressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.body.copyWith(color: TtColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x2),
          ClipRRect(
            borderRadius: BorderRadius.circular(TtRadius.full),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: TtColors.surfaceTertiary,
              valueColor: AlwaysStoppedAnimation<Color>(paceColor),
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: context.l10n.goalDaysLeftLabel,
                  value: context.l10n.daysCount(goal.daysRemaining(now)),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: context.l10n.goalTimeElapsed,
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
    const accent = TtColors.success;
    return Container(
      key: const Key('goal-detail-realized'),
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TtRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.point_of_sale_outlined, size: 20, color: accent),
          const SizedBox(width: TtSpace.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.journeyRealizedTitle,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TongtaiFormatters.vndShort(realized)} · '
                  '${context.l10n.percentOfGoal(share)}',
                  style: TtType.body.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.journeyRealizedSource,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
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
          style: TtType.body.copyWith(
            color: TtColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;

  /// **Vai**, không phải màu (WTM-425). Hai lời gọi truyền hai vai thật —
  /// `ai` (loại mục tiêu do Tổng Tài phân) và nhịp độ từ `tongtaiGoalPaceTone`.
  final TtStatus tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x3, vertical: 4),
      decoration: BoxDecoration(
        color: tone.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.full),
        border: Border.all(color: tone.color),
      ),
      child: Text(
        label,
        style: TtType.body.copyWith(
          color: TtColors.readableOn(tone.color),
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
      style: TtType.h2.copyWith(
        color: TtColors.textPrimary,
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
    const accent = TtColors.ai;
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x3),
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
              style: TtType.body.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: TtSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.titleVi,
                  style: TtType.body.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detailVi,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
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
      padding: const EdgeInsets.only(bottom: TtSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: TtColors.textSecondary),
          ),
          Expanded(
            child: Text(
              text,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
