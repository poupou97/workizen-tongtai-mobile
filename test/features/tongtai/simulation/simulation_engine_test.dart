import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/finance/settlement.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/simulation/demo_event.dart';
import 'package:tongtai/features/tongtai/simulation/demo_event_repository.dart';
import 'package:tongtai/features/tongtai/simulation/demo_scenario.dart';
import 'package:tongtai/features/tongtai/simulation/simulation_engine.dart';

/// WTM-337 · E1 — đồng hồ mô phỏng và sổ sự kiện.
///
/// Suite này chạy trên **danh mục thật đã nhập** từ dataset demo: một câu hỏi
/// *"còn màu đen size M không"* chỉ có nghĩa nếu áo đó có thật, với đúng con số
/// tồn — nên mô phỏng cũng phải đứng trên danh mục thật.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final anchor = DateTime(2026, 8, 9, 12);
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  SimulationEngine engine({DemoScenario scenario = const DemoScenario()}) =>
      SimulationEngine(
        events: DemoEventRepository(db),
        orders: DriftOrderRepository(db),
        products: DriftProductRepository(db),
        customers: DriftCustomerRepository(db),
        settlements: DriftSettlementRepository(db),
        shipments: ShipmentRepository(db),
        prefs: prefs,
        scenario: scenario,
      );

  Future<void> importCatalogue() async {
    final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
    final preview = await XlsxCommerceSource(
      bytes: file.readAsBytesSync(),
      fileName: file.uri.pathSegments.last,
      now: anchor,
    ).read();
    await CommerceImporter(
      database: db,
      products: DriftProductRepository(db),
      customers: DriftCustomerRepository(db),
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      commerce: CommerceRepository(db),
      shipments: ShipmentRepository(db),
      now: () => anchor,
      newId: () => 'test',
    ).apply(preview, sourceVendor: ImportVendor.bundledDemo, isDemo: true);
  }

  // ── tất định ─────────────────────────────────────────────────────────────

  group('tất định', () {
    test('⭐ cùng seed ⇒ CÙNG kịch bản, tới từng phút', () async {
      await importCatalogue();
      final products = await DriftProductRepository(db).loadAll();
      final customers = await DriftCustomerRepository(db).loadAll();

      List<String> run() => [
        for (final e in const DemoScenario().generate(
          startedAt: anchor,
          products: products,
          customers: customers,
        ))
          '${e.kind.code}@${e.occurredAt.toIso8601String()}|${e.headline}',
      ];

      // Một mô phỏng ngẫu nhiên thì mỗi lần mở app là một doanh nghiệp khác,
      // và không ai đối chiếu được gì với ai — kể cả Founder với chính mình.
      expect(run(), run());
      expect(run().length, greaterThan(80));
    });

    test('seed khác ⇒ kịch bản khác', () async {
      await importCatalogue();
      final products = await DriftProductRepository(db).loadAll();
      final customers = await DriftCustomerRepository(db).loadAll();

      final a = const DemoScenario().generate(
        startedAt: anchor,
        products: products,
        customers: customers,
      );
      final b = const DemoScenario(
        seed: 777,
      ).generate(startedAt: anchor, products: products, customers: customers);

      expect(
        a.map((e) => e.headline).toList(),
        isNot(b.map((e) => e.headline).toList()),
      );
    });

    test('danh mục rỗng ⇒ không sinh gì, không nổ', () {
      expect(
        const DemoScenario().generate(
          startedAt: anchor,
          products: const [],
          customers: const [],
        ),
        isEmpty,
      );
    });
  });

  // ── câu chuyện nối liền (§2) ─────────────────────────────────────────────

  group('dữ liệu LIÊN KẾT, không phải bản ghi rời', () {
    test(
      '⭐ bình luận → soạn trả lời → đơn hàng cùng một correlationId',
      () async {
        await importCatalogue();
        await engine().start(anchor: anchor);

        final story = await DemoEventRepository(
          db,
        ).loadStory('story-social-sale');

        expect(story, hasLength(3));
        expect(story[0].kind, DemoEventKind.commentReceived);
        expect(story[1].actor, DemoActor.agent);
        expect(story[2].kind, DemoEventKind.orderCreated);
        // Đây là khác biệt giữa "app có dữ liệu demo" và "app có một doanh nghiệp".
        expect(story.map((e) => e.correlationId).toSet(), hasLength(1));
      },
    );

    test(
      'kiện chậm → khách giận → Tổng Tài soạn xin lỗi, cùng câu chuyện',
      () async {
        await importCatalogue();
        await engine().start(anchor: anchor);

        final story = await DemoEventRepository(
          db,
        ).loadStory('story-late-angry');

        // WTM-345 — câu chuyện này nay chạy TRỌN, tới tận đánh giá của khách.
        expect(story.map((e) => e.kind), [
          DemoEventKind.orderCreated,
          DemoEventKind.shipmentDelayed,
          DemoEventKind.messageReceived,
          DemoEventKind.messageReceived,
          DemoEventKind.reviewCreated,
        ]);
      },
    );

    test('⭐ khách giận ⇒ BẮT BUỘC duyệt, bất kể mức tự động', () async {
      await importCatalogue();
      await engine().start(anchor: anchor);

      final story = await DemoEventRepository(db).loadStory('story-late-angry');
      final angry = story.firstWhere(
        (e) => e.payload['sentiment'] == 'negative',
      );
      // Tìm bản nháp bằng **chủ thể**, không bằng vị trí: câu chuyện còn dài
      // ra nữa (WTM-345 thêm đánh giá vào cuối), và `.last` sẽ âm thầm trỏ
      // sang một sự kiện khác.
      final draft = story.firstWhere((e) => e.actor == DemoActor.agent);

      // Một câu trả lời sai cho khách đang giận không rút lại được.
      expect(angry.payload['needsApproval'], isTrue);
      expect(draft.payload['needsApproval'], isTrue);
    });

    test(
      '⭐ hoàn tiền vào SỔ ĐỐI SOÁT, không chỉ nằm trên dòng thời gian',
      () async {
        await importCatalogue();
        final e = engine();
        await e.start(anchor: anchor);
        await e.advanceDay(days: 14);

        // ⚠️ Bộ 100 sản phẩm **đã có sẵn** dòng hoàn tiền (cứ đơn thứ 23 là
        // một đơn hoàn). Chỉ đếm phần MÔ PHỎNG sinh ra, nếu không bài test đo
        // hai nguồn khác nhau và con số chẳng nói lên điều gì.
        final refunds = [
          for (final line in await DriftSettlementRepository(db).loadAll())
            if (line.kind == SettlementKind.refund &&
                line.id.startsWith('sample-'))
              line,
        ];

        expect(refunds, hasLength(1));
        final refund = refunds.single;
        // ADR-TON-024: `amount` luôn dương, chiều nằm ở `direction`.
        expect(refund.amount, greaterThan(0));
        expect(refund.direction, SettlementDirection.outbound);
        // Người bán trả, không phải sàn — nên nó ăn vào **lời thật** của họ.
        expect(refund.fundedBy, FundingSource.seller);
      },
    );

    test('đòi hoàn KHÔNG trừ tiền — chỉ hoàn tất mới chạm sổ', () async {
      await importCatalogue();
      final e = engine();
      await e.start(anchor: anchor);
      // Ngày 12 có yêu cầu hoàn, ngày 13 mới hoàn tất. `start()` đã áp ngày
      // đầu, nên đẩy thêm 10 ngày là dừng đúng ở ngày có yêu cầu.
      await e.advanceDay(days: 10);

      final story = await DemoEventRepository(db).loadStory('story-refund');
      expect(
        story.where((x) => x.kind == DemoEventKind.refundRequested),
        isNotEmpty,
      );
      // Trừ tiền ở bước ĐÒI là trừ cho một việc chưa xảy ra.
      expect(
        (await DriftSettlementRepository(db).loadAll()).where(
          (l) => l.kind == SettlementKind.refund && l.id.startsWith('sample-'),
        ),
        isEmpty,
      );
    });

    test('⭐ đánh giá nối vào ĐÚNG câu chuyện kiện chậm', () async {
      await importCatalogue();
      await engine().start(anchor: anchor);

      final story = await DemoEventRepository(db).loadStory('story-late-angry');
      final review = story.firstWhere(
        (x) => x.kind == DemoEventKind.reviewCreated,
      );

      // Cùng một khách, cùng một câu chuyện — nên khi Founder mở khách ra thì
      // thấy cả cái kết chứ không phải một chuỗi cụt.
      expect(review.subjectKind, 'customer');
      expect(review.subjectId, story.first.payload['customerId']);
      expect(review.payload['rating'], 3);
    });

    test(
      '⭐ kiện đi ĐÚNG đường cũng thành bản ghi, không chỉ kiện hỏng',
      () async {
        await importCatalogue();
        final e = engine();
        await e.start(anchor: anchor);
        await e.advanceDay(days: 5);

        final shipment = (await ShipmentRepository(
          db,
        ).loadAll()).firstWhere((s) => s.id == 'sample-demo-fulfilment');

        // Bàn giao → đang giao → đã giao: trạng thái CUỐI phải thắng, không phải
        // bản ghi đầu tiên nhìn thấy.
        expect(shipment.status, ShipmentStatus.delivered);
        expect(shipment.carrier, Carrier.ghtk);
        expect(shipment.destination, 'Đà Nẵng');
      },
    );

    test('ba chủ thể phân biệt được: sàn · Tổng Tài · bạn', () async {
      await importCatalogue();
      await engine().start(anchor: anchor);

      final timeline = await DemoEventRepository(db).loadTimeline();
      final actors = timeline.map((e) => e.actor).toSet();

      // Gộp cả ba thành "system" là xoá mất đúng thông tin khiến dòng thời gian
      // đáng đọc.
      expect(actors, contains(DemoActor.platform));
      expect(actors, contains(DemoActor.agent));
    });
  });

  // ── đồng hồ lái miền THẬT ────────────────────────────────────────────────

  group('đồng hồ lái miền THẬT (ADR-TON-014)', () {
    test('chưa có danh mục ⇒ nói ra, không bịa sản phẩm', () async {
      final tick = await engine().start(anchor: anchor);

      expect(tick.reason, SimulationBlocked.needsCatalogue);
      expect(await DriftOrderRepository(db).loadAll(), isEmpty);
    });

    test('bắt đầu ⇒ đơn vào ĐÚNG OrderRepository, có phí sàn đi kèm', () async {
      await importCatalogue();
      final ordersBefore = (await DriftOrderRepository(db).loadAll()).length;

      await engine().start(anchor: anchor);

      final orders = await DriftOrderRepository(db).loadAll();
      expect(orders.length, greaterThan(ordersBefore));

      final simulated = orders.where((o) => o.id.startsWith('sample-demo-'));
      expect(simulated, isNotEmpty);
      expect(simulated.first.provenance.source, ProvenanceSource.sample);

      // Doanh thu mà chưa có phí là con số tâng bốc — WTM-322 đã dựng hẳn một
      // blocker để chặn đúng chuyện đó, nên mô phỏng không được tạo ra nó.
      final fees = await DriftSettlementRepository(db).loadAll();
      expect(
        fees.where((f) => f.orderId.startsWith('sample-demo-')),
        isNotEmpty,
      );
    });

    test(
      '⭐ bán được thì TỒN GIẢM — nếu không, "sắp hết hàng" không bao giờ xảy ra',
      () async {
        await importCatalogue();
        final before = {
          for (final p in await DriftProductRepository(db).loadAll())
            p.id: p.quantity ?? 0,
        };

        await engine().start(anchor: anchor);

        final after = await DriftProductRepository(db).loadAll();
        final dropped = after.where((p) => (p.quantity ?? 0) < before[p.id]!);
        expect(dropped, isNotEmpty);
        // Và không kho nào âm — một con số không giải thích được cho ai.
        expect(after.every((p) => (p.quantity ?? 0) >= 0), isTrue);
      },
    );

    test('kiện chậm vào ShipmentRepository với mốc cập nhật LÙI LẠI', () async {
      await importCatalogue();
      await engine().start(anchor: anchor);

      final shipments = await ShipmentRepository(db).loadAll();
      expect(shipments, isNotEmpty);
      // Không đặt sẵn cờ "chậm": việc nó chậm là **kết luận** của Rule Twin,
      // không phải một ô trong dữ liệu (WTM-323).
      final late = shipments.first;
      expect(late.lastUpdate!.isBefore(anchor), isTrue);
    });

    test('Ngày tiếp đẩy thế giới đi và áp thêm sự kiện', () async {
      await importCatalogue();
      final sim = engine();
      await sim.start(anchor: anchor);
      final dayBefore = await sim.currentDay();
      final appliedBefore = (await DemoEventRepository(
        db,
      ).loadTimeline(limit: 500)).length;

      final tick = await sim.advanceDay();

      expect(await sim.currentDay(), dayBefore + 1);
      expect(tick.didSomething, isTrue);
      expect(
        (await DemoEventRepository(db).loadTimeline(limit: 500)).length,
        greaterThan(appliedBefore),
      );
    });

    test('Sự kiện tiếp áp ĐÚNG MỘT sự kiện', () async {
      await importCatalogue();
      final sim = engine();
      await sim.start(anchor: anchor);

      final tick = await sim.advanceOneEvent();

      expect(tick.applied, hasLength(1));
    });

    test('sự kiện CHƯA áp không hiện trên dòng thời gian', () async {
      await importCatalogue();
      final sim = engine();
      await sim.start(anchor: anchor);

      final timeline = await DemoEventRepository(db).loadTimeline(limit: 500);

      // Một chuyện chưa xảy ra trong thế giới mô phỏng mà đã nằm trên dòng thời
      // gian là nói trước tương lai.
      expect(timeline.every((e) => e.isApplied), isTrue);
      expect(await DemoEventRepository(db).nextPending(), isNotNull);
    });

    test('áp lại không nhân đôi đơn', () async {
      await importCatalogue();
      final sim = engine();
      await sim.start(anchor: anchor);
      final count = (await DriftOrderRepository(db).loadAll()).length;

      // Bấm "Ngày tiếp" rồi lùi lại không được sinh đơn lần hai cho cùng sự
      // kiện: `appliedAt` là thứ chặn.
      await sim.advanceDay(days: 0);

      expect((await DriftOrderRepository(db).loadAll()).length, count);
    });

    test('chưa bắt đầu ⇒ Ngày tiếp nói rõ, không im lặng', () async {
      final tick = await engine().advanceDay();

      expect(tick.reason, SimulationBlocked.notStarted);
    });

    test('đặt lại xoá sổ sự kiện và đồng hồ, KHÔNG đụng miền thật', () async {
      await importCatalogue();
      final sim = engine();
      await sim.start(anchor: anchor);
      final orders = (await DriftOrderRepository(db).loadAll()).length;

      await sim.reset();

      expect(await DemoEventRepository(db).count(), 0);
      expect(await sim.startedAt(), isNull);
      // Hai đường xoá, mỗi đường khai rõ phạm vi (WTM-307): dọn đơn là việc của
      // "Đặt lại dữ liệu mẫu", không phải của đây.
      expect((await DriftOrderRepository(db).loadAll()).length, orders);
    });
  });

  // ── mã lạ ────────────────────────────────────────────────────────────────

  test('loại sự kiện lạ ⇒ bỏ dòng, không đoán', () async {
    await importCatalogue();
    await engine().start(anchor: anchor);
    final before = (await DemoEventRepository(
      db,
    ).loadTimeline(limit: 500)).length;

    // Phải hỏng một dòng ĐÃ ÁP: dòng chưa áp vốn không nằm trên dòng thời
    // gian, nên hỏng nó thì phép thử không chứng minh được gì.
    await db.customStatement(
      "UPDATE demo_events_table SET kind = 'khong_biet' "
      "WHERE id = (SELECT id FROM demo_events_table "
      "WHERE applied_at IS NOT NULL LIMIT 1)",
    );

    expect(
      (await DemoEventRepository(db).loadTimeline(limit: 500)).length,
      lessThan(before),
    );
  });
}
