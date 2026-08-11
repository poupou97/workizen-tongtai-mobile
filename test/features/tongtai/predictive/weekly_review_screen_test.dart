import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/predictive/weekly_review_rule.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_predictive_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_weekly_review_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_screen_data.dart';

/// **Màn Tổng kết tuần** — WTM-377, qua dây nối THẬT.
///
/// Không mock ở tầng màn hình và không dựng twin bằng tay:
/// `weeklyReviewProvider` thật chạy `WeeklyReviewRule` thật trên
/// `orderRepositoryProvider` thật (bản in-memory của cùng interface mà Drift
/// hiện thực).
///
/// Đồng hồ được ghim qua `weeklyReviewClockProvider` — một suite tổng kết tuần
/// mà đọc đồng hồ thật sẽ hỏng vào đúng một thứ Hai nào đó, và một suite hỏng
/// theo lịch là suite không ai tin nữa.
///
/// ## Thứ suite này khoá
///
/// **Ba trạng thái là BA, không phải hai.** *"Chưa xét được"* (xám) và *"tuần
/// rồi không bán được gì"* (số 0 thật) là hai câu khác nhau. Trộn chúng là giấu
/// mất tin người bán cần nghe nhất (P-03).
///
/// **Không bịa phép so sánh.** Không có tuần trước ⇒ hiện chữ *"chưa có tuần
/// trước để so"*, và chênh lệch phải **xám** — vắng mặt hẳn con số 0 %.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Thứ Tư 2026-08-12 ⇒ tuần hoàn chỉnh gần nhất là 3/8 → 9/8.
  final now = DateTime(2026, 8, 12, 9);

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

  Widget host(List<CustomerOrder> orders, {String locale = 'vi'}) =>
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            InMemoryOrderRepository(orders),
          ),
          weeklyReviewClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: const TongtaiWeeklyReviewScreen(),
        ),
      );

  Future<void> pump(WidgetTester tester, Widget app) async {
    // Mặt phẳng cao để cả trang được dựng — hợp đồng nói về thứ người bán NHÌN
    // THẤY, và một khối chưa dựng sẽ làm phép đếm đúng vì lý do sai.
    tester.view.physicalSize = const Size(400 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  Future<RuleTwinResult<WeeklyReview>> twinOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(TongtaiWeeklyReviewScreen)),
      ).read(weeklyReviewProvider.future);

  group('⭐ ba trạng thái, và chúng KHÁC nhau', () {
    testWidgets('chưa có đơn nào ⇒ ô XÁM "chưa xét được", KHÔNG có con số', (
      tester,
    ) async {
      await pump(tester, host(const []));

      expect(find.byType(TongtaiInsufficientView), findsOneWidget);
      expect(
        find.byKey(const Key('weekly-review-insufficient')),
        findsOneWidget,
      );
      // Không có bảng số nào — một tuần toàn số 0 chính là kiểu bịa phải chặn.
      expect(find.byKey(const Key('weekly-review-metrics')), findsNothing);
      expect(find.byKey(const Key('weekly-review-nothing-sold')), findsNothing);
      expect((await twinOf(tester)).result, isNull);
    });

    testWidgets(
      '⭐ tuần rồi TRỐNG nhưng tuần trước có bán ⇒ số 0 THẬT, không phải ô xám',
      (tester) async {
        await pump(
          tester,
          host([order(id: 'o1', date: DateTime(2026, 7, 29), amount: 500000)]),
        );

        expect(find.byType(TongtaiInsufficientView), findsNothing);
        expect(
          find.byKey(const Key('weekly-review-nothing-sold')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('weekly-review-metrics')), findsOneWidget);
        expect(find.text('0'), findsWidgets);
      },
    );

    testWidgets('tuần rồi có bán ⇒ số thật + so sánh + hàng bán chạy', (
      tester,
    ) async {
      await pump(
        tester,
        host([
          order(
            id: 'a',
            date: DateTime(2026, 8, 4),
            amount: 900000,
            product: 'Nồi chiên',
            quantity: 3,
          ),
          order(id: 'b', date: DateTime(2026, 8, 6), amount: 300000),
          order(id: 'c', date: DateTime(2026, 7, 28), amount: 400000),
        ]),
      );

      expect(find.byType(TongtaiInsufficientView), findsNothing);
      expect(find.byKey(const Key('weekly-review-nothing-sold')), findsNothing);
      expect(
        find.byKey(const Key('weekly-review-top-product')),
        findsOneWidget,
      );
      expect(find.text('Nồi chiên'), findsOneWidget);
    });
  });

  group('⛔ màn không tính lại gì', () {
    testWidgets('con số hiện ra ĐÚNG BẰNG con số twin trả về', (tester) async {
      final orders = [
        order(id: 'a', date: DateTime(2026, 8, 4), amount: 900000),
        order(
          id: 'b',
          date: DateTime(2026, 8, 6),
          amount: 300000,
          customerId: 'c2',
        ),
        order(id: 'c', date: DateTime(2026, 7, 28), amount: 400000),
      ];
      await pump(tester, host(orders));
      final review = (await twinOf(tester)).result!;

      // Doanh thu, số đơn, số khách — đọc từ màn, so với twin, không tự cộng.
      expect(
        find.text(TongtaiFormatters.vndShort(review.week.revenue)),
        findsWidgets,
      );
      expect(find.text('${review.week.orderCount}'), findsWidgets);
      expect(find.text('${review.week.customerCount}'), findsWidgets);
      expect(review.week.revenue, 1200000);
    });

    testWidgets('mọi tuần trong cửa sổ đều có một dòng, tuần trống cũng thế', (
      tester,
    ) async {
      await pump(
        tester,
        host([order(id: 'a', date: DateTime(2026, 8, 4), amount: 900000)]),
      );
      final rows = find.byWidgetPredicate((w) {
        final key = w.key;
        return key is ValueKey<String> &&
            key.value.startsWith('weekly-review-week-');
      });
      expect(rows, findsNWidgets(kWeeklyReviewWindowWeeks));
    });
  });

  group('⛔ không có tuần trước thì KHÔNG vẽ 0 %', () {
    testWidgets('hiện đúng câu "chưa có tuần trước để so"', (tester) async {
      // Chỉ một tuần có đơn, và nó là tuần đầu tiên của cửa sổ ⇒ tuần trước
      // bằng 0 ⇒ phần trăm không xác định.
      await pump(
        tester,
        host([order(id: 'a', date: DateTime(2026, 8, 4), amount: 900000)]),
      );
      final review = (await twinOf(tester)).result!;
      expect(review.revenueChange, isNull);

      expect(find.textContaining('Chưa có tuần trước'), findsWidgets);
      // Vắng mặt hẳn — 0 % là một phép so sánh KHÔNG tồn tại.
      expect(find.textContaining('0%'), findsNothing);
      expect(find.textContaining('+0%'), findsNothing);
    });

    testWidgets('chênh lệch chưa biết chiều hiện XÁM, không xanh', (
      tester,
    ) async {
      await pump(
        tester,
        host([order(id: 'a', date: DateTime(2026, 8, 4), amount: 900000)]),
      );
      final metric = tester
          .widgetList<TtMetric>(find.byType(TtMetric))
          .firstWhere((m) => m.delta != null);
      expect(
        metric.deltaStatus,
        isNull,
        reason: 'chưa biết chiều thì không được mang màu của tin tốt',
      );
    });
  });

  testWidgets('lý do hiện nguyên văn mã của twin, đúng locale', (tester) async {
    await pump(
      tester,
      host([
        order(id: 'a', date: DateTime(2026, 8, 4), amount: 900000),
        order(id: 'b', date: DateTime(2026, 7, 28), amount: 400000),
      ]),
    );
    final twin = await twinOf(tester);
    expect(twin.reasonCodes, contains(ReasonCode.partialWeekExcluded));
    for (final reason in twin.reasonCodes) {
      expect(find.text(reason.labelVi), findsWidgets, reason: reason.code);
    }
    // ⛔ Mã của THÁNG không được lọt vào bản tổng kết TUẦN.
    expect(find.text(ReasonCode.partialMonthExcluded.labelVi), findsNothing);
  });
}
