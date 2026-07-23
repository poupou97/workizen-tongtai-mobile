import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/chat_controller.dart';
import '../../chat/chat_message.dart';
import '../../inventory/product_image_source.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_chat_provider.dart';

/// Chat screen (WTM-80) — the conversation surface for the AI Copilot.
///
/// Covers every acceptance criterion, local-first (no chat backend exists in
/// the MVP):
/// - AC1: seller bubbles right / assistant bubbles left, each with a timestamp,
/// - AC2: text input with the platform keyboard (emoji included) + send,
/// - AC3: per-message delivery states rendered as ticks (✓ / ✓✓ / blue ✓✓),
/// - AC4: attachment picking with an inline preview before and after sending,
/// - AC5: assistant typing indicator + local presence chip in the app bar.
///
/// The reply pipeline is [TongtaiChatController]'s injectable [ChatResponder];
/// WTM-82 swaps in the real AI routing over the BYOK client. Conversation
/// history persists through [tongtaiChatStoreProvider] (WTM-81, local-only
/// per ADR-TON-004) when the screen builds its own controller.
class TongtaiChatScreen extends ConsumerStatefulWidget {
  const TongtaiChatScreen({super.key, this.controller, this.attachmentPicker});

  /// Injectable conversation state; the screen creates (and owns) a default
  /// one over the Riverpod chat store when omitted.
  final TongtaiChatController? controller;

  /// Returns a local file path to attach, or null when cancelled. Defaults to
  /// the gallery picker already used by the product form (WTM-69).
  final Future<String?> Function()? attachmentPicker;

  @override
  ConsumerState<TongtaiChatScreen> createState() => _TongtaiChatScreenState();
}

class _TongtaiChatScreenState extends ConsumerState<TongtaiChatScreen> {
  late final TongtaiChatController _controller;
  late final bool _ownsController;
  late final Future<String?> Function() _pickAttachment;
  final TextEditingController _input = TextEditingController();

  ChatAttachment? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TongtaiChatController(
          store: ref.read(tongtaiChatStoreProvider),
          // Workizen AI Router (WTM-82): classifies the query, injects local
          // business context, picks the best enabled provider, falls back to
          // the rule-based offline reply.
          responder: ref.read(tongtaiChatResponderProvider),
        );
    _ownsController = widget.controller == null;
    _pickAttachment =
        widget.attachmentPicker ??
        () => ImagePickerProductImageSource().pickFromGallery();
    // Restore the persisted conversation (WTM-81); the controller notifies
    // when history lands.
    _controller.hydrate();
  }

  @override
  void dispose() {
    _input.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final path = await _pickAttachment();
    if (!mounted || path == null) return;
    setState(() {
      _pendingAttachment = ChatAttachment(
        path: path,
        name: path.split(Platform.pathSeparator).last.split('/').last,
      );
    });
  }

  void _removePendingAttachment() {
    setState(() => _pendingAttachment = null);
  }

  void _send() {
    final attachment = _pendingAttachment;
    final text = _input.text;
    if (text.trim().isEmpty && attachment == null) return;
    _input.clear();
    setState(() => _pendingAttachment = null);
    // Fire-and-forget: the controller notifies as states advance.
    _controller.send(text, attachment: attachment);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final messages = _controller.messages;
        return Scaffold(
          backgroundColor: TongtaiDesignTokens.lightBackground,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: TongtaiDesignTokens.lightBackground,
            foregroundColor: TongtaiDesignTokens.lightTextPrimary,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Copilot'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _controller.assistantOnline
                            ? TongtaiDesignTokens.success
                            : TongtaiDesignTokens.neutral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: TongtaiDesignTokens.spacing1),
                    Text(
                      _controller.assistantOnline ? 'Online' : 'Offline',
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(
                            TongtaiDesignTokens.spacing4,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) => _MessageBubble(
                            message: messages[messages.length - 1 - index],
                          ),
                        ),
                ),
                if (_controller.isAssistantTyping) const _TypingIndicator(),
                if (_pendingAttachment != null)
                  _PendingAttachment(
                    attachment: _pendingAttachment!,
                    onRemove: _removePendingAttachment,
                  ),
                _InputBar(controller: _input, onAttach: _attach, onSend: _send),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One message bubble: seller right/blue, assistant left/neutral (AC1), with
