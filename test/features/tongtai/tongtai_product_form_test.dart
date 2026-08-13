import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_form.dart';
import 'package:tongtai/features/tongtai/inventory/product_history.dart';

/// Real unit tests for the WTM-69 Add/Edit domain: form validation (required
/// fields + numeric formats), form<->product conversion, and the [ProductEditor]
/// change-history logic (diff, revision recording, no-op edits).
void main() {
  Product product({
    String id = 'p1',
    String sku = 'SKU-1',
    String name = 'Widget',
    String category = 'Electronics',
    int quantity = 10,
    double pricePerUnit = 89000,
    int reorderLevel = 5,
    String description = '',
    List<String> imagePaths = const [],
    List<ProductRevision> history = const [],
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      sku: sku,
      name: name,
      category: category,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      reorderLevel: reorderLevel,
      description: description,
      imagePaths: imagePaths,
      history: history,
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );
  }

  const validData = ProductFormData(
    name: 'Mini fan',
    sku: 'SKU-EL-001',
    category: 'Electronics',
    priceText: '89000',
    quantityText: '20',
  );

  group('ProductField', () {
    test(
      'required set is exactly name, SKU, category, unit price, quantity',
      () {
        final required = ProductField.values.where((f) => f.isRequired).toSet();
        expect(required, {
          ProductField.name,
          ProductField.sku,
          ProductField.category,
          ProductField.unitPrice,
          ProductField.quantity,
        });
      },
    );

    test('description, reorder level and images are optional', () {
      expect(ProductField.description.isRequired, isFalse);
      expect(ProductField.reorderLevel.isRequired, isFalse);
      expect(ProductField.images.isRequired, isFalse);
    });

    test('English and Vietnamese labels differ and language switch works', () {
      expect(ProductField.unitPrice.labelEn, 'Unit price');
      expect(ProductField.unitPrice.labelVi, isNot('Unit price'));
      expect(ProductField.name.label('vi'), ProductField.name.labelVi);
      expect(ProductField.name.label('en'), ProductField.name.labelEn);
    });
  });

  group('ProductFormData.validate', () {
    test('an empty form reports all five required fields', () {
      final errors = const ProductFormData().validate();
      expect(
        errors.keys,
        containsAll(<ProductField>{
          ProductField.name,
          ProductField.sku,
          ProductField.category,
          ProductField.unitPrice,
          ProductField.quantity,
        }),
      );
      expect(errors.length, 5);
      expect(const ProductFormData().isValid, isFalse);
    });

    test('a fully populated form is valid', () {
      expect(validData.validate(), isEmpty);
      expect(validData.isValid, isTrue);
    });

    test('whitespace-only required fields are still errors', () {
      final errors = validData.copyWith(name: '   ').validate();
      expect(errors[ProductField.name], isNotNull);
    });

    test('non-numeric unit price is rejected', () {
      final errors = validData.copyWith(priceText: 'abc').validate();
      expect(errors[ProductField.unitPrice], contains('number'));
    });

    test('negative unit price is rejected', () {
      final errors = validData.copyWith(priceText: '-5').validate();
      expect(errors[ProductField.unitPrice], contains('negative'));
    });

    test('non-integer quantity is rejected', () {
      final errors = validData.copyWith(quantityText: '3.5').validate();
      expect(errors[ProductField.quantity], isNotNull);
    });

    test('negative quantity is rejected', () {
      final errors = validData.copyWith(quantityText: '-1').validate();
      expect(errors[ProductField.quantity], contains('negative'));
    });

    test('blank reorder level is allowed (optional)', () {
      expect(validData.copyWith(reorderLevelText: '').validate(), isEmpty);
    });

    test('a bad reorder level, when provided, is rejected', () {
      final errors = validData.copyWith(reorderLevelText: 'x').validate();
      expect(errors[ProductField.reorderLevel], isNotNull);
    });
  });

  group('ProductFormData parsing + toProduct', () {
    test('parsed getters convert the raw text', () {
      final data = validData.copyWith(
        priceText: '89000',
        quantityText: '20',
        reorderLevelText: '5',
      );
      expect(data.parsedPrice, 89000);
      expect(data.parsedQuantity, 20);
      expect(data.parsedReorderLevel, 5);
    });

    test('blank reorder level parses to 0', () {
      expect(validData.copyWith(reorderLevelText: '').parsedReorderLevel, 0);
    });

    test('toProduct trims text and applies parsed numbers', () {
      final result = validData
          .copyWith(name: '  Mini fan  ', sku: ' SKU-EL-001 ')
          .toProduct(id: 'new1', updatedAt: DateTime(2026, 7, 16));
      expect(result.id, 'new1');
      expect(result.name, 'Mini fan');
      expect(result.sku, 'SKU-EL-001');
      expect(result.pricePerUnit, 89000);
      expect(result.quantity, 20);
      expect(result.updatedAt, DateTime(2026, 7, 16));
      expect(result.history, isEmpty);
    });

    test('fromProduct round-trips a product back to itself', () {
      final original = product(
        name: 'Speaker',
        sku: 'SKU-EL-027',
        // WTM-393: stored categories are canonical codes; round-trip uses one.
        category: 'electronics',
        quantity: 95,
        pricePerUnit: 299000,
        reorderLevel: 30,
        description: '# Great speaker',
        imagePaths: const ['/a.jpg', '/b.jpg'],
      );
      final round = ProductFormData.fromProduct(
        original,
      ).toProduct(id: original.id, updatedAt: original.updatedAt);
      expect(round.name, original.name);
      expect(round.sku, original.sku);
      expect(round.category, original.category);
      expect(round.quantity, original.quantity);
      expect(round.pricePerUnit, original.pricePerUnit);
      expect(round.reorderLevel, original.reorderLevel);
      expect(round.description, original.description);
      expect(round.imagePaths, original.imagePaths);
    });
  });

  group('ProductEditor.create', () {
    test('builds a new product with an empty history', () {
      final now = DateTime(2026, 7, 16, 10);
      final result = ProductEditor.create(validData, id: 'n1', now: now);
      expect(result.id, 'n1');
      expect(result.name, 'Mini fan');
      expect(result.updatedAt, now);
      expect(result.history, isEmpty);
    });
  });

  group('ProductEditor.diff', () {
    test('detects every changed field', () {
      final before = product();
      final after = product(
        name: 'Widget Pro',
        pricePerUnit: 95000,
        quantity: 8,
        imagePaths: const ['/x.jpg'],
      );
      final changes = ProductEditor.diff(before, after);
      final fields = changes.map((c) => c.field).toSet();
      expect(fields, {
        ProductField.name,
        ProductField.unitPrice,
        ProductField.quantity,
        ProductField.images,
      });
      final nameChange = changes.firstWhere(
        (c) => c.field == ProductField.name,
      );
      expect(nameChange.before, 'Widget');
      expect(nameChange.after, 'Widget Pro');
    });

    test('identical products produce no changes', () {
      final p = product();
      expect(ProductEditor.diff(p, p), isEmpty);
    });

    test('unit price is formatted without a trailing .0', () {
      final change = ProductEditor.diff(
        product(pricePerUnit: 89000),
        product(pricePerUnit: 95000),
      ).single;
      expect(change.before, '89000');
      expect(change.after, '95000');
    });
  });

  group('ProductEditor.applyEdit', () {
    final now = DateTime(2026, 7, 16, 12);

    test('a real change records one revision, newest values applied', () {
      final original = product(quantity: 10);
      final data = ProductFormData.fromProduct(
        original,
      ).copyWith(quantityText: '42');
      final updated = ProductEditor.applyEdit(original, data, now: now);

      expect(updated.quantity, 42);
      expect(updated.updatedAt, now);
      expect(updated.history, hasLength(1));
      final revision = updated.history.first;
      expect(revision.timestamp, now);
      expect(revision.changes.single.field, ProductField.quantity);
      expect(revision.changes.single.before, '10');
      expect(revision.changes.single.after, '42');
    });

    test('a no-op edit returns the original untouched', () {
      final original = product();
      final data = ProductFormData.fromProduct(original);
      final updated = ProductEditor.applyEdit(original, data, now: now);
      expect(identical(updated, original), isTrue);
      expect(updated.history, isEmpty);
    });

    test('successive edits accumulate history newest-first', () {
      final original = product(name: 'A');
      final first = ProductEditor.applyEdit(
        original,
        ProductFormData.fromProduct(original).copyWith(name: 'B'),
        now: DateTime(2026, 7, 16, 9),
      );
      final second = ProductEditor.applyEdit(
        first,
        ProductFormData.fromProduct(first).copyWith(name: 'C'),
        now: DateTime(2026, 7, 16, 10),
      );

      expect(second.name, 'C');
      expect(second.history, hasLength(2));
      // Newest revision (B -> C) is first.
      expect(second.history.first.changes.single.after, 'C');
      expect(second.history.last.changes.single.after, 'B');
    });
  });

  group('Product.copyWith', () {
    test('overrides only the given fields', () {
      final original = product(name: 'A', quantity: 1);
      final copy = original.copyWith(name: 'B');
      expect(copy.name, 'B');
      expect(copy.quantity, 1);
      expect(copy.id, original.id);
    });

    test('new fields default to empty on the base model', () {
      final p = product();
      expect(p.description, '');
      expect(p.imagePaths, isEmpty);
      expect(p.history, isEmpty);
    });
  });
}
