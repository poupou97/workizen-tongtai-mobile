import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import 'demo_event.dart';

/// Hội thoại khách hàng — WTM-339 (E3 · Epic WTM-336).
///
/// ## ⭐ Chiếu, không phải một bảng nữa
///
/// Không có bảng `conversations`. Hội thoại là **chiếu** của sổ sự kiện lên
/// từng khách — đúng kết luận WTM-296 §10: chuỗi việc nối bằng `correlationId`
/// chứ không bằng một thực thể hội thoại.
///
/// Một bảng riêng sẽ lập tức sinh ra câu hỏi *"tin nhắn này đã vào bảng chưa"*
/// và một đường ghi thứ hai để quên. Chiếu thì không thể lệch: nguồn chỉ có
/// một.
///
/// ## Ba phía, vì ba phía có nghĩa khác nhau
///
/// Khách nói · Tổng Tài **soạn** · người bán **đã gửi**. Gộp hai cái sau là
/// xoá mất ranh giới quan trọng nhất của sản phẩm này: máy soạn thì chưa ai
/// nhận được gì.
enum ConversationSide {
  /// Khách — đến từ sàn/mạng xã hội.
  customer,

  /// Tổng Tài soạn. **Chưa gửi.**
  agent,

  /// Người bán đã bấm gửi.
  seller,
}

@immutable
class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.side,
    required this.text,
    required this.at,
    this.vendor,
    this.correlationId,
    this.needsApproval = false,
  });

  final String id;
  final ConversationSide side;

  /// Kênh — `facebook_page` · `shopee`… `null` khi việc xảy ra nội bộ.
  final String? vendor;

  final String text;
  final DateTime at;
  final String? correlationId;

  /// ⭐ Rủi ro cao ⇒ bắt buộc người bán duyệt, bất kể mức tự chủ (§16).
  final bool needsApproval;
}

@immutable
class CustomerConversation {
  const CustomerConversation({
    required this.customerId,
    required this.customerName,
    required this.messages,
    required this.events,
    required this.channels,
    required this.lastAt,
  });

  final String customerId;
  final String customerName;

  /// Cũ → mới, đọc như một khung chat.
  final List<ConversationMessage> messages;

  /// **Mọi** việc chạm khách này — đơn, kiện hàng, hoàn tiền — mới nhất trước.
  /// Đây là phần "360" mà một khung chat không nói được.
  final List<DemoEvent> events;

  /// Mã kênh đã xuất hiện, mới nhất trước.
  final List<String> channels;

  final DateTime lastAt;

  /// Bản nháp Tổng Tài soạn mà người bán **chưa gửi**.
  ///
  /// `null` = không có gì chờ bấm. Suy ra từ thứ tự tin nhắn chứ không từ một
  /// cờ lưu sẵn: một cờ thì có đường quên tắt.
  ConversationMessage? get pendingDraft {
    for (final m in messages.reversed) {
      if (m.side == ConversationSide.seller) return null;
      if (m.side == ConversationSide.agent) return m;
    }
    return null;
  }

  /// Khách đang chờ trả lời.
  bool get awaitingReply {
    for (final m in messages.reversed) {
      if (m.side == ConversationSide.seller) return false;
      if (m.side == ConversationSide.customer) return true;
    }
    return false;
  }

  /// Câu cuối cùng, để hiện ở danh sách.
  ConversationMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;
}

/// Dựng hội thoại từ sổ sự kiện.
///
/// [events] nhận theo **bất kỳ thứ tự nào** — hàm tự sắp. Người gọi truyền
/// thẳng `loadTimeline()` (mới nhất trước) là đúng.
List<CustomerConversation> projectConversations({
  required List<DemoEvent> events,
  required List<Customer> customers,
}) {
  final byId = {for (final c in customers) c.id: c};
  final grouped = <String, List<DemoEvent>>{};

  for (final e in events) {
    final id = customerIdOf(e);
    if (id == null) continue;
    grouped.putIfAbsent(id, () => []).add(e);
  }

  final out = <CustomerConversation>[];
  for (final entry in grouped.entries) {
    final own = entry.value.toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final messages = <ConversationMessage>[];
    final channels = <String>[];
    for (final e in own) {
      final message = _toMessage(e);
      if (message != null) messages.add(message);
      final vendor = e.vendor;
      if (vendor != null && !channels.contains(vendor)) channels.add(vendor);
    }

    out.add(
      CustomerConversation(
        customerId: entry.key,
        // Khách đã bị xoá khỏi danh bạ vẫn phải đọc được câu chuyện — nhưng
        // nói thẳng là không còn tên, chứ không bịa một cái.
        customerName: byId[entry.key]?.name ?? entry.key,
        messages: messages,
        events: own.reversed.toList(growable: false),
        channels: channels.reversed.toList(growable: false),
        lastAt: own.last.occurredAt,
      ),
    );
  }

  out.sort((a, b) => b.lastAt.compareTo(a.lastAt));
  return out;
}

/// Việc này chạm khách nào.
///
/// Hai đường: khách là **chủ thể** của việc, hoặc khách nằm trong payload của
/// một việc về đơn/tồn. Bỏ đường thứ hai thì Khách hàng 360 mất sạch đơn hàng
/// — và đó đúng là thứ khiến nó là "360".
String? customerIdOf(DemoEvent event) {
  if (event.subjectKind == 'customer' && event.subjectId != null) {
    return event.subjectId;
  }
  final fromPayload = event.payload['customerId'];
  return fromPayload is String && fromPayload.isNotEmpty ? fromPayload : null;
}

ConversationMessage? _toMessage(DemoEvent e) {
  if (e.kind != DemoEventKind.messageReceived &&
      e.kind != DemoEventKind.commentReceived) {
    return null;
  }

  final side = switch (e.actor) {
    DemoActor.platform => ConversationSide.customer,
    DemoActor.agent => ConversationSide.agent,
    DemoActor.seller => ConversationSide.seller,
  };

  // Nội dung thật nằm trong payload; `headline` là câu kể cho dòng thời gian
  // ("Chị Lan nhắn: …"). Dùng headline làm nội dung chat sẽ ra một khung chat
  // mà khách tự xưng tên mình ở ngôi thứ ba.
  final text = switch (side) {
    ConversationSide.agent => e.payload['draft'] as String?,
    _ => e.payload['message'] as String?,
  };

  return ConversationMessage(
    id: e.id,
    side: side,
    vendor: e.vendor,
    text: text ?? e.headline,
    at: e.occurredAt,
    correlationId: e.correlationId,
    needsApproval: e.payload['needsApproval'] == true,
  );
}
