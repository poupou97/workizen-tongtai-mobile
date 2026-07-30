import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../consumer/customer_order.dart';
import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/business_goal_controller.dart';
import '../../journey/goal_theme.dart';
import '../../journey/journey_progress.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import 'tongtai_goal_detail_screen.dart';
import 'tongtai_goal_form_screen.dart';

// The pace→color helper now lives in goal_theme.dart (shared with the detail
// screen); re-exported so existing importers keep resolving it here.
export '../../journey/goal_theme.dart' show tongtaiGoalPaceColor;

/// Business Goals screen (WTM-87) — the entry surface of the Journey epic.
///
/// Lists the seller's goals newest-updated first with progress, pace and a
/// rule-based recommendation (AC4/AC5); the FAB starts the multi-step goal
/// form (AC1/AC2) and tapping a card edits it (AC3). Local-first over a
/// [BusinessGoalController] backed by a [BusinessGoalRepository] (WTM-124 —
/// Drift-backed for the real app, empty for a new user); the AI step-plan
/// arrives with WTM-88.
class TongtaiGoalsScreen extends ConsumerStatefulWidget {
  const TongtaiGoalsScreen({
    super.key,
    this.controller,
    this.clock,
    this.orders,
  });

  /// Injectable goal set. When provided it is *not* disposed here.
  final BusinessGoalController? controller;

  /// Injectable clock for pace/recommendation rendering (defaults to
  /// [DateTime.now]).
  final DateTime Function()? clock;

  /// Injectable orders for the real-sales insight on goal detail (WTM-89). When
  /// null in real mode the screen loads them from the Orders repository; in test
  /// mode (an injected [controller]) it defaults to none rather than touching a
  /// provider.
  final List<CustomerOrder>? orders;

  @override
  ConsumerState<TongtaiGoalsScreen> createState() => _TongtaiGoalsScreenState();
}

class _TongtaiGoalsScreenState extends ConsumerState<TongtaiGoalsScreen> {
  static const _progress = JourneyProgressService();

  late final BusinessGoalController _controller;
  late final bool _ownsController;
  late final DateTime Function() _clock;

  /// Real orders backing the goal-detail sales insight (WTM-89).
  List<CustomerOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      // Test mode: never reach for a provider — use whatever was injected.
      _orders = widget.orders ?? const [];
    } else {
      // Real app: persistent Drift goals (WTM-124), empty for new users.
      _controller = BusinessGoalController(
        ref.read(businessGoalRepositoryProvider),
      );
      _ownsController = true;
      _loadOrders();
    }
    _clock = widget.clock ?? DateTime.now;
    if (_ownsController) _controller.hydrate();
  }

  Future<void> _loadOrders() async {
    final orders =
        widget.orders ?? await ref.read(orderRepositoryProvider).loadAll();
    if (!mounted) return;
    setState(() => _orders = orders);
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
    await _controller.upsert(result);
  }

  /// Opens the goal detail (WTM-88) — progress, pace, action plan and tips —
  /// with an Edit action that closes it and opens the form.
  ///
  /// [display] is the auto-derived view (WTM-138); [original] is the persisted
  /// goal the edit form must receive (manual fields intact).
  void _openDetail(
    BuildContext context, {
    required BusinessGoal display,
    required BusinessGoal original,
  }) {
    // Data-first insight (WTM-89): sales booked in the goal window from real
    // orders — only meaningful for revenue-denominated goals.
    final realized = display.targetAmount > 0
        ? _progress.realizedRevenue(display, _orders, _clock())
        : null;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiGoalDetailScreen(
          goal: display,
          clock: widget.clock,
          realizedRevenue: realized,
          onEdit: () {
            Navigator.of(context).pop();
            _openForm(context, goal: original);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = _clock();
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final goals = _controller.goals;
        // Auto-derive (WTM-138, Founder default): revenue-goal progress comes
        // from real booked orders; the persisted goals stay untouched.
        final display = deriveGoalsProgress(goals, _orders, now);
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
                    itemCount: display.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: TongtaiDesignTokens.spacing3),
                    itemBuilder: (context, index) => _GoalCard(
                      goal: display[index],
                      now: now,
                      onTap: () => _openDetail(
                        context,
                        display: display[index],
                        original: goals[index],
                      ),
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
                    pace.label(context.l10n.languageCode),
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
                goal.type.label(context.l10n.languageCode),
                if (goal.targetAmount > 0)
                  TongtaiFormatters.vnd(goal.targetAmount),
                context.l10n.daysLeft(goal.daysRemaining(now)),
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
              context.l10n.goalsEmptyPrompt,
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
