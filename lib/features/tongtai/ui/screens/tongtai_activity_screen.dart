import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../agent/agent_activity.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../agent/agent_runner.dart';
import '../../providers/tongtai_agentic_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Trải nghiệm #5 · "Tổng Tài đã làm gì"** — WTM-305 (Epic WTM-302).
///
/// > *"Không phải developer log."* — Founder Task Order §10
///
/// Mỗi dòng là một câu tiếng Việt về nghiệp vụ, và mỗi dòng truy được về một
/// bản ghi thật. Không dòng nào chứa tên bảng, mã lỗi hay id kỹ thuật.
///
/// ## Vì sao gộp theo ngày, không theo loại
///
/// Người bán nhớ theo *"hôm nay tôi đã làm gì"*, không theo *"đề xuất của tôi
/// đang ở trạng thái nào"*. Gộp theo loại sẽ dựng lại đúng cái bảng quản trị
/// mà màn này sinh ra để thay thế.
class TongtaiActivityScreen extends ConsumerStatefulWidget {
  const TongtaiActivityScreen({super.key, this.clock, this.autoRun = true});

  final DateTime Function()? clock;

  /// Chạy một lượt runner ngay khi mở màn. Tắt trong test muốn xem trạng thái
  /// **trước** khi runner đụng vào.
  final bool autoRun;

  @override
  ConsumerState<TongtaiActivityScreen> createState() =>
      _TongtaiActivityScreenState();
}

class _TongtaiActivityScreenState extends ConsumerState<TongtaiActivityScreen> {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    // Runner V1 chạy **khi app đang mở** (Task Order §12). Mở đúng màn kể lại
    // việc agent đã làm là thời điểm tự nhiên nhất: người bán vào đây để xem
    // nó đã làm gì, nên để nó làm nốt phần đến hạn trước khi kể là hợp lý.
    if (widget.autoRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run(silent: true));
    }
  }

  /// Một lượt chạy. [silent] cho lượt tự động — không bắn snack khi không có
  /// gì đến hạn, vì mở màn nào cũng thấy một thông báo là phiền.
  Future<void> _run({bool silent = false}) async {
    if (_running) return;
    setState(() => _running = true);

    AgentRunReport report = AgentRunReport.none;
    final failure = await runTongtaiAction(
      () async => report = await ref.read(agentRunnerProvider).runOnce(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'activity',
    );

    if (!mounted) return;
    setState(() => _running = false);
    if (failure != null) {
      if (!silent) showTongtaiFailure(context, failure);
      return;
    }

    // Một lượt runner ĐÓNG việc — tức là đổi thứ Home, brief và hành trình
    // đang hiện. Chỉ làm mới màn này sẽ để mọi màn khác nói con số cũ
    // (WTM-149 device defect 1).
    if (report.didSomething) invalidateBusinessDataProviders(ref);
    if (silent && !report.didSomething) return;

    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            report.didSomething
                ? l10n.agentRunDone(report.claimed)
                : l10n.agentRunNothing,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activity = ref.watch(agentActivityProvider);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleActivity),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        actions: [
          IconButton(
            key: const Key('activity-run'),
            tooltip: l10n.agentRunNow,
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _running ? null : _run,
          ),
        ],
      ),
      body: SafeArea(
        child: TongtaiAsyncScreenData<List<ActivityEntry>>(
          prefix: 'activity',
          async: activity,
          onRetry: () async => ref.invalidate(agentActivityProvider),
          isEmpty: (entries) => entries.isEmpty,
          emptyBuilder: (context) => const _ActivityEmpty(),
          builder: (context, entries) =>
              _ActivityBody(entries: entries, clock: widget.clock),
        ),
      ),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.entries, this.clock});

  final List<ActivityEntry> entries;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = (clock ?? DateTime.now)();
    final today = <ActivityEntry>[];
    final earlier = <ActivityEntry>[];
    for (final e in entries) {
      (_isSameDay(e.at, now) ? today : earlier).add(e);
    }

    return ListView(
      key: const Key('activity-list'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        Row(
          children: [
            const TongtaiFoxMascot.avatar(size: 40),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: Text(
                l10n.activitySubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
        if (today.isNotEmpty) ...[
          const SizedBox(height: TongtaiDesignTokens.spacing5),
          _DayLabel(
            key: const Key('activity-section-today'),
            text: l10n.activityToday,
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          for (final e in today) _ActivityLine(entry: e),
        ],
        if (earlier.isNotEmpty) ...[
          const SizedBox(height: TongtaiDesignTokens.spacing5),
          _DayLabel(
            key: const Key('activity-section-earlier'),
            text: l10n.activityEarlier,
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          for (final e in earlier) _ActivityLine(entry: e),
        ],
        const SizedBox(height: TongtaiDesignTokens.spacing5),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Một dòng: dấu · câu · (nhãn diễn tập nếu chưa ra khỏi máy).
class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.tone) {
      ActivityTone.done => (Icons.check, TongtaiDesignTokens.producerGreenText),
      ActivityTone.attention => (
        Icons.priority_high,
        TongtaiDesignTokens.inventoryOrangeText,
      ),
      ActivityTone.waiting => (
        Icons.arrow_forward,
        TongtaiDesignTokens.consumerBlueText,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: Icon(icon, size: 17, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
                if (entry.isDemo) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.briefDemoExecution,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: TongtaiDesignTokens.inventoryOrangeText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chưa có gì để kể là **một trạng thái bình thường**, không phải một lỗi.
class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 80),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            Text(
              l10n.activityEmpty,
              key: const Key('activity-empty-title'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              l10n.activityEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: TongtaiDesignTokens.neutralText,
    ),
  );
}