/// timestamp and — for seller messages — the delivery ticks (AC3).
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isSeller = message.isSeller;
    final background = isSeller
        ? TongtaiDesignTokens.consumerBlue.withValues(alpha: 0.12)
        : TongtaiDesignTokens.lightHover;
    return Align(
      alignment: isSeller ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('chat-bubble-${message.id}'),
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.cardBorderRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasAttachment) ...[
              _AttachmentView(attachment: message.attachment!),
              if (message.text.isNotEmpty)
                const SizedBox(height: TongtaiDesignTokens.spacing2),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TongtaiDesignTokens.bodyStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeOf(message.timestamp),
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
                if (isSeller) ...[
                  const SizedBox(width: TongtaiDesignTokens.spacing1),
                  _StatusTicks(status: message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _timeOf(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// Delivery-state ticks (AC3): clock while sending, one gray tick when sent,
/// double gray ticks when delivered, double blue ticks when read.
class _StatusTicks extends StatelessWidget {
  const _StatusTicks({required this.status});

  final ChatMessageStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      ChatMessageStatus.sending => (
        Icons.schedule,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      ChatMessageStatus.sent => (
        Icons.check,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      ChatMessageStatus.delivered => (
        Icons.done_all,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      ChatMessageStatus.read => (
        Icons.done_all,
        TongtaiDesignTokens.consumerBlue,
      ),
    };
    return Tooltip(
      message: status.labelEn,
      child: Icon(icon, size: 14, color: color),
    );
  }
}

/// Inline attachment rendering (AC4): image thumbnail when the file previews
/// as an image (placeholder when unreadable, e.g. in tests), otherwise a
/// filename chip.
class _AttachmentView extends StatelessWidget {
  const _AttachmentView({required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      final file = File(attachment.path);
      const size = 140.0;
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        child: file.existsSync()
            ? Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImagePlaceholder(),
              )
            : const _ImagePlaceholder(),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.description_outlined,
          size: 16,
          color: TongtaiDesignTokens.lightTextSecondary,
        ),
        const SizedBox(width: TongtaiDesignTokens.spacing1),
        Flexible(
          child: Text(
            attachment.name,
            overflow: TextOverflow.ellipsis,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      color: TongtaiDesignTokens.lightHover,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: TongtaiDesignTokens.lightTextSecondary,
      ),
    );
  }
}

/// "Assistant is typing…" row (AC5).
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-typing'),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Text(
        'AI Copilot đang nhập… | typing…',
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: TongtaiDesignTokens.lightTextSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Preview of the attachment queued for the next message (AC4), removable.
class _PendingAttachment extends StatelessWidget {
  const _PendingAttachment({required this.attachment, required this.onRemove});

  final ChatAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-pending-attachment'),
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        children: [
          Icon(
            attachment.isImage
                ? Icons.image_outlined
                : Icons.description_outlined,
            size: 16,
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing1),
          Expanded(
            child: Text(
              attachment.name,
              overflow: TextOverflow.ellipsis,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ),
          IconButton(
            key: const Key('chat-remove-attachment'),
            tooltip: 'Remove attachment',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Composer: attach + text field + send (AC2).
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: const BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        border: Border(top: BorderSide(color: TongtaiDesignTokens.lightBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const Key('chat-attach'),
            tooltip: 'Attach file',
            icon: const Icon(Icons.attach_file),
            onPressed: onAttach,
          ),
          Expanded(
            child: TextField(
              key: const Key('chat-input'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nhắn cho AI Copilot… | Message the AI Copilot…',
                filled: true,
                fillColor: TongtaiDesignTokens.lightHover,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    TongtaiDesignTokens.componentBorderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TongtaiDesignTokens.spacing3,
                  vertical: TongtaiDesignTokens.spacing2,
                ),
              ),
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          IconButton.filled(
            key: const Key('chat-send'),
            tooltip: 'Send',
            style: IconButton.styleFrom(
              backgroundColor: TongtaiDesignTokens.copilotViolet,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              'Hỏi AI Copilot về việc kinh doanh của bạn',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              'Ask the AI Copilot about your business.',
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
