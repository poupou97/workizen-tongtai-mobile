import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../providers/tongtai_finance_provider.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../../providers/tongtai_simulation_provider.dart';
import '../../simulation/demo_event.dart';
import '../../simulation/simulation_engine.dart';
import '../../timeline/business_event.dart';
import '../../timeline/business_event_sources.dart';
import '../../timeline/demo_event_source.dart';
import '../../timeline/timeline_service.dart';
import '../../timeline/timeline_theme.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Doanh nghiệp của bạn** — dòng thời gian DUY NHẤT của app.
/// WTM-346 (gộp WTM-114 + WTM-338). `IMPLEMENTATION_LEVEL=L3`.
///
/// ## Vì sao chỉ còn một màn
///
/// App từng có **hai** dòng thời gian: một dựng từ đơn/thu chi/cơ hội/mục tiêu
/// thật, một dựng từ sổ sự kiện mô phỏng. Người bán không có hai khái niệm đó
/// trong đầu — và tệ hơn, **không màn nào kể được trọn một ngày kinh doanh**:
/// màn demo không thấy đơn thật, màn thật không thấy chuyện demo.
///
/// Nay sổ sự kiện là **một nguồn nữa** (`DemoBusinessEventSource`), không phải
/// một màn nữa. Ngày connector thật thay chỗ mô phỏng, thứ phải đổi là một
/// nguồn.
///
/// ## §37 — ba chủ thể là NỘI DUNG
///
/// ```
/// 08:12  Shopee     · 3 đơn về
/// 09:05  Tổng Tài   · phát hiện sắp hết hàng
/// 11:05  Bạn        · đã gửi câu trả lời
/// ```
///
/// Gộp cả ba thành "hệ thống" là xoá mất đúng thông tin khiến dòng thời gian
/// đáng đọc. Bản ghi nghiệp vụ thuần (một dòng thu chi) **không** có chủ thể —
/// và để trống là câu trả lời đúng, không phải thiếu sót.
///
/// ## §33 · §40
///
/// Ba nút đẩy đồng hồ đổi **miền thật**. Đồng hồ mô phỏng ("Ngày 16 / 30")
/// nằm ở AppBar — §40 cấm giấu **trạng thái kỹ thuật**, còn nhãn *"dữ liệu này
/// là mẫu"* thì Founder cấm hiện (WTM-430).
class TongtaiBusinessLifeScreen extends ConsumerStatefulWidget {
  const TongtaiBusinessLifeScreen({super.key, this.clock});

  /// Đồng hồ tiêm vào để nhãn "Hôm nay/Hôm qua" kiểm được.
  final DateTime Function()? clock;

  @override
  ConsumerState<TongtaiBusinessLifeScreen> createState() =>
      _TongtaiBusinessLifeScreenState();
}

