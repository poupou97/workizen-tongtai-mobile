import 'package:flutter/foundation.dart';

import 'chat_message.dart';
import 'chat_message_store.dart';

/// Produces the assistant's reply to a seller message (WTM-80).
///
/// WTM-82 (AI Prompt Routing) will provide the real implementation over the
/// BYOK xAI client (WTM-61); until then [EchoChatResponder] gives the screen a
/// deterministic local reply, keeping the whole chat flow testable offline.
abstract interface class ChatResponder {
  /// Reply to [prompt] given the conversation [history] (oldest first).
  Future<String> reply(List<ChatMessage> history, String prompt);
}

/// Default local responder: acknowledges the seller's message bilingually.
/// Deterministic — no network, no randomness.
class EchoChatResponder implements ChatResponder {
  const EchoChatResponder();

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) async {
    return 'Đã nhận tin nhắn của bạn. Trợ lý AI sẽ được kết nối ở WTM-82 — '
        'hiện tại đây là phản hồi cục bộ.\n'
        'Got your message. The AI assistant hooks up in WTM-82 — this is a '
        'local reply for now.';
  }
}

/// Conversation state behind the Chat screen (WTM-80), persisted through an
/// optional [ChatMessageStore] (WTM-81).
///
/// Local-first: messages live in memory, mirrored write-through into the
/// store (Drift/SQLite in production — local-only per ADR-TON-004). Sending
/// walks the seller message through the local delivery states (sending →
/// sent → delivered, then read once the responder consumed it — AC3), raises
/// the typing indicator while the responder works (AC5), and appends the
/// assistant's reply. Call [hydrate] once after construction to restore the
/// persisted conversation.
class TongtaiChatController extends ChangeNotifier {
  TongtaiChatController({
    ChatResponder? responder,
    ChatMessageStore? store,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _responder = responder ?? const EchoChatResponder(),
       // ignore: prefer_initializing_formals — the field is nullable on purpose
       _store = store,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _sequentialId;

  static int _sequence = 0;
  static String _sequentialId() => 'msg-${++_sequence}';

  final ChatResponder _responder;
  final ChatMessageStore? _store;
  final DateTime Function() _clock;
  final String Function() _idFactory;

  final List<ChatMessage> _messages = [];
  bool _assistantTyping = false;
  bool _hydrated = false;

  /// Conversation, oldest first.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Whether [hydrate] has completed (or no store is attached, in which case
  /// there is nothing to restore).
  bool get isHydrated => _hydrated || _store == null;

  /// Restore the persisted conversation (WTM-81 AC5: history survives
  /// restarts and offline periods). Messages sent before hydration completes
  /// are preserved: restored history is prepended, keeping timestamp order.
  Future<void> hydrate() async {
    final store = _store;
    if (store == null || _hydrated) return;
    final persisted = await store.loadAll();
    _hydrated = true;
    if (persisted.isEmpty) {
      notifyListeners();
      return;
    }
    final liveIds = {for (final m in _messages) m.id};
    _messages.insertAll(0, [
      for (final m in persisted)
        if (!liveIds.contains(m.id)) m,
    ]);
    notifyListeners();
  }

  /// Whether the assistant is composing a reply (AC5 — typing indicator).
  bool get isAssistantTyping => _assistantTyping;

  /// Local presence: the on-device assistant is always reachable (AC5). A
  /// remote-backed chat would derive this from a connection state instead.
  bool get assistantOnline => true;

  /// Send a seller message. Blank text with no attachment is ignored. The
  /// returned future completes when the assistant's reply has arrived.
  Future<void> send(String text, {ChatAttachment? attachment}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachment == null) return;

    var message = ChatMessage(
      id: _idFactory(),
      sender: ChatSender.seller,
      text: trimmed,
      timestamp: _clock(),
      attachment: attachment,
    );
    _messages.add(message);
    notifyListeners();
    // Write-through BEFORE any status advance: even if the app dies mid-send
    // (offline period, crash), the composed message is already on disk
    // (WTM-81 AC5 — messages preserved until processed).
    await _persist(message);

    // Local pipeline: the message is immediately persisted-and-picked-up, so
    // it advances straight to delivered (no network hop exists to fail).
    message = await _update(message.id, ChatMessageStatus.delivered);

    _assistantTyping = true;
    notifyListeners();
    try {
      final replyText = await _responder.reply(messages, trimmed);
      // The responder has consumed the message — mark it read (AC3).
      await _update(message.id, ChatMessageStatus.read);
      final reply = ChatMessage(
        id: _idFactory(),
        sender: ChatSender.assistant,
        text: replyText,
        timestamp: _clock(),
        status: ChatMessageStatus.read,
      );
      _messages.add(reply);
      await _persist(reply);
    } finally {
      _assistantTyping = false;
      notifyListeners();
    }
  }

  Future<void> _persist(ChatMessage message) async {
    final store = _store;
    if (store == null) return;
    await store.save(message);
  }

  Future<ChatMessage> _update(String id, ChatMessageStatus status) async {
    final index = _messages.indexWhere((m) => m.id == id);
    final updated = _messages[index].copyWith(status: status);
    _messages[index] = updated;
    notifyListeners();
    await _store?.updateStatus(id, status);
    return updated;
  }
}
