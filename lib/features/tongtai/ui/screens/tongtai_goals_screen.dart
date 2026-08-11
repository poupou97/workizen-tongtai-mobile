import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../consumer/customer_order.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/business_goal_controller.dart';
import '../../journey/goal_theme.dart';
import '../../journey/journey_progress.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_goal_detail_screen.dart';
import 'tongtai_goal_form_screen.dart';
import '../../providers/tongtai_data_invalidation.dart';

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

  /// Goal hydration AND the orders behind the sales insight (WTM-89), loaded
  /// as one unit (WTM-148). The controller stays the live source of goals —
  /// it changes on every upsert — so the state's value is the orders; what the
  /// controller adds is that a failing `hydrate()` is no longer invisible.
  late final ScreenDataController<List<CustomerOrder>> _data;

  List<CustomerOrder> get _orders => _data.state.value ?? const [];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      // Real app: persistent Drift goals (WTM-124), empty for new users.
      _controller = BusinessGoalController(
        ref.read(businessGoalRepositoryProvider),
      );
      _ownsController = true;
    }
    _clock = widget.clock ?? DateTime.now;
    _data = ScreenDataController<List<CustomerOrder>>(
      _read,
      // Injected controller ⇒ test/preview mode: the orders are whatever was
      // passed in, known synchronously.
      initialValue: _ownsController ? null : (widget.orders ?? const []),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'goals',
    )..start();
  }

  Future<List<CustomerOrder>> _read() async {
    if (_ownsController) await _controller.hydrate();
    // Test mode with an injected controller never reaches for a provider.
    if (!_ownsController) return widget.orders ?? const [];
    return widget.orders ?? await ref.read(orderRepositoryProvider).loadAll();
  }

  @override
  void dispose() {
    _data.dispose();
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
    // A save that fails must say so — silently losing a goal the seller just
    // typed is the write-side twin of the silent-empty bug (WTM-148).
    final failure = await runTongtaiAction(
      () => _controller.upsert(result),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'goals',
    );
    if (failure != null && context.mounted) {
      showTongtaiFailure(
        context,
        failure,
        onRetry: () => _openForm(context, goal: goal),
      );
      return;
    }
    // WTM-224 — a goal is what the journey is planned against, and what Home's
    // journey tile counts. Without the signal the seller sets a target and the
    // rest of the app keeps planning around the old one.
    if (context.mounted) invalidateBusinessDataProviders(ref);
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
      listenable: Listenable.merge([_controller, _data]),
      builder: (context, _) {
        final goals = _controller.goals;
        // Auto-derive (WTM-138, Founder default): revenue-goal progress comes
        // from real booked orders; the persisted goals stay untouched.
        final display = deriveGoalsProgress(goals, _orders, now);
        return Scaffold(
          backgroundColor: TtColors.surfaceSecondary,
          appBar: AppBar(
            title: Text(context.l10n.titleBusinessGoals),
            elevation: 0,
            backgroundColor: TtColors.surfaceSecondary,
            foregroundColor: TtColors.textPrimary,
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('goals-action-new'),
            onPressed: () => _openForm(context),
            backgroundColor: TtColors.readableOn(TtColors.ai),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.goalNew),
          ),
          body: SafeArea(
            child: TongtaiScreenData<List<CustomerOrder>>(
              prefix: 'goals',
              state: _data.state,
              onRetry: _data.retry,
              isEmpty: (_) => goals.isEmpty,
              emptyBuilder: (_) => const _EmptyState(),
              builder: (context, _) => ListView.separated(
                padding: const EdgeInsets.all(TtSpace.x4),
                itemCount: display.length,
                separatorBuilder: (context, _) =>
                    const SizedBox(height: TtSpace.x3),
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
      key: Key('goals-item-${goal.id}'),
      borderRadius: BorderRadius.circular(TtRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TtSpace.x3),
        decoration: BoxDecoration(
          color: TtColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(TtRadius.md),
          border: Border.all(color: TtColors.border),
          boxShadow: TtElevation.soft,
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
                    style: TtType.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TtColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: TtSpace.x2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TtSpace.x2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TtRadius.full),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    pace.label(context.l10n.languageCode),
                    style: TtType.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              [
                goal.type.label(context.l10n.languageCode),
                if (goal.targetAmount > 0)
                  TongtaiFormatters.vnd(goal.targetAmount),
                context.l10n.daysLeft(goal.daysRemaining(now)),
              ].join(' • '),
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
            const SizedBox(height: TtSpace.x2),
            ClipRRect(
              borderRadius: BorderRadius.circular(TtRadius.full),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: TtColors.surfaceTertiary,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              '${(goal.progress * 100).round()}%',
              style: TtType.caption.copyWith(
                color: TtColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TtSpace.x2),
            Text(
              goal.recommendation(now),
              style: TtType.caption.copyWith(color: TtColors.textPrimary),
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
      key: const Key('goals-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TtSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 48,
              color: TtColors.textSecondary,
            ),
            const SizedBox(height: TtSpace.x3),
            Text(
              context.l10n.goalsEmptyPrompt,
              textAlign: TextAlign.center,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
