import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/simulation/demo_event_repository.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_business_life_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-338 · E2 — màn **Doanh nghiệp của bạn** (`IMPLEMENTATION_LEVEL=L3`).
///
/// WTM-346 gộp nó với dòng thời gian cũ: một màn, nhiều nguồn.
void main() {
  /// Cuộn tới khi widget tồn tại.
  ///
  /// Không dùng `scrollUntilVisible`: hàm đó gọi `.first` trên một finder chưa
  /// khớp gì và `Iterable.first` ném ngay, nên nó chỉ dùng được khi đã biết
  /// chắc widget tồn tại.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 40 && target.evaluate().isEmpty; i++) {
      await tester.drag(
        find.byKey(const Key('business-life-timeline')),
        const Offset(0, -300),
      );
      await tester.pump();
    }
  }

  late AppDatabase db;
  late SharedPreferences prefs;
  final anchor = DateTime(2026, 8, 9, 12);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

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

  Future<ProviderContainer> pumpLife(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        tongtaiDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: TongtaiBusinessLifeScreen(),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('business-life-start')));
    return container;
  }

  testWidgets('⭐ KHÔNG nhãn "dữ liệu là mẫu" — nhưng §40 vẫn nguyên', (
    tester,
  ) async {
    await pumpLife(tester);

    // ⚠️ WTM-430 — test này TRƯỚC ĐÂY khẳng định băng-rôn `DEMO` phải tồn tại,
    // viện dẫn §40. Founder chốt (lần thứ ba) là KHÔNG hiện nhãn nói dữ liệu là
    // mẫu: bản demo phải trông như thật.
    //
    // **Rekey, không xoá** (P-37). Bất biến §40 vẫn còn nguyên giá trị, chỉ là
    // nó không nằm ở cái băng-rôn ấy nữa:
    //
    //   * fake **dữ liệu** — được phép, Founder đã quyết;
    //   * fake **trạng thái kỹ thuật** — vẫn cấm tuyệt đối.
    //
    // Trên màn này, trạng thái kỹ thuật = *"bạn đang lái một trình mô phỏng và
    // đang ở ngày mấy"*. Nó hiện qua đồng hồ ở AppBar cộng ba nút đẩy thời
    // gian — không thể nhầm đây là một app đang chạy thật.
    expect(find.byKey(const Key('business-life-demo-banner')), findsNothing);
    expect(find.text('DEMO'), findsNothing);

    // Bằng chứng §40 còn sống: nút điều khiển trình mô phỏng vẫn ở đó, và người
    // dùng phải tự bấm mới có chuyện gì xảy ra.
    expect(find.byKey(const Key('business-life-start')), findsOneWidget);
  });

  testWidgets('chưa có danh mục ⇒ nói phải làm gì, không bịa sản phẩm', (
    tester,
  ) async {
    await pumpLife(tester);

    await tester.tap(find.byKey(const Key('business-life-start')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Nhập dữ liệu cửa hàng'), findsOneWidget);
  });

  testWidgets(
    '⭐ bắt đầu ⇒ dòng thời gian có việc, và ba chủ thể phân biệt được',
    (tester) async {
      await importCatalogue();
      await pumpLife(tester);

      await tester.tap(find.byKey(const Key('business-life-start')));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('business-life-timeline')),
      );

      expect(find.byKey(const Key('business-life-day')), findsOneWidget);
      // Ba chủ thể là NỘI DUNG của dòng thời gian, không phải chi tiết kỹ thuật.
      // Danh sách cuộn dựng lười, nên phải cuộn tới thì widget mới tồn tại.
      await scrollTo(tester, find.text('Shopee'));
      expect(find.text('Shopee'), findsWidgets);
      // Việc của Tổng Tài xảy ra ở ngày 1 nên nằm cuối danh sách (mới nhất
      // trước) — phải cuộn tới, `find.text` chỉ thấy widget đã dựng.
      //
      // Cuộn bằng tay chứ không `scrollUntilVisible`: hàm đó gọi `.first` trên
      // một finder chưa khớp gì và `Iterable.first` ném ngay, nên nó chỉ dùng
      // được khi đã biết chắc widget tồn tại.
      for (var i = 0; i < 30 && find.text('Tổng Tài').evaluate().isEmpty; i++) {
        await tester.drag(
          find.byKey(const Key('business-life-timeline')),
          const Offset(0, -300),
        );
        await tester.pump();
      }
      expect(find.text('Tổng Tài'), findsWidgets);

      final events = await DemoEventRepository(db).loadTimeline();
      expect(events, isNotEmpty);
    },
  );

  testWidgets('⭐ MỘT dòng thời gian: đơn thật và chuyện demo cùng chỗ', (
    tester,
  ) async {
    await importCatalogue();
    await pumpLife(tester);

    await tester.tap(find.byKey(const Key('business-life-start')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('business-life-timeline')),
    );

    // Bộ lọc theo loại áp cho **cả hai** nguồn — nếu demo có loại riêng thì
    // đây là chỗ vách ngăn cũ mọc lại.
    expect(find.byKey(const Key('business-life-filter-order')), findsOneWidget);
    expect(
      find.byKey(const Key('business-life-filter-customer')),
      findsOneWidget,
    );

    // Đơn THẬT (nhập từ Excel) nằm cùng dòng thời gian với chuyện demo.
    await scrollTo(tester, find.textContaining('DH-'));
    expect(find.textContaining('DH-'), findsWidgets);
  });

  testWidgets('⛔ cơ hội KHÔNG lên dòng thời gian', (tester) async {
    await importCatalogue();
    await pumpLife(tester);

    await tester.tap(find.byKey(const Key('business-life-start')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('business-life-timeline')),
    );

    // Cơ hội mang mốc `now` vì nó được suy ra lúc đọc, không xảy ra lúc nào
    // cả. Để nó vào đây là bốn mươi dòng "just now" dìm mất cả ngày thật.
    expect(
      find.byKey(const Key('business-life-filter-opportunity')),
      findsNothing,
    );
    expect(find.textContaining('Cơ hội:'), findsNothing);
  });

  testWidgets('Ngày tiếp đẩy thế giới đi và ĐƠN THẬT tăng lên', (tester) async {
    await importCatalogue();
    await pumpLife(tester);

    await tester.tap(find.byKey(const Key('business-life-start')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('business-life-next-day')),
    );
    final before = (await DriftOrderRepository(db).loadAll()).length;

    await tester.tap(find.byKey(const Key('business-life-next-day')));
    await tester.pumpAndSettle();

    // Đẩy đồng hồ phải đổi **miền thật**, không chỉ đổi một danh sách hiển thị.
    expect(
      (await DriftOrderRepository(db).loadAll()).length,
      greaterThan(before),
    );
  });

  testWidgets('Việc tiếp áp đúng MỘT việc', (tester) async {
    await importCatalogue();
    await pumpLife(tester);

    await tester.tap(find.byKey(const Key('business-life-start')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('business-life-next-event')),
    );
    final before = (await DemoEventRepository(
      db,
    ).loadTimeline(limit: 999)).length;

    await tester.tap(find.byKey(const Key('business-life-next-event')));
    await tester.pumpAndSettle();

    expect(
      (await DemoEventRepository(db).loadTimeline(limit: 999)).length,
      before + 1,
    );
  });

  testWidgets('bắt đầu lại ⇒ quay về nút Bắt đầu', (tester) async {
    await importCatalogue();
    await pumpLife(tester);

    await tester.tap(find.byKey(const Key('business-life-start')));
    await pumpUntilFound(tester, find.byKey(const Key('business-life-reset')));

    await tester.tap(find.byKey(const Key('business-life-reset')));
    await pumpUntilFound(tester, find.byKey(const Key('business-life-start')));

    expect(await DemoEventRepository(db).count(), 0);
    // ⚠️ Đơn đã sinh KHÔNG bị xoá — hai đường xoá, mỗi đường khai rõ phạm vi.
    expect(await DriftOrderRepository(db).loadAll(), isNotEmpty);
  });
}
