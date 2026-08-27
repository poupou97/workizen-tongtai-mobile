import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_import.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_source_resolver.dart';
import 'package:tongtai/features/tongtai/commerce/import/csv_reader.dart';
import 'package:tongtai/features/tongtai/commerce/import/marketplace_export_source.dart';
import 'package:tongtai/features/tongtai/commerce/import/marketplace_profile.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';

/// WTM-463 — bản xuat **products** thật của Shopify đi qua File Bridge.
///
/// ## File THẬT, không phải fixture dựng tay
///
/// `test/fixtures/shopify_products_export.csv` là bản xuất thật Founder đưa vào
/// (store demo "Nova Furniture"): 211 dòng · 73 cột · 35 sản phẩm · 132 biến
/// thể · 79 dòng chỉ-ảnh. Một fixture nhỏ chứng minh parser chạy; file thật
/// chứng minh **use-case** chạy — và WTM-463 sinh ra vì hai chuyện đó khác
/// nhau: catalog sản phẩm trước đây KHÔNG có đường vào.
///
/// ## Con số kiểm chứng (khớp audit trên vé)
///
/// 35 products · 132 variants · 79 dòng ảnh skip · tồn 6.696 · đúng 1 costPrice
/// có giá trị · 65 biến thể tồn=0 giữ **0 thật** (≠ null) · SKU thiếu 26/35 ·
/// giá vốn thiếu 131/132.
void main() {
  final now = DateTime(2026, 8, 27, 12);
  final fixture = File('test/fixtures/shopify_products_export.csv');
  final bytes = Uint8List.fromList(fixture.readAsBytesSync());

  Future<CommerceImportPreview> readProducts() => MarketplaceExportSource(
    bytes: bytes,
    fileName: 'shopify_products_export.csv',
    now: now,
    knownProducts: const [],
    reader: const CsvReader(),
  ).read();

  group('CsvReader — ô có ngoặc kép chứa xuống dòng + dấu phẩy', () {
    test(
      'gộp đúng bản ghi: 211 dòng dữ liệu, 73 cột, KHÔNG phải 517 dòng vật lý',
      () {
        // Cột `Body (HTML)` của Shopify chứa nhiều đoạn `<p>` mỗi đoạn một dòng —
        // 211 bản ghi trải trên 517 dòng vật lý. Một `split('\n')` ngây thơ sẽ
        // đọc thành 516 "dòng" rác. Máy trạng thái phải gộp lại.
        final sheets = const CsvReader().read(bytes);
        expect(sheets.length, 1);
        final rows = sheets.values.single;
        expect(rows.length, 212, reason: '1 tiêu đề + 211 bản ghi');
        expect(rows.first.length, 73);
        expect(rows.first.first, 'Handle');
        expect(rows.first.last, 'Status');
      },
    );

    test(
      'ô thoát "" thành một dấu " thật, xuống dòng trong ngoặc được giữ',
      () {
        final csv = 'a,b,c\n"x, y","he said ""hi""","line1\nline2"\n';
        final rows = const CsvReader().read(
          Uint8List.fromList(utf8.encode(csv)),
        );
        final data = rows.values.single;
        expect(data.length, 2);
        expect(data[1], ['x, y', 'he said "hi"', 'line1\nline2']);
      },
    );
  });

  group('nhận dạng — file products của Shopify', () {
    test('detect ra đúng (shopify, products), tự tin', () {
      final headers = const CsvReader().read(bytes).values.single.first;
      final match = MarketplaceMatch.detect(headers);
      expect(match, isNotNull);
      expect(match!.profile.vendor, 'shopify');
      expect(match.kind, MarketplaceFileKind.products);
      expect(match.isConfident, isTrue);
    });

    test('resolver ĐƯA được file .csv này tới MarketplaceExportSource', () async {
      // Đây là chứng minh lỗ WTM-463 đã vá THẬT: không chỉ parser chạy được mà
      // file còn TỚI được parser. `XlsxReader` ném ở byte đầu (không phải ZIP),
      // nên trước WTM-463 file rơi về bộ đọc danh mục và bị từ chối.
      final source = CommerceSourceResolver.resolve(
        bytes: bytes,
        fileName: 'shopify_products_export.csv',
        now: now,
        knownProducts: const [],
      );
      expect(source, isA<MarketplaceExportSource>());
      final preview = await source.read();
      expect(preview.products.length, 35);
    });
  });

  group('con số kiểm chứng trên file thật', () {
    late CommerceImportPreview preview;

    setUp(() async {
      preview = await readProducts();
    });

    test('35 sản phẩm · 132 biến thể', () {
      expect(preview.products.length, 35);
      expect(preview.variants.length, 132);
      expect(preview.counts['products'], 35);
      expect(preview.counts['variants'], 132);
    });

    test('79 dòng chỉ-ảnh bị bỏ qua nhưng ĐƯỢC ĐẾM và nói ra', () {
      final issue = preview.issues.firstWhere(
        (i) => i.code == 'image_rows_skipped',
      );
      expect(issue.detail, contains('79'));
      // Không đếm ảnh thành biến thể: 132 + 79 = 211 dòng dữ liệu.
      expect(preview.variants.length + 79, 211);
    });

    test('tổng tồn = 6.696 (cộng qua biến thể)', () {
      final total = preview.variants
          .map((v) => v.quantity ?? 0)
          .fold<double>(0, (a, b) => a + b);
      expect(total, 6696);
      // Tồn cấp sản phẩm = tổng biến thể ⇒ cộng qua sản phẩm cũng ra 6.696.
      final byProduct = preview.products
          .map((p) => (p.quantity ?? 0).toDouble())
          .fold<double>(0, (a, b) => a + b);
      expect(byProduct, 6696);
    });

    test('65 biến thể tồn=0 giữ 0 THẬT (≠ null)', () {
      final zero = preview.variants.where((v) => v.quantity == 0).toList();
      expect(zero.length, 65);
      // Không một biến thể tồn=0 nào bị biến thành null: 0 là câu trả lời, null
      // là im lặng (ADR-TON-022 áp cho tồn kho).
      for (final v in zero) {
        expect(v.quantity, isNotNull);
        expect(v.quantity, 0);
      }
      // Cả 132 biến thể đều có cột tồn ⇒ không cái nào null.
      expect(preview.variants.where((v) => v.quantity == null), isEmpty);
    });

    test(
      'đúng 1 costPrice có giá trị; 131 còn lại là null (KHÔNG rơi về 0)',
      () {
        final withCost = preview.variants
            .where((v) => v.costPrice != null)
            .toList();
        expect(withCost.length, 1);
        // Cái duy nhất KHÔNG null và KHÔNG 0.
        expect(withCost.single.costPrice, isNot(0));
        // 131 biến thể còn lại: costPrice là null, tuyệt đối không phải 0.
        final missing = preview.variants
            .where((v) => v.costPrice == null)
            .length;
        expect(missing, 131);
        expect(preview.variants.where((v) => v.costPrice == 0), isEmpty);

        // Sản phẩm mang cost (dòng tiêu đề của biến thể có cost) cũng đúng 1.
        expect(preview.products.where((p) => p.costPrice != null).length, 1);
      },
    );

    test('preview NÓI RA giá vốn thiếu 131/132 và SKU thiếu 26/35', () {
      final cost = preview.issues.firstWhere((i) => i.code == 'missing_cost');
      expect(cost.detail, contains('131/132'));

      final sku = preview.issues.firstWhere((i) => i.code == 'missing_sku');
      expect(sku.detail, contains('26/35'));
      // Đối chiếu: đúng 9 sản phẩm có SKU, 26 để trống (không bịa).
      expect(preview.products.where((p) => p.sku.isNotEmpty).length, 9);
      expect(preview.products.where((p) => p.sku.isEmpty).length, 26);
    });

    test('SKU trống ⇒ trống, KHÔNG bịa mã từ Handle/id', () {
      // Sản phẩm thiếu SKU giữ chuỗi RỖNG — không mượn Handle, id hay externalId
      // làm SKU giả (đó là cách "bịa" tinh vi nhất).
      for (final p in preview.products.where((p) => p.sku.isEmpty)) {
        expect(p.sku, '');
        expect(p.sku, isNot(p.externalId));
        expect(p.sku, isNot(p.id));
      }
      // Biến thể không có SKU cũng để trống, không lấy id kỹ thuật làm SKU.
      final blankSkuVariants = preview.variants
          .where((v) => v.sku.isEmpty)
          .toList();
      expect(blankSkuVariants, isNotEmpty);
      for (final v in blankSkuVariants) {
        expect(v.sku, isNot(v.id));
      }
    });

    test('tiền tệ không rõ ⇒ cảnh báo, KHÔNG tự quy đổi tỉ giá', () {
      final currency = preview.issues.firstWhere(
        (i) => i.code == 'currency_unknown',
      );
      expect(currency.level, ImportIssueLevel.warning);
    });

    test('mọi bản ghi tự khai nguồn File Bridge, id gom theo Handle', () {
      expect(
        preview.products.every(
          (p) => p.provenance == ProvenanceSource.fileBridge,
        ),
        isTrue,
      );
      expect(
        preview.products.every((p) => p.id.startsWith('mkt-shopify-')),
        isTrue,
      );
      // Biến thể trỏ về đúng sản phẩm của nó.
      final productIds = {for (final p in preview.products) p.id};
      expect(
        preview.variants.every((v) => productIds.contains(v.productId)),
        isTrue,
      );
    });

    test(
      'không có gì CHẶN — danh mục vẫn nhập được (chỉ cảnh báo/thông tin)',
      () {
        expect(preview.errors, isEmpty);
        expect(preview.hasAnythingToImport, isTrue);
      },
    );
  });

  group('semantics null-giữ-null trên CSV tối giản', () {
    Future<CommerceImportPreview> readCsv(String csv) =>
        MarketplaceExportSource(
          bytes: Uint8List.fromList(utf8.encode(csv)),
          fileName: 'mini.csv',
          now: now,
          knownProducts: const [],
          reader: const CsvReader(),
        ).read();

    // Bộ cột tối thiểu đủ để `detect` nhận ra hồ sơ products của Shopify.
    const header =
        'Handle,Title,Variant SKU,Variant Price,Cost per item,'
        'Variant Inventory Qty,Option1 Name,Option1 Value,Vendor,'
        'Product Category,Status,Image Src';

    test('Cost per item trống ⇒ costPrice null; tồn "0" ⇒ 0 thật', () async {
      final preview = await readCsv(
        '$header\n'
        'ghe-go,Ghế gỗ,,125.00,,0,Title,Default Title,Nova,Furniture,active,\n',
      );
      expect(preview.products.length, 1);
      expect(preview.variants.length, 1);
      final v = preview.variants.single;
      expect(v.costPrice, isNull);
      expect(v.quantity, 0);
      expect(v.quantity, isNotNull);
      expect(preview.products.single.costPrice, isNull);
    });

    test('dòng chỉ-ảnh (không giá) bị bỏ nhưng đếm', () async {
      final preview = await readCsv(
        '$header\n'
        'ghe-go,Ghế gỗ,SKU1,125.00,,3,Color,Đỏ,Nova,Furniture,active,\n'
        'ghe-go,,,,,,,,,,,https://cdn.shopify.com/a.jpg\n'
        'ghe-go,,SKU2,150.00,,2,Color,Xanh,Nova,Furniture,active,\n',
      );
      expect(preview.products.length, 1);
      expect(preview.variants.length, 2);
      final issue = preview.issues.firstWhere(
        (i) => i.code == 'image_rows_skipped',
      );
      expect(issue.detail, contains('1'));
    });
  });
}
