import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/export/backup_crypto.dart';
import 'package:tongtai/features/tongtai/export/csv_delivery.dart';
import 'package:tongtai/features/tongtai/export/csv_exporter.dart';
import 'package:tongtai/features/tongtai/export/export_history_store.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_export_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';

import '../../support/pump_until.dart';

/// WTM-99 — Data Export to CSV (Phase 2 per D-10):
///  - AC1: customers / products / orders exports
///  - AC2: header line, RFC-4180 quoting, UTF-8 BOM, VN diacritics intact
///  - AC3: inclusive date-range filtering for orders
///  - AC4: delivery seam (share sheet / email) receives file + subject
///  - AC5: history logged (SharedPreferences round-trip) and shown on screen
void main() {
  const exporter = TongtaiCsvExporter();

  group('CSV formatting (AC2)', () {
    test('field quoting: commas, quotes, newlines; plain stays plain', () {
      expect(TongtaiCsvExporter.field('plain'), 'plain');
      expect(TongtaiCsvExporter.field('a,b'), '"a,b"');
      expect(TongtaiCsvExporter.field('say "hi"'), '"say ""hi"""');
      expect(TongtaiCsvExporter.field('line1\nline2'), '"line1\nline2"');
      expect(TongtaiCsvExporter.field(null), '');
    });

    test('document starts with the UTF-8 BOM and a header line', () {
      final csv = exporter.customersCsv(kSampleCustomers);
      expect(csv.content.startsWith(TongtaiCsvExporter.bom), isTrue);
      final firstLine = csv.content
          .substring(TongtaiCsvExporter.bom.length)
          .split('\r\n')
          .first;
      expect(firstLine, startsWith('id,ten,dien_thoai'));
    });

    test('Vietnamese diacritics survive the round trip', () {
      final csv = exporter.customersCsv(kSampleCustomers);
      expect(csv.content, contains('Phương Nguyễn'));
      expect(csv.content, contains('Hà Nội'));
    });

    test('rows use CRLF and the document ends with a newline', () {
      final csv = exporter.productsCsv(kSampleProducts.take(2).toList());
      expect(csv.content, contains('\r\n'));
      expect(csv.content.endsWith('\r\n'), isTrue);
    });
  });

  group('data sets (AC1)', () {
    test('customers export: one row per customer, money as integer đồng', () {
      final csv = exporter.customersCsv(kSampleCustomers);
      expect(csv.rowCount, kSampleCustomers.length);
      // c01 spends 45,600,000: exported unformatted for spreadsheet math.
      expect(csv.content, contains('45600000'));
      expect(csv.content, isNot(contains('45.600.000')));
    });

    test('products export flags low stock', () {
      final csv = exporter.productsCsv(kSampleProducts);
      expect(csv.rowCount, kSampleProducts.length);
      expect(csv.content, contains('DU_HANG'));
    });

    test('orders export: one row per order LINE for pivoting', () {
      final csv = exporter.ordersCsv(kSampleCustomerOrders);
      final lineCount = kSampleCustomerOrders.fold<int>(
        0,
        (sum, o) => sum + o.items.length,
      );
      expect(csv.rowCount, lineCount);
      expect(csv.content, contains('DH-2026-0101'));
    });
  });

  group('date range (AC3)', () {
    CustomerOrder order(String id, DateTime date) => CustomerOrder(
      id: id,
      customerId: 'c1',
      orderNumber: 'DH-$id',
      date: date,
      status: OrderStatus.delivered,
      items: const [
        OrderItem(
          productName: 'X',
          category: 'C',
          quantity: 1,
          unitPrice: 1000,
        ),
      ],
    );

    test('inclusive from/to bounds', () {
      final orders = [
        order('a', DateTime(2026, 7, 1)),
        order('b', DateTime(2026, 7, 15)),
        order('c', DateTime(2026, 7, 31)),
      ];
      final csv = exporter.ordersCsv(
        orders,
        from: DateTime(2026, 7, 1),
        to: DateTime(2026, 7, 15),
      );
      expect(csv.rowCount, 2);
      expect(csv.content, contains('DH-a'));
      expect(csv.content, contains('DH-b'));
      expect(csv.content, isNot(contains('DH-c')));
    });
  });

  group('history store (AC5)', () {
    test('SharedPreferences round-trip, newest first, capped', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsTongtaiExportHistoryStore(prefs);

      for (var i = 0; i < 25; i++) {
        await store.add(
          TongtaiExportRecord(
            type: TongtaiExportType.customers,
            fileName: 'f$i.csv',
            rowCount: i,
            exportedAt: DateTime(2026, 7, 1 + (i % 28)),
          ),
        );
      }
      // A fresh store over the same prefs = app restart.
      final reloaded = await SharedPrefsTongtaiExportHistoryStore(prefs).load();
      expect(reloaded.length, TongtaiExportHistoryStore.maxEntries);
      expect(reloaded.first.fileName, 'f24.csv'); // newest first
    });

    test('corrupted history is dropped, not crashed on', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsTongtaiExportHistoryStore.storageKey: 'not-json{',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsTongtaiExportHistoryStore(prefs);
      expect(await store.load(), isEmpty);
    });
  });

  group('export screen (AC1/AC3/AC4/AC5)', () {
    void useTallViewport(WidgetTester tester) {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 3400);
    }

    testWidgets('export delivers CSV with subject and logs history', (
      tester,
    ) async {
      useTallViewport(tester);
      final delivery = RecordingCsvDelivery();
      final history = InMemoryTongtaiExportHistoryStore();
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiExportScreen(
            delivery: delivery,
            history: history,
            clock: () => DateTime(2026, 7, 23),
            // One-source (WTM-144): the screen exports the repositories; tests
            // inject their fixtures explicitly.
            customers: kSampleCustomers,
            products: kSampleProducts,
            orders: kSampleCustomerOrders,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-run')));
      await tester.pumpAndSettle();

      // AC4: delivered through the seam with an email-ready subject.
      expect(delivery.delivered, hasLength(1));
      final (csv, fileName, subject) = delivery.delivered.single;
      expect(fileName, 'tongtai-khach-hang-20260723.csv');
      expect(subject, contains('Customers'));
      expect(csv.rowCount, kSampleCustomers.length);

      // AC5: history logged and visible.
      expect((await history.load()), hasLength(1));
      expect(
        find.textContaining('tongtai-khach-hang-20260723.csv'),
        findsWidgets,
      );
      // Flush the confirmation snackbar timer.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets(
      'WTM-100: encrypted export delivers an armored .ttbk that round-trips '
      'with the passphrase',
      (tester) async {
        useTallViewport(tester);
        final delivery = RecordingCsvDelivery();
        // Low-iteration crypto so PBKDF2 stays fast under test; the container
        // embeds its own iteration count, so decrypt just works.
        const crypto = BackupCrypto(iterations: 10);
        await tester.pumpWidget(
          MaterialApp(
            home: TongtaiExportScreen(
              delivery: delivery,
              history: InMemoryTongtaiExportHistoryStore(),
              clock: () => DateTime(2026, 7, 23),
              crypto: crypto,
              customers: kSampleCustomers,
              products: kSampleProducts,
              orders: kSampleCustomerOrders,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enable encryption; a short passphrase is rejected before delivery.
        await tester.tap(find.byKey(const Key('export-encrypt-toggle')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('export-passphrase')),
          'abc',
        );
        await tester.tap(find.byKey(const Key('export-run')));
        await tester.pumpAndSettle();
        expect(delivery.delivered, isEmpty);
        expect(find.textContaining('at least 6 characters'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));

        // A proper passphrase delivers the armored container.
        await tester.enterText(
          find.byKey(const Key('export-passphrase')),
          'mật-khẩu-mạnh',
        );
        await tester.tap(find.byKey(const Key('export-run')));
        await tester.pumpAndSettle();

        final (csv, fileName, _) = delivery.delivered.single;
        expect(fileName, 'tongtai-khach-hang-20260723.csv.ttbk');
        expect(csv.content, startsWith('TONGTAI-BACKUP-V1:'));
        expect(csv.content, isNot(contains(kSampleCustomers.first.name)));

        // The container round-trips back to the plain CSV with the passphrase.
        final plain = await crypto.decryptArmored(csv.content, 'mật-khẩu-mạnh');
        expect(plain, contains(kSampleCustomers.first.name));
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets('orders type exposes the date-range presets and filters', (
      tester,
    ) async {
      useTallViewport(tester);
      final delivery = RecordingCsvDelivery();
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiExportScreen(
            delivery: delivery,
            history: InMemoryTongtaiExportHistoryStore(),
            clock: () => DateTime(2026, 7, 23),
            customers: kSampleCustomers,
            products: kSampleProducts,
            orders: kSampleCustomerOrders,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Range chips appear only for orders.
      expect(find.byKey(const Key('export-range-last30Days')), findsNothing);
      await tester.tap(find.byKey(const Key('export-type-orders')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export-range-last30Days')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-run')));
      await tester.pumpAndSettle();

      final (csv, fileName, _) = delivery.delivered.single;
      expect(fileName, startsWith('tongtai-don-hang'));
      // Sample orders within 30 days of 2026-07-23 (>= 2026-06-23): o01
      // (07-10, 2 lines), o04 (06-30, 1), o05 (07-13, 1) — o06 (06-08) is
      // outside the window → 4 rows.
      expect(csv.rowCount, 4);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('More → "Export Data (CSV)" opens the screen', (tester) async {
      useTallViewport(tester);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_MoreHost(await SharedPreferences.getInstance()));
      await tester.ensureVisible(find.text('Export Data (CSV)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export Data (CSV)'));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiExportScreen), findsOneWidget);
    });
  });
  testWidgets('WTM-164: export history survives a restart (production wiring)', (
    tester,
  ) async {
    // Fail-before/pass-after: the screen defaulted to the IN-MEMORY store even
    // in production, so the history WTM-99 AC5 promises reset on every launch
    // while `SharedPrefsTongtaiExportHistoryStore` sat unused.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SharedPrefsTongtaiExportHistoryStore(prefs).add(
      TongtaiExportRecord(
        type: TongtaiExportType.customers,
        fileName: 'tongtai-khach-hang-20260731.csv',
        rowCount: 2,
        exportedAt: DateTime(2026, 7, 31, 9, 41),
      ),
    );

    // A NEW screen with NO injected history must still find that record — it
    // has to resolve the persistent store, not build a fresh in-memory one.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          customerRepositoryProvider.overrideWithValue(
            InMemoryCustomerRepository(),
          ),
          productRepositoryProvider.overrideWithValue(
            InMemoryProductRepository(),
          ),
          orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
        ],
        child: const MaterialApp(home: TongtaiExportScreen()),
      ),
    );
    await pumpUntilFound(
      tester,
      find.textContaining('tongtai-khach-hang-20260731.csv'),
    );

    expect(
      find.textContaining('tongtai-khach-hang-20260731.csv'),
      findsWidgets,
    );
  });
}

/// More screen needs a Riverpod scope; the Export screen it opens now reads
/// the production repositories (WTM-144) — keep it on in-memory overrides.
class _MoreHost extends StatelessWidget {
  const _MoreHost(this.prefs);

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      customerRepositoryProvider.overrideWithValue(
        InMemoryCustomerRepository(),
      ),
      productRepositoryProvider.overrideWithValue(
        InMemoryProductRepository([]),
      ),
      orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
      // The Export screen persists its history in SharedPreferences
      // (WTM-164) exactly as production does, so this override is required
      // rather than optional.
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    // The scope must sit ABOVE the Navigator so pushed routes (the real
    // Export screen) inherit the in-memory overrides (WTM-144).
    child: const MaterialApp(home: TongtaiMoreScreen()),
  );
}
