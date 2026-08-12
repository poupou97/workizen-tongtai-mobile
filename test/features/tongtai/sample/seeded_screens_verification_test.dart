import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_business_seeder.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_history_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-344 — **bốn màn Founder yêu cầu kiểm, trên đúng bộ dữ liệu đã gieo.**
///
/// Kiểm trên máy thật là mục tiêu, nhưng máy đang cài kèm nhiều app khác và cú
/// chạm mù rơi sang app của Founder, nên phần còn lại được khoá ở đây: **cùng
/// một seeder production, cùng một cơ sở dữ liệu Drift**, rồi dựng chính các
/// màn đó lên và đọc thứ người bán đọc.
///
/// Hai điều được kiểm, đúng hai lỗi vừa sửa:
/// 1. **Không nhãn nào hiện chữ đếm bằng tiếng Anh** (`opportunities` /
///    `orders` / `customers`).
/// 2. **Không mốc nào ở tương lai** trong dữ liệu mà các màn này đọc.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  final now = DateTime(2026, 8, 10, 11, 30);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    final samples = SampleDataSeeder(
      customers: DriftCustomerRepository(db),
      products: DriftProductRepository(db),
      orders: DriftOrderRepository(db),
      goals: DriftBusinessGoalRepository(db),
      finance: DriftFinanceRepository(db),
    );
    await SampleBusinessSeeder(
      history: HistoricalDataSeeder(sampleSeeder: samples, clock: () => now),
      importer: CommerceImporter(
        database: db,
        products: DriftProductRepository(db),
        customers: DriftCustomerRepository(db),
        orders: DriftOrderRepository(db),
        settlements: DriftSettlementRepository(db),
        commerce: CommerceRepository(db),
        shipments: ShipmentRepository(db),
        now: () => now,
        newId: () => 'bundled',
      ),
      commerce: CommerceRepository(db),
      samples: samples,
      customers: DriftCustomerRepository(db),
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      bundledSource: () async => XlsxCommerceSource(
        bytes: File(
          'assets/demo/TongTai-Commerce-Demo-100-Products.xlsx',
        ).readAsBytesSync(),
        fileName: 'TongTai-Commerce-Demo-100-Products.xlsx',
        now: now,
      ),
    ).seed();
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget screen) async {
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
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: screen,
        ),
      ),
    );
  }

  /// Chữ đếm bằng tiếng Anh mà người bán Việt Nam không nên thấy.
  void expectNoEnglishCounts(WidgetTester tester) {
    for (final word in const ['opportunities', 'orders', 'customers']) {
      expect(
        find.textContaining(word),
        findsNothing,
        reason: 'màn tiếng Việt vẫn hiện chữ đếm tiếng Anh "$word"',
      );
    }
  }

  testWidgets('⭐ Cơ hội — đếm bằng tiếng Việt, và có cơ hội thật', (
    tester,
  ) async {
    await pump(tester, const TongtaiOpportunityFeedScreen());
    await pumpUntilFound(tester, find.textContaining('cơ hội'));

    expectNoEnglishCounts(tester);
    // Bộ mẫu phải sinh ra việc thật — nếu rỗng thì bài test này vô nghĩa.
    expect(find.text('0 cơ hội'), findsNothing);
  });

  testWidgets('⭐ Khách hàng — đếm bằng tiếng Việt', (tester) async {
    await pump(tester, const TongtaiCustomerListScreen());
    await pumpUntilFound(tester, find.textContaining('khách'));

    expectNoEnglishCounts(tester);
  });

  testWidgets('⭐ Trang chủ — dựng được trên dữ liệu đã gieo, không chữ Anh', (
    tester,
  ) async {
    await pump(tester, const TongtaiHomeScreen());
    // WTM-388: khối này đổi tên thành "Hành trình mục tiêu" — nó thôi nhận
    // mình là câu trả lời cho "hôm nay làm gì", vì câu đó nay chỉ có một chủ.
    await pumpUntilFound(
      tester,
      find.textContaining(AppStringsVi().homeTodaysMissions),
    );

    expectNoEnglishCounts(tester);
    // Thẻ đỏ của WTM-342 không được quay lại: brief phải dựng được.
    expect(find.byKey(const Key('home-brief-failed')), findsNothing);
  });

  testWidgets('⭐ Lịch sử mua hàng — đếm đơn bằng tiếng Việt', (tester) async {
    final customer = (await DriftCustomerRepository(db).loadAll()).firstWhere(
      (c) => c.orderCount > 0,
      orElse: () => (throw StateError('bộ mẫu phải có khách từng mua')),
    );

    await pump(tester, TongtaiCustomerHistoryScreen(customer: customer));
    await pumpUntilFound(tester, find.textContaining('đơn'));

    expectNoEnglishCounts(tester);
  });

  test('⭐ dữ liệu bốn màn đọc KHÔNG chứa mốc tương lai', () async {
    final orders = await DriftOrderRepository(db).loadAll();
    final finance = await DriftFinanceRepository(db).loadAll();
    final customers = await DriftCustomerRepository(db).loadAll();

    expect(orders, isNotEmpty);
    for (final o in orders) {
      expect(
        o.date.isAfter(now),
        isFalse,
        reason: 'đơn ${o.orderNumber} nằm ở tương lai (${o.date})',
      );
    }
    for (final t in finance) {
      expect(t.date.isAfter(now), isFalse, reason: 'thu chi ở tương lai');
    }
    for (final c in customers) {
      expect(
        c.lastPurchaseDate?.isAfter(now) ?? false,
        isFalse,
        reason: 'lần mua gần nhất của ${c.name} ở tương lai',
      );
    }
  });
}
