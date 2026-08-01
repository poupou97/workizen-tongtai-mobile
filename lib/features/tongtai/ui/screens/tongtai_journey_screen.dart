import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../journey/journey.dart';
import '../../journey/journey_node.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../widgets/tongtai_screen_data.dart' show TongtaiAsyncScreenData;

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
      backgroundColor: TongtaiDesignTokens.lightBackground,
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
            return _JourneyPlan(journey: journey);
          },
        ),
      ),
    );
  }
}

class _JourneyPlan extends StatelessWidget {
  const _JourneyPlan({required this.journey});

  final Journey journey;

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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        if (completion != null)
          _ProgressHeader(label: l10n.journeyProgress, value: completion),
        const SizedBox(height: TongtaiDesignTokens.spacing5),
        for (final milestone in roots) ...[
          _MilestoneTile(milestone: milestone, journey: journey),
          const SizedBox(height: TongtaiDesignTokens.spacing5),
        ],
      ],
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
          style: TongtaiDesignTokens.bodyStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        ClipRRect(
          borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusSm),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: TongtaiDesignTokens.lightBorder,
          ),
        ),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone, required this.journey});

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
                  ? TongtaiDesignTokens.producerGreenText
                  : TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: Text(
                milestone.title,
                style: TongtaiDesignTokens.bodyStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        for (final step in children)
          Padding(
            padding: const EdgeInsets.only(
              left: TongtaiDesignTokens.spacing8,
              top: TongtaiDesignTokens.spacing3,
            ),
            child: _StepTile(step: step),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final JourneyNode step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  ? TongtaiDesignTokens.producerGreenText
                  : TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            Expanded(
              child: Text(
                step.title,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                  decoration: step.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: TongtaiDesignTokens.spacing6,
            top: TongtaiDesignTokens.spacing1,
          ),
          child: Wrap(
            spacing: TongtaiDesignTokens.spacing2,
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
      style: TongtaiDesignTokens.captionStyle.copyWith(
        color: TongtaiDesignTokens.lightTextSecondary,
      ),
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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing6),
      children: [
        const SizedBox(height: TongtaiDesignTokens.spacing10),
        Text(
          title,
          style: TongtaiDesignTokens.heading2Style.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        Text(
          body,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
