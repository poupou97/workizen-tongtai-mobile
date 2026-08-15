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
}
