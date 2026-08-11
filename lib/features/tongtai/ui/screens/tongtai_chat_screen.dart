import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../chat/chat_controller.dart';
import '../../chat/chat_message.dart';
import '../../inventory/product_image_source.dart';
import '../../core/screen_data_controller.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../providers/tongtai_chat_provider.dart';
import '../widgets/tongtai_fox_mascot.dart';
import 'tongtai_chat_search_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';

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
    // Restore the persisted conversation (WTM-81). Through the seam (WTM-148):
    // an unreadable history is "we could not load your conversation", not a
    // chat that silently starts over.
    _data = ScreenDataController<TongtaiChatController>(
      _read,
      // An injected controller (tests, preview) already holds its messages.
      initialValue: _ownsController ? null : _controller,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'chat',
    )..start();
  }

  late final ScreenDataController<TongtaiChatController> _data;

  Future<TongtaiChatController> _read() async {
    await _controller.hydrate();
    return _controller;
  }

  @override
  void dispose() {
    _data.dispose();
    _input.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    String? path;
    // Picking an image crosses an OS permission boundary — a denial must read
    // as "permission needed", never as a silently ignored tap.
    final failure = await runTongtaiAction(
      () async => path = await _pickAttachment(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'chat',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    if (path == null) return;
    setState(() {
      _pendingAttachment = ChatAttachment(
        path: path!,
        name: path!.split(Platform.pathSeparator).last.split('/').last,
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

  /// Opens Chat Search (WTM-84) over the persisted store (ADR-TON-004, on-device).
  void _openSearch() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            TongtaiChatSearchScreen(store: ref.read(tongtaiChatStoreProvider)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _data]),
      builder: (context, _) {
        final messages = _controller.messages;
        return Scaffold(
          backgroundColor: TtColors.surfaceSecondary,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: TtColors.surfaceSecondary,
            foregroundColor: TtColors.textPrimary,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TongtaiFoxMascot.avatar(
                  size: 34,
                  semanticsLabel: 'Workizen AI',
                ),
                const SizedBox(width: TtSpace.x2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Workizen AI'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _controller.assistantOnline
                                ? TtColors.success
                                : TtColors.unknown,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: TtSpace.x1),
                        Text(
                          _controller.assistantOnline ? 'Online' : 'Offline',
                          style: TtType.caption.copyWith(
                            color: TtColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('chat-open-search'),
                tooltip: context.l10n.actionSearch,
                icon: const Icon(Icons.search),
                onPressed: _openSearch,
              ),
            ],
          ),
          body: SafeArea(
            child: TongtaiScreenData<TongtaiChatController>(
              prefix: 'chat',
              state: _data.state,
              onRetry: _data.retry,
              builder: (context, _) => Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(TtSpace.x4),
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
                  _InputBar(
                    controller: _input,
                    onAttach: _attach,
                    onSend: _send,
                  ),
                ],
              ),
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
        ? TtColors.info.withValues(alpha: 0.12)
        : TtColors.surfaceTertiary;
    return Align(
      alignment: isSeller ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('chat-bubble-${message.id}'),
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: TtSpace.x3),
        padding: const EdgeInsets.all(TtSpace.x3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TtRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasAttachment) ...[
              _AttachmentView(attachment: message.attachment!),
              if (message.text.isNotEmpty) const SizedBox(height: TtSpace.x2),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TtType.bodyLarge.copyWith(color: TtColors.textPrimary),
              ),
            const SizedBox(height: TtSpace.x1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeOf(message.timestamp),
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
                if (isSeller) ...[
                  const SizedBox(width: TtSpace.x1),
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
      ChatMessageStatus.sending => (Icons.schedule, TtColors.textSecondary),
      ChatMessageStatus.sent => (Icons.check, TtColors.textSecondary),
      ChatMessageStatus.delivered => (Icons.done_all, TtColors.textSecondary),
      ChatMessageStatus.read => (Icons.done_all, TtColors.info),
    };
    return Tooltip(
      message: status.label(context.l10n.languageCode),
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
        borderRadius: BorderRadius.circular(TtRadius.sm),
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
          color: TtColors.textSecondary,
        ),
        const SizedBox(width: TtSpace.x1),
        Flexible(
          child: Text(
            attachment.name,
            overflow: TextOverflow.ellipsis,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
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
      color: TtColors.surfaceTertiary,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: TtColors.textSecondary),
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
        horizontal: TtSpace.x4,
        vertical: TtSpace.x1,
      ),
      child: Text(
        context.l10n.chatTyping,
        style: TtType.caption.copyWith(
          color: TtColors.textSecondary,
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
        horizontal: TtSpace.x4,
        vertical: TtSpace.x1,
      ),
      child: Row(
        children: [
          Icon(
            attachment.isImage
                ? Icons.image_outlined
                : Icons.description_outlined,
            size: 16,
            color: TtColors.textSecondary,
          ),
          const SizedBox(width: TtSpace.x1),
          Expanded(
            child: Text(
              attachment.name,
              overflow: TextOverflow.ellipsis,
              style: TtType.body.copyWith(color: TtColors.textPrimary),
            ),
          ),
          IconButton(
            key: const Key('chat-remove-attachment'),
            tooltip: context.l10n.chatRemoveAttachment,
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
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: const BoxDecoration(
        color: TtColors.surfaceSecondary,
        border: Border(top: BorderSide(color: TtColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const Key('chat-attach'),
            tooltip: context.l10n.chatAttachFile,
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
                hintText: context.l10n.chatInputHint,
                filled: true,
                fillColor: TtColors.surfaceTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TtRadius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TtSpace.x3,
                  vertical: TtSpace.x2,
                ),
              ),
            ),
          ),
          const SizedBox(width: TtSpace.x2),
          IconButton.filled(
            key: const Key('chat-send'),
            tooltip: context.l10n.actionSend,
            style: IconButton.styleFrom(
              backgroundColor: TtColors.aiOnLight,
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
        padding: const EdgeInsets.all(TtSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 72),
            const SizedBox(height: TtSpace.x3),
            Text(
              context.l10n.chatEmptyPrompt,
              textAlign: TextAlign.center,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
