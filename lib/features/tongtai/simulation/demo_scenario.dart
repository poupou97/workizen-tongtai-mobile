import 'dart:math';

import '../consumer/customer.dart';
import '../inventory/product.dart';
import 'demo_event.dart';

/// Sinh 30 ngày kinh doanh — WTM-337 (§33 · §34).
///
/// ## ⭐ Tất định, và đó không phải chuyện kỹ thuật
///
/// `Random(seed)` cố định: cùng seed ⇒ **cùng kịch bản**, tới từng phút. Nhờ
/// đó ảnh chụp, test và buổi demo cho Founder đều kể **cùng một câu chuyện** —
/// và khi Founder nói *"cái ở ngày 5 ấy"* thì ta biết chính xác cái nào.
///
/// Một mô phỏng ngẫu nhiên thì mỗi lần mở app là một doanh nghiệp khác, và
/// không ai đối chiếu được gì với ai.
///
/// ## Dữ liệu phải LIÊN KẾT, không phải năm bản ghi rời (§2)
///
/// Mỗi câu chuyện mang một `correlationId` chạy suốt:
///
/// ```
/// Khách bình luận trên Facebook   ─┐
///   → Tổng Tài soạn trả lời         │
///   → Khách đặt đơn Shopee          ├─ cùng correlationId
///   → GHN báo chậm                  │
///   → Khách phàn nàn                │
///   → Tổng Tài chuẩn bị xin lỗi    ─┘
/// ```
///
/// Đó là khác biệt giữa *"app có dữ liệu demo"* và *"app có một doanh nghiệp"*.
class DemoScenario {
  const DemoScenario({this.seed = 20260809, this.days = 30});

  final int seed;
  final int days;

