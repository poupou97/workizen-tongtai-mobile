import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_enricher.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_business_seeder.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// WTM-343 — **một doanh nghiệp mẫu, một nút**, trên cơ sở dữ liệu THẬT.
///
/// Harness của `tongtai_home_screen_test.dart` dùng repository giả cho sản
/// phẩm nhưng Drift thật cho lần nhập, nên nó không nhìn thấy lớp thương mại.
/// Vòng đời đầy đủ phải được kiểm ở đây.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SampleBusinessSeeder seeder;
  late DriftProductRepository products;
  late DriftCustomerRepository customers;
  late CommerceRepository commerce;
  late DriftBusinessInputRepository businessInputs;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    products = DriftProductRepository(db);
    customers = DriftCustomerRepository(db);
    commerce = CommerceRepository(db);
    businessInputs = DriftBusinessInputRepository(db);
    final samples = SampleDataSeeder(
      customers: customers,
      products: products,
      orders: DriftOrderRepository(db),
      goals: DriftBusinessGoalRepository(db),
      finance: DriftFinanceRepository(db),
      businessInputs: businessInputs,
    );
    seeder = SampleBusinessSeeder(
      history: HistoricalDataSeeder(sampleSeeder: samples),
      importer: CommerceImporter(
        database: db,
        products: products,
        customers: customers,
        orders: DriftOrderRepository(db),
        settlements: DriftSettlementRepository(db),
        commerce: commerce,
        shipments: ShipmentRepository(db),
        now: () => DateTime(2026, 8, 9),
        newId: () => 'bundled',
      ),
      commerce: commerce,
      samples: samples,
      customers: customers,
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      products: products,
      enricher: ProductAttributeEnricher(AttributeRepository(db)),
      bundledSource: () async => XlsxCommerceSource(
        bytes: File(
          'assets/demo/TongTai-Commerce-Demo-100-Products.xlsx',
        ).readAsBytesSync(),
        fileName: 'TongTai-Commerce-Demo-100-Products.xlsx',
        now: DateTime(2026, 8, 9),
      ),
    );
  });

  tearDown(() => db.close());

  test(
    '⭐ một nút nạp CẢ HAI lớp — lịch sử 12 tháng và bộ 100 sản phẩm',
    () async {
      final report = await seeder.seed();

      expect(report.months, 12);
      expect(report.products, 100);

      final all = await products.loadAll();
      // Lớp lịch sử: bản ghi mang tiền tố `sample-`.
      expect(all.where((p) => p.id.startsWith(kSampleIdPrefix)), isNotEmpty);
      // Lớp thương mại: bản ghi mang khoá lần nhập.
      expect(all.where((p) => p.importJobId != null), hasLength(100));
      // …và báo giá nhà cung cấp, thứ mà lớp lịch sử KHÔNG sinh ra.
      expect(await commerce.loadQuotes(), isNotEmpty);
    },
  );

  test(
    '⭐ WTM-461 — nút demo gieo miền NGUỒN ĐẦU VÀO, đủ loại ADR-TON-023',
    () async {
      // Dogfood máy thật: Kho 114 sản phẩm mà Home hiện "Nguồn hàng: 0 đầu vào".
      // Nguyên nhân là bộ mẫu chưa gieo BusinessInput nào — gate này chặn tái
      // phạm: một nút demo mà không có lấy một đầu vào là demo kể chuyện cụt.
      await seeder.seed();

      final seeded = await businessInputs.loadAll();
      expect(seeded, isNotEmpty, reason: 'demo phải có nguồn đầu vào');
      // Mọi bản ghi mang tiền tố mẫu ⇒ "Xóa dữ liệu mẫu" gỡ đúng chúng.
      for (final input in seeded) {
        expect(input.id, startsWith(kSampleIdPrefix));
      }
      // Đủ CẢ NĂM loại (ADR-TON-023) — không loại nào rơi vào "Khác", đúng vấn
      // đề dogfood tìm ra.
      final kinds = {for (final i in seeded) i.kind};
      expect(kinds, containsAll(BusinessInputKind.values));
      // Câu chuyện tổng cam kết KÈM phần chưa biết: ít nhất một nguồn theo mức
      // dùng (usageBased ⇒ không phải cam kết) để màn Nguồn hàng có "chưa tính".
      final summary = BusinessInputSummary.from(seeded);
      expect(summary.monthlyCommitment, greaterThan(0));
      expect(summary.unknownCount, greaterThan(0));
    },
  );

  test(
    '⭐ WTM-461 — xoá mẫu gỡ luôn nguồn đầu vào, giữ nguồn người bán tự nhập',
    () async {
      await seeder.seed();
      // Nguồn người bán tự nhập (id UUID, không tiền tố mẫu).
      await businessInputs.upsert(
        const BusinessInput(
          id: 'a1b2c3d4-user-input',
          name: 'Nhà cung cấp của tôi',
          kind: BusinessInputKind.supplier,
          cadence: InputCadence.monthly,
          expectedAmount: 500000,
        ),
      );

      await seeder.removeAll();

      final remaining = await businessInputs.loadAll();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, 'a1b2c3d4-user-input');
    },
  );

  test('bấm hai lần không nhân đôi', () async {
    await seeder.seed();
    final first = (await products.loadAll()).length;
    await seeder.seed();

    expect((await products.loadAll()).length, first);
    expect(await commerce.loadImportJobs(), hasLength(1));
  });

  test('⭐ xoá mẫu xoá CẢ HAI lớp, và KHÔNG đụng dữ liệu người bán', () async {
    await customers.upsert(
      const Customer(
        id: 'f47ac10b-user',
        name: 'Khách Của Tôi',
        phone: '0900000000',
        location: 'HCM',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
      ),
    );

    await seeder.seed();
    await seeder.removeAll();

    expect(await products.loadAll(), isEmpty);
    expect(await commerce.loadQuotes(), isEmpty);
    expect(await commerce.loadImportJobs(), isEmpty);
    // Người thắng máy: dòng của người bán còn nguyên.
    expect((await customers.loadAll()).single.name, 'Khách Của Tôi');
  });

  test('xoá theo importJobId, KHÔNG quét theo tiền tố', () async {
    // File Excel **của người bán** đi qua đúng đường nhập này. Quét theo tiền
    // tố `import-` sẽ xoá luôn dữ liệu thật của họ.
    await seeder.seed();
    final ownFile = await XlsxCommerceSource(
      bytes: File(
        'assets/demo/TongTai-Commerce-Demo-100-Products.xlsx',
      ).readAsBytesSync(),
      fileName: 'Cua-hang-cua-toi.xlsx',
      now: DateTime(2026, 8, 9),
    ).read();
    await CommerceImporter(
      database: db,
      products: products,
      customers: customers,
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      commerce: commerce,
      shipments: ShipmentRepository(db),
      now: () => DateTime(2026, 8, 9),
      newId: () => 'own',
    ).apply(ownFile, sourceVendor: ImportVendor.localFile);

    await seeder.removeAll();

    final jobs = await commerce.loadImportJobs();
    // Lần nhập của người bán còn nguyên: phạm vi xoá khai theo **vendor của
    // lần nhập**, không phải "mọi thứ trông giống dữ liệu nhập".
    expect(jobs, hasLength(1));
    expect(jobs.single.sourceVendor, ImportVendor.localFile);
  });
}
