import 'dart:io';

import 'package:drift/native.dart';
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
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;

/// WTM-342 — **Brief phải dựng được ngay sau khi nhập dữ liệu.**
///
/// Tìm ra bằng cách cầm máy thật: nhập 714 bản ghi xong, Trang chủ nói
/// *"Hôm nay tôi tìm được 20 cơ hội"* — nhưng ngay dưới nó là một thẻ đỏ.
/// Suite test lúc đó đang xanh 2488, vì không test nào chạy **đường dựng
/// brief trên đúng bộ dữ liệu mà người bán nhập**.
///
/// Đây chính là hình dạng đã ghi trong TESTING-BIBLE: *suite xanh không thay
/// thế được mắt nhìn trên thiết bị*.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('⭐ nhập bộ 100 sản phẩm ⇒ brief dựng được, không ném', () async {
    final db = AppDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 8, 9, 12);

    final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
    final preview = await XlsxCommerceSource(
      bytes: file.readAsBytesSync(),
      fileName: file.uri.pathSegments.last,
      now: now,
    ).read();
    await CommerceImporter(
      database: db,
      products: DriftProductRepository(db),
      customers: DriftCustomerRepository(db),
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      commerce: CommerceRepository(db),
      shipments: ShipmentRepository(db),
      now: () => now,
      newId: () => 'test',
    ).apply(preview, sourceVendor: ImportVendor.bundledDemo, isDemo: true);

    final container = ProviderContainer(
      overrides: [
        tongtaiDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Ném ở đây = thẻ đỏ trên Trang chủ. Đọc được = brief dựng được.
    final brief = await container.read(businessBriefProvider.future);
    expect(brief, isNotEmpty);

    // Nguyên nhân gốc: hai luật cùng kết luận "sắp hết hàng" cho cùng sản
    // phẩm ⇒ cùng `BriefItem.id`, khác payload ⇒ khoá chống lặp nổ.
    final ids = brief.map((i) => i.id).toList();
    expect(
      ids.toSet(),
      hasLength(ids.length),
      reason: 'một chuyện về một mặt hàng phải là MỘT mục (P-27)',
    );
  });

  test(
    'đọc lại lần hai vẫn dựng được — publish phải chịu được chạy lại',
    () async {
      final db = AppDatabase.forExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 8, 9, 12);

      final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
      final preview = await XlsxCommerceSource(
        bytes: file.readAsBytesSync(),
        fileName: file.uri.pathSegments.last,
        now: now,
      ).read();
      await CommerceImporter(
        database: db,
        products: DriftProductRepository(db),
        customers: DriftCustomerRepository(db),
        orders: DriftOrderRepository(db),
        settlements: DriftSettlementRepository(db),
        commerce: CommerceRepository(db),
        shipments: ShipmentRepository(db),
        now: () => now,
        newId: () => 'test',
      ).apply(preview, sourceVendor: ImportVendor.bundledDemo, isDemo: true);

      final container = ProviderContainer(
        overrides: [
          tongtaiDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(businessBriefProvider.future);
      container.invalidate(businessBriefProvider);
      // Mở Trang chủ lần thứ hai là chuyện bình thường nhất trên đời.
      expect(await container.read(businessBriefProvider.future), isNotEmpty);
    },
  );
}
