import 'package:drift/drift.dart';

/// ChatMessage entity (WTM-81): one row per AI Copilot chat message, replacing
/// the Hub-era JSON-blob shape of `ai_chats` for new chat code.
///
/// Local-only by decision (ADR-TON-004): rows are never enqueued into the
/// sync outbox. Metadata columns are real (indexed) columns — sender,
/// timestamp, status — so history can be queried and searched without parsing
/// blobs (AC2/AC3). Added in schema v4.
@TableIndex(name: 'chat_messages_conversation', columns: {#conversationId})
@TableIndex(name: 'chat_messages_sent_at', columns: {#sentAt})
class ChatMessagesTable extends Table {
  TextColumn get id => text()();

  /// Conversation the message belongs to. The MVP has a single Copilot
  /// conversation ('default'); threads (WTM-84) can partition on this later.
  TextColumn get conversationId =>
      text().withDefault(const Constant('default'))();

  /// 'seller' or 'assistant' — `ChatSender.name`.
  TextColumn get sender => text()();

  /// Message text (may be empty for attachment-only messages).
  TextColumn get body => text()();

  /// When the message was composed.
  DateTimeColumn get sentAt => dateTime()();

  /// Local delivery state — `ChatMessageStatus.name` (AC2: read status).
  TextColumn get status => text()();

  /// Local file path/name of an attachment, when present. Paths never leave
  /// the device (ADR-TON-004).
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get attachmentName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
