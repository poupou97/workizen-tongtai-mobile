import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/business_goal_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import 'tongtai_goal_form_screen.dart';

/// Color for a [GoalPace] badge. Pure function — unit-testable without a
/// widget (same convention as `tongtaiCustomerTierColor`).
Color tongtaiGoalPaceColor(GoalPace pace) => switch (pace) {
  GoalPace.ahead => TongtaiDesignTokens.success,
  GoalPace.onTrack => TongtaiDesignTokens.info,
  GoalPace.behind => TongtaiDesignTokens.error,
  GoalPace.completed => TongtaiDesignTokens.success,
  GoalPace.notStarted => TongtaiDesignTokens.neutral,
};

/// Business Goals screen (WTM-87) — the entry surface of the Journey epic.
///
/// Lists the seller's goals newest-updated first with progress, pace and a
/// rule-based recommendation (AC4/AC5); the FAB starts the multi-step goal
/// form (AC1/AC2) and tapping a card edits it (AC3). Local-first over the
/// in-memory [BusinessGoalController]; the AI step-plan arrives with WTM-88.
class TongtaiGoalsScreen extends StatefulWidget {
  const TongtaiGoalsScreen({super.key, this.controller, this.clock});

  /// Injectable goal set. When provided it is *not* disposed here.
  final BusinessGoalController? controller;

  /// Injectable clock for pace/recommendation rendering (defaults to
  /// [DateTime.now]).
  final DateTime Function()? clock;

  @override
  State<TongtaiGoalsScreen> createState() => _TongtaiGoalsScreenState();
}

class _TongtaiGoalsScreenState extends State<TongtaiGoalsScreen> {
  late final BusinessGoalController _controller;
  late final bool _ownsController;
  late final DateTime Function() _clock;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = BusinessGoalController.sample();
      _ownsController = true;
    }
    _clock = widget.clock ?? DateTime.now;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm(BuildContext context, {BusinessGoal? goal}) async {
    final result = await Navigator.of(context).push<BusinessGoal>(
      MaterialPageRoute(
        builder: (_) => TongtaiGoalFormScreen(goal: goal, clock: widget.clock),
      ),
    );
    if (!context.mounted || result == null) return;
    _controller.upsert(result);
  }

  @override
  Widget build(BuildContext context) {
    final now = _clock();
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final goals = _controller.goals;
        return Scaffold(
          backgroundColor: TongtaiDesignTokens.lightBackground,
          appBar: AppBar(
            title: const Text('Business Goals'),
            elevation: 0,
            backgroundColor: TongtaiDesignTokens.lightBackground,
            foregroundColor: TongtaiDesignTokens.lightTextPrimary,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            backgroundColor: TongtaiDesignTokens.financePurple,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New goal'),
          ),
          body: SafeArea(
            child: goals.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
                    itemCount: goals.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: TongtaiDesignTokens.spacing3),
                    itemBuilder: (context, index) => _GoalCard(
                      goal: goals[index],
                      now: now,
                      onTap: () => _openForm(context, goal: goals[index]),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.now, required this.onTap});

  final BusinessGoal goal;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pace = goal.pace(now);
    final color = tongtaiGoalPaceColor(pace);
    return InkWell(
      key: Key('goal-card-${goal.id}'),
      borderRadius: BorderRadius.circular(TongtaiDesignTokens.cardBorderRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
        decoration: BoxDecoration(
          color: TongtaiDesignTokens.lightBackground,
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.cardBorderRadius,
          ),
          border: Border.all(color: TongtaiDesignTokens.lightBorder),
          boxShadow: TongtaiDesignTokens.elevation1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TongtaiDesignTokens.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TongtaiDesignTokens.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: TongtaiDesignTokens.spacing2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TongtaiDesignTokens.spacing2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      TongtaiDesignTokens.radiusFull,
                    ),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    pace.labelVi,
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              [
                goal.type.labelVi,
                if (goal.targetAmount > 0)
                  TongtaiFormatters.vnd(goal.targetAmount),
                'còn ${goal.daysRemaining(now)} ngày',
              ].join(' • '),
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.radiusFull,
              ),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: TongtaiDesignTokens.lightHover,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              '${(goal.progress * 100).round()}%',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              goal.recommendation(now),
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 48,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              'Đặt mục tiêu kinh doanh đầu tiên của bạn',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              'Set your first business goal.',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
