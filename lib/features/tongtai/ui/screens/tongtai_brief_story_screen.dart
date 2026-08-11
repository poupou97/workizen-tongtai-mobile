import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../action/business_action.dart';
import '../../action/business_action_executor.dart';
import '../../agent/brief_inbox.dart';
import '../../agent/business_brief.dart';
import '../../core/screen_data_controller.dart';
import '../../providers/tongtai_agentic_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../agent/automation_card.dart';
import '../widgets/tongtai_automation_card.dart';
import '../widgets/tongtai_brief_widgets.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Trải nghiệm #2 · Business Story** — WTM-305 (Epic WTM-302).
///
/// Chuỗi Founder yêu cầu người bán phải NHÌN THẤY, trên một màn:
///
/// ```
/// WHAT HAPPENED → WHY → WHAT AI SUGGESTS → WHAT I DECIDED → WHAT HAPPENED NEXT
/// ```
///
/// ## Ba nút, và vì sao là ba
///
/// *Làm ngay* · *Bỏ qua* · *Để sau*. Hai nút (đồng ý / từ chối) ép người bán
/// **quyết dứt** một việc họ chưa nghĩ xong — và ép sai thì họ sẽ bấm "bỏ qua"
/// cho xong, rồi luật xét lại theo miền sẽ giữ im lặng đúng thứ họ cần nghe.
///
/// *Để sau* là nút biến một cái chuông báo thành một trợ lý: nó tạo `AgentTask`
/// thật, và việc tự nổi lên lại đúng ngày mà người bán không phải nhớ.
///
/// ## Trung thực về chỗ chưa thật (Task Order §7)
///
/// Việc chạy qua `ActionVendor.demo` hiện **nhãn diễn tập ngay trên màn**, và
/// nhãn đó nói cả câu: đã ghi đủ trên máy, chưa kênh nào nhận. Không giả rằng
/// Telegram/Shopee thật đã chạy.
class TongtaiBriefStoryScreen extends ConsumerStatefulWidget {
  const TongtaiBriefStoryScreen({super.key, required this.item, this.decision});

  final BriefItem item;
  final BriefDecision? decision;

  @override
  ConsumerState<TongtaiBriefStoryScreen> createState() =>
      _TongtaiBriefStoryScreenState();
}

