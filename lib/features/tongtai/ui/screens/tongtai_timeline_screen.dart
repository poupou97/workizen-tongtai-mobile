import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  TimelineService _service = TimelineService(const []);
  late final DateTime Function() _clock;
  BusinessEventType? _filter;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    if (widget.service != null) {
      _service = widget.service!;
    } else {
      _loadReal();
    }
  }

  Future<void> _loadReal() async {
    // One source (WTM-144): finance/orders/goals from the live repositories +
    // the Rule Engine's generated opportunities — mirrors TimelineContext.
    final finance = await ref.read(financeRepositoryProvider).loadAll();
    final orders = await ref.read(orderRepositoryProvider).loadAll();
    final goals = await ref.read(businessGoalRepositoryProvider).loadAll();
    final opportunities = await ref.read(generatedOpportunitiesProvider.future);
    if (!mounted) return;
    setState(() {
      _service = TimelineService([
        FinanceEventSource(finance),
        OrderEventSource(orders),
        JourneyEventSource(goals),
        OpportunityEventSource(opportunities),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = _clock();
    final all = _service.timeline();
    final availableTypes = <BusinessEventType>[
      for (final t in BusinessEventType.values)
        if (all.any((e) => e.type == t)) t,
    ];
    final filtered = _filter == null
        ? all
        : all.where((e) => e.type == _filter).toList();
    final days = groupEventsByDay(filtered);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Dòng thời gian · Timeline'),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
      ),
      body: all.isEmpty
          ? const _TimelineEmptyState()
          : Column(
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
                    children: [
                      for (final day in days) _DaySection(day: day, now: now),
                    ],
                  ),
                ),
              ],
            ),
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
              label: const Text('Tất cả'),
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
                label: Text(t.labelVi),
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

  String get _label {
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day.date).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
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
            _label,
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
              'Chưa có hoạt động nào',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.heading3Style.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              'Đơn hàng, thu chi, cơ hội và mục tiêu sẽ xuất hiện ở đây theo '
              'thời gian.',
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