  /// Sinh toàn bộ kịch bản. Ngày 1 là [startedAt].
  ///
  /// Nhận danh mục và danh bạ **thật đã nhập** thay vì tự bịa: một câu hỏi về
  /// *"Áo thun cotton còn màu đen không"* chỉ có nghĩa nếu áo đó có thật trong
  /// kho, với đúng con số tồn.
  List<DemoEvent> generate({
    required DateTime startedAt,
    required List<Product> products,
    required List<Customer> customers,
  }) {
    if (products.isEmpty) return const [];
    final rng = Random(seed);
    final events = <DemoEvent>[];
    var counter = 0;

    String nextId(String prefix) => 'demo-$prefix-${++counter}';
    DateTime at(int day, int hour, int minute) =>
        startedAt.add(Duration(days: day - 1, hours: hour, minutes: minute));

    final sellable = [
      for (final p in products)
        if (p.quantity != null && p.quantity! > 0) p,
    ];
    if (sellable.isEmpty) return const [];

    Product product(int i) => sellable[i % sellable.length];
    Customer? customer(int i) =>
        customers.isEmpty ? null : customers[i % customers.length];

    // ── Câu chuyện 1: từ bình luận Facebook thành đơn hàng ────────────────
    //
    // Đây là hành trình "social → sale" của §6. Nó phải chạy trọn vì đó là
    // hành trình chứng minh hai phía đã nối vào nhau.
    {
      final story = 'story-social-sale';
      final item = product(3);
      final buyer = customer(1);

      events
        ..add(
          DemoEvent(
            id: nextId('cmt'),
            kind: DemoEventKind.commentReceived,
            actor: DemoActor.platform,
            vendor: DemoVendor.facebook,
            subjectKind: 'customer',
            subjectId: buyer?.id,
            correlationId: story,
            headline:
                '${buyer?.name ?? "Một khách"} hỏi trên Facebook: '
                '"${item.name} còn màu đen size M không shop?"',
            payload: {
              'message': '${item.name} còn màu đen size M không shop?',
              'productId': item.id,
              'channel': 'facebook',
              'needsReply': true,
            },
            occurredAt: at(1, 8, 31),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('draft'),
            kind: DemoEventKind.messageReceived,
            actor: DemoActor.agent,
            subjectKind: 'customer',
            subjectId: buyer?.id,
            correlationId: story,
            headline:
                'Tổng Tài soạn xong câu trả lời — đã tra tồn kho '
                '${item.quantity} sản phẩm',
            payload: {
              'draft':
                  'Dạ còn ạ! ${item.name} bên em còn ${item.quantity} sản '
                  'phẩm, giá ${_money(item.pricePerUnit)}. Chị đặt em gửi '
                  'luôn trong hôm nay nhé.',
              'productId': item.id,
              'needsApproval': false,
            },
            occurredAt: at(1, 8, 33),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('ord'),
            kind: DemoEventKind.orderCreated,
            actor: DemoActor.platform,
            vendor: DemoVendor.shopee,
            subjectKind: 'product',
            subjectId: item.id,
            correlationId: story,
            headline: '${buyer?.name ?? "Khách"} đặt ${item.name} trên Shopee',
            payload: {
              'productId': item.id,
              'customerId': buyer?.id,
              'quantity': 1,
              'unitPrice': item.pricePerUnit,
              'channel': 'shopee',
            },
            occurredAt: at(1, 9, 12),
          ),
        );
    }

    // ── Câu chuyện 2: kiện hàng chậm rồi khách giận ───────────────────────
    //
    // §13 + §16. Điểm của nó: cùng một khách, cùng một đơn — nên khi Founder
    // mở khách ra, cả câu chuyện nằm đó chứ không rải rác.
    {
      final story = 'story-late-angry';
      final item = product(7);
      final buyer = customer(2);

      events
        ..add(
          DemoEvent(
            id: nextId('ord'),
            kind: DemoEventKind.orderCreated,
            actor: DemoActor.platform,
            vendor: DemoVendor.tiktok,
            subjectKind: 'product',
            subjectId: item.id,
            correlationId: story,
            headline:
                '${buyer?.name ?? "Khách"} đặt ${item.name} trên TikTok Shop',
            payload: {
              'productId': item.id,
              'customerId': buyer?.id,
              'quantity': 2,
              'unitPrice': item.pricePerUnit,
              'channel': 'tiktok',
            },
            occurredAt: at(2, 10, 5),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('shp'),
            kind: DemoEventKind.shipmentDelayed,
            actor: DemoActor.platform,
            vendor: DemoVendor.ghn,
            subjectKind: 'shipment',
            correlationId: story,
            headline: 'GHN báo kiện của ${buyer?.name ?? "khách"} chậm 2 ngày',
            payload: {'carrier': 'ghn', 'delayDays': 2},
            occurredAt: at(4, 14, 20),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('msg'),
            kind: DemoEventKind.messageReceived,
            actor: DemoActor.platform,
            vendor: DemoVendor.facebook,
            subjectKind: 'customer',
            subjectId: buyer?.id,
            correlationId: story,
            headline:
                '${buyer?.name ?? "Khách"} nhắn: "Shop làm ăn kiểu gì vậy? '
                'Đơn tôi 5 ngày chưa tới!"',
            payload: {
              'message': 'Shop làm ăn kiểu gì vậy? Đơn tôi 5 ngày chưa tới!',
              'sentiment': 'negative',
              // ⭐ Rủi ro cao ⇒ bắt buộc duyệt, bất kể mức tự động (§16). Một
              // câu trả lời sai cho khách đang giận không rút lại được.
              'needsApproval': true,
              'needsReply': true,
            },
            occurredAt: at(5, 9, 40),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('draft'),
            kind: DemoEventKind.messageReceived,
            actor: DemoActor.agent,
            subjectKind: 'customer',
            subjectId: buyer?.id,
            correlationId: story,
            headline:
                'Tổng Tài chuẩn bị lời xin lỗi — CẦN bạn duyệt trước khi gửi',
            payload: {
              'draft':
                  'Em xin lỗi chị về việc giao hàng chậm. Em vừa kiểm tra với '
                  'GHN, kiện đang ở kho Hà Nội và dự kiến giao trong hôm nay. '
                  'Em gửi chị mã giảm 50k cho lần mua sau ạ.',
              'needsApproval': true,
            },
            occurredAt: at(5, 9, 45),
          ),
        );
    }

    // ── Câu chuyện 4: cùng một câu hỏi, kênh khác ─────────────────────────
    //
    // Người bán Việt Nam hiếm khi bán một kênh. Một khách hỏi trên Instagram
    // trong khi khách khác hỏi trên Facebook là **bình thường**, và nó là thứ
    // duy nhất chứng minh hộp thư gom được nhiều kênh chứ không phải một kênh
    // đổi tên.
    {
      final story = 'story-instagram-ask';
      final item = product(11);
      final buyer = customer(5);

      events
        ..add(
          DemoEvent(
            id: nextId('cmt'),
            kind: DemoEventKind.commentReceived,
            actor: DemoActor.platform,
            vendor: DemoVendor.instagram,
            subjectKind: 'customer',
            subjectId: buyer?.id,
            correlationId: story,
            headline:
                '${buyer?.name ?? "Một khách"} hỏi trên Instagram: '
                '"${item.name} ship Đà Nẵng mấy ngày ạ?"',
            payload: {
              'message': '${item.name} ship Đà Nẵng mấy ngày ạ?',
              'productId': item.id,
              'channel': 'instagram',
              'needsReply': true,
            },
            occurredAt: at(3, 20, 12),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('draft'),
            kind: DemoEventKind.messageReceived,
            actor: DemoActor.agent,
            subjectKind: 'customer',
            subjectId: buyer?.id,
            correlationId: story,
            headline: 'Tổng Tài soạn xong câu trả lời cho Instagram',
            payload: {
              'draft':
                  'Dạ ${item.name} bên em gửi Đà Nẵng khoảng 2–3 ngày ạ. '
                  'Chị đặt trước 15h thì em gửi trong ngày nhé.',
              'productId': item.id,
              'needsApproval': false,
            },
            occurredAt: at(3, 20, 14),
          ),
        );
    }

    // ── Câu chuyện 5: hai hãng vận chuyển, cùng một tuyến ─────────────────
    //
    // Luật so sánh của WTM-323 cần **hàng xóm**: cùng tuyến, cùng hãng, cùng
    // khoảng thời gian. Một hãng duy nhất trong cả tháng thì luật đó không bao
    // giờ có gì để so, và người bán sẽ kết luận tính năng hỏng.
    {
      events
        ..add(
          DemoEvent(
            id: nextId('shp'),
            kind: DemoEventKind.shipmentDelayed,
            actor: DemoActor.platform,
            vendor: DemoVendor.ghtk,
            subjectKind: 'shipment',
            correlationId: 'story-carrier-compare',
            headline: 'GHTK báo một kiện TP.HCM → Hà Nội chậm',
            payload: {'carrier': 'ghtk', 'delayDays': 3},
            occurredAt: at(9, 11, 0),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('shp'),
            kind: DemoEventKind.shipmentDelayed,
            actor: DemoActor.platform,
            vendor: DemoVendor.viettelPost,
            subjectKind: 'shipment',
            correlationId: 'story-carrier-compare',
            headline: 'Viettel Post báo một kiện TP.HCM → Hà Nội chậm',
            payload: {'carrier': 'viettel_post', 'delayDays': 2},
            occurredAt: at(11, 15, 30),
          ),
        );
    }

    // ── Câu chuyện 3: hết hàng → tìm nguồn → nhập ─────────────────────────
    {
      final story = 'story-sourcing';
      final item = sellable.reduce(
        (a, b) => (a.quantity ?? 0) < (b.quantity ?? 0) ? a : b,
      );

      events
        ..add(
          DemoEvent(
            id: nextId('inv'),
            kind: DemoEventKind.inventoryLow,
            actor: DemoActor.agent,
            subjectKind: 'product',
            subjectId: item.id,
            correlationId: story,
            headline:
                'Tổng Tài phát hiện ${item.name} chỉ còn ${item.quantity} '
                '— dưới mức đặt lại',
            payload: {'productId': item.id, 'quantity': item.quantity},
            occurredAt: at(6, 9, 5),
          ),
        )
        ..add(
          DemoEvent(
            id: nextId('quote'),
            kind: DemoEventKind.supplierQuoteChanged,
            actor: DemoActor.platform,
            vendor: DemoVendor.taobao1688,
            subjectKind: 'product',
            subjectId: item.id,
            correlationId: story,
            headline:
                'Nguồn trên 1688 báo giá ${item.name} rẻ hơn 12% '
                'nhưng giao chậm hơn 6 ngày',
            payload: {
              'productId': item.id,
              'savingRatio': 0.12,
              'slowerByDays': 6,
            },
            occurredAt: at(7, 11, 30),
          ),
        );
    }

    // ── Nhịp nền: đơn về mỗi ngày, tiền sàn về theo tuần ──────────────────
    for (var day = 1; day <= days; day++) {
      final ordersToday = 2 + rng.nextInt(4);
      for (var i = 0; i < ordersToday; i++) {
        final item = product(day * 7 + i);
        final buyer = customer(day * 3 + i);
        final channel = rng.nextBool() ? DemoVendor.shopee : DemoVendor.tiktok;

        events.add(
          DemoEvent(
            id: nextId('ord'),
            kind: DemoEventKind.orderCreated,
            actor: DemoActor.platform,
            vendor: channel,
            subjectKind: 'product',
            subjectId: item.id,
            correlationId: 'order-day$day-$i',
            headline:
                'Đơn mới trên ${DemoVendor.displayName(channel)}: ${item.name}',
            payload: {
              'productId': item.id,
              'customerId': buyer?.id,
              'quantity': 1 + rng.nextInt(2),
              'unitPrice': item.pricePerUnit,
              'channel': channel,
            },
            occurredAt: at(day, 8 + rng.nextInt(10), rng.nextInt(60)),
          ),
        );
      }

      // Tiền sàn về mỗi thứ Hai của thế giới mô phỏng.
      if (day % 7 == 0) {
        events.add(
          DemoEvent(
            id: nextId('stl'),
            kind: DemoEventKind.settlementReceived,
            actor: DemoActor.platform,
            vendor: DemoVendor.shopee,
            correlationId: 'settlement-week${day ~/ 7}',
            headline: 'Shopee đã đối soát tuần ${day ~/ 7} — phí sàn đã vào sổ',
            payload: {'week': day ~/ 7},
            occurredAt: at(day, 7, 0),
          ),
        );
        // Đối soát và **tiền thực sự về tài khoản** là hai việc khác nhau, và
        // khoảng cách giữa chúng là thứ người bán sống cùng mỗi tuần. Gộp làm
        // một là xoá mất đúng chỗ dòng tiền bị kẹt.
        events.add(
          DemoEvent(
            id: nextId('bank'),
            kind: DemoEventKind.paymentSucceeded,
            actor: DemoActor.platform,
            vendor: DemoVendor.bank,
            correlationId: 'settlement-week${day ~/ 7}',
            headline:
                'Ngân hàng báo có: tiền đối soát tuần ${day ~/ 7} đã về tài '
                'khoản',
            payload: {'week': day ~/ 7, 'source': 'shopee'},
            occurredAt: at(day, 9, 30),
          ),
        );
      }

      // Ngày 14: chiến dịch tốt về ROAS nhưng mỏng về lời (§27).
      if (day == 14) {
        events.add(
          DemoEvent(
            id: nextId('cmp'),
            kind: DemoEventKind.campaignPerformanceChanged,
            actor: DemoActor.agent,
            vendor: DemoVendor.facebookAds,
            correlationId: 'campaign-1',
            headline:
                'Chiến dịch Facebook có ROAS 3,2 nhưng sau phí sàn và giá vốn '
                'thì gần như hoà vốn',
            payload: {'roas': 3.2, 'profitAfterAll': 180000},
            occurredAt: at(day, 16, 10),
          ),
        );
      }

      // Ngày 21: một khách lặng lâu.
      if (day == 21 && customers.isNotEmpty) {
        final quiet = customer(11);
        events.add(
          DemoEvent(
            id: nextId('churn'),
            kind: DemoEventKind.customerChurnRisk,
            actor: DemoActor.agent,
            subjectKind: 'customer',
            subjectId: quiet?.id,
            correlationId: 'churn-${quiet?.id}',
            headline:
                '${quiet?.name ?? "Một khách quen"} đã 92 ngày không quay lại '
                '— trước đây mua đều mỗi tháng',
            payload: {'customerId': quiet?.id, 'silentDays': 92},
            occurredAt: at(day, 9, 15),
          ),
        );
      }

      // Ngày 28: khách tới nhịp mua lại (§19).
      if (day == 28 && customers.isNotEmpty) {
        final loyal = customer(4);
        events.add(
          DemoEvent(
            id: nextId('repeat'),
            kind: DemoEventKind.repeatPurchaseDue,
            actor: DemoActor.agent,
            subjectKind: 'customer',
            subjectId: loyal?.id,
            correlationId: 'repeat-${loyal?.id}',
            headline:
                '${loyal?.name ?? "Khách quen"} thường mua lại sau 30 ngày '
                '— hôm nay là ngày thứ 28',
            payload: {'customerId': loyal?.id, 'cycleDays': 30},
            occurredAt: at(day, 8, 20),
          ),
        );
      }
    }

    events.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return events;
  }

  static String _money(double amount) {
    final value = amount.round();
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} triệu';
    }
    return '${(value / 1000).round()}k';
  }
}
