// Một nguồn duy nhất cho mọi con số phân khúc — WTM-419 bước 1.
//
// ## Lỗi có thật mà cổng này canh
//
// Dogfood Nokia 2026-08-15 (build +17): trên **cùng một màn hình**, ô tóm tắt
// hiện `VIP: 0` còn chip ngay dưới hiện `Khách VIP (8)`; `Mới: 4` đứng cạnh
// `Khách mới (14)`. **2863 test xanh** — vì không test nào hỏi *"hai con số
// này có nói cùng một chuyện không"*.
//
// Ba nguồn đội chung một cái nhãn: một trường xếp hạng không ai ghi · một phép
// đếm `orderCount == 0` gắn nhãn "Mới" (thật ra là CHƯA MUA, gần như ngược
// nghĩa) · và nhãn lưu sẵn từ file nhập.
//
// Nên §1 dưới đây không kiểm một con số cụ thể — nó kiểm **quan hệ** giữa các
// con số, thứ duy nhất mà lỗi kia phá vỡ.
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/analytics/customer_segment_view.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_segment.dart';

final _now = DateTime(2026, 8, 15);

Customer _customer(String id) => Customer(
  id: id,
  name: 'Khách $id',
  phone: '',
  location: '',
  orderCount: 0,
  totalSpent: 0,
  lastPurchaseDate: null,
);

CustomerRfm _buyer(
  String id, {
  required int recencyDays,
  required int frequency,
  double monetary = 1000000,
  double? medianGapDays = 20,
  int firstOrderDaysAgo = 300,
}) => CustomerRfm(
  customerId: id,
  recencyDays: recencyDays,
  frequency: frequency,
  monetary: monetary,
  firstOrderAt: _now.subtract(Duration(days: firstOrderDaysAgo)),
  lastOrderAt: _now.subtract(Duration(days: recencyDays)),
  medianGapDays: medianGapDays,
  ordersInWindow: frequency,
);

void main() {
  test(
    '§1 ⭐ mọi khách được đếm ĐÚNG MỘT LẦN: segmented + chưa mua == tổng',
    () {
      // Bất biến ADR-TON-015 ở màn này. Lệch ⇒ có khách rơi khỏi mọi cách đếm,
      // hoặc bị đếm hai lần bởi hai nguồn khác nhau — đúng thứ đã xảy ra thật.
      final view = CustomerSegmentView.derive(
        customers: [for (var i = 0; i < 10; i++) _customer('c$i')],
        profiles: [
          for (var i = 0; i < 6; i++)
            _buyer('c$i', recencyDays: 5, frequency: 4),
          for (var i = 6; i < 10; i++) CustomerRfm.noOrders('c$i'),
        ],
        now: _now,
      );

      expect(view.total, 10);
      expect(view.segmented, 6);
      expect(view.notPurchased, 4);
      expect(
        view.segmented + view.notPurchased,
        view.total,
        reason: 'có khách không nằm trong cách đếm nào, hoặc nằm trong hai',
      );
    },
  );

  test('§2 "đang hoạt động" là TỔNG của chính các phân khúc đang hoạt động', () {
    // Trước đây con số này dùng cửa sổ cố định 90 ngày trong khi phân khúc dùng
    // nhịp riêng của từng khách — hai cách ấy bất đồng ở mọi khách mua theo quý.
    final view = CustomerSegmentView.derive(
      customers: [for (var i = 0; i < 4; i++) _customer('c$i')],
      profiles: [
        _buyer('c0', recencyDays: 5, frequency: 4), // loyal/vip
        _buyer('c1', recencyDays: 5, frequency: 2), // returning
        _buyer('c2', recencyDays: 25, frequency: 4), // slowing
        _buyer('c3', recencyDays: 200, frequency: 4), // churned
      ],
      now: _now,
    );

    final activeFromTally =
        view.of(CustomerSegment.newcomer) +
        view.of(CustomerSegment.oneTime) +
        view.of(CustomerSegment.returning) +
        view.of(CustomerSegment.loyal) +
        view.of(CustomerSegment.vip);

    expect(view.active, activeFromTally);
    expect(view.active, 2, reason: 'c0 và c1 còn trong nhịp; c2/c3 thì không');
  });

  test('§3 khách chưa mua KHÔNG rơi vào phân khúc nào', () {
    final view = CustomerSegmentView.derive(
      customers: [_customer('a'), _customer('b')],
      profiles: const [CustomerRfm.noOrders('a'), CustomerRfm.noOrders('b')],
      now: _now,
    );

    expect(view.tally, isEmpty);
    expect(view.notPurchased, 2);
    expect(
      view.of(CustomerSegment.newcomer),
      0,
      reason:
          'liên hệ chưa từng mua bị đếm thành "khách mới" là thổi phồng '
          'đúng con số người bán dùng để tự đánh giá',
    );
  });

  test('§3b nhãn người bán TỰ ĐẶT được giữ, nhãn trùng phân khúc thì không', () {
    // Cổng `count_list_contract_test` bắt bản đầu của tôi xoá sạch nhãn tự đặt.
    // "bán sỉ" không mâu thuẫn với RFM — nó trả lời một câu hỏi khác.
    final view = CustomerSegmentView.derive(
      customers: [
        Customer(
          id: 'a',
          name: 'A',
          phone: '',
          location: '',
          orderCount: 0,
          totalSpent: 0,
          lastPurchaseDate: null,
          segments: const ['bán sỉ', 'vip'],
        ),
      ],
      profiles: [_buyer('a', recencyDays: 5, frequency: 4)],
      now: _now,
    );

    expect(view.customLabels['bán sỉ'], 1);
    expect(
      view.customLabels.containsKey('vip'),
      isFalse,
      reason:
          'nhãn trùng tên phân khúc canonical CHÍNH LÀ chỗ sinh mâu thuẫn '
          '— nó phải nhường cho phép suy từ đơn thật',
    );
  });

  test('§4 không đọc được đơn hàng ⇒ KHÔNG rơi về nhãn lưu sẵn', () {
    // Quay lại nguồn cũ chính là quay lại mâu thuẫn. `unknown` rỗng, và màn
    // nói ra là chưa biết.
    expect(CustomerSegmentView.unknown.isEmpty, isTrue);
    expect(CustomerSegmentView.unknown.segmented, 0);
    expect(CustomerSegmentView.unknown.notPurchased, 0);
  });
}