class _TongtaiBusinessLifeScreenState
    extends ConsumerState<TongtaiBusinessLifeScreen> {
  late final ScreenDataController<TimelineService> _data;
  BusinessEventType? _filter;
  bool _busy = false;

  DateTime Function() get _clock => widget.clock ?? DateTime.now;

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<TimelineService>(
      _read,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'business_life',
    )..load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  /// Một dòng thời gian, nhiều nguồn — bản ghi thật **và** chuyện mô phỏng.
  Future<TimelineService> _read() async {
    final l10n = context.l10n;
    final finance = await ref.read(financeRepositoryProvider).loadAll();
    final orders = await ref.read(orderRepositoryProvider).loadAll();
    final goals = await ref.read(businessGoalRepositoryProvider).loadAll();
    final demo = await ref
        .read(demoEventRepositoryProvider)
        .loadTimeline(limit: 500);

    // ⛔ **Cơ hội KHÔNG lên dòng thời gian** (WTM-346).
    //
    // Chúng là *việc nên làm*, không phải *việc đã xảy ra* — và điều đó lộ ra
    // ở chính dữ liệu: mọi cơ hội đều mang mốc `now`, vì nó được suy ra lúc
    // đọc chứ không xảy ra lúc nào cả. Gộp vào đây thì bốn mươi dòng "just
    // now" dìm mất cả ngày kinh doanh thật, và người bán mở ra chỉ thấy máy
    // nói về chính nó.
    //
    // Cơ hội đã có nhà riêng: màn Cơ hội và brief "Việc hôm nay" trên Trang
    // chủ. Đây là dòng thời gian của **doanh nghiệp**, không phải nhật ký của
    // bộ luật.
    return TimelineService([
      FinanceEventSource(finance, l10n: l10n),
      OrderEventSource(orders),
      JourneyEventSource(goals),
      DemoBusinessEventSource(demo),
    ]);
  }

  Future<void> _run(Future<SimulationTick> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);

    SimulationTick? tick;
    final failure = await runTongtaiAction(
      () async => tick = await action(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'business_life',
    );

    if (!mounted) return;
    setState(() => _busy = false);

    // Đẩy đồng hồ là đổi cả doanh nghiệp: đơn, tồn kho, phí, cơ hội, brief.
    // Chỉ làm mới màn này thì Founder bấm "Ngày tiếp" mà Home đứng im — và đó
    // đúng là thứ phá cảm giác "doanh nghiệp đang sống".
    invalidateBusinessDataProviders(ref);
    await _data.load();

    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }

    final l10n = context.l10n;
    _say(switch (tick?.reason) {
      SimulationBlocked.needsCatalogue => l10n.demoNeedsCatalogue,
      SimulationBlocked.notStarted => l10n.demoNotStarted,
      SimulationBlocked.finished => l10n.demoFinished,
      null => l10n.demoAdvanced(tick?.applied.length ?? 0),
    });
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final day = ref.watch(simulationDayProvider).asData?.value;

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleBusinessLife),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
        // ⭐ Đồng hồ của trình mô phỏng — thứ DUY NHẤT còn lại từ băng-rôn cũ.
        //
        // Nó KHÔNG nói *"dữ liệu của bạn là giả"* (thứ Founder cấm ở WTM-430);
        // nó nói *"bạn đang ở ngày mấy của 30 ngày mô phỏng"* — tức **trạng
        // thái kỹ thuật**, đúng thứ §40 bắt buộc không được giấu. Người bán
        // đang tự bấm "Ngày tiếp" mà không biết mình ở ngày mấy thì màn này
        // mất nghĩa.
        actions: [
          if (day != null)
            Padding(
              padding: const EdgeInsets.only(right: TtSpace.x4),
              child: Center(
                child: Text(
                  l10n.demoDayOf(day + 1, 30),
                  key: const Key('business-life-day'),
                  style: TtType.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TtColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Controls(
              busy: _busy,
              started: day != null,
              onStart: () => _run(
                () => ref
                    .read(simulationEngineProvider)
                    .start(anchor: DateTime.now()),
              ),
              onNextEvent: () => _run(
                () => ref.read(simulationEngineProvider).advanceOneEvent(),
              ),
              onNextDay: () =>
                  _run(() => ref.read(simulationEngineProvider).advanceDay()),
              onNextWeek: () => _run(
                () => ref.read(simulationEngineProvider).advanceDay(days: 7),
              ),
              onReset: () => _run(() async {
                await ref.read(simulationEngineProvider).reset();
                return const SimulationTick.notStarted();
              }),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _data,
                builder: (context, _) => TongtaiScreenData<TimelineService>(
                  prefix: 'business-life',
                  state: _data.state,
                  onRetry: _data.retry,
                  isEmpty: (service) => service.timeline().isEmpty,
                  builder: _body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TimelineService service) {
    final now = _clock();
    final all = service.timeline();
    // Chỉ hiện bộ lọc cho loại **thật sự có** — một chip rỗng là một lời hứa
    // suông.
    final availableTypes = <BusinessEventType>[
      for (final t in BusinessEventType.values)
        if (all.any((e) => e.type == t)) t,
    ];
    final filtered = _filter == null
        ? all
        : [
            for (final e in all)
              if (e.type == _filter) e,
          ];
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
            key: const Key('business-life-timeline'),
            padding: const EdgeInsets.only(bottom: TtSpace.x6),
            children: [for (final d in days) _DaySection(day: d, now: now)],
          ),
        ),
      ],
    );
  }
}

