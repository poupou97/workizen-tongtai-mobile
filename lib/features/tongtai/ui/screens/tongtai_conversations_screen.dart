import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_simulation_provider.dart';
import '../../simulation/customer_conversation.dart';
import '../../simulation/demo_event.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_conversation_screen.dart';

/// **Hội thoại khách hàng** — WTM-339 (E3 · Epic WTM-336).
/// `IMPLEMENTATION_LEVEL=L3`.
///
/// ## §38 — người bán mở app là để biết "ai đang chờ mình"
///
/// Sắp xếp không theo thời gian thuần: **việc đang chờ nổi lên trước**. Một
/// hộp thư sắp theo thời gian thì câu hỏi *"tôi có nợ ai câu trả lời không"*
/// phải tự cuộn tay mà tìm — và đó là câu hỏi duy nhất khiến người ta mở màn
/// này.
class TongtaiConversationsScreen extends ConsumerWidget {
  const TongtaiConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(customerConversationsProvider);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleConversations),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: TongtaiAsyncScreenData<List<CustomerConversation>>(
          prefix: 'conversations',
          async: async,
          onRetry: () async => ref.invalidate(customerConversationsProvider),
          isEmpty: (list) => list.isEmpty,
          emptyMessage: l10n.conversationsEmpty,
          builder: (context, all) {
            final sorted = sortConversationsForInbox(all);
            return ListView.separated(
              key: const Key('conversations-list'),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _ConversationTile(sorted[i]),
            );
          },
        ),
      ),
    );
  }
}

/// Việc đang chờ trước, rồi mới tới mới nhất.
///
/// Hàm thuần, tách khỏi widget để kiểm được thứ tự mà không phải dựng màn.
List<CustomerConversation> sortConversationsForInbox(
  List<CustomerConversation> all,
) {
  int weight(CustomerConversation c) {
    if (c.pendingDraft?.needsApproval == true) return 0;
    if (c.pendingDraft != null) return 1;
    if (c.awaitingReply) return 2;
    return 3;
  }

  return all.toList()..sort((a, b) {
    final byWeight = weight(a).compareTo(weight(b));
    return byWeight != 0 ? byWeight : b.lastAt.compareTo(a.lastAt);
  });
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile(this.conversation);

  final CustomerConversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = conversation.lastMessage;
    final draft = conversation.pendingDraft;

    return ListTile(
      key: Key('conversation-${conversation.customerId}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ),
          for (final channel in conversation.channels.take(2))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _Chip(
                DemoVendor.displayName(channel),
                const Color(0xFF3B6FD4),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (last != null)
            Text(
              last.side == ConversationSide.seller
                  ? '${l10n.conversationYouSent}: ${last.text}'
                  : last.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (draft != null && draft.needsApproval)
                _Chip(l10n.conversationNeedsApproval, const Color(0xFFB3261E))
              else if (draft != null)
                _Chip(l10n.conversationDraftReady, const Color(0xFF7A4FCF))
              else if (conversation.awaitingReply)
                _Chip(l10n.conversationAwaiting, const Color(0xFF8A6100)),
            ],
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              TongtaiConversationScreen(customerId: conversation.customerId),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}
