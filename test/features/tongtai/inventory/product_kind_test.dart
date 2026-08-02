import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/export/backup_codec.dart';
import 'package:tongtai/features/tongtai/inventory/inventory_context.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert.dart';
import 'package:tongtai/features/tongtai/inventory/stock_alert_service.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_rule_engine.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';

/// WTM-227 / ADR-TON-023 — a digital product has no stock.
///
/// Dogfood found this by trying to record Workizen itself in Tổng Tài: the
/// model forced a quantity onto a piece of software, and the app then acted on
/// the number it had made the seller invent — Inventory shouted "Hết hàng" and
/// the Rule Engine generated a **restock opportunity for software**.
///
/// The rule the whole story defends: `null` means *"does not apply"*, never
/// *"zero"*. Same discipline as `costPrice` (WTM-204) and `paymentStatus`
/// (WTM-211), now applied to stock.
void main() {
  Product product({
    required ProductKind kind,
    int? quantity,
    int? reorderLevel,
    String id = 'p1',
  }) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Tổng Tài',
    category: 'Phần mềm',
    pricePerUnit: 199000,
    kind: kind,
    quantity: quantity,
    reorderLevel: reorderLevel,
    updatedAt: DateTime(2026, 8, 2),
  );

  group('a digital product is never out of stock', () {
    test('no stock status, no alert', () {
      final digital = product(kind: ProductKind.digital);

      expect(digital.stockStatus, isNull);
      expect(digital.needsRestock, isFalse);
      expect(StockAlert.forProduct(digital), isNull);
      expect(StockAlertService([digital]).hasAlerts, isFalse);
    });

    test('a service behaves the same way', () {
      expect(product(kind: ProductKind.service).stockStatus, isNull);
    });

    test('the physical model is untouched — the other half of the rule', () {
      // "Không ép doanh nghiệp hàng hoá thành doanh nghiệp số" (ADR-TON-023).
      final out = product(
        kind: ProductKind.physical,
        quantity: 0,
        reorderLevel: 5,
      );
      final low = product(
        kind: ProductKind.physical,
        quantity: 3,
        reorderLevel: 5,
      );
      final ok = product(
        kind: ProductKind.physical,
        quantity: 50,
        reorderLevel: 5,
      );

      expect(out.stockStatus, StockStatus.outOfStock);
      expect(low.stockStatus, StockStatus.lowStock);
      expect(ok.stockStatus, StockStatus.inStock);
      expect(StockAlertService([out, low, ok]).alerts, hasLength(2));
    });
  });

  test('no restock opportunity is generated for software', () {
    // The exact defect dogfood found: the engine proposing that the seller
    // order more units of a thing that has no units.
    final digital = product(kind: ProductKind.digital);
    final sale = CustomerOrder(
      id: 'o1',
      customerId: 'c1',
      orderNumber: 'DH-1',
      date: DateTime(2026, 7, 20),
      status: OrderStatus.delivered,
      items: [
        OrderItem(
          productName: 'Tổng Tài',
          category: 'Phần mềm',
          quantity: 2,
          unitPrice: 199000,
        ),
      ],
    );

    final generated = const OpportunityRuleEngine().generate(
      products: [digital],
      customers: const [],
      orders: [sale],
      goals: const [],
      now: DateTime(2026, 8, 2),
    );

    expect(
      generated.where((o) => o.id.startsWith('gen-restock-')),
      isEmpty,
      reason: 'phần mềm không có gì để nhập thêm',
    );
  });

  test('stock metrics count only what actually has stock', () {
    final summary = InventorySummary.from([
      product(kind: ProductKind.physical, quantity: 0, reorderLevel: 5),
      product(kind: ProductKind.digital, id: 'p2'),
      product(kind: ProductKind.service, id: 'p3'),
    ]);

    expect(summary.productCount, 3, reason: 'cả ba đều là sản phẩm');
    expect(summary.outOfStockCount, 1);
    expect(
      summary.lowStockCount,
      0,
      reason: 'sản phẩm số không nằm trong chỉ số kho, kể cả ở phía "còn hàng"',
    );
  });

  test(
    '"không áp dụng" survives a restart — it is not rewritten as 0',
    () async {
      // If the null collapsed to 0 on the way to disk, reopening the app would
      // declare the seller's software out of stock. That is the whole bug, one
      // layer down.
      final dir = await Directory.systemTemp.createTemp('tongtai_kind');
      final file = File('${dir.path}/t.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      var db = AppDatabase.forExecutor(NativeDatabase(file));
      await DriftProductRepository(db).upsertAll([
        product(kind: ProductKind.digital),
        product(
          kind: ProductKind.physical,
          id: 'p2',
          quantity: 7,
          reorderLevel: 3,
        ),
      ]);
      await db.close();

      db = AppDatabase.forExecutor(NativeDatabase(file));
      final loaded = await DriftProductRepository(db).loadAll();
      await db.close();

      final digital = loaded.singleWhere((p) => p.id == 'p1');
      final physical = loaded.singleWhere((p) => p.id == 'p2');

      expect(digital.kind, ProductKind.digital);
      expect(digital.quantity, isNull);
      expect(digital.stockStatus, isNull);
      expect(physical.kind, ProductKind.physical);
      expect(physical.quantity, 7);
    },
  );

  group('.ttbk carries the kind — the WTM-211 hole, not repeated', () {
    test('a digital product survives backup and restore', () {
      // WTM-211 shipped `paymentStatus` without the codec, so a restore would
      // have silently erased the seller's receivables. Same shape here: if
      // `kind` were missing, every digital product would come back physical —
      // and physical with no quantity reads as OUT OF STOCK.
      final decoded = BackupCodec.decodeProduct(
        BackupCodec.encodeProduct(product(kind: ProductKind.digital)),
      );

      expect(decoded!.kind, ProductKind.digital);
      expect(decoded.quantity, isNull);
      expect(decoded.stockStatus, isNull);
    });

    test('a file from an older build restores as physical, intact', () {
      final json = BackupCodec.encodeProduct(
        product(kind: ProductKind.physical, quantity: 12, reorderLevel: 4),
      )..remove('kind');

      final decoded = BackupCodec.decodeProduct(json);

      expect(decoded!.kind, ProductKind.physical);
      expect(decoded.quantity, 12);
      expect(decoded.reorderLevel, 4);
    });
  });

  group('biên lợi nhuận mỗi đơn vị bán (WTM-231)', () {
    test('sản phẩm số tính được biên dù KHÔNG có tồn kho', () {
      // Câu trả lời của dogfood: lợi nhuận một sản phẩm số không cần giá nhập
      // kho — nó cần chi phí biến đổi mỗi lượt bán (token AI, phí giao dịch).
      final software = Product(
        id: 'p1',
        sku: 'SKU',
        name: 'Tổng Tài',
        category: 'Phần mềm',
        pricePerUnit: 199000,
        kind: ProductKind.digital,
        costPrice: 49000,
        updatedAt: DateTime(2026, 8, 2),
      );

      expect(software.quantity, isNull);
      expect(software.unitMargin, 150000);
      expect(software.marginRatio, closeTo(0.7538, 0.001));
    });

    test('chưa nhập chi phí ⇒ null, KHÔNG phải lãi 100%', () {
      // 0 ở đây in ra con số dễ chịu nhất và sai nhất có thể.
      final unknown = product(kind: ProductKind.digital);
      expect(unknown.unitMargin, isNull);
      expect(unknown.marginRatio, isNull);
    });

    test('giá bán 0 không có biên nào để nói', () {
      final freebie = Product(
        id: 'p2',
        sku: 'SKU',
        name: 'Quà tặng',
        category: 'Khác',
        pricePerUnit: 0,
        kind: ProductKind.digital,
        costPrice: 1000,
        updatedAt: DateTime(2026, 8, 2),
      );

      expect(freebie.marginRatio, isNull, reason: 'chia cho 0 không phải biên');
      expect(freebie.unitMargin, -1000, reason: 'lỗ thì vẫn phải nói là lỗ');
    });

    test('hàng vật lý dùng ĐÚNG phép tính đó — một khái niệm, một chủ', () {
      final goods = product(
        kind: ProductKind.physical,
        quantity: 10,
        reorderLevel: 2,
      );
      final withCost = goods.copyWith(costPrice: 60000);

      expect(withCost.unitMargin, 199000 - 60000);
    });
  });

  test('an unknown kind code reads as physical, never as a guess', () {
    // A `.ttbk` from a newer build may name a kind this one has never heard
    // of. Every row that predates ADR-TON-023 WAS physical, so that is the
    // truth about them — not a fallback chosen for convenience.
    expect(ProductKind.fromCode(null), ProductKind.physical);
    expect(ProductKind.fromCode('subscription'), ProductKind.physical);
    expect(ProductKind.fromCode('digital'), ProductKind.digital);
  });
}