// ⛔ WTM-430 — KHÔNG còn băng-rôn `DEMO` ở đây.
//
// Founder chốt luật này **ba lần**: WTM-343 (gỡ băng-rôn Trang chủ) · WTM-348
// (gỡ nhãn trên từng thẻ brief, sót ngay hôm gỡ băng-rôn kia) · và 2026-08-15
// khi băng-rôn này vẫn còn. *"Bản demo phải trông như thật"* — nó là thứ mang
// đi cho đối tác xem.
//
// Nhãn nói về **dữ liệu**, không nói về **trạng thái kỹ thuật**, nên gỡ nó
// không phạm §40. Ba thứ giữ nguyên để rủi ro "nhầm mẫu là số của mình" không
// thành mất mát:
//   * mỗi bản ghi vẫn mang tiền tố `sample-` / `importJobId`;
//   * "Xoá dữ liệu mẫu" vẫn xoá đúng chúng, không đụng dữ liệu thật;
//   * **đồng hồ mô phỏng** ("Ngày 16 / 30") chuyển lên AppBar — đó là trạng
//     thái kỹ thuật, §40 cấm giấu.
//
// ⚠️ Rò ba lần vì luật chỉ nằm trong chú thích. Nay có cổng:
// `test/features/tongtai/p0/no_demo_label_gate_test.dart`.

class _Controls extends StatelessWidget {
  const _Controls({
    required this.busy,
    required this.started,
    required this.onStart,
    required this.onNextEvent,
    required this.onNextDay,
    required this.onNextWeek,
    required this.onReset,
  });

  final bool busy;
  final bool started;
  final VoidCallback onStart;
  final VoidCallback onNextEvent;
  final VoidCallback onNextDay;
  final VoidCallback onNextWeek;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: started
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('business-life-next-event'),
                      onPressed: busy ? null : onNextEvent,
                      child: Text(l10n.demoNextEvent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const Key('business-life-next-day'),
                      onPressed: busy ? null : onNextDay,
                      child: Text(l10n.demoNextDay),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    key: const Key('business-life-next-week'),
                    onPressed: busy ? null : onNextWeek,
                    child: Text(l10n.demoNextWeek),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: IconButton(
                    key: const Key('business-life-reset'),
                    tooltip: l10n.demoReset,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: busy ? null : onReset,
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('business-life-start'),
                onPressed: busy ? null : onStart,
                child: Text(l10n.demoStart),
              ),
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
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x4),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: TtSpace.x2),
          child: ChoiceChip(
            key: const Key('business-life-filter-all'),
            label: Text(context.l10n.filterAll),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final t in types)
          Padding(
            padding: const EdgeInsets.only(right: TtSpace.x2),
            child: ChoiceChip(
              key: Key('business-life-filter-${t.name}'),
              label: Text(t.label(context.l10n.languageCode)),
              selected: selected == t,
              onSelected: (_) => onSelected(t),
            ),
          ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          TtSpace.x4,
          TtSpace.x4,
          TtSpace.x4,
          TtSpace.x2,
        ),
        child: Text(
          _label(context.l10n),
          style: TtType.body.copyWith(
            color: TtColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      for (var i = 0; i < day.events.length; i++)
        _EventRow(
          event: day.events[i],
          now: now,
          // Gạch nối giữa hai dòng cùng một câu chuyện — mắt bắt được chuỗi sự
          // việc trước khi đọc chữ.
          continuesStory:
              i + 1 < day.events.length &&
              day.events[i].correlationId != null &&
              day.events[i].correlationId == day.events[i + 1].correlationId,
        ),
    ],
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.now,
    this.continuesStory = false,
  });

  final BusinessEvent event;
  final DateTime now;
  final bool continuesStory;

  /// Ai làm việc này. `null` = bản ghi nghiệp vụ thuần, và để trống là câu trả
  /// lời đúng: một dòng thu chi không có "ai" theo nghĩa đó.
  (String, Color)? _actor(AppStrings l10n) => switch (event.actorCode) {
    'platform' => (
      event.vendor == null
          ? l10n.actorPlatform
          : DemoVendor.displayName(event.vendor),
      const Color(0xFF3B6FD4),
    ),
    'agent' => (l10n.actorAgent, const Color(0xFF7A4FCF)),
    'seller' => (l10n.actorSeller, const Color(0xFF2E7D4F)),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = _actor(l10n);
    final color = actor?.$2 ?? businessEventColor(event.type);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TtSpace.x4,
        vertical: TtSpace.x2,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    businessEventIcon(event.type),
                    size: 18,
                    color: color,
                  ),
                ),
                if (continuesStory)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: TtSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actor != null)
                    Text(
                      actor.$1,
                      style: TtType.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: actor.$2,
                      ),
                    ),
                  Text(
                    event.title,
                    style: TtType.body.copyWith(
                      color: TtColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.subtitle.isNotEmpty)
                    Text(
                      event.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: TtSpace.x2),
            Text(
              TongtaiFormatters.relativeDate(event.timestamp, now: now),
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
