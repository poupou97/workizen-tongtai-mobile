import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../agent/brief_inbox.dart';
import '../../agent/business_brief.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_agentic_provider.dart';
import '../widgets/tongtai_brief_widgets.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../widgets/tongtai_more_action.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_activity_screen.dart';
import 'tongtai_brief_story_screen.dart';

/// **Màn Tổng Tài** — nơi ở của agent (WTM-304 · Epic WTM-302).
///
/// ## Vì sao là một màn riêng, không phải một tab nữa của Home
///
/// Home trả lời *"doanh nghiệp tôi đang thế nào"* — số liệu, mô-đun, lối đi.
/// Màn này trả lời một câu khác hẳn: *"Tổng Tài nghĩ gì, và tôi cần quyết gì"*.
///
/// Trộn hai câu đó vào một màn là cách chắc chắn nhất để cả hai đọc như một
/// dashboard. Founder Task Order §2 nói rõ điều phải đạt: *"toàn bộ flow trông
/// giống một Business Conversation, không giống một collection của CRUD
/// screens."*
///
/// ## Trật tự trên màn là trật tự của việc, không phải của dữ liệu
///
/// **Đang chờ bạn quyết** lên trước — đó là thứ duy nhất cần người. **Chỉ để
/// bạn biết** xuống dưới. Một danh sách trộn hai loại sẽ bắt người bán tự phân
/// loại, và đó đúng là việc trợ lý phải làm hộ.
class TongtaiAgentScreen extends ConsumerWidget {
  const TongtaiAgentScreen({super.key, this.clock});

  /// Đồng hồ tiêm được — lời chào theo buổi phải test được lúc 3 giờ sáng.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brief = ref.watch(businessBriefProvider);
    final decisionsAsync = ref.watch(briefDecisionsProvider);
    final decisions = decisionsAsync.hasValue
        ? decisionsAsync.value ?? const <String, BriefDecision>{}
        : const <String, BriefDecision>{};

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleAgent),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        actions: [
          IconButton(
            key: const Key('agent-open-activity'),
            tooltip: l10n.titleActivity,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const TongtaiActivityScreen()),
            ),
          ),
          const TongtaiMoreAction(),
        ],
      ),
      body: SafeArea(
        // Qua seam chung (ADR-TON-017). Một lần đọc hỏng KHÔNG phải "không có
        // việc nào" — nó là "chưa tính được", và hai câu đó dẫn tới hai hành
        // vi khác nhau của người bán.
        child: TongtaiAsyncScreenData<List<BriefItem>>(
          prefix: 'agent',
          async: brief,
          onRetry: () async => ref.invalidate(businessBriefProvider),
          isEmpty: (items) => items.isEmpty,
          emptyBuilder: (context) => _AgentEmpty(clock: clock),
          builder: (context, items) => _AgentBody(
            items: items,
            decisions: decisions,
            clock: clock,
            onRefresh: () async {
              ref.invalidate(businessBriefProvider);
              await ref.read(businessBriefProvider.future);
            },
          ),
        ),
      ),
    );
  }
}

class _AgentBody extends StatelessWidget {
  const _AgentBody({
    required this.items,
    required this.decisions,
    required this.onRefresh,
    this.clock,
  });

  final List<BriefItem> items;
  final Map<String, BriefDecision> decisions;
  final Future<void> Function() onRefresh;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final decide = [
      for (final i in items)
        if (i.isActionable) i,
    ];
    final know = [
      for (final i in items)
        if (!i.isActionable) i,
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('agent-list'),
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        children: [
          _AgentGreeting(count: items.length, clock: clock),
          if (decide.isNotEmpty) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing5),
            _SectionLabel(
              key: const Key('agent-section-decide'),
              text: l10n.briefSectionDecide,
            ),
            for (final item in decide) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing3),
              TongtaiBriefTile(
                item: item,
                keyPrefix: 'agent',
                decision: decisions[item.id],
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => TongtaiBriefStoryScreen(
                      item: item,
                      decision: decisions[item.id],
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (know.isNotEmpty) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing5),
            _SectionLabel(
              key: const Key('agent-section-know'),
              text: l10n.briefSectionKnow,
            ),
            for (final item in know) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing3),
              TongtaiBriefTile(item: item, keyPrefix: 'agent'),
            ],
          ],
          const SizedBox(height: TongtaiDesignTokens.spacing5),
        ],
      ),
    );
  }
}

/// Lời chào + một câu tổng kết. **Sự hiện diện của AI**, không phải một tiêu đề.
class _AgentGreeting extends StatelessWidget {
  const _AgentGreeting({required this.count, this.clock});

  final int count;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = (clock ?? DateTime.now)();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TongtaiFoxMascot.avatar(size: 44),
        const SizedBox(width: TongtaiDesignTokens.spacing3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tongtaiBriefGreeting(l10n, now),
                key: const Key('agent-greeting'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TongtaiDesignTokens.neutralText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.briefHeadline(count),
                key: const Key('agent-headline'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.agentSubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Không có việc nào là **một tin tốt**, và màn hình phải nói ra như vậy.
///
/// Một trạng thái rỗng lạnh lùng ("Không có dữ liệu") ở đây sẽ đọc như app
/// hỏng. Người bán cần biết agent vẫn đang trông.
class _AgentEmpty extends StatelessWidget {
  const _AgentEmpty({this.clock});

  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 88),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            Text(
              l10n.briefNothingTitle,
              key: const Key('agent-empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              l10n.briefNothingBody,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({super.key, required this.text});

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
