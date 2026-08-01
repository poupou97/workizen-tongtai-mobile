import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/export/backup_codec.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_form.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';

/// WTM-204 — the cost price reaches the domain.
///
/// The column (`costPerUnit`) had been in the schema since v1; the domain never
/// carried it. That one missing field blocked four capabilities: real
/// opportunity ROI, the High Risk badge, per-product margin, and the journey's
/// "record your cost price" step (see ADR-TON-022).
///
/// The rule under test everywhere here: **null is "not entered", never 0.**
/// Zero claims the stock is free and prints a 100% margin nobody computed.
void main() {
  Product product({double? costPrice}) => Product(
    id: 'p1',
    sku: 'SKU-1',
    name: 'Quạt mini',
    category: 'Home',
    quantity: 10,
    pricePerUnit: 100000,
    reorderLevel: 3,
    updatedAt: DateTime(2026, 8, 1),
    costPrice: costPrice,
  );

  group('margin follows the ADR-TON-022 rule', () {
    test('known cost gives a real profit per unit', () {
      expect(product(costPrice: 60000).profitPerUnit, 40000);
    });

    test('no cost gives null, not a 100% margin', () {
      expect(
        product().profitPerUnit,
        isNull,
        reason: 'insufficient is an answer; a made-up margin is not',
      );
    });
  });

  test('the cost price survives closing and reopening the app', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_cost');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var db = AppDatabase.forExecutor(NativeDatabase(file));
    await DriftProductRepository(db).upsertAll([product(costPrice: 60000)]);
    await db.close();

    db = AppDatabase.forExecutor(NativeDatabase(file));
    final loaded = (await DriftProductRepository(db).loadAll()).single;
    await db.close();

    expect(loaded.costPrice, 60000);
  });

  test('a product saved without a cost comes back null, not zero', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_cost_null');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var db = AppDatabase.forExecutor(NativeDatabase(file));
    await DriftProductRepository(db).upsertAll([product()]);
    await db.close();

    db = AppDatabase.forExecutor(NativeDatabase(file));
    final loaded = (await DriftProductRepository(db).loadAll()).single;
    await db.close();

    expect(loaded.costPrice, isNull);
  });

  group('.ttbk', () {
    test('round-trips the cost price', () {
      final decoded = BackupCodec.decodeProduct(
        BackupCodec.encodeProduct(product(costPrice: 60000)),
      );

      expect(decoded!.costPrice, 60000);
    });

    test('a file written before cost prices existed still restores', () {
      // Old files lack the key entirely. The product comes back with no cost
      // entered — which is the truth about that backup.
      final json = BackupCodec.encodeProduct(product())..remove('costPrice');

      final decoded = BackupCodec.decodeProduct(json);

      expect(decoded, isNotNull);
      expect(decoded!.costPrice, isNull);
    });
  });

  group('the form', () {
    test('empty stays null — "not entered" is not "free"', () {
      final built = const ProductFormData(
        name: 'Quạt',
        sku: 'SKU-1',
        category: 'Home',
        priceText: '100000',
        quantityText: '5',
      ).toProduct(id: 'p1', updatedAt: DateTime(2026, 8, 1));

      expect(built.costPrice, isNull);
    });

    test('a typed cost is kept, and is optional to type at all', () {
      final data = const ProductFormData(
        name: 'Quạt',
        sku: 'SKU-1',
        category: 'Home',
        priceText: '100000',
        costPriceText: '60000',
        quantityText: '5',
      );

      expect(data.isValid, isTrue);
      expect(
        data.toProduct(id: 'p1', updatedAt: DateTime(2026, 8, 1)).costPrice,
        60000,
      );
    });

    test('garbage in the cost field is an error, not a silent null', () {
      final data = const ProductFormData(
        name: 'Quạt',
        sku: 'SKU-1',
        category: 'Home',
        priceText: '100000',
        costPriceText: 'abc',
        quantityText: '5',
      );

      expect(data.isValid, isFalse);
    });

    test('a changed cost price lands in the audit trail', () {
      // Margins move with the cost, and "why did my profit change" should
      // have an answer in the history.
      final before = product(costPrice: 60000);
      final after = ProductEditor.applyEdit(
        before,
        ProductFormData.fromProduct(before).copyWith(costPriceText: '70000'),
        now: DateTime(2026, 8, 2),
      );

      expect(after.history, isNotEmpty);
      expect(after.costPrice, 70000);
    });
  });
}
