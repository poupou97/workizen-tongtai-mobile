import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/simulation/demo_event_repository.dart';
import 'package:tongtai/features/tongtai/simulation/simulation_engine.dart';

/// # ⛔ Invariant thời gian — WTM-344
///
/// **Không một bản ghi nghiệp vụ nào được mang mốc thời gian sau `now`**, trừ
/// đúng một ngoại lệ được khai rõ: sự kiện mô phỏng **chưa áp**
/// (`appliedAt == null`), tức là chuyện *đã lên lịch nhưng chưa xảy ra*.
///
/// ## Vì sao đây là invariant chứ không phải một bài test lẻ
///
/// Founder cầm máy ngày 10/8 và thấy đơn hàng ngày **29/8** và **31/8**. Lỗi
/// gốc chỉ là một dòng — cửa sổ lịch sử kết thúc ở *cuối tháng hiện tại* thay
/// vì ở *hôm nay*. Nhưng hậu quả không nằm ở dòng đó: tháng hiện tại trông như
/// đã bán xong cả tháng, nên Dự báo doanh thu lấy một tháng đầy giả làm mốc và
/// mọi so sánh "tháng này vs tháng trước" đều lệch.
///
/// Vá đúng một chỗ thì lần sau một nguồn sinh dữ liệu khác lại tái phạm, và
/// **không có gì đỏ lên** — người phát hiện duy nhất lại là Founder. Nên luật
/// được viết ở đây, áp cho **mọi** nguồn sinh dữ liệu.
///
/// ## Hai mốc phải test, không phải một
///
/// **Giữa tháng** là ca hỏng (ngày 10 mà sinh tới ngày 31) và **cuối tháng** là
/// ca dễ tưởng đã đúng: ngày 31 thì "cuối tháng" trùng "hôm nay", nên một bản
/// vá sai vẫn xanh nếu chỉ test mốc đó.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Mọi mốc thời gian mà một bản ghi mang theo.
  void expectNoFuture(
    Iterable<DateTime?> stamps,
    DateTime now, {
    required String what,
  }) {
    final future = [
      for (final s in stamps)
        if (s != null && s.isAfter(now)) s,
    ];
    expect(
      future,
      isEmpty,
      reason:
          '$what mang mốc sau "bây giờ" ($now). Một lịch sử chứa tương lai '
          'không còn là lịch sử: ${future.take(5)}',
    );
  }

  group('lịch sử 12 tháng KHÔNG được chứa tương lai', () {
    for (final (label, now) in [
      ('giữa tháng', DateTime(2026, 8, 10, 14, 30)),
      ('ngày cuối tháng', DateTime(2026, 8, 31, 23, 0)),
      ('ngày đầu tháng', DateTime(2026, 9, 1, 8, 0)),
    ]) {
      test('⭐ $label', () {
        final data = HistoricalDataGenerator(
          clock: () => now,
        ).generate(const HistoricalDataSpec());

        expectNoFuture(
          data.orders.map((o) => o.date),
          now,
          what: 'đơn hàng lịch sử',
        );
        expectNoFuture(
          data.transactions.map((t) => t.date),
          now,
          what: 'giao dịch thu chi lịch sử',
        );
        expectNoFuture(
          data.customers.map((c) => c.lastPurchaseDate),
          now,
          what: 'lần mua gần nhất của khách',
        );
        expectNoFuture([data.windowEnd], now, what: 'cuối cửa sổ lịch sử');

        // …và vẫn phải là **dữ liệu thật sự có**, không phải rỗng cho an toàn.
        expect(data.orders, isNotEmpty);
        expect(
          data.spec.months,
          12,
          reason: 'cắt trần thời gian KHÔNG được rút ngắn cửa sổ 12 tháng',
        );
      });
    }

    test('người gọi ghim một tháng trong quá khứ thì KHÔNG bị cắt', () {
      // Cắt theo `now`, không cắt theo "hôm nay là ngày mấy": một cửa sổ kết
      // thúc từ năm ngoái vẫn phải trọn tháng cuối của nó.
      final data = HistoricalDataGenerator(
        clock: () => DateTime(2026, 8, 10),
      ).generate(HistoricalDataSpec(endMonth: DateTime(2025, 11)));

      expect(data.windowEnd.month, 11);
      expect(data.windowEnd.day, 30);
    });
  });

  group('mô phỏng: việc ĐÃ ÁP không ở tương lai', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() => db.close());

    test('⭐ áp tới đâu thì mốc nằm trong quá khứ tới đó', () async {
      final now = DateTime(2026, 8, 10, 12);
      final products = DriftProductRepository(db);
      final customers = DriftCustomerRepository(db);
      final seeded = HistoricalDataGenerator(
        clock: () => now,
      ).generate(const HistoricalDataSpec());
      await customers.upsertAll(seeded.customers);
      await products.upsertAll(seeded.products);

      final events = DemoEventRepository(db);
      final engine = SimulationEngine(
        events: events,
        orders: DriftOrderRepository(db),
        products: products,
        customers: customers,
        settlements: DriftSettlementRepository(db),
        shipments: ShipmentRepository(db),
        prefs: prefs,
      );

      await engine.start(anchor: now);
      await engine.advanceDay(days: 14);

      final applied = await events.loadTimeline(limit: 1000);
      expect(applied, isNotEmpty);
      expectNoFuture(
        applied.map((e) => e.occurredAt),
        now,
        what: 'việc đã áp trong mô phỏng',
      );

      // Miền thật mà mô phỏng ghi ra cũng phải tuân luật.
      expectNoFuture(
        (await DriftOrderRepository(db).loadAll()).map((o) => o.date),
        now,
        what: 'đơn do mô phỏng sinh',
      );
    });

    test('⭐ NGOẠI LỆ có tên: chỉ việc CHƯA ÁP mới được ở tương lai', () async {
      final now = DateTime(2026, 8, 10, 12);
      final products = DriftProductRepository(db);
      final customers = DriftCustomerRepository(db);
      final seeded = HistoricalDataGenerator(
        clock: () => now,
      ).generate(const HistoricalDataSpec());
      await customers.upsertAll(seeded.customers);
      await products.upsertAll(seeded.products);

      final engine = SimulationEngine(
        events: DemoEventRepository(db),
        orders: DriftOrderRepository(db),
        products: products,
        customers: customers,
        settlements: DriftSettlementRepository(db),
        shipments: ShipmentRepository(db),
        prefs: prefs,
      );
      await engine.start(anchor: now);

      final pending = await DemoEventRepository(
        db,
      ).loadDue(now.add(const Duration(days: 365)));

      // Kịch bản phải còn việc ở phía trước, nếu không đồng hồ chẳng có gì để
      // đẩy tới.
      expect(pending, isNotEmpty);

      // ⭐ Luật: **ở tương lai ⇒ bắt buộc chưa áp.** Hôm nay engine neo cả cửa
      // sổ 30 ngày kết thúc ở `now`, nên trên thực tế KHÔNG có việc nào mang
      // mốc tương lai — vế trái rỗng và luật đúng một cách hiển nhiên.
      //
      // Vẫn viết ra, vì cái đáng giữ là **hình dạng của ngoại lệ**: ngày nào
      // ai đó đổi cách neo để kịch bản chạy về phía trước, dòng này là thứ
      // duy nhất còn nói được "được, nhưng chỉ khi chưa áp".
      for (final e in pending) {
        if (e.occurredAt.isAfter(now)) {
          expect(
            e.appliedAt,
            isNull,
            reason: 'việc ở tương lai thì BẮT BUỘC chưa được áp',
          );
        }
      }

      // …và trạng thái hôm nay được khoá lại, để việc đổi cách neo là một
      // quyết định nhìn thấy được chứ không phải một hệ quả lặng lẽ.
      expect(
        pending.where((e) => e.occurredAt.isAfter(now)),
        isEmpty,
        reason:
            'engine đang neo cửa sổ mô phỏng kết thúc ở `now`; đổi điều đó '
            'thì phải sửa dòng này một cách có ý thức',
      );
    });
  });
}
