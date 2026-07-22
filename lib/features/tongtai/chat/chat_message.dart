import 'package:flutter/foundation.dart';

/// Who authored a chat message (WTM-80 AC1 — sender/receiver differentiation).
enum ChatSender { seller, assistant }

/// Local-first delivery state of a seller message (WTM-80 AC3).
///
/// There is no chat backend in the MVP (PRODUCT-CONTEXT: no backend, BYOK
/// only), so these states track the message through the local pipeline:
/// composed → persisted locally → picked up by the assistant pipeline → read
/// by the responder before it replied.
enum ChatMessageStatus {
  sending,
  sent,
  delivered,
  read;

  String get labelEn => switch (this) {
    ChatMessageStatus.sending => 'Sending',
    ChatMessageStatus.sent => 'Sent',
    ChatMessageStatus.delivered => 'Delivered',
    ChatMessageStatus.read => 'Read',
  };

  String get labelVi => switch (this) {
    ChatMessageStatus.sending => 'Đang gửi',
    ChatMessageStatus.sent => 'Đã gửi',
    ChatMessageStatus.delivered => 'Đã nhận',
    ChatMessageStatus.read => 'Đã đọc',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A file attached to a message (WTM-80 AC4). Only the local path is stored —
/// nothing ever leaves the device.
@immutable
class ChatAttachment {
  const ChatAttachment({required this.path, required this.name});

  /// Absolute local file path.
  final String path;

  /// Display filename, e.g. "hoa-don.jpg".
  final String name;

  /// Whether the attachment should preview as an image (by extension).
  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatAttachment && other.path == path && other.name == name);

  @override
  int get hashCode => Object.hash(path, name);
}

/// One chat message (WTM-80): text and/or an attachment, stamped and tracked
/// through the local delivery states. Immutable — status changes go through
/// [copyWith] on the controller.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = ChatMessageStatus.sending,
    this.attachment,
  });

  final String id;
  final ChatSender sender;
  final String text;

  /// When the message was composed (AC1 — timestamps).
  final DateTime timestamp;

  /// Delivery state; only meaningful for seller messages (AC3).
  final ChatMessageStatus status;

  /// Optional attached file (AC4).
  final ChatAttachment? attachment;

  bool get isSeller => sender == ChatSender.seller;
  bool get hasAttachment => attachment != null;

  ChatMessage copyWith({ChatMessageStatus? status}) => ChatMessage(
    id: id,
    sender: sender,
    text: text,
    timestamp: timestamp,
    status: status ?? this.status,
    attachment: attachment,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage && other.id == id && other.status == status);

  @override
  int get hashCode => Object.hash(id, status);

  @override
  String toString() => 'ChatMessage($id, ${sender.name}, ${status.name})';
}
