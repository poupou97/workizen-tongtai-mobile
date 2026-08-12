import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../ai/opportunity_ai.dart';
import '../../core/tongtai_formatters.dart';
import '../../core/screen_data_controller.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_action_plan.dart';
import '../../opportunity/opportunity_signals.dart';
import '../../journey/business_goal.dart';
import '../../journey/journey_controller.dart';
import '../../opportunity/opportunity_theme.dart';
import '../../providers/tongtai_ai_provider.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../widgets/tongtai_opportunity_signal_badges.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import 'tongtai_journey_screen.dart';

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
    _say(l10n.oppGoalCreatedSnack(_o.title));
  }

  /// Shows [message], replacing whatever is on screen.
  ///
  /// SnackBars queue by default, so a second tap's answer would sit behind the
  /// first one's — the seller taps, reads a stale message, and concludes
  /// nothing happened.
  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// WTM-191 — turn this opportunity into work inside the active journey.
  ///
  /// Complements [_createGoal] (WTM-94) rather than replacing it: a goal is
  /// the *target*, a journey node is the *work*. Before this, deciding to
  /// pursue an opportunity was a dead end — the app recorded the decision and
  /// nothing downstream ever used it.
  Future<void> _addToJourney() async {
    final l10n = context.l10n;
    final journey = await ref.read(activeJourneyProvider.future);
    if (!mounted) return;
    if (journey == null) {
      // An honest refusal beats inventing a journey the seller never asked
      // for: a journey belongs to a goal, and only the seller sets goals.
      _say(l10n.oppNoActiveJourney);
      return;
    }
    if (journey.nodes.any((n) => n.sourceOpportunityId == _o.id)) {
      _say(l10n.oppAlreadyInJourney);
      return;
    }
    final failure = await runTongtaiAction(
      () =>
          JourneyController(
            ref.read(journeyRepositoryProvider),
            clock: widget.clock ?? DateTime.now,
          ).addFromOpportunity(
            journey,
            opportunityId: _o.id,
            title: _o.title,
            nodeId: 'node-from-${_o.id}',
          ),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'opportunity',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: _addToJourney);
      return;
    }
    ref.invalidate(activeJourneyProvider);
    ref.invalidate(journeysProvider);
    _say(l10n.oppAddedToJourneySnack(_o.title));
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
    // Read from the journey itself, not from a local "I tapped it" flag: the
    // seller may have added this from another screen, or restored a backup.
    // The node carrying `sourceOpportunityId` IS the record (WTM-191), and a
    // second copy of that fact could disagree with it.
    final inJourney =
        ref
            .watch(activeJourneyProvider)
            .value
            ?.nodes
            .any((n) => n.sourceOpportunityId == _o.id) ??
        false;

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleOpportunityDetail),
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('opportunity-detail-save'),
            tooltip: _saved ? l10n.oppUnsaveTooltip : l10n.oppSaveTooltip,
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_outline,
              color: _saved ? TtColors.warning : TtColors.textSecondary,
            ),
            onPressed: _toggleSaved,
          ),
        ],
      ),
      // Stable test ID on the scroller so `tapByKey` can reach a control below
      // the fold. Without it `tester.tap` computes an off-screen offset, only
      // warns, and every later assertion runs on a screen nobody touched.
      body: ListView(
        key: const Key('opportunity-detail-list'),
        padding: const EdgeInsets.all(TtSpace.x4),
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
          const SizedBox(height: TtSpace.x3),
          Text(
            _o.title,
            key: const Key('opportunity-detail-title'),
            style: TtType.h1.copyWith(color: TtColors.textPrimary),
          ),
          Builder(
            builder: (context) {
              final signals = opportunitySignals(
                _o,
                now: (widget.clock ?? DateTime.now)(),
              );
              if (signals.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: TtSpace.x3),
                child: TongtaiOpportunitySignalBadges(signals: signals),
              );
            },
          ),
          const SizedBox(height: TtSpace.x4),

          // ── Key numbers ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  // WTM-384: nhãn nói con số là quan sát hay ước tính.
                  label: _o.impactBasis.isEstimate
                      ? l10n.oppImpact
                      : l10n.oppObservedPrefix,
                  value: tongtaiImpactAmount(_o, TongtaiFormatters.vndShort),
                  accent: TtColors.ai,
                ),
              ),
              const SizedBox(width: TtSpace.x3),
              Expanded(
                child: _StatTile(
                  label: l10n.oppDetected,
                  value: TongtaiFormatters.isoDate(_o.discoveredAt),
                  accent: TtColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x5),

          // ── Reasoning ────────────────────────────────────────────────
          Text(
            l10n.oppWhyWorth,
            style: TtType.h2.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          Text(
            _o.description,
            style: TtType.bodyLarge.copyWith(color: TtColors.textSecondary),
          ),
          const SizedBox(height: TtSpace.x5),

          // ── Workizen AI insight (WTM-141) — annotation only; the rule
          //    score stays authoritative. ─────────────────────────────────
          Container(
            key: const Key('opportunity-ai-section'),
            padding: const EdgeInsets.all(TtSpace.x3),
            decoration: BoxDecoration(
              color: TtColors.ai.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(TtRadius.sm),
              border: Border.all(color: TtColors.ai.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: TtColors.ai,
                    ),
                    const SizedBox(width: TtSpace.x2),
                    Expanded(
                      child: Text(
                        _insight == null
                            ? 'Workizen AI'
                            : 'Workizen AI — '
                                  '${_insight!.isAi ? (_insight!.provider?.displayName ?? 'AI') : 'Rule-based'}'
                                  '${_insight!.aiScore != null ? ' · ${l10n.aiScoreLabel} ${_insight!.aiScore!.round()}' : ''}',
                        style: TtType.caption.copyWith(
                          color: TtColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TtSpace.x2),
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
                    style: TtType.body.copyWith(
                      color: TtColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TtSpace.x5),

          // ── Action plan ──────────────────────────────────────────────
          Text(
            l10n.sectionActionPlan,
            style: TtType.h2.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          Column(
            key: const Key('opportunity-detail-plan'),
            children: [
              for (var i = 0; i < plan.length; i++)
                _PlanStep(index: i + 1, step: plan[i], accent: color),
            ],
          ),
          const SizedBox(height: TtSpace.x6),

          // ── Opportunity Action (WTM-94): opportunity → Journey goal ──
          OutlinedButton.icon(
            key: const Key('opportunity-create-goal'),
            onPressed: _createGoal,
            icon: const Icon(Icons.flag_outlined),
            label: Text(context.l10n.opportunityCreateGoal),
          ),
          const SizedBox(height: TtSpace.x3),
          // ── Business Loop (WTM-223, Founder 2026-08-02) ──────────────
          //
          // Beat 3 "thấy kết quả" and beat 4 "biết bước tiếp theo" must
          // OUTLIVE the action. A snackbar is explicitly not the end of a
          // business flow: it vanishes in seconds, so a seller who looked away
          // is left with a decision they made and no trace of where it went.
          //
          // Once this opportunity is in the journey the button is replaced by
          // its RESULT plus the way onward — contextual navigation, never an
          // automatic screen change: the seller may be working through several
          // opportunities and keeps the wheel.
          if (inJourney)
            Container(
              key: const Key('opportunity-in-journey'),
              width: double.infinity,
              padding: const EdgeInsets.all(TtSpace.x3),
              decoration: BoxDecoration(
                color: TtColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(TtRadius.md),
                border: Border.all(
                  color: TtColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: TtColors.successOnLight,
                      ),
                      const SizedBox(width: TtSpace.x2),
                      Expanded(
                        child: Text(
                          l10n.oppInJourney,
                          style: TtType.body.copyWith(
                            color: TtColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TtSpace.x2),
                  OutlinedButton.icon(
                    key: const Key('opportunity-open-journey'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const TongtaiJourneyScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.route_outlined),
                    label: Text(l10n.oppOpenJourney),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              key: const Key('opportunity-detail-add-to-journey'),
              onPressed: _addToJourney,
              icon: const Icon(Icons.route_outlined),
              label: Text(l10n.oppAddToJourney),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          const SizedBox(height: TtSpace.x3),

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
                    foregroundColor: TtColors.danger,
                    side: const BorderSide(color: TtColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: TtSpace.x3),
                  ),
                ),
              ),
              const SizedBox(width: TtSpace.x3),
              Expanded(
                child: TtPrimaryButton(
                  key: const Key('opportunity-detail-interested'),
                  label: l10n.oppInterested,
                  icon: Icons.thumb_up_alt_outlined,
                  onPressed: _interested,
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
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x3, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.full),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TtType.body.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  /// `null` when nothing could be computed (WTM-193).
  final double? score;

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
      padding: const EdgeInsets.all(TtSpace.x1),
      decoration: BoxDecoration(
        color: TtColors.ai.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            // A dash reads as "unknown"; a 0 would read as "worthless".
            score?.round().toString() ?? '—',
            style: TtType.h2.copyWith(
              color: TtColors.ai,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            context.l10n.aiScoreLabel,
            style: TtType.caption.copyWith(color: TtColors.ai, fontSize: 9),
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
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TtRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
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
