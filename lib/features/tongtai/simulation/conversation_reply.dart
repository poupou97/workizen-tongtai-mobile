import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../action/business_action.dart';
import '../action/business_action_executor.dart';
import 'customer_conversation.dart';
import 'demo_event.dart';
import 'demo_event_repository.dart';

/// Gửi câu trả lời cho khách — WTM-339 (E3 · Epic WTM-336).
///
/// ## ⭐ Dữ liệu là giả, ĐƯỜNG ĐI thì thật (§40)
///
/// Câu trả lời không ra khỏi máy. Nhưng nó vẫn đi trọn `plan → approve → run`
/// của [BusinessActionExecutor]: có vòng đời, có lease, có chống lặp, và kết
/// quả mang tiền tố `demo:` nên **không màn nào hiểu nhầm là đã gửi thật**.
///
/// Đường tắt — ghi thẳng một `DemoEvent` "đã gửi" — sẽ cho Founder đúng cái
/// ảnh cần chụp, và để lại một đường ghi thứ hai không ai kiểm. Ngày Messenger
/// thật xuất hiện, thứ phải đổi là **một handler**, không phải màn này.
class ConversationReplyService {
  const ConversationReplyService({
    required this.actions,
    required this.events,
    this.now = DateTime.now,
  });

  final BusinessActionExecutor actions;
  final DemoEventRepository events;
  final DateTime Function() now;

  /// Gửi [text] cho khách của [conversation], trả lời bản nháp [draft].
  ///
  /// Sửa lời rồi gửi là một việc **khác** — khoá chống lặp gồm vân tay nội
  /// dung, nên gửi lại y nguyên thì an toàn, còn sửa rồi gửi thì ra một tin
  /// thứ hai đúng như người bán vừa bấm.
  Future<ActionRunResult> send({
    required CustomerConversation conversation,
    required ConversationMessage draft,
    required String text,
  }) async {
    final parameters = <String, Object?>{
      'text': text,
      'channel': draft.vendor,
      'customerId': conversation.customerId,
    };
    final digest = sha256
        .convert(utf8.encode(BusinessActionExecutor.hashRequest(parameters)))
        .toString()
        .substring(0, 12);
    final key = 'conversation-reply:${draft.id}:$digest';

    final at = now();
    final action = BusinessAction(
      id: key,
      type: BusinessActionType.customerSendMessage,
      // Chưa nền tảng nào nhận — `demo` là *nơi chạy*, không phải một cờ.
      vendor: ActionVendor.demo,
      subjectKind: 'customer',
      subjectId: conversation.customerId,
      subjectLabel: conversation.customerName,
      summary: 'Gửi trả lời cho ${conversation.customerName}',
      proposedBy: 'agent',
      correlationId: draft.correlationId,
      parameters: parameters,
      idempotencyKey: key,
      requestHash: BusinessActionExecutor.hashRequest(parameters),
      plannedAt: at,
    );

    await actions.plan(action);
    final refused = await actions.approve(action.id, requestedBy: 'seller');
    if (refused != null) return refused;

    final result = await actions.run(action.id);
    if (result is! ActionSucceeded) return result;

    // Chỉ ghi vào sổ khi hành động đã chạy xong. Ghi trước là kể một chuyện
    // chưa xảy ra — đúng lỗi mà `appliedAt` sinh ra để chặn.
    await events.saveAll([
      DemoEvent(
        id: 'seller-reply-${action.id}',
        kind: DemoEventKind.messageReceived,
        actor: DemoActor.seller,
        vendor: draft.vendor,
        subjectKind: 'customer',
        subjectId: conversation.customerId,
        correlationId: draft.correlationId,
        headline: 'Bạn đã trả lời ${conversation.customerName}',
        payload: {'message': text, 'actionId': action.id},
        occurredAt: at,
        appliedAt: at,
      ),
    ]);

    return result;
  }
}
