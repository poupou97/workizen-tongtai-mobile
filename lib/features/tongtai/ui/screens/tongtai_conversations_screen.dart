import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
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
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleConversations),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: TongtaiAsyncScreenData<List<CustomerConversation>>(
          prefix: 'conversations',
          async: async,
          onRetry: () async => ref.invalidate(customerConversationsProvider),
          isEmpty: (list) => conversationsForInbox(list).isEmpty,
          emptyMessage: l10n.conversationsEmpty,
          builder: (context, all) {
            final sorted = conversationsForInbox(all);
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

/// Hội thoại cho hộp thư: **việc đang chờ trước**, rồi mới tới mới nhất.
///
/// Lọc bỏ khách chưa hề nhắn gì. Chiếu gom mọi việc chạm tới khách — kể cả
/// đơn hàng — vì Khách hàng 360 cần thế; nhưng một hộp thư liệt kê cả người
/// chưa từng nói câu nào thì mọi khách có đơn đều thành một dòng trống, và
/// đúng ba hội thoại thật bị chôn giữa bốn mươi dòng như vậy.
///
/// Hàm thuần, tách khỏi widget để kiểm được thứ tự mà không phải dựng màn.
List<CustomerConversation> conversationsForInbox(
  List<CustomerConversation> all,
) {
  int weight(CustomerConversation c) {
    if (c.pendingDraft?.needsApproval == true) return 0;
    if (c.pendingDraft != null) return 1;
    if (c.awaitingReply) return 2;
    return 3;
  }

  return [
    for (final c in all)
      if (c.messages.isNotEmpty) c,
  ]..sort((a, b) {
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
                color: TtColors.textPrimary,
              ),
            ),
          ),
          for (final channel in conversation.channels.take(2))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              // Kênh bán là **thông tin**, không phải phán quyết ⇒ `info`.
              child: TtStatusBadge(
                status: TtStatus.info,
                label: DemoVendor.displayName(channel),
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
                color: TtColors.textSecondary,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              // ⛔ WTM-414 (DS-2) — ba mã hex tự chọn đã bị thay bằng sắc thái.
              //
              // Bản cũ truyền `0xFFB3261E` / `0xFF7A4FCF` / `0xFF8A6100` — màn
              // **tự dựng một bảng màu riêng** cho một vai **trạng thái**, bỏ
              // qua cả tầng token lẫn tầng semantic. Ba mã ấy không có trong
              // `TtColors`, nên không ai đổi được chúng từ một chỗ.
              //
              // Nghĩa giữ nguyên: cần duyệt = việc chặn (`danger`) · bản nháp
              // do AI soạn (`ai`) · đang chờ khách trả lời (`warning`).
              if (draft != null && draft.needsApproval)
                TtStatusBadge(
                  status: TtStatus.danger,
                  label: l10n.conversationNeedsApproval,
                )
              else if (draft != null)
                TtStatusBadge(
                  status: TtStatus.ai,
                  label: l10n.conversationDraftReady,
                )
              else if (conversation.awaitingReply)
                TtStatusBadge(
                  status: TtStatus.warning,
                  label: l10n.conversationAwaiting,
                ),
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
