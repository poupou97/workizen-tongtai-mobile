import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/migrations/tongtai_migrations.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/export/backup_codec.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';

/// WTM-327 · C3 — miền thương mại chuẩn hoá (schema v24).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CommerceRepository repo;
  final now = DateTime(2026, 8, 9, 10);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = CommerceRepository(db);
  });

  tearDown(() => db.close());

  ImportJob job({
    String id = 'imp-1',
    bool isDemo = true,
    String? checksum = 'abc123',
  }) => ImportJob(
    id: id,
    source: ProvenanceSource.fileBridge,
    sourceVendor: ImportVendor.googleDrive,
    sourceFile: 'TongTai-Commerce-Demo-100-Products.xlsx',
    sourceChecksum: checksum,
    recordCounts: const {'products': 100, 'orders': 96},
    warnings: const ['3 dòng thiếu giá vốn'],
    isDemo: isDemo,
    importedAt: now,
  );

  Future<void> seedProduct(String id, {String? importJobId}) async {
    await db
        .into(db.productsTable)
        .insert(
          ProductsTableCompanion.insert(
            id: id,
            businessId: await const LocalWorkspace().ensureBusinessId(db),
            sku: 'SKU-$id',
            name: 'Sản phẩm $id',
            listPrice: 100000,
            importJobId: Value(importJobId),
            provenanceCode: Value(
              importJobId == null ? null : ProvenanceSource.fileBridge.code,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  group('lược đồ v24→v26', () {
    test('phiên bản hiện tại là 26', () {
      expect(kTongtaiSchemaVersion, 26);
      expect(db.schemaVersion, 26);
    });

    test('ba bảng mới tồn tại và có chỉ mục (P-32)', () async {
      // `Migrator.createTable()` KHÔNG tạo chỉ mục — bài học P-32. Một bảng
      // không chỉ mục vẫn "chạy được", nên không có gì đỏ; nó chỉ chậm dần khi
      // dữ liệu lớn lên, đúng lúc không ai còn nhớ vì sao.
      for (final table in const [
        'product_variants_table',
        'supplier_quotes_table',
        'import_jobs_table',
      ]) {
        final rows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
              variables: [Variable(table)],
            )
            .get();
        expect(rows, hasLength(1), reason: 'thiếu bảng $table');

        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
              variables: [Variable(table)],
            )
            .get();
        expect(
          indexes,
          isNotEmpty,
          reason: 'bảng $table không có chỉ mục nào — P-32',
        );
      }
    });

    test('products có năm cột nguồn ngoài', () async {
      final info = await db
          .customSelect("PRAGMA table_info('products_table')")
          .get();
      final names = info.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(const [
          'external_id',
          'provenance_code',
          'import_job_id',
          'brand',
          'image_url',
        ]),
      );
    });
  });

  group('nâng cấp từ v23 thật', () {
    test('dữ liệu v23 sống sót qua v24 · v25 · v26', () async {
      final dir = await Directory.systemTemp.createTemp('tongtai-v23-');
      final file = File('${dir.path}/tongtai.db');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });

      // Dựng một cơ sở dữ liệu v23 rồi ghi một sản phẩm vào.
      final old = AppDatabase.forExecutor(NativeDatabase(file));
      await old.customStatement('PRAGMA user_version');
      final businessId = await const LocalWorkspace().ensureBusinessId(old);
      await old
          .into(old.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              id: 'p-cu',
              businessId: businessId,
              sku: 'SKU-CU',
              name: 'Sản phẩm có trước v24',
              listPrice: 50000,
            ),
          );
      await old.customStatement('PRAGMA user_version = 23');
      await old.close();

      // Mở lại: migration v23 → v24 phải chạy và không mất gì.
      final upgraded = AppDatabase.forExecutor(NativeDatabase(file));
      final products = await upgraded.select(upgraded.productsTable).get();
      addTearDown(upgraded.close);

      expect(products, hasLength(1));
      expect(products.single.name, 'Sản phẩm có trước v24');
      // Dòng có trước v24 **không** mang provenance — suy ra, không đoán.
      expect(products.single.provenanceCode, isNull);
      expect(products.single.importJobId, isNull);

      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.first, 26);
    });
  });

  group('lần nhập là một bản ghi', () {
    test('ghi rồi đọc lại giữ nguyên số đếm và cảnh báo', () async {
      await repo.saveImportJob(job());

      final loaded = (await repo.loadImportJobs()).single;

      expect(loaded.source, ProvenanceSource.fileBridge);
      expect(loaded.sourceFile, contains('100-Products.xlsx'));
      expect(loaded.recordCounts['products'], 100);
      expect(loaded.warnings, ['3 dòng thiếu giá vốn']);
      expect(loaded.isDemo, isTrue);
      expect(loaded.totalRecords, 196);
    });

    test('tìm lại bằng CHECKSUM, không bằng tên file', () async {
      await repo.saveImportJob(job());

      // Người bán đổi tên file rồi nhập lại — vẫn là cùng dữ liệu.
      expect(await repo.findByChecksum('abc123'), isNotNull);
      expect(await repo.findByChecksum('khac'), isNull);
    });

    test('mã nguồn lạ ⇒ bỏ dòng, không rơi về mặc định', () async {
      await repo.saveImportJob(job());
      await db.customStatement(
        "UPDATE import_jobs_table SET source_code = 'khong_biet'",
      );

      expect(await repo.loadImportJobs(), isEmpty);
    });
  });

  group('phiên bản sản phẩm', () {
    test('giá null nghĩa là KẾ THỪA, không phải miễn phí', () {
      const variant = ProductVariant(
        id: 'v1',
        productId: 'p1',
        name: 'Đen / S',
        sku: 'AO-DEN-S',
      );

      expect(variant.effectiveSellingPrice(250000), 250000);
      expect(variant.effectiveCostPrice(150000), 150000);
      // Cả hai chưa biết ⇒ `null`, KHÔNG rơi về 0: 0 đồng là một câu trả lời
      // sai chứ không phải im lặng.
      expect(variant.effectiveSellingPrice(null), isNull);
    });

    test('ghi rồi đọc lại giữ nguyên hai lựa chọn', () async {
      await seedProduct('p1');
      await repo.upsertVariants([
        ProductVariant(
          id: 'v1',
          productId: 'p1',
          name: 'Đen / S',
          sku: 'AO-DEN-S',
          option1Name: 'Màu',
          option1Value: 'Đen',
          option2Name: 'Size',
          option2Value: 'S',
          quantity: 12,
          provenance: ProvenanceSource.fileBridge,
          importJobId: 'imp-1',
        ),
      ]);

      final loaded = (await repo.loadVariants(productId: 'p1')).single;

      expect(loaded.option1Value, 'Đen');
      expect(loaded.option2Value, 'S');
      expect(loaded.provenance, ProvenanceSource.fileBridge);
    });

    test('xoá sản phẩm là xoá phiên bản của nó', () async {
      await seedProduct('p1');
      await repo.upsertVariants([
        const ProductVariant(
          id: 'v1',
          productId: 'p1',
          name: 'Đen / S',
          sku: 'AO-DEN-S',
        ),
      ]);

      await (db.delete(db.productsTable)..where((t) => t.id.equals('p1'))).go();

      expect(await repo.loadVariants(), isEmpty);
    });
  });

  group('báo giá nhà cung cấp', () {
    test('báo giá KHÔNG cần nhà cung cấp có sẵn trong sổ', () async {
      await seedProduct('p1');
      await repo.upsertQuotes([
        SupplierQuote(
          id: 'q1',
          productId: 'p1',
          supplierName: 'Xưởng Quảng Châu A',
          unitCost: 82000,
          quotedAt: now,
          platform: SupplierPlatform.taobao1688,
          sourceUrl: 'https://detail.1688.com/offer/123.html',
        ),
      ]);

      final loaded = (await repo.loadQuotes(productId: 'p1')).single;

      expect(loaded.supplierId, isNull);
      expect(loaded.supplierName, 'Xưởng Quảng Châu A');
      expect(loaded.platform, SupplierPlatform.taobao1688);
    });

    test('nền tảng lạ ⇒ null, KHÔNG rơi về nguồn trong nước', () {
      // Một nguồn Trung Quốc hiện thành nguồn trong nước sẽ làm người bán tính
      // sai cả lead time lẫn thuế.
      expect(SupplierPlatform.fromCode('shopee_mall'), isNull);
      expect(SupplierPlatform.fromCode(null), isNull);
      expect(SupplierPlatform.fromCode('1688'), SupplierPlatform.taobao1688);
    });

    test('lead time null = CHƯA BIẾT, đọc lại vẫn null', () async {
      await seedProduct('p1');
      await repo.upsertQuotes([
        SupplierQuote(
          id: 'q1',
          productId: 'p1',
          supplierName: 'Chưa rõ giao bao lâu',
          unitCost: 90000,
          quotedAt: now,
        ),
      ]);

      final loaded = (await repo.loadQuotes()).single;

      expect(loaded.leadTimeDays, isNull);
      expect(loaded.rating, isNull);
      expect(loaded.minimumOrderQuantity, isNull);
    });

    test('báo giá cũ đếm được tuổi', () {
      final quote = SupplierQuote(
        id: 'q1',
        productId: 'p1',
        supplierName: 'A',
        unitCost: 1,
        quotedAt: now.subtract(const Duration(days: 90)),
      );

      expect(quote.daysOldAt(now), 90);
    });
  });

  group('xoá theo PHẠM VI (§22)', () {
    test('xoá một lần nhập KHÔNG đụng dữ liệu người bán tự tạo', () async {
      await repo.saveImportJob(job());
      await seedProduct('p-nhap', importJobId: 'imp-1');
      await seedProduct('p-tu-nhap'); // không thuộc lần nhập nào
      await repo.upsertVariants([
        const ProductVariant(
          id: 'v1',
          productId: 'p-nhap',
          name: 'Đen / S',
          sku: 'A',
          importJobId: 'imp-1',
        ),
      ]);
      await repo.upsertQuotes([
        SupplierQuote(
          id: 'q1',
          productId: 'p-nhap',
          supplierName: 'A',
          unitCost: 1,
          quotedAt: now,
          importJobId: 'imp-1',
        ),
      ]);

      final removed = await repo.deleteImport('imp-1');

      expect(removed['products'], 1);
      expect(removed['variants'], 1);
      expect(removed['quotes'], 1);

      final left = await db.select(db.productsTable).get();
      expect(left.map((p) => p.id).toList(), ['p-tu-nhap']);
      expect(await repo.loadImportJobs(), isEmpty);
    });

    test('xoá lần nhập A không đụng lần nhập B', () async {
      await repo.saveImportJob(job(id: 'imp-A', checksum: 'a'));
      await repo.saveImportJob(job(id: 'imp-B', checksum: 'b'));
      await seedProduct('pA', importJobId: 'imp-A');
      await seedProduct('pB', importJobId: 'imp-B');

      await repo.deleteImport('imp-A');

      final left = await db.select(db.productsTable).get();
      expect(left.map((p) => p.id).toList(), ['pB']);
      expect((await repo.loadImportJobs()).single.id, 'imp-B');
    });
  });

  group('sống sót qua .ttbk (ADR-TON-018)', () {
    test('phiên bản và báo giá đi tròn một vòng, KHÔNG mất', () {
      final variant = ProductVariant(
        id: 'v1',
        productId: 'p1',
        name: 'Đen / S',
        sku: 'AO-DEN-S',
        option1Name: 'Màu',
        option1Value: 'Đen',
        quantity: 12,
        provenance: ProvenanceSource.fileBridge,
        importJobId: 'imp-1',
      );
      final quote = SupplierQuote(
        id: 'q1',
        productId: 'p1',
        supplierName: 'Xưởng A',
        unitCost: 82000,
        quotedAt: now,
        platform: SupplierPlatform.taobao1688,
        provenance: ProvenanceSource.fileBridge,
        importJobId: 'imp-1',
      );

      final v = BackupCodec.decodeProductVariant(
        BackupCodec.encodeProductVariant(variant),
      )!;
      final q = BackupCodec.decodeSupplierQuote(
        BackupCodec.encodeSupplierQuote(quote),
      )!;

      expect(v.option1Value, 'Đen');
      expect(v.provenance, ProvenanceSource.fileBridge);
      expect(v.importJobId, 'imp-1');
      expect(q.platform, SupplierPlatform.taobao1688);
      expect(q.unitCost, 82000);
    });

    test('null KHÔNG biến thành 0 qua một vòng backup', () {
      // Nếu restore biến `null` thành 0 thì: mọi phiên bản bán 0 đồng, và mọi
      // nguồn "giao ngay hôm nay". Hai lời nói dối, một dòng code.
      const variant = ProductVariant(
        id: 'v1',
        productId: 'p1',
        name: 'x',
        sku: 'x',
      );
      final quote = SupplierQuote(
        id: 'q1',
        productId: 'p1',
        supplierName: 'A',
        unitCost: 1,
        quotedAt: now,
      );

      final v = BackupCodec.decodeProductVariant(
        BackupCodec.encodeProductVariant(variant),
      )!;
      final q = BackupCodec.decodeSupplierQuote(
        BackupCodec.encodeSupplierQuote(quote),
      )!;

      expect(v.sellingPrice, isNull);
      expect(v.quantity, isNull);
      expect(q.leadTimeDays, isNull);
      expect(q.rating, isNull);
      expect(q.minimumOrderQuantity, isNull);
    });

    test('lần nhập giữ nguyên số đếm, cảnh báo và cờ demo', () {
      final decoded = BackupCodec.decodeImportJob(
        BackupCodec.encodeImportJob(job()),
      )!;

      expect(decoded.recordCounts['products'], 100);
      expect(decoded.warnings, ['3 dòng thiếu giá vốn']);
      expect(decoded.isDemo, isTrue);
      expect(decoded.source, ProvenanceSource.fileBridge);
    });

    test('mã nguồn lạ ⇒ BỎ lần nhập, không đoán', () {
      final raw = BackupCodec.encodeImportJob(job())..['source'] = 'khong_biet';

      // Một lần nhập không biết từ đâu tới vẫn sẽ được dùng làm phạm vi xoá.
      // Đoán ở đây là đoán về việc xoá cái gì.
      expect(BackupCodec.decodeImportJob(raw), isNull);
    });

    test('sản phẩm giữ được liên kết tới lần nhập sinh ra nó', () {
      final product = Product(
        id: 'p1',
        sku: 'SKU-1',
        name: 'Áo thun',
        category: 'Thời trang',
        pricePerUnit: 250000,
        updatedAt: now,
        externalId: 'ROW-1',
        brand: 'Local',
        imageUrl: 'https://example.com/a.jpg',
        provenance: ProvenanceSource.fileBridge,
        importJobId: 'imp-1',
      );

      final decoded = BackupCodec.decodeProduct(
        BackupCodec.encodeProduct(product),
      )!;

      // Thiếu chỗ này thì khôi phục xong "Đặt lại dữ liệu demo" không tìm thấy
      // gì để xoá — đúng hình dạng lỗ hổng WTM-211.
      expect(decoded.importJobId, 'imp-1');
      expect(decoded.provenance, ProvenanceSource.fileBridge);
      expect(decoded.externalId, 'ROW-1');
      expect(decoded.imageUrl, 'https://example.com/a.jpg');
    });
  });
}
