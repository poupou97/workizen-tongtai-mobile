import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../timeline/business_event.dart';
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_finance_provider.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../../timeline/business_event_sources.dart';
import '../../timeline/timeline_service.dart';
import '../../timeline/timeline_theme.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../../../core/l10n/app_strings.dart';

/// Business Timeline (WTM-114) — a chronological feed of everything that
/// happened in the business (orders, finance, opportunities, goals…), grouped
/// by day with a type filter.
///
/// Local-first: events come from [TimelineService], which merges per-module
/// sources. **Real mode (WTM-144 P0 §1) builds the service from the PRODUCTION
/// repositories** — the same rows every other screen shows; the old
/// sample-default silently displayed fixture events. `service`/`clock` stay
/// injectable for deterministic tests.
class TongtaiTimelineScreen extends ConsumerStatefulWidget {
  const TongtaiTimelineScreen({super.key, this.service, this.clock});

  final TimelineService? service;
  final DateTime Function()? clock;

  @override
  ConsumerState<TongtaiTimelineScreen> createState() =>
      _TongtaiTimelineScreenState();
}

class _TongtaiTimelineScreenState extends ConsumerState<TongtaiTimelineScreen> {
  late final DateTime Function() _clock;
  BusinessEventType? _filter;

  /// The timeline is a *derived projection* over four repositories (WTM-134),
  /// so it has four ways to fail. Loading them through one controller means a
  /// single failure is reported once, with a retry, instead of the feed simply
  /// looking like a business where nothing ever happened (WTM-148).
  late final ScreenDataController<TimelineService> _data;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    _data = ScreenDataController<TimelineService>(
      _read,
      // An injected service (tests, preview) is already true data: render it
      // on the first frame instead of a loading state that resolves to the
      // same thing one microtask later.
      initialValue: widget.service,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'timeline',
    )..start();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<TimelineService> _read() async {
    // Injected service (tests/preview) short-circuits the repositories.
    final injected = widget.service;
    if (injected != null) return injected;
    // One source (WTM-144): finance/orders/goals from the live repositories +
    // the Rule Engine's generated opportunities — mirrors TimelineContext.
    final finance = await ref.read(financeRepositoryProvider).loadAll();
    final orders = await ref.read(orderRepositoryProvider).loadAll();
    final goals = await ref.read(businessGoalRepositoryProvider).loadAll();
    final opportunities = await ref.read(generatedOpportunitiesProvider.future);
    return TimelineService([
      FinanceEventSource(finance),
      OrderEventSource(orders),
      JourneyEventSource(goals),
      OpportunityEventSource(opportunities),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleTimeline),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<TimelineService>(
          prefix: 'timeline',
          state: _data.state,
          onRetry: _data.retry,
          isEmpty: (service) => service.timeline().isEmpty,
          emptyBuilder: (_) => const _TimelineEmptyState(),
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TimelineService service) {
    final now = _clock();
    final all = service.timeline();
    final availableTypes = <BusinessEventType>[
      for (final t in BusinessEventType.values)
        if (all.any((e) => e.type == t)) t,
    ];
    final filtered = _filter == null
        ? all
        : all.where((e) => e.type == _filter).toList();
    final days = groupEventsByDay(filtered);

    return Column(
      children: [
        _FilterRow(
          types: availableTypes,
          selected: _filter,
          onSelected: (t) => setState(() => _filter = t),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              bottom: TongtaiDesignTokens.spacing6,
            ),
            children: [for (final day in days) _DaySection(day: day, now: now)],
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<BusinessEventType> types;
  final BusinessEventType? selected;
  final ValueChanged<BusinessEventType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: TongtaiDesignTokens.spacing4,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
            child: ChoiceChip(
              label: Text(context.l10n.filterAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final t in types)
            Padding(
              padding: const EdgeInsets.only(
                right: TongtaiDesignTokens.spacing2,
              ),
              child: ChoiceChip(
                key: Key('timeline-filter-${t.name}'),
                label: Text(t.label(context.l10n.languageCode)),
                selected: selected == t,
                onSelected: (_) => onSelected(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.now});

  final TimelineDay day;
  final DateTime now;

  String _label(AppStrings l10n) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day.date).inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    return TongtaiFormatters.isoDate(day.date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TongtaiDesignTokens.spacing4,
            TongtaiDesignTokens.spacing4,
            TongtaiDesignTokens.spacing4,
            TongtaiDesignTokens.spacing2,
          ),
          child: Text(
            _label(context.l10n),
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final event in day.events) _EventRow(event: event, now: now),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.now});

  final BusinessEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final color = businessEventColor(event.type);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(businessEventIcon(event.type), size: 18, color: color),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.subtitle.isNotEmpty)
                  Text(
                    event.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (event.amount != null) _AmountText(amount: event.amount!),
              Text(
                TongtaiFormatters.relativeDate(event.timestamp, now: now),
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final positive = amount >= 0;
    final color = positive
        ? TongtaiDesignTokens.producerGreen
        : TongtaiDesignTokens.error;
    final sign = positive ? '+' : '-';
    return Text(
      '$sign${TongtaiFormatters.vndShort(amount.abs())}',
      style: TongtaiDesignTokens.smallStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('timeline-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 72),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            Text(
              context.l10n.timelineEmptyTitle,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.heading3Style.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              context.l10n.timelineEmptyBody,
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
