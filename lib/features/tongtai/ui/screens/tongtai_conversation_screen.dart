import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../action/business_action_executor.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../providers/tongtai_simulation_provider.dart';
import '../../simulation/customer_conversation.dart';
import '../../simulation/demo_event.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Một hội thoại** — WTM-339 (E3 · Epic WTM-336).
/// `IMPLEMENTATION_LEVEL=L3`.
///
/// ## Ba phía, ba chỗ đứng khác nhau trên màn
///
/// Khách bên trái · người bán bên phải · **bản nháp của Tổng Tài nằm giữa,
/// trong một khung riêng có nút Gửi**. Đặt nháp cùng chỗ với tin đã gửi là
/// xoá mất ranh giới quan trọng nhất: máy soạn thì chưa ai nhận được gì.
///
/// ## §40 — bấm Gửi rồi thì nói rõ nó đi tới đâu
///
/// Không có gì rời khỏi máy. Câu xác nhận nói thẳng điều đó, và bản ghi hành
/// động mang `vendor: demo` + `externalId` tiền tố `demo:` — nên chỗ khoe kết
/// quả và chỗ khai nó là mô phỏng là **cùng một trường**.
class TongtaiConversationScreen extends ConsumerStatefulWidget {
  const TongtaiConversationScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<TongtaiConversationScreen> createState() =>
      _TongtaiConversationScreenState();
}

class _TongtaiConversationScreenState
    extends ConsumerState<TongtaiConversationScreen> {
  bool _busy = false;
  String? _edited;

  Future<void> _send(
    CustomerConversation conversation,
    ConversationMessage draft,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);

    ActionRunResult? result;
    final failure = await runTongtaiAction(
      () async => result = await ref
          .read(conversationReplyServiceProvider)
          .send(
            conversation: conversation,
            draft: draft,
            text: _edited ?? draft.text,
          ),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'conversation',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _edited = null;
    });

    // Một câu trả lời đã gửi đổi hộp thư, dòng thời gian và cả Khách hàng 360.
    invalidateBusinessDataProviders(ref);

    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }

    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result is ActionSucceeded
                ? l10n.conversationSent
                : l10n.conversationSendFailed,
          ),
        ),
      );
  }

  Future<void> _edit(ConversationMessage draft) async {
    final controller = TextEditingController(text: _edited ?? draft.text);
    final l10n = context.l10n;
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.conversationEdit),
        content: TextField(
          key: const Key('conversation-edit-field'),
          controller: controller,
          maxLines: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            key: const Key('conversation-edit-save'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (next != null && next.trim().isNotEmpty) {
      setState(() => _edited = next.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(customerConversationProvider(widget.customerId));

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(async.asData?.value?.customerName ?? ''),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: TongtaiAsyncScreenData<CustomerConversation?>(
          prefix: 'conversation',
          async: async,
          onRetry: () async =>
              ref.invalidate(customerConversationProvider(widget.customerId)),
          isEmpty: (c) => c == null || c.messages.isEmpty,
          builder: (context, value) {
            final conversation = value!;
            final draft = conversation.pendingDraft;
            final sent = [
              for (final m in conversation.messages)
                if (m != draft) m,
            ];

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    key: const Key('conversation-thread'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: sent.length,
                    itemBuilder: (context, i) => _Bubble(sent[i]),
                  ),
                ),
                if (draft != null)
                  _DraftCard(
                    text: _edited ?? draft.text,
                    needsApproval: draft.needsApproval,
                    busy: _busy,
                    onSend: () => _send(conversation, draft),
                    onEdit: () => _edit(draft),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.message);

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mine = message.side == ConversationSide.seller;
    final label = switch (message.side) {
      ConversationSide.customer => DemoVendor.displayName(message.vendor),
      ConversationSide.agent => l10n.actorAgent,
      ConversationSide.seller => l10n.conversationYouSent,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            '$label · ${_hhmm(message.at)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: mine ? const Color(0xFFDDEFE3) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.text,
    required this.needsApproval,
    required this.busy,
    required this.onSend,
    required this.onEdit,
  });

  final String text;
  final bool needsApproval;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      key: const Key('conversation-draft'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF3EEFB),
        border: Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.conversationDraftLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7A4FCF),
                ),
              ),
              const Spacer(),
              if (needsApproval)
                Text(
                  l10n.conversationNeedsApproval,
                  key: const Key('conversation-needs-approval'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB3261E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            key: const Key('conversation-draft-text'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    key: const Key('conversation-edit'),
                    onPressed: busy ? null : onEdit,
                    child: Text(l10n.conversationEdit),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    key: const Key('conversation-send'),
                    onPressed: busy ? null : onSend,
                    child: Text(l10n.conversationSend),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _hhmm(DateTime at) =>
    '${at.day}/${at.month} '
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';
