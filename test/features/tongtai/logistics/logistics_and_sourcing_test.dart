import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_opportunity_service.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_profit.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/commerce/sourcing_url.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_rule.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-323 · C7 — Logistics tracking + URL import cho Alibaba/1688.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 9, 12);

  Shipment shipment({
    required String id,
    ShipmentStatus status = ShipmentStatus.inTransit,
    int silentDays = 0,
    Carrier? carrier = Carrier.ghn,
    String? origin = 'TP.HCM',
    String? destination = 'Hà Nội',
  }) => Shipment(
    id: id,
    trackingNumber: 'TT$id',
    status: status,
    carrier: carrier,
    lastUpdate: now.subtract(Duration(days: silentDays)),
    origin: origin,
    destination: destination,
  );

  // ── nhận hãng từ mã vận đơn ──────────────────────────────────────────────

  group('nhận hãng từ mã vận đơn', () {
    test('nhận ra các tiền tố quen', () {
      expect(Carrier.guessFrom('SPXVN123456789'), Carrier.spx);
      expect(Carrier.guessFrom('GHN123456789'), Carrier.ghn);
      expect(Carrier.guessFrom('S12345678'), Carrier.ghtk);
    });

    test('⭐ không đoán được ⇒ null, KHÔNG chọn bừa', () {
      // Đoán sai hãng làm mọi lần tra cứu sau đó trỏ nhầm cửa, và người bán sẽ
      // kết luận app không tra được — chứ không kết luận app đoán sai.
      expect(Carrier.guessFrom('123456'), isNull);
      expect(Carrier.guessFrom(''), isNull);
      expect(Carrier.guessFrom('ABC-XYZ'), isNull);
    });
  });

  // ── Rule Twin vận chuyển ─────────────────────────────────────────────────

  group('Rule Twin vận chuyển', () {
    test('⭐ đứng im TRONG KHI đơn cùng tuyến đã tới', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'ket', silentDays: 5),
        shipment(id: 'a', silentDays: 4, status: ShipmentStatus.delivered),
        shipment(id: 'b', silentDays: 4, status: ShipmentStatus.delivered),
      ], now: now);

      final stuck = concerns.firstWhere((c) => c.shipment.id == 'ket');
      // Câu này loại được nguyên nhân chung (bão, quá tải) và chỉ còn lại
      // nguyên nhân riêng của kiện đó.
      expect(stuck.kind, ShipmentConcernKind.stuckWhilePeersArrived);
      expect(stuck.peersDelivered, 2);
    });

    test('một chuyến đối chiếu là TRÙNG HỢP, không phải mẫu', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'ket', silentDays: 5),
        shipment(id: 'a', silentDays: 4, status: ShipmentStatus.delivered),
      ], now: now);

      // Chỉ nói nó im lặng, không kết luận thay.
      expect(concerns.single.kind, ShipmentConcernKind.silent);
    });

    test('khác tuyến thì KHÔNG so', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'ket', silentDays: 5),
        shipment(
          id: 'a',
          silentDays: 4,
          status: ShipmentStatus.delivered,
          destination: 'Đà Nẵng',
        ),
        shipment(
          id: 'b',
          silentDays: 4,
          status: ShipmentStatus.delivered,
          destination: 'Cần Thơ',
        ),
      ], now: now);

      expect(concerns.single.kind, ShipmentConcernKind.silent);
    });

    test('khác hãng thì KHÔNG so', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'ket', silentDays: 5),
        shipment(
          id: 'a',
          silentDays: 4,
          status: ShipmentStatus.delivered,
          carrier: Carrier.jt,
        ),
        shipment(
          id: 'b',
          silentDays: 4,
          status: ShipmentStatus.delivered,
          carrier: Carrier.jt,
        ),
      ], now: now);

      expect(concerns.single.kind, ShipmentConcernKind.silent);
    });

    test('thiếu một đầu tuyến ⇒ không so, và không nổ', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'ket', silentDays: 5, destination: null),
        shipment(id: 'a', silentDays: 4, status: ShipmentStatus.delivered),
        shipment(id: 'b', silentDays: 4, status: ShipmentStatus.delivered),
      ], now: now);

      // So hai chuyến mà không biết chúng có cùng tuyến hay không thì so sánh
      // vô nghĩa, và cảnh báo cũng vô nghĩa theo.
      expect(concerns.single.kind, ShipmentConcernKind.silent);
    });

    test('giao thất bại là việc CẤP NHẤT, lên đầu', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'im', silentDays: 5),
        shipment(id: 'hong', status: ShipmentStatus.failed),
      ], now: now);

      expect(concerns.first.kind, ShipmentConcernKind.deliveryFailed);
    });

    test('chuyến đã xong KHÔNG bao giờ bị nhắc', () {
      final concerns = const ShipmentRule().assess([
        shipment(id: 'a', status: ShipmentStatus.delivered, silentDays: 30),
        shipment(id: 'b', status: ShipmentStatus.returning, silentDays: 30),
      ], now: now);

      expect(concerns, isEmpty);
    });

    test('chưa có tin nào ⇒ không tính là đứng im', () {
      final concerns = const ShipmentRule().assess([
        const Shipment(
          id: 'moi',
          trackingNumber: 'X',
          status: ShipmentStatus.created,
        ),
      ], now: now);

      // `lastUpdate == null` là "chưa có tin nào", không phải "cập nhật lúc 0".
      expect(concerns, isEmpty);
    });
  });

  // ── URL import (§D-6) ────────────────────────────────────────────────────

  group('URL import — connector KHÔNG chỉ là API', () {
    test('đọc được link Alibaba · 1688 · AliExpress', () {
      expect(
        SourcingUrl.parse(
          'https://www.alibaba.com/product-detail/Cotton-Tshirt_1600123456789.html',
        )?.platform,
        SupplierPlatform.alibaba,
      );
      expect(
        SourcingUrl.parse(
          'https://detail.1688.com/offer/712345678901.html',
        )?.platform,
        SupplierPlatform.taobao1688,
      );
      expect(
        SourcingUrl.parse(
          'https://www.aliexpress.com/item/1005006789012.html',
        )?.platform,
        SupplierPlatform.aliexpress,
      );
    });

    test('link chia sẻ kèm chữ vẫn đọc được', () {
      final parsed = SourcingUrl.parse(
        'Áo thun cotton giá rẻ '
        'https://detail.1688.com/offer/712345678901.html?spm=abc 【1688】',
      );

      expect(parsed, isNotNull);
      expect(parsed!.externalId, '712345678901');
    });

    test('⭐ bỏ tham số theo dõi ⇒ hai lần dán ra CÙNG một link', () {
      final a = SourcingUrl.parse(
        'https://detail.1688.com/offer/712345678901.html?spm=a1&tracelog=x',
      );
      final b = SourcingUrl.parse(
        'https://m.1688.com/offer/712345678901.html?from=share&uid=99',
      );

      // Giữ nguyên tham số thì hai lần dán cùng một sản phẩm ra hai chuỗi khác
      // nhau và chống trùng không chạy.
      expect(a!.canonicalUrl, b!.canonicalUrl);
      expect(a.externalId, b.externalId);
    });

    test('trang lạ ⇒ null, không tạo báo giá trỏ đi đâu không rõ', () {
      expect(SourcingUrl.parse('https://example.com/abc'), isNull);
      expect(SourcingUrl.parse('không phải link'), isNull);
      expect(SourcingUrl.parse(''), isNull);
    });

    test('⭐ trả về KHUNG còn trống, không phải một báo giá', () {
      final draft = SourcingUrl.parse(
        'https://detail.1688.com/offer/712345678901.html',
      )!.toDraft(productId: 'p1');

      // Không scraping ⇒ app chỉ biết nền tảng và mã sản phẩm. Để trống rồi
      // hiện 0 thì một báo giá 0 đồng sẽ THẮNG mọi so sánh nhà cung cấp, và
      // app sẽ khuyên người bán đổi sang một nguồn không có giá.
      expect(draft.sourceUrl, contains('1688.com'));
      expect(
        SourcingDraft.unknownFields,
        containsAll(const [
          'unit_cost',
          'minimum_order_quantity',
          'lead_time_days',
        ]),
      );
    });
  });

  // ── vận chuyển đi vào brief ──────────────────────────────────────────────

  group('vận chuyển thành việc cần làm', () {
    test('sinh brief với bằng chứng nói được tuyến và số ngày', () {
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
        shipments: const ShipmentRule().assess([
          shipment(id: 'ket', silentDays: 5),
          shipment(id: 'a', silentDays: 4, status: ShipmentStatus.delivered),
          shipment(id: 'b', silentDays: 4, status: ShipmentStatus.delivered),
        ], now: now),
      );

      final item = items.firstWhere(
        (i) => i.evidence.any((e) => e.source == 'rule:shipment-tracking'),
      );
      expect(item.headline, contains('2 đơn cùng tuyến đã tới'));
      expect(item.evidence.single.detail, contains('Giao Hàng Nhanh'));
      expect(item.evidence.single.detail, contains('TP.HCM→Hà Nội'));
    });
  });

  // ── nhập từ dataset thật ─────────────────────────────────────────────────

  group('SHIPMENTS trong dataset đi được vào sổ', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('nhập file demo ⇒ có chuyến giao hàng, mang đúng nguồn gốc', () async {
      final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
      final preview = await XlsxCommerceSource(
        bytes: file.readAsBytesSync(),
        fileName: file.uri.pathSegments.last,
        now: now,
      ).read();

      final result = await CommerceImporter(
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

      final stored = await ShipmentRepository(db).loadAll();
      expect(stored, isNotEmpty);
      expect(stored.first.provenance, ProvenanceSource.fileBridge);
      expect(stored.first.importJobId, result.job.id);
      expect(result.counts['shipments'], stored.length);
    });

    test('đặt lại lần nhập xoá cả chuyến giao hàng', () async {
      final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
      final preview = await XlsxCommerceSource(
        bytes: file.readAsBytesSync(),
        fileName: 'x.xlsx',
        now: now,
      ).read();
      final result = await CommerceImporter(
        database: db,
        products: DriftProductRepository(db),
        customers: DriftCustomerRepository(db),
        orders: DriftOrderRepository(db),
        settlements: DriftSettlementRepository(db),
        commerce: CommerceRepository(db),
        shipments: ShipmentRepository(db),
        now: () => now,
        newId: () => 'test',
      ).apply(preview, sourceVendor: ImportVendor.bundledDemo);

      final removed = await ShipmentRepository(db).deleteImport(result.job.id);

      expect(removed, greaterThan(0));
      expect(await ShipmentRepository(db).loadAll(), isEmpty);
    });

    test('mã trạng thái lạ ⇒ bỏ dòng, không rơi về "đang giao"', () async {
      await ShipmentRepository(db).upsertAll([shipment(id: 's1')]);
      await db.customStatement(
        "UPDATE shipments_table SET status = 'khong_biet'",
      );

      // Rơi về "đang giao" sẽ khiến một kiện đã hoàn về kho trông như đang
      // trên đường tới khách — và không ai đi tìm nó.
      expect(await ShipmentRepository(db).loadAll(), isEmpty);
    });
  });
}
