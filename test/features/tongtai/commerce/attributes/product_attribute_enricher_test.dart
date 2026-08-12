import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_catalog.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_enricher.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';

/// WTM-335 — the enricher writes per-industry DYNAMIC attributes ADDITIVELY and
/// is idempotent (§17). Real Drift, real governed writes.
void main() {
  late AppDatabase db;
  late AttributeRepository repo;
  late ProductAttributeEnricher enricher;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = AttributeRepository(db);
    var n = 0;
    enricher = ProductAttributeEnricher(repo, newId: () => 'seed-${n++}');
  });
  tearDown(() => db.close());

  Product product(String id, String category) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'P $id',
    category: category,
    pricePerUnit: 100000,
    updatedAt: DateTime(2026, 8, 12),
  );

  test('enrich creates definitions, groups and per-product values', () async {
    final report = await enricher.enrich([
      product('import-1', 'Thời trang'),
      product('import-2', 'Điện tử'),
    ]);

    expect(report.definitions, kProductAttributeDefinitions.length);
    expect(report.groups, kProductAttributeGroups.length);
    expect(report.enrichedProducts, 2);
    expect(report.values, greaterThan(0));

    // The values are actually readable at the (only) read path.
    final fashionValues = await repo.loadValuesForEntity('product', 'import-1');
    expect(fashionValues, isNotEmpty);
    final electronicsValues = await repo.loadValuesForEntity(
      'product',
      'import-2',
    );
    expect(electronicsValues, isNotEmpty);
  });

  test('a product with an unmapped category gets NO values', () async {
    final report = await enricher.enrich([product('import-9', 'Mỹ phẩm')]);
    expect(report.enrichedProducts, 0);
    expect(await repo.loadValuesForEntity('product', 'import-9'), isEmpty);
  });

  test(
    'running twice is idempotent — no duplicate defs / groups / values',
    () async {
      final products = [
        product('import-1', 'Thời trang'),
        product('import-2', 'Điện tử'),
        product('import-3', 'Gia dụng'),
      ];
      await enricher.enrich(products);
      final defsAfterFirst = (await repo.loadDefinitions()).length;
      final groupsAfterFirst = (await repo.loadGroups()).length;
      final valuesAfterFirst = (await repo.loadAllValues()).length;

      await enricher.enrich(products);
      expect((await repo.loadDefinitions()).length, defsAfterFirst);
      expect((await repo.loadGroups()).length, groupsAfterFirst);
      expect(
        (await repo.loadAllValues()).length,
        valuesAfterFirst,
        reason: 'setValue replaces; the catalog is ensure-by-code',
      );

      // Group memberships must not stack either.
      final groups = await repo.loadGroups();
      for (final g in groups) {
        final items = await repo.loadGroupItems(g.id);
        final defIds = items.map((i) => i.definitionId).toList();
        expect(
          defIds.toSet().length,
          defIds.length,
          reason: 'no definition is added to a group twice',
        );
      }
    },
  );

  test(
    'every stored value is valid for its definition type (governed write)',
    () async {
      await enricher.enrich([
        product('import-1', 'Thời trang'),
        product('import-2', 'Điện tử'),
        product('import-3', 'Gia dụng'),
      ]);
      final defsById = {for (final d in await repo.loadDefinitions()) d.id: d};
      for (final v in await repo.loadAllValues()) {
        final def = defsById[v.definitionId]!;
        expect(
          def.type.isValidValue(v.valueRaw, options: def.enumOptions),
          isTrue,
          reason:
              '${def.code} stored an invalid ${def.type.code}: ${v.valueRaw}',
        );
      }
    },
  );
}
