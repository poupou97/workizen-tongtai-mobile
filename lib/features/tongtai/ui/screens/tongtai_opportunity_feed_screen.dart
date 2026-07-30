import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_feed_controller.dart';
import '../../opportunity/opportunity_signals.dart';
import '../../opportunity/opportunity_theme.dart';
import '../../providers/tongtai_context_provider.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../widgets/tongtai_opportunity_signal_badges.dart';
import 'tongtai_opportunity_detail_screen.dart';
import '../../../../core/l10n/app_strings.dart';

// The type→color helper now lives in opportunity_theme.dart (shared with the
// detail screen); re-exported so existing importers keep resolving it here.
export '../../opportunity/opportunity_theme.dart'
    show tongtaiOpportunityTypeColor;

/// Opportunity Feed screen (WTM-91) — "Opportunity is the central unit".
///
/// A personalized feed of business opportunities: title/description/expected
/// impact per card (AC1), type filter chips (AC2), relevance/recency/ROI
/// sorting (AC3), bookmark + saved view (AC4), and swipe gestures — right =
/// interested, left = dismiss with undo (AC5). Local-first over the
/// in-memory [OpportunityFeedController]. **Real mode (WTM-140):** the feed
/// loads the Rule Engine's generated opportunities (WTM-139) — a brand-new
/// business sees the empty state (User Data First); tests/demo inject a
/// controller.
class TongtaiOpportunityFeedScreen extends ConsumerStatefulWidget {
  const TongtaiOpportunityFeedScreen({super.key, this.controller, this.clock});

  /// Injectable feed. When provided it is *not* disposed here.
  final OpportunityFeedController? controller;

  /// Injectable clock for the rule-based signals (WTM-130); defaults to
  /// [DateTime.now].
  final DateTime Function()? clock;

  @override
  ConsumerState<TongtaiOpportunityFeedScreen> createState() =>
      _TongtaiOpportunityFeedScreenState();
}

