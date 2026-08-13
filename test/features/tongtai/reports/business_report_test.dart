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
      // WTM-393: categories group by canonical code (English inputs heal on read).
      expect(cats.map((c) => c.category), [
        'home_appliances',
        'fashion',
        'electronics',
      ]);
      expect(cats.map((c) => c.revenue), [1970000, 1240000, 848000]);
      expect(cats.fold<double>(0, (s, c) => s + c.revenue), report.revenueYtd);
    });

    test('top products are ordered by YTD revenue, capped at 5 (WTM-97)', () {
      final products = report.topProducts;
      expect(products, hasLength(5));
      expect(products.map((p) => p.name), [
        'Nồi chiên không dầu',
        'Váy linen',
        'Tai nghe bluetooth',
        'Bộ dao nhà bếp',
        'Áo thun cotton',
      ]);
      expect(products.map((p) => p.revenue), [
        1250000,
        700000,
        420000,
        390000,
        360000,
      ]);
      // Units sold aggregate per product (Váy linen: 2, Áo thun: 3).
      expect(products.firstWhere((p) => p.name == 'Váy linen').quantity, 2);
      expect(
        products.firstWhere((p) => p.name == 'Áo thun cotton').quantity,
        3,
      );
    });

    test('top customers are ordered by YTD spend with names (WTM-97)', () {
      final customers = report.topCustomers;
      // Three customers have billable orders this year.
      expect(customers.map((c) => c.name), [
        'Thu Hà', // c10
        'Phương Nguyễn', // c01
        'Bảo Lê', // c07
      ]);
      expect(customers.map((c) => c.spend), [2940000, 788000, 330000]);
      expect(customers.first.orders, 4); // Thu Hà's billable orders
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

  group('ReportPeriod.range (WTM-115)', () {
    test('this month spans the whole calendar month', () {
      final (start, end) = ReportPeriod.thisMonth.range(DateTime(2026, 7, 24));
      expect(start, DateTime(2026, 7, 1));
      expect(end.year, 2026);
      expect(end.month, 7);
      expect(end.day, 31);
    });

    test('December this-month does not overflow the year', () {
      final (start, end) = ReportPeriod.thisMonth.range(DateTime(2026, 12, 10));
      expect(start, DateTime(2026, 12, 1));
      expect(end.month, 12);
      expect(end.day, 31);
    });

    test('this quarter spans its three months', () {
      final (start, end) = ReportPeriod.thisQuarter.range(
        DateTime(2026, 7, 24),
      );
      expect(start, DateTime(2026, 7, 1)); // Q3 starts in July
      expect(end.month, 9);
      expect(end.day, 30);
    });

    test('quarter start snaps back for a mid-quarter month', () {
      final (start, _) = ReportPeriod.thisQuarter.range(DateTime(2026, 2, 15));
      expect(start, DateTime(2026, 1, 1)); // Q1
    });

    test('this year spans the calendar year', () {
      final (start, end) = ReportPeriod.thisYear.range(DateTime(2026, 7, 24));
      expect(start, DateTime(2026, 1, 1));
      expect(end.month, 12);
      expect(end.day, 31);
    });
  });

  group('ReportsService.breakdownFor period scoping (WTM-115)', () {
    final now = DateTime(2026, 7, 24);
    final service = ReportsService([
      order('lastyear', DateTime(2025, 11, 10), OrderStatus.delivered, [
        item('Home', 1, 900000),
      ]),
      order('q2', DateTime(2026, 5, 10), OrderStatus.delivered, [
        item('Home', 1, 300000),
      ]),
      order('jul1', DateTime(2026, 7, 5), OrderStatus.delivered, [
        item('Fashion', 1, 500000),
      ]),
      order('jul2', DateTime(2026, 7, 20), OrderStatus.delivered, [
        item('Electronics', 1, 200000),
      ]),
      order('void', DateTime(2026, 7, 6), OrderStatus.cancelled, [
        item('Home', 1, 999000),
      ]),
    ]);

    test('this month = July billable only (cancelled excluded)', () {
      final b = service.breakdownFor(now, ReportPeriod.thisMonth);
      expect(b.revenue, 700000);
      expect(b.orders, 2);
      expect(b.topCategories.map((c) => c.category), [
        'fashion',
        'electronics',
      ]);
      expect(b.hasSales, isTrue);
    });

    test('this quarter (Q3) matches July here — Q2 May order excluded', () {
      final b = service.breakdownFor(now, ReportPeriod.thisQuarter);
      expect(b.revenue, 700000);
      expect(b.orders, 2);
    });

    test('this year adds the Q2 order, still no last-year order', () {
      final b = service.breakdownFor(now, ReportPeriod.thisYear);
      expect(b.revenue, 1000000); // 300k (Home) + 500k (Fashion) + 200k (Elec)
      expect(b.orders, 3);
      // Fashion (500k) leads this year; Home is only 300k here.
      expect(b.topCategories.first.category, 'fashion');
      expect(b.topCategories.map((c) => c.category), [
        'fashion',
        'home_appliances',
        'electronics',
      ]);
    });

    test('all time adds the 2025 order', () {
      final b = service.breakdownFor(now, ReportPeriod.allTime);
      expect(b.revenue, 1900000); // + 900k from Nov 2025
      expect(b.orders, 4);
      // Home now leads with 1.2M (300k + 900k).
      expect(b.topCategories.first.category, 'home_appliances');
      expect(b.topCategories.first.revenue, 1200000);
    });

    test('empty book yields the empty breakdown', () {
      final b = ReportsService([]).breakdownFor(now, ReportPeriod.thisYear);
      expect(b.hasSales, isFalse);
      expect(b.revenue, 0);
      expect(b.topCategories, isEmpty);
    });
  });
}
