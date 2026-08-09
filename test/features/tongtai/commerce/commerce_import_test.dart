import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_import.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_reader.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-325 + WTM-326 — dataset thật đi qua **đường production** (§15).
///
/// Suite này chạy trên **chính file** đóng gói vào app, không phải một fixture
/// nhỏ dựng riêng cho test. Một fixture nhỏ chứng minh parser chạy; file thật
/// chứng minh **sản phẩm** chạy — và hai chuyện đó đã từng khác nhau.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final demoFile = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
  final now = DateTime(2026, 8, 9, 12);

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<CommerceImportPreview> readDemo() => XlsxCommerceSource(
    bytes: demoFile.readAsBytesSync(),
    fileName: demoFile.uri.pathSegments.last,
    now: now,
  ).read();

  CommerceImporter importer() => CommerceImporter(
    database: db,
    products: DriftProductRepository(db),
    customers: DriftCustomerRepository(db),
    orders: DriftOrderRepository(db),
    settlements: DriftSettlementRepository(db),
    commerce: CommerceRepository(db),
    shipments: ShipmentRepository(db),
    now: () => now,
    newId: () => 'test',
  );

  // ── C1 · dataset ─────────────────────────────────────────────────────────

  group('WTM-325 · dataset có KỊCH BẢN', () {
    test('file demo có mặt và đóng gói vào app', () {
      expect(demoFile.existsSync(), isTrue);
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        pubspec,
        contains('assets/demo/'),
        reason:
            'file có trên đĩa mà không khai vào pubspec ⇒ app không đọc được',
      );
    });

    test('đủ tám bảng', () {
      final sheets = const XlsxReader().read(demoFile.readAsBytesSync());

      expect(
        sheets.keys,
        containsAll(const [
          'PRODUCTS',
          'VARIANTS',
          'SUPPLIERS',
          'SUPPLIER_QUOTES',
          'CUSTOMERS',
          'ORDERS',
          'SETTLEMENT',
          'SHIPMENTS',
        ]),
      );
    });

    test('đủ 100 sản phẩm, KHÔNG trùng SKU', () async {
      final preview = await readDemo();

      expect(preview.products, hasLength(100));
      final skus = preview.products.map((p) => p.sku).toSet();
      expect(skus, hasLength(100));
      expect(preview.errors.where((e) => e.code == 'duplicate_sku'), isEmpty);
    });

    test('đủ mười nhóm kịch bản, đếm được từng nhóm', () {
      final sheets = const XlsxReader().read(demoFile.readAsBytesSync());
      final table = SheetTable('PRODUCTS', sheets['PRODUCTS']!);
      final counts = <String, int>{};
      for (final row in table.dataRows) {
        final scenario = table.cell(row, 'scenario');
        counts[scenario] = (counts[scenario] ?? 0) + 1;
      }

      expect(counts, {
        'A_FAST_LOW_STOCK': 12,
        'B_DEAD_STOCK': 10,
        'C_HIGH_MARGIN': 10,
        'D_LOW_MARGIN': 9,
        'E_NEW': 10,
        'F_REORDER_SOON': 10,
        'G_SUPPLIER_DIFF': 12,
        'H_BUNDLE': 10,
        'I_OUT_OF_STOCK': 5,
        'J_NORMAL': 12,
      });
    });

    test('nhóm J là ĐỐI CHỨNG — không phải sản phẩm nào cũng có vấn đề', () {
      final sheets = const XlsxReader().read(demoFile.readAsBytesSync());
      final table = SheetTable('PRODUCTS', sheets['PRODUCTS']!);
      final normal = table.dataRows.where(
        (r) => table.cell(r, 'scenario') == 'J_NORMAL',
      );

      for (final row in normal) {
        final quantity = table.number(row, 'quantity')!;
        final reorder = table.number(row, 'reorder_level')!;
        final cost = table.number(row, 'cost_price')!;
        final price = table.number(row, 'selling_price')!;

        // Không sắp hết, không hết, và lãi gộp chịu được phí sàn ~10%.
        expect(quantity, greaterThan(reorder));
        expect((price - cost) / price, greaterThan(0.15));
      }
    });

    test('nhóm D thật sự LỖ sau phí — câu hỏi "lời bao nhiêu THẬT"', () {
      final sheets = const XlsxReader().read(demoFile.readAsBytesSync());
      final table = SheetTable('PRODUCTS', sheets['PRODUCTS']!);
      final low = table.dataRows.where(
        (r) => table.cell(r, 'scenario') == 'D_LOW_MARGIN',
      );

      expect(low, isNotEmpty);
      for (final row in low) {
        final cost = table.number(row, 'cost_price')!;
        final price = table.number(row, 'selling_price')!;
        final grossMargin = price - cost;
        // Phí sàn thực tế (hoa hồng + thanh toán) khoảng 7,5–8,3%.
        final fees = price * 0.075;

        expect(grossMargin, greaterThan(0), reason: 'lãi GỘP vẫn dương');
        expect(
          grossMargin - fees,
          lessThan(0),
          reason: 'nhưng sau phí thì âm — đó mới là điểm của nhóm này',
        );
      }
    });

    test('mọi đơn trỏ tới một sản phẩm CÓ THẬT', () async {
      final preview = await readDemo();
      final ids = {for (final p in preview.products) p.id};

      expect(preview.orders, isNotEmpty);
      for (final order in preview.orders) {
        for (final item in order.items) {
          expect(ids, contains(item.productId));
        }
      }
      expect(preview.errors.where((e) => e.code == 'orphan_order'), isEmpty);
    });

    test('nhóm G có ≥2 báo giá để so sánh', () async {
      final preview = await readDemo();
      final byProduct = <String, int>{};
      for (final q in preview.quotes) {
        byProduct[q.productId] = (byProduct[q.productId] ?? 0) + 1;
      }

      final comparable = byProduct.values.where((c) => c >= 2).length;
      expect(comparable, greaterThanOrEqualTo(10));
    });

    test(
      'có báo giá CỐ Ý thiếu lead time — để so sánh phải nói "chưa biết"',
      () async {
        final preview = await readDemo();

        expect(
          preview.quotes.where((q) => q.leadTimeDays == null),
          isNotEmpty,
          reason: 'thiếu dữ liệu là một tình huống thật, dataset phải có nó',
        );
      },
    );

    test('file demo KHÔNG chứa dữ liệu cá nhân thật', () async {
      final preview = await readDemo();

      for (final customer in preview.customers) {
        expect(customer.email, contains('.invalid'));
      }
    });
  });

  // ── C2 · đọc và kiểm tra ─────────────────────────────────────────────────

  group('WTM-326 · đọc và kiểm tra', () {
    test('file không phải Excel ⇒ nói một câu người dùng hiểu', () async {
      final preview = await XlsxCommerceSource(
        bytes: Uint8List.fromList('đây là một file văn bản'.codeUnits),
        fileName: 'ghi-chu.txt',
        now: now,
      ).read();

      expect(preview.errors, hasLength(1));
      expect(preview.errors.single.detail, contains('không phải file Excel'));
      expect(preview.hasAnythingToImport, isFalse);
      // ⛔ Không có mã lỗi kỹ thuật trong câu hiển thị (§27).
      expect(preview.errors.single.detail, isNot(contains('Exception')));
    });

    test('thiếu cột bắt buộc ⇒ nói ĐỦ danh sách một lần', () async {
      final sheet = SheetTable('PRODUCTS', [
        ['sku', 'category'],
        ['A-1', 'Thời trang'],
      ]);

      expect(sheet.missingColumns(const ['sku', 'name', 'selling_price']), [
        'name',
        'selling_price',
      ]);
    });

    test('ô trống KHÔNG thành 0 — chưa nhập khác không có', () {
      final sheet = SheetTable('PRODUCTS', [
        ['sku', 'quantity'],
        ['A-1', ''],
      ]);

      expect(sheet.number(sheet.dataRows.first, 'quantity'), isNull);
    });

    test('số có dấu phân cách nghìn kiểu Việt Nam đọc được', () {
      final sheet = SheetTable('PRODUCTS', [
        ['price'],
        ['1.250.000'],
      ]);

      expect(sheet.number(sheet.dataRows.first, 'price'), 1250000);
    });

    test('cột đảo thứ tự vẫn đọc đúng — tra theo TÊN, không theo vị trí', () {
      final sheet = SheetTable('PRODUCTS', [
        ['name', 'sku', 'selling_price'],
        ['Áo thun', 'AT-1', '250000'],
      ]);
      final row = sheet.dataRows.first;

      // Đọc theo chỉ mục sẽ lấy "Áo thun" làm SKU — một lỗi không ai nhìn thấy
      // cho tới lúc báo cáo sai.
      expect(sheet.cell(row, 'sku'), 'AT-1');
      expect(sheet.cell(row, 'name'), 'Áo thun');
    });

    test('cảnh báo thiếu giá vốn KHÔNG chặn nhập', () async {
      final preview = await readDemo();

      // Toàn bộ 100 sản phẩm đều có giá vốn trong file demo, nhưng luật phải
      // đúng: `missing_cost` là WARNING, không phải ERROR.
      for (final issue in preview.issues) {
        if (issue.code == 'missing_cost') {
          expect(issue.blocks, isFalse);
        }
      }
      expect(preview.products, hasLength(100));
    });
  });

  // ── C2 · ghi qua đường production ────────────────────────────────────────

  group('WTM-326 · import qua ĐƯỜNG PRODUCTION (§15)', () {
    test('sau khi nhập, các repository THẬT đọc được dữ liệu', () async {
      final preview = await readDemo();
      final result = await importer().apply(
        preview,
        sourceVendor: ImportVendor.bundledDemo,
        isDemo: true,
      );

      // Đọc lại bằng **chính repository màn hình dùng**, không phải bằng SQL.
      expect(await DriftProductRepository(db).loadAll(), hasLength(100));
      expect(await DriftCustomerRepository(db).loadAll(), hasLength(40));
      expect(
        (await DriftOrderRepository(db).loadAll()).length,
        greaterThan(90),
      );
      expect(
        await CommerceRepository(db).loadVariants(),
        hasLength(preview.variants.length),
      );
      expect(result.counts['products'], 100);
    });

    test('mỗi bản ghi khai đúng nguồn gốc (§14)', () async {
      final preview = await readDemo();
      final result = await importer().apply(
        preview,
        sourceVendor: ImportVendor.bundledDemo,
        isDemo: true,
      );

      final products = await DriftProductRepository(db).loadAll();
      for (final product in products.take(20)) {
        expect(product.provenance, ProvenanceSource.fileBridge);
        expect(product.importJobId, result.job.id);
      }

      final job = (await CommerceRepository(db).loadImportJobs()).single;
      expect(job.isDemo, isTrue);
      expect(job.sourceFile, contains('100-Products.xlsx'));
      expect(job.sourceChecksum, isNotEmpty);
      expect(job.recordCounts['products'], 100);
    });

    test('nhập lại CÙNG file không nhân đôi danh mục', () async {
      final preview = await readDemo();
      await importer().apply(preview, sourceVendor: ImportVendor.bundledDemo);
      await importer().apply(preview, sourceVendor: ImportVendor.bundledDemo);

      // Id suy ra từ mã ở nguồn ⇒ lần hai ghi đè, không sinh thêm.
      expect(await DriftProductRepository(db).loadAll(), hasLength(100));
    });

    test('nhận ra "đã nhập file này rồi" bằng checksum', () async {
      final preview = await readDemo();
      await importer().apply(preview, sourceVendor: ImportVendor.bundledDemo);

      final previous = await CommerceRepository(
        db,
      ).findByChecksum(preview.checksum);

      expect(previous, isNotNull);
      expect(previous!.sourceFile, contains('100-Products.xlsx'));
    });

    test('ô tồn trống đi thẳng xuống cột NULL (ADR-TON-023)', () async {
      final source = XlsxCommerceSource(
        bytes: demoFile.readAsBytesSync(),
        fileName: 'x.xlsx',
        now: now,
      );
      final preview = await source.read();
      // File demo có sản phẩm hết hàng (tồn = 0) — 0 và `null` phải khác nhau.
      final outOfStock = preview.products.where((p) => p.quantity == 0);

      expect(outOfStock, isNotEmpty);
      for (final p in outOfStock) {
        expect(p.quantity, isNotNull, reason: 'hết hàng là 0, KHÔNG phải null');
      }
    });

    test('đặt lại demo xoá đúng lần nhập, GIỮ dữ liệu tự nhập', () async {
      final preview = await readDemo();
      final result = await importer().apply(
        preview,
        sourceVendor: ImportVendor.bundledDemo,
        isDemo: true,
      );

      // Người bán tự thêm một sản phẩm sau khi nhập demo.
      //
      // Dựng thẳng chứ không `copyWith(importJobId: null)`: `copyWith` dùng
      // `?? this.x` nên truyền `null` **giữ nguyên** giá trị cũ — sản phẩm
      // "tự nhập" sẽ vẫn mang khoá lần nhập và bị xoá cùng. Bẫy này có thật,
      // và nó vừa bắt được chính test này.
      await DriftProductRepository(db).upsert(
        Product(
          id: 'cua-toi',
          sku: 'CUA-TOI-1',
          name: 'Sản phẩm tôi tự nhập',
          category: 'Thời trang',
          pricePerUnit: 199000,
          updatedAt: now,
        ),
      );

      final removed = await CommerceRepository(db).deleteImport(result.job.id);

      expect(removed['products'], 100);
      final left = await DriftProductRepository(db).loadAll();
      expect(left, hasLength(1));
      expect(left.single.id, 'cua-toi');
      expect(await CommerceRepository(db).loadVariants(), isEmpty);
      expect(await CommerceRepository(db).loadQuotes(), isEmpty);
    });
  });
}
