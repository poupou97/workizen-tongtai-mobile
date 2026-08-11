import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../journey/journey.dart';
import '../../journey/journey_node.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../widgets/tongtai_screen_data.dart' show TongtaiAsyncScreenData;
import 'tongtai_opportunity_feed_screen.dart';
import 'tongtai_inventory_screen.dart';
import 'tongtai_finance_screen.dart';
import 'tongtai_customer_list_screen.dart';
import '../../journey/journey_metric.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_business_inputs_screen.dart';

/// The journey, shown as the tiered plan the Concept describes (WTM-187).
///
/// Until now Business Journey was a goal with a progress bar reached from a
/// settings list, so the app could say *how far along* but not *whether the
/// seller is on track* — the distinction the Concept uses to separate a Journey
/// from a workflow.
///
/// ## Three states, deliberately distinct
/// - **empty** — no journey yet; the seller has not started one.
/// - **insufficient** — a journey cannot be planned yet because the business
///   has nothing in it. That is an answer, not a failure (ADR-TON-017), and it
///   beats handing someone eight generic steps that fit nobody.
/// - **ready** — the plan.
///
/// ## Every step says where it came from
/// A node authored by the rule engine is labelled as such, and a step that
/// completes itself from real numbers says so. Without that, a seller cannot
/// tell which parts of their plan they decided and which the app proposed —
/// and ADR-TON-016's boundary would be invisible exactly where it matters most.
class TongtaiJourneyScreen extends ConsumerWidget {
  const TongtaiJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final journeys = ref.watch(journeysProvider);

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(title: Text(l10n.journeyTitle)),
      body: SafeArea(
        child: TongtaiAsyncScreenData<List<Journey>>(
          prefix: 'journey',
          async: journeys,
          onRetry: () async => ref.invalidate(journeysProvider),
          isEmpty: (list) => list.isEmpty,
          emptyBuilder: (context) => _Message(
            key: const Key('journey-empty-message'),
            title: l10n.journeyEmptyTitle,
            body: l10n.journeyEmptyBody,
          ),
          builder: (context, list) {
            final journey = list.firstWhere(
              (j) => j.state == JourneyState.active,
              orElse: () => list.first,
            );
            return _JourneyPlan(
              journey: journey,
              onDo: (d) => _openDestination(context, ref, d),
              // Invite, never auto-create: only the seller sets goals
              // (WTM-191), so the app opens the place and stops there.
              onSetNextGoal: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const TongtaiGoalsScreen()),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Opens the capability a step's work happens in, then **closes the loop**
  /// (WTM-220).
  ///
  /// `push`, deliberately — not a tab switch: popping puts the seller back on
  /// the journey they left, which is the third thing the Founder's rule asks
  /// for ("đi tới được · hoàn thành được luồng · **quay lại Journey**").
  ///
  /// On the way back the journey is re-read, and the read path measures it
  /// (WTM-224). `refreshDerived` had **no production caller at all** until
  /// WTM-220, so a step tied to `expenses >= 5` never ticked itself; WTM-220
  /// then called it here, which only covered sellers who happened to start
  /// from the journey. The measurement now belongs to reading the journey,
  /// wherever the work was done.
  Future<void> _openDestination(
    BuildContext context,
    WidgetRef ref,
    JourneyDestination destination,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => switch (destination) {
          JourneyDestination.finance => const TongtaiFinanceScreen(),
          JourneyDestination.customers => const TongtaiCustomerListScreen(),
          JourneyDestination.inventory => const TongtaiInventoryScreen(),
          JourneyDestination.opportunity =>
            const TongtaiOpportunityFeedScreen(),
          JourneyDestination.inputs => const TongtaiBusinessInputsScreen(),
        },
      ),
    );

    // WTM-224: the measuring moved INTO the read path, so all this has to do
    // is re-read. Doing the arithmetic here was the bug — it tied "the journey
    // notices your work" to a navigation gesture, and a seller who records the
    // same expenses straight from the Finance tab never made that gesture.
    ref.invalidate(journeyMetricsProvider);
    ref.invalidate(journeysProvider);
  }
}

class _JourneyPlan extends StatelessWidget {
  const _JourneyPlan({
    required this.journey,
    required this.onDo,
    required this.onSetNextGoal,
  });

  final Journey journey;
  final ValueChanged<JourneyDestination> onDo;
  final VoidCallback onSetNextGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roots = journey.rootNodes;

    // A journey with no nodes means the planner refused: the business has
    // nothing to plan against yet. Saying so is more useful than an empty list.
    if (roots.isEmpty) {
      return _Message(
        key: const Key('journey-insufficient-message'),
        title: l10n.journeyInsufficientTitle,
        body: l10n.journeyInsufficientBody,
      );
    }

