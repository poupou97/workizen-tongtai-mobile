import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/connection/connection_catalog.dart';
import 'package:tongtai/features/tongtai/simulation/demo_event.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/simulation/demo_scenario.dart';

/// WTM-340 · E4 — trạng thái **thứ bảy** và luật "demo không che sự thật".
void main() {
  ConnectionSource source(String id) => ConnectionCatalog.byId(id)!;

  test('⭐ demo KHÔNG được đè lên nguồn đã nối thật', () {
    // Telegram đã chạy thật (WTM-318). Bật mô phỏng lên không được biến nó
    // thành "demo" — chiều này làm mất công sức thật đã có.
    expect(
      readinessWithDemo(source('telegram'), {'telegram'}),
      ConnectionReadiness.connected,
    );
    // …và Drive vẫn là đường nhập file thật.
    expect(
      readinessWithDemo(source('google_drive_xlsx'), {'google_drive_xlsx'}),
      ConnectionReadiness.fileBridge,
    );
  });

  test(
    '⭐ nguồn chưa nối mà đang phát ⇒ demoConnected, KHÔNG phải connected',
    () {
      for (final id in ['shopee', 'tiktok_shop', 'facebook_page', 'ghn']) {
        expect(
          readinessWithDemo(source(id), {id}),
          ConnectionReadiness.demoConnected,
          reason: '$id đang phát trong mô phỏng',
        );
        // §40: fake dữ liệu được, fake trạng thái engineering thì không.
        expect(
          readinessWithDemo(source(id), {id}),
          isNot(ConnectionReadiness.connected),
        );
      }
    },
  );

  test('không phát thì giữ nguyên nhãn thật của nó', () {
    expect(
      readinessWithDemo(source('shopee'), const {}),
      ConnectionReadiness.partnerRequired,
    );
    expect(
      readinessWithDemo(source('amazon'), const {'shopee'}),
      ConnectionReadiness.apiFuture,
    );
  });

  test('mã nguồn trong catalog khớp mã nền tảng của mô phỏng', () {
    // Hai bảng mã lệch nhau thì nhãn "đang phát" im lặng không bao giờ hiện,
    // và không có gì đỏ lên — đúng loại lỗi chỉ Founder phát hiện được.
    const shouldExist = [
      DemoVendor.shopee,
      DemoVendor.tiktok,
      DemoVendor.facebook,
      DemoVendor.facebookAds,
      DemoVendor.instagram,
      DemoVendor.taobao1688,
      DemoVendor.ghn,
      DemoVendor.ghtk,
      DemoVendor.viettelPost,
      DemoVendor.bank,
      DemoVendor.telegram,
      DemoVendor.googleDrive,
    ];
    for (final code in shouldExist) {
      expect(
        ConnectionCatalog.byId(code),
        isNotNull,
        reason: 'catalog thiếu "$code" — nhãn "đang phát" sẽ không hiện',
      );
    }
  });

  test('⭐ kịch bản 30 ngày thật sự phát đủ 10 nền tảng', () {
    final events = const DemoScenario().generate(
      startedAt: DateTime(2026, 8, 9),
      products: [
        for (var i = 0; i < 20; i++)
          Product(
            id: 'p$i',
            sku: 'SKU$i',
            name: 'Sản phẩm $i',
            category: 'Thời trang',
            pricePerUnit: 200000,
            quantity: 10 + i,
            updatedAt: DateTime(2026, 8, 9),
          ),
      ],
      customers: const [],
    );

    final vendors = {for (final e in events) ?e.vendor};
    final demoConnected = [
      for (final s in ConnectionCatalog.all)
        if (readinessWithDemo(s, vendors) == ConnectionReadiness.demoConnected)
          s.id,
    ];

    // Con số là **kết quả**, không phải mục tiêu: nó đếm nền tảng thật sự có
    // sự kiện trong kịch bản. Kịch bản bớt đi một nguồn thì test này đỏ, chứ
    // không phải màn hình lặng lẽ khai thiếu.
    expect(demoConnected, hasLength(10));
  });
}
