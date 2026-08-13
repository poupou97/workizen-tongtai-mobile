import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_create_order_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart'
    show kSampleCustomers;
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart'
    show kSampleProducts;

/// **WTM-399 — thứ tự đọc có phụ thuộc chiều cao màn hình không?**
///
/// Bản audit WTM-277 Option C kết luận *"thứ tự đọc sạch"*, nhưng nó dựng màn ở
/// `1080×2160` (**823 dp**) và gọi đó là kích thước Nokia. Nokia 6.1 là 16:9 —
/// **731 dp**. Rộng đúng, cao sai 92 dp.
///
/// Kết luận cũ **có thể** vẫn đúng; đây là chỗ biến "có thể" thành một phép đo.
/// Màn cao hơn chứa nhiều nội dung hơn trước khi phải cuộn, nên về nguyên tắc
/// một danh sách bị cắt ở chiều cao thật có thể đọc khác đi.
///
/// So **trực tiếp hai chiều cao trong một lần chạy** thay vì đối chiếu với mấy
/// tệp dump cũ: dump cũ mang rect của chiều cao sai, nên so text sẽ khác nhau vì
/// toạ độ chứ không vì thứ tự — một khác biệt vô nghĩa che mất khác biệt có
/// nghĩa.
///
/// Thứ được so là **chuỗi nhãn theo thứ tự duyệt** — đúng thứ TalkBack đọc ra.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryCustomerRepository customerRepo;
  late InMemoryProductRepository productRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryBusinessGoalRepository goalRepo;
  late InMemoryFinanceRepository financeRepo;
  AppDatabase? sharedDb;
  AppDatabase memoryDb() =>
      sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());

  tearDown(() async {
    await sharedDb?.close();
    sharedDb = null;
  });

  setUp(() {
    customerRepo = InMemoryCustomerRepository();
    productRepo = InMemoryProductRepository([]);
    orderRepo = InMemoryOrderRepository();
    goalRepo = InMemoryBusinessGoalRepository();
    financeRepo = InMemoryFinanceRepository();
    SharedPreferences.setMockInitialValues({});
  });

  SampleDataSeeder seeder() => SampleDataSeeder(
    customers: customerRepo,
    products: productRepo,
    orders: orderRepo,
    goals: goalRepo,
    finance: financeRepo,
  );

  Future<Widget> host(Widget screen) async => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      customerRepositoryProvider.overrideWithValue(customerRepo),
      productRepositoryProvider.overrideWithValue(productRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
      businessGoalRepositoryProvider.overrideWithValue(goalRepo),
      financeRepositoryProvider.overrideWithValue(financeRepo),
      tongtaiSearchFavoritesStoreProvider.overrideWithValue(
        InMemorySupplierFavoritesStore(),
      ),
      tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
    ],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: screen,
    ),
  );

  final screens = <String, Widget Function()>{
    'home': () => TongtaiHomeScreen(clock: () => DateTime(2026, 7, 30)),
    'inventory': () => const TongtaiInventoryScreen(),
    'customer-list': () => const TongtaiCustomerListScreen(),
    'create-order': () => TongtaiCreateOrderScreen(
      customer: kSampleCustomers.first,
      products: kSampleProducts,
    ),
    'reports': () => const TongtaiReportsScreen(),
    'consumer': () => const TongtaiConsumerScreen(),
    'more': () => const TongtaiMoreScreen(),
  };

  /// Chuỗi nhãn theo thứ tự duyệt — đúng thứ TalkBack đọc.
  List<String> labelsInTraversalOrder(WidgetTester tester) {
    SemanticsNode? root;
    void findRoot(PipelineOwner owner) {
      root ??= owner.semanticsOwner?.rootSemanticsNode;
      owner.visitChildren(findRoot);
    }

    findRoot(tester.binding.rootPipelineOwner);
    final out = <String>[];
    // ⚠️ THỨ TỰ DUYỆT, không phải thứ tự cây.
    //
    // `visitChildren` đi theo cấu trúc cây. TalkBack đọc theo **traversal
    // order** — thứ tự đã áp sortKey. Hai thứ này khác nhau, và kết luận
    // "màn X đọc sai thứ tự" rút ra từ thứ tự cây là một báo động có thể sai.
    void walk(SemanticsNode node) {
      final d = node.getSemanticsData();
      if (d.label.trim().isNotEmpty) out.add(d.label.trim());
      for (final c in node.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.traversalOrder,
      )) {
        walk(c);
      }
    }

    if (root != null) walk(root!);
    return out;
  }

  Future<List<String>> readAt(
    WidgetTester tester,
    Widget screen,
    Size physical,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = physical;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await host(screen));
    await tester.pumpAndSettle();
    final labels = labelsInTraversalOrder(tester);
    await tester.pumpWidget(const SizedBox());
    return labels;
  }

  testWidgets('⭐ thứ tự đọc ở 731dp (Nokia THẬT) so với 823dp (bản audit cũ)', (
    tester,
  ) async {
    await seeder().seed();
    final handle = tester.ensureSemantics();

    final report = StringBuffer()
      ..writeln('# WTM-399 — đối chiếu thứ tự đọc theo chiều cao màn hình')
      ..writeln()
      ..writeln('Nokia 6.1 THẬT: 1080x1920 @2.625 = 411x731 dp')
      ..writeln('Bản audit cũ  : 1080x2160 @2.625 = 411x823 dp (SAI)')
      ..writeln();

    final differing = <String>[];
    for (final entry in screens.entries) {
      final real = await readAt(tester, entry.value(), const Size(1080, 1920));
      final old = await readAt(tester, entry.value(), const Size(1080, 2160));
      final same =
          real.length == old.length &&
          List.generate(real.length, (i) => real[i] == old[i]).every((x) => x);
      report
        ..writeln('## ${entry.key}')
        ..writeln('- 731dp: ${real.length} nhãn')
        ..writeln('- 823dp: ${old.length} nhãn')
        ..writeln('- thứ tự: ${same ? "GIỐNG HỆT" : "KHÁC"}');
      if (!same) {
        differing.add(entry.key);
        final n = real.length < old.length ? real.length : old.length;
        for (var i = 0; i < n; i++) {
          if (real[i] != old[i]) {
            report
              ..writeln('  - lệch đầu tiên ở vị trí $i:')
              ..writeln('    731dp: "${real[i]}"')
              ..writeln('    823dp: "${old[i]}"');
            break;
          }
        }
        if (real.length != old.length) {
          report.writeln(
            '  - chênh số nhãn: ${(real.length - old.length).abs()}',
          );
        }
        report.writeln('  - **731dp (Nokia THẬT) đọc:**');
        for (var i = 0; i < real.length && i < 14; i++) {
          report.writeln('    $i. ${real[i]}');
        }
        report.writeln('  - **823dp (bản cũ) đọc:**');
        for (var i = 0; i < old.length && i < 14; i++) {
          report.writeln('    $i. ${old[i]}');
        }
      }
      report.writeln();
      // ⛔ KHÔNG assert "toàn bộ phải giống hệt": phần đuôi khác nhau là hành vi
      // ĐÚNG của danh sách ảo hoá — ở 731dp Kho dựng thêm 2 thẻ sản phẩm trước
      // nút "Thêm sản phẩm". Ép nó giống sẽ biến một sự thật thành một test đỏ
      // phải "sửa".
      //
      // ⭐ NHƯNG phần ĐẦU thì phải giống: thứ người mù nghe thấy TRƯỚC TIÊN khi
      // vào màn — tên màn, tiêu đề, khối tổng quan — không được đổi theo kích
      // thước máy. Một người dùng Nokia và một người dùng máy cao hơn phải được
      // định hướng giống nhau. Đó là bất biến, và đó là chỗ đặt cổng.
      const head = 10;
      final n = real.length < old.length ? real.length : old.length;
      final headLen = n < head ? n : head;
      expect(
        real.take(headLen).toList(),
        old.take(headLen).toList(),
        reason:
            '${entry.key}: $headLen nhãn ĐẦU TIÊN đổi theo chiều cao màn hình — '
            'người dùng hai máy khác nhau sẽ được định hướng khác nhau',
      );
    }

    report.writeln(
      differing.isEmpty
          ? '**KẾT LUẬN: thứ tự đọc KHÔNG phụ thuộc chiều cao** ⇒ kết luận '
                '"thứ tự đọc sạch" của WTM-277 giữ nguyên ở chiều cao thật.'
          : '**KẾT LUẬN: ${differing.length} màn đọc KHÁC ở chiều cao thật: '
                '${differing.join(", ")}** ⇒ bản audit cũ chưa phủ được chúng.',
    );

    final out = File(
      '${Platform.environment['HOME']}/Desktop/WTM-399-height-equivalence.md',
    );
    out.writeAsStringSync(report.toString());
    // ignore: avoid_print
    print(report.toString());
    handle.dispose();
  });
}
