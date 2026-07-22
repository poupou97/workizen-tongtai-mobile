import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_history.dart';
import 'package:tongtai/features/tongtai/inventory/product_image_source.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_form_screen.dart';

/// A fake image source that returns fixed paths without touching platform
/// channels, so AC2 (upload / camera) is testable in a widget test.
class _FakeImageSource implements ProductImageSource {
  _FakeImageSource({this.gallery, this.camera});

  final String? gallery;
  final String? camera;
  int galleryCalls = 0;
  int cameraCalls = 0;

  @override
  Future<String?> pickFromGallery() async {
    galleryCalls++;
    return gallery;
  }

  @override
  Future<String?> captureFromCamera() async {
    cameraCalls++;
    return camera;
  }
}

/// Real widget tests for the WTM-69 Add/Edit Product form — every acceptance
/// criterion exercised through the UI: the required fields, image upload/camera,
/// markdown preview, edit-mode change history, and Save/Cancel validation.
void main() {
  // A tall viewport so the whole scrolling form is laid out and every field is
  // reachable without scroll-until-visible gymnastics.
  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3200);
  }

  // Reads the current text of a keyed form field's controller.
  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

  // Flushes the validation SnackBar's auto-dismiss timer so it isn't left
  // pending at teardown (which fails the test).
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Product sampleProduct({
    List<ProductRevision> history = const [],
    List<String> imagePaths = const [],
  }) {
    return Product(
      id: 'p1',
      sku: 'SKU-EL-001',
      name: 'Mini fan',
      category: 'Electronics',
      quantity: 20,
      pricePerUnit: 89000,
      reorderLevel: 50,
      description: 'A handy fan',
      imagePaths: imagePaths,
      history: history,
      updatedAt: DateTime(2026, 7, 1),
    );
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    Product? product,
    ProductImageSource? imageSource,
    bool Function(String)? isSkuTaken,
    List<String> categories = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiProductFormScreen(
          product: product,
          imageSource: imageSource,
          isSkuTaken: isSkuTaken,
          categories: categories,
          clock: () => DateTime(2026, 7, 16, 12),
          idFactory: () => 'new-id',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pushes the form from a host route so [Navigator.pop] results are captured.
  Future<void> Function() pushForm(
    WidgetTester tester, {
    Product? product,
    ProductImageSource? imageSource,
    bool Function(String)? isSkuTaken,
    required void Function(Product?) onResult,
  }) {
    late BuildContext hostContext;
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                hostContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      // Push the form and capture its pop result, but do NOT await the push
      // future here: it only completes when the route is popped (by a later
      // Save/Cancel tap in the test), so awaiting it during setup would
      // deadlock. `unawaited` fires the navigation and lets the test proceed.
      unawaited(
        Navigator.of(hostContext)
            .push<Product>(
              MaterialPageRoute(
                builder: (_) => TongtaiProductFormScreen(
                  product: product,
                  imageSource: imageSource,
                  isSkuTaken: isSkuTaken,
                  clock: () => DateTime(2026, 7, 16, 12),
                  idFactory: () => 'new-id',
                ),
              ),
            )
            .then(onResult),
      );
      await tester.pumpAndSettle();
    };
  }

  testWidgets('add mode renders the required fields and Save/Cancel', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpForm(tester);

    expect(find.text('Add Product'), findsOneWidget); // AppBar title
    expect(find.byKey(const Key('product-name-field')), findsOneWidget);
    expect(find.byKey(const Key('product-sku-field')), findsOneWidget);
    expect(find.byKey(const Key('product-category-field')), findsOneWidget);
    expect(find.byKey(const Key('product-price-field')), findsOneWidget);
    expect(find.byKey(const Key('product-quantity-field')), findsOneWidget);
    expect(find.text('Save Product'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Save on an empty form shows required-field errors and blocks', (
    tester,
  ) async {
    useTallViewport(tester);
    Product? result;
    var resultReceived = false;
    final open = pushForm(
      tester,
      onResult: (r) {
        result = r;
        resultReceived = true;
      },
    );
    await open();

    await tester.tap(find.text('Save Product'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('SKU is required'), findsOneWidget);
    expect(find.text('Unit price is required'), findsOneWidget);
    expect(find.text('Quantity is required'), findsOneWidget);
    // Still on the form; nothing was returned.
    expect(find.text('Add Product'), findsOneWidget);
    expect(resultReceived, isFalse);
    expect(result, isNull);
    await dismissSnackBar(tester);
  });

  testWidgets('a valid add returns a fully-built product', (tester) async {
    useTallViewport(tester);
    Product? result;
    final open = pushForm(tester, onResult: (r) => result = r);
    await open();

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Mini fan',
    );
    await tester.enterText(
      find.byKey(const Key('product-sku-field')),
      'SKU-EL-001',
    );
    await tester.enterText(
      find.byKey(const Key('product-category-field')),
      'Electronics',
    );
    await tester.enterText(
      find.byKey(const Key('product-price-field')),
      '89000',
    );
    await tester.enterText(
      find.byKey(const Key('product-quantity-field')),
      '20',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Product'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.id, 'new-id');
    expect(result!.name, 'Mini fan');
    expect(result!.sku, 'SKU-EL-001');
    expect(result!.category, 'Electronics');
    expect(result!.pricePerUnit, 89000);
    expect(result!.quantity, 20);
    expect(result!.history, isEmpty);
  });

  testWidgets('a duplicate SKU is rejected by the uniqueness check', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpForm(tester, isSkuTaken: (sku) => sku == 'SKU-DUP');

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Thing',
    );
    await tester.enterText(
      find.byKey(const Key('product-sku-field')),
      'SKU-DUP',
    );
    await tester.enterText(
      find.byKey(const Key('product-category-field')),
      'Misc',
    );
    await tester.enterText(find.byKey(const Key('product-price-field')), '100');
    await tester.enterText(
      find.byKey(const Key('product-quantity-field')),
      '1',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Product'));
    await tester.pumpAndSettle();

    expect(find.text('SKU already exists'), findsOneWidget);
    await dismissSnackBar(tester);
  });

  testWidgets('edit mode prefills fields and shows an Edit title', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpForm(tester, product: sampleProduct());

    expect(find.text('Edit Product'), findsOneWidget);
    expect(fieldText(tester, 'product-name-field'), 'Mini fan');
    expect(fieldText(tester, 'product-sku-field'), 'SKU-EL-001');
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('editing a field shows a live unsaved-changes preview', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpForm(tester, product: sampleProduct());

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Mini fan v2',
    );
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes (1)'), findsOneWidget);
    expect(find.textContaining('Name: Mini fan → Mini fan v2'), findsOneWidget);
  });

  testWidgets('saving an edit returns a product with grown change history', (
    tester,
  ) async {
    useTallViewport(tester);
    Product? result;
    final open = pushForm(
      tester,
      product: sampleProduct(),
      onResult: (r) => result = r,
    );
    await open();

    await tester.enterText(
      find.byKey(const Key('product-quantity-field')),
      '42',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.quantity, 42);
    expect(result!.history, hasLength(1));
    expect(result!.history.first.changes.single.field, ProductField.quantity);
  });

  testWidgets('past change history is shown in edit mode', (tester) async {
    useTallViewport(tester);
    final withHistory = sampleProduct(
      history: [
        ProductRevision(
          timestamp: DateTime(2026, 7, 10),
          changes: const [
            ProductFieldChange(
              field: ProductField.quantity,
              before: '10',
              after: '20',
            ),
          ],
        ),
      ],
    );
    await pumpForm(tester, product: withHistory);

    expect(find.text('Change history'), findsOneWidget);
    expect(find.textContaining('Quantity: 10 → 20'), findsOneWidget);
  });

  testWidgets('markdown description has a working preview toggle', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpForm(tester);

    await tester.enterText(
      find.byKey(const Key('product-description-field')),
      '# Heading',
    );
    await tester.pumpAndSettle();

    // Write mode: raw text field, no rendered markdown.
    expect(find.byType(MarkdownBody), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Preview'));
    await tester.pumpAndSettle();

    // Preview mode: markdown is rendered, the raw field is gone.
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.byKey(const Key('product-description-field')), findsNothing);
  });

  testWidgets('uploading an image adds a thumbnail (AC2)', (tester) async {
    useTallViewport(tester);
    final source = _FakeImageSource(gallery: '/tmp/product-photo.jpg');
    await pumpForm(tester, imageSource: source);

    expect(find.text('Images (0)'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload'));
    await tester.pumpAndSettle();

    expect(source.galleryCalls, 1);
    expect(find.text('Images (1)'), findsOneWidget);
    expect(find.byTooltip('Remove image'), findsOneWidget);

    // Removing it clears the thumbnail again.
    await tester.tap(find.byTooltip('Remove image'));
    await tester.pumpAndSettle();
    expect(find.text('Images (0)'), findsOneWidget);
  });

  testWidgets('a saved product carries its images and description (AC2/AC3)', (
    tester,
  ) async {
    useTallViewport(tester);
    final source = _FakeImageSource(gallery: '/tmp/product-photo.jpg');
    Product? result;
    final open = pushForm(
      tester,
      imageSource: source,
      onResult: (r) => result = r,
    );
    await open();

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Mini fan',
    );
    await tester.enterText(
      find.byKey(const Key('product-sku-field')),
      'SKU-EL-001',
    );
    await tester.enterText(
      find.byKey(const Key('product-category-field')),
      'Electronics',
    );
    await tester.enterText(
      find.byKey(const Key('product-price-field')),
      '89000',
    );
    await tester.enterText(
      find.byKey(const Key('product-quantity-field')),
      '20',
    );
    await tester.enterText(
      find.byKey(const Key('product-description-field')),
      '# Great fan',
    );
    await tester.pumpAndSettle();

    // Attach a photo through the (faked) gallery picker before saving.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload'));
    await tester.pumpAndSettle();
    expect(find.text('Images (1)'), findsOneWidget);

    await tester.tap(find.text('Save Product'));
    await tester.pumpAndSettle();

    // The picked image path and the markdown description reach the saved
    // Product — not just the on-screen thumbnail/preview.
    expect(result, isNotNull);
    expect(result!.imagePaths, ['/tmp/product-photo.jpg']);
    expect(result!.description, '# Great fan');
  });

  testWidgets('the camera button captures via the image source (AC2)', (
    tester,
  ) async {
    useTallViewport(tester);
    final source = _FakeImageSource(camera: '/tmp/captured.jpg');
    await pumpForm(tester, imageSource: source);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Camera'));
    await tester.pumpAndSettle();

    expect(source.cameraCalls, 1);
    expect(find.text('Images (1)'), findsOneWidget);
  });

  testWidgets('a cancelled pick leaves the image list unchanged', (
    tester,
  ) async {
    useTallViewport(tester);
    final source = _FakeImageSource(gallery: null); // user cancelled
    await pumpForm(tester, imageSource: source);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload'));
    await tester.pumpAndSettle();

    expect(source.galleryCalls, 1);
    expect(find.text('Images (0)'), findsOneWidget);
  });

  testWidgets('a category suggestion chip fills the category field', (
    tester,
  ) async {
    useTallViewport(tester);
    await pumpForm(tester, categories: const ['Electronics', 'Beauty']);

    await tester.tap(find.widgetWithText(ActionChip, 'Beauty'));
    await tester.pumpAndSettle();

    expect(fieldText(tester, 'product-category-field'), 'Beauty');
  });

  testWidgets('Cancel pops without returning a product', (tester) async {
    useTallViewport(tester);
    Product? result;
    var resultReceived = false;
    final open = pushForm(
      tester,
      onResult: (r) {
        result = r;
        resultReceived = true;
      },
    );
    await open();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resultReceived, isTrue);
    expect(result, isNull);
  });
}