class _TongtaiOpportunityFeedScreenState
    extends ConsumerState<TongtaiOpportunityFeedScreen> {
  late OpportunityFeedController _controller;
  late final bool _ownsController;
  late final DateTime Function() _clock;

  OpportunityQuery _query = const OpportunityQuery();

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      // Real mode: start empty, then hydrate with the rule-generated
      // opportunities (WTM-139) — progressive, no blocking spinner.
      _controller = OpportunityFeedController(const []);
      _ownsController = true;
      _loadGenerated();
    }
  }

  Future<void> _loadGenerated() async {
    final List<Opportunity> generated = await ref.read(
      generatedOpportunitiesProvider.future,
    );
    if (!mounted) return;
    setState(() {
      final old = _controller;
      _controller = OpportunityFeedController(generated);
      old.dispose();
    });
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onDismissed(Opportunity opportunity) {
    final l10n = context.l10n;
    _controller.dismiss(opportunity.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.oppDismissedSnack(opportunity.title)),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => _controller.restore(opportunity.id),
          ),
        ),
      );
  }

  void _onInterested(Opportunity opportunity) {
    _controller.markInterested(opportunity.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.oppInterestedSnack(opportunity.title)),
        ),
      );
  }

  /// Opens the detail screen (WTM-92); its reaction buttons write back through
  /// the same controller so the feed stays in sync when it returns.
  void _openDetail(Opportunity opportunity) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiOpportunityDetailScreen(
          opportunity: opportunity,
          onToggleSaved: () => _controller.toggleSaved(opportunity.id),
          onInterested: () => _controller.markInterested(opportunity.id),
          onDismiss: () => _controller.dismiss(opportunity.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final items = _controller.feed(_query);
        return Scaffold(
          backgroundColor: TongtaiDesignTokens.lightBackground,
          appBar: AppBar(
            title: Text(context.l10n.titleOpportunities),
            elevation: 0,
            backgroundColor: TongtaiDesignTokens.lightBackground,
            foregroundColor: TongtaiDesignTokens.lightTextPrimary,
            actions: [
              IconButton(
                key: const Key('opportunity-saved-toggle'),
                tooltip: _query.savedOnly ? 'All opportunities' : 'Saved',
                icon: Icon(
                  _query.savedOnly ? Icons.bookmark : Icons.bookmark_outline,
                  color: _query.savedOnly
                      ? TongtaiDesignTokens.inventoryOrange
                      : null,
                ),
                onPressed: () => setState(
                  () => _query = _query.copyWith(savedOnly: !_query.savedOnly),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChipsRow(
                  label: context.l10n.labelType,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: TongtaiDesignTokens.spacing2,
                      ),
                      child: ChoiceChip(
                        label: Text(context.l10n.filterAll),
                        selected: _query.type == null,
                        onSelected: (_) => setState(
                          () => _query = _query.copyWith(clearType: true),
                        ),
                      ),
                    ),
                    for (final type in _controller.availableTypes)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: TongtaiDesignTokens.spacing2,
                        ),
                        child: ChoiceChip(
                          key: Key('opportunity-type-${type.name}'),
                          label: Text(type.label(context.l10n.languageCode)),
                          selected: _query.type == type,
                          onSelected: (selected) => setState(
                            () => _query = selected
                                ? _query.copyWith(type: type)
                                : _query.copyWith(clearType: true),
                          ),
                        ),
                      ),
                  ],
                ),
                _ChipsRow(
                  label: context.l10n.labelSort,
                  children: [
                    for (final sort in OpportunitySort.values)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: TongtaiDesignTokens.spacing2,
                        ),
                        child: ChoiceChip(
                          key: Key('opportunity-sort-${sort.name}'),
                          label: Text(sort.label(context.l10n.languageCode)),
                          selected: _query.sort == sort,
                          onSelected: (_) => setState(
                            () => _query = _query.copyWith(sort: sort),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TongtaiDesignTokens.spacing4,
                    TongtaiDesignTokens.spacing3,
                    TongtaiDesignTokens.spacing4,
                    TongtaiDesignTokens.spacing2,
                  ),
                  child: Text(
                    items.length == 1
                        ? '1 opportunity'
                        : '${items.length} opportunities',
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? _EmptyState(savedOnly: _query.savedOnly)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            TongtaiDesignTokens.spacing4,
                            0,
                            TongtaiDesignTokens.spacing4,
                            TongtaiDesignTokens.spacing4,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (context, _) => const SizedBox(
                            height: TongtaiDesignTokens.spacing3,
                          ),
                          itemBuilder: (context, index) {
                            final opportunity = items[index];
                            // AC5: swipe right = interested, left = dismiss.
                            // The reaction is part of the key: a swiped-right
                            // card stays in the feed, so its Dismissible must
                            // be recreated fresh (a keyed Dismissible state
                            // stays dismissed forever otherwise).
                            return Dismissible(
                              key: Key(
                                'opportunity-${opportunity.id}-'
                                '${opportunity.reaction.name}',
                              ),
                              background: _SwipeHint(
                                alignment: Alignment.centerLeft,
                                color: TongtaiDesignTokens.success,
                                icon: Icons.thumb_up_alt_outlined,
                                label: context.l10n.oppInterested,
                              ),
                              secondaryBackground: _SwipeHint(
                                alignment: Alignment.centerRight,
                                color: TongtaiDesignTokens.error,
                                icon: Icons.close,
                                label: context.l10n.oppDismiss,
                              ),
                              onDismissed: (direction) =>
                                  direction == DismissDirection.startToEnd
                                  ? _onInterested(opportunity)
                                  : _onDismissed(opportunity),
                              child: _OpportunityCard(
                                opportunity: opportunity,
                                signals: opportunitySignals(
                                  opportunity,
                                  now: _clock(),
                                ),
                                onOpen: () => _openDetail(opportunity),
                                onToggleSaved: () =>
                                    _controller.toggleSaved(opportunity.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.signals,
    required this.onToggleSaved,
    required this.onOpen,
  });

  final Opportunity opportunity;

  /// Rule-based signals (WTM-130) shown as badges under the title.
  final Set<OpportunitySignal> signals;

  final VoidCallback onToggleSaved;

  /// Tapping the card body opens the detail screen (WTM-92).
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiOpportunityTypeColor(opportunity.type);
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: Key('opportunity-card-${opportunity.id}'),
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
                    opportunity.type.label(context.l10n.languageCode),
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (opportunity.reaction != OpportunityReaction.none) ...[
                  const SizedBox(width: TongtaiDesignTokens.spacing2),
                  Text(
                    opportunity.reaction.label(context.l10n.languageCode),
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  key: Key('opportunity-save-${opportunity.id}'),
                  tooltip: opportunity.isSaved
                      ? context.l10n.oppUnsaveTooltip
                      : context.l10n.oppSaveTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    opportunity.isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    size: 20,
                    color: opportunity.isSaved
                        ? TongtaiDesignTokens.inventoryOrange
                        : TongtaiDesignTokens.lightTextSecondary,
                  ),
                  onPressed: onToggleSaved,
                ),
              ],
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              opportunity.title,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            if (signals.isNotEmpty) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing2),
              TongtaiOpportunitySignalBadges(signals: signals),
            ],
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              opportunity.description,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              '${context.l10n.oppEstimatePrefix} '
              '+${TongtaiFormatters.vnd(opportunity.expectedImpact)}'
              ' • ROI ${(opportunity.estimatedRoi * 100).round()}%'
              ' • ${context.l10n.oppScoreLabel} ${opportunity.aiScore.round()}',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored swipe-action backdrop shown under a card mid-swipe (AC5).
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: TongtaiDesignTokens.spacing1),
          Text(
            label,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.savedOnly});

  final bool savedOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Saved-only keeps the bookmark cue; the main feed empty is branded
            // with the Origami fox (WTM-111).
            if (savedOnly)
              const Icon(
                Icons.bookmark_outline,
                size: 48,
                color: TongtaiDesignTokens.lightTextSecondary,
              )
            else
              const TongtaiFoxMascot.face(size: 64),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              savedOnly ? context.l10n.oppEmptySaved : context.l10n.oppEmptyTab,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              savedOnly ? 'Nothing saved yet.' : 'No opportunities here yet.',
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

/// Labelled, horizontally-scrolling chips row (shared chrome).
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: children),
            ),
          ),
        ],
      ),
    );
  }
}
