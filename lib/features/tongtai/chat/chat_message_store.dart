import 'package:drift/drift.dart';

import '../../../database/database.dart';
import 'chat_message.dart';

/// Filters for querying persisted chat history (WTM-81 AC3): free-text
/// keyword (case-insensitive substring over the message body) and/or an
/// inclusive date range. The search *UI* ships with WTM-84 — this is the
/// persistence-layer capability it will sit on.
class ChatHistoryQuery {
  const ChatHistoryQuery({this.text = '', this.from, this.to});

  /// Keyword matched case-insensitively against the message body.
  final String text;

  /// Earliest timestamp to include (inclusive); null = no lower bound.
  final DateTime? from;

  /// Latest timestamp to include (inclusive); null = no upper bound.
  final DateTime? to;

  bool get isEmpty => text.trim().isEmpty && from == null && to == null;
}

/// Persistence boundary for AI Copilot chat messages (WTM-81).
///
/// Local-only by decision (ADR-TON-004): implementations must never move
/// messages off-device. Same interface + in-memory-fake pattern as the
/// onboarding/tab-state stores so the controller stays testable without a
/// real database.
abstract interface class ChatMessageStore {
  /// Insert [message] (or replace the row with the same id).
  Future<void> save(ChatMessage message);

  /// Update just the delivery [status] of message [id] (AC2: read status is
  /// indexed metadata, not part of an opaque blob).
  Future<void> updateStatus(String id, ChatMessageStatus status);

  /// Every persisted message, oldest first — what the screen hydrates from.
  Future<List<ChatMessage>> loadAll();

  /// Messages matching [query], oldest first (AC3: keyword or date).
  Future<List<ChatMessage>> search(ChatHistoryQuery query);
}

/// Drift/SQLite-backed store over `chat_messages_table` (schema v4).
class DriftChatMessageStore implements ChatMessageStore {
  DriftChatMessageStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(ChatMessage message) {
    return _db
        .into(_db.chatMessagesTable)
        .insertOnConflictUpdate(
          ChatMessagesTableCompanion.insert(
            id: message.id,
            sender: message.sender.name,
            body: message.text,
            sentAt: message.timestamp,
            status: message.status.name,
            attachmentPath: Value(message.attachment?.path),
            attachmentName: Value(message.attachment?.name),
          ),
        );
  }

  @override
  Future<void> updateStatus(String id, ChatMessageStatus status) {
    return (_db.update(_db.chatMessagesTable)..where((t) => t.id.equals(id)))
        .write(ChatMessagesTableCompanion(status: Value(status.name)));
  }

  @override
  Future<List<ChatMessage>> loadAll() async {
    final rows = await (_db.select(
      _db.chatMessagesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.sentAt)])).get();
    return [for (final row in rows) _toMessage(row)];
  }

  @override
  Future<List<ChatMessage>> search(ChatHistoryQuery query) async {
    // Date bounds run in SQL against the indexed sentAt column; the keyword
    // match runs in Dart so it is a plain substring (no LIKE-wildcard
    // injection) and case-insensitive for Vietnamese too, which SQLite's
    // ASCII-only LIKE folding cannot do.
    final select = _db.select(_db.chatMessagesTable)
      ..orderBy([(t) => OrderingTerm.asc(t.sentAt)]);
    final from = query.from;
    if (from != null) {
      select.where((t) => t.sentAt.isBiggerOrEqualValue(from));
    }
    final to = query.to;
    if (to != null) {
      select.where((t) => t.sentAt.isSmallerOrEqualValue(to));
    }
    final rows = await select.get();
    final keyword = query.text.trim().toLowerCase();
    return [
      for (final row in rows)
        if (keyword.isEmpty || row.body.toLowerCase().contains(keyword))
          _toMessage(row),
    ];
  }

  ChatMessage _toMessage(ChatMessagesTableData row) {
    return ChatMessage(
      id: row.id,
      sender: ChatSender.values.byName(row.sender),
      text: row.body,
      timestamp: row.sentAt,
      status: ChatMessageStatus.values.byName(row.status),
      attachment: row.attachmentPath == null
          ? null
          : ChatAttachment(
              path: row.attachmentPath!,
              name: row.attachmentName ?? '',
            ),
    );
  }
}

/// In-memory store for tests and store-less usage (no database required).
class InMemoryChatMessageStore implements ChatMessageStore {
  final List<ChatMessage> _messages = [];

  @override
  Future<void> save(ChatMessage message) async {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      _messages[index] = message;
    } else {
      _messages.add(message);
    }
  }

  @override
  Future<void> updateStatus(String id, ChatMessageStatus status) async {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(status: status);
    }
  }

  @override
  Future<List<ChatMessage>> loadAll() async {
    final sorted = List.of(_messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  @override
  Future<List<ChatMessage>> search(ChatHistoryQuery query) async {
    final keyword = query.text.trim().toLowerCase();
    final all = await loadAll();
    return [
      for (final m in all)
        if ((keyword.isEmpty || m.text.toLowerCase().contains(keyword)) &&
            (query.from == null || !m.timestamp.isBefore(query.from!)) &&
            (query.to == null || !m.timestamp.isAfter(query.to!)))
          m,
    ];
  }
}
