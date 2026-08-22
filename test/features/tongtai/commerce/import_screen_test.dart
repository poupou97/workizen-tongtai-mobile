import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/core/design/tt.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_import_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-326 · màn **Nhập dữ liệu cửa hàng** (`IMPLEMENTATION_LEVEL=L3`).
void main() {
  late AppDatabase db;

  final demoBytes = File(
    'assets/demo/TongTai-Commerce-Demo-100-Products.xlsx',
  ).readAsBytesSync();

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<ProviderContainer> pumpImport(
    WidgetTester tester, {
    Future<PickedImportFile?> Function()? pickFile,
  }) async {
    final container = ProviderContainer(
      overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiImportScreen(pickFile: pickFile),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('import-list')));
    return container;
  }

  /// Dựng một `.xlsx` danh mục tối giản (sheet `PRODUCTS`) trong bộ nhớ.
  ///
  /// Khuôn mượn từ `marketplace_file_bridge_test.dart` — cùng lý do: mỗi test
  /// cần một bộ dữ liệu khác nhau, và mười file fixture trên đĩa thì không ai
  /// đọc nổi cái nào khác cái nào.
  Uint8List productsXlsx(List<List<String>> rows) {
    String cell(String v, int col, int row) {
      final letter = String.fromCharCode(65 + col);
      final escaped = v
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      return '<c r="$letter$row" t="inlineStr"><is><t>$escaped</t></is></c>';
    }

    final sheetRows = [
      for (var r = 0; r < rows.length; r++)
        '<row r="${r + 1}">'
            '${[for (var c = 0; c < rows[r].length; c++) cell(rows[r][c], c, r + 1)].join()}'
            '</row>',
    ];

    final archive = Archive();
    void add(String name, String content) {
      // `utf8.encode`, KHÔNG `codeUnits` — `codeUnits` là UTF-16 và mọi chữ có
      // dấu sẽ hỏng, rồi test đỏ vì một lý do không liên quan gì tới màu sắc.
      final data = utf8.encode(content);
      archive.addFile(ArchiveFile(name, data.length, data));
    }

    add(
      '[Content_Types].xml',
      '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/'
          'package/2006/content-types"/>',
    );
    add(
      'xl/workbook.xml',
      '<?xml version="1.0"?><workbook><sheets>'
          '<sheet name="PRODUCTS" sheetId="1"/></sheets></workbook>',
    );
    add(
      'xl/worksheets/sheet1.xml',
      '<?xml version="1.0"?><worksheet><sheetData>'
          '${sheetRows.join()}</sheetData></worksheet>',
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Như [productsXlsx] nhưng sheet mang **tên khác** — dùng để dựng một file
  /// sàn lạ: không sheet `PRODUCTS`, không bí danh cột nào của sáu hồ sơ.
  Uint8List strangeXlsx(List<List<String>> rows) {
    final bytes = productsXlsx(rows);
    final archive = ZipDecoder().decodeBytes(bytes);
    final out = Archive();
    for (final f in archive.files) {
      if (f.name == 'xl/workbook.xml') {
        final data = utf8.encode(
          '<?xml version="1.0"?><workbook><sheets>'
          '<sheet name="Sheet1" sheetId="1"/></sheets></workbook>',
        );
        out.addFile(ArchiveFile(f.name, data.length, data));
      } else {
        out.addFile(f);
      }
    }
    return Uint8List.fromList(ZipEncoder().encode(out));
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('mở màn: chưa có gì để nhập, chưa có lịch sử', (tester) async {
    await pumpImport(tester);

    expect(find.byKey(const Key('import-preview')), findsNothing);
    expect(find.byKey(const Key('import-history-empty')), findsOneWidget);
  });

  testWidgets('chọn nhầm file ⇒ nói một câu người dùng hiểu, KHÔNG ghi gì', (
    tester,
  ) async {
    await pumpImport(
      tester,
      pickFile: () async => PickedImportFile(
        name: 'anh-san-pham.jpg',
        bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]),
      ),
    );

    final pick = find.byKey(const Key('import-pick-file'));
    await reveal(tester, pick);
    await tester.tap(pick);
    await pumpUntilFound(tester, find.byKey(const Key('import-preview')));

    // Xem trước vẫn hiện — nhưng nói ra vấn đề, và nút nhập tắt.
    final errors = find.byKey(const Key('import-preview-errors'));
    await reveal(tester, errors);
    expect(errors, findsOneWidget);

    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('import-confirm')),
    );
    expect(confirm.onPressed, isNull);
    expect(await DriftProductRepository(db).loadAll(), isEmpty);
  });

  testWidgets('WTM-424 · khối LỖI đỏ, khối CẢNH BÁO vàng — KHÔNG cam', (
    tester,
  ) async {
    // Cổng §3c của ratchet DS là cổng **cú pháp**: nó cấm `Colors.orange`, chứ
    // không cấm ai đó truyền `TtStatus.danger` cho khối cảnh báo hay
    // `TtColors.brand` cho khối lỗi. Chỗ hỏng thật nằm ở **màu nhìn thấy**, nên
    // phải có một khẳng định đọc đúng thứ mắt người đọc.
    //
    // Bản trước tô khối cảnh báo bằng `Colors.orange`. Theo luật màu Founder,
    // **cam = Brand/Primary Action** — chỗ đang báo có vấn đề lại đọc ra
    // *"bấm vào đây"*.
    // Bộ demo 100 sản phẩm **sạch** — không sinh cảnh báo nào, nên nó không
    // dùng được ở đây. Dựng một file một dòng thiếu giá vốn: đó đúng là
    // `missing_cost`, một CẢNH BÁO thật (bán được, chỉ chưa tính được lời).
    await pumpImport(
      tester,
      pickFile: () async => PickedImportFile(
        name: 'thieu-gia-von.xlsx',
        bytes: productsXlsx([
          ['sku', 'name', 'selling_price', 'cost_price', 'quantity'],
          ['SKU-1', 'Áo thun', '150000', '', '10'],
        ]),
      ),
    );

    final pick = find.byKey(const Key('import-pick-file'));
    await reveal(tester, pick);
    await tester.tap(pick);
    await pumpUntilFound(tester, find.byKey(const Key('import-preview')));

    final warnings = find.byKey(const Key('import-preview-warnings'));
    await reveal(tester, warnings);
    expect(
      warnings,
      findsOneWidget,
      reason:
          'thiếu giá vốn PHẢI là cảnh báo — nếu nó thành lỗi hoặc biến mất thì '
          'test này mất đối tượng, phải sửa dữ liệu chứ KHÔNG bỏ khẳng định',
    );

    // Dòng đầu của khối là tiêu đề — chính chỗ mang màu.
    final headline = tester.widget<Text>(
      find.descendant(of: warnings, matching: find.byType(Text)).first,
    );
    expect(
      headline.style?.color,
      TtColors.warning,
      reason: 'cảnh báo phải VÀNG',
    );
    expect(
      headline.style?.color,
      isNot(TtColors.brand),
      reason: 'CAM là Brand/Primary Action — không bao giờ là cảnh báo',
    );
  });

  testWidgets('trọn chuỗi: xem trước 100 sản phẩm → nhập → bỏ lần nhập', (
    tester,
  ) async {
    await pumpImport(
      tester,
      pickFile: () async => PickedImportFile(
        name: 'TongTai-Commerce-Demo-100-Products.xlsx',
        bytes: demoBytes,
      ),
    );

    // ── xem trước ──────────────────────────────────────────────────────
    final pick = find.byKey(const Key('import-pick-file'));
    await reveal(tester, pick);
    await tester.tap(pick);
    await pumpUntilFound(tester, find.byKey(const Key('import-preview')));

    final headline = find.byKey(const Key('import-preview-products'));
    await reveal(tester, headline);
    expect(
      tester.widget<Text>(headline).data,
      '100 sản phẩm đã sẵn sàng',
      reason: 'ngôn ngữ nghiệp vụ, không phải "parsed 100 rows" (§27)',
    );
    // Chưa ghi gì cả — người bán mới chỉ *nhìn*.
    expect(await DriftProductRepository(db).loadAll(), isEmpty);

    // ── nhập ───────────────────────────────────────────────────────────
    final confirm = find.byKey(const Key('import-confirm'));
    await reveal(tester, confirm);
    await tester.tap(confirm);
    await pumpUntilFound(tester, find.byKey(const Key('import-result')));

    expect(await DriftProductRepository(db).loadAll(), hasLength(100));
    final job = (await CommerceRepository(db).loadImportJobs()).single;
    expect(job.sourceFile, contains('100-Products.xlsx'));

    // ── bỏ lần nhập ────────────────────────────────────────────────────
    final undo = find.byKey(Key('import-undo-${job.id}'));
    await pumpUntilFound(tester, undo);
    await reveal(tester, undo);
    await tester.tap(undo);
    await tester.pumpAndSettle();

    expect(await DriftProductRepository(db).loadAll(), isEmpty);
    expect(await CommerceRepository(db).loadImportJobs(), isEmpty);
  });

  testWidgets('⛔ màn này chỉ nhận file CỦA NGƯỜI BÁN — WTM-343', (
    tester,
  ) async {
    await pumpImport(tester);

    // Bộ 100 sản phẩm là **dữ liệu mẫu**, và dữ liệu mẫu có đúng một chủ:
    // "Nạp dữ liệu mẫu" trong Thêm. Hai lối vào cho một khái niệm là hai chỗ
    // để chọn nhầm (P-27). Vòng đời của bộ đóng kèm được kiểm ở
    // `test/features/tongtai/sample/sample_business_seeder_test.dart`.
    expect(find.byKey(const Key('import-use-demo')), findsNothing);
    expect(find.byKey(const Key('import-pick-file')), findsOneWidget);
  });

  // ── WTM-443 · người bán tự chỉ cột ───────────────────────────────────────

  group('WTM-443 · bước ghép cột', () {
    const strangeRows = [
      ['Ma_Don', 'Ma_Hang', 'SL', 'Don_Gia'],
      ['DH-1', 'TT-001', '2', '250000'],
    ];

    Future<ProviderContainer> pumpStrangeFile(WidgetTester tester) =>
        pumpImport(
          tester,
          pickFile: () async => PickedImportFile(
            name: 'sanla.xlsx',
            bytes: strangeXlsx(strangeRows),
          ),
        );

    testWidgets('⭐ file chưa hiểu ⇒ MỜI ghép cột, không dừng ở lời từ chối', (
      tester,
    ) async {
      await pumpStrangeFile(tester);
      await tester.tap(find.byKey(const Key('import-pick-file')));
      await pumpUntilFound(tester, find.byKey(const Key('import-column-map')));

      expect(find.byKey(const Key('import-column-map')), findsOneWidget);
      // Bốn vai trò BẮT BUỘC của file đơn phải có ô chọn.
      for (final f in const ['orderId', 'sku', 'quantity', 'unitPrice']) {
        expect(
          find.byKey(Key('import-column-map-field-$f')),
          findsOneWidget,
          reason: 'thiếu ô chọn cho vai trò bắt buộc $f',
        );
      }
    });

    testWidgets('⭐ WTM-446 · KHÔNG hiện thẻ ngõ cụt cùng lúc với lời mời', (
      tester,
    ) async {
      // Tìm ra trên S24 của Founder, lượt thử đầu tiên. Màn hình nói hai điều
      // trái ngược theo đúng thứ tự tệ nhất:
      //   trên → "Không có gì để nhập từ file này."  (ngõ cụt)
      //   dưới → "Chỉ giúp cột nào là cột nào…"      (phải cuộn mới thấy)
      // Người ta đọc từ trên xuống, gặp ngõ cụt, đóng app.
      // ⚠️ Màn cao BẤT THƯỜNG, cố ý. `ListView` dựng LƯỜI: thẻ nằm ngoài
      // vùng nhìn thì **không được dựng**, nên `findsNothing` sẽ xanh kể cả
      // khi thẻ vẫn còn nguyên trong code. Bản đầu của test này chính là một
      // cổng giả như vậy — đột biến "hiện lại cả hai thẻ" vẫn xanh.
      //
      // Cho toàn bộ nội dung nằm trong vùng nhìn thì `findsNothing` mới trả
      // lời đúng câu ta đang hỏi.
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpStrangeFile(tester);
      await tester.tap(find.byKey(const Key('import-pick-file')));
      await pumpUntilFound(tester, find.byKey(const Key('import-column-map')));

      expect(find.byKey(const Key('import-preview')), findsNothing);
      expect(find.textContaining('PRODUCTS'), findsNothing);
    });

    testWidgets('⭐ WTM-446 · file danh mục hỏng THẬT vẫn báo lỗi cũ', (
      tester,
    ) async {
      // Chiều ngược lại của cùng cổng. Sửa bằng cách đổi thứ tự ưu tiên chứ
      // KHÔNG đổi câu chữ — câu lỗi kia vẫn đúng khi người bán đưa vào một
      // file danh mục thật sự hỏng (có sheet PRODUCTS nhưng thiếu cột).
      await pumpImport(
        tester,
        pickFile: () async => PickedImportFile(
          name: 'danhmuc-hong.xlsx',
          bytes: productsXlsx(const [
            ['sku', 'ten'],
            ['TT-001', 'Áo thun'],
          ]),
        ),
      );
      await tester.tap(find.byKey(const Key('import-pick-file')));
      await pumpUntilFound(tester, find.byKey(const Key('import-preview')));

      expect(find.byKey(const Key('import-column-map')), findsNothing);
      expect(find.byKey(const Key('import-preview-errors')), findsOneWidget);
    });

    testWidgets('⭐ chưa ghép đủ vai trò bắt buộc ⇒ nút lưu BỊ CHẶN', (
      tester,
    ) async {
      await pumpStrangeFile(tester);
      await tester.tap(find.byKey(const Key('import-pick-file')));
      await pumpUntilFound(tester, find.byKey(const Key('import-column-map')));

      // Nhập nửa vời tệ hơn không nhập: một đơn không có mã thì lần nhập sau
      // đếm nó lần nữa.
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('import-column-map-save')),
      );
      expect(save.onPressed, isNull);
      expect(
        find.byKey(const Key('import-column-map-missing')),
        findsOneWidget,
      );
    });

    testWidgets('⭐ ghép đủ ⇒ đọc lại được và ra ĐƠN HÀNG', (tester) async {
      // Gieo sẵn sản phẩm để SKU khớp. Không gieo thì đơn bị chặn vì
      // `sku_not_found` — hành vi ĐÚNG, nhưng lúc ấy test chỉ chứng minh
      // "thẻ ghép cột biến mất", không chứng minh "đọc ra đơn hàng". Tên test
      // hứa vế thứ hai nên nó phải kiểm vế thứ hai (P-45).
      await DriftProductRepository(db).upsert(
        Product(
          id: 'p1',
          sku: 'TT-001',
          name: 'Áo thun cotton',
          category: 'Thời trang',
          pricePerUnit: 250000,
          costPrice: 120000,
          updatedAt: DateTime(2026, 8, 9),
        ),
      );

      await pumpStrangeFile(tester);
      await tester.tap(find.byKey(const Key('import-pick-file')));
      await pumpUntilFound(tester, find.byKey(const Key('import-column-map')));

      Future<void> choose(String field, String column) async {
        await reveal(tester, find.byKey(Key('import-column-map-field-$field')));
        await tester.tap(find.byKey(Key('import-column-map-field-$field')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(column).last);
        await tester.pumpAndSettle();
      }

      await choose('orderId', 'Ma_Don');
      await choose('sku', 'Ma_Hang');
      await choose('quantity', 'SL');
      await choose('unitPrice', 'Don_Gia');

      await reveal(tester, find.byKey(const Key('import-column-map-save')));
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('import-column-map-save')),
      );
      expect(save.onPressed, isNotNull, reason: 'ghép đủ rồi mà vẫn chặn');

      await tester.tap(find.byKey(const Key('import-column-map-save')));
      await tester.pumpAndSettle();

      // Thẻ ghép cột biến mất ⇒ file đã được đọc lại và đã hiểu.
      expect(find.byKey(const Key('import-column-map')), findsNothing);
      // Và nó thật sự ra ĐƠN, không phải chỉ "hết lỗi". Đọc lại đi qua ĐÚNG
      // đường thật — không có nhánh tắt cho file đã ghép tay — nên mọi luật
      // cũ (khớp SKU, chống trùng, cảnh báo thiếu báo cáo thu nhập) vẫn chạy.
      await reveal(tester, find.byKey(const Key('import-preview')));
      expect(find.textContaining('1 đơn'), findsWidgets);
    });
  });
}
