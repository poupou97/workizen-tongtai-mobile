import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/reports/business_report.dart';

/// WTM-95/96 — the Reports aggregator turns orders into dashboard figures.
///
/// The sample fixtures ([kSampleCustomerOrders]) are fixed and dated, so with
/// an injected `now` every KPI is an exact number, not a range.
void main() {
  // "Today" for the sample-data assertions: July 2026, matching the newest
  // sample orders (o01 Jul 10, o05 Jul 13).
  final now = DateTime(2026, 7, 24);

  CustomerOrder order(
    String id,
    DateTime date,
    OrderStatus status,
    List<OrderItem> items,
  ) => CustomerOrder(
    id: id,
    customerId: 'c',
    orderNumber: id,
    date: date,
    status: status,
    items: items,
  );

  OrderItem item(String category, int qty, double price) => OrderItem(
    productName: '$category-$qty',
    category: category,
    quantity: qty,
    unitPrice: price,
  );

  group('ReportsService over the sample orders', () {
    final report = ReportsService.sample().reportAsOf(now);

    test('MTD revenue sums only this calendar month, billable orders', () {
      // July 2026: o01 (428.000) + o05 (420.000).
      expect(report.revenueMtd, 848000);
      expect(report.ordersMtd, 2);
    });

    test('YTD revenue sums the year and excludes the cancelled order', () {
      // All 2026 billable orders; o03 (Mar, cancelled) is dropped.
      expect(report.revenueYtd, 4058000);
      expect(report.ordersYtd, 7);
    });

    test('average order value is YTD revenue over YTD billable orders', () {
      expect(report.averageOrderValue, closeTo(4058000 / 7, 0.001));
    });

    test('has sales, so the dashboard renders (not the empty state)', () {
      expect(report.hasSales, isTrue);
    });

    test('monthly trend is the trailing six months, oldest first', () {
      final months = report.monthlyRevenue;
      expect(months, hasLength(6));
      expect(months.map((m) => '${m.year}-${m.month}'), [
        '2026-2',
        '2026-3',
        '2026-4',
        '2026-5',
        '2026-6',
        '2026-7',
      ]);
      // Feb=o08, Mar=cancelled→0, Apr=o07, May=o02, Jun=o04+o06, Jul=o01+o05.
      expect(months.map((m) => m.revenue), [
        390000,
        0,
        1250000,
        360000,
        1210000,
        848000,
      ]);
    });

    test('peak monthly revenue is April (the nồi chiên order)', () {
      expect(report.peakMonthlyRevenue, 1250000);
    });

    test('top categories are ordered by YTD revenue and sum to YTD', () {
      final cats = report.topCategories;
      expect(cats.map((c) => c.category), ['Home', 'Fashion', 'Electronics']);
      expect(cats.map((c) => c.revenue), [1970000, 1240000, 848000]);
      expect(cats.fold<double>(0, (s, c) => s + c.revenue), report.revenueYtd);
    });
  });

  group('ReportsService edge cases', () {
    test('an empty order book yields the empty-state report', () {
      final report = ReportsService([]).reportAsOf(now);
      expect(report.hasSales, isFalse);
      expect(report.revenueMtd, 0);
      expect(report.revenueYtd, 0);
      expect(report.averageOrderValue, 0);
      expect(report.topCategories, isEmpty);
      // The trend window is still present, all zero.
      expect(report.monthlyRevenue, hasLength(6));
      expect(report.monthlyRevenue.every((m) => m.revenue == 0), isTrue);
      expect(report.peakMonthlyRevenue, 0);
    });

    test('the trend window crosses the year boundary correctly', () {
      final service = ReportsService([
        order('a', DateTime(2025, 12, 5), OrderStatus.delivered, [
          item('Home', 1, 100000),
        ]),
        order('b', DateTime(2026, 1, 9), OrderStatus.delivered, [
          item('Home', 1, 200000),
        ]),
      ], monthsBack: 3);

      final report = service.reportAsOf(DateTime(2026, 1, 20));
      // Nov 2025, Dec 2025, Jan 2026.
      expect(report.monthlyRevenue.map((m) => '${m.year}-${m.month}'), [
        '2025-11',
        '2025-12',
        '2026-1',
      ]);
      expect(report.monthlyRevenue.map((m) => m.revenue), [0, 100000, 200000]);
      // YTD is 2026 only — December 2025 is last year, excluded.
      expect(report.revenueYtd, 200000);
      expect(report.ordersYtd, 1);
    });

    test('cancelled orders never count toward any figure', () {
      final service = ReportsService([
        order('ok', DateTime(2026, 3, 1), OrderStatus.delivered, [
          item('Fashion', 1, 500000),
        ]),
        order('void', DateTime(2026, 3, 2), OrderStatus.cancelled, [
          item('Fashion', 1, 999000),
        ]),
      ]);

      final report = service.reportAsOf(DateTime(2026, 3, 15));
      expect(report.revenueMtd, 500000);
      expect(report.ordersMtd, 1);
      expect(report.topCategories.single.revenue, 500000);
    });
  });
}
