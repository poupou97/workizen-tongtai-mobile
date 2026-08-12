import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_enricher.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_detail_screen.dart';

import '../../../../support/pump_until.dart';

/// WTM-335 — the read-only, grouped Product Detail (§15). Real Drift, real
/// on-demand attribute read through the production provider. Behaviour is found
/// by stable test-id (Key), never by display text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  Product product(String id, String category) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Sản phẩm $id',
    category: category,
    pricePerUnit: 250000,
    quantity: 12,
    reorderLevel: 3,
    updatedAt: DateTime(2026, 8, 12),
  );

  Future<void> pump(WidgetTester tester, Product p) async {
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
          home: TongtaiProductDetailScreen(product: p),
        ),
      ),
    );
  }

  testWidgets('a product WITH attributes shows the grouped block + values', (
    tester,
  ) async {
    final p = product('import-E1', 'Điện tử');
    // Seed the attributes for exactly this product through the real enricher.
    await ProductAttributeEnricher(AttributeRepository(db)).enrich([p]);

    await pump(tester, p);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('product-detail-attributes')),
    );

    // Core section is always present.
    expect(find.byKey(const Key('product-detail-core')), findsOneWidget);
    // The grouped attribute block rendered, with the Electronics group heading.
    expect(find.byKey(const Key('product-detail-attributes')), findsOneWidget);
    expect(find.text('Điện tử'), findsWidgets);
    // A real value line (wattage/voltage/warranty) is on screen. The field
    // label lives inside a RichText TextSpan, so match rich text too.
    expect(find.textContaining('Công suất', findRichText: true), findsWidgets);
  });

  testWidgets('a product with NO attributes shows NO grouped block', (
    tester,
  ) async {
    // "Mỹ phẩm" is not one of the four enriched industries ⇒ no attributes.
    final p = product('import-M1', 'Mỹ phẩm');
    await ProductAttributeEnricher(AttributeRepository(db)).enrich([p]);

    await pump(tester, p);
    // The synchronous core section is enough to prove the screen rendered.
    await pumpUntilFound(tester, find.byKey(const Key('product-detail-core')));

    expect(find.byKey(const Key('product-detail-core')), findsOneWidget);
    // The whole grouped section — heading and card — must be absent.
    expect(find.byKey(const Key('product-detail-attributes')), findsNothing);
    expect(find.text('Thông số kỹ thuật'), findsNothing);
  });

  testWidgets('key information is always shown (SKU, price, kind)', (
    tester,
  ) async {
    final p = product('import-M2', 'Mỹ phẩm');
    await pump(tester, p);
    await pumpUntilFound(tester, find.byKey(const Key('product-detail-core')));

    expect(find.text('SKU-import-M2'), findsWidgets);
    expect(find.text('Thông tin chính'), findsOneWidget);
  });

  testWidgets('the edit action appears only when an onEdit is wired', (
    tester,
  ) async {
    final p = product('import-M3', 'Mỹ phẩm');
    var edited = false;
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
          home: TongtaiProductDetailScreen(
            product: p,
            onEdit: () => edited = true,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('product-detail-core')));

    await tester.tap(find.byKey(const Key('product-detail-action-edit')));
    await tester.pump();
    expect(edited, isTrue);
  });
}
