// Phân khúc khách suy từ đơn thật — WTM-419 (concept-1 `cp4`).
//
// Luật này thay một nhãn **lưu sẵn** bằng một kết luận **tính ra**, nên thứ
// đáng canh không phải "có ra đúng chữ không" mà là **nó có nói dối không**:
//
//   §1 khách chưa mua ⇒ KHÔNG xếp phân khúc. Xếp họ vào "khách mới" là biến ô
//      trống thành lời khẳng định, và thổi phồng đúng con số người bán dùng để
//      tự đánh giá mình có bao nhiêu khách.
//   §2 vòng đời trả lời TRƯỚC số lần mua: một khách đã rời bỏ thì việc từng mua
//      10 lần không làm họ thành "trung thành" ở thì hiện tại.
//   §3 VIP là **phân vị của tệp**, không phải mốc tiền cố định — và phân vị
//      phải tính trên người ĐÃ MUA, vì gộp người chưa mua (chi 0) sẽ kéo mốc
//      xuống và phong VIP cho một khách trung bình.
//   §4 luật KHÔNG đẻ ngưỡng riêng: nó phải nhất quán với `customerLifecycleStage`
//      — hai con số cạnh nhau trên cùng một màn không được nói ngược nhau.
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/analytics/customer_segment_rule.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer_segment.dart';

final _now = DateTime(2026, 8, 15);

/// Hồ sơ RFM dựng thẳng — test luật, không test đường nạp.
CustomerRfm _rfm(
  String id, {
  required int? recencyDays,
  required int frequency,
  required double monetary,
  double? medianGapDays,
  int? firstOrderDaysAgo,
}) => CustomerRfm(
  customerId: id,
  recencyDays: recencyDays,
  frequency: frequency,
  monetary: monetary,
  firstOrderAt: firstOrderDaysAgo == null
      ? null
      : _now.subtract(Duration(days: firstOrderDaysAgo)),
  lastOrderAt: recencyDays == null
      ? null
      : _now.subtract(Duration(days: recencyDays)),
  medianGapDays: medianGapDays,
  ordersInWindow: frequency,
);

