import 'dart:io';
import 'dart:typed_data';

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

  testWidgets('bộ dữ liệu mẫu đóng gói sẵn nhập được, không cần file ngoài', (
    tester,
  ) async {
    await pumpImport(tester);

    final demo = find.byKey(const Key('import-use-demo'));
    await reveal(tester, demo);
    await tester.tap(demo);
    await pumpUntilFound(tester, find.byKey(const Key('import-preview')));

    final confirm = find.byKey(const Key('import-confirm'));
    await reveal(tester, confirm);
    await tester.tap(confirm);
    await pumpUntilFound(tester, find.byKey(const Key('import-result')));

    expect(await DriftProductRepository(db).loadAll(), hasLength(100));
    // Cờ demo nằm ở **lần nhập**, không ở từng dòng.
    expect(
      (await CommerceRepository(db).loadImportJobs()).single.isDemo,
      isTrue,
    );
  });
}