class _TongtaiBriefStoryScreenState
    extends ConsumerState<TongtaiBriefStoryScreen> {
  late BriefDecision? _decision = widget.decision;
  bool _busy = false;

  /// Kết quả lần chạy vừa rồi — `null` khi chưa bấm gì lượt này.
  ActionRunResult? _result;

  BriefItem get _item => widget.item;

  /// Mọi lần ghi đi qua `runTongtaiAction` (ADR-TON-017).
  ///
  /// Ba nút này **thay đổi dữ liệu nghiệp vụ**. Một lần ghi hỏng mà màn hình
  /// im lặng sẽ để người bán tin rằng họ đã duyệt xong — và họ sẽ không duyệt
  /// lại, vì trong đầu họ việc đó đã làm rồi.
  Future<void> _decide(
    Future<void> Function() write, {
    required String Function(AppStrings l10n) message,
    required BriefDecision becomes,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    final failure = await runTongtaiAction(
      write,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'story',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }

    setState(() => _decision = becomes);
    // Quyết định vừa đổi dữ liệu nghiệp vụ — mọi màn đang mở phải đọc lại,
    // nếu không Home vẫn nói "3 việc" trong khi hộp việc còn 2 (WTM-149).
    invalidateBusinessDataProviders(ref);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message(context.l10n))));
  }

  Future<void> _accept() => _decide(
    () async => _result = await ref.read(briefInboxProvider).accept(_item),
    message: (l10n) => l10n.briefAcceptedSnack,
    becomes: BriefDecision.accepted,
  );

  Future<void> _dismiss() => _decide(
    () => ref.read(briefInboxProvider).dismiss(_item),
    message: (l10n) => l10n.briefDismissedSnack,
    becomes: BriefDecision.dismissed,
  );

  Future<void> _later() => _decide(
    () async => ref.read(briefInboxProvider).postpone(_item),
    message: (l10n) => l10n.briefLaterSnack(BriefInbox.kPostponeDays),
    becomes: BriefDecision.postponed,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = tongtaiBriefColor(_item.severity);
    final open = _decision == null || _decision == BriefDecision.pending;

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.briefStoryTitle),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('story-body'),
          padding: const EdgeInsets.all(TtSpace.x4),
          children: [
            // ── WHAT HAPPENED ────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TongtaiFoxMascot.avatar(size: 40),
                const SizedBox(width: TtSpace.x3),
                Expanded(
                  child: Text(
                    _item.headline,
                    key: const Key('story-headline'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: TtColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            // ── WHY ──────────────────────────────────────────────────────
            const SizedBox(height: TtSpace.x5),
            _Label(text: l10n.briefWhyTitle, key: const Key('story-why')),
            const SizedBox(height: TtSpace.x2),
            for (final e in _item.evidence)
              if (e.detail != null) TongtaiBriefReason(text: e.detail!),

            // ── WHAT AI SUGGESTS ─────────────────────────────────────────
            if (_item.isActionable) ...[
              const SizedBox(height: TtSpace.x4),
              _Label(
                text: l10n.briefSuggestTitle,
                key: const Key('story-suggest'),
              ),
              const SizedBox(height: TtSpace.x2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TtSpace.x3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(TtRadius.md),
                ),
                child: Text(
                  _item.suggestion,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: TtColors.readableOn(color),
                  ),
                ),
              ),
            ],

            // ── WHAT I DECIDED ───────────────────────────────────────────
            if (open && _item.isActionable) ...[
              const SizedBox(height: TtSpace.x5),
              _Decisions(
                busy: _busy,
                onAccept: _accept,
                onDismiss: _dismiss,
                onLater: _later,
              ),
            ] else if (_decision != null) ...[
              const SizedBox(height: TtSpace.x5),
              _Label(
                text: l10n.briefStoryHappened,
                key: const Key('story-decided'),
              ),
              const SizedBox(height: TtSpace.x2),
              Text(
                tongtaiBriefStatusLabel(l10n, _decision!),
                key: Key('story-decision-${tongtaiBriefStatusKey(_decision!)}'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TtColors.textPrimary,
                ),
              ),
            ],

            // ── WHAT HAPPENED NEXT ───────────────────────────────────────
            if (_isDemoRun) ...[
              const SizedBox(height: TtSpace.x4),
              const _DemoExecutionNotice(),
            ],
            if (_decision == BriefDecision.accepted ||
                _decision == BriefDecision.postponed) ...[
              const SizedBox(height: TtSpace.x4),
              _Label(text: l10n.briefStoryNext, key: const Key('story-next')),
              const SizedBox(height: TtSpace.x2),
              TongtaiBriefReason(
                text: _decision == BriefDecision.postponed
                    ? l10n.briefLaterSnack(BriefInbox.kPostponeDays)
                    : l10n.briefAcceptedSnack,
              ),
            ],
            // ── Tôi làm việc này thế nào (trải nghiệm #3) ─────────────────
            //
            // Dưới cùng, không phải trên đầu: người bán tới đây để QUYẾT một
            // việc cụ thể. Hình dạng của luật là câu hỏi thứ hai, và chỉ một
            // số người hỏi.
            const SizedBox(height: TtSpace.x5),
            TongtaiAutomationCard(
              keyPrefix: 'story-automation',
              card: AutomationCard.forKind(
                _item.kind,
                settings: ref.watch(autonomySettingsProvider),
              ),
            ),
            const SizedBox(height: TtSpace.x5),
          ],
        ),
      ),
    );
  }

  /// Việc vừa chạy có thật sự ra khỏi máy này không.
  ///
  /// Đọc từ **chính kết quả** (`vendor` + `externalId`), không từ một cờ riêng
  /// của màn hình: một cờ riêng thì có đường quên bật.
  bool get _isDemoRun {
    final result = _result;
    if (result is! ActionSucceeded) return false;
    final move = _item.move;
    return move is DoSomething && move.vendor == ActionVendor.demo;
  }
}

/// Ba nút. **Động từ**, không phải "OK / Cancel".
class _Decisions extends StatelessWidget {
  const _Decisions({
    required this.busy,
    required this.onAccept,
    required this.onDismiss,
    required this.onLater,
  });

  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TtPrimaryButton(
          key: const Key('story-accept'),
          label: l10n.briefActionAccept,
          onPressed: busy ? null : onAccept,
        ),
        const SizedBox(height: TtSpace.x2),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('story-later'),
                onPressed: busy ? null : onLater,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l10n.briefActionLater),
              ),
            ),
            const SizedBox(width: TtSpace.x2),
            Expanded(
              child: TextButton(
                key: const Key('story-dismiss'),
                onPressed: busy ? null : onDismiss,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: TtColors.textSecondary,
                ),
                child: Text(l10n.briefActionDismiss),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ⚠️ **Chưa gửi đi đâu** — và nói cả câu vì sao điều đó vẫn có ích.
class _DemoExecutionNotice extends StatelessWidget {
  const _DemoExecutionNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('story-demo-execution'),
      width: double.infinity,
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: TtColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 18,
                color: TtColors.warningOnDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.briefDemoExecution,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TtColors.warningOnDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.briefDemoExecutionBody,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: TtColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: TtColors.textSecondary,
    ),
  );
}
