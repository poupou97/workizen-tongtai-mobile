import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/week_bucket.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/predictive/weekly_review_rule.dart';

/// **Weekly Review Rule Twin** — WTM-376 (Epic WTM-179).
///
/// Ba câu twin phải phân biệt được, và chúng là ba câu KHÁC nhau:
///
/// 1. *"chưa xét được"* — chưa có gì trong cả cửa sổ;
/// 2. *"tuần rồi không bán được gì"* — một câu trả lời **thật**;
/// 3. *"tuần rồi bán được X"*.
///
/// Câu 2 là câu dễ mất nhất: gộp nó vào câu 1 là giấu mất đúng tin người bán
/// cần nghe (Testing Bible P-03).
void main() {
  // Thứ Hai 2026-08-03 · thứ Hai 2026-08-10 · "bây giờ" = thứ Tư 2026-08-12,
  // nên **tuần hoàn chỉnh gần nhất** là tuần bắt đầu 2026-08-03.
  final now = DateTime(2026, 8, 12, 14, 30);

  CustomerOrder order({
    required String id,
    required DateTime date,
    required double amount,
    String customerId = 'c1',
    String product = 'Quạt mini',
    int quantity = 1,
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: id,
    date: date,
    status: status,
    items: [
      OrderItem(
        productId: 'p-$product',
        productName: product,
        sku: 'SKU-$product',
        category: 'Điện gia dụng',
        unit: 'cái',
        quantity: quantity,
        unitPrice: amount / quantity,
      ),
    ],
  );

  group('lưới tuần', () {
    test('tuần bắt đầu THỨ HAI — cuối tuần không bị cắt đôi', () {
      // Thứ Bảy 8/8 và Chủ nhật 9/8 phải cùng một tuần với thứ Hai 3/8.
      final monday = WeekKey.of(DateTime(2026, 8, 3));
      expect(WeekKey.of(DateTime(2026, 8, 8, 23, 59)), monday);
      expect(WeekKey.of(DateTime(2026, 8, 9, 0, 1)), monday);
      // Nhưng thứ Hai kế tiếp thì sang tuần khác.
      expect(WeekKey.of(DateTime(2026, 8, 10)), isNot(monday));
      expect(monday.sunday, DateTime(2026, 8, 9));
      expect(monday.endExclusive, DateTime(2026, 8, 10));
    });

    test('cửa sổ loại tuần đang chạy và xếp cũ → mới', () {
      final window = weekWindow(now: now, weeks: 3);
      expect(window.map((w) => w.monday.day), [20, 27, 3]);
      expect(window.last, WeekKey.of(DateTime(2026, 8, 3)));
      // Tuần đang chạy (10/8) KHÔNG nằm trong cửa sổ phân tích.
      expect(window.contains(WeekKey.of(now)), isFalse);
    });

    test('bật cờ thì tuần đang chạy vào cửa sổ', () {
      final window = weekWindow(now: now, weeks: 2, excludeCurrentWeek: false);
      expect(window.last, WeekKey.of(now));
    });

    test('cửa sổ ≤ 0 tuần là rỗng, không phải ngoại lệ', () {
      expect(weekWindow(now: now, weeks: 0), isEmpty);
      expect(weekWindow(now: now, weeks: -3), isEmpty);
    });

    test('bước tuần qua ranh giới năm vẫn liên tục', () {
      final lastOf2026 = WeekKey.of(DateTime(2026, 12, 30));
      expect(lastOf2026.addWeeks(1).weeksSince(lastOf2026), 1);
      expect(lastOf2026.addWeeks(1).monday.year, 2027);
    });

    test('giờ UTC được quy về giờ địa phương trước khi chia', () {
      final local = DateTime(2026, 8, 3, 0, 30);
      expect(WeekKey.of(local.toUtc()), WeekKey.of(local));
    });
  });

  group('⛔ chưa xét được ≠ không bán được gì', () {
    test('không đơn nào trong cả cửa sổ ⇒ insufficient, result null', () {
      final out = const WeeklyReviewRule().evaluate(orders: [], now: now);
      expect(out.sufficiency, DataSufficiency.insufficient);
      expect(out.result, isNull);
      expect(out.confidence, ForecastConfidence.none);
      expect(out.reasonCodes, contains(ReasonCode.noRevenueYet));
    });

    test('⭐ tuần rồi trống nhưng tuần trước có bán ⇒ TRẢ LỜI, không phải '
        '"chưa xét được"', () {
      // Bán ở tuần 27/7, im lặng ở tuần 3/8 — đó là tin xấu THẬT, và người bán
      // phải nghe nó thay vì thấy màn "chưa đủ dữ liệu".
      final out = const WeeklyReviewRule().evaluate(
        orders: [order(id: 'o1', date: DateTime(2026, 7, 29), amount: 500000)],
        now: now,
      );
      expect(out.sufficiency, DataSufficiency.sufficient);
      expect(out.result, isNotNull);
      expect(out.result!.week.isEmpty, isTrue);
      expect(out.result!.week.orderCount, 0);
      expect(out.result!.trend, WeeklyTrend.down);
      expect(out.reasonCodes, contains(ReasonCode.noRevenueYet));
    });
  });

  group('tổng kết tuần', () {
    final orders = [
      // Tuần trước: 3/8 → 9/8 (tuần được tổng kết).
      order(id: 'a1', date: DateTime(2026, 8, 3), amount: 300000),
      order(
        id: 'a2',
        date: DateTime(2026, 8, 9, 22),
        amount: 900000,
        customerId: 'c2',
        product: 'Nồi chiên',
        quantity: 3,
      ),
      // Tuần trước nữa: 27/7 → 2/8.
      order(id: 'b1', date: DateTime(2026, 7, 28), amount: 400000),
      // Tuần ĐANG CHẠY — phải bị loại khỏi con số.
      order(id: 'c1', date: DateTime(2026, 8, 11), amount: 9999999),
      // Đơn huỷ — không tính tiền.
      order(
        id: 'x1',
        date: DateTime(2026, 8, 4),
        amount: 5000000,
        status: OrderStatus.cancelled,
      ),
    ];

    test('chỉ đếm tuần hoàn chỉnh, đơn huỷ không tính', () {
      final out = const WeeklyReviewRule().evaluate(orders: orders, now: now);
      final review = out.result!;
      expect(review.week.week, WeekKey.of(DateTime(2026, 8, 3)));
      expect(review.week.revenue, 1200000);
      expect(review.week.orderCount, 2);
      expect(review.week.customerCount, 2);
      // 9,999,999 của tuần đang chạy không lọt vào bất kỳ điểm nào.
      expect(
        review.history.every((p) => p.revenue < 9999999),
        isTrue,
        reason: 'tuần đang chạy phải bị loại',
      );
      expect(out.reasonCodes, contains(ReasonCode.partialWeekExcluded));
    });

    test('so với tuần trước, và xu hướng vượt dải nhiễu', () {
      final out = const WeeklyReviewRule().evaluate(orders: orders, now: now);
      final review = out.result!;
      expect(review.previous!.revenue, 400000);
      expect(review.revenueChange, closeTo(2.0, 0.001));
      expect(review.ordersChange, closeTo(1.0, 0.001));
      expect(review.trend, WeeklyTrend.up);
    });

    test('nhúc nhích trong dải nhiễu là ĐI NGANG, không phải tăng', () {
      final out = const WeeklyReviewRule().evaluate(
        orders: [
          order(id: 'p', date: DateTime(2026, 7, 28), amount: 1000000),
          order(id: 'q', date: DateTime(2026, 8, 4), amount: 1050000),
        ],
        now: now,
      );
      expect(out.result!.revenueChange, closeTo(0.05, 0.001));
      expect(out.result!.trend, WeeklyTrend.flat);
    });

    test('mọi tuần trong cửa sổ đều có một điểm, tuần trống là số 0', () {
      final out = const WeeklyReviewRule().evaluate(orders: orders, now: now);
      expect(out.result!.history, hasLength(kWeeklyReviewWindowWeeks));
      expect(out.result!.history.first.isEmpty, isTrue);
      expect(out.result!.history.first.revenue, 0);
    });

    test('⛔ không có gì để so ⇒ KHÔNG vẽ 0 %', () {
      // Một tuần duy nhất trong cửa sổ: `previous` là null, và phần trăm phải
      // là null chứ không phải 0 — "không so được" khác "không đổi".
      final out = const WeeklyReviewRule(windowWeeks: 1).evaluate(
        orders: [order(id: 'o', date: DateTime(2026, 8, 4), amount: 700000)],
        now: now,
      );
      expect(out.result!.previous, isNull);
      expect(out.result!.revenueChange, isNull);
      expect(out.result!.ordersChange, isNull);
      expect(out.result!.trend, WeeklyTrend.flat);
      expect(out.sufficiency, DataSufficiency.partial);
    });

    test('⛔ tuần trước bằng 0 ⇒ phần trăm là null, không phải vô cực', () {
      final out = const WeeklyReviewRule(windowWeeks: 2).evaluate(
        orders: [order(id: 'o', date: DateTime(2026, 8, 4), amount: 700000)],
        now: now,
      );
      expect(out.result!.previous!.revenue, 0);
      expect(out.result!.revenueChange, isNull);
      expect(out.result!.trend, WeeklyTrend.flat);
    });
  });

  group('hàng bán chạy — theo TIỀN, không theo số lượng', () {
    test('200 túi nilon không thắng 2 nồi chiên', () {
      final out = const WeeklyReviewRule().evaluate(
        orders: [
          order(
            id: 'n',
            date: DateTime(2026, 8, 4),
            amount: 200000,
            product: 'Túi nilon',
            quantity: 200,
          ),
          order(
            id: 'm',
            date: DateTime(2026, 8, 5),
            amount: 3000000,
            product: 'Nồi chiên',
            quantity: 2,
          ),
        ],
        now: now,
      );
      expect(out.result!.week.topProduct!.name, 'Nồi chiên');
      expect(out.result!.week.topProduct!.revenue, 3000000);
      expect(out.result!.week.topProduct!.quantity, 2);
    });

    test('tuần trống không có hàng bán chạy', () {
      final out = const WeeklyReviewRule().evaluate(
        orders: [order(id: 'o', date: DateTime(2026, 7, 28), amount: 100000)],
        now: now,
      );
      expect(out.result!.week.topProduct, isNull);
    });
  });

  group('hợp đồng Rule Twin', () {
    test('chạy được KHÔNG cần AI, mạng hay khoá — và lặp lại y hệt', () {
      final rule = const WeeklyReviewRule();
      final orders = [
        order(id: 'o1', date: DateTime(2026, 8, 4), amount: 250000),
        order(id: 'o2', date: DateTime(2026, 7, 30), amount: 100000),
      ];
      final first = rule.evaluate(orders: orders, now: now);
      final second = rule.evaluate(orders: orders.reversed.toList(), now: now);
      expect(second.result!.week, first.result!.week);
      expect(second.reasonCodes, first.reasonCodes);
      expect(first.version, kWeeklyReviewRuleVersion);
    });

    test('provenance không mang tiền hay tên khách', () {
      final out = const WeeklyReviewRule().evaluate(
        orders: [
          order(
            id: 'o',
            date: DateTime(2026, 8, 4),
            amount: 1234567,
            customerId: 'chi-Lan',
          ),
        ],
        now: now,
      );
      expect(out.provenance, contains(kWeeklyReviewRuleVersion));
      expect(out.provenance, isNot(contains('1234567')));
      expect(out.provenance, isNot(contains('chi-Lan')));
    });

    test('độ tin cậy đo SỐ TUẦN NHÌN ĐƯỢC, không đo tin tốt hay xấu', () {
      List<CustomerOrder> activeWeeks(int n) => [
        for (var i = 0; i < n; i++)
          order(
            id: 'o$i',
            date: DateTime(2026, 8, 4).subtract(Duration(days: 7 * i)),
            amount: 100000,
          ),
      ];
      final rule = const WeeklyReviewRule();
      expect(
        rule.evaluate(orders: activeWeeks(1), now: now).confidence,
        ForecastConfidence.low,
      );
      expect(
        rule.evaluate(orders: activeWeeks(2), now: now).confidence,
        ForecastConfidence.medium,
      );
      expect(
        rule.evaluate(orders: activeWeeks(4), now: now).confidence,
        ForecastConfidence.high,
      );
    });
  });
}
