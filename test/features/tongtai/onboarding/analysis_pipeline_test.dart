import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/onboarding/analysis_pipeline.dart';
import 'package:tongtai/features/tongtai/onboarding/first_insight_input.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-353 (S4) — tiến trình phân tích phải là **công việc thật**.
///
/// Governance ở cuối file quét chính mã nguồn: một `Future.delayed` lọt vào
/// pipeline là cách màn onboarding biến thành sân khấu, và không test hành vi
/// nào bắt được nó (một độ trễ giả vẫn cho đúng số đếm).
void main() {
  final now = DateTime(2026, 8, 11, 9);

  Product product(String id, {int? quantity, int? reorderLevel}) => Product(
    id: id,
    sku: id.toUpperCase(),
    name: 'Hàng $id',
    category: 'test',
    pricePerUnit: 100000,
    costPrice: 60000,
    quantity: quantity,
    reorderLevel: reorderLevel,
    updatedAt: now,
  );

  CustomerOrder order(String id) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: id,
    date: now.subtract(const Duration(days: 2)),
    status: OrderStatus.delivered,
    items: [
      const OrderItem(
        productId: 'p1',
        productName: 'Hàng p1',
        sku: 'P1',
        category: 'test',
        quantity: 1,
        unitPrice: 100000,
      ),
    ],
  );

  Customer customer(String id) => Customer(
    id: id,
    name: 'Khách $id',
    phone: '090000000$id',
    location: 'Hà Nội',
    orderCount: 1,
    totalSpent: 100000,
    lastPurchaseDate: now.subtract(const Duration(days: 2)),
  );

  runPipeline(_FakeSource source) async {
    AnalysisRun? run;
    final seen = await AnalysisPipeline(
      source: source,
    ).run(now: now, onDone: (r) => run = r).toList();
    return (seen: seen, run: run);
  }

  group('mỗi dòng tiến trình mang số đếm THẬT', () {
    test('số đếm bằng đúng số bản ghi đã tải', () async {
      final source = _FakeSource(
        products: [product('p1'), product('p2'), product('p3')],
        orders: [order('o1'), order('o2')],
        customers: [customer('c1')],
        now: now,
      );

      final result = await runPipeline(source);

      expect(result.run, isNotNull);
      expect(result.run!.countOf(AnalysisStage.products), 3);
      expect(result.run!.countOf(AnalysisStage.orders), 2);
      expect(result.run!.countOf(AnalysisStage.customers), 1);
    });

    test('⭐ không dữ liệu ⇒ đếm 0, KHÔNG phải một con số đẹp', () async {
      // Đây là dòng chữ Founder không bao giờ được thấy: "đang phân tích 1.246
      // đơn hàng" trên một máy chưa có đơn nào.
      final result = await runPipeline(_FakeSource(now: now));

      for (final p in result.seen) {
        expect(p.count, 0, reason: '${p.stage.code} phát ra ${p.count}');
      }
    });

    test('chặng tồn kho gọi StockAlertService, không tự đếm', () async {
      // Ba mặt hàng, hai trong đó dưới mức đặt lại. Nếu chặng này đếm "số sản
      // phẩm" thì nó ra 3 — nó phải ra 2, tức là nó thật sự đã quét.
      final source = _FakeSource(
        products: [
          product('p1', quantity: 0, reorderLevel: 10),
          product('p2', quantity: 1, reorderLevel: 10),
          product('p3', quantity: 500, reorderLevel: 10),
        ],
        now: now,
      );

      final result = await runPipeline(source);

      expect(result.run!.countOf(AnalysisStage.stock), 2);
      expect(result.run!.countOf(AnalysisStage.products), 3);
    });

    test('chặng tín hiệu đếm đúng số phát hiện của engine', () async {
      final source = _FakeSource(
        products: [product('p1', quantity: 0, reorderLevel: 10)],
        now: now,
      );

      final result = await runPipeline(source);

      expect(
        result.run!.countOf(AnalysisStage.signals),
        result.run!.insight.findings.length,
      );
    });
  });

  group('thứ tự và tính đầy đủ', () {
    test('phát đúng năm chặng, đúng thứ tự', () async {
      final result = await runPipeline(_FakeSource(now: now));

      expect(result.seen.map((p) => p.stage), [
        AnalysisStage.products,
        AnalysisStage.orders,
        AnalysisStage.customers,
        AnalysisStage.stock,
        AnalysisStage.signals,
      ]);
    });

    test('mỗi chặng phát SAU khi việc của nó xong', () async {
      // Nguồn ghi lại thứ tự nó bị gọi. Nếu một dòng tiến trình được phát
      // trước lời gọi tải tương ứng thì con số đó không thể là thật.
      final source = _FakeSource(
        products: [product('p1')],
        orders: [order('o1')],
        customers: [customer('c1')],
        now: now,
      );

      await runPipeline(source);

      expect(source.calls, ['products', 'orders', 'customers', 'assemble']);
    });
  });

  group('⛔ governance · tiến trình không được là sân khấu', () {
    late String code;

    setUpAll(() {
      // Bỏ chú thích trước khi quét. Bản đầu của test này quên làm thế và ĐỎ
      // ngay — vì chính câu văn "không Future.delayed" trong doc comment. Vui,
      // nhưng nó cũng là bằng chứng bộ quét thật sự đọc file.
      code = File('lib/features/tongtai/onboarding/analysis_pipeline.dart')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
    });

    test('đọc được mã nguồn (chống PASS giả)', () {
      expect(code, contains('class AnalysisPipeline'));
      expect(code, contains('loadProducts'));
    });

    test('không Future.delayed trong pipeline', () {
      expect(
        code.contains('Future.delayed'),
        isFalse,
        reason:
            'một độ trễ giả vẫn cho ĐÚNG số đếm, nên không test hành vi nào '
            'bắt được nó — chỉ có quét mã nguồn',
      );
    });

    test('không Duration nào trong pipeline', () {
      // Kể cả `Duration.zero`: nó là chỗ để đặt một con số khác vào ngày mai.
      expect(code.contains('Duration('), isFalse);
      expect(code.contains('Duration.'), isFalse);
    });

    test('không hằng số đếm nào — mọi số đếm là `.length`', () {
      final counts = RegExp(
        r'step\(AnalysisStage\.\w+, ([^)]+)\)',
      ).allMatches(code).map((m) => m.group(1)!).toList();

      expect(counts, hasLength(5));
      for (final expr in counts) {
        expect(
          expr.endsWith('.length'),
          isTrue,
          reason: 'chặng phát ra "$expr" — không phải length của việc vừa làm',
        );
      }
    });
  });
}

class _FakeSource implements AnalysisSource {
  _FakeSource({
    required this.now,
    this.products = const [],
    this.orders = const [],
    this.customers = const [],
  });

  final DateTime now;
  final List<Product> products;
  final List<CustomerOrder> orders;
  final List<Customer> customers;

  final List<String> calls = [];

  @override
  Future<List<Product>> loadProducts() async {
    calls.add('products');
    return products;
  }

  @override
  Future<List<CustomerOrder>> loadOrders() async {
    calls.add('orders');
    return orders;
  }

  @override
  Future<List<Customer>> loadCustomers() async {
    calls.add('customers');
    return customers;
  }

  @override
  Future<FirstInsightInput> assemble({
    required DateTime now,
    required List<Product> products,
    required List<CustomerOrder> orders,
    required List<Customer> customers,
  }) async {
    calls.add('assemble');
    return FirstInsightInput(
      now: now,
      products: products,
      orders: orders,
      customers: customers,
      marketplaceOrdersWithoutFees: 0,
    );
  }
}
