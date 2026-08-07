import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/platform/canonical_event.dart';

/// WTM-294 · N3 — Canonical Events (ADR-TON-024 luật 4).
///
/// Nếu connector được phép emit mã riêng của nền tảng thì mỗi sàn mới thêm một
/// từ vựng, và lõi nghiệp vụ phải biết tên riêng của từng sàn — tức **phải sửa
/// kiến trúc lần thứ hai**. Đó đúng là thứ Wave 2 tồn tại để tránh.
void main() {
  CanonicalEvent event({
    String eventId = 'evt-1',
    CanonicalEventType type = CanonicalEventType.orderCreated,
    DateTime? occurredAt,
    DateTime? receivedAt,
    String connectionId = 'conn-1',
    Map<String, Object?> payload = const {},
  }) => CanonicalEvent(
    eventId: eventId,
    type: type,
    occurredAt: occurredAt ?? DateTime(2026, 8, 7, 9),
    receivedAt: receivedAt ?? DateTime(2026, 8, 7, 10),
    connectionId: connectionId,
    payload: payload,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 1 · cùng một sự việc ⇒ cùng một mã', () {
    test('mọi mã đều đúng dạng `<miền>.<việc đã xảy ra>`', () {
      for (final t in CanonicalEventType.values) {
        expect(t.code, '${t.domain.code}.${t.action}');
        expect(t.code.split('.'), hasLength(2), reason: t.code);
      }
    });

    test('không mã nào mang tên nền tảng', () {
      // Phép thử: nếu ngày mai có sàn thứ tư làm cùng việc này, nó dùng được mã
      // này không? Một mã chứa 'shopee' thì câu trả lời là không.
      const platforms = ['shopee', 'tiktok', 'shopify', 'github', 'stripe'];
      for (final t in CanonicalEventType.values) {
        for (final p in platforms) {
          expect(
            t.code.contains(p),
            isFalse,
            reason:
                '${t.code} mô tả CÁCH NỀN TẢNG NÓI, không phải việc đã xảy ra',
          );
        }
      }
    });

    test('mỗi miền có đúng MỘT mã unknown', () {
      for (final d in EventDomain.values) {
        final unknowns = CanonicalEventType.values
            .where((t) => t.domain == d && t.isUnknown)
            .toList();
        expect(unknowns, hasLength(1), reason: d.code);
        expect(unknowns.single.code, d.unknownCode);
      }
    });

    test('mã là duy nhất trên toàn từ vựng', () {
      final codes = CanonicalEventType.values.map((t) => t.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('`type` là enum, nên mã nền tảng KHÔNG dựng được envelope', () {
      // Đây là luật 1 thành cấu trúc: nếu trường này là String thì một
      // connector viết 'shopee.order_status_push' vẫn dựng được envelope.
      expect(event().type, isA<CanonicalEventType>());
      expect(CanonicalEventType.fromCode('shopee.order_status_push'), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 2 · mã lạ ⇒ `<miền>.unknown`, không đoán', () {
    const shopee = ConnectorEventMapping(
      connectorId: 'shopee',
      domain: EventDomain.order,
      mappings: {
        'UNPAID': CanonicalEventType.orderCreated,
        'READY_TO_SHIP': CanonicalEventType.orderPaid,
        'COMPLETED': CanonicalEventType.orderFulfilled,
        'CANCELLED': CanonicalEventType.orderCancelled,
      },
      ignored: {'IN_CANCEL'},
    );

    test('mã đã biết ⇒ đúng mã canonical', () {
      expect(shopee.resolve('COMPLETED'), CanonicalEventType.orderFulfilled);
    });

    test('`TO_CONFIRM_RECEIVE` ⇒ unknown, KHÔNG phải orderFulfilled', () {
      // Cám dỗ cụ thể: nó *gần giống* `order.fulfilled`. Ánh xạ bừa vào đó làm
      // doanh thu ghi nhận SỚM MỘT KHÂU, và không ai phát hiện cho tới khi có
      // đơn bị trả.
      final resolved = shopee.resolve('TO_CONFIRM_RECEIVE');
      expect(resolved, CanonicalEventType.orderUnknown);
      expect(resolved, isNot(CanonicalEventType.orderFulfilled));
      expect(resolved!.isUnknown, isTrue);
    });

    test('mã cố ý bỏ qua ⇒ null, KHÁC hẳn với unknown', () {
      // Bỏ qua là một quyết định đã cân nhắc; unknown là một khoảng trống cần
      // người xem. Gộp chúng thì một mã mới của sàn sẽ im lặng biến mất.
      expect(shopee.resolve('IN_CANCEL'), isNull);
      expect(shopee.resolve('MÃ_CHƯA_TỪNG_THẤY'), isNotNull);
    });

    test('ánh xạ GitHub thật: tag và PR-đóng-không-merge đều bị bỏ qua', () {
      // Hai dòng này đáng chú ý hơn ba dòng kia: không phải mọi thứ nền tảng có
      // đều đáng thành một sự kiện. Ánh xạ tag → release đúng là kiểu đoán mà
      // luật 2 cấm.
      const github = ConnectorEventMapping(
        connectorId: 'github',
        domain: EventDomain.delivery,
        mappings: {
          'commit': CanonicalEventType.deliveryCommit,
          'pull_request_merged': CanonicalEventType.deliveryChangeMerged,
          'release': CanonicalEventType.deliveryReleased,
        },
        ignored: {'tag', 'pull_request_closed_unmerged'},
      );
      expect(github.resolve('tag'), isNull);
      expect(github.resolve('pull_request_closed_unmerged'), isNull);
      expect(github.resolve('commit'), CanonicalEventType.deliveryCommit);
    });

    test('mọi miền đều tra được mã thoát', () {
      for (final d in EventDomain.values) {
        expect(CanonicalEventType.unknownFor(d).domain, d);
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 3 · `event_id` là khoá chống trùng', () {
    test('khoá gồm cả kết nối — hai shop không đụng nhau', () {
      final a = event(connectionId: 'shop-a');
      final b = event(connectionId: 'shop-b');
      expect(a.dedupeKey, isNot(b.dedupeKey));
      expect(a, isNot(b));
    });

    test('cùng khoá ⇒ bằng nhau, dù mốc thời gian khác', () {
      // Chạy lại connector không được sinh đơn ma.
      final a = event(occurredAt: DateTime(2026, 8, 7, 9));
      final b = event(occurredAt: DateTime(2026, 8, 7, 11));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('khoá KHÔNG dựa trên thời gian — hai việc có thể trùng mốc', () {
      final t = DateTime(2026, 8, 7, 9);
      final a = event(eventId: 'e1', occurredAt: t);
      final b = event(eventId: 'e2', occurredAt: t);
      expect(a, isNot(b));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 4 · occurredAt ≠ receivedAt', () {
    test('độ trễ tính từ hai mốc, không phải một', () {
      final e = event(
        occurredAt: DateTime(2026, 8, 7, 9),
        receivedAt: DateTime(2026, 8, 7, 11, 30),
      );
      expect(e.lag, const Duration(hours: 2, minutes: 30));
    });

    test('độ trễ âm được trả NGUYÊN để chẩn đoán, không kẹp về 0', () {
      // Âm là đồng hồ lệch, không phải "tới trước khi xảy ra". Kẹp về 0 là giấu
      // đúng thứ cần nhìn thấy.
      final e = event(
        occurredAt: DateTime(2026, 8, 7, 11),
        receivedAt: DateTime(2026, 8, 7, 9),
      );
      expect(e.lag.isNegative, isTrue);
    });

    test('dữ liệu CŨ HƠN không ghi đè dữ liệu mới', () {
      // Chỗ hay hỏng nhất khi có retry: một lần gọi lại mang về sự việc cũ, và
      // nếu nó ghi đè thì trạng thái đơn lùi lại một bước mà không ai biết.
      final moi = event(occurredAt: DateTime(2026, 8, 7, 11));
      final cu = event(occurredAt: DateTime(2026, 8, 7, 9));
      expect(moi.supersedes(cu), isTrue);
      expect(cu.supersedes(moi), isFalse);
    });

    test('sự kiện của kết nối khác KHÔNG thay thế được nhau', () {
      final a = event(
        connectionId: 'shop-a',
        occurredAt: DateTime(2026, 8, 7, 11),
      );
      final b = event(
        connectionId: 'shop-b',
        occurredAt: DateTime(2026, 8, 7, 9),
      );
      expect(a.supersedes(b), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Backend không đặt kết luận kinh doanh vào payload', () {
    test('payload sạch ⇒ danh sách rỗng', () {
      expect(
        event(
          payload: {'order_id': 'x', 'total': 1000},
        ).businessConclusionsInPayload,
        isEmpty,
      );
    });

    test('mọi khoá cấm đều bị CHẶN NGAY tại constructor', () {
      // Luật này từng chỉ là một lời khuyên: `businessConclusionsInPayload`
      // trả danh sách và chỗ gọi tự quyết. Lời khuyên thì bị bỏ qua đúng vào
      // ngày ai đó vội, nên nó thành assert — envelope xấu không dựng được.
      for (final key in CanonicalEvent.forbiddenPayloadKeys) {
        expect(
          () => event(payload: {key: 1}),
          throwsA(isA<AssertionError>()),
          reason: key,
        );
      }
    });

    test('hàm liệt kê vẫn dùng được để chẩn đoán, và nói ra CÁI NÀO', () {
      // Assert chặn đường dựng envelope; hàm này để soi một payload **chưa**
      // bọc — ví dụ ngay khi vừa nhận từ mạng, để báo lỗi nói được cái nào sai
      // thay vì chỉ ném.
      final raw = {'revenue': 1, 'priority': 2, 'order_id': 'x'};
      expect(
        CanonicalEvent.forbiddenPayloadKeys.where(raw.containsKey),
        hasLength(2),
      );
      expect(event().businessConclusionsInPayload, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bao bì', () {
    test('mặc định là connector đã khai, không phải suy đoán', () {
      final e = event();
      expect(e.provenance.source, ProvenanceSource.connector);
      expect(e.provenance.inferred, isFalse);
      expect(e.provenance.storedCode, 'connector');
    });

    test('mặc định freshness là live, và mã lạ ⇒ null', () {
      expect(event().freshness, FreshnessConfidence.live);
      expect(FreshnessConfidence.fromCode('pretty_fresh'), isNull);
    });

    test('phiên bản bao bì đi kèm mọi sự kiện', () {
      expect(event().envelopeVersion, CanonicalEvent.currentEnvelopeVersion);
    });
  });
}