    final completion = journey.completion;
    return ListView(
      key: const Key('journey-list'),
      padding: const EdgeInsets.all(TtSpace.x4),
      children: [
        // WTM-226 — the moment the seller finishes. `JourneyState.completed`
        // existed from the start and nothing ever set it, so someone who did
        // every step was left staring at a 100% bar that never became
        // anything: the most important moment in the product, and the product
        // said nothing.
        //
        // Deliberately says the PLAN is done, not that the goal was reached —
        // a seller can finish every step the Rule Twin planned and still be
        // short of their number. Saying the two are one thing would be the
        // app's first lie to them.
        if (journey.isPlanComplete) ...[
          _PlanDone(onSetNextGoal: onSetNextGoal),
          const SizedBox(height: TtSpace.x5),
        ],
        if (completion != null)
          _ProgressHeader(label: l10n.journeyProgress, value: completion),
        const SizedBox(height: TtSpace.x5),
        for (final milestone in roots) ...[
          _MilestoneTile(milestone: milestone, journey: journey, onDo: onDo),
          const SizedBox(height: TtSpace.x5),
        ],
      ],
    );
  }
}

class _PlanDone extends StatelessWidget {
  const _PlanDone({required this.onSetNextGoal});

  final VoidCallback onSetNextGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('journey-plan-done'),
      width: double.infinity,
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.journeyPlanDoneTitle,
            style: TtType.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          Text(
            l10n.journeyPlanDoneBody,
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
          const SizedBox(height: TtSpace.x3),
          OutlinedButton.icon(
            key: const Key('journey-set-next-goal'),
            onPressed: onSetNextGoal,
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.journeySetNextGoal),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('journey-progress'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label — ${(value * 100).round()}%',
          style: TtType.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(height: TtSpace.x2),
        ClipRRect(
          borderRadius: BorderRadius.circular(TtRadius.xs),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: TtColors.border,
          ),
        ),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.journey,
    required this.onDo,
  });

  final ValueChanged<JourneyDestination> onDo;

  final JourneyNode milestone;
  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final children = journey.childrenOf(milestone.id);
    return Column(
      key: Key('journey-milestone-${milestone.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              milestone.isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 20,
              color: milestone.isDone
                  ? TtColors.readableOn(TtColors.success)
                  : TtColors.textSecondary,
            ),
            const SizedBox(width: TtSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TtType.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TtColors.textPrimary,
                    ),
                  ),
                  // WTM-191: say where this came from. A commitment the seller
                  // made from an opportunity sits beside the rules' own
                  // milestones, and without this it reads as one of theirs.
                  if (milestone.isFromOpportunity)
                    _Tag(
                      key: Key('journey-milestone-source-${milestone.id}'),
                      label: context.l10n.journeyFromOpportunity,
                    ),
                ],
              ),
            ),
          ],
        ),
        for (final step in children)
          Padding(
            padding: const EdgeInsets.only(left: TtSpace.x8, top: TtSpace.x3),
            child: _StepTile(step: step, onDo: onDo),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.onDo});

  final JourneyNode step;

  /// Opens the capability where this step's work happens (WTM-220).
  final ValueChanged<JourneyDestination> onDo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destination = journeyNodeDestination(step);
    return Column(
      key: Key('journey-step-${step.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              step.isDone ? Icons.check : Icons.circle_outlined,
              size: 16,
              color: step.isDone
                  ? TtColors.readableOn(TtColors.success)
                  : TtColors.textSecondary,
            ),
            const SizedBox(width: TtSpace.x2),
            Expanded(
              child: Text(
                step.title,
                style: TtType.body.copyWith(
                  color: TtColors.textPrimary,
                  decoration: step.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: TtSpace.x6, top: TtSpace.x1),
          child: Wrap(
            spacing: TtSpace.x2,
            children: [
              if (step.origin == JourneyNodeOrigin.ruleTwin)
                _Tag(
                  key: Key('journey-step-origin-${step.id}'),
                  label: l10n.journeyFromRule,
                ),
              if (step.completion == JourneyCompletion.derived)
                _Tag(
                  key: Key('journey-step-measured-${step.id}'),
                  label: l10n.journeyMeasured,
                ),
              // The step that closes the loop (WTM-220). Until this button
              // existed the journey named the work and then abandoned the
              // seller: no way from "ghi 5 khoản chi" to the place expenses
              // are recorded. Only on steps that are still open and have an
              // honest destination — a button that goes nowhere is worse than
              // no button (WTM-169).
              if (!step.isDone && destination != null)
                TextButton(
                  key: Key('journey-step-do-${step.id}'),
                  onPressed: () => onDo(destination),
                  child: Text(l10n.journeyDoStep),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TtType.caption.copyWith(color: TtColors.textSecondary),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TtSpace.x6),
      children: [
        const SizedBox(height: TtSpace.x10),
        Text(title, style: TtType.h1.copyWith(color: TtColors.textPrimary)),
        const SizedBox(height: TtSpace.x3),
        Text(
          body,
          style: TtType.body.copyWith(
            color: TtColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