void main() {
  test('§1 khách chưa mua KHÔNG có phân khúc', () {
    final segments = customerSegmentsFrom(
      profiles: [
        const CustomerRfm.noOrders('c-chua-mua'),
        _rfm('c-da-mua', recencyDays: 5, frequency: 2, monetary: 1000000,
            medianGapDays: 20, firstOrderDaysAgo: 60),
      ],
      now: _now,
    );

    expect(
      segments.containsKey('c-chua-mua'),
      isFalse,
      reason: 'một liên hệ chưa từng mua có mọi tín hiệu VẮNG, không phải bằng '
          '0 — xếp họ vào "khách mới" là thổi phồng số khách',
    );
    expect(segments['c-da-mua'], isNotNull);
  });

  test('§2 đã rời bỏ thì mua nhiều lần cũng không phải trung thành', () {
    // 10 đơn, nhịp 20 ngày, nhưng im lặng 200 ngày = 10× nhịp ⇒ churned.
    final segments = customerSegmentsFrom(
      profiles: [
        _rfm('c1', recencyDays: 200, frequency: 10, monetary: 50000000,
            medianGapDays: 20, firstOrderDaysAgo: 400),
      ],
      now: _now,
    );

    expect(segments['c1'], CustomerSegment.churned);
  });

  test('§2b nhất quán với vòng đời ở CẢ BỐN bậc', () {
    // Cùng một khách, chỉ đổi độ trễ so với nhịp 20 ngày của chính họ.
    for (final (recency, stage, segment) in [
      (10, CustomerLifecycleStage.active, CustomerSegment.loyal),
      (25, CustomerLifecycleStage.cooling, CustomerSegment.slowing),
      (50, CustomerLifecycleStage.atRisk, CustomerSegment.atRisk),
      (200, CustomerLifecycleStage.churned, CustomerSegment.churned),
    ]) {
      final profile = _rfm('c', recencyDays: recency, frequency: 5,
          monetary: 1000000, medianGapDays: 20, firstOrderDaysAgo: 300);

      expect(
        customerLifecycleStage(profile),
        stage,
        reason: 'giả định của test lệch khỏi thang vòng đời thật',
      );
      expect(
        customerSegmentsFrom(profiles: [profile], now: _now)['c'],
        segment,
        reason: 'phân khúc nói khác vòng đời ở độ trễ $recency ngày — hai con '
            'số cạnh nhau trên cùng một màn sẽ mâu thuẫn',
      );
    }
  });

  test('§3 VIP là phân vị của tệp, không phải mốc tiền cố định', () {
    final profiles = [
      for (var i = 0; i < 9; i++)
        _rfm('nho$i', recencyDays: 5, frequency: 4, monetary: 1000000,
            medianGapDays: 20, firstOrderDaysAgo: 300),
      _rfm('to', recencyDays: 5, frequency: 4, monetary: 90000000,
          medianGapDays: 20, firstOrderDaysAgo: 300),
    ];

    final segments = customerSegmentsFrom(profiles: profiles, now: _now);
    expect(segments['to'], CustomerSegment.vip);
    expect(segments['nho0'], CustomerSegment.loyal);
  });

  test('§3b người chưa mua KHÔNG được kéo mốc VIP xuống', () {
    // 20 liên hệ chưa mua + 2 người mua bằng nhau. Nếu phân vị tính cả người
    // chưa mua (chi 0), mốc 80% rơi xuống 0 và cả hai đều thành VIP.
    final segments = customerSegmentsFrom(
      profiles: [
        for (var i = 0; i < 20; i++) CustomerRfm.noOrders('trong$i'),
        _rfm('a', recencyDays: 5, frequency: 4, monetary: 5000000,
            medianGapDays: 20, firstOrderDaysAgo: 300),
        _rfm('b', recencyDays: 5, frequency: 4, monetary: 5000000,
            medianGapDays: 20, firstOrderDaysAgo: 300),
      ],
      now: _now,
    );

    expect(
      segments.values.where((s) => s == CustomerSegment.vip).length,
      lessThan(2),
      reason: 'hai khách chi tiêu y hệt nhau mà cả hai đều VIP nghĩa là mốc đã '
          'bị nhóm chưa mua kéo xuống 0',
    );
  });

  group('mới mua một lần', () {
    test('đơn đầu trong 30 ngày ⇒ khách mới', () {
      final segments = customerSegmentsFrom(
        profiles: [
          _rfm('c', recencyDays: 3, frequency: 1, monetary: 500000,
              firstOrderDaysAgo: 3),
        ],
        now: _now,
      );
      expect(segments['c'], CustomerSegment.newcomer);
    });

    test('mua một lần nhưng đã lâu ⇒ mua một lần, KHÔNG phải khách mới', () {
      // Vẫn "active" theo cửa sổ cố định (không có nhịp để so), nhưng đơn đầu
      // đã 25 ngày… lấy 29 để nằm trong active mà ngoài "mới" thì không được;
      // dùng đơn đầu 100 ngày và đơn duy nhất cách đây 20 ngày.
      final segments = customerSegmentsFrom(
        profiles: [
          _rfm('c', recencyDays: 20, frequency: 1, monetary: 500000,
              firstOrderDaysAgo: 100),
        ],
        now: _now,
      );
      expect(segments['c'], CustomerSegment.oneTime);
    });
  });

  test('bảng đếm chỉ đếm người đã mua', () {
    final tally = customerSegmentTally(
      profiles: [
        const CustomerRfm.noOrders('x'),
        const CustomerRfm.noOrders('y'),
        _rfm('c', recencyDays: 3, frequency: 1, monetary: 500000,
            firstOrderDaysAgo: 3),
      ],
      now: _now,
    );

    expect(tally.values.fold(0, (a, b) => a + b), 1);
  });
}
