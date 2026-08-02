import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_form.dart';
import 'package:tongtai/features/tongtai/inventory/product_history.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_product_form_screen.dart';

/// WTM-233 / ADR-TON-023 — người bán CHỌN được loại sản phẩm.
///
/// WTM-227 đưa `ProductKind` vào miền và dạy Inventory/Rule Engine im lặng với
/// hàng không có tồn kho, nhưng form vẫn là form hàng vật lý nguyên vẹn: không
/// có ô chọn loại, `quantity` vẫn bắt buộc, và đường lưu vẫn ép `?? 0`. Với
/// người dùng, ADR chưa hề xảy ra.
void main() {
  Product digital({int? quantity, int? reorderLevel}) => Product(
    id: 'p-digital',
    sku: 'TONGTAI-PRO',
    name: 'Tổng Tài Pro',
    category: 'Phần mềm',
    kind: ProductKind.digital,
    quantity: quantity,
    reorderLevel: reorderLevel,
    pricePerUnit: 199000,
    updatedAt: DateTime(2026, 8, 1),
  );

  group('đường LƯU không được dựng lại lời nói dối vừa gỡ', () {
    test('sửa một sản phẩm số rồi lưu: nó vẫn là sản phẩm số', () {
      // Đây là lỗ thật: `toProduct` không truyền `kind` nên mặc định
      // `physical`, và `_tryParseInt(...) ?? 0` biến ô trống thành 0 cái. Chỉ
      // cần mở ra sửa tên là một phần mềm thành hàng hoá HẾT HÀNG, rồi Rule
      // Engine sinh cơ hội nhập hàng cho nó.
      final original = digital();
      final edited = ProductEditor.applyEdit(
        original,
        ProductFormData.fromProduct(original).copyWith(name: 'Tổng Tài Pro 2'),
        now: DateTime(2026, 8, 2),
      );

      expect(edited.kind, ProductKind.digital);
      expect(edited.quantity, isNull, reason: '"không áp dụng" ≠ 0 cái');
      expect(edited.reorderLevel, isNull);
      expect(
        edited.stockStatus,
        isNull,
        reason: 'một phần mềm không bao giờ "hết hàng"',
      );
      expect(edited.needsRestock, isFalse);
    });

    test(
      'đổi loại từ hàng hoá sang số thì tồn kho được XOÁ, không giữ lại',
      () {
        const form = ProductFormData(
          name: 'Khoá học',
          sku: 'KH-01',
          category: 'Đào tạo',
          priceText: '500000',
          // Người bán đã gõ số này khi form còn là form hàng vật lý.
          quantityText: '12',
          reorderLevelText: '3',
          kind: ProductKind.digital,
        );

        final product = form.toProduct(
          id: 'x',
          updatedAt: DateTime(2026, 8, 2),
        );

        expect(product.quantity, isNull);
        expect(product.reorderLevel, isNull);
        expect(
          product.stockValue,
          0,
          reason: 'không có đồng vốn nào nằm trong kho',
        );
      },
    );

    test('hàng vật lý giữ nguyên mọi hành vi cũ', () {
      // Luật thứ ba của ADR-TON-023: không ép doanh nghiệp hàng hoá thành
      // doanh nghiệp số.
      const form = ProductFormData(
        name: 'Quạt mini',
        sku: 'SKU-01',
        category: 'Điện tử',
        priceText: '89000',
        quantityText: '0',
      );

      final product = form.toProduct(id: 'x', updatedAt: DateTime(2026, 8, 2));

      expect(product.kind, ProductKind.physical);
      expect(product.quantity, 0);
      expect(product.reorderLevel, 0, reason: 'ô để trống vẫn là 0 như trước');
      expect(product.stockStatus, StockStatus.outOfStock);
    });
  });

  group('form không hỏi thứ loại này không có', () {
    test('sản phẩm số lưu được mà KHÔNG cần điền tồn kho', () {
      const form = ProductFormData(
        name: 'Tổng Tài Pro',
        sku: 'TT-PRO',
        category: 'Phần mềm',
        priceText: '199000',
        kind: ProductKind.digital,
      );

      expect(form.validate()[ProductField.quantity], isNull);
      expect(form.isValid, isTrue);
    });

    test('hàng vật lý VẪN bắt buộc điền tồn kho', () {
      const form = ProductFormData(
        name: 'Quạt mini',
        sku: 'SKU-01',
        category: 'Điện tử',
        priceText: '89000',
      );

      expect(form.validate()[ProductField.quantity], isNotNull);
    });
  });

  group('ô nhập không được hiện chữ "null"', () {
    test('tồn kho "không áp dụng" đọc ra ô TRỐNG', () {
      // `int?.toString()` in ra đúng bốn chữ cái n-u-l-l vào ô của người bán.
      final data = ProductFormData.fromProduct(digital());
      expect(data.quantityText, '');
      expect(data.reorderLevelText, '');
      expect(data.kind, ProductKind.digital);
    });

    test('lịch sử sửa đổi không ghi "12 → null"', () {
      final before = Product(
        id: 'p1',
        sku: 'S',
        name: 'N',
        category: 'C',
        quantity: 12,
        reorderLevel: 3,
        pricePerUnit: 1000,
        updatedAt: DateTime(2026, 8, 1),
      );
      final after = before.copyWith(kind: ProductKind.service).toKindless();

      final changes = ProductEditor.diff(before, after);
      final quantity = changes.firstWhere(
        (c) => c.field == ProductField.quantity,
      );

      expect(quantity.after, '');
      expect(
        changes.map((c) => c.after),
        isNot(contains('null')),
        reason: 'lịch sử là bản ghi vĩnh viễn — không được chứa rác kỹ thuật',
      );
    });

    test('đổi loại được ghi vào lịch sử, bằng MÃ chứ không phải nhãn', () {
      final before = digital();
      final after = before.copyWith(kind: ProductKind.service);

      final changes = ProductEditor.diff(before, after);
      final kind = changes.singleWhere((c) => c.field == ProductField.kind);

      expect(kind.before, 'digital');
      expect(kind.after, 'service');
    });
  });

  group('bản sao phải mang theo loại', () {
    test('withId giữ nguyên kind', () {
      // Móc gieo dữ liệu mẫu (ADR-TON-014) chép sản phẩm qua id mới; quên
      // `kind` ở đây là biến một sản phẩm số thành hàng hoá rồi kêu hết hàng.
      expect(digital().withId('sample-1').kind, ProductKind.digital);
    });
  });

  group('nhãn loại không được nói dối', () {
    test('mỗi loại có một nhãn riêng ở cả hai ngôn ngữ', () {
      // Nhánh mặc định trả "Hàng hoá", nên một loại mới thêm mà quên nhãn sẽ
      // âm thầm hiện thành "Hàng hoá" — đúng lỗi `_ => 'Bán sỉ'` của WTM-232.
      for (final strings in [AppStringsVi(), AppStringsEn()]) {
        final labels = {
          for (final k in ProductKind.values) strings.productKindName(k.code),
        };
        expect(
          labels.length,
          ProductKind.values.length,
          reason: 'thiếu nhãn cho một loại: ${strings.languageCode}',
        );
      }
    });

    test('nhãn của mã lạ khớp với thứ miền THẬT SỰ làm với nó', () {
      // Khác WTM-232: ở đây `fromCode` cố ý trả `physical` cho mã lạ, nên nhãn
      // "Hàng hoá" là đúng — hai bên nói cùng một điều (P-27).
      expect(ProductKind.fromCode('franchise'), ProductKind.physical);
      expect(AppStringsVi().productKindName('franchise'), 'Hàng hoá');
    });
  });

  group('màn hình', () {
    Future<void> pumpForm(WidgetTester tester, {Product? product}) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 3200);
      await tester.pumpWidget(
        MaterialApp(
          home: TongtaiProductFormScreen(
            product: product,
            clock: () => DateTime(2026, 8, 2),
            idFactory: () => 'new-id',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('có ô chọn loại, mặc định là hàng hoá', (tester) async {
      await pumpForm(tester);

      for (final kind in ProductKind.values) {
        expect(find.byKey(Key('product-kind-${kind.code}')), findsOneWidget);
      }
      expect(
        tester
            .widget<ChoiceChip>(const Key('product-kind-physical').byKeyFinder)
            .selected,
        isTrue,
      );
    });

    testWidgets('chọn "sản phẩm số" thì ô tồn kho BIẾN MẤT', (tester) async {
      await pumpForm(tester);
      expect(find.byKey(const Key('product-quantity-field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('product-kind-digital')));
      await tester.pumpAndSettle();

      // Biến mất chứ không làm mờ: một ô xám vẫn nói "khái niệm này có thật
      // với bạn, bạn chưa điền", và người bán phần mềm sẽ đi tìm cách điền nó.
      expect(find.byKey(const Key('product-quantity-field')), findsNothing);
      expect(find.byKey(const Key('product-reorder-field')), findsNothing);
      expect(find.byKey(const Key('product-no-stock-note')), findsOneWidget);
    });

    testWidgets('mở một sản phẩm số ra sửa: không thấy ô tồn kho', (
      tester,
    ) async {
      await pumpForm(tester, product: digital());

      expect(find.byKey(const Key('product-quantity-field')), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(const Key('product-kind-digital').byKeyFinder)
            .selected,
        isTrue,
      );
    });

    testWidgets('lưu một sản phẩm số mà không điền tồn kho', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 3200);

      Product? saved;
      late BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );
      unawaited(
        Navigator.of(hostContext)
            .push<Product>(
              MaterialPageRoute(
                builder: (_) => TongtaiProductFormScreen(
                  clock: () => DateTime(2026, 8, 2),
                  idFactory: () => 'new-id',
                ),
              ),
            )
            .then((value) => saved = value),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('product-kind-digital')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('product-name-field')),
        'Tổng Tài Pro',
      );
      await tester.enterText(
        find.byKey(const Key('product-sku-field')),
        'TT-PRO',
      );
      await tester.enterText(
        find.byKey(const Key('product-category-field')),
        'Phần mềm',
      );
      await tester.enterText(
        find.byKey(const Key('product-price-field')),
        '199000',
      );
      await tester.pumpAndSettle();

      // Không có ô tồn kho để điền — nếu form vẫn đòi, Save sẽ chỉ hiện lỗi.
      await tester.tap(find.byKey(const Key('product-save-button')));
      await tester.pumpAndSettle();

      expect(
        saved,
        isNotNull,
        reason: 'form phải lưu được, không dừng lại ở lỗi "thiếu số lượng"',
      );
      expect(saved!.kind, ProductKind.digital);
      expect(saved!.quantity, isNull);
      expect(saved!.stockStatus, isNull);
    });
  });
}

extension on Key {
  Finder get byKeyFinder => find.byKey(this);
}

extension on Product {
  /// Sản phẩm không có tồn kho, dùng để dựng vế "sau" của một lần đổi loại.
  Product toKindless() => Product(
    id: id,
    sku: sku,
    name: name,
    category: category,
    kind: kind,
    pricePerUnit: pricePerUnit,
    updatedAt: updatedAt,
  );
}
