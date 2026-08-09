import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/simulation/customer_conversation.dart';
import 'package:tongtai/features/tongtai/simulation/demo_event.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_conversations_screen.dart';

/// WTM-339 · E3 — chiếu sổ sự kiện thành hội thoại khách hàng.
void main() {
  final at = DateTime(2026, 8, 9, 9);

  Customer buyer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '0900000000',
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  DemoEvent event({
    required String id,
    required DemoEventKind kind,
    required DemoActor actor,
    String? vendor,
    String? subjectKind,
    String? subjectId,
    Map<String, Object?> payload = const {},
    String headline = 'việc',
    int minute = 0,
  }) => DemoEvent(
    id: id,
    kind: kind,
    actor: actor,
    vendor: vendor,
    subjectKind: subjectKind,
    subjectId: subjectId,
    correlationId: 'story-1',
    headline: headline,
    payload: payload,
    occurredAt: at.add(Duration(minutes: minute)),
    appliedAt: at,
  );

  test('⭐ khách nằm trong payload vẫn vào 360 — nếu không thì mất sạch đơn', () {
    final conversations = projectConversations(
      events: [
        event(
          id: 'e1',
          kind: DemoEventKind.orderCreated,
          actor: DemoActor.platform,
          vendor: DemoVendor.shopee,
          subjectKind: 'product',
          subjectId: 'p1',
          payload: {'customerId': 'c1'},
          headline: 'Chị Lan đặt Áo thun trên Shopee',
        ),
      ],
      customers: [buyer('c1', 'Chị Lan')],
    );

    expect(conversations, hasLength(1));
    expect(conversations.single.customerName, 'Chị Lan');
    expect(conversations.single.events, hasLength(1));
    // Đơn hàng không phải tin nhắn — nó nằm ở "câu chuyện", không ở khung chat.
    expect(conversations.single.messages, isEmpty);
  });

  test('⭐ nội dung chat lấy từ payload, KHÔNG lấy headline', () {
    final conversations = projectConversations(
      events: [
        event(
          id: 'e1',
          kind: DemoEventKind.commentReceived,
          actor: DemoActor.platform,
          vendor: DemoVendor.facebook,
          subjectKind: 'customer',
          subjectId: 'c1',
          payload: {'message': 'Còn màu đen không shop?'},
          headline: 'Chị Lan hỏi trên Facebook: "Còn màu đen không shop?"',
        ),
      ],
      customers: [buyer('c1', 'Chị Lan')],
    );

    // Dùng headline làm nội dung sẽ ra một khung chat mà khách tự xưng tên
    // mình ở ngôi thứ ba.
    expect(
      conversations.single.messages.single.text,
      'Còn màu đen không shop?',
    );
    expect(
      conversations.single.messages.single.side,
      ConversationSide.customer,
    );
  });

  test('nháp của Tổng Tài là nháp cho tới khi người bán gửi', () {
    List<DemoEvent> base() => [
      event(
        id: 'e1',
        kind: DemoEventKind.messageReceived,
        actor: DemoActor.platform,
        vendor: DemoVendor.facebook,
        subjectKind: 'customer',
        subjectId: 'c1',
        payload: {'message': 'Đơn tôi đâu?', 'needsReply': true},
        minute: 1,
      ),
      event(
        id: 'e2',
        kind: DemoEventKind.messageReceived,
        actor: DemoActor.agent,
        subjectKind: 'customer',
        subjectId: 'c1',
        payload: {'draft': 'Em xin lỗi chị…', 'needsApproval': true},
        minute: 2,
      ),
    ];

    final before = projectConversations(
      events: base(),
      customers: [buyer('c1', 'Chị Lan')],
    ).single;
    expect(before.pendingDraft?.text, 'Em xin lỗi chị…');
    expect(before.pendingDraft?.needsApproval, isTrue);
    expect(before.awaitingReply, isTrue);

    final after = projectConversations(
      events: [
        ...base(),
        event(
          id: 'e3',
          kind: DemoEventKind.messageReceived,
          actor: DemoActor.seller,
          subjectKind: 'customer',
          subjectId: 'c1',
          payload: {'message': 'Em xin lỗi chị…'},
          minute: 3,
        ),
      ],
      customers: [buyer('c1', 'Chị Lan')],
    ).single;

    // Gửi rồi thì không còn gì chờ bấm — suy ra từ thứ tự, không từ một cờ.
    expect(after.pendingDraft, isNull);
    expect(after.awaitingReply, isFalse);
  });

  test('⭐ hộp thư: việc cần duyệt lên đầu, không phải cái mới nhất', () {
    CustomerConversation only(List<DemoEvent> events, Customer c) =>
        projectConversations(events: events, customers: [c]).single;

    final needsApproval = only([
      event(
        id: 'a1',
        kind: DemoEventKind.messageReceived,
        actor: DemoActor.platform,
        subjectKind: 'customer',
        subjectId: 'c1',
        payload: {'message': 'Đơn tôi đâu?'},
        minute: 0,
      ),
      event(
        id: 'a2',
        kind: DemoEventKind.messageReceived,
        actor: DemoActor.agent,
        subjectKind: 'customer',
        subjectId: 'c1',
        payload: {'draft': 'Em xin lỗi…', 'needsApproval': true},
        minute: 1,
      ),
    ], buyer('c1', 'Khách giận'));

    final newerButDone = only([
      event(
        id: 'b1',
        kind: DemoEventKind.messageReceived,
        actor: DemoActor.seller,
        subjectKind: 'customer',
        subjectId: 'c2',
        payload: {'message': 'Dạ em gửi rồi ạ'},
        minute: 99,
      ),
    ], buyer('c2', 'Khách xong'));

    final sorted = conversationsForInbox([newerButDone, needsApproval]);

    // Sắp theo thời gian thuần thì câu hỏi "tôi nợ ai câu trả lời" phải cuộn
    // tay mà tìm — và đó là câu hỏi duy nhất khiến người ta mở màn này.
    expect(sorted.first.customerName, 'Khách giận');
  });

  test('⭐ hộp thư chỉ liệt kê HỘI THOẠI, không liệt kê mọi khách có đơn', () {
    final onlyOrders = projectConversations(
      events: [
        event(
          id: 'e1',
          kind: DemoEventKind.orderCreated,
          actor: DemoActor.platform,
          vendor: DemoVendor.shopee,
          subjectKind: 'product',
          subjectId: 'p1',
          payload: {'customerId': 'c9'},
        ),
      ],
      customers: [buyer('c9', 'Khách chỉ mua')],
    );

    // Chiếu VẪN giữ khách này — Khách hàng 360 cần cả đơn hàng.
    expect(onlyOrders.single.events, hasLength(1));
    // …nhưng hộp thư thì không: một hộp thư liệt kê cả người chưa từng nói
    // câu nào sẽ chôn ba hội thoại thật giữa bốn mươi dòng trống.
    expect(conversationsForInbox(onlyOrders), isEmpty);
  });

  test('khách đã xoá khỏi danh bạ vẫn đọc được, và không bịa tên', () {
    final conversations = projectConversations(
      events: [
        event(
          id: 'e1',
          kind: DemoEventKind.messageReceived,
          actor: DemoActor.platform,
          subjectKind: 'customer',
          subjectId: 'ghost',
          payload: {'message': 'alo'},
        ),
      ],
      customers: const [],
    );

    expect(conversations.single.customerName, 'ghost');
  });
}
