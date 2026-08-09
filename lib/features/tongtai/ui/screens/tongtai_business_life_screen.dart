import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../providers/tongtai_simulation_provider.dart';
import '../../simulation/demo_event.dart';
import '../../simulation/simulation_engine.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Doanh nghiệp của bạn** — dòng thời gian + đồng hồ mô phỏng.
/// WTM-338 (E2 · Epic WTM-336). `IMPLEMENTATION_LEVEL=L3`.
///
/// ## §37 — Founder phải NHÌN THẤY doanh nghiệp đang sống
///
/// ```
/// 08:12  Shopee     · 3 đơn về
/// 08:31  Facebook   · khách hỏi về Áo thun cotton
/// 09:05  Tổng Tài   · phát hiện sắp hết hàng
/// 11:05  Bạn        · đã gửi câu trả lời
/// ```
///
/// Ba chủ thể — **sàn · Tổng Tài · bạn** — hiện rõ ai làm gì. Gộp cả ba thành
/// "hệ thống" là xoá mất đúng thông tin khiến dòng thời gian đáng đọc: người
/// bán cần phân biệt việc nào sàn báo về, việc nào máy tự làm, việc nào chính
/// mình đã bấm.
///
/// ## §33 — 30 ngày trong 15 phút
///
/// Ba nút đẩy đồng hồ. Mỗi lần đẩy, **miền thật thay đổi** — đơn vào sổ, tồn
/// giảm, phí sàn về — nên mọi màn khác cũng đổi theo.
///
/// ## §40 — Không giấu chuyện đây là mô phỏng
///
/// Băng-rôn nằm trên cùng, không phải một dòng chữ mờ ở chân màn. Fake dữ liệu
/// được phép; fake **trạng thái kỹ thuật** thì không.
class TongtaiBusinessLifeScreen extends ConsumerStatefulWidget {
  const TongtaiBusinessLifeScreen({super.key});

  @override
  ConsumerState<TongtaiBusinessLifeScreen> createState() =>
      _TongtaiBusinessLifeScreenState();
}

class _TongtaiBusinessLifeScreenState
    extends ConsumerState<TongtaiBusinessLifeScreen> {
  bool _busy = false;

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
    final timeline = ref.watch(businessTimelineProvider);
    final day = ref.watch(simulationDayProvider).asData?.value;

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleBusinessLife),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _DemoBanner(day: day),
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
              child: TongtaiAsyncScreenData<List<DemoEvent>>(
                prefix: 'business-life',
                async: timeline,
                onRetry: () async => ref.invalidate(businessTimelineProvider),
                isEmpty: (events) => events.isEmpty,
                builder: (context, events) => ListView.builder(
                  key: const Key('business-life-timeline'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, i) => _TimelineRow(
                    event: events[i],
                    // Vạch ngày. Cột giờ chỉ có `hh:mm`, nên một tháng dồn
                    // lại đọc ra "10:03 · 08:50 · 13:38" và trông như sắp
                    // xếp hỏng — trong khi thứ tự vẫn đúng, chỉ là đã sang
                    // ngày khác. Thiếu vạch này thì màn hình tự tố cáo mình
                    // một lỗi không có thật.
                    startsDay:
                        i == 0 ||
                        !_sameDay(
                          events[i].occurredAt,
                          events[i - 1].occurredAt,
                        ),
                    // Gạch nối giữa hai dòng cùng một câu chuyện — mắt bắt
                    // được chuỗi sự việc trước khi đọc chữ.
                    continuesStory:
                        i + 1 < events.length &&
                        events[i].correlationId != null &&
                        events[i].correlationId == events[i + 1].correlationId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.day});

  final int? day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      key: const Key('business-life-demo-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.demoTag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF8A6100),
                ),
              ),
              const Spacer(),
              if (day != null)
                Text(
                  l10n.demoDayOf(day! + 1, 30),
                  key: const Key('business-life-day'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A6100),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.demoBanner,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF6B4E00),
            ),
          ),
        ],
      ),
    );
  }
}

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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.continuesStory,
    this.startsDay = false,
  });

  final DemoEvent event;
  final bool continuesStory;

  /// Dòng đầu tiên của một ngày ⇒ có vạch ngày phía trên.
  final bool startsDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (event.actor) {
      // Biết sàn nào thì gọi tên riêng của nó; không biết thì nói "Sàn" —
      // một dòng ghi "Tổng Tài" cho việc do Shopee báo về là nói sai ai làm gì.
      DemoActor.platform => (
        event.vendor == null
            ? l10n.actorPlatform
            : DemoVendor.displayName(event.vendor),
        const Color(0xFF3B6FD4),
      ),
      DemoActor.agent => (l10n.actorAgent, const Color(0xFF7A4FCF)),
      DemoActor.seller => (l10n.actorSeller, const Color(0xFF2E7D4F)),
    };

    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              _hhmm(event.occurredAt),
              style: const TextStyle(
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (continuesStory)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.headline,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: TongtaiDesignTokens.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!startsDay) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${event.occurredAt.day}/${event.occurredAt.month}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ),
        row,
      ],
    );
  }

  static String _hhmm(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';
}
