import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_rule.dart';
import 'package:tongtai/features/tongtai/logistics/shipment.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_opportunity_service.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_profit.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/commerce/supplier_comparison.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/settlement.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/finance/true_profit.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-328 (lời thật sau phí) + WTM-329 (cơ hội + so sánh nhà cung cấp).
///
/// Phần cuối chạy trên **dataset thật đã nhập**, không phải trên vài bản ghi
/// dựng tay: câu hỏi của story là *"engine có tìm ra được gì từ 100 sản phẩm
/// không"*, và ba bản ghi không trả lời được câu đó.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 9, 12);

  Product product({
    required String id,
    double price = 259000,
    double? cost = 240000,
    int? quantity = 30,
    int? reorder = 10,
  }) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Sản phẩm $id',
    category: 'Điện tử',
    pricePerUnit: price,
    costPrice: cost,
    quantity: quantity,
    reorderLevel: reorder,
    updatedAt: now,
  );

  CustomerOrder order({
    required String id,
    required Product of,
    int quantity = 1,
    int daysAgo = 3,
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: id,
    date: now.subtract(Duration(days: daysAgo)),
    status: status,
    items: [
      OrderItem(
        productId: of.id,
        productName: of.name,
        sku: of.sku,
        category: of.category,
        quantity: quantity,
        unitPrice: of.pricePerUnit,
      ),
    ],
  );

  SettlementLine fee({
    required String orderId,
    required SettlementKind kind,
    required double amount,
  }) => SettlementLine(
    id: '$orderId-${kind.code}',
    orderId: orderId,
    kind: kind,
    direction: SettlementDirection.outbound,
    amount: amount,
    currency: 'VND',
    occurredAt: now,
    fundedBy: FundingSource.seller,
  );

  // ── C4 · lời thật ────────────────────────────────────────────────────────

  group('WTM-328 · lời thật sau phí', () {
    test('lãi gộp DƯƠNG mà lời thật ÂM — chuyện không ai nhìn thấy', () {
      final p = product(id: 'p1');
      final context = CommerceProfitContext.derive(
        products: [p],
        orders: [order(id: 'o1', of: p)],
        settlements: [
          fee(orderId: 'o1', kind: SettlementKind.commission, amount: 14245),
          fee(orderId: 'o1', kind: SettlementKind.platformFee, amount: 7252),
        ],
        now: now,
      );

      final entry = context.byProduct.single;
      // Người bán tính nhẩm: 259.000 − 240.000 = lãi 19.000.
      expect(entry.revenue - 240000, 19000);
      // Sự thật: 19.000 − 14.245 − 7.252 = −2.497.
      expect(entry.amount, closeTo(-2497, 1));
      expect(entry.isLosingAfterFees, isTrue);
      expect(entry.grossLooksFineButLoses(240000), isTrue);
    });

    test('chưa nhập giá vốn ⇒ TỪ CHỐI trả số, không coi bằng 0', () {
      final p = product(id: 'p1', cost: null);
      final context = CommerceProfitContext.derive(
        products: [p],
        orders: [order(id: 'o1', of: p)],
        settlements: const [],
        now: now,
      );

      // Coi vốn bằng 0 sẽ biến sản phẩm chưa nhập vốn thành sản phẩm siêu lời.
      expect(context.byProduct.single.profit, isA<ProfitInsufficient>());
      expect(context.byProduct.single.amount, isNull);
      expect(context.overall, isA<ProfitInsufficient>());
      expect(
        (context.overall as ProfitInsufficient).blockers,
        contains(ProfitBlocker.missingCost),
      );
    });

    test('đơn ĐÃ HUỶ không tính vào doanh thu', () {
      final p = product(id: 'p1');
      final context = CommerceProfitContext.derive(
        products: [p],
        orders: [
          order(id: 'o1', of: p),
          order(id: 'o2', of: p, status: OrderStatus.cancelled),
        ],
        settlements: const [],
        now: now,
      );

      expect(context.byProduct.single.orderCount, 1);
      expect(context.byProduct.single.revenue, 259000);
    });

    test('đơn ngoài kỳ 30 ngày không tính', () {
      final p = product(id: 'p1');
      final context = CommerceProfitContext.derive(
        products: [p],
        orders: [order(id: 'o1', of: p, daysAgo: 45)],
        settlements: const [],
        now: now,
      );

      expect(context.hasData, isFalse);
    });

    test('lỗ lên ĐẦU danh sách — người bán mở màn này để tìm chỗ chảy máu', () {
      final good = product(id: 'tot', price: 300000, cost: 100000);
      final bad = product(id: 'xau');
      final context = CommerceProfitContext.derive(
        products: [good, bad],
        orders: [
          order(id: 'o1', of: good),
          order(id: 'o2', of: bad),
        ],
        settlements: [
          fee(orderId: 'o2', kind: SettlementKind.commission, amount: 25000),
        ],
        now: now,
      );

      expect(context.byProduct.first.productId, 'xau');
      expect(context.losingAfterFees.single.productId, 'xau');
    });

    test('phí của đơn nhiều món phân bổ theo tỷ trọng doanh thu', () {
      final a = product(id: 'a', price: 300000, cost: 100000);
      final b = product(id: 'b', price: 100000, cost: 30000);
      final context = CommerceProfitContext.derive(
        products: [a, b],
        orders: [
          CustomerOrder(
            id: 'o1',
            customerId: 'c1',
            orderNumber: 'o1',
            date: now,
            status: OrderStatus.delivered,
            items: [
              OrderItem(
                productId: 'a',
                productName: 'a',
                sku: 'a',
                category: 'x',
                quantity: 1,
                unitPrice: 300000,
              ),
              OrderItem(
                productId: 'b',
                productName: 'b',
                sku: 'b',
                category: 'x',
                quantity: 1,
                unitPrice: 100000,
              ),
            ],
          ),
        ],
        settlements: [
          fee(orderId: 'o1', kind: SettlementKind.commission, amount: 40000),
        ],
        now: now,
      );

      final byId = {for (final p in context.byProduct) p.productId: p};
      // 300k/400k = 75% phí về món a, 25% về món b.
      expect(byId['a']!.amount, closeTo(300000 - 100000 - 30000, 1));
      expect(byId['b']!.amount, closeTo(100000 - 30000 - 10000, 1));
    });
  });

  // ── C5 · so sánh nhà cung cấp ────────────────────────────────────────────

  group('WTM-329 · so sánh nhà cung cấp', () {
    SupplierQuote quote({
      required String id,
      required double cost,
      int? leadTime,
      double? moq,
      double? rating,
    }) => SupplierQuote(
      id: id,
      productId: 'p1',
      supplierId: id,
      supplierName: 'Nguồn $id',
      unitCost: cost,
      quotedAt: now,
      leadTimeDays: leadTime,
      minimumOrderQuantity: moq,
      rating: rating,
    );

    test(
      'rẻ hơn 12% nhưng chậm hơn 6 ngày là ĐÁNH ĐỔI, không phải câu trả lời',
      () {
        final comparison = SupplierComparison.from(
          productId: 'p1',
          currentSupplierId: 'hien-tai',
          quotes: [
            quote(id: 'hien-tai', cost: 100000, leadTime: 7),
            quote(id: 're-hon', cost: 88000, leadTime: 13),
          ],
        );

        final option = comparison.alternatives.single;
        expect(option.savingRatio, closeTo(0.12, 0.001));
        expect(option.slowerByDays, 6);
        // Rẻ hơn nhưng chậm hơn ⇒ **không** phải "rõ ràng tốt hơn".
        expect(comparison.clearWin, isNull);
      },
    );

    test('rẻ hơn VÀ nhanh hơn mới là lựa chọn rõ ràng', () {
      final comparison = SupplierComparison.from(
        productId: 'p1',
        currentSupplierId: 'hien-tai',
        quotes: [
          quote(id: 'hien-tai', cost: 100000, leadTime: 20),
          quote(id: 'tot-hon', cost: 88000, leadTime: 14),
        ],
      );

      expect(comparison.clearWin!.quote.supplierId, 'tot-hon');
      expect(comparison.clearWin!.slowerByDays, -6);
    });

    test('THIẾU lead time ⇒ không đoán, và không được gọi là tốt hơn', () {
      final comparison = SupplierComparison.from(
        productId: 'p1',
        currentSupplierId: 'hien-tai',
        quotes: [
          quote(id: 'hien-tai', cost: 100000, leadTime: 20),
          quote(id: 'chua-biet', cost: 80000),
        ],
      );

      final option = comparison.alternatives.single;
      // Coi `null` là 0 sẽ biến một nguồn chưa ai hỏi thành "giao nhanh ngang".
      expect(option.slowerByDays, isNull);
      expect(option.unknowns, contains('lead_time'));
      expect(comparison.clearWin, isNull);
    });

    test('không có báo giá nào ⇒ không so sánh được, không nổ', () {
      final comparison = SupplierComparison.from(
        productId: 'p1',
        quotes: const [],
      );

      expect(comparison.current, isNull);
      expect(comparison.isComparable, isFalse);
    });

    test('tiết kiệm tính theo số đã bán thật', () {
      final comparison = SupplierComparison.from(
        productId: 'p1',
        currentSupplierId: 'hien-tai',
        quotes: [
          quote(id: 'hien-tai', cost: 100000, leadTime: 10),
          quote(id: 're-hon', cost: 88000, leadTime: 8),
        ],
      );

      expect(comparison.clearWin!.savingFor(60), 720000);
    });
  });

  // ── C5 · cơ hội, derive từ dữ liệu ───────────────────────────────────────

  group('WTM-329 · cơ hội suy ra từ dữ liệu (§16)', () {
    test('không có dữ liệu ⇒ KHÔNG có việc nào — không bịa ra thẻ', () {
      final items = const CommerceOpportunityService().derive(
        products: const [],
        profit: CommerceProfitContext.derive(
          orders: const [],
          products: const [],
          settlements: const [],
          now: now,
        ),
        quotes: const [],
        now: now,
      );

      expect(items, isEmpty);
    });

    test('sản phẩm lỗ sau phí ⇒ việc CẤP NHẤT, kèm giá đề xuất có số', () {
      final p = product(id: 'p1');
      final profit = CommerceProfitContext.derive(
        products: [p],
        orders: [order(id: 'o1', of: p)],
        settlements: [
          fee(orderId: 'o1', kind: SettlementKind.commission, amount: 21000),
        ],
        now: now,
      );

      final items = const CommerceOpportunityService().derive(
        products: [p],
        profit: profit,
        quotes: const [],
        now: now,
      );

      final loss = items.firstWhere((i) => i.kind == BriefKind.marginTooThin);
      expect(loss.severity, BriefSeverity.critical);
      expect(loss.headline, contains('nhìn thì có lãi'));

      // Đề xuất phải là một CON SỐ, không phải "anh xem lại giá đi".
      final move = loss.move! as ChangeAFact;
      final proposed = double.parse(move.proposedValue);
      // Và con số đó phải THẬT SỰ hết lỗ sau phí.
      expect(proposed - 240000 - proposed * 0.083, greaterThan(0));
    });

    test('sản phẩm không theo dõi tồn KHÔNG bao giờ "sắp hết hàng"', () {
      final service = product(id: 'dich-vu', quantity: null, reorder: null);
      final items = const CommerceOpportunityService().derive(
        products: [service],
        profit: CommerceProfitContext.derive(
          orders: const [],
          products: [service],
          settlements: const [],
          now: now,
        ),
        quotes: const [],
        now: now,
      );

      expect(items.where((i) => i.kind == BriefKind.stockRunningOut), isEmpty);
    });

    test('⭐ kiện kẹt ⇒ bấm được: nhắn cho KHÁCH đang chờ (WTM-348)', () {
      final stuck = Shipment(
        id: 'shp-1',
        orderId: 'o-1',
        trackingNumber: 'GHN12345678',
        status: ShipmentStatus.inTransit,
        carrier: Carrier.ghn,
        lastUpdate: now.subtract(const Duration(days: 6)),
        origin: 'TP.HCM',
        destination: 'Hà Nội',
      );
      final item = const CommerceOpportunityService()
          .derive(
            products: const [],
            profit: CommerceProfitContext.derive(
              products: const [],
              orders: const [],
              settlements: const [],
              now: now,
            ),
            quotes: const [],
            now: now,
            shipments: [
              ShipmentConcern(
                shipment: stuck,
                kind: ShipmentConcernKind.silent,
                peersDelivered: 0,
              ),
            ],
            orders: [
              order(
                id: 'o-1',
                of: product(id: 'p1'),
              ),
            ],
          )
          .firstWhere((i) => i.subjectKind == 'shipment');

      // Trước WTM-348 mục này chỉ nói "gọi hãng" rồi dừng — thấy được mà không
      // bấm được gì.
      final move = item.move;
      expect(move, isA<DoSomething>());
      expect(
        (move! as DoSomething).actionType,
        BusinessActionType.customerSendMessage,
      );
    });

    test('⛔ không tra ra khách ⇒ KHÔNG có nút, chứ không nhắn bừa', () {
      final orphan = Shipment(
        id: 'shp-2',
        trackingNumber: 'GHN99999999',
        status: ShipmentStatus.inTransit,
        carrier: Carrier.ghn,
        lastUpdate: now.subtract(const Duration(days: 6)),
      );
      final item = const CommerceOpportunityService()
          .derive(
            products: const [],
            profit: CommerceProfitContext.derive(
              products: const [],
              orders: const [],
              settlements: const [],
              now: now,
            ),
            quotes: const [],
            now: now,
            shipments: [
              ShipmentConcern(
                shipment: orphan,
                kind: ShipmentConcernKind.silent,
                peersDelivered: 0,
              ),
            ],
          )
          .firstWhere((i) => i.subjectKind == 'shipment');

      // Vẫn hiện ra — biết có chuyện vẫn hơn không biết. Chỉ là không có nút,
      // vì nhắn cho một khách đoán bừa còn tệ hơn im lặng.
      expect(item.move, isNull);
    });

    test('hàng nằm = KHÔNG bán được món nào, không phải "bán ít"', () {
      final slow = product(id: 'cham', quantity: 50);
      final dead = product(id: 'nam', quantity: 80);
      final profit = CommerceProfitContext.derive(
        products: [slow, dead],
        orders: [order(id: 'o1', of: slow)],
        settlements: const [],
        now: now,
      );

      final items = const CommerceOpportunityService().derive(
        products: [slow, dead],
        profit: profit,
        quotes: const [],
        now: now,
      );

      final deadStock = items.where(
        (i) => i.evidence.any((e) => e.source == 'rule:dead-stock'),
      );
      expect(deadStock.map((i) => i.subjectId), ['nam']);
    });
  });

  // ── chạy trên DATASET THẬT ───────────────────────────────────────────────

  group('trên 100 sản phẩm đã nhập thật', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    Future<
      ({
        CommerceProfitContext profit,
        List<BriefItem> items,
        List<Product> products,
      })
    >
    importAndDerive() async {
      final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
      final preview = await XlsxCommerceSource(
        bytes: file.readAsBytesSync(),
        fileName: file.uri.pathSegments.last,
        now: now,
      ).read();

      await CommerceImporter(
        database: db,
        products: DriftProductRepository(db),
        customers: DriftCustomerRepository(db),
        orders: DriftOrderRepository(db),
        settlements: DriftSettlementRepository(db),
        commerce: CommerceRepository(db),
        shipments: ShipmentRepository(db),
        now: () => now,
        newId: () => 'test',
      ).apply(preview, sourceVendor: ImportVendor.bundledDemo, isDemo: true);

      final products = await DriftProductRepository(db).loadAll();
      final profit = CommerceProfitContext.derive(
        orders: await DriftOrderRepository(db).loadAll(),
        products: products,
        settlements: await DriftSettlementRepository(db).loadAll(),
        now: now,
      );
      final items = const CommerceOpportunityService().derive(
        products: products,
        profit: profit,
        quotes: await CommerceRepository(db).loadQuotes(),
        now: now,
      );
      return (profit: profit, items: items, products: products);
    }

    test('tính được lời thật của cả kỳ', () async {
      final result = await importAndDerive();

      expect(result.profit.hasData, isTrue);
      expect(result.profit.overall, isA<ProfitKnown>());
      expect(result.profit.byProduct, isNotEmpty);
    });

    test('tìm ra sản phẩm ĐANG LỖ sau phí — nhóm D của dataset', () async {
      final result = await importAndDerive();

      expect(
        result.profit.losingAfterFees,
        isNotEmpty,
        reason: 'dataset cố ý gieo 9 sản phẩm lỗ sau phí — engine phải thấy',
      );
    });

    test('engine tìm ra ĐỦ BỐN loại việc từ dữ liệu', () async {
      final result = await importAndDerive();
      final sources = {
        for (final item in result.items)
          for (final e in item.evidence) e.source,
      };

      expect(sources, contains('rule:true-profit'));
      expect(sources, contains('rule:stock-level'));
      expect(sources, contains('rule:dead-stock'));
      expect(sources, contains('rule:supplier-comparison'));
    });

    test('mỗi việc có bằng chứng, và bằng chứng nói bằng tiếng Việt', () async {
      final result = await importAndDerive();

      expect(result.items, isNotEmpty);
      for (final item in result.items) {
        expect(item.evidence, isNotEmpty);
        expect(item.headline, isNotEmpty);
        // Không lộ id kỹ thuật ra câu người bán đọc.
        expect(item.headline, isNot(contains('import-')));
        expect(item.headline, isNot(contains('DEMO-P')));
      }
    });

    test('danh sách KHÔNG dài quá — mỗi loại tối đa ba việc', () async {
      final result = await importAndDerive();

      // Một danh sách ba mươi dòng tương đương một danh sách trống.
      expect(result.items.length, lessThanOrEqualTo(12));
    });

    test('so sánh nhà cung cấp dùng được trên sản phẩm nhóm G', () async {
      await importAndDerive();
      final quotes = await CommerceRepository(db).loadQuotes();
      final byProduct = <String, List<SupplierQuote>>{};
      for (final q in quotes) {
        (byProduct[q.productId] ??= []).add(q);
      }

      final comparable = [
        for (final entry in byProduct.entries)
          if (entry.value.length >= 2)
            SupplierComparison.from(productId: entry.key, quotes: entry.value),
      ];

      expect(comparable.length, greaterThanOrEqualTo(10));
      expect(comparable.every((c) => c.isComparable), isTrue);
      // Và có ít nhất một nguồn thiếu lead time — để giao diện phải nói
      // "chưa biết" chứ không đoán.
      expect(
        comparable.any(
          (c) => c.alternatives.any((o) => o.unknowns.contains('lead_time')),
        ),
        isTrue,
      );
    });
  });
}
